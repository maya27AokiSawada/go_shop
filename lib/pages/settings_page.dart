import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_settings_provider.dart';
import '../providers/app_mode_notifier_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../services/user_preferences_service.dart';
import '../services/user_initialization_service.dart';
import '../services/access_control_service.dart';
import '../services/list_cleanup_service.dart';
import '../services/shopping_list_data_migration_service.dart';
import '../datastore/user_settings_repository.dart';
import '../widgets/test_scenario_widget.dart';
import '../debug/fix_maya_group.dart';
import '../config/app_mode_config.dart';
import '../utils/app_logger.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final userNameController = TextEditingController();
  bool _isSecretMode = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('SettingsPage初期化開始 - SharedPreferencesからユーザー名読み込み');

    // プロバイダーとは別に、直接SharedPreferencesから読み込みを実行
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          final userName = await UserPreferencesService.getUserName();
          if (userName != null && userName.isNotEmpty) {
            userNameController.text = userName;
            AppLogger.info('ユーザー名読み込み成功: $userName');
          } else {
            AppLogger.warning('ユーザー名が保存されていません');
          }

          // シークレットモード状態も読み込み
          final accessControl = ref.read(accessControlServiceProvider);
          final isSecretMode = await accessControl.isSecretModeEnabled();
          setState(() {
            _isSecretMode = isSecretMode;
          });
        } catch (e) {
          AppLogger.error('UserPreferences読み込みエラー', e);
        }
      }
    });
  }

  @override
  void dispose() {
    userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final syncStatus = ref.watch(firestoreSyncStatusProvider);

    return SafeArea(
      child: authState.when(
        data: (user) {
          final isAuthenticated = user != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ステータス表示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAuthenticated
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAuthenticated
                          ? Colors.green.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAuthenticated
                            ? Icons.check_circle
                            : Icons.account_circle,
                        color: isAuthenticated ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAuthenticated ? 'ログイン済み: ${user.email}' : '未ログイン状態',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isAuthenticated
                                ? Colors.green.shade800
                                : Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Firestore同期状態表示（サインイン済みの場合のみ）
                if (isAuthenticated && syncStatus != 'idle') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: syncStatus == 'syncing'
                          ? Colors.orange.shade50
                          : syncStatus == 'completed'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: syncStatus == 'syncing'
                            ? Colors.orange.shade200
                            : syncStatus == 'completed'
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          syncStatus == 'syncing'
                              ? Icons.sync
                              : syncStatus == 'completed'
                                  ? Icons.check_circle
                                  : Icons.error,
                          color: syncStatus == 'syncing'
                              ? Colors.orange
                              : syncStatus == 'completed'
                                  ? Colors.green
                                  : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncStatus == 'syncing'
                                ? 'Firestore同期中...'
                                : syncStatus == 'completed'
                                    ? 'Firestore同期完了'
                                    : 'Firestore同期エラー',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: syncStatus == 'syncing'
                                  ? Colors.orange.shade800
                                  : syncStatus == 'completed'
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                            ),
                          ),
                        ),
                        if (syncStatus == 'syncing')
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 20),

                // アプリモード切り替えパネル（常に表示）
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'アプリモード',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'アプリの表示モードを切り替えます',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, child) {
                          // appModeNotifierProviderを監視して現在のモードを取得
                          final currentMode =
                              ref.watch(appModeNotifierProvider);

                          return SegmentedButton<AppMode>(
                            segments: const [
                              ButtonSegment<AppMode>(
                                value: AppMode.shopping,
                                label: Text('買い物リスト'),
                                icon: Icon(Icons.shopping_cart, size: 16),
                              ),
                              ButtonSegment<AppMode>(
                                value: AppMode.todo,
                                label: Text('TODO共有'),
                                icon: Icon(Icons.task_alt, size: 16),
                              ),
                            ],
                            selected: {currentMode},
                            onSelectionChanged:
                                (Set<AppMode> newSelection) async {
                              final newMode = newSelection.first;

                              // UserSettingsに保存
                              final userSettingsAsync =
                                  await ref.read(userSettingsProvider.future);
                              final updatedSettings =
                                  userSettingsAsync.copyWith(
                                appMode: newMode.index,
                              );
                              final repository =
                                  ref.read(userSettingsRepositoryProvider);
                              await repository.saveSettings(updatedSettings);

                              // AppModeSettingsに反映
                              AppModeSettings.setMode(newMode);

                              // UIを更新（appModeNotifierProviderを使用）
                              ref.read(appModeNotifierProvider.notifier).state =
                                  newMode;

                              // SnackBar表示
                              if (context.mounted) {
                                final modeName = newMode == AppMode.shopping
                                    ? '買い物リスト'
                                    : 'TODO共有';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('モードを「$modeName」に変更しました'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // プライバシー設定パネル（認証済み時または開発環境で表示）
                if (isAuthenticated || true) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'プライバシー設定',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'シークレットモードをオンにすると、サインインが必要になります',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final accessControl =
                                ref.read(accessControlServiceProvider);
                            await accessControl.toggleSecretMode();
                            final newSecretMode =
                                await accessControl.isSecretModeEnabled();
                            setState(() {
                              _isSecretMode = newSecretMode;
                            });
                          },
                          icon: Icon(
                            _isSecretMode
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 16,
                          ),
                          label: Text(
                            _isSecretMode ? 'シークレットモード: ON' : 'シークレットモード: OFF',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSecretMode
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            foregroundColor: _isSecretMode
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 通知設定パネル（認証済み時のみ表示）
                if (isAuthenticated) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '通知設定',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'リスト変更通知の設定',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer(
                          builder: (context, ref, child) {
                            final userSettingsAsync =
                                ref.watch(userSettingsProvider);

                            return userSettingsAsync.when(
                              data: (userSettings) {
                                return SwitchListTile(
                                  title: const Text(
                                    'リスト変更通知',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  subtitle: const Text(
                                    'アイテムの追加・削除・購入完了を5分ごとに通知',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: userSettings.enableListNotifications,
                                  onChanged: (value) async {
                                    final repository = ref
                                        .read(userSettingsRepositoryProvider);
                                    final updatedSettings =
                                        userSettings.copyWith(
                                      enableListNotifications: value,
                                    );
                                    await repository
                                        .saveSettings(updatedSettings);

                                    // プロバイダーを更新
                                    ref.invalidate(userSettingsProvider);

                                    // SnackBar表示
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(value
                                              ? 'リスト変更通知をオンにしました'
                                              : 'リスト変更通知をオフにしました'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  activeThumbColor: Colors.amber.shade700,
                                  contentPadding: EdgeInsets.zero,
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) => Text(
                                'エラー: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 開発者ツールパネル（開発環境用）
                if (true) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.teal.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '開発者ツール',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Firebase認証とCRUD操作のテストシナリオを実行できます',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TestScenarioWidget(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_circle_filled,
                                    size: 16),
                                label: const Text(
                                  'テストシナリオ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade100,
                                  foregroundColor: Colors.teal.shade800,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FixMayaGroupScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.build, size: 16),
                                label: const Text(
                                  'グループ修正',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade100,
                                  foregroundColor: Colors.orange.shade800,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🆕 データメンテナンス
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cleaning_services,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'データメンテナンス',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '削除済みアイテムのクリーンアップ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '30日以上経過した削除済みアイテムを完全削除します',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _performCleanup();
                              },
                              icon: const Icon(Icons.delete_sweep, size: 18),
                              label: const Text('クリーンアップ実行'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade100,
                                foregroundColor: Colors.blue.shade800,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                          // 🆕 Firestore同期
                          Text(
                            'デフォルトグループのFirestore同期',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ローカルのみのデフォルトグループをクラウドに同期します',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _syncDefaultGroup();
                              },
                              icon: const Icon(Icons.cloud_upload, size: 18),
                              label: const Text('Firestore同期'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade100,
                                foregroundColor: Colors.green.shade800,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                          // 🆕 データ移行
                          Text(
                            'データ形式移行（開発者向け）',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '配列形式 → Map形式への移行（通常は自動実行）',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _checkMigrationStatus();
                                  },
                                  icon:
                                      const Icon(Icons.info_outline, size: 16),
                                  label: const Text('状況確認'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    foregroundColor: Colors.grey.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _performMigration();
                                  },
                                  icon: const Icon(Icons.sync, size: 16),
                                  label: const Text('移行実行'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade100,
                                    foregroundColor: Colors.orange.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 設定ページのコンテンツをここに追加予定
                Center(
                  child: Text(
                    '設定ページ（仮）',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // フッター情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.settings, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Go Shop 設定',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('認証状態を確認中...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'エラーが発生しました',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: $err',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ), // authState.when閉じ
    ); // SafeArea閉じ
  }

  /// クリーンアップ実行メソッド
  Future<void> _performCleanup() async {
    try {
      // 確認ダイアログ表示
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cleaning_services, color: Colors.blue),
              SizedBox(width: 8),
              Text('クリーンアップ確認'),
            ],
          ),
          content: const Text(
            '30日以上経過した削除済みアイテムを完全削除します。\nこの操作は取り消せません。\n\n実行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('実行'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('クリーンアップ中...'),
                ],
              ),
            ),
          ),
        ),
      );

      // クリーンアップ実行
      final cleanupService = ref.read(listCleanupServiceProvider);
      final cleanedCount = await cleanupService.cleanupAllLists(
        olderThanDays: 30,
        forceCleanup: false, // needsCleanup判定あり
      );

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                cleanedCount > 0 ? Icons.check_circle : Icons.info,
                color: cleanedCount > 0 ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('クリーンアップ完了'),
            ],
          ),
          content: Text(
            cleanedCount > 0
                ? '$cleanedCount個のアイテムを削除しました'
                : 'クリーンアップ対象のアイテムはありませんでした',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('クリーンアップエラー', e);

      // エラー時もローディングを閉じる
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('エラー'),
            ],
          ),
          content: Text('クリーンアップ中にエラーが発生しました\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// 🆕 デフォルトグループFirestore同期メソッド
  Future<void> _syncDefaultGroup() async {
    try {
      // 認証状態確認
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('認証が必要です'),
              ],
            ),
            content: const Text('Firestore同期にはサインインが必要です。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // 確認ダイアログ表示
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.green),
              SizedBox(width: 8),
              Text('Firestore同期確認'),
            ],
          ),
          content: const Text(
            'ローカルのみのデフォルトグループをFirestoreに同期します。\n同期後、他のデバイスからもアクセスできるようになります。\n\n実行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('実行'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Firestore同期中...'),
                ],
              ),
            ),
          ),
        ),
      );

      // 同期実行
      final allGroupsNotifier = ref.read(allGroupsProvider.notifier);
      final success = await allGroupsNotifier.syncDefaultGroupToFirestore(user);

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(success ? '同期完了' : '同期失敗'),
            ],
          ),
          content: Text(
            success
                ? 'デフォルトグループをFirestoreに同期しました。\n\nアプリを再起動すると、買い物リストもクラウドに保存されるようになります。'
                : '同期に失敗しました。ネットワーク接続を確認してください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('Firestore同期エラー', e);

      // エラー時もローディングを閉じる
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('同期エラー'),
            ],
          ),
          content: Text('エラーが発生しました:\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// 移行状況確認メソッド
  Future<void> _checkMigrationStatus() async {
    try {
      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('確認中...'),
                ],
              ),
            ),
          ),
        ),
      );

      final migrationService =
          ref.read(shoppingListDataMigrationServiceProvider);
      final status = await migrationService.checkMigrationStatus();

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('移行状況'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('総リスト数: ${status['total']}'),
              const SizedBox(height: 8),
              Text('移行済み: ${status['migrated']}',
                  style: const TextStyle(color: Colors.green)),
              Text('未移行: ${status['remaining']}',
                  style: TextStyle(
                      color: status['remaining']! > 0
                          ? Colors.orange
                          : Colors.grey)),
              const SizedBox(height: 12),
              Text(
                status['remaining']! > 0
                    ? '「移行実行」ボタンで移行してください'
                    : '全てのリストが移行済みです',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('移行状況確認エラー', e);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('エラー'),
            ],
          ),
          content: Text('移行状況確認中にエラーが発生しました\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// データ移行実行メソッド
  Future<void> _performMigration() async {
    try {
      // 確認ダイアログ表示
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('データ移行確認'),
            ],
          ),
          content: const Text(
            'データ形式を配列からMapに移行します。\n\nFirestoreにバックアップを作成してから実行しますが、念のためデータのエクスポートをお勧めします。\n\n実行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('実行'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('移行中...'),
                  SizedBox(height: 8),
                  Text(
                    'バックアップ作成 → データ変換 → 保存',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 移行実行
      final migrationService =
          ref.read(shoppingListDataMigrationServiceProvider);
      final migratedCount = await migrationService.migrateAllData();

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                migratedCount > 0 ? Icons.check_circle : Icons.info,
                color: migratedCount > 0 ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('移行完了'),
            ],
          ),
          content: Text(
            migratedCount > 0
                ? '$migratedCount個のリストを移行しました\n\nバックアップはFirestoreの\nusers/[uid]/backups に保存されています'
                : '移行対象のリストはありませんでした',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('データ移行エラー', e);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('エラー'),
            ],
          ),
          content: Text('データ移行中にエラーが発生しました\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
