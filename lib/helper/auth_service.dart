// lib/services/auth_service.dart
// 25-08-29
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      _logger.severe('signIn error: $e'); // エラー処理（必要に応じて例外を投げるなど）
      rethrow;
    }
  }
  final Logger _logger = Logger('AuthService');

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      _logger.severe("signUp error: $e");
      rethrow;
    }
  }
  Future<String?> getCurrentUid() async {
    try {
      final user = _auth.currentUser;
      return user?.uid;
    } catch (e) {
      _logger.severe("getCurrentUid error: $e");
      rethrow;
    }
  }
}
