import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../helpers/ui_helper.dart';
import '../services/authentication_service.dart';
import '../services/user_preferences_service.dart';
import '../services/email_management_service.dart';
import '../services/group_management_service.dart';
import '../helpers/qr_code_helper.dart';
import '../providers/purchase_group_provider.dart';
import 'auth_provider.dart';

/// Home Page用の認証・UI操作を拡張したサービス
class HomePageAuthService {
  final WidgetRef ref;
  final BuildContext context;
  final bool Function()? isMounted;
  
  HomePageAuthService({
    required this.ref,
    required this.context,
    this.isMounted,
  });
  
  /// サインイン処琁E
  Future<void> performSignIn({
    required String email,
    required String password,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required bool rememberEmail,
  }) async {
    if (isMounted != null && !isMounted!()) return;
    
    if (email.isEmpty || password.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスとパスワードを入力してください');
      return;
    }

    try {
      Log.info('🔧 サインイン開姁E $email');
      
      final userCredential = await AuthenticationService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential == null) {
      if (isMounted != null && isMounted!()) {
        UiHelper.showErrorMessage(context, 'ログインに失敗しました');
      }
      return;
    }
    
    // メールアドレスの保孁E削除を実衁E
    await _saveOrClearEmail(email, rememberEmail);
    
    if (isMounted != null && isMounted!()) {
      UiHelper.showSuccessMessage(context, 'ログインしました');        // サインイン成功後�E処琁E
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _userInfoSave();
          ref.invalidate(selectedGroupProvider);
          ref.invalidate(allGroupsProvider);
          await _loadUserNameFromDefaultGroup();
          // 保存された招征E��報があれ�E自動�E琁E
          await QrCodeHelper.processPendingInvitation(context, ref, () async {
            await _loadUserNameFromDefaultGroup();
          });
        });
      }
    } on FirebaseAuthException catch (e) {
      await _handleFirebaseAuthError(e, email, password);
    } catch (e) {
      Log.error('❁Eサインイン中に予期しなぁE��ラー: $e');
      if (isMounted != null && isMounted!()) {
        UiHelper.showErrorMessage(context, 'サインインに失敗しました: $e');
      }
    }
  }
  
  /// サインアチE�E処琁E
  Future<void> performSignUp({
    required String email,
    required String password,
    required String userName,
    required TextEditingController emailController,
    required TextEditingController passwordController,
  }) async {
    if (isMounted != null && isMounted!() == false) return;
    
    if (email.isEmpty || password.isEmpty || userName.isEmpty) {
      UiHelper.showWarningMessage(context, 'すべての頁E��を�E力してください');
      return;
    }

    try {
      Log.info('�E サインアチE�E開姁E $email');
      
      final userCredential = await AuthenticationService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential?.user != null) {
        Log.info('✁EサインアチE�E成功: ${userCredential!.user!.uid}');
        
        if (isMounted != null && isMounted!()) {
          UiHelper.showSuccessMessage(context, 'アカウントを作�Eしました');
          
          // サインアチE�E成功後�E処琁E
          await _userInfoSave();
        }
      }
    } on FirebaseAuthException catch (e) {
      Log.error('❁EサインアチE�E FirebaseAuthException: ${e.code}, ${e.message}');
      if (isMounted != null && isMounted!()) {
        String errorMessage = _getFirebaseAuthErrorMessage(e);
        UiHelper.showErrorMessage(context, errorMessage);
      }
    } catch (e) {
      Log.error('❁EサインアチE�E中に予期しなぁE��ラー: $e');
      if (isMounted != null && isMounted!()) {
        UiHelper.showErrorMessage(context, 'アカウント作�Eに失敗しました: $e');
      }
    }
  }
  
  /// パスワードリセチE��メール送信
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスを�E力してください');
      return;
    }

    try {
      final authService = ref.read(authProvider);
      await authService.sendPasswordResetEmail(email);
      
      if (isMounted != null && isMounted!()) {
        UiHelper.showSuccessMessage(context, 'パスワードリセチE��メールを送信しました');
      }
    } catch (e) {
      Log.error('❁EパスワードリセチE��メール送信エラー: $e');
      if (isMounted != null && isMounted!()) {
        UiHelper.showErrorMessage(context, 'メール送信に失敗しました: $e');
      }
    }
  }
  
  /// ユーザー名保存�E琁E
  Future<void> saveUserName(String userName) async {
    if (userName.isEmpty) {
      UiHelper.showWarningMessage(context, 'ユーザー名を入力してください');
      return;
    }

    try {
      Log.info('💾 ユーザー名保存開姁E $userName');
      
      // UserPreferencesServiceを使用してSharedPreferencesに保存
      await UserPreferencesService.saveUserName(userName);
      Log.info('✅ SharedPreferencesに保存完了');
      
      // デフォルトグループの情報も更新
      await _userInfoSave();
      Log.info('✅ デフォルトグループ更新完了');
      
      if (isMounted != null && isMounted!()) {
        UiHelper.showSuccessMessage(context, 'ユーザー名「$userName」を保存しました');
      }
    } catch (e) {
      Log.error('❌ ユーザー名保存エラー: $e');
      if (isMounted != null && isMounted!()) {
        UiHelper.showErrorMessage(context, 'ユーザー名の保存に失敗しました: $e');
      }
    }
  }
  
  /// About Dialog表示
  void showAppAboutDialog() {
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
      children: [
        const Text('家族やグループで買い物リストを共有できるアプリです。'),
        const SizedBox(height: 16),
        const Text('主な機能:'),
        const Text('• グループでの買い物リストの共有'),
        const Text('• リアルタイム同期'),
        const Text('• オフライン対応'),
        const Text('• メンバー管理'),
        const SizedBox(height: 16),
        const Text('開発者: 金ヶ江真由美 ファティマ(Maya Fatima Kanagae)'),
        const Text('お問い合わせ: fatima.sumomo@gmail.com'),
        const SizedBox(height: 16),
        const Text('© 2024 Go Shop. All rights reserved.'),
      ],
    );
  }
  
  // ========== プライベ�EトメソチE�� ==========
  
  Future<void> _saveOrClearEmail(String email, bool rememberEmail) async {
    final emailService = ref.read(emailManagementServiceProvider);
    await emailService.saveOrClearEmail(
      email: email,
      shouldRemember: rememberEmail,
    );
  }
  
  Future<void> _userInfoSave() async {
    // チE��ォルトグループ情報の更新処琁E
    // 既存�E userInfoSave() ロジチE��をここに移勁E
  }
  
  Future<void> _loadUserNameFromDefaultGroup() async {
    final groupService = ref.read(groupManagementServiceProvider);
    await groupService.loadUserNameFromDefaultGroup();
  }
  
  Future<void> _handleFirebaseAuthError(FirebaseAuthException e, String email, String password) async {
    Log.error('❁EFirebase認証エラー: ${e.code}');
    Log.error('❁EエラーメチE��ージ: ${e.message}');
    
    if (isMounted != null && isMounted!()) {
      String errorMessage = _getFirebaseAuthErrorMessage(e);
      
      if (e.code == 'user-not-found') {
        // ユーザーが見つからなぁE��合、サインアチE�Eを提桁E
        await _offerSignUp(email);
      } else {
        UiHelper.showErrorMessage(context, errorMessage);
      }
    }
  }
  
  Future<void> _offerSignUp(String email) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントが見つかりません'),
        content: Text('$email のアカウントが見つかりません、En新規アカウントを作�Eしますか�E�E),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('新規作�E'),
          ),
        ],
      ),
    );
    
    if (result == true && isMounted != null && isMounted!()) {
      // サインアチE�Eフォームに刁E��替える処琁E
      // 既存�E _performSignUp() 呼び出しロジチE��
    }
  }
  
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'こ�Eメールアドレスのアカウントが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違ってぁE��ぁE;
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'こ�Eアカウント�E無効化されてぁE��ぁE;
      case 'email-already-in-use':
        return 'こ�Eメールアドレスは既に使用されてぁE��ぁE;
      case 'weak-password':
        return 'パスワードが脁E��です。より強力なパスワードを設定してください';
      default:
        return '認証エラーが発生しました: ${e.message}';
    }
  }
}

/// HomePageAuthService用のプロバイダー
final homePageAuthServiceProvider = Provider.family<HomePageAuthService, BuildContext>((ref, context) {
  return HomePageAuthService(
    ref: ref as WidgetRef,
    context: context,
  );
});
