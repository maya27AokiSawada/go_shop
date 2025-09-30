// lib/services/auth_service.dart
// 25-08-29
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../helper/misc.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService() {
    // Firebase Auth初期化状態をログ出力
    logger.i("FirebaseAuth app: ${_auth.app.name}");
    logger.i("FirebaseAuth currentUser: ${_auth.currentUser}");
  }
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  Future<User?> signIn(String email, String password) async {
    try {
      logger.i("Attempting to sign in: $email");
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i("Sign in successful for: $email");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      logger.e("FirebaseAuth signIn error: ${e.code} - ${e.message}");
      switch (e.code) {
        case 'user-not-found':
          throw Exception('ユーザーが見つかりません。');
        case 'wrong-password':
          throw Exception('パスワードが間違っています。');
        case 'invalid-email':
          throw Exception('無効なメールアドレスです。');
        case 'user-disabled':
          throw Exception('このアカウントは無効です。');
        case 'too-many-requests':
          throw Exception('ログイン試行回数が多すぎます。しばらく待ってから再試行してください。');
        default:
          throw Exception('サインインに失敗しました: ${e.message}');
      }
    } catch (e) {
      logger.e('signIn unexpected error: $e');
      throw Exception('予期しないエラーが発生しました: $e');
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      logger.i("Attempting to create account for: $email");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i("Account created successfully for: $email");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      logger.e("FirebaseAuth signUp error: ${e.code} - ${e.message}");
      switch (e.code) {
        case 'weak-password':
          throw Exception('パスワードが弱すぎます。');
        case 'email-already-in-use':
          throw Exception('このメールアドレスは既に使用されています。');
        case 'invalid-email':
          throw Exception('無効なメールアドレスです。');
        case 'operation-not-allowed':
          throw Exception('メール/パスワード認証が無効です。管理者に連絡してください。');
        default:
          throw Exception('アカウント作成に失敗しました: ${e.message}');
      }
    } catch (e) {
      logger.e("signUp unexpected error: $e");
      throw Exception('予期しないエラーが発生しました: $e');
    }
  }
  Future<String?> getCurrentUid() async {
    try {
      final user = _auth.currentUser;
      return user?.uid;
    } catch (e) {
      logger.e("getCurrentUid error: $e");
      rethrow;
    }
  }
}
