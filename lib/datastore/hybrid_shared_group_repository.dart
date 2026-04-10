import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // ValueNotifier用
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import '../models/shared_group.dart';
import '../datastore/shared_group_repository.dart';
import '../datastore/hive_shared_group_repository.dart';
import '../datastore/firestore_shared_group_repository.dart';
import '../providers/hive_provider.dart';
import '../providers/firestore_provider.dart';
import '../flavors.dart';
import '../utils/app_logger.dart';
import '../services/network_monitor_service.dart'; // Network monitoring

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
  // 🔥 CRITICAL: 初期値をtrueにして、初期化完了後に実際の状態を反映
  // 理由: 非同期初期化中にsyncStatusProviderが呼ばれるとfalseのままになる
  bool _isOnline = true;
  bool _isSyncing = false;

  // 🔔 同期状態の変更を通知するためのValueNotifier
  final ValueNotifier<bool> _isSyncingNotifier = ValueNotifier<bool>(false);

  // 外部から同期状態notifierを取得するためのgetter
  ValueNotifier<bool> get isSyncingNotifier => _isSyncingNotifier;

  // 同期キューとタイマー管理
  final List<_SyncOperation> _syncQueue = [];
  Timer? _syncTimer;

  // 🛡️ 本格的初期化状態管理
  InitializationStatus _initStatus = InitializationStatus.notStarted;
  bool _isInitialized = false;
  String? _initializationError;
  DateTime? _initStartTime;
  int _firestoreRetryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _initTimeout = Duration(seconds: 15);

  // 初期化進捗コールバック（UI表示用）
  Function(InitializationStatus, String?)? _onInitializationProgress;
  Future<void>? _firestoreInitializationFuture;
  Future<void>? _safeInitializationWaitFuture;

  HybridSharedGroupRepository(
    this._ref, {
    HiveSharedGroupRepository? hiveRepo,
    FirestoreSharedGroupRepository? firestoreRepo,
  }) {
    // テスト用: 外部から注入されたFirestoreリポジトリを使用
    if (firestoreRepo != null) {
      _firestoreRepo = firestoreRepo;
    }

    AppLogger.info('🆕 [HYBRID_REPO] HybridSharedGroupRepository安全初期化開始');
    AppLogger.info('🔍 [HYBRID_REPO] 現在のFlavor: ${F.appFlavor}');
    AppLogger.info('🔍 [HYBRID_REPO] Ref状態: ${_ref.runtimeType}');

    // コンストラクタでは絶対にクラッシュしない - Hiveのみ確実に初期化
    try {
      AppLogger.info('🔄 [HYBRID_REPO] HiveSharedGroupRepository作成開始...');
      _hiveRepo = hiveRepo ?? HiveSharedGroupRepository(_ref);
      AppLogger.info('✅ [HYBRID_REPO] HiveSharedGroupRepository初期化成功');
      AppLogger.info('🛡️ [HYBRID_REPO] 最低限の安全な動作環境確保完了 - Hiveで動作可能');
    } catch (e, stackTrace) {
      AppLogger.info('❌ [HYBRID_REPO] 致命的エラー: Hive初期化失敗 - システム継続不可');
      AppLogger.info('📄 [HYBRID_REPO] Error Type: ${e.runtimeType}');
      AppLogger.info('📄 [HYBRID_REPO] Error Message: $e');
      AppLogger.info('📄 [HYBRID_REPO] StackTrace: $stackTrace');
      rethrow; // Hive初期化失敗は真のクリティカルエラー
    }

    // Firestore初期化は非同期で安全に実行（クラッシュリスクゼロ）
    // 🔥 devモードでもFirestore初期化を実行（QR招待のため）
    // DI経由でfirestoreRepoが注入された場合は非同期初期化をスキップ（テスト用）
    if (firestoreRepo != null) {
      AppLogger.info('✅ [HYBRID_REPO] DI経由でFirestoreRepo注入済み - 非同期初期化スキップ');
      _isInitialized = true;
      _isOnline = true;
    } else {
      AppLogger.info(
          '🔄 [HYBRID_REPO] 非同期Firestore初期化をスケジュール (Flavor: ${F.appFlavor})');
      // 非同期で安全にFirestore初期化を試行
      _safeAsyncFirestoreInitialization();
    }
  }

  /// 同期状態を更新するヘルパーメソッド
  /// _isSyncingとValueNotifierを同期させる
  /// 🔥 syncStatusProviderを即座に再評価させるためprovider更新を呼び出し
  void _setSyncing(bool isSyncing) {
    _isSyncing = isSyncing;
    _isSyncingNotifier.value = isSyncing;
    AppLogger.info(
        '🔔 [HYBRID_REPO] 同期状態変更: $_isSyncing (ValueNotifier: ${_isSyncingNotifier.value})');

    // 🔥 isSyncingProviderを更新してsyncStatusProviderを再評価させる
    // これにより、UI側のアイコンが即座に更新される
    try {
      // shared_group_provider.dartからisSyncingProviderをインポートして使用
      // （注: 循環参照を避けるため、動的インポートまたは遅延評価が必要）
      // ここでは_refを使ってproviderを無効化
      // _ref.invalidate(isSyncingProvider);  // これは循環参照になる

      // 代わりに、ValueNotifierの変更自体がトリガーとなるように設計
      // UI側でValueListenableBuilderまたはChangeNotifierProviderを使用することを推奨
    } catch (e) {
      AppLogger.info('⚠️ [HYBRID_REPO] Provider更新失敗（無視）: $e');
    }
  }

  /// 完全にクラッシュ防止のFirestore初期化（非同期・安全）
  Future<void> _safeAsyncFirestoreInitialization() async {
    if (_firestoreRepo != null) {
      return;
    }

    final existingFuture = _firestoreInitializationFuture;
    if (existingFuture != null) {
      AppLogger.info('⚠️ [HYBRID_REPO] Firestore初期化既に進行中 - 完了待機');
      await existingFuture;
      return;
    }

    final initializationFuture = _performFirestoreInitialization();
    _firestoreInitializationFuture = initializationFuture;

    try {
      await initializationFuture;
    } finally {
      if (identical(_firestoreInitializationFuture, initializationFuture)) {
        _firestoreInitializationFuture = null;
      }
    }
  }

  bool _shouldRecoverFirestoreForAuthenticatedUser() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      return currentUser != null && _firestoreRepo == null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureFirestoreReadyForAuthenticatedUser() async {
    if (!_shouldRecoverFirestoreForAuthenticatedUser()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    AppLogger.info(
        '🔄 [HYBRID_REPO] 認証済みユーザーのFirestore再初期化開始: ${AppLogger.maskUserId(currentUser?.uid)}');

    await _safeAsyncFirestoreInitialization();

    if (_firestoreRepo != null) {
      AppLogger.info('✅ [HYBRID_REPO] 認証済みユーザーのFirestore再初期化完了');
    } else {
      AppLogger.warning('⚠️ [HYBRID_REPO] Firestore再初期化後もHiveのみモード継続');
    }
  }

  Future<void> _performFirestoreInitialization() async {
    AppLogger.info('🔄 [HYBRID_REPO] 安全なFirestore初期化開始...');

    try {
      // 🔐 認証状態チェック - 認証なしではFirestoreを使わない
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        AppLogger.info('⚠️ [HYBRID_REPO] 認証なし - Firestore同期スキップ（Hiveのみモード）');
        _firestoreRepo = null;
        // 🔥 FIX: 認証なしの場合でもtrueを維持（UIで「未ログイン」表示は別の判定）
        // _isOnlineはFirestoreへの接続可否を示し、認証状態は別途チェックする
        _isOnline = true; // ネットワーク自体は接続可能
        _isInitialized = true;
        _initializationError = 'No authentication - Hive only mode';
        return;
      }

      AppLogger.info('✅ [HYBRID_REPO] 認証確認: ${currentUser.uid}');

      // 複数層の安全網でFirestore初期化
      await Future.delayed(const Duration(milliseconds: 500)); // 安定化待機

      AppLogger.info('🔥 [HYBRID_REPO] FirestoreSharedGroupRepository作成試行...');
      final firestore = _ref.read(firestoreProvider);
      _firestoreRepo = FirestoreSharedGroupRepository(firestore);

      // 初期化後のヘルスチェック
      await Future.delayed(const Duration(milliseconds: 100));
      AppLogger.info('🌐 [HYBRID_REPO] Firestore統合有効化完了 - ハイブリッドモード開始');

      _isOnline = true;
      _isInitialized = true;
      _initializationError = null;
    } catch (e, stackTrace) {
      AppLogger.info('❌ [HYBRID_REPO] Firestore初期化エラー（安全にキャッチ）: $e');
      AppLogger.info('📄 [HYBRID_REPO] StackTrace: $stackTrace');

      _firestoreRepo = null;
      _isOnline = false;
      _isInitialized = true; // Hiveのみで初期化完了
      _initializationError = e.toString();

      AppLogger.info('🔧 [HYBRID_REPO] 安全フォールバック完了: Hiveのみで動作継続');
    } finally {
      AppLogger.info('✅ [HYBRID_REPO] 初期化プロセス完了 - システム動作準備OK');
    }
  }

  /// 初期化完了まで安全に待機（ローディングスピナー表示推奨）
  Future<void> waitForSafeInitialization() async {
    if (_isInitialized) {
      await _ensureFirestoreReadyForAuthenticatedUser();
      return;
    }

    final existingWaitFuture = _safeInitializationWaitFuture;
    if (existingWaitFuture != null) {
      await existingWaitFuture;
      return;
    }

    final waitFuture = _performSafeInitializationWait();
    _safeInitializationWaitFuture = waitFuture;

    try {
      await waitFuture;
    } finally {
      if (identical(_safeInitializationWaitFuture, waitFuture)) {
        _safeInitializationWaitFuture = null;
      }
    }
  }

  Future<void> _performSafeInitializationWait() async {
    _initStartTime = DateTime.now();
    _initStatus = InitializationStatus.initializingHive;
    _notifyProgress(InitializationStatus.initializingHive, 'Hive初期化中...');

    AppLogger.info('🚀 [HybridRepo] Safe initialization started');

    // Hive準備完了
    _initStatus = InitializationStatus.hiveReady;
    _notifyProgress(InitializationStatus.hiveReady, 'Hive準備完了');

    // Firestoreリトライ開始
    if (!_isInitialized) {
      unawaited(_attemptFirestoreInitializationWithRetry());
    }
    int attempts = 0;
    const maxAttempts = 30; // 15秒間待機（500ms × 30）

    while (!_isInitialized && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;

      final elapsed = DateTime.now().difference(_initStartTime!);
      if (elapsed >= _initTimeout) {
        AppLogger.info(
            '⏰ [HybridRepo] Initialization timeout (${_initTimeout.inSeconds}s)');
        _initStatus = InitializationStatus.hiveOnlyMode;
        _notifyProgress(
            InitializationStatus.hiveOnlyMode, 'タイムアウト - Hiveのみモード');
        break;
      }
    }

    if (!_isInitialized) {
      AppLogger.info('⚠️ [HYBRID_REPO] 初期化タイムアウト - Hiveのみで強制続行');
      _isInitialized = true;
      _isOnline = false;
      _firestoreRepo = null;
      _initStatus = InitializationStatus.hiveOnlyMode;
      _notifyProgress(
          InitializationStatus.hiveOnlyMode, 'タイムアウト - Hiveのみで強制続行');
    }

    final duration = DateTime.now().difference(_initStartTime!);
    AppLogger.info(
        '🎯 [HybridRepo] Safe initialization finished - Status: $_isInitialized, Duration: ${duration.inMilliseconds}ms');

    if (_initializationError != null) {
      AppLogger.info('ℹ️ [HYBRID_REPO] 初期化時エラー（回復済み）: $_initializationError');
    }

    await _ensureFirestoreReadyForAuthenticatedUser();
  }

  /// オンライン状態をチェック
  bool get isOnline => _isOnline;

  /// 同期状態をチェック
  bool get isSyncing => _isSyncing;

  /// アプリ終了時の同期処理
  Future<void> syncOnAppExit() async {
    AppLogger.info('🚪 [HYBRID_REPO] アプリ終了時同期開始');
    _syncTimer?.cancel();

    if (_syncQueue.isNotEmpty) {
      await _processSyncQueue();
    }

    AppLogger.info('👋 [HYBRID_REPO] アプリ終了時同期完了');
  }

  /// ローカル（Hive）のみからグループを取得（Firestore同期なし）
  Future<List<SharedGroup>> getLocalGroups() async {
    try {
      return await _hiveRepo.getAllGroups();
    } catch (e) {
      AppLogger.info('❌ getLocalGroups error: $e');
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
    AppLogger.info('✅ [HYBRID_REPO] 安全な初期化確認完了 - 全グループ取得続行');

    return await _getAllGroupsInternal();
  }

  /// 内部用：初期化待機なしでグループを取得
  Future<List<SharedGroup>> _getAllGroupsInternal() async {
    AppLogger.info(
        '🔍 [HYBRID] _getAllGroupsInternal開始 - Flavor: ${F.appFlavor}, Online: $_isOnline');
    try {
      // 🔥 サインイン必須仕様: Firestore優先
      if (_firestoreRepo != null) {
        try {
          AppLogger.info(
              '🔥 [HYBRID_REPO] Firestore優先モード - Firestoreから全グループ取得');
          AppLogger.info('🔥 [HYBRID] Firestore優先モード - 全グループ取得開始');

          // 1. Firestoreから取得（常に最新）
          final firestoreGroups = await _firestoreRepo!.getAllGroups();
          AppLogger.info(
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
          AppLogger.info('✅ [HYBRID_REPO] Hiveキャッシュ更新完了');
          AppLogger.info('✅ [HYBRID] Hiveキャッシュ更新完了');

          return firestoreGroups;
        } catch (e) {
          AppLogger.info('⚠️ [HYBRID_REPO] Firestore取得エラー、Hiveにフォールバック: $e');
          AppLogger.warning('⚠️ [HYBRID] Firestore取得エラー、Hiveにフォールバック: $e');

          // Firestoreエラー時のみHiveフォールバック
          final cachedGroups = await _hiveRepo.getAllGroups();
          AppLogger.info(
              '📦 [HYBRID] Hiveから${cachedGroups.length}グループ取得（フォールバック）');
          return cachedGroups;
        }
      }

      // dev環境またはFirestore未初期化の場合のみHive
      AppLogger.info('📦 [HYBRID_REPO] dev環境 - Hiveから取得');
      final cachedGroups = await _hiveRepo.getAllGroups();
      AppLogger.info('📦 [HYBRID] Hiveから${cachedGroups.length}グループ取得（dev環境）');
      for (var group in cachedGroups) {
        AppLogger.info(
            '  📦 [HIVE] ${AppLogger.maskGroup(group.groupName, group.groupId)} - allowedUid: ${group.allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()}');
      }

      return cachedGroups;
    } catch (e) {
      AppLogger.info('❌ [HYBRID_REPO] getAllGroups error: $e');
      AppLogger.error('❌ [HYBRID] getAllGroups error: $e');
      rethrow;
    }
  }

  /// UI使用専用：初期化を待たずに即座にHiveからグループを取得
  /// 通常のUI表示で使用する（長時間待機を避ける）
  Future<List<SharedGroup>> getAllGroupsForUI() async {
    AppLogger.info('🚀 [HYBRID_REPO] UI用グループ取得開始（初期化待機なし）');

    try {
      return await _getAllGroupsInternal();
    } catch (e) {
      AppLogger.info('❌ [HYBRID_REPO] UI用グループ取得エラー: $e');
      // エラー時は空リストを返す（UIクラッシュを防ぐ）
      return [];
    }
  }

  @override
  Future<SharedGroup> getGroupById(String groupId) async {
    // 🔥 サインイン必須仕様: Firestore優先
    if (_firestoreRepo != null) {
      try {
        developer
            .log('🔥 [HYBRID_REPO] Firestore優先モード - Firestoreから取得: $groupId');

        // 1. Firestoreから取得（常に最新）
        final firestoreGroup = await _firestoreRepo!.getGroupById(groupId);
        developer
            .log('✅ [HYBRID_REPO] Firestore取得完了: ${firestoreGroup.groupName}');

        // 2. Hiveにキャッシュ（次回の高速読み取りのため）
        await _hiveRepo.saveGroup(firestoreGroup);
        AppLogger.info('✅ [HYBRID_REPO] Hiveキャッシュ更新完了');

        return firestoreGroup;
      } catch (e) {
        AppLogger.info('⚠️ [HYBRID_REPO] Firestore取得エラー、Hiveにフォールバック: $e');
        // Firestoreエラー時のみHiveフォールバック
        return await _hiveRepo.getGroupById(groupId);
      }
    } else {
      // Firestore未初期化の場合のみHive
      AppLogger.info('📝 [HYBRID_REPO] Firestore未初期化 - Hiveから取得: $groupId');
      return await _hiveRepo.getGroupById(groupId);
    }
  }

  // =================================================================
  // 楽観的更新戦略: Optimistic Update with Conflict Resolution
  // =================================================================

  @override
  Future<SharedGroup> createGroup(
      String groupId, String groupName, SharedGroupMember member) async {
    AppLogger.info('🆕 [HYBRID_REPO] グループ作成開始: $groupName');

    // 🛡️ 安全な初期化完了を待機（ローディングスピナー表示推奨）
    await waitForSafeInitialization();
    AppLogger.info('✅ [HYBRID_REPO] 安全な初期化確認完了 - グループ作成続行');

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
      AppLogger.info(
          '🔍 [HYBRID_REPO] Flavor check: F.appFlavor = ${F.appFlavor}');
      AppLogger.info(
          '🔍 [HYBRID_REPO] Firestore repo check: _firestoreRepo = ${_firestoreRepo != null ? "initialized" : "NULL"}');

      if (_firestoreRepo != null) {
        AppLogger.info('🔥 [HYBRID_REPO] Firestore優先モード - Firestoreに作成');

        // 🔄 同期開始を通知
        _setSyncing(true);

        try {
          // 1. Firestoreに作成（Firestore SDKがオフライン時も即座にローカルキャッシュに書き込み）
          // 🔥 FIX: 10秒タイムアウトを追加（万が一Firestoreがハングした場合のセーフティネット）
          developer
              .log('🔥 [HYBRID_REPO] Calling _firestoreRepo!.createGroup()...');
          final newGroup = await _firestoreRepo!
              .createGroup(groupId, groupName, member)
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              AppLogger.warning(
                  '⏱️ [HYBRID_REPO] Firestore createGroup 10秒タイムアウト - Hiveフォールバック');
              throw TimeoutException('Firestore createGroup timeout');
            },
          );
          AppLogger.info('✅ [HYBRID_REPO] Firestore作成完了: $groupName');

          // 2. Hiveにキャッシュ（読み取り高速化のため）
          await _hiveRepo.saveGroup(newGroup);
          AppLogger.info('✅ [HYBRID_REPO] Hiveキャッシュ保存完了: $groupName');

          return newGroup;
        } catch (e) {
          // 🔥 FIX: Firestoreエラー/タイムアウト時はHiveフォールバックでユーザーをブロックしない
          AppLogger.warning('⚠️ [HYBRID_REPO] Firestore作成失敗、Hiveフォールバック: $e');
          final hiveGroup =
              await _hiveRepo.createGroup(groupId, groupName, member);
          AppLogger.info('✅ [HYBRID_REPO] Hiveフォールバック保存完了: $groupName');
          return hiveGroup;
        } finally {
          // 🔄 同期終了を通知
          _setSyncing(false);
        }
      } else {
        // dev環境またはFirestore未初期化の場合のみHive
        AppLogger.info('📝 [HYBRID_REPO] dev環境またはFirestore未初期化 - Hiveに作成');
        AppLogger.info(
            '🔍 [HYBRID_REPO] Reason: Flavor=${F.appFlavor}, _firestoreRepo=${_firestoreRepo != null ? "not null" : "NULL"}');
        final newGroup =
            await _hiveRepo.createGroup(groupId, groupName, member);
        AppLogger.info('✅ [HYBRID_REPO] Hive保存完了: $groupName');
        return newGroup;
      }
    } catch (e) {
      AppLogger.info('❌ [HYBRID_REPO] グループ作成エラー: $e');
      rethrow;
    }
  }

  // =================================================================
  // 同期キューとタイマー管理
  // =================================================================

  /// 同期タイマーをスケジュール（30秒後に再試行）
  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 30), () {
      AppLogger.info('⏰ [HYBRID_REPO] 定期同期開始');
      _processSyncQueue();
    });
  }

  /// 同期キューを処理
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty || _isSyncing) {
      return;
    }

    AppLogger.info('🔄 [HYBRID_REPO] 同期キュー処理開始: ${_syncQueue.length}件');
    _setSyncing(true);

    final failedOperations = <_SyncOperation>[];

    try {
      for (final operation in _syncQueue) {
        try {
          await _executeSyncOperation(operation);
          AppLogger.info(
              '✅ [HYBRID_REPO] 同期成功: ${operation.type} ${operation.groupId}');
        } catch (e) {
          AppLogger.error(
              '❌ [HYBRID_REPO] 同期失敗: ${operation.type} ${operation.groupId} - $e');

          // 再試行回数が3回未満なら再キュー
          if (operation.retryCount < 3) {
            failedOperations
                .add(operation.copyWith(retryCount: operation.retryCount + 1));
          } else {
            AppLogger.error(
                '💀 [HYBRID_REPO] 同期諦め（3回失敗）: ${operation.type} ${operation.groupId}');
          }
        }
      }
    } finally {
      _syncQueue.clear();
      _syncQueue.addAll(failedOperations);
      _setSyncing(false);

      // 失敗操作があれば再スケジュール
      if (failedOperations.isNotEmpty) {
        AppLogger.info(
            '🔄 [HYBRID_REPO] 失敗操作の再スケジュール: ${failedOperations.length}件');
        _scheduleSync();
      }
    }
  }

  /// 個別の同期操作を実行
  Future<void> _executeSyncOperation(_SyncOperation operation) async {
    if (_firestoreRepo == null) {
      throw Exception('Firestore repository not available');
    }

    try {
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
        case 'update':
          final group = operation.data['group'] as SharedGroup;
          await _firestoreRepo!.updateGroup(operation.groupId, group);

          final renameNotification =
              operation.data['renameNotification'] as Map<String, dynamic>?;
          if (renameNotification != null) {
            await _sendGroupRenameNotifications(
              group: group,
              oldName: renameNotification['oldName'] as String,
              newName: renameNotification['newName'] as String,
              renamerName: renameNotification['renamerName'] as String,
            );
          }
          break;
        default:
          throw Exception('Unknown sync operation: ${operation.type}');
      }
    } catch (e) {
      AppLogger.info('❌ Sync operation failed: $e');
      rethrow;
    }
  }

  @override
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group) async {
    try {
      AppLogger.info(
          '🔍 [HYBRID UPDATE] groupId: $groupId, allowedUid: ${group.allowedUid}');

      SharedGroup? previousGroup;
      try {
        previousGroup = await _hiveRepo.getGroupById(groupId);
      } catch (_) {
        previousGroup = null;
      }

      final isGroupRenamed =
          previousGroup != null && previousGroup.groupName != group.groupName;
      String renamerName = 'ユーザー';
      try {
        renamerName = FirebaseAuth.instance.currentUser?.displayName ??
            FirebaseAuth.instance.currentUser?.email ??
            'ユーザー';
      } catch (_) {}

      // 1. Hiveを即座に更新
      await _hiveRepo.saveGroup(group);
      AppLogger.info('✅ [HYBRID UPDATE] Hive保存完了');

      if (!_isOnline || _firestoreRepo == null) {
        AppLogger.info(
            '💡 [HYBRID UPDATE] Firestore同期スキップ (online=$_isOnline)');

        _syncQueue.add(
          _SyncOperation(
            type: 'update',
            groupId: groupId,
            data: {
              'group': group,
              if (isGroupRenamed)
                'renameNotification': {
                  'oldName': previousGroup.groupName,
                  'newName': group.groupName,
                  'renamerName': renamerName,
                },
            },
            timestamp: DateTime.now(),
          ),
        );
        _scheduleSync();
        return group;
      }

      AppLogger.info('🔥 [HYBRID UPDATE] Firestore同期開始...');

      // 🔄 同期開始を通知
      _setSyncing(true);

      // 2. Firestoreに同期（allowedUid更新の確実性のため完了を待つ）
      try {
        final updatedGroup = await _firestoreRepo!.updateGroup(groupId, group);
        AppLogger.info('✅ [HYBRID UPDATE] Firestore同期完了');

        if (isGroupRenamed) {
          await _sendGroupRenameNotifications(
            group: updatedGroup,
            oldName: previousGroup.groupName,
            newName: updatedGroup.groupName,
            renamerName: renamerName,
          );
        }

        // Firestoreで更新された場合、差分をHiveに反映
        if (updatedGroup.hashCode != group.hashCode) {
          await _hiveRepo.saveGroup(updatedGroup);
          AppLogger.info('🔄 Firestore changes synced back to cache');
        }
        return updatedGroup;
      } catch (e) {
        AppLogger.info('⚠️ [HYBRID UPDATE] Firestore同期失敗: $e');
        _syncQueue.add(
          _SyncOperation(
            type: 'update',
            groupId: groupId,
            data: {
              'group': group,
              if (isGroupRenamed)
                'renameNotification': {
                  'oldName': previousGroup.groupName,
                  'newName': group.groupName,
                  'renamerName': renamerName,
                },
            },
            timestamp: DateTime.now(),
          ),
        );
        _scheduleSync();
        // Hiveは既に保存済みなので継続
        return group;
      } finally {
        // 🔄 同期終了を通知
        _setSyncing(false);
      }
    } catch (e) {
      AppLogger.info('❌ updateGroup error: $e');
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
      Log.info('  - _isOnline: $_isOnline');
      Log.info(
          '  - _firestoreRepo: ${_firestoreRepo != null ? "初期化済み" : "null"}');

      if (!_isOnline || _firestoreRepo == null) {
        Log.warning('⚠️ [DELETE] Firestore削除スキップ (条件未満たず)');
        return deletedGroup;
      }

      // 2. Firestoreから同期削除（メンバープール以外のみ）
      // 削除操作は確実に完了させるため、awaitで待つ
      Log.info('🔥 [DELETE] Firestore削除実行開始: $groupId');

      // 🔄 同期開始を通知
      _setSyncing(true);

      try {
        await _firestoreRepo!.deleteGroup(groupId);
        Log.info('✅ [DELETE] Firestore削除完了: $groupId');
      } catch (e) {
        Log.error('❌ [DELETE] Firestore削除失敗: $e');
        // Firestoreへの削除が失敗してもHive削除は完了しているので処理継続
      } finally {
        // 🔄 同期終了を通知
        _setSyncing(false);
      }

      return deletedGroup;
    } catch (e) {
      AppLogger.info('❌ deleteGroup error: $e');
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
          AppLogger.info('🔄 AddMember synced to Firestore');
        }).catchError((e) {
          AppLogger.info('⚠️ Failed to sync addMember to Firestore: $e');
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
          AppLogger.info('🔄 RemoveMember synced to Firestore');
        }).catchError((e) {
          AppLogger.info('⚠️ Failed to sync removeMember to Firestore: $e');
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
    AppLogger.info('🧹 [HYBRID_REPO] Delegating cleanup to Hive repository');
    return await _hiveRepo.cleanupDeletedGroups();
  }

  @override
  Future<SharedGroup> setMemberId(
      String oldId, String newId, String? contact) async {
    try {
      final updatedGroup = await _hiveRepo.setMemberId(oldId, newId, contact);

      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        _unawaited(_firestoreRepo!.setMemberId(oldId, newId, contact).then((_) {
          AppLogger.info('🔄 SetMemberId synced to Firestore');
        }).catchError((e) {
          AppLogger.info('⚠️ Failed to sync setMemberId to Firestore: $e');
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

  /// Fire-and-forget 非同期実行
  void _unawaited(Future<void> operation) {
    operation.catchError((e) {
      AppLogger.info('⚠️ Unawaited operation failed: $e');
    });
  }

  /// updatedAt の比較。
  ///
  /// 戻り値:
  /// - `> 0`: left の方が新しい
  /// - `< 0`: right の方が新しい
  /// - `0`: 同一または比較不能
  int _compareUpdatedAt(DateTime? left, DateTime? right) {
    if (left == null && right == null) return 0;
    if (left != null && right == null) return 1;
    if (left == null && right != null) return -1;

    return left!.compareTo(right!);
  }

  // =================================================================
  // 手動同期・管理機能
  // =================================================================

  /// 手動でFirestoreからフル同期
  Future<void> forceSyncFromFirestore() async {
    // 🔥 FIX 8: サインイン後にFirestore未初期化の場合、Fix 7の再初期化ロジックを発動
    await waitForSafeInitialization();
    await _ensureFirestoreReadyForAuthenticatedUser();

    if (_firestoreRepo == null) {
      AppLogger.info('🔧 Force sync skipped - Firestore not initialized');
      return;
    }

    try {
      _setSyncing(true);
      final firestoreGroups = await _firestoreRepo!
          .getAllGroups()
          .timeout(const Duration(seconds: 10));

      // すべてのFirestoreデータでHiveを更新
      for (final group in firestoreGroups) {
        await _hiveRepo.saveGroup(group);
      }

      AppLogger.info(
          '✅ Force sync completed: ${firestoreGroups.length} groups');
      _isOnline = true;
    } on TimeoutException catch (e) {
      AppLogger.info('⏱️ Force sync timeout: $e');
      _isOnline = false;
      final networkMonitor = _ref.read(networkMonitorProvider);
      if (networkMonitor.currentStatus == NetworkStatus.online) {
        AppLogger.info('🔍 Checking Firestore connection after timeout');
        networkMonitor.checkFirestoreConnection();
        networkMonitor.startAutoRetry();
      }
      rethrow;
    } catch (e) {
      AppLogger.info('❌ Force sync failed: $e');
      _isOnline = false;
      rethrow;
    } finally {
      _setSyncing(false);
    }
  }

  /// 未同期のローカル変更をFirestoreにプッシュ
  Future<void> pushLocalChangesToFirestore() async {
    if (_firestoreRepo == null) return;

    try {
      final localGroups = await _hiveRepo.getAllGroups();

      for (final group in localGroups) {
        try {
          SharedGroup? firestoreGroup;

          try {
            firestoreGroup = await _firestoreRepo!
                .getGroupById(group.groupId)
                .timeout(const Duration(seconds: 10));
          } catch (_) {
            firestoreGroup = null;
          }

          if (firestoreGroup == null) {
            await _firestoreRepo!
                .updateGroup(group.groupId, group)
                .timeout(const Duration(seconds: 10));
            AppLogger.info('📤 Firestore未存在のためpush: ${group.groupName}');
            continue;
          }

          if (firestoreGroup.isDeleted) {
            await _hiveRepo.saveGroup(firestoreGroup);
            AppLogger.info('🪦 Firestoreで削除済みのためHiveへ削除反映: ${group.groupName}');
            continue;
          }

          final timestampComparison =
              _compareUpdatedAt(group.updatedAt, firestoreGroup.updatedAt);

          if (timestampComparison > 0) {
            await _firestoreRepo!
                .updateGroup(group.groupId, group)
                .timeout(const Duration(seconds: 10));
            AppLogger.info('📤 Hiveの方が新しいためpush: ${group.groupName}');
            continue;
          }

          if (timestampComparison < 0) {
            await _hiveRepo.saveGroup(firestoreGroup);
            AppLogger.info('📥 Firestoreの方が新しいためHiveへ反映: ${group.groupName}');
            continue;
          }

          AppLogger.info('ℹ️ 同期不要: ${group.groupName}');
        } on TimeoutException catch (e) {
          AppLogger.info('⏱️ Push timeout for ${group.groupName}: $e');
          final networkMonitor = _ref.read(networkMonitorProvider);
          if (networkMonitor.currentStatus == NetworkStatus.online) {
            AppLogger.info('🔍 Checking Firestore connection after timeout');
            networkMonitor.checkFirestoreConnection();
            networkMonitor.startAutoRetry();
          }
        } catch (e) {
          AppLogger.info('⚠️ Failed to push ${group.groupName}: $e');
        }
      }
    } catch (e) {
      AppLogger.info('❌ Push operation failed: $e');
      rethrow;
    }
  }

  /// キャッシュクリア
  Future<void> clearCache() async {
    try {
      final box = _ref.read(SharedGroupBoxProvider);
      await box.clear();
      AppLogger.info('🗑️ Cache cleared');
    } catch (e) {
      AppLogger.info('❌ Failed to clear cache: $e');
      rethrow;
    }
  }

  /// 接続状態を設定（テスト用）
  void setOnlineStatus(bool online) {
    _isOnline = online;
    AppLogger.info('🌐 Online status set to: $online');
  }

  /// Firestoreから強制的に同期してHiveを更新
  /// Firebase認証済みユーザーのデータ復旧時に使用
  Future<void> syncFromFirestore() async {
    // 🔥 FIX 8: サインイン後にFirestore未初期化の場合、Fix 7の再初期化ロジックを発動
    await waitForSafeInitialization();
    await _ensureFirestoreReadyForAuthenticatedUser();

    if (!_isOnline || _firestoreRepo == null) {
      AppLogger.info('💡 Firestore同期スキップ (オフライン)');
      return;
    }

    if (_isSyncing) {
      AppLogger.info('⏳ 既に同期処理中...');
      return;
    }

    _setSyncing(true);

    try {
      AppLogger.info('🔄 Firestoreからの強制同期開始...');

      // Firestoreからすべてのグループを取得
      final firestoreGroups = await _firestoreRepo!
          .getAllGroups()
          .timeout(const Duration(seconds: 10));
      AppLogger.info('📥 Firestoreから${firestoreGroups.length}グループを取得');

      // ✅ Firestoreからグループが取得できた場合のみ、Hiveをクリアして更新
      if (firestoreGroups.isNotEmpty) {
        AppLogger.info('✅ Firestore からグループを取得しました。Hive を更新します...');

        // Hiveを完全にクリア
        await clearCache();

        // FirestoreデータをすべてHiveに保存
        for (final group in firestoreGroups) {
          await _hiveRepo.saveGroup(group);
        }

        AppLogger.info('✅ Firestore→Hive同期完了 (${firestoreGroups.length}グループ)');
      } else {
        AppLogger.info('⚠️ Firestore からグループが取得できませんでした。Hive はクリアしません。');
        AppLogger.info('💡 考えられる原因: ユーザーがグループに属していない、セキュリティルール制限、認証エラー等');
      }
    } on TimeoutException catch (e) {
      AppLogger.info('⏱️ Firestore同期タイムアウト: $e');
      final networkMonitor = _ref.read(networkMonitorProvider);
      if (networkMonitor.currentStatus == NetworkStatus.online) {
        AppLogger.info('🔍 Checking Firestore connection after timeout');
        networkMonitor.checkFirestoreConnection();
        networkMonitor.startAutoRetry();
      }
      rethrow;
    } catch (e) {
      AppLogger.info('❌ Firestore同期エラー: $e');
      AppLogger.info('💡 エラーの詳細: ${e.toString()}');
      rethrow;
    } finally {
      _setSyncing(false);
    }
  }

  Future<void> _sendGroupRenameNotifications({
    required SharedGroup group,
    required String oldName,
    required String newName,
    required String renamerName,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppLogger.info('⚠️ [HYBRID UPDATE] 認証なし - グループ名変更通知スキップ');
      return;
    }

    final firestore = _ref.read(firestoreProvider);
    final memberIds = group.members
            ?.map((member) => member.memberId)
            .where((memberId) => memberId.isNotEmpty)
            .toSet()
            .toList() ??
        <String>[];

    if (memberIds.isEmpty) {
      AppLogger.info('⚠️ [HYBRID UPDATE] 通知対象メンバーなし - グループ名変更通知スキップ');
      return;
    }

    AppLogger.info('✏️ [HYBRID UPDATE] グループ名変更通知送信開始: $oldName → $newName');

    for (final memberId in memberIds) {
      await firestore.collection('notifications').add({
        'userId': memberId,
        'type': 'group_updated',
        'groupId': group.groupId,
        'message': '$renamerName が「$oldName」を「$newName」に変更しました',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? currentUser.email ?? 'Unknown',
        'metadata': {
          'oldGroupName': oldName,
          'newGroupName': newName,
          'renamerName': renamerName,
        },
      });
    }

    AppLogger.info('✅ [HYBRID UPDATE] グループ名変更通知送信完了: ${memberIds.length}件');
  }

  /// 📊 初期化進行状況の通知
  void _notifyProgress(InitializationStatus status, String? message) {
    _initStatus = status;
    _onInitializationProgress?.call(status, message);
    AppLogger.info('📊 [HybridRepo] Status: $status - $message');
  }

  /// 🔄 リトライ付きFirestore初期化
  Future<void> _attemptFirestoreInitializationWithRetry() async {
    _firestoreRetryCount = 0;

    while (_firestoreRetryCount < _maxRetries) {
      _firestoreRetryCount++;

      try {
        _notifyProgress(InitializationStatus.initializingFirestore,
            'Firestore接続試行 $_firestoreRetryCount/$_maxRetries');

        await _safeAsyncFirestoreInitialization();

        if (_firestoreRepo != null) {
          _notifyProgress(InitializationStatus.fullyReady, 'Firestore接続完了');
          return;
        }
      } catch (e) {
        AppLogger.error(
            '🔄 [HybridRepo] Firestore retry $_firestoreRetryCount/$_maxRetries failed: $e');
      }

      if (_firestoreRetryCount < _maxRetries) {
        // 指数バックオフ: 1秒, 2秒, 4秒
        final delay =
            Duration(seconds: math.pow(2, _firestoreRetryCount - 1).toInt());
        await Future.delayed(delay);
      }
    }

    // 全リトライ失敗
    _notifyProgress(
        InitializationStatus.hiveOnlyMode, 'Firestore接続失敗 - Hiveのみモード');
    AppLogger.error(
        '❌ [HybridRepo] All Firestore retries failed, falling back to Hive-only');
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
