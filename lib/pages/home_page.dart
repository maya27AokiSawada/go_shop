import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../services/user_initialization_service.dart';
import '../widgets/user_name_panel_widget.dart';
import '../widgets/news_and_ads_panel_widget.dart';
import '../utils/app_logger.dart';

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

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showEmailSignIn = false;

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

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      final userName = userNameController.text.trim();

      // まずサインイン試行
      try {
        await ref.read(authProvider).signIn(email, password);
        AppLogger.info('既存ユーザーでサインイン成功');
      } catch (e) {
        // サインイン失敗 → 新規登録を試行
        if (e.toString().contains('user-not-found') ||
            e.toString().contains('wrong-password') ||
            e.toString().contains('invalid-credential')) {
          AppLogger.info('ユーザーが存在しないため新規登録を試行');
          await ref.read(authProvider).signUp(email, password);
          AppLogger.info('新規ユーザー登録成功');
        } else {
          rethrow;
        }
      }

      // ユーザー名を保存
      if (userName.isNotEmpty) {
        await UserPreferencesService.saveUserName(userName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('ログインエラー', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ログインに失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSignInScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // アプリロゴ・タイトル
              const Icon(
                Icons.shopping_bag,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Go Shop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '買い物リスト共有アプリ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // プライバシー情報
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.privacy_tip,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'プライバシーについて',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPrivacyPoint('最初に共有される情報は、ログイン情報と表示名のみです'),
                    _buildPrivacyPoint('買い物リストは、あなたが共有したユーザーとのみ共有されます'),
                    _buildPrivacyPoint('グループに参加するユーザーも同じポリシーが適用されます'),
                    _buildPrivacyPoint('アプリの利用にはFirebaseアカウントが必須です'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // サインインボタン
              if (!_showEmailSignIn) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showEmailSignIn = true);
                  },
                  icon: const Icon(Icons.email, size: 20),
                  label: const Text('メールアドレスでログイン / 新規登録'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],

              // メール/パスワードフォーム
              if (_showEmailSignIn) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ユーザー名
                      TextFormField(
                        controller: userNameController,
                        decoration: InputDecoration(
                          labelText: '表示名（ニックネーム）',
                          hintText: '例: 太郎',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '表示名を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // メールアドレス
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'メールアドレス',
                          hintText: 'example@email.com',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'メールアドレスを入力してください';
                          }
                          if (!value.contains('@')) {
                            return '有効なメールアドレスを入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // パスワード
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'パスワード',
                          hintText: '6文字以上',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'パスワードを入力してください';
                          }
                          if (value.length < 6) {
                            return 'パスワードは6文字以上で入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ログインボタン
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithEmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('ログイン / 新規登録'),
                      ),
                      const SizedBox(height: 12),

                      // 戻るボタン
                      TextButton(
                        onPressed: () {
                          setState(() => _showEmailSignIn = false);
                        },
                        child: const Text('戻る'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // 注意事項
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '初めての方へ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'メールアドレスとパスワードでアカウント作成・ログインができます。\n'
                      '既にアカウントをお持ちの方は同じ情報でログインしてください。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
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

          // 認証済み - 元の画面を表示
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ステータス表示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ログイン済み: ${user.email}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Firestore同期ステータス
                if (syncStatus != 'idle') ...[
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

                // ニュース＆広告パネル
                const NewsAndAdsPanelWidget(),

                const SizedBox(height: 20),

                // ユーザー名パネル
                UserNamePanelWidget(userNameController: userNameController),

                const SizedBox(height: 20),

                // 案内メッセージ
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'アプリの使い方',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoPoint('画面下の「グループ」タブでグループを管理できます'),
                      _buildInfoPoint('グループを選択すると買い物リストが表示されます'),
                      _buildInfoPoint('QRコードで家族や友達を招待できます'),
                      _buildInfoPoint('「設定」タブでアプリの設定ができます'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ログアウトボタン
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(authProvider).signOut();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ログアウトしました'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ログアウトエラー: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('ログアウト'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
