// lib/helper/mock_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'misc.dart';

class MockAuthService extends AuthService {
  User? _currentUser;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    logger.i("Mock signInWithEmail: $email");
    // 開発用のダミー認証
    await Future.delayed(const Duration(milliseconds: 500)); // 実際のAPIコールをシミュレート
    throw FirebaseAuthException(code: 'user-not-found', message: 'Mock user not found');
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    logger.i("Mock signUpWithEmail: $email");
    await Future.delayed(const Duration(milliseconds: 500));
    
    // ダミーのUserCredentialを返す
    final mockUser = MockUser(email: email, uid: 'mock_${email.hashCode}');
    _currentUser = mockUser;
    return MockUserCredential(user: mockUser);
  }

  @override
  Future<void> signOut() async {
    logger.i("Mock signOut");
    _currentUser = null;
  }

  @override
  Future<User?> signIn(String email, String password) async {
    logger.i("Mock signIn: $email");
    await Future.delayed(const Duration(milliseconds: 500));
    throw FirebaseAuthException(code: 'user-not-found', message: 'Mock user not found for signIn');
  }

  @override
  Future<User?> signUp(String email, String password) async {
    logger.i("Mock signUp: $email");
    await Future.delayed(const Duration(milliseconds: 500));
    
    final mockUser = MockUser(email: email, uid: 'mock_${email.hashCode}');
    _currentUser = mockUser;
    logger.i("Mock account created successfully for: $email");
    return mockUser;
  }

  @override
  Future<String?> getCurrentUid() async {
    return _currentUser?.uid;
  }
}

// 簡単なMock User実装
class MockUser implements User {
  @override
  final String? email;
  @override
  final String uid;

  MockUser({required this.email, required this.uid});

  @override
  bool get emailVerified => true;
  @override
  String? get displayName => email;
  @override
  String? get photoURL => null;
  @override
  String? get phoneNumber => null;
  @override
  bool get isAnonymous => false;
  @override
  UserMetadata get metadata => MockUserMetadata();
  @override
  List<UserInfo> get providerData => [];
  @override
  String? get refreshToken => null;
  @override
  String? get tenantId => null;
  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  // 必須メソッドのみ実装、その他はUnimplementedErrorを投げる
  @override
  Future<void> delete() async => throw UnimplementedError();
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async => throw UnimplementedError();
  @override
  Future<void> reload() async {}
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async => throw UnimplementedError();
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) async => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<void> linkWithRedirect(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<User> unlink(String providerId) async => throw UnimplementedError();
  @override
  Future<void> updatePassword(String newPassword) async => throw UnimplementedError();
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async => throw UnimplementedError();
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async => throw UnimplementedError();
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<void> updateDisplayName(String? displayName) async => throw UnimplementedError();
  @override
  Future<void> updatePhotoURL(String? photoURL) async => throw UnimplementedError();
}

class MockUserCredential implements UserCredential {
  @override
  final User user;
  @override
  final AuthCredential? credential = null;
  @override
  final AdditionalUserInfo? additionalUserInfo = null;

  MockUserCredential({required this.user});
}

class MockUserMetadata implements UserMetadata {
  @override
  DateTime? get creationTime => DateTime.now();
  @override
  DateTime? get lastSignInTime => DateTime.now();
}