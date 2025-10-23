import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/data_version_service.dart';
import '../services/user_initialization_service.dart';
import '../widgets/data_migration_widget.dart';
import '../utils/app_logger.dart';
import '../providers/user_name_provider.dart';
import '../providers/purchase_group_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAppInitialization();
    });
  }

  /// アプリ全体の初期化処理を実行
  Future<void> _performAppInitialization() async {
    if (_isInitializing) return;

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

  /// ユーザー初期化サービスの開始
  Future<void> _initializeUserServices() async {
    try {
      final userInitService = ref.read(userInitializationServiceProvider);
      userInitService.startAuthStateListener();
      Log.info('✅ ユーザー初期化サービス開始');

      // ユーザー名プロバイダーの初期化を明示的に実行
      ref.invalidate(userNameProvider);
      Log.info('🔄 ユーザー名プロバイダーを初期化');

      // デフォルトグループの確認を確実に実行
      setState(() {
        _initializationStatus = 'グループ情報を準備中...';
      });

      // 少し待ってからデフォルトグループ確認
      await Future.delayed(const Duration(milliseconds: 300));

      // AllGroupsProviderを明示的に初期化してデフォルトグループを確認
      try {
        await ref.read(allGroupsProvider.future);
        Log.info('✅ グループ情報の初期化完了');
      } catch (e) {
        Log.warning('⚠️ グループ情報初期化エラー: $e');
      }
    } catch (e) {
      Log.error('❌ ユーザー初期化サービスエラー: $e');
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
              'Go Shop',
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
