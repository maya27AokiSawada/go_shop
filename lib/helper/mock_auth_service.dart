import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class MockAuthService extends AuthService {
  User? _mockUser;

  MockAuthService() : super(auth: FirebaseAuth.instance);

  @override
  Future<User?> signIn(String email, String password) async {
    // テスト用のダミーユーザーを返す
    _mockUser = UserMock(email: email);
    return _mockUser;
  }

  @override
  Future<User?> signUp(String email, String password) async {
    _mockUser = UserMock(email: email);
    return _mockUser;
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
  }

  @override
  User? getCurrentUser() {
    return _mockUser;
  }

  @override
  String? getCurrentUid() {
    return _mockUser?.uid;
  }
}

class UserMock implements User {
  @override
  final String uid;
  @override
  final String email;

  UserMock({required this.email}) : uid = 'mock_uid_${email.hashCode}';

  // ...Userインターフェースの他のメンバーは未実装（必要に応じて追加）
  @override
  // ignore: noSuchMethod_override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
