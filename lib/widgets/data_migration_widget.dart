import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../services/data_version_service.dart';
import '../services/user_preferences_service.dart';
import '../services/firestore_migration_service.dart';
import '../helpers/ui_helper.dart';

/// データマイグレーションウィジェット
///
/// プリファレンスに保存されているデータバージョンと
/// 起動したアプリのデータバージョンが異なる場合に表示される
///
/// 【現在の機能】：Hive + Firestore削除 + 新規作成のみ
/// 【将来予定】：段階的データマイグレーション機能
class DataMigrationWidget extends ConsumerStatefulWidget {
  final VoidCallback onMigrationComplete;
  final String? oldVersion;
  final String? newVersion;

  const DataMigrationWidget({
    Key? key,
    required this.onMigrationComplete,
    this.oldVersion,
    this.newVersion,
  }) : super(key: key);

  @override
  ConsumerState<DataMigrationWidget> createState() =>
      _DataMigrationWidgetState();
}

class _DataMigrationWidgetState extends ConsumerState<DataMigrationWidget>
    with TickerProviderStateMixin {
  bool _isMigrating = false;
  bool _migrationComplete = false;
  String _currentStep = '';
  // ignore: unused_field
  double _progress = 0.0;

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// データマイグレーション実行
  Future<void> _performMigration() async {
    if (_isMigrating) return;

    setState(() {
      _isMigrating = true;
      _progress = 0.0;
      _currentStep = '準備中...';
    });

    try {
      Log.info('🔄 データマイグレーション開始');

      // ステップ1: バックアップ（将来用）
      await _updateProgress(0.1, 'データのバックアップ準備中...');
      await Future.delayed(const Duration(milliseconds: 500));

      // ステップ2: Firestoreデータマイグレーション（v2 → v3）
      await _updateProgress(0.2, 'Firestoreデータ構造をアップグレード中...');
      final firestoreMigration = FirestoreDataMigrationService();
      try {
        await firestoreMigration.migrateToVersion3();
        Log.info('✅ Firestoreマイグレーション完了');
      } catch (e) {
        Log.error('⚠️ Firestoreマイグレーション警告: $e (続行します)');
        // Firestoreマイグレーションエラーは続行可能
      }

      // ステップ3: Hiveデータ削除
      await _updateProgress(0.5, 'ローカルデータベースを削除中...');
      final dataVersionService = DataVersionService();
      await dataVersionService.checkAndMigrateData();

      // ステップ4: クラウドデータ整理完了
      await _updateProgress(0.7, 'クラウドデータの整理完了...');
      await Future.delayed(const Duration(milliseconds: 500));

      // ステップ5: ユーザー設定クリア
      await _updateProgress(0.8, 'ユーザー設定を初期化中...');
      await UserPreferencesService.clearAllUserInfo();

      // ステップ6: 新バージョン設定
      await _updateProgress(0.9, '新しいデータ形式で初期化中...');
      await UserPreferencesService.saveDataVersion(
          DataVersionService.currentDataVersion);

      // 完了
      await _updateProgress(1.0, 'マイグレーション完了！');

      setState(() {
        _migrationComplete = true;
      });

      Log.info('✅ データマイグレーション完了');

      // 少し待ってから完了コールバック
      await Future.delayed(const Duration(milliseconds: 1000));
      widget.onMigrationComplete();
    } catch (e) {
      Log.error('❌ データマイグレーションエラー: $e');
      setState(() {
        _isMigrating = false;
        _currentStep = 'エラーが発生しました';
      });

      if (mounted) {
        UiHelper.showErrorMessage(
          context,
          'データマイグレーションに失敗しました: $e',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  /// 進捗更新
  Future<void> _updateProgress(double progress, String step) async {
    if (!mounted) return;

    setState(() {
      _progress = progress;
      _currentStep = step;
    });

    _animationController.animateTo(progress);

    // UIの更新を待つ
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // バックボタンを無効化
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            // 🔥 タブレットランドスケープモード対応: スクロール可能にする
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // アイコン
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _migrationComplete
                          ? Colors.green[100]
                          : Colors.blue[100],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      _migrationComplete ? Icons.check_circle : Icons.upgrade,
                      size: 48,
                      color: _migrationComplete
                          ? Colors.green[700]
                          : Colors.blue[700],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // タイトル
                  Text(
                    _migrationComplete ? 'アップデート完了' : 'データアップデート',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // バージョン情報
                  if (widget.oldVersion != null &&
                      widget.newVersion != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'v${widget.oldVersion} → v${widget.newVersion}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 説明文
                  Text(
                    _migrationComplete
                        ? 'Firestoreデータ構造のアップデートが完了しました。\n新しい効率的なデータ構造により、\nより高速にグループデータを取得できます。'
                        : 'Firestoreデータ構造が改善されました。\n\n【改善内容】\n• より効率的なグループデータ取得\n• メンバーシップ管理の最適化\n• データ整合性の向上\n\nアップデートを開始してください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 進捗表示
                  if (_isMigrating) ...[
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[600]!,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentStep,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_progressAnimation.value * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ] else if (!_migrationComplete) ...[
                    // 開始ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _performMigration,
                        icon: const Icon(Icons.upgrade),
                        label: const Text('データを更新する'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 注意書き
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        border: Border.all(color: Colors.amber[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '現在のデータは削除され、\n新しい形式で初期化されます',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber[800],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 完了ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onMigrationComplete,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('アプリを開始'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ), // SingleChildScrollView
          ),
        ),
      ),
    );
  }
}

/// データマイグレーション状態プロバイダー
class DataMigrationNotifier extends StateNotifier<bool> {
  DataMigrationNotifier() : super(false);

  /// マイグレーションが必要かチェック
  Future<bool> checkMigrationNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('data_version')) {
        await UserPreferencesService.saveDataVersion(
            DataVersionService.currentDataVersion);
        Log.info('🆕 data_version未保存のため現在バージョンを保存して終了');
        state = false;
        return false;
      }

      final savedVersion = await UserPreferencesService.getDataVersion();
      final currentVersion = DataVersionService.currentDataVersion;

      Log.info('🔍 マイグレーションチェック: 保存済み=$savedVersion, 現在=$currentVersion');

      final needsMigration = savedVersion != currentVersion;
      state = needsMigration;

      return needsMigration;
    } catch (e) {
      Log.error('❌ マイグレーションチェックエラー: $e');
      return false;
    }
  }

  /// マイグレーション完了
  void completeMigration() {
    state = false;
  }
}

final dataMigrationProvider =
    StateNotifierProvider<DataMigrationNotifier, bool>((ref) {
  return DataMigrationNotifier();
});
