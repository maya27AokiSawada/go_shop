import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../helpers/ui_helper.dart';
import '../services/authentication_service.dart';
import '../services/user_preferences_service.dart';
import 'auth_provider.dart';

/// Home Page用の拡張認証サービス
class HomePageAuthService {
  final WidgetRef ref;
  final BuildContext context;
  
  HomePageAuthService({
    required this.ref,
    required this.context,
  });
  
  /// サインイン処理
  Future<void> performSignIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスとパスワードを入力してください');
      return;
    }

    try {
      Log.info('🔧 サインイン開始: $email');
      
      final userCredential = await AuthenticationService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential == null) {
        UiHelper.showErrorMessage(context, 'ログインに失敗しました');
        return;
      }
      
      UiHelper.showSuccessMessage(context, 'ログインしました');
      
    } on FirebaseAuthException catch (e) {
      await handleFirebaseAuthError(e, email);
    } catch (e) {
      Log.error('❌ サインイン中に予期しないエラー: $e');
      UiHelper.showErrorMessage(context, 'サインインに失敗しました: $e');
    }
  }
  
  /// サインアップ処理
  Future<void> performSignUp(String email, String password, String userName) async {
    if (email.isEmpty || password.isEmpty || userName.isEmpty) {
      UiHelper.showWarningMessage(context, 'すべての項目を入力してください');
      return;
    }

    try {
      Log.info('🆕 サインアップ開始: $email');
      
      // FirebaseAuthServiceを使用してサインアップ
      final authService = ref.read(authProvider);
      final user = await authService.signUp(email, password);
      
      if (user != null) {
        Log.info('✅ サインアップ成功: ${user.uid}');
        UiHelper.showSuccessMessage(context, 'アカウントを作成しました');
      }
    } on FirebaseAuthException catch (e) {
      Log.error('❌ サインアップ FirebaseAuthException: ${e.code}, ${e.message}');
      String errorMessage = getFirebaseAuthErrorMessage(e);
      UiHelper.showErrorMessage(context, errorMessage);
    } catch (e) {
      Log.error('❌ サインアップ中に予期しないエラー: $e');
      UiHelper.showErrorMessage(context, 'アカウント作成に失敗しました: $e');
    }
  }
  
  /// パスワードリセットメール送信
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスを入力してください');
      return;
    }

    try {
      final authService = ref.read(authProvider);
      await authService.sendPasswordResetEmail(email);
      UiHelper.showSuccessMessage(context, 'パスワードリセットメールを送信しました');
    } catch (e) {
      Log.error('❌ パスワードリセットメール送信エラー: $e');
      UiHelper.showErrorMessage(context, 'メール送信に失敗しました: $e');
    }
  }
  
  /// ユーザー名保存処理
  Future<void> saveUserName(String userName) async {
    if (userName.isEmpty) {
      UiHelper.showWarningMessage(context, 'ユーザー名を入力してください');
      return;
    }

    try {
      Log.info('💾 ユーザー名保存開始: $userName');
      
      // SharedPreferencesに保存
      await UserPreferencesService.saveUserName(userName);
      Log.info('✅ SharedPreferencesに保存完了');
      
      UiHelper.showSuccessMessage(context, 'ユーザー名「$userName」を保存しました');
    } catch (e) {
      Log.error('❌ ユーザー名保存エラー: $e');
      UiHelper.showErrorMessage(context, 'ユーザー名の保存に失敗しました: $e');
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
  
  /// Firebase認証エラー処理
  Future<void> handleFirebaseAuthError(FirebaseAuthException e, String email) async {
    Log.error('❌ Firebase認証エラー: ${e.code}');
    Log.error('❌ エラーメッセージ: ${e.message}');
    
    String errorMessage = getFirebaseAuthErrorMessage(e);
    
    if (e.code == 'user-not-found') {
      // ユーザーが見つからない場合、サインアップを提案
      await offerSignUp(email);
    } else {
      UiHelper.showErrorMessage(context, errorMessage);
    }
  }
  
  /// サインアップ提案ダイアログ
  Future<void> offerSignUp(String email) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントが見つかりません'),
        content: Text('$email のアカウントが見つかりません。\n新規アカウントを作成しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('新規作成'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      // サインアップフォームに切り替える処理をここに追加
      Log.info('ユーザーがサインアップを選択しました');
    }
  }
  
  /// Firebase Auth エラーメッセージ取得
  String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'このメールアドレスのアカウントが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードが脆弱です。より強力なパスワードを設定してください';
      default:
        return '認証エラーが発生しました: ${e.message}';
    }
  }
}

/// HomePageAuthService用のプロバイダー
/// 使用例: final authService = HomePageAuthService(ref: ref, context: context);
/// Riverpodプロバイダーとしては使用しません。直接インスタンス化してください。