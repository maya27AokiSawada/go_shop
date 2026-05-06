import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../utils/app_logger.dart';
import '../l10n/l10n.dart';

// 保存されたメールアドレスを取得するプロバイダ
final savedEmailProvider = FutureProvider<String?>((ref) async {
  final savedEmail = await UserPreferencesService.getSavedEmailForSignIn();
  return savedEmail;
});

// 保存されたユーザー名を取得するプロバイダ
final savedUserNameProvider = FutureProvider<String?>((ref) async {
  final savedUserName = await UserPreferencesService.getUserName();
  return savedUserName;
});

/// サインイン・サインアップのパネルウィジェット
class AuthPanelWidget extends ConsumerStatefulWidget {
  /// 認証成功時のコールバック
  final VoidCallback? onAuthSuccess;

  /// ユーザー名コントローラー（親から渡される）
  final TextEditingController? userNameController;

  const AuthPanelWidget({
    super.key,
    this.onAuthSuccess,
    this.userNameController,
  });

  @override
  ConsumerState<AuthPanelWidget> createState() => _AuthPanelWidgetState();
}

class _AuthPanelWidgetState extends ConsumerState<AuthPanelWidget> {
  late final TextEditingController userNameController;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool showSignInForm = false;
  bool _isPasswordVisible = false;
  bool _isPasswordResetLoading = false;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    // 親からコントローラーが渡されている場合はそれを使用、なければ新規作成
    userNameController = widget.userNameController ?? TextEditingController();
    _loadSavedData();
  }

  @override
  void dispose() {
    // 親から渡されていない場合のみdispose
    if (widget.userNameController == null) {
      userNameController.dispose();
    }
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// 保存されたメールアドレスとユーザー名を読み込む（初期化用）
  Future<void> _loadSavedData() async {
    try {
      // ユーザー名を読み込む（コントローラーが空の場合のみ）
      if (userNameController.text.isEmpty) {
        final savedUserName = await UserPreferencesService.getUserName();
        if (savedUserName != null && savedUserName.isNotEmpty && mounted) {
          userNameController.text = savedUserName;
          AppLogger.info(
              '👤 AuthPanel: 保存されたユーザー名を設定: ${AppLogger.maskName(savedUserName)}');
        }
      } else {
        AppLogger.info(
            '👤 AuthPanel: 親からユーザー名が渡されています: ${userNameController.text}');
      }

      // メールアドレスを読み込む
      final savedEmail = await UserPreferencesService.getSavedEmailForSignIn();
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        emailController.text = savedEmail;
        setState(() {
          _rememberEmail = true;
        });
        AppLogger.info('📧 AuthPanel: 保存されたメールアドレスを設定: $savedEmail');
      }
    } catch (e) {
      AppLogger.error('❌ AuthPanel: 保存データ読み込みエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.login, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'ログイン・新規登録',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'メールアドレスとパスワードでアカウント作成・ログイン',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // サインインフォーム表示切り替えボタン
              if (!showSignInForm) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showSignInForm = true;
                    });
                  },
                  icon: const Icon(Icons.login),
                  label: Text(texts.loginOrRegister),
                ),
              ],

              // メール/パスワード入力フォーム
              if (showSignInForm) ...[
                // ユーザー名入力フィールド
                TextFormField(
                  controller: userNameController,
                  decoration: const InputDecoration(
                    labelText: 'ユーザー名',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    hintText: 'お名前（ニックネーム）',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ユーザー名を入力してください';
                    }
                    if (value.isEmpty) {
                      return 'ユーザー名は1文字以上で入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!value.contains('@')) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    border: const OutlineInputBorder(),
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
                      tooltip: _isPasswordVisible ? 'パスワードを隠す' : 'パスワードを表示',
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
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
                const SizedBox(height: 8),

                // メールアドレス保存チェックボックス
                CheckboxListTile(
                  value: _rememberEmail,
                  onChanged: (value) {
                    setState(() {
                      _rememberEmail = value ?? false;
                    });
                  },
                  title: Text(texts.saveEmail),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 16),

                // サインイン・サインアップボタン
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await ref.read(authProvider).performSignIn(
                                  context: context,
                                  ref: ref,
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                  emailController: emailController,
                                  passwordController: passwordController,
                                  userNameController: userNameController,
                                  rememberEmail: _rememberEmail,
                                  onSuccess: () {
                                    setState(() {
                                      showSignInForm = false;
                                    });
                                    widget.onAuthSuccess?.call();
                                  },
                                );
                          }
                        },
                        icon: const Icon(Icons.login),
                        label: Text(texts.login),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // ユーザー名が空の場合、入力を促す
                            if (userNameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(texts.enterUserName),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            await ref.read(authProvider).performSignUp(
                                  context: context,
                                  ref: ref,
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                  userName: userNameController.text.trim(),
                                  emailController: emailController,
                                  passwordController: passwordController,
                                  userNameController: userNameController,
                                  rememberEmail: _rememberEmail,
                                  onSuccess: () {
                                    setState(() {
                                      showSignInForm = false;
                                    });
                                    widget.onAuthSuccess?.call();
                                  },
                                );
                          }
                        },
                        icon: const Icon(Icons.person_add),
                        label: Text(texts.register),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // パスワードリセットボタン
                TextButton.icon(
                  onPressed: _isPasswordResetLoading
                      ? null
                      : () async {
                          setState(() {
                            _isPasswordResetLoading = true;
                          });

                          await ref.read(authProvider).performPasswordReset(
                                context: context,
                                email: emailController.text.trim(),
                              );

                          if (mounted) {
                            setState(() {
                              _isPasswordResetLoading = false;
                            });
                          }
                        },
                  icon: _isPasswordResetLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.email_outlined),
                  label:
                      Text(_isPasswordResetLoading ? '送信中...' : 'パスワードを忘れた場合'),
                ),

                // キャンセルボタン
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      showSignInForm = false;
                    });
                  },
                  icon: const Icon(Icons.cancel),
                  label: Text(texts.cancel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
