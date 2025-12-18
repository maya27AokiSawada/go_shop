import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;
import '../models/shared_group.dart';
import '../datastore/shared_group_repository.dart';
import '../datastore/hive_shared_group_repository.dart';
import '../datastore/firestore_purchase_group_repository.dart';
import '../providers/hive_provider.dart';
import '../providers/firestore_provider.dart';
import '../flavors.dart';
import '../utils/app_logger.dart';

/// 🛡️ 初期化ステータス定義
enum InitializationStatus {
  notStarted, // 未開始
  initializingHive, // Hive初期化中
  hiveReady, // Hive準備完了
  initializingFirestore, // Firestore初期化中
  fullyReady, // 完全準備完了（Hive + Firestore）
  hiveOnlyMode, // Hiveのみモード（Firestoreエラー）
  criticalError, // クリティカルエラー
}

/// Hive（ローカルキャッシュ）+ Firestore（リモート）のハイブリッドリポジトリ
///
/// 動作原理:
/// - 読み取り: まずHiveから取得、なければFirestoreから取得してHiveにキャッシュ
/// - 書き込み: HiveとFirestore両方に保存（楽観的更新）
/// - 同期: バックグラウンドでFirestore→Hiveの差分同期
/// - オフライン: Hiveのみで動作、オンライン復帰時に自動同期
class HybridSharedGroupRepository implements SharedGroupRepository {
  final Ref _ref;
  late final HiveSharedGroupRepository _hiveRepo;
  FirestoreSharedGroupRepository? _firestoreRepo;

  // 接続状態管理
  bool _isOnline = true;
  bool _isSyncing = false;

  // 同期キューとタイマー管理
  final List<_SyncOperation> _syncQueue = [];
  Timer? _syncTimer;

  // 🛡️ 本格的初期化状態管理
  InitializationStatus _initStatus = InitializationStatus.notStarted;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initializationError;
  DateTime? _initStartTime;
  int _firestoreRetryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _initTimeout = Duration(seconds: 15);

  // 初期化進捗コールバック（UI表示用）
  Function(InitializationStatus, String?)? _onInitializationProgress;

  HybridSharedGroupRepository(this._ref) {
    developer.log('🆕 [HYBRID_REPO] HybridSharedGroupRepository安全初期化開始');
    developer.log('🔍 [HYBRID_REPO] 現在のFlavor: ${F.appFlavor}');
    developer.log('🔍 [HYBRID_REPO] Ref状態: ${_ref.runtimeType}');

    // コンストラクタでは絶対にクラッシュしない - Hiveのみ確実に初期化
    try {
      developer.log('🔄 [HYBRID_REPO] HiveSharedGroupRepository作成開始...');
      _hiveRepo = HiveSharedGroupRepository(_ref);
      developer.log('✅ [HYBRID_REPO] HiveSharedGroupRepository初期化成功');
      developer.log('🛡️ [HYBRID_REPO] 最低限の安全な動作環境確保完了 - Hiveで動作可能');
    } catch (e, stackTrace) {
      developer.log('❌ [HYBRID_REPO] 致命的エラー: Hive初期化失敗 - システム継続不可');
      developer.log('📄 [HYBRID_REPO] Error Type: ${e.runtimeType}');
      developer.log('📄 [HYBRID_REPO] Error Message: $e');
      developer.log('📄 [HYBRID_REPO] StackTrace: $stackTrace');
      rethrow; // Hive初期化失敗は真のクリティカルエラー
    }

    // Firestore初期化は非同期で安全に実行（クラッシュリスクゼロ）
    // 🔥 devモードでもFirestore初期化を実行（QR招待のため）
    developer.log(
        '🔄 [HYBRID_REPO] 非同期Firestore初期化をスケジュール (Flavor: ${F.appFlavor})');
    // 非同期で安全にFirestore初期化を試行
    _safeAsyncFirestoreInitialization();
  }

  /// 完全にクラッシュ防止のFirestore初期化（非同期・安全）
  Future<void> _safeAsyncFirestoreInitialization() async {
    if (_isInitializing) {
      developer.log('⚠️ [HYBRID_REPO] Firestore初期化既に進行中 - スキップ');
      return;
    }

    _isInitializing = true;
    developer.log('🔄 [HYBRID_REPO] 安全なFirestore初期化開始...');

    try {
      // 🔐 認証状態チェック - 認証なしではFirestoreを使わない
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        developer.log('⚠️ [HYBRID_REPO] 認証なし - Firestore同期スキップ（Hiveのみモード）');
        _firestoreRepo = null;
        _isOnline = false;
        _isInitialized = true;
        _initializationError = 'No authentication - Hive only mode';
        return;
      }

      developer.log('✅ [HYBRID_REPO] 認証確認: ${currentUser.uid}');

      // 複数層の安全網でFirestore初期化
      await Future.delayed(const Duration(milliseconds: 500)); // 安定化待機

      developer.log('🔥 [HYBRID_REPO] FirestoreSharedGroupRepository作成試行...');
      final firestore = _ref.read(firestoreProvider);
      _firestoreRepo = FirestoreSharedGroupRepository(firestore);

      // 初期化後のヘルスチェック
      await Future.delayed(const Duration(milliseconds: 100));
      developer.log('🌐 [HYBRID_REPO] Firestore統合有効化完了 - ハイブリッドモード開始');

      _isOnline = true;
      _isInitialized = true;
      _initializationError = null;
    } catch (e, stackTrace) {
      developer.log('❌ [HYBRID_REPO] Firestore初期化エラー（安全にキャッチ）: $e');
      developer.log('📄 [HYBRID_REPO] StackTrace: $stackTrace');

      _firestoreRepo = null;
      _isOnline = false;
      _isInitialized = true; // Hiveのみで初期化完了
      _initializationError = e.toString();

      developer.log('🔧 [HYBRID_REPO] 安全フォールバック完了: Hiveのみで動作継続');
    } finally {
      _isInitializing = false;
      developer.log('✅ [HYBRID_REPO] 初期化プロセス完了 - システム動作準備OK');
    }
  }

  /// 初期化完了まで安全に待機（ローディングスピナー表示推奨）
  Future<void> waitForSafeInitialization() async {
    _initStartTime = DateTime.now();
    _initStatus = InitializationStatus.initializingHive;
    _notifyProgress(InitializationStatus.initializingHive, 'Hive初期化中...');

    developer.log('🚀 [HybridRepo] Safe initialization started',
        name: 'HybridRepo');

    // Hive準備完了
    _initStatus = InitializationStatus.hiveReady;
    _notifyProgress(InitializationStatus.hiveReady, 'Hive準備完了');

    // Firestoreリトライ開始
    if (!_isInitialized) {
      _attemptFirestoreInitializationWithRetry(); // awaitしない（バックグラウンド実行）
    }
    int attempts = 0;
    const maxAttempts = 30; // 15秒間待機（500ms × 30）

    while (!_isInitialized && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;

      final elapsed = DateTime.now().difference(_initStartTime!);
      if (elapsed >= _initTimeout) {
        developer.log(
            '⏰ [HybridRepo] Initialization timeout (${_initTimeout.inSeconds}s)',
            name: 'HybridRepo');
        _initStatus = InitializationStatus.hiveOnlyMode;
        _notifyProgress(
            InitializationStatus.hiveOnlyMode, 'タイムアウト - Hiveのみモード');
        break;
      }
    }

    if (!_isInitialized) {
      developer.log('⚠️ [HYBRID_REPO] 初期化タイムアウト - Hiveのみで強制続行');
      _isInitialized = true;
      _isOnline = false;
      _firestoreRepo = null;
      _initStatus = InitializationStatus.hiveOnlyMode;
      _notifyProgress(
          InitializationStatus.hiveOnlyMode, 'タイムアウト - Hiveのみで強制続行');
    }

    final duration = DateTime.now().difference(_initStartTime!);
    developer.log(
        '🎯 [HybridRepo] Safe initialization finished - Status: $_isInitialized, Duration: ${duration.inMilliseconds}ms',
        name: 'HybridRepo');

    if (_initializationError != null) {
      developer.log('ℹ️ [HYBRID_REPO] 初期化時エラー（回復済み）: $_initializationError');
    }
  }

  /// オンライン状態をチェック
  bool get isOnline => _isOnline;

  /// 同期状態をチェック
  bool get isSyncing => _isSyncing;

  /// アプリ終了時の同期処理
  Future<void> syncOnAppExit() async {
    developer.log('🚪 [HYBRID_REPO] アプリ終了時同期開始');
    _syncTimer?.cancel();

    if (_syncQueue.isNotEmpty) {
      await _processSyncQueue();
    }

    developer.log('👋 [HYBRID_REPO] アプリ終了時同期完了');
  }

  /// ローカル（Hive）のみからグループを取得（Firestore同期なし）
  Future<List<SharedGroup>> getLocalGroups() async {
    try {
      return await _hiveRepo.getAllGroups();
    } catch (e) {
      developer.log('❌ getLocalGroups error: $e');
      return [];
    }
  }

  // =================================================================
  // キャッシュ戦略: Cache-First with Background Sync
  // =================================================================

  @override
  Future<List<SharedGroup>> getAllGroups() async {
    // 🛡️ 安全な初期化完了を待機（ローディングスピナー表示推奨）
    await waitForSafeInitialization();
    developer.log('✅ [HYBRID_REPO] 安全な初期化確認完了 - 全グループ取得続行');

    return await _getAllGroupsInternal();
  }

  /// 内部用：初期化待機なしでグループを取得
  Future<List<SharedGroup>> _getAllGroupsInternal() async {
    AppLogger.info(
        '🔍 [HYBRID] _getAllGroupsInternal開始 - Flavor: ${F.appFlavor}, Online: $_isOnline');
    try {
      // 🔥 サインイン必須仕様: Firestore優先
      if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        try {
          developer.log('🔥 [HYBRID_REPO] Firestore優先モード - Firestoreから全グループ取得');
          AppLogger.info('🔥 [HYBRID] Firestore優先モード - 全グループ取得開始');

          // 1. Firestoreから取得（常に最新）
          final firestoreGroups = await _firestoreRepo!.getAllGroups();
          developer.log(
              '✅ [HYBRID_REPO] Firestore取得完了: ${firestoreGroups.length}グループ');
          AppLogger.info(
              '✅ [HYBRID] Firestoreから${firestoreGroups.length}グループ取得');

          for (var group in firestoreGroups) {
            AppLogger.info(
                '  📡 [FIRESTORE] ${AppLogger.maskGroup(group.groupName, group.groupId)} - allowedUid: ${group.allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()}');
          }

          // 2. Hiveにキャッシュ（次回の高速読み取りのため）
          for (final group in firestoreGroups) {
            await _hiveRepo.saveGroup(group);
          }
          developer.log('✅ [HYBRID_REPO] Hiveキャッシュ更新完了');
          AppLogger.info('✅ [HYBRID] Hiveキャッシュ更新完了');

          return firestoreGroups;
        } catch (e) {
          developer.log('⚠️ [HYBRID_REPO] Firestore取得エラー、Hiveにフォールバック: $e');
          AppLogger.warning('⚠️ [HYBRID] Firestore取得エラー、Hiveにフォールバック: $e');

          // Firestoreエラー時のみHiveフォールバック
          final cachedGroups = await _hiveRepo.getAllGroups();
          AppLogger.info(
              '📦 [HYBRID] Hiveから${cachedGroups.length}グループ取得（フォールバック）');
          return cachedGroups;
        }
      }

      // dev環境またはFirestore未初期化の場合のみHive
      developer.log('📦 [HYBRID_REPO] dev環境 - Hiveから取得');
      final cachedGroups = await _hiveRepo.getAllGroups();
      AppLogger.info('📦 [HYBRID] Hiveから${cachedGroups.length}グループ取得（dev環境）');
      for (var group in cachedGroups) {
        AppLogger.info(
            '  📦 [HIVE] ${AppLogger.maskGroup(group.groupName, group.groupId)} - allowedUid: ${group.allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()}');
      }

      return cachedGroups;
    } catch (e) {
      developer.log('❌ [HYBRID_REPO] getAllGroups error: $e');
      AppLogger.error('❌ [HYBRID] getAllGroups error: $e');
      rethrow;
    }
  }

  /// UI使用専用：初期化を待たずに即座にHiveからグループを取得
  /// 通常のUI表示で使用する（長時間待機を避ける）
  Future<List<SharedGroup>> getAllGroupsForUI() async {
    developer.log('🚀 [HYBRID_REPO] UI用グループ取得開始（初期化待機なし）');

    try {
      return await _getAllGroupsInternal();
    } catch (e) {
      developer.log('❌ [HYBRID_REPO] UI用グループ取得エラー: $e');
      // エラー時は空リストを返す（UIクラッシュを防ぐ）
      return [];
    }
  }

  @override
  Future<SharedGroup> getGroupById(String groupId) async {
    // 🔥 サインイン必須仕様: Firestore優先
    if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
      try {
        developer
            .log('🔥 [HYBRID_REPO] Firestore優先モード - Firestoreから取得: $groupId');

        // 1. Firestoreから取得（常に最新）
        final firestoreGroup = await _firestoreRepo!.getGroupById(groupId);
        developer
            .log('✅ [HYBRID_REPO] Firestore取得完了: ${firestoreGroup.groupName}');

        // 2. Hiveにキャッシュ（次回の高速読み取りのため）
        await _hiveRepo.saveGroup(firestoreGroup);
        developer.log('✅ [HYBRID_REPO] Hiveキャッシュ更新完了');

        return firestoreGroup;
      } catch (e) {
        developer.log('⚠️ [HYBRID_REPO] Firestore取得エラー、Hiveにフォールバック: $e');
        // Firestoreエラー時のみHiveフォールバック
        return await _hiveRepo.getGroupById(groupId);
      }
    } else {
      // dev環境またはFirestore未初期化の場合のみHive
      developer.log('📝 [HYBRID_REPO] dev環境 - Hiveから取得: $groupId');
      return await _hiveRepo.getGroupById(groupId);
    }
  }

  // =================================================================
  // 楽観的更新戦略: Optimistic Update with Conflict Resolution
  // =================================================================

  @override
  Future<SharedGroup> createGroup(
      String groupId, String groupName, SharedGroupMember member) async {
    developer.log('🆕 [HYBRID_REPO] グループ作成開始: $groupName');

    // 🛡️ 安全な初期化完了を待機（ローディングスピナー表示推奨）
    await waitForSafeInitialization();
    developer.log('✅ [HYBRID_REPO] 安全な初期化確認完了 - グループ作成続行');

    try {
      // メンバープール用グループはHiveのみに保存する
      if (groupId == 'member_pool') {
        developer
            .log('🔒 [HYBRID_REPO] Member pool group - Hiveのみ: $groupName');
        final newGroup =
            await _hiveRepo.createGroup(groupId, groupName, member);
        return newGroup;
      }

      // 🔥 サインイン必須仕様: Firestore優先
      if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        developer.log('🔥 [HYBRID_REPO] Firestore優先モード - Firestoreに作成');

        // 1. Firestoreに作成
        final newGroup =
            await _firestoreRepo!.createGroup(groupId, groupName, member);
        developer.log('✅ [HYBRID_REPO] Firestore作成完了: $groupName');

        // 2. Hiveにキャッシュ（読み取り高速化のため）
        await _hiveRepo.saveGroup(newGroup);
        developer.log('✅ [HYBRID_REPO] Hiveキャッシュ保存完了: $groupName');

        return newGroup;
      } else {
        // dev環境またはFirestore未初期化の場合のみHive
        developer.log('📝 [HYBRID_REPO] dev環境 - Hiveに作成');
        final newGroup =
            await _hiveRepo.createGroup(groupId, groupName, member);
        developer.log('✅ [HYBRID_REPO] Hive保存完了: $groupName');
        return newGroup;
      }
    } catch (e) {
      developer.log('❌ [HYBRID_REPO] グループ作成エラー: $e');
      rethrow;
    }
  }

  // =================================================================
  // 同期キューとタイマー管理
  // =================================================================

  /// 同期キューに操作を追加
  void _addToSyncQueue(_SyncOperation operation) {
    _syncQueue.add(operation);
    developer.log(
        '📋 [HYBRID_REPO] 同期キュー追加: ${operation.type} ${operation.groupId}');
    developer.log('📊 [HYBRID_REPO] キューサイズ: ${_syncQueue.length}');
  }

  /// 同期タイマーをスケジュール（30秒後に再試行）
  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 30), () {
      developer.log('⏰ [HYBRID_REPO] 定期同期開始');
      _processSyncQueue();
    });
  }

  /// 同期キューを処理
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty || _isSyncing) {
      return;
    }

    developer.log('🔄 [HYBRID_REPO] 同期キュー処理開始: ${_syncQueue.length}件');
    _isSyncing = true;

    final failedOperations = <_SyncOperation>[];

    try {
      for (final operation in _syncQueue) {
        try {
          await _executeSyncOperation(operation);
          developer.log(
              '✅ [HYBRID_REPO] 同期成功: ${operation.type} ${operation.groupId}');
        } catch (e) {
          developer.log(
              '❌ [HYBRID_REPO] 同期失敗: ${operation.type} ${operation.groupId} - $e');

          // 再試行回数が3回未満なら再キュー
          if (operation.retryCount < 3) {
            failedOperations
                .add(operation.copyWith(retryCount: operation.retryCount + 1));
          } else {
            developer.log(
                '💀 [HYBRID_REPO] 同期諦め（3回失敗）: ${operation.type} ${operation.groupId}');
          }
        }
      }
    } finally {
      _syncQueue.clear();
      _syncQueue.addAll(failedOperations);
      _isSyncing = false;

      // 失敗操作があれば再スケジュール
      if (failedOperations.isNotEmpty) {
        developer
            .log('🔄 [HYBRID_REPO] 失敗操作の再スケジュール: ${failedOperations.length}件');
        _scheduleSync();
      }
    }
  }

  /// 個別の同期操作を実行
  Future<void> _executeSyncOperation(_SyncOperation operation) async {
    if (_firestoreRepo == null) {
      throw Exception('Firestore repository not available');
    }

    switch (operation.type) {
      case 'create':
        final ownerMember = SharedGroupMember(
          memberId: operation.data['ownerMember']['uid'] ??
              operation.data['ownerMember']['memberId'] ??
              '',
          name: operation.data['ownerMember']['displayName'] ??
              operation.data['ownerMember']['name'] ??
              '',
          contact: operation.data['ownerMember']['contact'] ?? '',
          role: SharedGroupRole.values.firstWhere(
            (role) => role.name == operation.data['ownerMember']['role'],
          ),
          invitedAt: DateTime.now(),
          acceptedAt: DateTime.now(),
        );
        await _firestoreRepo!.createGroup(
          operation.groupId,
          operation.data['groupName'],
          ownerMember,
        );
        break;
      // TODO: update, delete操作も実装
      default:
        throw Exception('Unknown sync operation: ${operation.type}');
    }
  }

  /// Firestoreへのグループ作成同期（フォールバック付き同期的書き込み）
  Future<void> _syncCreateGroupToFirestoreWithFallback(
      SharedGroup group) async {
    developer.log('🔍 [HYBRID_REPO] Firestore同期的書き込み開始: ${group.groupName}');

    if (F.appFlavor == Flavor.dev || _firestoreRepo == null) {
      developer.log('⚠️ [HYBRID_REPO] DEV環境またはFirestore無効 - Hiveのみ');
      return;
    }

    try {
      // 🛡️ Members empty チェック（crash-proof）
      if (group.members?.isEmpty ?? true) {
        developer.log(
            '❌ [HYBRID_REPO] Group members is empty - skipping Firestore sync');
        return;
      }

      // 同期的書き込み（ユーザーを待たせてもOK）
      final ownerMember = group.members!
          .firstWhere((m) => m.role == SharedGroupRole.owner, orElse: () {
        developer.log('⚠️ [HYBRID_REPO] No owner found, using first member');
        return group.members!.first;
      });

      developer.log('⏳ [HYBRID_REPO] Firestore書き込み中...: ${group.groupName}');
      developer.log(
          '🔍 [HYBRID_REPO] Owner member: ${ownerMember.name} (${ownerMember.memberId})');

      await _firestoreRepo!
          .createGroup(group.groupId, group.groupName, ownerMember)
          .timeout(
        const Duration(seconds: 15), // タイムアウトを15秒に延長
        onTimeout: () {
          developer
              .log('⏰ [HYBRID_REPO] Firestore書き込みタイムアウト: ${group.groupName}');
          throw Exception('Firestore write timeout after 15 seconds');
        },
      );

      developer.log('✅ [HYBRID_REPO] Firestore書き込み成功: ${group.groupName}');
      _isOnline = true; // オンライン状態を更新
    } catch (e, stackTrace) {
      developer.log('❌ [HYBRID_REPO] Firestore書き込み失敗: $e');
      developer.log('📄 [HYBRID_REPO] StackTrace: $stackTrace');

      // オフライン状態に設定
      _isOnline = false;

      // 🛡️ Members安全チェック（crash-proof）
      if (group.members?.isEmpty ?? true) {
        developer.log('❌ [HYBRID_REPO] Cannot add to sync queue - no members');
        return;
      }

      final firstMember = group.members!.first;
      // 同期キューに追加（タイマーで後で再試行）
      _addToSyncQueue(_SyncOperation(
        type: 'create',
        groupId: group.groupId,
        data: {
          'groupName': group.groupName,
          'ownerMember': {
            'memberId': firstMember.memberId,
            'name': firstMember.name,
            'contact': firstMember.contact,
            'role': firstMember.role.name,
          }
        },
        timestamp: DateTime.now(),
      ));

      developer.log('📋 [HYBRID_REPO] 同期キューに追加 - 後で再試行');
      _scheduleSync();
    }
  }

  @override
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group) async {
    try {
      developer.log(
          '🔍 [HYBRID UPDATE] groupId: $groupId, allowedUid: ${group.allowedUid}');

      // 1. Hiveを即座に更新
      await _hiveRepo.saveGroup(group);
      developer.log('✅ [HYBRID UPDATE] Hive保存完了');

      if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
        developer.log(
            '💡 [HYBRID UPDATE] Firestore同期スキップ (dev=${F.appFlavor == Flavor.dev}, online=$_isOnline)');
        return group;
      }

      developer.log('🔥 [HYBRID UPDATE] Firestore同期開始...');

      // 2. Firestoreに同期（allowedUid更新の確実性のため完了を待つ）
      try {
        final updatedGroup = await _firestoreRepo!.updateGroup(groupId, group);
        developer.log('✅ [HYBRID UPDATE] Firestore同期完了');
        // Firestoreで更新された場合、差分をHiveに反映
        if (updatedGroup.hashCode != group.hashCode) {
          await _hiveRepo.saveGroup(updatedGroup);
          developer.log('🔄 Firestore changes synced back to cache');
        }
        return updatedGroup;
      } catch (e) {
        developer.log('⚠️ [HYBRID UPDATE] Firestore同期失敗: $e');
        // Hiveは既に保存済みなので継続
        return group;
      }
    } catch (e) {
      developer.log('❌ updateGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<SharedGroup> deleteGroup(String groupId) async {
    try {
      Log.info('🗑️ [DELETE] グループ削除開始: $groupId');

      // 1. Hiveから削除
      final deletedGroup = await _hiveRepo.deleteGroup(groupId);
      Log.info('✅ [DELETE] Hive削除完了: $groupId');

      // メンバープール用グループはHiveのみで削除
      if (groupId == 'member_pool') {
        Log.info('🔒 Member pool group deleted from Hive only: $groupId');
        return deletedGroup;
      }

      // Firestore削除の前提条件チェック
      Log.info('🔍 [DELETE] Firestore削除条件チェック:');
      Log.info('  - Flavor: ${F.appFlavor} (prod必須)');
      Log.info('  - _isOnline: $_isOnline');
      Log.info(
          '  - _firestoreRepo: ${_firestoreRepo != null ? "初期化済み" : "null"}');

      if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
        Log.warning('⚠️ [DELETE] Firestore削除スキップ (条件未満たず)');
        return deletedGroup;
      }

      // 2. Firestoreから同期削除（メンバープール以外のみ）
      // 削除操作は確実に完了させるため、awaitで待つ
      Log.info('🔥 [DELETE] Firestore削除実行開始: $groupId');
      try {
        await _firestoreRepo!.deleteGroup(groupId);
        Log.info('✅ [DELETE] Firestore削除完了: $groupId');
      } catch (e) {
        Log.error('❌ [DELETE] Firestore削除失敗: $e');
        // Firestoreへの削除が失敗してもHive削除は完了しているので処理継続
      }

      return deletedGroup;
    } catch (e) {
      developer.log('❌ deleteGroup error: $e');
      rethrow;
    }
  }

  // =================================================================
  // メンバー操作（楽観的更新）
  // =================================================================

  @override
  Future<SharedGroup> addMember(
      String groupId, SharedGroupMember member) async {
    try {
      final updatedGroup = await _hiveRepo.addMember(groupId, member);

      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        _unawaited(_firestoreRepo!.addMember(groupId, member).then((_) {
          developer.log('🔄 AddMember synced to Firestore');
        }).catchError((e) {
          developer.log('⚠️ Failed to sync addMember to Firestore: $e');
        }));
      }

      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SharedGroup> removeMember(
      String groupId, SharedGroupMember member) async {
    try {
      final updatedGroup = await _hiveRepo.removeMember(groupId, member);

      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        _unawaited(_firestoreRepo!.removeMember(groupId, member).then((_) {
          developer.log('🔄 RemoveMember synced to Firestore');
        }).catchError((e) {
          developer.log('⚠️ Failed to sync removeMember to Firestore: $e');
        }));
      }

      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  // =================================================================
  // メンバープール（ローカル専用 - 個人情報保護）
  // =================================================================

  /// メンバープールは個人情報保護の観点からHiveローカルDBにのみ保存
  /// Firestoreには一切同期しない
  @override
  Future<SharedGroup> getOrCreateMemberPool() async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.getOrCreateMemberPool();
  }

  @override
  Future<void> syncMemberPool() async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.syncMemberPool();
  }

  @override
  Future<List<SharedGroupMember>> searchMembersInPool(String query) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.searchMembersInPool(query);
  }

  @override
  Future<SharedGroupMember?> findMemberByEmail(String email) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.findMemberByEmail(email);
  }

  @override
  Future<int> cleanupDeletedGroups() async {
    // Hiveのクリーンアップメソッドを呼び出す
    developer.log('🧹 [HYBRID_REPO] Delegating cleanup to Hive repository');
    return await _hiveRepo.cleanupDeletedGroups();
  }

  @override
  Future<SharedGroup> setMemberId(
      String oldId, String newId, String? contact) async {
    try {
      final updatedGroup = await _hiveRepo.setMemberId(oldId, newId, contact);

      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        _unawaited(_firestoreRepo!.setMemberId(oldId, newId, contact).then((_) {
          developer.log('🔄 SetMemberId synced to Firestore');
        }).catchError((e) {
          developer.log('⚠️ Failed to sync setMemberId to Firestore: $e');
        }));
      }

      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  // =================================================================
  // バックグラウンド同期
  // =================================================================

  /// Firestoreから全グループを非同期で同期
  void _syncFromFirestoreInBackground() {
    if (_isSyncing || F.appFlavor == Flavor.dev || _firestoreRepo == null) {
      return;
    }

    _isSyncing = true;
    _unawaited(_firestoreRepo!.getAllGroups().then((firestoreGroups) async {
      // 差分を検出してHiveに同期
      for (final firestoreGroup in firestoreGroups) {
        try {
          final cachedGroup =
              await _hiveRepo.getGroupById(firestoreGroup.groupId);

          // 簡単な差分検出（実際はtimestamp比較が望ましい）
          if (cachedGroup.hashCode != firestoreGroup.hashCode) {
            await _hiveRepo.saveGroup(firestoreGroup);
            developer
                .log('🔄 Synced from Firestore: ${firestoreGroup.groupName}');
          }
        } catch (e) {
          // キャッシュにない場合は新規追加
          await _hiveRepo.saveGroup(firestoreGroup);
          developer.log('➕ New from Firestore: ${firestoreGroup.groupName}');
        }
      }
    }).catchError((e) {
      developer.log('⚠️ Background sync failed: $e');
      _isOnline = false; // 接続エラーを検出
    }).whenComplete(() {
      _isSyncing = false;
    }));
  }

  /// 特定グループをFirestoreから同期
  void _syncGroupFromFirestoreInBackground(String groupId) {
    if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
      return;
    }

    _unawaited(
        _firestoreRepo!.getGroupById(groupId).then((firestoreGroup) async {
      final cachedGroup = await _hiveRepo.getGroupById(groupId);

      if (cachedGroup.hashCode != firestoreGroup.hashCode) {
        await _hiveRepo.saveGroup(firestoreGroup);
        developer
            .log('🔄 Group synced from Firestore: ${firestoreGroup.groupName}');
      }
    }).catchError((e) {
      developer.log('⚠️ Group sync failed: $e');
    }));
  }

  /// Fire-and-forget 非同期実行
  void _unawaited(Future<void> operation) {
    operation.catchError((e) {
      developer.log('⚠️ Unawaited operation failed: $e');
    });
  }

  // =================================================================
  // 手動同期・管理機能
  // =================================================================

  /// 手動でFirestoreからフル同期
  Future<void> forceSyncFromFirestore() async {
    if (F.appFlavor == Flavor.dev || _firestoreRepo == null) {
      developer.log('🔧 Force sync skipped in dev mode');
      return;
    }

    try {
      _isSyncing = true;
      final firestoreGroups = await _firestoreRepo!.getAllGroups();

      // すべてのFirestoreデータでHiveを更新
      for (final group in firestoreGroups) {
        await _hiveRepo.saveGroup(group);
      }

      developer.log('✅ Force sync completed: ${firestoreGroups.length} groups');
      _isOnline = true;
    } catch (e) {
      developer.log('❌ Force sync failed: $e');
      _isOnline = false;
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// 未同期のローカル変更をFirestoreにプッシュ
  Future<void> pushLocalChangesToFirestore() async {
    if (F.appFlavor == Flavor.dev || _firestoreRepo == null) return;

    try {
      final localGroups = await _hiveRepo.getAllGroups();

      for (final group in localGroups) {
        try {
          await _firestoreRepo!.updateGroup(group.groupId, group);
          developer.log('📤 Pushed to Firestore: ${group.groupName}');
        } catch (e) {
          developer.log('⚠️ Failed to push ${group.groupName}: $e');
        }
      }
    } catch (e) {
      developer.log('❌ Push operation failed: $e');
      rethrow;
    }
  }

  /// キャッシュクリア
  Future<void> clearCache() async {
    try {
      final box = _ref.read(SharedGroupBoxProvider);
      await box.clear();
      developer.log('🗑️ Cache cleared');
    } catch (e) {
      developer.log('❌ Failed to clear cache: $e');
      rethrow;
    }
  }

  /// 接続状態を設定（テスト用）
  void setOnlineStatus(bool online) {
    _isOnline = online;
    developer.log('🌐 Online status set to: $online');
  }

  /// Firestoreから強制的に同期してHiveを更新
  /// Firebase認証済みユーザーのデータ復旧時に使用
  Future<void> syncFromFirestore() async {
    if (!_isOnline || F.appFlavor == Flavor.dev || _firestoreRepo == null) {
      developer.log('💡 Firestore同期スキップ (オフラインまたはDEV環境)');
      return;
    }

    if (_isSyncing) {
      developer.log('⏳ 既に同期処理中...');
      return;
    }

    _isSyncing = true;

    try {
      developer.log('🔄 Firestoreからの強制同期開始...');

      // Firestoreからすべてのグループを取得
      final firestoreGroups = await _firestoreRepo!.getAllGroups();
      developer.log('📥 Firestoreから${firestoreGroups.length}グループを取得');

      // ✅ Firestoreからグループが取得できた場合のみ、Hiveをクリアして更新
      if (firestoreGroups.isNotEmpty) {
        developer.log('✅ Firestore からグループを取得しました。Hive を更新します...');

        // Hiveを完全にクリア
        await clearCache();

        // FirestoreデータをすべてHiveに保存
        for (final group in firestoreGroups) {
          await _hiveRepo.saveGroup(group);
        }

        developer.log('✅ Firestore→Hive同期完了 (${firestoreGroups.length}グループ)');
      } else {
        developer.log('⚠️ Firestore からグループが取得できませんでした。Hive はクリアしません。');
        developer.log('💡 考えられる原因: ユーザーがグループに属していない、セキュリティルール制限、認証エラー等');
      }
    } catch (e) {
      developer.log('❌ Firestore同期エラー: $e');
      developer.log('💡 エラーの詳細: ${e.toString()}');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// 📊 初期化進行状況の通知
  void _notifyProgress(InitializationStatus status, String? message) {
    _initStatus = status;
    _onInitializationProgress?.call(status, message);
    developer.log('📊 [HybridRepo] Status: $status - $message',
        name: 'HybridRepo');
  }

  /// 🔄 リトライ付きFirestore初期化
  Future<void> _attemptFirestoreInitializationWithRetry() async {
    _firestoreRetryCount = 0;

    while (_firestoreRetryCount < _maxRetries) {
      try {
        _notifyProgress(InitializationStatus.initializingFirestore,
            'Firestore接続試行 ${_firestoreRetryCount + 1}/$_maxRetries');

        await _safeAsyncFirestoreInitialization();

        if (_firestoreRepo != null) {
          _notifyProgress(InitializationStatus.fullyReady, 'Firestore接続完了');
          return;
        }
      } catch (e) {
        _firestoreRetryCount++;
        developer.log(
            '🔄 [HybridRepo] Firestore retry $_firestoreRetryCount/$_maxRetries failed: $e',
            name: 'HybridRepo');

        if (_firestoreRetryCount < _maxRetries) {
          // 指数バックオフ: 1秒, 2秒, 4秒
          final delay =
              Duration(seconds: math.pow(2, _firestoreRetryCount - 1).toInt());
          await Future.delayed(delay);
        }
      }
    }

    // 全リトライ失敗
    _notifyProgress(
        InitializationStatus.hiveOnlyMode, 'Firestore接続失敗 - Hiveのみモード');
    developer.log(
        '❌ [HybridRepo] All Firestore retries failed, falling back to Hive-only',
        name: 'HybridRepo');
  }

  /// 🎛️ 初期化進行状況コールバック設定
  void setInitializationProgressCallback(
      Function(InitializationStatus, String?)? callback) {
    _onInitializationProgress = callback;
  }

  /// 📊 現在の初期化ステータス取得
  InitializationStatus get initializationStatus => _initStatus;
}

/// 同期操作を表すクラス
class _SyncOperation {
  final String type; // 'create', 'update', 'delete'
  final String groupId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  const _SyncOperation({
    required this.type,
    required this.groupId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  _SyncOperation copyWith({int? retryCount}) {
    return _SyncOperation(
      type: type,
      groupId: groupId,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
