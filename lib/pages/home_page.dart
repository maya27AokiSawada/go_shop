import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/shared_group.dart';
import '../models/shared_list.dart';
import '../providers/auth_provider.dart';
import '../providers/hive_provider.dart';
import '../providers/shared_group_provider.dart';
import '../providers/shared_list_provider.dart' hide sharedListBoxProvider;
import '../providers/page_index_provider.dart';
import '../services/user_preferences_service.dart';
import '../services/firestore_user_name_service.dart';
import '../services/password_reset_service.dart';
import '../services/ad_service.dart';
import '../services/app_launch_service.dart';
import '../helpers/user_id_change_helper.dart';

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
  bool _isSignUpMode = true; // true: アカウント作成, false: サインイン
  bool _rememberEmail = false; // メールアドレス保存チェックボックス

  @override
  void initState() {
    super.initState();
    AppLogger.info('HomePage初期化開始');
    _loadUserName();
    _loadSavedEmail();
    _incrementAppLaunchCount(); // 🔥 アプリ起動カウント
  }

  /// アプリ起動回数をインクリメント
  Future<void> _incrementAppLaunchCount() async {
    try {
      final launchCount = await AppLaunchService.incrementLaunchCount();
      AppLogger.info('📱 [HOME] アプリ起動回数: $launchCount 回');
    } catch (e) {
      AppLogger.error('❌ [HOME] アプリ起動カウントエラー: $e');
    }
  }

  /// ユーザー名をSharedPreferencesからロード
  Future<void> _loadUserName() async {
    try {
      final savedUserName = await UserPreferencesService.getUserName();
      if (savedUserName != null && savedUserName.isNotEmpty) {
        setState(() {
          userNameController.text = savedUserName;
        });
        AppLogger.info(
            '✅ [HOME] ユーザー名をロード: ${AppLogger.maskName(savedUserName)}');
      }
    } catch (e) {
      AppLogger.error('❌ [HOME] ユーザー名ロードエラー: $e');
    }
  }

  /// 保存されたメールアドレスをロード
  Future<void> _loadSavedEmail() async {
    try {
      final savedEmail = await UserPreferencesService.getSavedEmailForSignIn();
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          emailController.text = savedEmail;
          _rememberEmail = true;
        });
        AppLogger.info('✅ [HOME] メールアドレスをロード: $savedEmail');
      }
    } catch (e) {
      AppLogger.error('❌ [HOME] メールアドレスロードエラー: $e');
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// アカウント作成処理（ディスプレイネーム必須）
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      final userName = userNameController.text.trim();

      // 🔍 デバッグ: 入力値確認
      AppLogger.info(
          '🔍 [SIGNUP DEBUG] 入力されたユーザー名: "${AppLogger.maskName(userName)}" (長さ: ${userName.length})');
      AppLogger.info(
          '🔍 [SIGNUP DEBUG] メールアドレス: ${AppLogger.maskUserId(email)}');

      // ✅ ディスプレイネームが空の場合はエラー（バリデーション通過してもダブルチェック）
      if (userName.isEmpty) {
        AppLogger.error('❌ [SIGNUP] ディスプレイネームが空です！');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ディスプレイネームを入力してください'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 新規登録前に古いデータをクリア（順序重要！）
      // 1. SharedPreferencesをクリア（古いユーザー名を削除）
      await UserPreferencesService.clearAllUserInfo();
      AppLogger.info('🗑️ [SIGNUP] SharedPreferences 全ユーザー情報をクリア');

      // 🔥 CRITICAL: Firebase Auth登録前にユーザー名を保存（authStateChanges発火時に参照できるように）
      await UserPreferencesService.saveUserName(userName);
      AppLogger.info(
          '✅ [SIGNUP] ディスプレイネームをPreferencesに事前保存: ${AppLogger.maskName(userName)}');

      // メールアドレスもPreferencesに事前保存
      await UserPreferencesService.saveUserEmail(email);
      AppLogger.info('✅ [SIGNUP] メールアドレスをPreferencesに事前保存');

      // 2. Hiveデータをクリア（Firebase Auth登録前に実行）
      final SharedGroupBox = ref.read(SharedGroupBoxProvider);
      final sharedListBox = ref.read(sharedListBoxProvider);
      await SharedGroupBox.clear();
      await sharedListBox.clear();
      AppLogger.info('🗑️ [SIGNUP] 前ユーザーのHiveデータをクリア完了');

      // 3. Firebase Auth 新規登録（authStateChanges発火前にHiveクリア完了）
      await ref.read(authProvider).signUp(email, password);
      AppLogger.info('✅ [SIGNUP] 新規ユーザー登録成功');

      // プロバイダーを無効化（UIをリセット）
      ref.invalidate(allGroupsProvider);
      ref.invalidate(selectedGroupProvider);
      ref.invalidate(sharedListProvider);
      await Future.delayed(const Duration(milliseconds: 300));
      AppLogger.info('🔄 [SIGNUP] プロバイダー無効化完了');

      // Firebase Authのディスプレイネームを更新
      final user = ref.read(authProvider).currentUser;
      if (user != null) {
        await user.updateDisplayName(userName);
        await user.reload();
        AppLogger.info(
            '✅ [SIGNUP] Firebase Authのディスプレイネームを更新: ${AppLogger.maskName(userName)}');
      }

      // Firestoreにユーザープロファイルを作成
      await FirestoreUserNameService.ensureUserProfileExists(
          userName: userName);
      AppLogger.info(
          '✅ [SIGNUP] Firestoreにユーザープロファイル作成: ${AppLogger.maskName(userName)}');

      // 📝 注: ディスプレイネーム・メールアドレスは既にPreferencesに事前保存済み（Firebase Auth登録前）

      // Firestoreデータ反映を待つ（書き込み完了まで待機）
      AppLogger.info('⏳ [SIGNUP] Firestoreデータ反映待機中...');
      await Future.delayed(const Duration(seconds: 2));

      // ⚠️ ウィジェットが破棄されていないか確認
      if (!mounted) {
        AppLogger.warning('⚠️ [SIGNUP] ウィジェットが破棄されたため処理中断');
        return;
      }

      // Firestore→Hiveの同期を実行（デフォルトグループをHiveに反映）
      AppLogger.info('🔄 [SIGNUP] Firestore→Hive同期開始...');
      try {
        ref.invalidate(forceSyncProvider);
        await ref.read(forceSyncProvider.future);
        AppLogger.info('✅ [SIGNUP] Firestore→Hive同期完了');
      } catch (e) {
        AppLogger.error('❌ [SIGNUP] 同期エラー（継続）', e);
        // 同期エラーでも処理は継続（UI更新は行う）
      }

      // ⚠️ ウィジェットが破棄されていないか確認
      if (!mounted) {
        AppLogger.warning('⚠️ [SIGNUP] ウィジェットが破棄されたため処理中断');
        return;
      }

      // プロバイダーを再読み込み（グループリストを更新）
      ref.invalidate(allGroupsProvider);
      await Future.delayed(const Duration(milliseconds: 500));
      AppLogger.info('🔄 [SIGNUP] allGroupsProvider再読み込み完了');

      // グループ数を確認して初期セットアップ画面に遷移
      final allGroupsAsync = await ref.read(allGroupsProvider.future);
      if (allGroupsAsync.isEmpty) {
        AppLogger.info('📋 [SIGNUP] グループ0個 - グループタブに自動遷移');
        // グループタブ（pageIndex=1）に切り替え
        ref.read(pageIndexProvider.notifier).setPageIndex(1);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アカウントを作成しました！ようこそ、$userNameさん'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ [SIGNUP] アカウント作成エラー', e);
      if (mounted) {
        String errorMessage = 'アカウント作成に失敗しました';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'このメールアドレスは既に使用されています';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'パスワードが弱すぎます';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'メールアドレスの形式が正しくありません';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

  /// サインイン処理（ディスプレイネーム任意）
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      // サインイン（サインアウト時に既にHiveクリア済み）
      await ref.read(authProvider).signIn(email, password);
      AppLogger.info('✅ [SIGNIN] サインイン成功');

      final signedInUser = ref.read(authProvider).currentUser;
      if (signedInUser != null) {
        await UserIdChangeHelper.ensureUserContextReady(
          ref: ref,
          context: context,
          user: signedInUser,
          mounted: mounted,
        );
        AppLogger.info('✅ [SIGNIN] ユーザー切り替えコンテキスト準備完了');
      }

      // メールアドレス保存処理
      await UserPreferencesService.saveOrClearEmailForSignIn(
        email: email,
        shouldRemember: _rememberEmail,
      );
      AppLogger.info('✅ [SIGNIN] メールアドレス保存設定: $_rememberEmail');

      // Firestoreにユーザープロファイルが存在することを確認（なければ作成）
      await FirestoreUserNameService.ensureUserProfileExists();
      AppLogger.info('✅ [SIGNIN] ユーザープロファイル確認完了');

      // Firestore users/{userId}/profile からユーザー名を取得
      final firestoreUserName = await FirestoreUserNameService.getUserName();

      if (firestoreUserName != null && firestoreUserName.isNotEmpty) {
        // Firestoreからユーザー名を取得できた場合
        await UserPreferencesService.saveUserName(firestoreUserName);
        setState(() {
          userNameController.text = firestoreUserName;
        });
        AppLogger.info(
            '✅ [SIGNIN] Firestoreからユーザー名を取得・反映: ${AppLogger.maskName(firestoreUserName)}');
      } else {
        // Firestoreに未設定の場合、Firebase Authから取得を試みる
        final user = ref.read(authProvider).currentUser;
        if (user != null &&
            user.displayName != null &&
            user.displayName!.isNotEmpty) {
          await UserPreferencesService.saveUserName(user.displayName!);
          setState(() {
            userNameController.text = user.displayName!;
          });
          AppLogger.info(
              '✅ [SIGNIN] Firebase Authからユーザー名を反映: ${user.displayName}');
        } else {
          AppLogger.info('💡 [SIGNIN] ユーザー名が未設定（Firestore・Auth両方）');
        }
      }

      // Firestore同期は UserIdChangeHelper 側で完了済み。
      // ここでは provider 再構築結果を明示的に待つ。
      await ref.read(allGroupsProvider.notifier).cleanupInvalidHiveGroups();
      await ref.read(allGroupsProvider.notifier).refresh();
      AppLogger.info('✅ [SIGNIN] allGroupsProvider再構築完了');

      // 🔥 NEW: グループが0個の場合は自動的にグループページ（タブ1）に遷移
      var allGroups = await ref.read(allGroupsProvider.future);
      if (allGroups.isEmpty) {
        AppLogger.info('⏳ [SIGNIN] 初回判定で0件 - Firestore復元完了確認を再実行');
        ref.invalidate(forceSyncProvider);
        await ref.read(forceSyncProvider.future);
        await ref.read(allGroupsProvider.notifier).cleanupInvalidHiveGroups();
        await ref.read(allGroupsProvider.notifier).refresh();
        allGroups = await ref.read(allGroupsProvider.future);
        AppLogger.info('📊 [SIGNIN] Firestore復元後のグループ数: ${allGroups.length}件');
      }

      if (allGroups.isEmpty) {
        AppLogger.info('📋 [SIGNIN] グループ0個 → グループページ（タブ1）に遷移');
        ProviderScope.containerOf(context)
            .read(pageIndexProvider.notifier)
            .setPageIndex(1);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('サインインしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ [SIGNIN] サインインエラー', e);
      if (mounted) {
        String errorMessage = 'サインインに失敗しました';
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'ユーザーが見つかりません。アカウント作成が必要です';
        } else if (e.toString().contains('wrong-password') ||
            e.toString().contains('invalid-credential')) {
          errorMessage = 'メールアドレスまたはパスワードが正しくありません';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
                'GoShopping',
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

              // モード選択ボタン
              if (!_showEmailSignIn) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showEmailSignIn = true;
                      _isSignUpMode = true; // デフォルトはアカウント作成
                    });
                  },
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('アカウント作成'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showEmailSignIn = true;
                      _isSignUpMode = false; // サインインモード
                    });
                  },
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('サインイン'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],

              // メール/パスワードフォーム
              if (_showEmailSignIn) ...[
                // モード表示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSignUpMode
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSignUpMode ? Icons.person_add : Icons.login,
                        color:
                            _isSignUpMode ? Colors.blue : Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSignUpMode ? 'アカウント作成' : 'サインイン',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isSignUpMode
                              ? Colors.blue.shade900
                              : Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUpMode = !_isSignUpMode;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Text(_isSignUpMode ? 'サインインへ' : 'アカウント作成へ'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ディスプレイネーム（アカウント作成時のみ必須）
                      if (_isSignUpMode)
                        Column(
                          children: [
                            TextFormField(
                              controller: userNameController,
                              decoration: InputDecoration(
                                labelText: 'ディスプレイネーム（必須）',
                                hintText: '例: 太郎',
                                prefixIcon: const Icon(Icons.person),
                                helperText: 'グループメンバーに表示される名前です',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (_isSignUpMode &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'ディスプレイネームを入力してください';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

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
                      const SizedBox(height: 8),

                      // パスワードリセットリンク（サインイン時のみ）
                      if (!_isSignUpMode)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              final email = emailController.text.trim();
                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('メールアドレスを入力してください'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              // パスワードリセットメール送信
                              final service = PasswordResetService();
                              final result =
                                  await service.sendPasswordResetEmail(email);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result.message),
                                    backgroundColor: result.success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'パスワードを忘れた場合',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // メールアドレス保存チェックボックス（サインイン時のみ）
                      if (!_isSignUpMode)
                        CheckboxListTile(
                          value: _rememberEmail,
                          onChanged: (value) {
                            setState(() {
                              _rememberEmail = value ?? false;
                            });
                          },
                          title: const Text(
                            'メールアドレスを保存',
                            style: TextStyle(fontSize: 14),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      const SizedBox(height: 8),

                      // 実行ボタン
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_isSignUpMode ? _signUp : _signIn),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                          backgroundColor: _isSignUpMode ? Colors.blue : null,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isSignUpMode ? 'アカウントを作成' : 'サインイン'),
                      ),
                      const SizedBox(height: 16),

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
    // syncStatusは使用しないため削除（AppBarに統合済み）

    return SafeArea(
      child: authState.when(
        data: (user) {
          final isAuthenticated = user != null;

          // 🔍 デバッグログ: 現在の認証状態とユーザー情報
          if (isAuthenticated) {
            AppLogger.info(
                '🔍 [HOME_BUILD] ログイン中 - UID: ${AppLogger.maskUserId(user.uid)}, Email: ${user.email}, DisplayName: ${AppLogger.maskName(user.displayName)}');
          } else {
            AppLogger.info('🔍 [HOME_BUILD] 未ログイン状態');
          }

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
                // ステータス表示を削除（AppBarに統合済み）

                // ニュース＆広告パネル
                const NewsAndAdsPanelWidget(),

                const SizedBox(height: 16),

                // バナー広告
                const HomeBannerAdWidget(),

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
                        await UserIdChangeHelper.performSignOutCleanup(
                            ref: ref);
                        AppLogger.info('🗑️ [SIGNOUT] ローカル状態クリーンアップ完了');

                        // Firebase Authからサインアウト
                        await ref.read(authProvider).signOut();
                        AppLogger.info('✅ [SIGNOUT] サインアウト完了');

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ログアウトしました'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      } catch (e) {
                        AppLogger.error('❌ [SIGNOUT] サインアウトエラー', e);
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
