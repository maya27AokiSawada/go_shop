import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../helper/mock_auth_service.dart';
import '../flavors.dart';

final _logger = Logger();

// Mock認証状態を管理するProvider
final mockAuthStateProvider = StateProvider<MockUser?>((ref) => null);

// 統一された認証サービスインターface
abstract class AuthServiceInterface {
  Future<dynamic> signIn(String email, String password);
  Future<dynamic> signUp(String email, String password);
  Future<void> signOut();
  dynamic get currentUser;
}

// Firebase Auth wrapper
class FirebaseAuthService implements AuthServiceInterface {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
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
  
  @override
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
  
  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  @override
  User? get currentUser => _auth.currentUser;
}

// Mock Auth Service wrapper
class MockAuthServiceWrapper implements AuthServiceInterface {
  final MockAuthService _mockService;
  
  MockAuthServiceWrapper(this._mockService);
  
  @override
  Future<MockUser?> signIn(String email, String password) async {
    return await _mockService.signIn(email, password);
  }
  
  @override
  Future<MockUser?> signUp(String email, String password) async {
    return await _mockService.signUp(email, password);
  }
  
  @override
  Future<void> signOut() async {
    await _mockService.signOut();
  }
  
  @override
  MockUser? get currentUser => _mockService.currentUser;
}

final authProvider = Provider<AuthServiceInterface>((ref) {
  // 本番環境では実際のFirebase Authを使用
  if (F.appFlavor == Flavor.prod) {
    return FirebaseAuthService();
  }
  // 開発環境ではMockAuthServiceを使用（Singleton）
  _mockAuthServiceInstance ??= MockAuthService();
  return MockAuthServiceWrapper(_mockAuthServiceInstance!);
});

// MockAuthServiceのSingletonインスタンス
MockAuthService? _mockAuthServiceInstance;

// 統一された認証状態プロバイダー - どちらの環境でも動作
final authStateProvider = StreamProvider<dynamic>((ref) {
  // 本番環境では実際のFirebase Auth状態を監視
  if (F.appFlavor == Flavor.prod) {
    return FirebaseAuth.instance.authStateChanges();
  }
  // 開発環境ではMock状態を監視
  final mockUser = ref.watch(mockAuthStateProvider);
  return Stream.value(mockUser);
});
