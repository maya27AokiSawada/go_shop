// test/unit/services/access_control_service_test.dart
//
// ✅ Firebase Auth Mock Implementation Complete!
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// firebase_auth_mocks パッケージを使用してFirebase Auth状態を完全にモック化。
// AccessControlService をリファクタリングして依存性注入を可能にしました。
//
// 全23テスト実行可能:
// ✅ canCreateGroup: 認証済み/未認証（2テスト）
// ✅ canEditGroup: デフォルト/通常のgroupId（2テスト）
// ✅ canInviteMembers: デフォルト/通常のgroupId（2テスト）
// ✅ toggleSecretMode: 全パターン（4テスト）
// ✅ getGroupVisibilityMode: 全パターン（3テスト）
// ✅ getAccessDeniedMessage: 全タイプ（3テスト）
// ✅ Enum Tests（2テスト）
// ✅ Edge Cases: 空文字列、連続呼び出し（3テスト）
// ✅ watchSecretMode: Stream監視（1テスト）
// ✅ isSecretModeEnabled: 初期状態/保存済み（2テスト）
//
// リファクタリング内容:
// - AccessControlService(ref, {FirebaseAuth? auth}) - オプショナルパラメータ追加
// - テスト時: MockFirebaseAuth注入
// - 本番時: デフォルトでFirebaseAuth.instance使用（既存コードへの影響ゼロ）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goshopping/services/access_control_service.dart';
import 'package:goshopping/flavors.dart';
import 'package:goshopping/providers/purchase_group_provider.dart';

// Firebase Mock Setup
Future<void> initializeFirebaseForTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
      ),
    );
  } catch (e) {
    // Firebase already initialized, ignore
  }
}

// MockRef implementation
class MockRef extends Fake implements Ref {
  final List<ProviderBase> _invalidatedProviders = [];

  List<ProviderBase> get invalidatedProviders => _invalidatedProviders;

  @override
  void invalidate(ProviderOrFamily provider) {
    _invalidatedProviders.add(provider as ProviderBase);
  }
}

void main() {
  setUpAll(() async {
    await initializeFirebaseForTest();
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessControlService - canCreateGroup', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
      SharedPreferences.setMockInitialValues({});
    });

    test('認証済みユーザーはグループ作成可能', () async {
      // Arrange
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid-001',
          email: 'test@example.com',
          displayName: 'Test User',
        ),
      );
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = service.canCreateGroup();

      // Assert
      expect(result, isTrue);
    });

    test('未認証ユーザーはグループ作成不可', () {
      // Arrange
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = service.canCreateGroup();

      // Assert
      expect(result, isFalse);
    });
  });

  group('AccessControlService - canEditGroup', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
      SharedPreferences.setMockInitialValues({});
    });

    test('デフォルトグループは常に編集可能', () {
      // Arrange
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = service.canEditGroup('default_group');

      // Assert
      expect(result, isTrue);
    });

    test('通常のgroupIdでは認証チェックが実行される', () {
      // Arrange
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid-002',
          email: 'user@example.com',
          displayName: 'Regular User',
        ),
      );
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = service.canEditGroup('group_123');

      // Assert - 認証済みユーザーはグループ編集可能
      expect(result, isTrue);
    });
  });

  group('AccessControlService - canInviteMembers', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
      SharedPreferences.setMockInitialValues({});
    });

    test('デフォルトグループは招待不可', () {
      // Arrange
      final mockAuth = MockFirebaseAuth(signedIn: true);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = service.canInviteMembers('default_group');

      // Assert
      expect(result, isFalse);
    });

    test('通常のgroupIdでは認証チェックが実行される', () {
      // Arrange
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid-003',
          email: 'inviter@example.com',
          displayName: 'Inviter User',
        ),
      );
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = service.canInviteMembers('group_456');

      // Assert - 認証済みユーザーは通常グループで招待可能
      expect(result, isTrue);
    });
  });

  group('AccessControlService - Secret Mode', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
    });

    test('初期状態ではシークレットモードはfalse', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = await service.isSecretModeEnabled();

      // Assert
      expect(result, isFalse);
    });

    test('SharedPreferencesに保存されたシークレットモードを取得できる', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'secret_mode': true});
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = await service.isSecretModeEnabled();

      // Assert
      expect(result, isTrue);
    });

    test('toggleSecretMode - シークレットモードをON→OFFに切り替え', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'secret_mode': true});
      F.appFlavor = Flavor.dev; // 開発環境で実行
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid-004',
          email: 'secretuser@example.com',
        ),
      );
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final newMode = await service.toggleSecretMode();

      // Assert
      expect(newMode, isFalse); // true → false に切り替え

      // プロバイダー無効化の確認
      expect(mockRef.invalidatedProviders, contains(allGroupsProvider));
    });

    test('toggleSecretMode - シークレットモードをOFF→ONに切り替え', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'secret_mode': false});
      F.appFlavor = Flavor.dev;
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid-005',
          email: 'normaluser@example.com',
        ),
      );
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final newMode = await service.toggleSecretMode();

      // Assert
      expect(newMode, isTrue); // false → true に切り替え
      expect(mockRef.invalidatedProviders, contains(allGroupsProvider));
    });

    test('toggleSecretMode - 初期値なしの場合はONに切り替え', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      F.appFlavor = Flavor.dev;
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid-006',
          email: 'newuser@example.com',
        ),
      );
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final newMode = await service.toggleSecretMode();

      // Assert
      expect(newMode, isTrue); // デフォルトfalse → true に切り替え
    });

    test('watchSecretMode - 現在の状態をStreamで取得', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'secret_mode': true});
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final stream = service.watchSecretMode();
      final firstValue = await stream.first;

      // Assert
      expect(firstValue, isTrue);
    });
  });

  group('AccessControlService - getGroupVisibilityMode', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
    });

    test('シークレットOFF時は常に全グループ表示', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'secret_mode': false});
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = await service.getGroupVisibilityMode();

      // Assert
      expect(result, GroupVisibilityMode.all);
    });

    test('シークレットON + 未認証時はdefaultOnlyモード', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'secret_mode': true});
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = await service.getGroupVisibilityMode();

      // Assert
      expect(result, GroupVisibilityMode.defaultOnly);
    });

    test('シークレットON + 認証済み時は全グループ表示', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'secret_mode': true});
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid-007',
          email: 'authenticated@example.com',
        ),
      );
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = await service.getGroupVisibilityMode();

      // Assert
      expect(result, GroupVisibilityMode.all);
    });

    test('シークレットモード未設定時はfalse扱い（全グループ表示）', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = await service.getGroupVisibilityMode();

      // Assert
      expect(result, GroupVisibilityMode.all);
    });
  });

  group('AccessControlService - getAccessDeniedMessage', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
      SharedPreferences.setMockInitialValues({});
    });

    test('createGroupのエラーメッセージを取得', () {
      // Arrange
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final message = service.getAccessDeniedMessage(AccessType.createGroup);

      // Assert
      expect(message, 'グループを作成するにはサインインが必要です');
    });

    test('editGroupのエラーメッセージを取得', () {
      // Arrange
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final message = service.getAccessDeniedMessage(AccessType.editGroup);

      // Assert
      expect(message, 'グループを編集するにはサインインが必要です');
    });

    test('inviteMembersのエラーメッセージを取得', () {
      // Arrange
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final message = service.getAccessDeniedMessage(AccessType.inviteMembers);

      // Assert
      expect(message, 'メンバーを招待するにはサインインが必要です');
    });
  });

  group('AccessControlService - Enum Tests', () {
    test('GroupVisibilityMode - 3つの値が定義されている', () {
      expect(GroupVisibilityMode.values.length, 3);
      expect(GroupVisibilityMode.values, contains(GroupVisibilityMode.all));
      expect(GroupVisibilityMode.values, contains(GroupVisibilityMode.defaultOnly));
      expect(GroupVisibilityMode.values, contains(GroupVisibilityMode.readOnly));
    });

    test('AccessType - 3つの値が定義されている', () {
      expect(AccessType.values.length, 3);
      expect(AccessType.values, contains(AccessType.createGroup));
      expect(AccessType.values, contains(AccessType.editGroup));
      expect(AccessType.values, contains(AccessType.inviteMembers));
    });
  });

  group('AccessControlService - Edge Cases', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
    });

    test('空文字列のgroupIdでcanEditGroupを呼び出し', () {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = service.canEditGroup('');

      // Assert
      expect(result, isFalse); // 未認証ユーザーは編集不可
    });

    test('空文字列のgroupIdでcanInviteMembersを呼び出し', () {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final result = service.canInviteMembers('');

      // Assert
      // デフォルトグループ以外なので認証チェック実行
      expect(result, isFalse); // 未認証ユーザーは招待不可
    });

    test('toggleSecretMode - 連続呼び出しで状態が正しく切り替わる', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'secret_mode': false});
      F.appFlavor = Flavor.dev;
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid-008',
          email: 'multiuser@example.com',
        ),
      );
      final service = AccessControlService(mockRef, auth: mockAuth);

      // Act
      final firstToggle = await service.toggleSecretMode();  // false → true
      final secondToggle = await service.toggleSecretMode(); // true → false
      final thirdToggle = await service.toggleSecretMode();  // false → true

      // Assert
      expect(firstToggle, isTrue);
      expect(secondToggle, isFalse);
      expect(thirdToggle, isTrue);

      // プロバイダー無効化が3回実行されている
      expect(mockRef.invalidatedProviders.length, 3);
    });
  });
}
