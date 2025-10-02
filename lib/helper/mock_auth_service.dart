// lib/helper/mock_auth_service.dart
import "misc.dart";

class MockUser {
  final String uid;
  final String email;
  MockUser({required this.uid, required this.email});
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
    
    if ((email == "pisce.plum@gmail.com" || email == "pisces.plum@gmail.com") && password == "TestPassword123!") {
      final mockUser = MockUser(email: email, uid: "C3LO8EaKwiZPt2rhi5pKoITBUSg");
      _currentUser = mockUser;
      logger.i("Mock signInWithEmail successful for: $email");
      return MockUserCredential(user: mockUser);
    } else {
      throw Exception("無効な認証情報です。開発モードでは pisce.plum@gmail.com / TestPassword123! を使用してください。");
    }
  }
  
  Future<MockUserCredential> signUpWithEmail(String email, String password) async {
    logger.i("Mock signUpWithEmail: $email");
    await Future.delayed(const Duration(milliseconds: 500));
    
    final mockUser = MockUser(email: email, uid: "mock_${DateTime.now().millisecondsSinceEpoch}");
    _currentUser = mockUser;
    logger.i("Mock signUpWithEmail successful for: $email");
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
