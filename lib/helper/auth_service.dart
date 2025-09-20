// lib/services/auth_service.dart
// 25-08-29
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../helper/misc.dart';


class AuthService {
  final FirebaseAuth _auth;
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      logger.e('signIn error: $e');
      rethrow;
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      logger.e('signUp error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      logger.e('signOut error: $e');
      rethrow;
    }
  }

  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      logger.e('getCurrentUser error: $e');
      return null;
    }
  }

  String? getCurrentUid() {
    try {
      return _auth.currentUser?.uid;
    } catch (e) {
      logger.e('getCurrentUid error: $e');
      return null;
    }
  }
}
