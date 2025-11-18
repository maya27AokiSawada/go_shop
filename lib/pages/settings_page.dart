import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../services/user_initialization_service.dart';
import '../utils/app_logger.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final userNameController = TextEditingController();

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
}
