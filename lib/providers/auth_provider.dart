import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

// Firebase Auth Service
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<User?> signIn(String email, String password) async {
    try {
      _logger.d('🔥 FirebaseAuthService: signIn開始 - email: $email');
      _logger.d('🔥 FirebaseAuth instance: ${_auth.toString()}');
      _logger.d('🔥 FirebaseAuth currentUser: ${_auth.currentUser}');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _logger.d('🔥 FirebaseAuthService: signIn成功 - user: ${credential.user}');
      return credential.user;
    } catch (e) {
      _logger.e('🔥 FirebaseAuthService: signInでエラー発生');
      _logger.e('🔥 エラータイプ: ${e.runtimeType}');
      _logger.e('🔥 エラー内容: $e');
      if (e.toString().contains('FirebaseAuthException')) {
        _logger.e('🔥 FirebaseAuthException詳細: $e');
      }
      rethrow; // エラーを再スローして上位でキャッチ
    }
  }
  
  Future<User?> signUp(String email, String password) async {
    try {
      _logger.d('🔥 FirebaseAuthService: signUp開始 - email: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _logger.d('🔥 FirebaseAuthService: signUp成功 - user: ${credential.user}');
      return credential.user;
    } catch (e) {
      _logger.e('🔥 FirebaseAuthService: signUpでエラー発生');
      _logger.e('🔥 エラータイプ: ${e.runtimeType}');
      _logger.e('🔥 エラー内容: $e');
      rethrow; // エラーを再スローして上位でキャッチ
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  User? get currentUser => _auth.currentUser;
}



// Firebase Auth プロバイダー
final authProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Firebase認証状態プロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
