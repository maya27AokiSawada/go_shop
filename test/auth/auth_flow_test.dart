// 認証フロー（サインアップ・サインイン）のユニットテスト
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// 🔥 重要: このテストはFirebase Authの動作フローをテストします
// 実際のFirebase接続は使用せず、モックを使用してテストします

@GenerateMocks([FirebaseAuth, User, UserCredential])
import 'auth_flow_test.mocks.dart';

void main() {
  group('認証フロー Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockUserCredential mockCredential;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockCredential = MockUserCredential();
    });

    group('サインアップフロー Tests', () {
      test('サインアップ - 正常系: メールアドレスとパスワードでアカウント作成', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'password123';
        const testUid = 'test-uid-123';

        when(mockUser.uid).thenReturn(testUid);
        when(mockUser.email).thenReturn(testEmail);
        when(mockUser.displayName).thenReturn(null);
        when(mockCredential.user).thenReturn(mockUser);

        when(mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.user, isNotNull);
        expect(result.user?.uid, testUid);
        expect(result.user?.email, testEmail);

        verify(mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).called(1);
      });

      test('サインアップ - 異常系: 既に登録済みのメールアドレス（email-already-in-use）', () async {
        // Arrange
        const testEmail = 'existing@example.com';
        const testPassword = 'password123';

        when(mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenThrow(FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        ));

        // Act & Assert
        expect(
          () => mockAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'email-already-in-use',
          )),
        );
      });

      test('サインアップ - 異常系: 弱いパスワード（weak-password）', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = '12345'; // 6文字未満

        when(mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenThrow(FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters',
        ));

        // Act & Assert
        expect(
          () => mockAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'weak-password',
          )),
        );
      });

      test('サインアップ - 異常系: 不正なメールアドレス形式（invalid-email）', () async {
        // Arrange
        const testEmail = 'invalid-email'; // @がない
        const testPassword = 'password123';

        when(mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenThrow(FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ));

        // Act & Assert
        expect(
          () => mockAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-email',
          )),
        );
      });

      test('サインアップフロー: ユーザー名設定→Firebase Auth displayName更新', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'password123';
        const testUserName = 'テストユーザー';
        const testUid = 'test-uid-123';

        when(mockUser.uid).thenReturn(testUid);
        when(mockUser.email).thenReturn(testEmail);
        when(mockUser.displayName).thenReturn(null);
        when(mockUser.updateDisplayName(testUserName))
            .thenAnswer((_) async => {});
        when(mockUser.reload()).thenAnswer((_) async => {});
        when(mockCredential.user).thenReturn(mockUser);

        when(mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        final user = result.user!;

        // ユーザー名設定フロー（実際のアプリの順序）
        // 1. SharedPreferencesに保存（モックでは省略）
        // 2. Firebase Auth displayNameを更新
        await user.updateDisplayName(testUserName);
        await user.reload();

        // Assert
        verify(user.updateDisplayName(testUserName)).called(1);
        verify(user.reload()).called(1);
      });
    });

    group('サインインフロー Tests', () {
      test('サインイン - 正常系: 登録済みユーザーでログイン成功', () async {
        // Arrange
        const testEmail = 'existing@example.com';
        const testPassword = 'password123';
        const testUid = 'existing-uid-456';

        when(mockUser.uid).thenReturn(testUid);
        when(mockUser.email).thenReturn(testEmail);
        when(mockUser.displayName).thenReturn('既存ユーザー');
        when(mockCredential.user).thenReturn(mockUser);

        when(mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.user, isNotNull);
        expect(result.user?.uid, testUid);
        expect(result.user?.email, testEmail);
        expect(result.user?.displayName, '既存ユーザー');

        verify(mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).called(1);
      });

      test('サインイン - 異常系: ユーザーが見つからない（user-not-found）', () async {
        // Arrange
        const testEmail = 'nonexistent@example.com';
        const testPassword = 'password123';

        when(mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'There is no user record corresponding to this identifier.',
        ));

        // Act & Assert
        expect(
          () => mockAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-not-found',
          )),
        );
      });

      test('サインイン - 異常系: パスワードが間違っている（wrong-password）', () async {
        // Arrange
        const testEmail = 'existing@example.com';
        const testPassword = 'wrongpassword';

        when(mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenThrow(FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid.',
        ));

        // Act & Assert
        expect(
          () => mockAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'wrong-password',
          )),
        );
      });

      test('サインイン - 異常系: アカウントが無効（user-disabled）', () async {
        // Arrange
        const testEmail = 'disabled@example.com';
        const testPassword = 'password123';

        when(mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenThrow(FirebaseAuthException(
          code: 'user-disabled',
          message: 'The user account has been disabled by an administrator.',
        ));

        // Act & Assert
        expect(
          () => mockAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-disabled',
          )),
        );
      });

      test('サインイン - 異常系: 無効な認証情報（invalid-credential）', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'wrongpassword';

        when(mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenThrow(FirebaseAuthException(
          code: 'invalid-credential',
          message:
              'The supplied auth credential is incorrect, malformed or has expired.',
        ));

        // Act & Assert
        expect(
          () => mockAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-credential',
          )),
        );
      });

      test('サインインフロー: UID変更検出パターン', () async {
        // Arrange
        const oldEmail = 'old@example.com';
        const newEmail = 'new@example.com';
        const password = 'password123';
        const oldUid = 'old-uid-123';
        const newUid = 'new-uid-456';

        // 最初のユーザー（旧UID）
        final mockOldUser = MockUser();
        when(mockOldUser.uid).thenReturn(oldUid);
        when(mockOldUser.email).thenReturn(oldEmail);

        // 新しいユーザー（新UID）
        final mockNewUser = MockUser();
        when(mockNewUser.uid).thenReturn(newUid);
        when(mockNewUser.email).thenReturn(newEmail);

        final mockNewCredential = MockUserCredential();
        when(mockNewCredential.user).thenReturn(mockNewUser);

        when(mockAuth.signInWithEmailAndPassword(
          email: newEmail,
          password: password,
        )).thenAnswer((_) async => mockNewCredential);

        // Act
        final result = await mockAuth.signInWithEmailAndPassword(
          email: newEmail,
          password: password,
        );

        // Assert
        expect(result.user?.uid, newUid);
        expect(result.user?.uid, isNot(oldUid)); // UIDが変わった
      });
    });

    group('サインアウトフロー Tests', () {
      test('サインアウト - 正常系: ログアウト成功', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await mockAuth.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });

      test('サインアウト - currentUserがnullになる', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockAuth.signOut()).thenAnswer((_) async {
          when(mockAuth.currentUser).thenReturn(null);
          return;
        });

        // Act
        expect(mockAuth.currentUser, isNotNull);
        await mockAuth.signOut();

        // Assert
        expect(mockAuth.currentUser, isNull);
      });
    });

    group('パスワードリセットフロー Tests', () {
      test('パスワードリセット - 正常系: リセットメール送信成功', () async {
        // Arrange
        const testEmail = 'test@example.com';
        when(mockAuth.sendPasswordResetEmail(email: testEmail))
            .thenAnswer((_) async => {});

        // Act
        await mockAuth.sendPasswordResetEmail(email: testEmail);

        // Assert
        verify(mockAuth.sendPasswordResetEmail(email: testEmail)).called(1);
      });

      test('パスワードリセット - 異常系: ユーザーが存在しない', () async {
        // Arrange
        const testEmail = 'nonexistent@example.com';
        when(mockAuth.sendPasswordResetEmail(email: testEmail))
            .thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'There is no user record corresponding to this identifier.',
        ));

        // Act & Assert
        expect(
          () => mockAuth.sendPasswordResetEmail(email: testEmail),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-not-found',
          )),
        );
      });
    });

    group('認証状態管理 Tests', () {
      test('currentUser - ログイン前はnull', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Assert
        expect(mockAuth.currentUser, isNull);
      });

      test('currentUser - ログイン後はUserオブジェクト', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');

        // Assert
        expect(mockAuth.currentUser, isNotNull);
        expect(mockAuth.currentUser?.uid, 'test-uid');
      });

      test('authStateChanges - ログイン状態の変化を検知', () async {
        // Arrange
        final controller = StreamController<User?>();
        when(mockAuth.authStateChanges()).thenAnswer((_) => controller.stream);

        // Act
        final states = <User?>[];
        final subscription = mockAuth.authStateChanges().listen(states.add);

        controller.add(null); // 未ログイン
        await Future.delayed(const Duration(milliseconds: 10));

        controller.add(mockUser); // ログイン
        await Future.delayed(const Duration(milliseconds: 10));

        controller.add(null); // ログアウト
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(states.length, 3);
        expect(states[0], isNull);
        expect(states[1], mockUser);
        expect(states[2], isNull);

        await subscription.cancel();
        await controller.close();
      });
    });

    group('統合シナリオ Tests', () {
      test('シナリオ1: サインアップ→ログアウト→サインイン', () async {
        // Arrange
        const testEmail = 'newuser@example.com';
        const testPassword = 'password123';
        const testUid = 'new-user-uid';

        when(mockUser.uid).thenReturn(testUid);
        when(mockUser.email).thenReturn(testEmail);
        when(mockCredential.user).thenReturn(mockUser);

        // Step 1: サインアップ
        when(mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenAnswer((_) async => mockCredential);

        final signUpResult = await mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        expect(signUpResult.user?.uid, testUid);

        // Step 2: ログアウト
        when(mockAuth.signOut()).thenAnswer((_) async {
          when(mockAuth.currentUser).thenReturn(null);
          return;
        });
        await mockAuth.signOut();
        expect(mockAuth.currentUser, isNull);

        // Step 3: サインイン
        when(mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenAnswer((_) async => mockCredential);
        when(mockAuth.currentUser).thenReturn(mockUser);

        final signInResult = await mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        expect(signInResult.user?.uid, testUid);
        expect(mockAuth.currentUser, isNotNull);
      });

      test('シナリオ2: 複数アカウント切り替え（UID変更検出）', () async {
        // Arrange
        const user1Email = 'user1@example.com';
        const user2Email = 'user2@example.com';
        const password = 'password123';
        const user1Uid = 'user1-uid';
        const user2Uid = 'user2-uid';

        final mockUser1 = MockUser();
        when(mockUser1.uid).thenReturn(user1Uid);
        when(mockUser1.email).thenReturn(user1Email);

        final mockUser2 = MockUser();
        when(mockUser2.uid).thenReturn(user2Uid);
        when(mockUser2.email).thenReturn(user2Email);

        final mockCredential1 = MockUserCredential();
        when(mockCredential1.user).thenReturn(mockUser1);

        final mockCredential2 = MockUserCredential();
        when(mockCredential2.user).thenReturn(mockUser2);

        // Step 1: User1でログイン
        when(mockAuth.signInWithEmailAndPassword(
          email: user1Email,
          password: password,
        )).thenAnswer((_) async => mockCredential1);

        final result1 = await mockAuth.signInWithEmailAndPassword(
          email: user1Email,
          password: password,
        );
        final storedUid = result1.user?.uid; // 保存されたUID
        expect(storedUid, user1Uid);

        // Step 2: ログアウト
        when(mockAuth.signOut()).thenAnswer((_) async => {});
        await mockAuth.signOut();

        // Step 3: User2でログイン（UID変更検出）
        when(mockAuth.signInWithEmailAndPassword(
          email: user2Email,
          password: password,
        )).thenAnswer((_) async => mockCredential2);

        final result2 = await mockAuth.signInWithEmailAndPassword(
          email: user2Email,
          password: password,
        );
        final newUid = result2.user?.uid;

        // Assert: UID変更を検出
        expect(newUid, user2Uid);
        expect(newUid, isNot(storedUid));
      });
    });
  });
}
