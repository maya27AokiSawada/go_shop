import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/data_version_service.dart';
import '../services/user_initialization_service.dart';
import '../services/notification_service.dart';
import '../services/user_preferences_service.dart';
import '../services/user_specific_hive_service.dart';
import '../services/periodic_purchase_service.dart'; // 🆕 定期購入サービス
import '../widgets/data_migration_widget.dart';
import '../utils/app_logger.dart';
import '../helpers/user_id_change_helper.dart';
import '../flavors.dart';
import '../config/app_mode_config.dart';
import '../providers/user_settings_provider.dart';
import '../providers/shared_group_provider.dart'; // forceSyncProvider
import '../providers/hive_provider.dart';
import '../models/shared_group.dart';

/// アプリ初期化を管理するウィジェット
///
/// 以下の処理を統合管理:
/// - データマイグレーションチェック
/// - ユーザー初期化サービス開始
/// - ディープリンク初期化
/// - 初期化完了までのローディング表示
class AppInitializeWidget extends ConsumerStatefulWidget {
  final Widget child;

  const AppInitializeWidget({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppInitializeWidget> createState() =>
      _AppInitializeWidgetState();
}

class _AppInitializeWidgetState extends ConsumerState<AppInitializeWidget> {
  bool _isInitialized = false;
  bool _isInitializing = false;
  String _initializationStatus = 'アプリを準備中...';

  @override
  void initState() {
    super.initState();
    Log.info('🚀 [APP_INIT] AppInitializeWidget initState()');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAppInitialization();
    });

    // Firebase Auth状態の監視を開始
    Log.info('🔍 [APP_INIT] Flavor check: ${F.appFlavor}');
    if (F.appFlavor == Flavor.prod || F.appFlavor == Flavor.dev) {
      Log.info('🔍 [APP_INIT] Starting auth listener...');
      _startAuthListener();
    } else {
      Log.info('⚠️ [APP_INIT] Skipping auth listener (not prod/dev flavor)');
    }
  }

  /// Auth状態変化を監視してUID変更を検出
  void _startAuthListener() {
    Log.info('🔍 [UID_WATCH] Auth listener started');

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      Log.info('🔔 [UID_WATCH] Auth state changed: ${user?.uid ?? "null"}');

      if (user == null) {
        // ログアウト時 - UIDは保持（次回ログイン時に比較するため）
        Log.info('🔓 [UID_WATCH] ログアウト検出 - UIDは保持したままログアウト');
        return;
      }

      final currentUid = user.uid;
      final currentEmail = user.email ?? 'Unknown';
      Log.info('🔑 [UID_WATCH] Current UID: $currentUid, Email: $currentEmail');

      await UserIdChangeHelper.ensureUserContextReady(
        ref: ref,
        context: context,
        user: user,
        mounted: mounted,
      );
      Log.info('✅ [UID_WATCH] ユーザーコンテキスト確認完了: $currentUid');
    });
  }

  /// アプリ全体の初期化処理を実行
  Future<void> _performAppInitialization() async {
    if (_isInitializing) return;

    Log.info('🔄 [APP_INITIALIZE_WIDGET] _performAppInitialization() 開始');

    setState(() {
      _isInitializing = true;
      _initializationStatus = 'データをチェック中...';
    });

    try {
      Log.info('🚀 AppInitializeWidget: 初期化開始');

      // ステップ1: マイグレーションチェック
      await _checkAndHandleMigration();

      // ステップ2: ユーザー初期化サービス開始
      setState(() {
        _initializationStatus = 'ユーザー情報を準備中...';
      });
      await _initializeUserServices();

      // 初期化完了
      setState(() {
        _isInitialized = true;
        _initializationStatus = '準備完了';
      });

      Log.info('✅ AppInitializeWidget: 初期化完了');
    } catch (e) {
      Log.error('❌ AppInitializeWidget: 初期化エラー: $e');
      setState(() {
        _isInitialized = true; // エラーでも進行させる
        _initializationStatus = '初期化エラーが発生しましたが、続行します';
      });
    }
  }

  /// マイグレーションチェックと実行
  Future<void> _checkAndHandleMigration() async {
    try {
      final migrationNotifier = ref.read(dataMigrationProvider.notifier);
      final needsMigration = await migrationNotifier.checkMigrationNeeded();

      if (needsMigration && mounted) {
        Log.info('🔄 マイグレーションが必要です');

        // バージョン情報を取得
        final dataVersionService = DataVersionService();
        final oldVersion = await dataVersionService.getSavedVersionString();
        final newVersion = DataVersionService.currentVersionString;

        // マイグレーション画面をフルスクリーン表示
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DataMigrationWidget(
              oldVersion: oldVersion,
              newVersion: newVersion,
              onMigrationComplete: () {
                Navigator.of(context).pop();
              },
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );

        Log.info('✅ マイグレーション完了');
      } else {
        Log.info('ℹ️ マイグレーション不要');
      }
    } catch (e) {
      Log.error('❌ マイグレーションチェックエラー: $e');
      // エラーでも続行
    }
  }

  /// 最小限の初期化(基本サービスのみ)
  Future<void> _initializeUserServices() async {
    try {
      setState(() {
        _initializationStatus = 'サービス準備中...';
      });

      // Hive Boxを開く（UserSettingsにアクセスする前に必須）
      // Android/iOS/MacOSではinitializeForDefaultUserを使用
      try {
        await UserSpecificHiveService.instance.initializeForDefaultUser();
        Log.info('✅ Hive Box初期化完了（デフォルトユーザー）');
      } catch (e) {
        Log.error('❌ Hive Box初期化エラー: $e');
      }

      // AppMode初期化: UserSettingsからモードを読み込み
      try {
        final userSettings = await ref.read(userSettingsProvider.future);
        final appMode = AppMode.values[userSettings.appMode];
        AppModeSettings.setMode(appMode);
        Log.info('✅ AppMode初期化: ${appMode.name}');
      } catch (e) {
        Log.error('⚠️ AppMode初期化エラー: $e (デフォルトモード使用)');
        // エラー時はデフォルト(shopping)のまま
      }

      // 基本的なユーザー初期化サービスの開始のみ
      final userInitService = ref.read(userInitializationServiceProvider);
      userInitService.startAuthStateListener();

      // 通知リスナーを起動（認証済みの場合のみ）
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.startListening();

      // 🆕 未読グループ通知チェックと条件付きFirestore同期
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null &&
          (F.appFlavor == Flavor.prod || F.appFlavor == Flavor.dev)) {
        try {
          final groupBox = ref.read(SharedGroupBoxProvider);
          final needsColdStartRestore = groupBox.isEmpty;
          final hasGroupNotifications =
              await notificationService.hasUnreadGroupNotifications();

          if (hasGroupNotifications || needsColdStartRestore) {
            setState(() {
              _initializationStatus = 'グループデータを同期中...';
            });

            if (needsColdStartRestore) {
              Log.info('🚀 [APP_INIT] 認証済み cold start + ローカル空 → Firestore復元実行');
            } else {
              Log.info('🔔 [APP_INIT] グループ通知検出 → Firestore同期実行');
            }

            ref.invalidate(forceSyncProvider);
            await ref.read(forceSyncProvider.future);

            await ref
                .read(allGroupsProvider.notifier)
                .cleanupInvalidHiveGroups();
            await ref.read(allGroupsProvider.notifier).refresh();

            // 🔥 同期完了後に最終同期時刻を更新
            await notificationService.updateLastSyncTime();

            Log.info('✅ [APP_INIT] Firestore復元/同期完了');
          } else {
            Log.info('✅ [APP_INIT] 新規通知なし → Hiveデータ使用（同期スキップ）');
          }
        } catch (e) {
          Log.warning('⚠️ [APP_INIT] 通知チェックエラー（続行）: $e');
        }
      }

      // 🆕 定期購入アイテムの自動リセット（アプリ起動時）
      _resetPeriodicPurchaseItems();

      // 🔥 論理削除アイテムのクリーンアップは無効化（クラッシュ対策）
      // _cleanupDeletedItems();

      Log.info('✅ 基本初期化完了 - 各ページで必要な初期化を実行します');
    } catch (e) {
      Log.error('❌ 基本初期化エラー: $e');
      // エラーでも続行
    }
  }

  /// 定期購入アイテムの自動リセット（バックグラウンド処理）
  Future<void> _resetPeriodicPurchaseItems() async {
    try {
      // 5秒待機してからバックグラウンドで実行
      Future.delayed(const Duration(seconds: 5), () async {
        final periodicService = ref.read(periodicPurchaseServiceProvider);
        final resetCount = await periodicService.resetPeriodicPurchaseItems();
        Log.info('🔄 定期購入アイテムリセット完了: $resetCount 件');
      });
    } catch (e) {
      Log.error('❌ 定期購入リセットエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return widget.child;
  }

  /// 初期化中のローディング画面
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリアイコン（あれば）
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.shopping_bag,
                size: 48,
                color: Colors.blue[700],
              ),
            ),

            const SizedBox(height: 32),

            // プログレスインジケーター
            const CircularProgressIndicator(
              strokeWidth: 3,
            ),

            const SizedBox(height: 24),

            // ステータステキスト
            Text(
              _initializationStatus,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            // アプリ名
            const Text(
              'GoShopping',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
