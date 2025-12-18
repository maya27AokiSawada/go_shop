import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../widgets/auth_panel_widget.dart';
import '../widgets/user_name_panel_widget.dart';
import '../widgets/news_and_ads_panel_widget.dart';
import '../services/user_initialization_service.dart';
import '../utils/app_logger.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final bool _isPasswordVisible = false;
  bool _isLoading = false;
  final bool _showEmailSignIn = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('HomePage初期化開始');
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signInWithGoogle();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Googleアカウントでログインしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログインエラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = ref.read(authProviderProvider.notifier);
      await authProvider.performSignIn(
        emailController.text.trim(),
        passwordController.text,
        userNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログインエラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final syncStatus = ref.watch(firestoreSyncStatusProvider);

    return SafeArea(
      child: authState.when(
        data: (user) {
          final isAuthenticated = user != null;

          // 未認証時はサインイン画面を表示
          if (!isAuthenticated) {
            return _buildSignInScreen();
          }

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

                // 1. ニュース＆広告パネル（常に表示、認証状態で内容変更）
                const NewsAndAdsPanelWidget(),

                const SizedBox(height: 20),

                // 2. ユーザー名パネル（常に表示）
                UserNamePanelWidget(
                  userNameController: userNameController,
                  onSaveSuccess: () {
                    AppLogger.info('ユーザー名保存成功');
                  },
                ),

                const SizedBox(height: 20),

                // 3. サインインパネル（未認証時のみ表示）
                if (!isAuthenticated) ...[
                  AuthPanelWidget(
                    userNameController: userNameController,
                    onAuthSuccess: () {
                      // 認証成功時の処理
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 20),

                // 6. サインアウトボタン（認証済み時のみ表示）
                if (isAuthenticated) ...[
                  // サインアウトボタンもコンパクトに
                  ElevatedButton.icon(
                    onPressed: () async {
                      // 確認ダイアログを表示
                      final shouldSignOut = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('ログアウト確認'),
                          content: const Text('ログアウトしますか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('ログアウト'),
                            ),
                          ],
                        ),
                      );

                      if (shouldSignOut == true) {
                        await ref.read(authProvider).signOut();
                      }
                    },
                    icon: const Icon(Icons.logout, size: 16), // アイコンサイズを小さく
                    label: const Text('ログアウト',
                        style: TextStyle(fontSize: 14)), // テキストサイズを明示的に指定
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade800,
                      // コンパクトなパディング
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      // ボタンの最小サイズを小さく
                      minimumSize: const Size(0, 36),
                      // テキストに合わせてボタンサイズを調整
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // フッター情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Go Shop - モジュラー設計による買い物リスト共有アプリ',
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
                Text(
                  'Error: $err',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
