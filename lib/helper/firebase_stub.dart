// lib/helper/firebase_stub.dart
// devフレーバー用のFirebase Auth stub

// Firebase Auth stub
class FirebaseAuth {
  static FirebaseAuth get instance => FirebaseAuth._();
  FirebaseAuth._();
  
  Stream<User?> authStateChanges() => Stream.value(null);
  
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Firebase Auth not available in dev mode');
  }
  
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Firebase Auth not available in dev mode');
  }
  
  Future<void> signOut() async {
    throw UnimplementedError('Firebase Auth not available in dev mode');
  }
  
  User? get currentUser => null;
}

class User {
  final String uid = 'dev-stub-uid';
  final String? email = 'dev@example.com';
  final String? displayName = 'Dev User';
}

class UserCredential {
  final User? user = null;
}

class FirebaseAuthException implements Exception {
  final String code;
  final String? message;
  
  const FirebaseAuthException({required this.code, this.message});
  
  @override
  String toString() => 'FirebaseAuthException: $code - $message';
}