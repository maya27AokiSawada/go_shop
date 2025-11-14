// lib/services/auth_service.dart
// 25-08-29
// lib/services/auth_service.dart
// Firebase関連は本番環境のみでインポート
import 'package:firebase_auth/firebase_auth.dart'
    if (dart.library.io) 'firebase_stub.dart';
import '../helpers/misc.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService() {
    // 本番環境でのみFirebase Auth初期化状態をログ出力
    logger.i("AuthService initialized");
    try {
      logger.i("FirebaseAuth app: ${_auth.app.name}");
      logger.i("FirebaseAuth currentUser: ${_auth.currentUser}");
    } catch (e) {
      logger.w("Firebase Auth not available (dev mode): $e");
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    throw UnimplementedError(
        'AuthService should not be used in dev mode. Use MockAuthService instead.');
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    throw UnimplementedError(
        'AuthService should not be used in dev mode. Use MockAuthService instead.');
  }

  Future<void> signOut() async {
    throw UnimplementedError(
        'AuthService should not be used in dev mode. Use MockAuthService instead.');
  }

  Future<User?> signIn(String email, String password) async {
    throw UnimplementedError(
        'AuthService should not be used in dev mode. Use MockAuthService instead.');
  }

  Future<User?> signUp(String email, String password) async {
    throw UnimplementedError(
        'AuthService should not be used in dev mode. Use MockAuthService instead.');
  }

  Future<String?> getCurrentUid() async {
    throw UnimplementedError(
        'AuthService should not be used in dev mode. Use MockAuthService instead.');
  }
}
