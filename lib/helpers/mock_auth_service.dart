// lib/helper/mock_auth_service.dart
import "misc.dart";

class MockUser {
  final String uid;
  final String email;
  final String? displayName;
  MockUser({required this.uid, required this.email, this.displayName});
}

class MockUserCredential {
  final MockUser? user;
  MockUserCredential({this.user});
}

class MockAuthService {
  MockUser? _currentUser;
  
  MockUser? get currentUser => _currentUser;
  
  Future<MockUserCredential> signInWithEmail(String email, String password) async {
    logger.i("Mock signInWithEmail: $email");
    await Future.delayed(const Duration(milliseconds: 500));
    
    // DEVモードでは任意のメール/パスワードでログイン可能
    if (email.isNotEmpty && password.isNotEmpty) {
      // メールアドレスの@マーク前の部分をユーザー名として使用
      final displayName = email.split('@').first;
      final mockUser = MockUser(
        email: email, 
        uid: "mock_${email.hashCode}", 
        displayName: displayName
      );
      _currentUser = mockUser;
      logger.i("Mock signInWithEmail successful for: $email (displayName: $displayName)");
      return MockUserCredential(user: mockUser);
    } else {
      throw Exception("メールアドレスとパスワードを入力してください。");
    }
  }
  
  Future<MockUserCredential> signUpWithEmail(String email, String password) async {
    logger.i("Mock signUpWithEmail: $email");
    await Future.delayed(const Duration(milliseconds: 500));
    
    // メールアドレスの@マーク前の部分をユーザー名として使用
    final displayName = email.split('@').first;
    final mockUser = MockUser(
      email: email, 
      uid: "mock_${DateTime.now().millisecondsSinceEpoch}",
      displayName: displayName
    );
    _currentUser = mockUser;
    logger.i("Mock signUpWithEmail successful for: $email (displayName: $displayName)");
    return MockUserCredential(user: mockUser);
  }
  
  Future<void> signOut() async {
    logger.i("Mock signOut called");
    _currentUser = null;
  }
  
  Future<MockUser?> signIn(String email, String password) async {
    final credential = await signInWithEmail(email, password);
    return credential.user;
  }
  
  Future<MockUser?> signUp(String email, String password) async {
    final credential = await signUpWithEmail(email, password);
    return credential.user;
  }
  
  Future<String?> getCurrentUid() async {
    return _currentUser?.uid;
  }
  
  void reset() {
    _currentUser = null;
  }
}
