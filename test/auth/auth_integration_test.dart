// 認証統合フローのテスト
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
import 'auth_integration_test.mocks.dart';

// 統合フロー用の認証サービス
class IntegratedAuthService {
  final FirebaseAuth auth;
  final List<String> eventLog = []; // イベントログ

  IntegratedAuthService(this.auth);

  Future<User?> performSignUp(
      String email, String password, String displayName) async {
    eventLog.add('signUp_start');

    try {
      // 1. Firebase Auth登録
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        eventLog.add('signUp_failed_no_user');
        return null;
      }

      eventLog.add('signUp_auth_success');

      // 2. displayName設定
      await user.updateDisplayName(displayName);
      eventLog.add('signUp_displayname_updated');

      // 3. ユーザー情報リロード
      await user.reload();
      eventLog.add('signUp_complete');

      return auth.currentUser;
    } catch (e) {
      eventLog.add('signUp_error: ${e.toString()}');
      rethrow;
    }
  }

  Future<User?> performSignIn(String email, String password) async {
    eventLog.add('signIn_start');

    try {
      // Firebase Authサインイン
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      eventLog.add('signIn_success');
      return credential.user;
    } catch (e) {
      eventLog.add('signIn_error: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> performSignOut() async {
    eventLog.add('signOut_start');

    try {
      await auth.signOut();
      eventLog.add('signOut_complete');
    } catch (e) {
      eventLog.add('signOut_error: ${e.toString()}');
      rethrow;
    }
  }

  void clearEventLog() {
    eventLog.clear();
  }
}

void main() {
  group('認証統合フロー Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockUserCredential mockCredential;
    late IntegratedAuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockCredential = MockUserCredential();
      authService = IntegratedAuthService(mockAuth);
    });

    group('サインアップ完全フロー Tests', () {
      test('サインアップフロー - 正常系（Auth登録→displayName設定→reload）', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'password123';
        const displayName = 'テストユーザー';
        const uid = 'new-user-uid';

        when(mockUser.uid).thenReturn(uid);
        when(mockUser.email).thenReturn(email);
        when(mockUser.displayName).thenReturn(null); // 初期状態
        when(mockUser.updateDisplayName(displayName)).thenAnswer((_) async {
          when(mockUser.displayName).thenReturn(displayName); // 更新後
        });
        when(mockUser.reload()).thenAnswer((_) async {});
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result =
            await authService.performSignUp(email, password, displayName);

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, uid);
        expect(authService.eventLog, [
          'signUp_start',
          'signUp_auth_success',
          'signUp_displayname_updated',
          'signUp_complete',
        ]);

        verify(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).called(1);
        verify(mockUser.updateDisplayName(displayName)).called(1);
        verify(mockUser.reload()).called(1);
      });

      test('サインアップフロー - displayName設定失敗時もAuth登録は成功', () async {
        // Arrange
        const email = 'user@example.com';
        const password = 'password123';
        const displayName = 'ユーザー';
        const uid = 'user-uid';

        when(mockUser.uid).thenReturn(uid);
        when(mockUser.email).thenReturn(email);
        when(mockUser.displayName).thenReturn(null);
        when(mockUser.updateDisplayName(displayName))
            .thenThrow(Exception('displayName update failed'));
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act & Assert
        try {
          await authService.performSignUp(email, password, displayName);
          fail('Expected exception but none was thrown');
        } catch (e) {
          expect(e, isA<Exception>());
          // Auth登録は成功していることを確認
          expect(authService.eventLog.contains('signUp_auth_success'), true);
          // エラーログが記録されていることを確認
          expect(
              authService.eventLog.any((log) => log.contains('signUp_error')),
              true);
        }
      });
    });

    group('サインイン→サインアウトフロー Tests', () {
      test('サインイン→サインアウトフロー - 正常系', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const uid = 'test-uid';

        when(mockUser.uid).thenReturn(uid);
        when(mockUser.email).thenReturn(email);
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockAuth.signOut()).thenAnswer((_) async {
          when(mockAuth.currentUser).thenReturn(null);
        });

        // Act - サインイン
        final signInResult = await authService.performSignIn(email, password);

        // Assert - サインイン成功
        expect(signInResult, isNotNull);
        expect(signInResult?.uid, uid);
        expect(authService.eventLog, ['signIn_start', 'signIn_success']);

        // Act - サインアウト
        await authService.performSignOut();

        // Assert - サインアウト成功
        expect(authService.eventLog, [
          'signIn_start',
          'signIn_success',
          'signOut_start',
          'signOut_complete',
        ]);
        expect(mockAuth.currentUser, isNull);
      });

      test('サインアウト - すでにログアウト状態でもエラーなし', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.performSignOut();

        // Assert
        expect(authService.eventLog, [
          'signOut_start',
          'signOut_complete',
        ]);
      });
    });

    group('マルチユーザー切り替えフロー Tests', () {
      test('ユーザーA→サインアウト→ユーザーBサインイン', () async {
        // Arrange
        const userAEmail = 'userA@example.com';
        const userAPassword = 'passwordA';
        const userAUid = 'user-a-uid';
        const userBEmail = 'userB@example.com';
        const userBPassword = 'passwordB';
        const userBUid = 'user-b-uid';

        final mockUserA = MockUser();
        final mockUserB = MockUser();
        final mockCredentialA = MockUserCredential();
        final mockCredentialB = MockUserCredential();

        // ユーザーA設定
        when(mockUserA.uid).thenReturn(userAUid);
        when(mockUserA.email).thenReturn(userAEmail);
        when(mockCredentialA.user).thenReturn(mockUserA);

        // ユーザーB設定
        when(mockUserB.uid).thenReturn(userBUid);
        when(mockUserB.email).thenReturn(userBEmail);
        when(mockCredentialB.user).thenReturn(mockUserB);

        // ユーザーAサインイン
        when(mockAuth.signInWithEmailAndPassword(
          email: userAEmail,
          password: userAPassword,
        )).thenAnswer((_) async => mockCredentialA);
        when(mockAuth.currentUser).thenReturn(mockUserA);

        // Act - ユーザーAサインイン
        final userA =
            await authService.performSignIn(userAEmail, userAPassword);
        expect(userA?.uid, userAUid);

        authService.clearEventLog();

        // ユーザーAサインアウト
        when(mockAuth.signOut()).thenAnswer((_) async {
          when(mockAuth.currentUser).thenReturn(null);
        });

        // Act - ユーザーAサインアウト
        await authService.performSignOut();
        expect(mockAuth.currentUser, isNull);

        // ユーザーBサインイン
        when(mockAuth.signInWithEmailAndPassword(
          email: userBEmail,
          password: userBPassword,
        )).thenAnswer((_) async => mockCredentialB);
        when(mockAuth.currentUser).thenReturn(mockUserB);

        authService.clearEventLog();

        // Act - ユーザーBサインイン
        final userB =
            await authService.performSignIn(userBEmail, userBPassword);

        // Assert
        expect(userB?.uid, userBUid);
        expect(authService.eventLog, [
          'signIn_start',
          'signIn_success',
        ]);
      });
    });

    group('エラーリカバリーフロー Tests', () {
      test('サインイン失敗→リトライ成功', () async {
        // Arrange
        const email = 'test@example.com';
        const wrongPassword = 'wrong123';
        const correctPassword = 'password123';
        const uid = 'test-uid';

        // 1回目：失敗
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: wrongPassword,
        )).thenThrow(FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid.',
        ));

        // Act - 1回目失敗
        try {
          await authService.performSignIn(email, wrongPassword);
          fail('Expected FirebaseAuthException');
        } catch (e) {
          expect(e, isA<FirebaseAuthException>());
        }

        expect(authService.eventLog.last.contains('signIn_error'), true);

        authService.clearEventLog();

        // 2回目：成功
        when(mockUser.uid).thenReturn(uid);
        when(mockUser.email).thenReturn(email);
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: correctPassword,
        )).thenAnswer((_) async => mockCredential);

        // Act - 2回目成功
        final result = await authService.performSignIn(email, correctPassword);

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, uid);
        expect(authService.eventLog, [
          'signIn_start',
          'signIn_success',
        ]);
      });

      test('ネットワークエラー→リトライ成功', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const uid = 'test-uid';

        // 1回目：ネットワークエラー
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'network-request-failed',
          message: 'A network error occurred.',
        ));

        // Act - 1回目失敗
        try {
          await authService.performSignIn(email, password);
          fail('Expected FirebaseAuthException');
        } catch (e) {
          expect(e, isA<FirebaseAuthException>());
        }

        authService.clearEventLog();

        // 2回目：成功
        when(mockUser.uid).thenReturn(uid);
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act - 2回目成功
        final result = await authService.performSignIn(email, password);

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, uid);
      });
    });

    group('連続操作フロー Tests', () {
      test('サインアップ→即座にサインアウト→サインイン', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const displayName = 'テストユーザー';
        const uid = 'test-uid';

        when(mockUser.uid).thenReturn(uid);
        when(mockUser.email).thenReturn(email);
        when(mockUser.displayName).thenReturn(null);
        when(mockUser.updateDisplayName(displayName)).thenAnswer((_) async {});
        when(mockUser.reload()).thenAnswer((_) async {});
        when(mockCredential.user).thenReturn(mockUser);

        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act - サインアップ
        await authService.performSignUp(email, password, displayName);
        expect(authService.eventLog.last, 'signUp_complete');

        authService.clearEventLog();

        // サインアウト
        when(mockAuth.signOut()).thenAnswer((_) async {
          when(mockAuth.currentUser).thenReturn(null);
        });
        await authService.performSignOut();

        authService.clearEventLog();

        // サインイン
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);
        when(mockAuth.currentUser).thenReturn(mockUser);

        final result = await authService.performSignIn(email, password);

        // Assert
        expect(result, isNotNull);
        expect(authService.eventLog, [
          'signIn_start',
          'signIn_success',
        ]);
      });

      test('複数回サインイン/サインアウト繰り返し', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const uid = 'test-uid';

        when(mockUser.uid).thenReturn(uid);
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act - 3回繰り返し
        for (int i = 0; i < 3; i++) {
          authService.clearEventLog();

          // サインイン
          when(mockAuth.currentUser).thenReturn(mockUser);
          await authService.performSignIn(email, password);
          expect(authService.eventLog.last, 'signIn_success');

          // サインアウト
          when(mockAuth.signOut()).thenAnswer((_) async {
            when(mockAuth.currentUser).thenReturn(null);
          });
          await authService.performSignOut();
          expect(authService.eventLog.last, 'signOut_complete');
        }

        // Assert
        verify(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).called(3);
        verify(mockAuth.signOut()).called(3);
      });
    });
  });
}
