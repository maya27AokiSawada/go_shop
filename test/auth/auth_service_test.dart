// 認証サービス層のユニットテスト
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
import 'auth_service_test.mocks.dart';

// 認証サービスのテスト用クラス（実装のシミュレーション）
class TestAuthService {
  final FirebaseAuth auth;

  TestAuthService(this.auth);

  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  User? get currentUser => auth.currentUser;
}

void main() {
  group('認証サービス層 Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockUserCredential mockCredential;
    late TestAuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockCredential = MockUserCredential();
      authService = TestAuthService(mockAuth);
    });

    group('サインイン処理 Tests', () {
      test('サインイン成功 - Userオブジェクトが返される', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const uid = 'test-uid-123';

        when(mockUser.uid).thenReturn(uid);
        when(mockUser.email).thenReturn(email);
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, uid);
        expect(result?.email, email);
      });

      test('サインイン失敗 - FirebaseAuthExceptionをスロー', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrongpassword';

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid.',
        ));

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('サインイン - 空のメールアドレス', () async {
        // Arrange
        const email = '';
        const password = 'password123';

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ));

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-email',
          )),
        );
      });

      test('サインイン - 空のパスワード', () async {
        // Arrange
        const email = 'test@example.com';
        const password = '';

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid.',
        ));

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('サインアップ処理 Tests', () {
      test('サインアップ成功 - 新規Userオブジェクトが作成される', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'password123';
        const uid = 'new-user-uid';

        when(mockUser.uid).thenReturn(uid);
        when(mockUser.email).thenReturn(email);
        when(mockUser.displayName).thenReturn(null);
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signUp(email, password);

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, uid);
        expect(result?.email, email);
        expect(result?.displayName, isNull); // 初期状態ではdisplayNameはnull
      });

      test('サインアップ失敗 - メールアドレス既に使用中', () async {
        // Arrange
        const email = 'existing@example.com';
        const password = 'password123';

        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use.',
        ));

        // Act & Assert
        expect(
          () => authService.signUp(email, password),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'email-already-in-use',
          )),
        );
      });

      test('サインアップ失敗 - 弱いパスワード', () async {
        // Arrange
        const email = 'test@example.com';
        const password = '123'; // 6文字未満

        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters',
        ));

        // Act & Assert
        expect(
          () => authService.signUp(email, password),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'weak-password',
          )),
        );
      });

      test('サインアップ - 不正なメールアドレス形式', () async {
        // Arrange
        const email = 'invalid-email'; // @がない
        const password = 'password123';

        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ));

        // Act & Assert
        expect(
          () => authService.signUp(email, password),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-email',
          )),
        );
      });
    });

    group('サインアウト処理 Tests', () {
      test('サインアウト成功', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });

      test('サインアウト後 - currentUserがnullになる', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockAuth.signOut()).thenAnswer((_) async {
          when(mockAuth.currentUser).thenReturn(null);
          return null;
        });

        // Act
        expect(authService.currentUser, isNotNull);
        await authService.signOut();

        // Assert
        expect(authService.currentUser, isNull);
      });
    });

    group('認証状態 Tests', () {
      test('未ログイン状態 - currentUserはnull', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Assert
        expect(authService.currentUser, isNull);
      });

      test('ログイン状態 - currentUserはUserオブジェクト', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn('test@example.com');

        // Assert
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.uid, 'test-uid');
        expect(authService.currentUser?.email, 'test@example.com');
      });
    });

    group('エラーハンドリング Tests', () {
      test('ネットワークエラー - network-request-failed', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'network-request-failed',
          message: 'A network error occurred.',
        ));

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'network-request-failed',
          )),
        );
      });

      test('タイムアウトエラー - too-many-requests', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many unsuccessful login attempts.',
        ));

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'too-many-requests',
          )),
        );
      });

      test('アカウント無効エラー - user-disabled', () async {
        // Arrange
        const email = 'disabled@example.com';
        const password = 'password123';

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'user-disabled',
          message: 'The user account has been disabled.',
        ));

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-disabled',
          )),
        );
      });

      test('不明なエラー - operation-not-allowed', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Email/password accounts are not enabled.',
        ));

        // Act & Assert
        expect(
          () => authService.signUp(email, password),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'operation-not-allowed',
          )),
        );
      });
    });

    group('パフォーマンス Tests', () {
      test('サインイン - レスポンスタイム < 5秒', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockUser.uid).thenReturn('test-uid');
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500)); // 模擬遅延
          return mockCredential;
        });

        // Act
        final stopwatch = Stopwatch()..start();
        await authService.signIn(email, password);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds < 5000, true); // 5秒以内
      });

      test('連続サインイン処理 - 3回連続でエラーなし', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockUser.uid).thenReturn('test-uid');
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act & Assert
        for (int i = 0; i < 3; i++) {
          final result = await authService.signIn(email, password);
          expect(result, isNotNull);
        }

        verify(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).called(3);
      });
    });
  });
}
