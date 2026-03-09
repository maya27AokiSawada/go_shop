// test/datastore/hybrid_purchase_group_repository_test.dart
//
// ✅ HybridSharedGroupRepository Unit Tests
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DI（依存性注入）を使用して HiveRepo / FirestoreRepo をモック化。
// _safeAsyncFirestoreInitialization() をバイパスして、
// 各メソッドの分岐ロジックを直接テストする。
//
// テスト戦略:
// - getGroupById: waitForSafeInitialization() を呼ばないため直接テスト可能
// - getAllGroupsForUI: waitForSafeInitialization() を呼ばないため直接テスト可能
// - updateGroup / deleteGroup: Hive-first + Firestore同期ロジック
// - addMember / removeMember / setMemberId: Hive-first + unawaited Firestore
// - Member Pool ops: 全てHiveに委譲（Firestore不使用）
//
// 注意: waitForSafeInitialization() を使うメソッド (getAllGroups, createGroup) は
// 非同期初期化の完了が必要なため、Hive-onlyパスのみテスト。
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';

import 'package:goshopping/models/shared_group.dart';
import 'package:goshopping/datastore/hybrid_purchase_group_repository.dart';
import 'package:goshopping/datastore/hive_shared_group_repository.dart';
import 'package:goshopping/datastore/firestore_purchase_group_repository.dart';
import 'package:goshopping/flavors.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Mock Classes
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Mockitoの手動モックでは、non-nullable Futureを返すメソッドのwhen()呼び出し時に
// デフォルトのnullが返されてTypeErrorが発生する。
// noSuchMethodでreturnValueを指定して回避する。

const _dummyGroup = SharedGroup(
  groupId: '_dummy_',
  groupName: '_dummy_',
  ownerUid: '_dummy_',
  ownerName: '_dummy_',
  ownerEmail: '_dummy_',
  members: [],
  allowedUid: [],
);

class MockHiveSharedGroupRepository extends Mock
    implements HiveSharedGroupRepository {
  @override
  Future<SharedGroup> getGroupById(String groupId) => super.noSuchMethod(
        Invocation.method(#getGroupById, [groupId]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<List<SharedGroup>> getAllGroups() => super.noSuchMethod(
        Invocation.method(#getAllGroups, []),
        returnValue: Future<List<SharedGroup>>.value(<SharedGroup>[]),
      ) as Future<List<SharedGroup>>;

  @override
  Future<SharedGroup> createGroup(
          String groupId, String groupName, SharedGroupMember member) =>
      super.noSuchMethod(
        Invocation.method(#createGroup, [groupId, groupName, member]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> deleteGroup(String groupId) => super.noSuchMethod(
        Invocation.method(#deleteGroup, [groupId]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> addMember(String groupId, SharedGroupMember member) =>
      super.noSuchMethod(
        Invocation.method(#addMember, [groupId, member]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> removeMember(String groupId, SharedGroupMember member) =>
      super.noSuchMethod(
        Invocation.method(#removeMember, [groupId, member]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> setMemberId(
          String oldMemberId, String newMemberId, String? contact) =>
      super.noSuchMethod(
        Invocation.method(#setMemberId, [oldMemberId, newMemberId, contact]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group) =>
      super.noSuchMethod(
        Invocation.method(#updateGroup, [groupId, group]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> getOrCreateMemberPool() => super.noSuchMethod(
        Invocation.method(#getOrCreateMemberPool, []),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<void> syncMemberPool() => super.noSuchMethod(
        Invocation.method(#syncMemberPool, []),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<List<SharedGroupMember>> searchMembersInPool(String query) =>
      super.noSuchMethod(
        Invocation.method(#searchMembersInPool, [query]),
        returnValue:
            Future<List<SharedGroupMember>>.value(<SharedGroupMember>[]),
      ) as Future<List<SharedGroupMember>>;

  @override
  Future<SharedGroupMember?> findMemberByEmail(String email) =>
      super.noSuchMethod(
        Invocation.method(#findMemberByEmail, [email]),
        returnValue: Future<SharedGroupMember?>.value(null),
      ) as Future<SharedGroupMember?>;

  @override
  Future<int> cleanupDeletedGroups() => super.noSuchMethod(
        Invocation.method(#cleanupDeletedGroups, []),
        returnValue: Future<int>.value(0),
      ) as Future<int>;
}

class MockFirestoreSharedGroupRepository extends Mock
    implements FirestoreSharedGroupRepository {
  @override
  Future<SharedGroup> getGroupById(String groupId) => super.noSuchMethod(
        Invocation.method(#getGroupById, [groupId]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<List<SharedGroup>> getAllGroups() => super.noSuchMethod(
        Invocation.method(#getAllGroups, []),
        returnValue: Future<List<SharedGroup>>.value(<SharedGroup>[]),
      ) as Future<List<SharedGroup>>;

  @override
  Future<SharedGroup> createGroup(
          String groupId, String groupName, SharedGroupMember member) =>
      super.noSuchMethod(
        Invocation.method(#createGroup, [groupId, groupName, member]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> deleteGroup(String groupId) => super.noSuchMethod(
        Invocation.method(#deleteGroup, [groupId]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> addMember(String groupId, SharedGroupMember member) =>
      super.noSuchMethod(
        Invocation.method(#addMember, [groupId, member]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> removeMember(String groupId, SharedGroupMember member) =>
      super.noSuchMethod(
        Invocation.method(#removeMember, [groupId, member]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> setMemberId(
          String oldMemberId, String newMemberId, String? contact) =>
      super.noSuchMethod(
        Invocation.method(#setMemberId, [oldMemberId, newMemberId, contact]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group) =>
      super.noSuchMethod(
        Invocation.method(#updateGroup, [groupId, group]),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<SharedGroup> getOrCreateMemberPool() => super.noSuchMethod(
        Invocation.method(#getOrCreateMemberPool, []),
        returnValue: Future<SharedGroup>.value(_dummyGroup),
      ) as Future<SharedGroup>;

  @override
  Future<void> syncMemberPool() => super.noSuchMethod(
        Invocation.method(#syncMemberPool, []),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<List<SharedGroupMember>> searchMembersInPool(String query) =>
      super.noSuchMethod(
        Invocation.method(#searchMembersInPool, [query]),
        returnValue:
            Future<List<SharedGroupMember>>.value(<SharedGroupMember>[]),
      ) as Future<List<SharedGroupMember>>;

  @override
  Future<SharedGroupMember?> findMemberByEmail(String email) =>
      super.noSuchMethod(
        Invocation.method(#findMemberByEmail, [email]),
        returnValue: Future<SharedGroupMember?>.value(null),
      ) as Future<SharedGroupMember?>;

  @override
  Future<int> cleanupDeletedGroups() => super.noSuchMethod(
        Invocation.method(#cleanupDeletedGroups, []),
        returnValue: Future<int>.value(0),
      ) as Future<int>;
}

class MockRef extends Fake implements Ref {
  @override
  void invalidate(ProviderOrFamily provider) {
    // no-op for tests
  }

  @override
  T read<T>(ProviderListenable<T> provider) {
    // Return a dummy — this is called by _safeAsyncFirestoreInitialization
    // which we bypass via DI, so it should not be reached in normal test flow.
    throw UnimplementedError('MockRef.read called for $provider');
  }
}

// Firebase test init (required because constructor may touch FirebaseAuth)
Future<void> _initFirebase() async {
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
  } catch (_) {
    // already initialized
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Test Helpers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SharedGroup _makeGroup({
  String groupId = 'group-001',
  String groupName = 'テストグループ',
  String ownerUid = 'owner-uid',
  List<SharedGroupMember>? members,
}) {
  return SharedGroup(
    groupId: groupId,
    groupName: groupName,
    ownerUid: ownerUid,
    ownerName: 'テストオーナー',
    ownerEmail: 'owner@test.com',
    members: members ??
        [
          const SharedGroupMember(
            memberId: 'owner-uid',
            name: 'テストオーナー',
            contact: 'owner@test.com',
            role: SharedGroupRole.owner,
          ),
        ],
    allowedUid: [ownerUid],
  );
}

SharedGroupMember _makeMember({
  String memberId = 'member-001',
  String name = 'テストメンバー',
  String contact = 'member@test.com',
  SharedGroupRole role = SharedGroupRole.member,
}) {
  return SharedGroupMember(
    memberId: memberId,
    name: name,
    contact: contact,
    role: role,
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Tests
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

void main() {
  setUpAll(() async {
    await _initFirebase();
  });

  // ================================================================
  // getGroupById — Firestore-first + Hive fallback
  // ================================================================
  group('getGroupById', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
    });

    test('Firestore成功時: Firestoreから取得しHiveにキャッシュ', () async {
      final group = _makeGroup();
      when(mockFirestore.getGroupById('group-001'))
          .thenAnswer((_) async => group);
      when(mockHive.saveGroup(group)).thenAnswer((_) async {});

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      // Async init runs in background; getGroupById doesn't wait for it.
      // _firestoreRepo is set in constructor before async init.
      final result = await repo.getGroupById('group-001');

      expect(result.groupId, equals('group-001'));
      expect(result.groupName, equals('テストグループ'));
      verify(mockFirestore.getGroupById('group-001')).called(1);
      verify(mockHive.saveGroup(group)).called(1);
    });

    test('Firestoreエラー時: Hiveからフォールバック取得', () async {
      final group = _makeGroup();
      when(mockFirestore.getGroupById('group-001'))
          .thenThrow(Exception('Firestore error'));
      when(mockHive.getGroupById('group-001')).thenAnswer((_) async => group);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.getGroupById('group-001');

      expect(result.groupId, equals('group-001'));
      verify(mockFirestore.getGroupById('group-001')).called(1);
      verify(mockHive.getGroupById('group-001')).called(1);
    });

    test('Firestoreがnull（Hive-onlyモード）: Hiveから直接取得', () async {
      final group = _makeGroup();
      when(mockHive.getGroupById('group-001')).thenAnswer((_) async => group);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        // firestoreRepo: null → Hive-onlyモード
      );

      final result = await repo.getGroupById('group-001');

      expect(result.groupId, equals('group-001'));
      verify(mockHive.getGroupById('group-001')).called(1);
      // mockFirestore was not injected, so no calls expected
      // (verifyNever with non-nullable requires typed matcher)
    });
  });

  // ================================================================
  // getAllGroupsForUI — no waitForSafeInitialization
  // ================================================================
  group('getAllGroupsForUI', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
    });

    test('Firestore成功: Firestoreからグループ一覧取得しHiveにキャッシュ', () async {
      final groups = [
        _makeGroup(groupId: 'g1', groupName: 'Group A'),
        _makeGroup(groupId: 'g2', groupName: 'Group B'),
      ];
      when(mockFirestore.getAllGroups()).thenAnswer((_) async => groups);
      for (final g in groups) {
        when(mockHive.saveGroup(g)).thenAnswer((_) async {});
      }
      when(mockHive.getAllGroups()).thenAnswer((_) async => groups);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.getAllGroupsForUI();

      expect(result.length, equals(2));
      expect(result[0].groupName, equals('Group A'));
      verify(mockFirestore.getAllGroups()).called(1);
    });

    test('Firestoreエラー: Hiveフォールバック', () async {
      final groups = [_makeGroup(groupId: 'g1', groupName: 'Hiveグループ')];
      when(mockFirestore.getAllGroups())
          .thenThrow(Exception('Firestore error'));
      when(mockHive.getAllGroups()).thenAnswer((_) async => groups);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.getAllGroupsForUI();

      expect(result.length, equals(1));
      expect(result[0].groupName, equals('Hiveグループ'));
      verify(mockHive.getAllGroups()).called(1);
    });

    test('Firestore null: Hiveのみ', () async {
      final groups = [_makeGroup(groupId: 'g1')];
      when(mockHive.getAllGroups()).thenAnswer((_) async => groups);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
      );

      final result = await repo.getAllGroupsForUI();

      expect(result.length, equals(1));
      verify(mockHive.getAllGroups()).called(1);
    });

    test('両方エラー: 空リスト返却', () async {
      when(mockFirestore.getAllGroups())
          .thenThrow(Exception('Firestore error'));
      when(mockHive.getAllGroups()).thenThrow(Exception('Hive error'));

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.getAllGroupsForUI();

      // getAllGroupsForUI catches all errors and returns empty list
      expect(result, isEmpty);
    });
  });

  // ================================================================
  // updateGroup — Hive-first + Firestore sync
  // ================================================================
  group('updateGroup', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
    });

    test('Hive保存成功 + Firestore同期成功', () async {
      final group = _makeGroup();
      when(mockHive.saveGroup(group)).thenAnswer((_) async {});
      when(mockFirestore.updateGroup('group-001', group))
          .thenAnswer((_) async => group);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.updateGroup('group-001', group);

      expect(result.groupId, equals('group-001'));
      verify(mockHive.saveGroup(group)).called(greaterThanOrEqualTo(1));
      verify(mockFirestore.updateGroup('group-001', group)).called(1);
    });

    test('Hive保存成功 + Firestoreエラー: Hive保存済みのグループを返却', () async {
      final group = _makeGroup();
      when(mockHive.saveGroup(group)).thenAnswer((_) async {});
      when(mockFirestore.updateGroup('group-001', group))
          .thenThrow(Exception('Firestore error'));

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.updateGroup('group-001', group);

      // Firestoreエラーでも、Hive保存済みのグループが返る
      expect(result.groupId, equals('group-001'));
      verify(mockHive.saveGroup(group)).called(1);
    });

    test('Firestoreがnull: Hiveのみ保存', () async {
      final group = _makeGroup();
      when(mockHive.saveGroup(group)).thenAnswer((_) async {});

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
      );

      final result = await repo.updateGroup('group-001', group);

      expect(result.groupId, equals('group-001'));
      verify(mockHive.saveGroup(group)).called(1);
      // Firestore not injected, no calls expected
    });

    test('Firestore更新でハッシュ差分 → Hiveに再保存', () async {
      final group = _makeGroup(groupName: 'Before');
      final updatedGroup = _makeGroup(groupName: 'After');
      when(mockHive.saveGroup(group)).thenAnswer((_) async {});
      when(mockHive.saveGroup(updatedGroup)).thenAnswer((_) async {});
      when(mockFirestore.updateGroup('group-001', group))
          .thenAnswer((_) async => updatedGroup);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.updateGroup('group-001', group);

      expect(result.groupName, equals('After'));
      // saveGroup called: (1) Hive-first + (2) Firestore diff sync back
      verify(mockHive.saveGroup(group)).called(1);
      verify(mockHive.saveGroup(updatedGroup)).called(1);
    });
  });

  // ================================================================
  // deleteGroup — Hive-first + Firestore delete
  // ================================================================
  group('deleteGroup', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
    });

    test('Hive削除 + Firestore削除成功', () async {
      final group = _makeGroup();
      when(mockHive.deleteGroup('group-001')).thenAnswer((_) async => group);
      when(mockFirestore.deleteGroup('group-001'))
          .thenAnswer((_) async => group);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.deleteGroup('group-001');

      expect(result.groupId, equals('group-001'));
      verify(mockHive.deleteGroup('group-001')).called(1);
      verify(mockFirestore.deleteGroup('group-001')).called(1);
    });

    test('Hive削除成功 + Firestoreエラー: 処理継続', () async {
      final group = _makeGroup();
      when(mockHive.deleteGroup('group-001')).thenAnswer((_) async => group);
      when(mockFirestore.deleteGroup('group-001'))
          .thenThrow(Exception('Firestore error'));

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      // Firestoreエラーでもクラッシュしない
      final result = await repo.deleteGroup('group-001');

      expect(result.groupId, equals('group-001'));
      verify(mockHive.deleteGroup('group-001')).called(1);
    });

    test('member_poolグループ: Hiveのみ削除', () async {
      final poolGroup = _makeGroup(groupId: 'member_pool', groupName: 'Pool');
      when(mockHive.deleteGroup('member_pool'))
          .thenAnswer((_) async => poolGroup);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.deleteGroup('member_pool');

      expect(result.groupId, equals('member_pool'));
      verify(mockHive.deleteGroup('member_pool')).called(1);
      // Firestore delete should not be called for member_pool
    });

    test('Firestoreがnull: Hiveのみ削除', () async {
      final group = _makeGroup();
      when(mockHive.deleteGroup('group-001')).thenAnswer((_) async => group);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
      );

      final result = await repo.deleteGroup('group-001');

      expect(result.groupId, equals('group-001'));
      verify(mockHive.deleteGroup('group-001')).called(1);
    });
  });

  // ================================================================
  // addMember — Hive-first + unawaited Firestore
  // ================================================================
  group('addMember', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
      F.appFlavor = Flavor.prod;
    });

    test('Hive更新成功', () async {
      final member = _makeMember();
      final updatedGroup = _makeGroup(
        members: [
          const SharedGroupMember(
            memberId: 'owner-uid',
            name: 'テストオーナー',
            contact: 'owner@test.com',
            role: SharedGroupRole.owner,
          ),
          member,
        ],
      );
      when(mockHive.addMember('group-001', member))
          .thenAnswer((_) async => updatedGroup);
      when(mockFirestore.addMember('group-001', member))
          .thenAnswer((_) async => updatedGroup);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.addMember('group-001', member);

      expect(result.members!.length, equals(2));
      verify(mockHive.addMember('group-001', member)).called(1);
    });

    test('Hive更新成功（Firestoreはunawaitedで失敗しても問題なし）', () async {
      final member = _makeMember();
      final updatedGroup = _makeGroup();
      when(mockHive.addMember('group-001', member))
          .thenAnswer((_) async => updatedGroup);
      when(mockFirestore.addMember('group-001', member))
          .thenAnswer((_) async => throw Exception('Firestore error'));

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      // unawaitedなのでFirestoreエラーは伝播しない
      final result = await repo.addMember('group-001', member);

      expect(result.groupId, equals('group-001'));
      verify(mockHive.addMember('group-001', member)).called(1);
    });
  });

  // ================================================================
  // removeMember — Hive-first + unawaited Firestore
  // ================================================================
  group('removeMember', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
      F.appFlavor = Flavor.prod;
    });

    test('Hiveからメンバー削除成功', () async {
      final member = _makeMember();
      final updatedGroup = _makeGroup(members: [
        const SharedGroupMember(
          memberId: 'owner-uid',
          name: 'テストオーナー',
          contact: 'owner@test.com',
          role: SharedGroupRole.owner,
        ),
      ]);
      when(mockHive.removeMember('group-001', member))
          .thenAnswer((_) async => updatedGroup);
      when(mockFirestore.removeMember('group-001', member))
          .thenAnswer((_) async => updatedGroup);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.removeMember('group-001', member);

      expect(result.members!.length, equals(1));
      verify(mockHive.removeMember('group-001', member)).called(1);
    });
  });

  // ================================================================
  // setMemberId — Hive-first + unawaited Firestore
  // ================================================================
  group('setMemberId', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
      F.appFlavor = Flavor.prod;
    });

    test('Hive更新成功', () async {
      final updatedGroup = _makeGroup();
      when(mockHive.setMemberId('old-id', 'new-id', 'contact@test.com'))
          .thenAnswer((_) async => updatedGroup);
      when(mockFirestore.setMemberId('old-id', 'new-id', 'contact@test.com'))
          .thenAnswer((_) async => updatedGroup);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result =
          await repo.setMemberId('old-id', 'new-id', 'contact@test.com');

      expect(result.groupId, equals('group-001'));
      verify(mockHive.setMemberId('old-id', 'new-id', 'contact@test.com'))
          .called(1);
    });
  });

  // ================================================================
  // Member Pool — 全てHiveに委譲
  // ================================================================
  group('Member Pool操作（Hive専用）', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
    });

    test('getOrCreateMemberPool: Hiveに委譲', () async {
      final pool = _makeGroup(groupId: 'member_pool', groupName: 'Member Pool');
      when(mockHive.getOrCreateMemberPool()).thenAnswer((_) async => pool);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.getOrCreateMemberPool();

      expect(result.groupId, equals('member_pool'));
      verify(mockHive.getOrCreateMemberPool()).called(1);
      verifyNever(mockFirestore.getOrCreateMemberPool());
    });

    test('syncMemberPool: Hiveに委譲', () async {
      when(mockHive.syncMemberPool()).thenAnswer((_) async {});

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      await repo.syncMemberPool();

      verify(mockHive.syncMemberPool()).called(1);
    });

    test('searchMembersInPool: Hiveに委譲', () async {
      final members = [_makeMember(name: 'テスト太郎')];
      when(mockHive.searchMembersInPool('テスト'))
          .thenAnswer((_) async => members);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.searchMembersInPool('テスト');

      expect(result.length, equals(1));
      expect(result[0].name, equals('テスト太郎'));
      verify(mockHive.searchMembersInPool('テスト')).called(1);
    });

    test('findMemberByEmail: Hiveに委譲', () async {
      final member = _makeMember(name: 'メール太郎');
      when(mockHive.findMemberByEmail('test@example.com'))
          .thenAnswer((_) async => member);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.findMemberByEmail('test@example.com');

      expect(result, isNotNull);
      expect(result!.name, equals('メール太郎'));
      verify(mockHive.findMemberByEmail('test@example.com')).called(1);
    });

    test('findMemberByEmail: 見つからない場合null', () async {
      when(mockHive.findMemberByEmail('unknown@example.com'))
          .thenAnswer((_) async => null);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.findMemberByEmail('unknown@example.com');

      expect(result, isNull);
    });

    test('cleanupDeletedGroups: Hiveに委譲', () async {
      when(mockHive.cleanupDeletedGroups()).thenAnswer((_) async => 3);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      final result = await repo.cleanupDeletedGroups();

      expect(result, equals(3));
      verify(mockHive.cleanupDeletedGroups()).called(1);
    });
  });

  // ================================================================
  // createGroup — member_pool path (Hive-only)
  // ================================================================
  group('createGroup（member_poolパス）', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockFirestoreSharedGroupRepository mockFirestore;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockFirestore = MockFirestoreSharedGroupRepository();
      mockRef = MockRef();
    });

    test('member_poolグループ: Hiveのみに保存', () async {
      final member = _makeMember(
        memberId: 'owner-uid',
        name: 'テストオーナー',
        role: SharedGroupRole.owner,
      );
      final poolGroup =
          _makeGroup(groupId: 'member_pool', groupName: 'Member Pool');

      when(mockHive.createGroup('member_pool', 'Member Pool', member))
          .thenAnswer((_) async => poolGroup);

      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );

      // waitForSafeInitialization が完了するのを待つため少し待機
      // (非同期初期化が FirebaseAuth にアクセスして完了する)
      await Future.delayed(const Duration(seconds: 2));

      final result =
          await repo.createGroup('member_pool', 'Member Pool', member);

      expect(result.groupId, equals('member_pool'));
      verify(mockHive.createGroup('member_pool', 'Member Pool', member))
          .called(1);
      // Firestore should not be called for member_pool group
    });
  });

  // ================================================================
  // isSyncingNotifier
  // ================================================================
  group('isSyncingNotifier', () {
    late MockHiveSharedGroupRepository mockHive;
    late MockRef mockRef;

    setUp(() {
      mockHive = MockHiveSharedGroupRepository();
      mockRef = MockRef();
    });

    test('初期値はfalse', () {
      final repo = HybridSharedGroupRepository(
        mockRef,
        hiveRepo: mockHive,
      );

      expect(repo.isSyncingNotifier.value, isFalse);
    });
  });
}
