import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../helpers/ui_helper.dart';
import '../services/authentication_service.dart';
import '../services/user_info_service.dart';
import '../services/email_management_service.dart';
import '../services/user_preferences_service.dart';
import '../providers/user_name_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../services/group_management_service.dart';
import '../flavors.dart';

// Logger instance

// Firebase Auth Service
class FirebaseAuthService {
  FirebaseAuth? get _auth =>
      F.appFlavor == Flavor.prod ? FirebaseAuth.instance : null;

  Future<User?> signIn(String email, String password) async {
    if (_auth == null) {
      Log.warning('🔧 DEV環境: Firebase認証は利用できません');
      return null;
    }

    try {
      Log.debug('🔥 FirebaseAuthService: signIn開始 - email: $email');
      Log.debug('🔥 FirebaseAuth instance: ${_auth.toString()}');
      Log.debug('🔥 FirebaseAuth currentUser: ${_auth!.currentUser}');

      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Log.debug('🔥 FirebaseAuthService: signIn成功 - user: ${credential.user}');
      return credential.user;
    } catch (e) {
      Log.error('🔥 FirebaseAuthService: signInでエラー発生');
      Log.error('🔥 エラータイプ: ${e.runtimeType}');
      Log.error('🔥 エラー内容: $e');
      if (e.toString().contains('FirebaseAuthException')) {
        Log.error('🔥 FirebaseAuthException詳細: $e');
      }
      rethrow; // エラーを再スローして上位でキャッチ
    }
  }

  Future<User?> signUp(String email, String password) async {
    if (_auth == null) {
      Log.warning('🔧 DEV環境: Firebase認証は利用できません');
      return null;
    }

    try {
      Log.debug('🔥 FirebaseAuthService: signUp開始 - email: $email');

      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      Log.debug('🔥 FirebaseAuthService: signUp成功 - user: ${credential.user}');
      return credential.user;
    } catch (e) {
      Log.error('🔥 FirebaseAuthService: signUpでエラー発生');
      Log.error('🔥 エラータイプ: ${e.runtimeType}');
      Log.error('🔥 エラー内容: $e');
      rethrow; // エラーを再スローして上位でキャッチ
    }
  }

  Future<void> signOut() async {
    if (_auth == null) {
      Log.warning('🔧 DEV環境: Firebase認証は利用できません');
      return;
    }
    await _auth!.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (_auth == null) {
      Log.warning('🔧 DEV環境: Firebase認証は利用できません');
      return;
    }

    try {
      Log.debug(
          '🔥 FirebaseAuthService: sendPasswordResetEmail開始 - email: $email');

      await _auth!.sendPasswordResetEmail(email: email);

      Log.debug('🔥 FirebaseAuthService: sendPasswordResetEmail成功');
    } catch (e) {
      Log.error('🔥 FirebaseAuthService: sendPasswordResetEmailでエラー発生');
      Log.error('🔥 エラータイプ: ${e.runtimeType}');
      Log.error('🔥 エラー内容: $e');
      rethrow;
    }
  }

  User? get currentUser => _auth?.currentUser;

  /// Home Page用の統合認証操作
  /// サインイン処理
  Future<void> performSignIn({
    required BuildContext context,
    required WidgetRef ref,
    required String email,
    required String password,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController userNameController,
    required VoidCallback onSuccess,
    bool rememberEmail = false, // メールアドレス保存フラグを追加
  }) async {
    if (email.isEmpty || password.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスとパスワードを入力してください');
      return;
    }

    try {
      Log.info('🔧 サインイン開始: $email');

      // ユーザー名の検証: 入力があるか、または SharedPreferences から読み込めるか確認
      String userName = userNameController.text.trim();

      if (userName.isEmpty) {
        // SharedPreferences からユーザー名を読み込んでみる
        final savedUserName = await UserPreferencesService.getUserName();
        if (savedUserName != null && savedUserName.isNotEmpty) {
          userName = savedUserName;
          userNameController.text = userName;
          Log.info('📝 SharedPreferences からユーザー名を復元: $userName');
        } else {
          // ユーザー名がない場合はエラー
          UiHelper.showWarningMessage(
              context, 'ユーザー名を入力してください。または画面上部に名前を入力してください。');
          Log.warning('⚠️ ユーザー名が見つかりません - 入力不可');
          return;
        }
      } else {
        // 入力されたユーザー名を SharedPreferences に保存
        await UserPreferencesService.saveUserName(userName);
        Log.info('💾 入力されたユーザー名を SharedPreferences に保存: $userName');
      }

      final userCredential =
          await AuthenticationService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null) {
        UiHelper.showErrorMessage(context, 'ログインに失敗しました');
        return;
      }

      // メールアドレスの保存処理
      await UserPreferencesService.saveOrClearEmailForSignIn(
        email: email,
        shouldRemember: rememberEmail,
      );

      UiHelper.showSuccessMessage(context, 'ログインしました');

      // サインイン成功後の処理
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _performPostSignInActions(ref, userNameController);
        onSuccess();
      });

      // フォームリセット（メールアドレス保存時は email はクリアしない）
      if (!rememberEmail) {
        emailController.clear();
      }
      passwordController.clear();
    } on FirebaseAuthException catch (e) {
      Log.error('🚨 Firebase認証エラー: ${e.code} - ${e.message}');
      await _handleFirebaseAuthError(e, email, password, context, ref,
          emailController, userNameController);
    } catch (e) {
      Log.error('🚨 ログイン失敗: $e');
      UiHelper.showErrorMessage(context, 'ログインに失敗しました: $e');
    }
  }

  /// サインアップ処理
  Future<void> performSignUp({
    required BuildContext context,
    required WidgetRef ref,
    required String email,
    required String password,
    required String userName,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController userNameController,
    required VoidCallback onSuccess,
    bool rememberEmail = false, // メールアドレス保存フラグを追加
  }) async {
    if (email.isEmpty || password.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスとパスワードを入力してください');
      return;
    }

    if (userName.isEmpty) {
      UiHelper.showWarningMessage(context, 'ユーザー名を入力してください');
      return;
    }

    try {
      Log.info('🔧 サインアップ開始: $email - userName: $userName');

      // ユーザー名を SharedPreferences に保存（サインアップ時に同期）
      await UserPreferencesService.saveUserName(userName);
      Log.info('💾 ユーザー名を SharedPreferences に保存（サインアップ時）: $userName');

      final userCredential =
          await AuthenticationService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        userName: userName,
      );

      if (userCredential == null) {
        UiHelper.showErrorMessage(context, 'アカウント作成に失敗しました');
        return;
      }

      // メールアドレスの保存処理
      await UserPreferencesService.saveOrClearEmailForSignIn(
        email: email,
        shouldRemember: rememberEmail,
      );

      UiHelper.showSuccessMessage(context, 'アカウントを作成してログインしました');

      // サインアップ成功後の処理
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _performPostSignUpActions(ref, userNameController);
        onSuccess();
      });

      // フォームリセット（メールアドレス保存時は email はクリアしない）
      if (!rememberEmail) {
        emailController.clear();
      }
      passwordController.clear();
    } on FirebaseAuthException catch (e) {
      Log.error('🚨 Firebase認証エラー: ${e.code} - ${e.message}');
      String errorMessage = _getFirebaseAuthErrorMessage(e);
      UiHelper.showErrorMessage(context, errorMessage,
          duration: const Duration(seconds: 4));
    } catch (e) {
      Log.error('🚨 サインアップ失敗: $e');
      UiHelper.showErrorMessage(context, 'アカウント作成に失敗しました: $e');
    }
  }

  /// ユーザー名保存処理
  Future<void> saveUserName({
    required BuildContext context,
    required WidgetRef ref,
    required String userName,
  }) async {
    if (userName.isEmpty) {
      UiHelper.showWarningMessage(context, 'ユーザー名を入力してください');
      return;
    }

    try {
      Log.info('💾 ユーザー名保存開始: $userName');

      // UserNameNotifierを使用してSharedPreferences + Firestoreに保存
      await ref.read(userNameNotifierProvider.notifier).setUserName(userName);
      Log.info('✅ SharedPreferences + Firestoreに保存完了');

      // デフォルトグループの情報も更新
      await _saveUserInfo(ref, userName, '');
      Log.info('✅ デフォルトグループ更新完了');

      // ユーザー名表示プロバイダーを明示的に更新
      ref.invalidate(userNameProvider);
      Log.info('🔄 ユーザー名プロバイダーを更新しました');

      UiHelper.showSuccessMessage(context, 'ユーザー名「$userName」を保存しました');
    } catch (e) {
      Log.error('❌ ユーザー名保存エラー: $e');
      UiHelper.showErrorMessage(context, 'ユーザー名の保存に失敗しました: $e');
    }
  }

  /// パスワードリセットメール送信処理
  Future<void> performPasswordReset({
    required BuildContext context,
    required String email,
  }) async {
    if (email.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスを入力してください');
      return;
    }

    try {
      Log.info('📧 パスワードリセットメール送信開始: $email');

      await sendPasswordResetEmail(email);

      UiHelper.showSuccessMessage(
        context,
        'パスワードリセットメールを送信しました',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Log.error('❌ パスワードリセットメール送信エラー: $e');
      UiHelper.showErrorMessage(
        context,
        'メール送信に失敗しました: $e',
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// About Dialog表示
  static void showAppAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Go Shop',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.shopping_cart,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: const [
        Text('家族やグループで買い物リストを共有できるアプリです。'),
        SizedBox(height: 16),
        Text('主な機能:'),
        Text('• グループでの買い物リスト共有'),
        Text('• リアルタイム同期'),
        Text('• オフライン対応'),
        Text('• メンバー管理'),
        SizedBox(height: 16),
        Text('開発者: 金ヶ江 真也 ファーティマ (Maya Fatima Kanagae)'),
        Text('お問い合わせ: fatima.sumomo@gmail.com'),
        SizedBox(height: 16),
        Text('© 2024 Go Shop. All rights reserved.'),
      ],
    );
  }

  // プライベートヘルパーメソッド
  Future<void> _performPostSignInActions(
      WidgetRef ref, TextEditingController userNameController) async {
    // SharedPreferences からユーザー名を読み込んで表示を更新
    final savedUserName = await UserPreferencesService.getUserName();
    if (savedUserName != null && savedUserName.isNotEmpty) {
      userNameController.text = savedUserName;
      Log.info('📱 SharedPreferences からユーザー名を読み込み: $savedUserName');
    }

    await _saveUserInfo(ref, userNameController.text, '');
    ref.invalidate(selectedGroupProvider);
    ref.invalidate(allGroupsProvider);
    await _loadUserNameFromDefaultGroup(ref, userNameController);

    // サインイン時にFirestore上のユーザー名があればプリファレンスへ同期し、
    // 表示用プロバイダーを更新する（Firestore同期はサインイン時のみ）
    try {
      final firestoreName = await ref
          .read(userNameNotifierProvider.notifier)
          .restoreUserNameFromFirestore();

      if (firestoreName != null && firestoreName.isNotEmpty) {
        // Firestore の名前が優先。プリファレンスへ保存
        await UserPreferencesService.saveUserName(firestoreName);
        userNameController.text = firestoreName;
        // 表示用Providerをプリファレンスから再読み込みして更新
        await ref.read(userNameProvider.notifier).refresh();
        Log.info('🔄 サインイン時にFirestoreのユーザー名を同期しました: $firestoreName');
      } else {
        // Firestoreに名前がない場合はプリファレンスを再読み込みして表示を安定化
        await ref.read(userNameProvider.notifier).refresh();
        Log.info('ℹ️ Firestoreにユーザー名が無かったため、プリファレンスから表示を再読み込みしました');
      }
    } catch (e) {
      Log.warning('⚠️ サインイン時のユーザー名Firestore同期でエラー: $e');
      // エラー時はプリファレンスの値を再読み込みしてUIを維持
      try {
        await ref.read(userNameProvider.notifier).refresh();
      } catch (_) {}
    }
    // TODO: QrCodeHelper.processPendingInvitation処理
  }

  Future<void> _performPostSignUpActions(
      WidgetRef ref, TextEditingController userNameController) async {
    // SharedPreferences からユーザー名を読み込んで表示を更新
    final savedUserName = await UserPreferencesService.getUserName();
    if (savedUserName != null && savedUserName.isNotEmpty) {
      userNameController.text = savedUserName;
      Log.info('📱 SharedPreferences からユーザー名を読み込み: $savedUserName');
    }

    await _saveUserInfo(ref, userNameController.text, '');

    // 🎉 サインアップ時に1か月間の無料期間を開始
    try {
      await ref.read(subscriptionProvider.notifier).startSignupFreePeriod();
      Log.info('🎉 サインアップ特典: 1か月間の無料期間を開始しました');
    } catch (e) {
      Log.error('❌ 無料期間開始エラー: $e');
    }

    ref.invalidate(selectedGroupProvider);
    ref.invalidate(allGroupsProvider);
    await _loadUserNameFromDefaultGroup(ref, userNameController);

    // サインアップ後も同様にFirestore上のユーザー名を確認して同期（存在する場合）
    try {
      final firestoreName = await ref
          .read(userNameNotifierProvider.notifier)
          .restoreUserNameFromFirestore();

      if (firestoreName != null && firestoreName.isNotEmpty) {
        // Firestore の名前が優先。プリファレンスへ保存
        await UserPreferencesService.saveUserName(firestoreName);
        userNameController.text = firestoreName;
        await ref.read(userNameProvider.notifier).refresh();
        Log.info('🔄 サインアップ後にFirestoreのユーザー名を同期しました: $firestoreName');
      } else {
        await ref.read(userNameProvider.notifier).refresh();
      }
    } catch (e) {
      Log.warning('⚠️ サインアップ後のユーザー名Firestore同期でエラー: $e');
      try {
        await ref.read(userNameProvider.notifier).refresh();
      } catch (_) {}
    }
  }

  Future<void> _saveUserInfo(
      WidgetRef ref, String userName, String email) async {
    final userInfoService = ref.read(userInfoServiceProvider);
    await userInfoService.saveUserInfo(
      userNameFromForm: userName,
      emailFromForm: email,
    );
  }

  Future<void> _loadUserNameFromDefaultGroup(
      WidgetRef ref, TextEditingController userNameController) async {
    final groupService = ref.read(groupManagementServiceProvider);
    final userName = await groupService.loadUserNameFromDefaultGroup();

    if (userName != null && userName.isNotEmpty) {
      userNameController.text = userName;
    }
  }

  Future<void> _handleFirebaseAuthError(
    FirebaseAuthException e,
    String email,
    String password,
    BuildContext context,
    WidgetRef ref,
    TextEditingController emailController,
    TextEditingController userNameController,
  ) async {
    String errorMessage;
    bool offerSignUp = false;

    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'このメールアドレスは登録されていません';
        offerSignUp = true;
        break;
      case 'invalid-credential':
        errorMessage = 'ログイン情報が正しくありません。アカウントが存在しない可能性があります';
        offerSignUp = true;
        break;
      case 'wrong-password':
        errorMessage = 'パスワードが間違っています';
        break;
      case 'invalid-email':
        errorMessage = 'メールアドレスの形式が正しくありません';
        break;
      case 'too-many-requests':
        errorMessage = 'ログイン試行回数が多すぎます。しばらく待ってから再試行してください';
        break;
      default:
        errorMessage = 'ログインに失敗しました';
        offerSignUp = true;
    }

    if (offerSignUp) {
      await _offerSignUp(
          email, password, context, ref, emailController, userNameController);
    } else {
      UiHelper.showErrorMessage(context, errorMessage,
          duration: const Duration(seconds: 4));
    }
  }

  Future<void> _offerSignUp(
    String email,
    String password,
    BuildContext context,
    WidgetRef ref,
    TextEditingController emailController,
    TextEditingController userNameController,
  ) async {
    var userName = userNameController.text.trim();

    // ユーザー名が空の場合、SharedPreferences から読み込みを試みる
    if (userName.isEmpty) {
      final savedUserName = await UserPreferencesService.getUserName();
      if (savedUserName != null && savedUserName.isNotEmpty) {
        userName = savedUserName;
        userNameController.text = userName;
        Log.info('📱 SharedPreferences からユーザー名を復元: $userName');
      }
    }

    if (userName.isEmpty) {
      UiHelper.showInfoDialog(
        context,
        title: 'ユーザー名が必要です',
        message:
            'サインアップするには、まずユーザー名を設定してください。\n\n画面上部のユーザー名入力欄にお名前を入力してから再度お試しください。',
      );
      return;
    }

    final shouldSignUp = await UiHelper.showConfirmDialog(
      context,
      title: 'アカウントが見つかりません',
      message: 'メールアドレス "$email" は登録されていません。\n新しいアカウントを作成しますか？',
      confirmText: 'アカウント作成',
    );

    if (shouldSignUp) {
      await performSignUp(
        context: context,
        ref: ref,
        email: email,
        password: password,
        userName: userName,
        emailController: emailController,
        passwordController: TextEditingController()..text = password,
        userNameController: userNameController,
        onSuccess: () {},
      );
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'weak-password':
        return 'パスワードが弱すぎます。より強力なパスワードを入力してください';
      default:
        return 'アカウント作成に失敗しました: ${e.message}';
    }
  }

  /// メールアドレスを保存または削除（認証と統合）
  Future<void> saveOrClearEmail({
    required WidgetRef ref,
    required String email,
    required bool shouldRemember,
  }) async {
    try {
      final emailService = ref.read(emailManagementServiceProvider);
      await emailService.saveOrClearEmail(
        email: email,
        shouldRemember: shouldRemember,
      );
      Log.info('🔐 AuthProvider: メールアドレス保存処理完了');
    } catch (e) {
      Log.error('❌ AuthProvider: メールアドレス保存エラー: $e');
      rethrow;
    }
  }
}

// Firebase Auth プロバイダー
final authProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Firebase認証状態プロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  if (F.appFlavor == Flavor.prod) {
    return FirebaseAuth.instance.authStateChanges();
  } else {
    // DEV環境では常にnullを返すストリーム
    return Stream.value(null);
  }
});
