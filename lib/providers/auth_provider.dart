import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../helpers/ui_helper.dart';
import '../helpers/user_id_change_helper.dart';
import '../services/authentication_service.dart';
import '../services/user_info_service.dart';
import '../services/email_management_service.dart';
import '../services/user_preferences_service.dart';
import '../services/firestore_group_sync_service.dart';
import '../providers/user_name_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_settings_provider.dart';
import '../providers/hive_provider.dart';
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

    // ログアウト時はUIDを保持（次回ログイン時のUID比較のため）
    // await UserPreferencesService.clearUserId(); ← 削除
    Log.info('🔓 [SIGNOUT] ログアウト実行（UIDは保持）');

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

      // レート制限チェック（1日5通まで）
      final rateLimitDoc = await FirebaseFirestore.instance
          .collection('mail_rate_limit')
          .doc(email)
          .get();

      if (rateLimitDoc.exists) {
        final data = rateLimitDoc.data()!;
        final count = data['count'] as int? ?? 0;
        final lastReset = (data['lastReset'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        // 24時間以内に5通送信済みの場合は拒否
        if (lastReset != null &&
            now.difference(lastReset).inHours < 24 &&
            count >= 5) {
          throw Exception('送信制限に達しました。24時間後に再度お試しください。');
        }
      }

      // Firestore Trigger Email用のドキュメントを作成
      await FirebaseFirestore.instance.collection('mail').add({
        'to': [email],
        'template': {
          'name': 'password-reset',
          'data': {
            'email': email,
            'resetLink': 'https://go-shop-app.firebaseapp.com/__/auth/action',
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      // レート制限カウンターを更新
      final now = DateTime.now();
      final docData = rateLimitDoc.exists ? rateLimitDoc.data()! : {};
      final lastReset = (docData['lastReset'] as Timestamp?)?.toDate();
      final shouldReset =
          lastReset == null || now.difference(lastReset).inHours >= 24;

      await FirebaseFirestore.instance
          .collection('mail_rate_limit')
          .doc(email)
          .set({
        'count': shouldReset ? 1 : FieldValue.increment(1),
        'lastReset': shouldReset ? FieldValue.serverTimestamp() : lastReset,
        'lastSent': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Log.info('📧 Firestore Triggerメールドキュメント作成: $email');
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
          Log.info(
              '📝 SharedPreferences からユーザー名を復元: ${AppLogger.maskName(userName)}');
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
        Log.info(
            '💾 入力されたユーザー名を SharedPreferences に保存: ${AppLogger.maskName(userName)}');
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

      // 🔍 UID変更チェック: サインイン成功直後に実行
      final newUid = userCredential.user?.uid;
      final storedUid = await UserPreferencesService.getUserId();

      if (newUid != null &&
          storedUid != null &&
          storedUid.isNotEmpty &&
          storedUid != newUid) {
        Log.info('⚠️ [SIGNIN] UID変更検出: $storedUid → $newUid');

        // UID変更ダイアログを表示
        await UserIdChangeHelper.handleUserIdChange(
          ref: ref,
          context: context,
          newUserId: newUid,
          userEmail: email,
          mounted: true,
        );

        // ダイアログ処理後にUID保存は完了しているので、ここでは保存不要
        Log.info('✅ [SIGNIN] UID変更処理完了');
      } else {
        // UID変更なし or 初回ログイン
        if (newUid != null) {
          await UserPreferencesService.saveUserId(newUid);
          Log.info('💾 [SIGNIN] UID保存完了: $newUid');
        }
      }

      // メールアドレスの保存処理
      await UserPreferencesService.saveOrClearEmailForSignIn(
        email: email,
        shouldRemember: rememberEmail,
      );

      UiHelper.showSuccessMessage(context, 'ログインしました');

      // サインイン成功後の処理（同期的に実行）
      try {
        await _performPostSignInActions(ref, userNameController);
      } catch (e) {
        Log.warning('⚠️ サインイン後処理でエラー: $e');
      }

      // フォームリセット（メールアドレス保存時は email はクリアしない）
      if (!rememberEmail) {
        emailController.clear();
      }
      passwordController.clear();

      // 成功コールバックは最後に実行
      onSuccess();
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
      Log.info(
          '🔧 サインアップ開始: ${AppLogger.maskName(email)} - userName: ${AppLogger.maskName(userName)}');

      // ユーザー名を SharedPreferences に保存（サインアップ時に同期）
      await UserPreferencesService.saveUserName(userName);
      Log.info(
          '💾 ユーザー名を SharedPreferences に保存（サインアップ時）: ${AppLogger.maskName(userName)}');

      // ユーザー名を UserSettings (Hive) にも保存
      try {
        await ref.read(userSettingsProvider.notifier).updateUserName(userName);
        Log.info('💾 ユーザー名を UserSettings (Hive) に保存（サインアップ時）: $userName');
      } catch (e) {
        Log.warning('⚠️ UserSettings保存エラー（サインアップ継続）: $e');
      }

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
      Log.info('💾 ユーザー名保存開始: ${AppLogger.maskName(userName)}');

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
    // TextEditingControllerが破棄されていないかチェック
    String? currentUserName;

    // SharedPreferences からユーザー名を読み込んで表示を更新
    final savedUserName = await UserPreferencesService.getUserName();
    if (savedUserName != null && savedUserName.isNotEmpty) {
      currentUserName = savedUserName;
      try {
        userNameController.text = savedUserName;
      } catch (e) {
        Log.warning('⚠️ userNameController更新失敗（既にdispose済み）: $e');
      }
      Log.info('📱 SharedPreferences からユーザー名を読み込み: $savedUserName');
    }

    await _saveUserInfo(ref, currentUserName ?? userNameController.text, '');

    // Firestoreからグループを同期してHiveに保存（本番環境のみ）
    if (F.appFlavor == Flavor.prod) {
      try {
        final syncedGroups =
            await FirestoreGroupSyncService.syncGroupsOnSignIn();
        if (syncedGroups.isNotEmpty) {
          final groupBox = ref.read(SharedGroupBoxProvider);
          for (final group in syncedGroups) {
            try {
              await groupBox.put(group.groupId, group);
              Log.info('📦 [サインイン] グループ「${group.groupName}」をHiveに保存');
            } catch (e) {
              Log.warning('⚠️ [サインイン] グループ「${group.groupName}」のHive保存失敗: $e');
            }
          }
          Log.info('✅ [サインイン] ${syncedGroups.length}件のグループをHiveに保存完了');
        }
      } catch (e) {
        Log.warning('⚠️ [サインイン] Firestoreグループ同期エラー: $e');
      }
    }

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
        try {
          userNameController.text = firestoreName;
        } catch (e) {
          Log.warning('⚠️ userNameController更新失敗（既にdispose済み）: $e');
        }
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
        errorMessage = 'メールアドレスまたはパスワードが正しくありません';
        offerSignUp = true;
        break;
      case 'wrong-password':
        errorMessage = 'メールアドレスまたはパスワードが正しくありません';
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
        Log.info(
            '📱 SharedPreferences からユーザー名を復元: ${AppLogger.maskName(userName)}');
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
