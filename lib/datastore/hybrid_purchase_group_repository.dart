import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../datastore/firestore_purchase_group_repository.dart';
import '../providers/hive_provider.dart';
import '../flavors.dart';

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
class HybridPurchaseGroupRepository implements PurchaseGroupRepository {
  final Ref _ref;
  late final HivePurchaseGroupRepository _hiveRepo;
  FirestorePurchaseGroupRepository? _firestoreRepo;

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

  HybridPurchaseGroupRepository(this._ref) {
    developer.log('🆕 [HYBRID_REPO] HybridPurchaseGroupRepository安全初期化開始');
    developer.log('🔍 [HYBRID_REPO] 現在のFlavor: ${F.appFlavor}');
    developer.log('🔍 [HYBRID_REPO] Ref状態: ${_ref.runtimeType}');

    // コンストラクタでは絶対にクラッシュしない - Hiveのみ確実に初期化
    try {
      developer.log('🔄 [HYBRID_REPO] HivePurchaseGroupRepository作成開始...');
      _hiveRepo = HivePurchaseGroupRepository(_ref);
      developer.log('✅ [HYBRID_REPO] HivePurchaseGroupRepository初期化成功');
      developer.log('🛡️ [HYBRID_REPO] 最低限の安全な動作環境確保完了 - Hiveで動作可能');
    } catch (e, stackTrace) {
      developer.log('❌ [HYBRID_REPO] 致命的エラー: Hive初期化失敗 - システム継続不可');
      developer.log('📄 [HYBRID_REPO] Error Type: ${e.runtimeType}');
      developer.log('📄 [HYBRID_REPO] Error Message: $e');
      developer.log('📄 [HYBRID_REPO] StackTrace: $stackTrace');
      rethrow; // Hive初期化失敗は真のクリティカルエラー
    } // Firestore初期化は非同期で安全に実行（クラッシュリスクゼロ）
    if (F.appFlavor != Flavor.dev) {
      developer.log('🔄 [HYBRID_REPO] 非同期Firestore初期化をスケジュール');
      // 非同期で安全にFirestore初期化を試行
      _safeAsyncFirestoreInitialization();
    } else {
      developer.log('💡 [HYBRID_REPO] DEV環境 - Hiveのみで動作');
      _isInitialized = true;
    }
  }

  /// 完全にクラッシュ防止のFirestore初期化（非同期・安全）
  Future<void> _safeAsyncFirestoreInitialization() async {
    if (_isInitializing) {
      developer.log('⚠️ [HYBRID_REPO] Firestore初期化既に進行中 - スキップ');
      return;
    }

    _isInitializing = true;
    developer.log('� [HYBRID_REPO] 安全なFirestore初期化開始...');

    try {
      // 複数層の安全網でFirestore初期化
      await Future.delayed(const Duration(milliseconds: 500)); // 安定化待機

      developer.log('� [HYBRID_REPO] FirestorePurchaseGroupRepository作成試行...');
      _firestoreRepo = FirestorePurchaseGroupRepository(_ref);

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
  Future<List<PurchaseGroup>> getLocalGroups() async {
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
  Future<List<PurchaseGroup>> getAllGroups() async {
    // 🛡️ 安全な初期化完了を待機（ローディングスピナー表示推奨）
    await waitForSafeInitialization();
    developer.log('✅ [HYBRID_REPO] 安全な初期化確認完了 - 全グループ取得続行');

    return await _getAllGroupsInternal();
  }

  /// 内部用：初期化待機なしでグループを取得
  Future<List<PurchaseGroup>> _getAllGroupsInternal() async {
    try {
      // 1. まずHiveから取得（高速）
      final cachedGroups = await _hiveRepo.getAllGroups();

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        // Dev環境またはオフライン時はHiveのみ
        developer.log('📦 Cache-only: ${cachedGroups.length}グループ取得');
        return cachedGroups;
      }

      // ✅ Hiveが空の場合、Firestoreからフォールバック
      if (cachedGroups.isEmpty &&
          F.appFlavor == Flavor.prod &&
          _firestoreRepo != null) {
        developer.log('🔍 Hiveが空です。Firestoreから復旧を試みます...');
        try {
          final firestoreGroups = await _firestoreRepo!.getAllGroups();
          developer.log('✅ Firestore復旧: ${firestoreGroups.length}グループを取得');

          // Hiveにキャッシュ
          for (final group in firestoreGroups) {
            await _hiveRepo.saveGroup(group);
          }
          developer.log('💾 Hiveにキャッシュ保存完了');
          return firestoreGroups;
        } catch (firestoreError) {
          developer.log('⚠️ Firestore復旧失敗: $firestoreError');
          // Firestore復旧失敗時も、キャッシュの空リストを返す（オフライン対応）
          return cachedGroups;
        }
      }

      // 2. バックグラウンドでFirestoreと同期（ノンブロッキング）
      _syncFromFirestoreInBackground();

      // 3. キャッシュデータを即座に返却
      developer.log('⚡ Cache-first: ${cachedGroups.length}グループ取得 (同期中...)');
      return cachedGroups;
    } catch (e) {
      developer.log('❌ getAllGroups error: $e');

      // Hiveでエラーの場合、Firestoreから直接取得を試行
      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        try {
          final firestoreGroups = await _firestoreRepo!.getAllGroups();
          developer
              .log('🔥 Fallback to Firestore: ${firestoreGroups.length}グループ');
          return firestoreGroups;
        } catch (firestoreError) {
          developer.log('❌ Firestore fallback failed: $firestoreError');
        }
      }

      rethrow;
    }
  }

  /// UI使用専用：初期化を待たずに即座にHiveからグループを取得
  /// 通常のUI表示で使用する（長時間待機を避ける）
  Future<List<PurchaseGroup>> getAllGroupsForUI() async {
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
  Future<PurchaseGroup> getGroupById(String groupId) async {
    try {
      // 1. Hiveから取得を試行
      final cachedGroup = await _hiveRepo.getGroupById(groupId);

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return cachedGroup;
      }

      // 2. バックグラウンドでFirestoreの最新版をチェック
      _syncGroupFromFirestoreInBackground(groupId);

      return cachedGroup;
    } catch (e) {
      // Hiveで見つからない場合、Firestoreから取得してキャッシュ
      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        try {
          final firestoreGroup = await _firestoreRepo!.getGroupById(groupId);

          // Hiveにキャッシュ
          await _hiveRepo.saveGroup(firestoreGroup);

          developer.log('🔄 Firestore→Cache: ${firestoreGroup.groupName}');
          return firestoreGroup;
        } catch (firestoreError) {
          developer.log('❌ Group not found in Firestore: $groupId');
        }
      }

      rethrow;
    }
  }

  // =================================================================
  // 楽観的更新戦略: Optimistic Update with Conflict Resolution
  // =================================================================

  @override
  Future<PurchaseGroup> createGroup(
      String groupId, String groupName, PurchaseGroupMember member) async {
    developer.log('🆕 [HYBRID_REPO] グループ作成開始: $groupName');

    // 🛡️ 安全な初期化完了を待機（ローディングスピナー表示推奨）
    await waitForSafeInitialization();
    developer.log('✅ [HYBRID_REPO] 安全な初期化確認完了 - グループ作成続行');

    try {
      // 1. まずHiveに保存（楽観的更新）
      developer.log('📝 [HYBRID_REPO] Hive保存開始...');
      developer
          .log('🔍 [HYBRID_REPO] _hiveRepo インスタンス: ${_hiveRepo.runtimeType}');
      developer.log('🔍 [HYBRID_REPO] createGroup パラメータ:');
      developer.log('   - groupId: $groupId');
      developer.log('   - groupName: $groupName');
      developer.log('   - member: ${member.name} (${member.memberId})');

      final newGroup = await _hiveRepo.createGroup(groupId, groupName, member);
      developer.log('✅ [HYBRID_REPO] Hive保存完了: $groupName');

      // メンバープール用グループはHiveのみに保存する
      if (groupId == 'member_pool') {
        developer
            .log('🔒 [HYBRID_REPO] Member pool group - Hiveのみ: $groupName');
        return newGroup;
      }

      // 2. Firestoreへの同期的書き込み（ユーザーを待たせてもOK）
      await _syncCreateGroupToFirestoreWithFallback(newGroup);

      return newGroup;
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
        final ownerMember = PurchaseGroupMember(
          memberId: operation.data['ownerMember']['memberId'],
          name: operation.data['ownerMember']['name'],
          contact: operation.data['ownerMember']['contact'],
          role: PurchaseGroupRole.values.firstWhere(
            (role) => role.name == operation.data['ownerMember']['role'],
          ),
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
      PurchaseGroup group) async {
    developer.log('🔍 [HYBRID_REPO] Firestore同期的書き込み開始: ${group.groupName}');

    if (F.appFlavor == Flavor.dev || _firestoreRepo == null) {
      developer.log('⚠️ [HYBRID_REPO] DEV環境またはFirestore無効 - Hiveのみ');
      return;
    }

    try {
      // 🛡️ Members null チェック（crash-proof）
      if (group.members == null || group.members!.isEmpty) {
        developer.log(
            '❌ [HYBRID_REPO] Group members is null or empty - skipping Firestore sync');
        return;
      }

      // 同期的書き込み（ユーザーを待たせてもOK）
      final ownerMember = group.members!
          .firstWhere((m) => m.role == PurchaseGroupRole.owner, orElse: () {
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
      if (group.members == null || group.members!.isEmpty) {
        developer.log('❌ [HYBRID_REPO] Cannot add to sync queue - no members');
        return;
      }

      // 同期キューに追加（タイマーで後で再試行）
      _addToSyncQueue(_SyncOperation(
        type: 'create',
        groupId: group.groupId,
        data: {
          'groupName': group.groupName,
          'ownerMember': {
            'memberId': group.members!.first.memberId,
            'name': group.members!.first.name,
            'contact': group.members!.first.contact,
            'role': group.members!.first.role.name,
          }
        },
        timestamp: DateTime.now(),
      ));

      developer.log('📋 [HYBRID_REPO] 同期キューに追加 - 後で再試行');
      _scheduleSync();
    }
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    try {
      // 1. Hiveを即座に更新
      await _hiveRepo.saveGroup(group);

      if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
        return group;
      }

      // 2. Firestoreに非同期同期
      _unawaited(_firestoreRepo!
          .updateGroup(groupId, group)
          .then((updatedGroup) async {
        // Firestoreで更新された場合、差分をHiveに反映
        if (updatedGroup.hashCode != group.hashCode) {
          await _hiveRepo.saveGroup(updatedGroup);
          developer.log('🔄 Firestore changes synced back to cache');
        }
      }).catchError((e) {
        developer.log('⚠️ Failed to sync update to Firestore: $e');
        // TODO: 競合解決ロジック
      }));

      return group;
    } catch (e) {
      developer.log('❌ updateGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    try {
      // 1. Hiveから削除
      final deletedGroup = await _hiveRepo.deleteGroup(groupId);

      // メンバープール用グループはHiveのみで削除
      if (groupId == 'member_pool') {
        developer.log('🔒 Member pool group deleted from Hive only: $groupId');
        return deletedGroup;
      }

      if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
        return deletedGroup;
      }

      // 2. Firestoreから非同期削除（メンバープール以外のみ）
      _unawaited(_firestoreRepo!.deleteGroup(groupId).then((_) {
        developer.log('🔄 Delete synced to Firestore: $groupId');
      }).catchError((e) {
        developer.log('⚠️ Failed to sync delete to Firestore: $e');
      }));

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
  Future<PurchaseGroup> addMember(
      String groupId, PurchaseGroupMember member) async {
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
  Future<PurchaseGroup> removeMember(
      String groupId, PurchaseGroupMember member) async {
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
  Future<PurchaseGroup> getOrCreateMemberPool() async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.getOrCreateMemberPool();
  }

  @override
  Future<void> syncMemberPool() async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.syncMemberPool();
  }

  @override
  Future<List<PurchaseGroupMember>> searchMembersInPool(String query) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.searchMembersInPool(query);
  }

  @override
  Future<PurchaseGroupMember?> findMemberByEmail(String email) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.findMemberByEmail(email);
  }

  @override
  Future<PurchaseGroup> setMemberId(
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
      final box = _ref.read(purchaseGroupBoxProvider);
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
