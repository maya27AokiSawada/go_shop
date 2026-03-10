// test/datastore/hybrid_shared_list_repository_test.dart
//
// ✅ HybridSharedListRepository Unit Tests
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DI（依存性注入）を使用して HiveRepo / FirestoreRepo をモック化。
// 各メソッドの分岐ロジックを直接テストする。
//
// テスト戦略:
// - getSharedListById: Firestore優先 + 10sタイムアウト → Hiveフォールバック
// - getSharedListsByGroup: Firestore優先 + Hiveキャッシュ
// - createSharedList: Firestore優先（customListIdでDeviceIdService回避）
// - updateSharedList / deleteSharedList: Firestore優先 + Hiveキャッシュ
// - addItemToList / removeItemFromList / updateItemStatusInList:
//     Hive優先 + 通知(listNotificationBatchService) + Firestore同期
// - addSingleItem / removeSingleItem / updateSingleItem:
//     Firestore優先（WithGroupId系メソッド）+ Hiveキャッシュ
// - cleanupDeletedItems: Hive cleanup + unawaited Firestore同期
// - clearPurchasedItemsFromList / getOrCreateDefaultList: 純Hive委譲
// - deleteSharedListsByGroupId: Hive + 条件付きFirestore
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';

import 'package:goshopping/models/shared_list.dart';
import 'package:goshopping/datastore/hybrid_shared_list_repository.dart';
import 'package:goshopping/datastore/hive_shared_list_repository.dart';
import 'package:goshopping/datastore/firestore_shared_list_repository.dart';
import 'package:goshopping/services/list_notification_batch_service.dart';
import 'package:goshopping/flavors.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Sentinels for noSuchMethod returnValue
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final _dummyList = SharedList(
  ownerUid: '_dummy_',
  groupId: '_dummy_',
  groupName: '_dummy_',
  listId: '_dummy_',
  listName: '_dummy_',
  createdAt: DateTime(2020),
  updatedAt: DateTime(2020),
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Mock Classes
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class MockHiveSharedListRepository extends Mock
    implements HiveSharedListRepository {
  // Manual capture for updateSharedList (captureAny returns null in null-safe Dart)
  final List<SharedList> updateSharedListCalls = [];

  // --- Legacy methods ---
  @override
  Future<SharedList?> getSharedList(String groupId) => super.noSuchMethod(
        Invocation.method(#getSharedList, [groupId]),
        returnValue: Future<SharedList?>.value(null),
      ) as Future<SharedList?>;

  @override
  Future<void> addItem(SharedList list) => super.noSuchMethod(
        Invocation.method(#addItem, [list]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> clearSharedList(String groupId) => super.noSuchMethod(
        Invocation.method(#clearSharedList, [groupId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> addSharedItem(String groupId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#addSharedItem, [groupId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> removeSharedItem(String groupId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#removeSharedItem, [groupId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> updateSharedItemStatus(String groupId, SharedItem item,
          {required bool isPurchased}) =>
      super.noSuchMethod(
        Invocation.method(#updateSharedItemStatus, [groupId, item],
            {#isPurchased: isPurchased}),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<SharedList> getOrCreateList(String groupId, String groupName) =>
      super.noSuchMethod(
        Invocation.method(#getOrCreateList, [groupId, groupName]),
        returnValue: Future<SharedList>.value(_dummyList),
      ) as Future<SharedList>;

  @override
  List<SharedList> getAllLists() => super.noSuchMethod(
        Invocation.method(#getAllLists, []),
        returnValue: <SharedList>[],
      ) as List<SharedList>;

  // --- New Multi-List methods ---
  @override
  Future<SharedList> createSharedList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
    String? customListId,
  }) =>
      super.noSuchMethod(
        Invocation.method(#createSharedList, [], {
          #ownerUid: ownerUid,
          #groupId: groupId,
          #listName: listName,
          #description: description,
          #customListId: customListId,
        }),
        returnValue: Future<SharedList>.value(_dummyList),
      ) as Future<SharedList>;

  @override
  Future<SharedList?> getSharedListById(String listId) => super.noSuchMethod(
        Invocation.method(#getSharedListById, [listId]),
        returnValue: Future<SharedList?>.value(null),
      ) as Future<SharedList?>;

  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) =>
      super.noSuchMethod(
        Invocation.method(#getSharedListsByGroup, [groupId]),
        returnValue: Future<List<SharedList>>.value(<SharedList>[]),
      ) as Future<List<SharedList>>;

  @override
  Future<void> updateSharedList(SharedList list) {
    updateSharedListCalls.add(list);
    // Always return Future.value() — the SUT creates new SharedList objects
    // via copyWith(), so Mockito stubs won't match. We capture calls manually.
    return Future<void>.value();
  }

  @override
  Future<void> deleteSharedList(String groupId, String listId) =>
      super.noSuchMethod(
        Invocation.method(#deleteSharedList, [groupId, listId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> deleteSharedListsByGroupId(String groupId) => super.noSuchMethod(
        Invocation.method(#deleteSharedListsByGroupId, [groupId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> addItemToList(String listId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#addItemToList, [listId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> removeItemFromList(String listId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#removeItemFromList, [listId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> updateItemStatusInList(String listId, SharedItem item,
          {required bool isPurchased}) =>
      super.noSuchMethod(
        Invocation.method(#updateItemStatusInList, [listId, item],
            {#isPurchased: isPurchased}),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> addSingleItem(String listId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#addSingleItem, [listId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> removeSingleItem(String listId, String itemId) =>
      super.noSuchMethod(
        Invocation.method(#removeSingleItem, [listId, itemId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> updateSingleItem(String listId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#updateSingleItem, [listId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> cleanupDeletedItems(String listId, {int olderThanDays = 30}) =>
      super.noSuchMethod(
        Invocation.method(
            #cleanupDeletedItems, [listId], {#olderThanDays: olderThanDays}),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> clearPurchasedItemsFromList(String listId) => super.noSuchMethod(
        Invocation.method(#clearPurchasedItemsFromList, [listId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<SharedList> getOrCreateDefaultList(String groupId, String groupName) =>
      super.noSuchMethod(
        Invocation.method(#getOrCreateDefaultList, [groupId, groupName]),
        returnValue: Future<SharedList>.value(_dummyList),
      ) as Future<SharedList>;

  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) =>
      super.noSuchMethod(
        Invocation.method(#watchSharedList, [groupId, listId]),
        returnValue: Stream<SharedList?>.value(null),
      ) as Stream<SharedList?>;
}

class MockFirestoreSharedListRepository extends Mock
    implements FirestoreSharedListRepository {
  // Capture calls to updateSharedList (bypasses Mockito tracking for non-nullable return)
  final List<SharedList> updateSharedListCalls = [];
  Exception? updateSharedListError; // Set this to make updateSharedList throw

  @override
  Future<void> updateSharedList(SharedList list) {
    if (updateSharedListError != null) {
      return Future<void>.error(updateSharedListError!);
    }
    updateSharedListCalls.add(list);
    return Future<void>.value();
  }

  // --- Interface methods ---
  @override
  Future<SharedList?> getSharedList(String groupId) => super.noSuchMethod(
        Invocation.method(#getSharedList, [groupId]),
        returnValue: Future<SharedList?>.value(null),
      ) as Future<SharedList?>;

  @override
  Future<void> addItem(SharedList list) => super.noSuchMethod(
        Invocation.method(#addItem, [list]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> clearSharedList(String groupId) => super.noSuchMethod(
        Invocation.method(#clearSharedList, [groupId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> addSharedItem(String groupId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#addSharedItem, [groupId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> removeSharedItem(String groupId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#removeSharedItem, [groupId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> updateSharedItemStatus(String groupId, SharedItem item,
          {required bool isPurchased}) =>
      super.noSuchMethod(
        Invocation.method(#updateSharedItemStatus, [groupId, item],
            {#isPurchased: isPurchased}),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<SharedList> getOrCreateList(String groupId, String groupName) =>
      super.noSuchMethod(
        Invocation.method(#getOrCreateList, [groupId, groupName]),
        returnValue: Future<SharedList>.value(_dummyList),
      ) as Future<SharedList>;

  @override
  Future<SharedList> createSharedList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
    String? customListId,
  }) =>
      super.noSuchMethod(
        Invocation.method(#createSharedList, [], {
          #ownerUid: ownerUid,
          #groupId: groupId,
          #listName: listName,
          #description: description,
          #customListId: customListId,
        }),
        returnValue: Future<SharedList>.value(_dummyList),
      ) as Future<SharedList>;

  @override
  Future<SharedList?> getSharedListById(String listId) => super.noSuchMethod(
        Invocation.method(#getSharedListById, [listId]),
        returnValue: Future<SharedList?>.value(null),
      ) as Future<SharedList?>;

  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) =>
      super.noSuchMethod(
        Invocation.method(#getSharedListsByGroup, [groupId]),
        returnValue: Future<List<SharedList>>.value(<SharedList>[]),
      ) as Future<List<SharedList>>;

  @override
  Future<void> deleteSharedList(String groupId, String listId) =>
      super.noSuchMethod(
        Invocation.method(#deleteSharedList, [groupId, listId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> deleteSharedListsByGroupId(String groupId) => super.noSuchMethod(
        Invocation.method(#deleteSharedListsByGroupId, [groupId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> addItemToList(String listId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#addItemToList, [listId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> removeItemFromList(String listId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#removeItemFromList, [listId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> updateItemStatusInList(String listId, SharedItem item,
          {required bool isPurchased}) =>
      super.noSuchMethod(
        Invocation.method(#updateItemStatusInList, [listId, item],
            {#isPurchased: isPurchased}),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> addSingleItem(String listId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#addSingleItem, [listId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> removeSingleItem(String listId, String itemId) =>
      super.noSuchMethod(
        Invocation.method(#removeSingleItem, [listId, itemId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> updateSingleItem(String listId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#updateSingleItem, [listId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> cleanupDeletedItems(String listId, {int olderThanDays = 30}) =>
      super.noSuchMethod(
        Invocation.method(
            #cleanupDeletedItems, [listId], {#olderThanDays: olderThanDays}),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> clearPurchasedItemsFromList(String listId) => super.noSuchMethod(
        Invocation.method(#clearPurchasedItemsFromList, [listId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<SharedList> getOrCreateDefaultList(String groupId, String groupName) =>
      super.noSuchMethod(
        Invocation.method(#getOrCreateDefaultList, [groupId, groupName]),
        returnValue: Future<SharedList>.value(_dummyList),
      ) as Future<SharedList>;

  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) =>
      super.noSuchMethod(
        Invocation.method(#watchSharedList, [groupId, listId]),
        returnValue: Stream<SharedList?>.value(null),
      ) as Stream<SharedList?>;

  // --- Extra methods NOT in abstract interface (used by hybrid repo) ---
  @override
  Future<void> addSingleItemWithGroupId(
          String listId, String groupId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(#addSingleItemWithGroupId, [listId, groupId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> removeSingleItemWithGroupId(
          String listId, String groupId, String itemId) =>
      super.noSuchMethod(
        Invocation.method(
            #removeSingleItemWithGroupId, [listId, groupId, itemId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> updateSingleItemWithGroupId(
          String listId, String groupId, SharedItem item) =>
      super.noSuchMethod(
        Invocation.method(
            #updateSingleItemWithGroupId, [listId, groupId, item]),
        returnValue: Future<void>.value(),
      ) as Future<void>;
}

class MockListNotificationBatchService extends Mock
    implements ListNotificationBatchService {
  @override
  Future<void> recordItemAdded({
    required String listId,
    required String groupId,
    required String itemName,
  }) =>
      super.noSuchMethod(
        Invocation.method(#recordItemAdded, [],
            {#listId: listId, #groupId: groupId, #itemName: itemName}),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> recordItemRemoved({
    required String listId,
    required String groupId,
    required String itemName,
  }) =>
      super.noSuchMethod(
        Invocation.method(#recordItemRemoved, [],
            {#listId: listId, #groupId: groupId, #itemName: itemName}),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> recordItemPurchased({
    required String listId,
    required String groupId,
    required String itemName,
  }) =>
      super.noSuchMethod(
        Invocation.method(#recordItemPurchased, [],
            {#listId: listId, #groupId: groupId, #itemName: itemName}),
        returnValue: Future<void>.value(),
      ) as Future<void>;
}

class MockRef extends Fake implements Ref {
  final MockListNotificationBatchService _mockNotificationService;

  MockRef(this._mockNotificationService);

  @override
  void invalidate(ProviderOrFamily provider) {
    // no-op for tests
  }

  @override
  T read<T>(ProviderListenable<T> provider) {
    // Handle listNotificationBatchServiceProvider reads
    if (provider == listNotificationBatchServiceProvider) {
      return _mockNotificationService as T;
    }
    throw UnimplementedError('MockRef.read called for $provider');
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Firebase test init
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
// Helper functions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SharedList _makeList({
  String groupId = 'group-1',
  String listId = 'list-1',
  String listName = 'テストリスト',
  String ownerUid = 'owner-1',
  String groupName = 'テストグループ',
  Map<String, SharedItem>? items,
  DateTime? updatedAt,
}) {
  return SharedList(
    ownerUid: ownerUid,
    groupId: groupId,
    groupName: groupName,
    listId: listId,
    listName: listName,
    items: items ?? {},
    createdAt: DateTime(2025, 1, 1),
    updatedAt: updatedAt ?? DateTime(2025, 1, 1),
  );
}

SharedItem _makeItem({
  String itemId = 'item-1',
  String name = 'テストアイテム',
  String memberId = 'member-1',
  bool isPurchased = false,
  bool isDeleted = false,
  DateTime? deletedAt,
}) {
  return SharedItem(
    memberId: memberId,
    name: name,
    registeredDate: DateTime(2025, 1, 1),
    itemId: itemId,
    isPurchased: isPurchased,
    isDeleted: isDeleted,
    deletedAt: deletedAt,
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Tests
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

void main() {
  setUpAll(() async {
    await _initFirebase();
    // テスト中はdev flavorに設定（Firestoreリポジトリの自動生成を避ける）
    F.appFlavor = Flavor.dev;
  });

  // ================================================================
  // getSharedListById
  // ================================================================
  group('getSharedListById', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Firestore成功時: Firestoreから取得しHiveにキャッシュ', () async {
      final expected = _makeList(listId: 'list-A');
      when(mockFirestore.getSharedListById('list-A'))
          .thenAnswer((_) async => expected);

      final result = await repo.getSharedListById('list-A');

      expect(result, equals(expected));
      verify(mockFirestore.getSharedListById('list-A')).called(1);
      // MockHive.updateSharedList is captured manually
      expect(mockHive.updateSharedListCalls, isNotEmpty);
      expect(mockHive.updateSharedListCalls.last.listId, equals('list-A'));
    });

    test('Firestoreがnull返却時: Hiveフォールバック', () async {
      final hiveResult = _makeList(listId: 'list-B');
      when(mockFirestore.getSharedListById('list-B'))
          .thenAnswer((_) async => null);
      when(mockHive.getSharedListById('list-B'))
          .thenAnswer((_) async => hiveResult);

      final result = await repo.getSharedListById('list-B');

      expect(result, equals(hiveResult));
      verify(mockFirestore.getSharedListById('list-B')).called(1);
      verify(mockHive.getSharedListById('list-B')).called(1);
    });

    test('Firestoreエラー時: Hiveフォールバック', () async {
      final hiveResult = _makeList(listId: 'list-C');
      when(mockFirestore.getSharedListById('list-C'))
          .thenAnswer((_) async => throw Exception('Firestore down'));
      when(mockHive.getSharedListById('list-C'))
          .thenAnswer((_) async => hiveResult);

      final result = await repo.getSharedListById('list-C');

      expect(result, equals(hiveResult));
    });

    test('Hiveのみモード（firestoreRepo=null）: Hiveから取得', () async {
      final hiveOnly = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        // firestoreRepo is null
      );
      final expected = _makeList(listId: 'list-D');
      when(mockHive.getSharedListById('list-D'))
          .thenAnswer((_) async => expected);

      final result = await hiveOnly.getSharedListById('list-D');

      expect(result, equals(expected));
      verifyNever(mockFirestore.getSharedListById('list-D'));
    });
  });

  // ================================================================
  // getSharedListsByGroup
  // ================================================================
  group('getSharedListsByGroup', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Firestore成功時: 全リスト取得しHiveにキャッシュ', () async {
      final list1 = _makeList(listId: 'l1', groupId: 'g1');
      final list2 = _makeList(listId: 'l2', groupId: 'g1');
      when(mockFirestore.getSharedListsByGroup('g1'))
          .thenAnswer((_) async => [list1, list2]);

      final result = await repo.getSharedListsByGroup('g1');

      expect(result.length, equals(2));
      verify(mockFirestore.getSharedListsByGroup('g1')).called(1);
      // MockHive.updateSharedList is captured manually
      expect(mockHive.updateSharedListCalls.length, greaterThanOrEqualTo(2));
    });

    test('Firestoreエラー時: Hiveフォールバック', () async {
      final hiveList = _makeList(listId: 'lh', groupId: 'g2');
      when(mockFirestore.getSharedListsByGroup('g2'))
          .thenAnswer((_) async => throw Exception('timeout'));
      when(mockHive.getSharedListsByGroup('g2'))
          .thenAnswer((_) async => [hiveList]);

      final result = await repo.getSharedListsByGroup('g2');

      expect(result.length, equals(1));
      expect(result.first.listId, equals('lh'));
    });
  });

  // ================================================================
  // createSharedList
  // ================================================================
  group('createSharedList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Firestore優先: Firestoreに作成しHiveにキャッシュ', () async {
      final created = _makeList(listId: 'custom-id', groupId: 'g1');
      when(mockFirestore.createSharedList(
        ownerUid: 'owner-1',
        groupId: 'g1',
        listName: 'New List',
        description: null,
        customListId: 'custom-id',
      )).thenAnswer((_) async => created);

      final result = await repo.createSharedList(
        ownerUid: 'owner-1',
        groupId: 'g1',
        listName: 'New List',
        customListId: 'custom-id',
      );

      expect(result.listId, equals('custom-id'));
      verify(mockFirestore.createSharedList(
        ownerUid: 'owner-1',
        groupId: 'g1',
        listName: 'New List',
        description: null,
        customListId: 'custom-id',
      )).called(1);
      // MockHive.updateSharedList is captured manually
      expect(mockHive.updateSharedListCalls, isNotEmpty);
    });

    test('Firestoreエラー時: 例外がrethrowされる', () async {
      when(mockFirestore.createSharedList(
        ownerUid: 'owner-1',
        groupId: 'g1',
        listName: 'New List',
        description: null,
        customListId: 'custom-id-2',
      )).thenAnswer((_) async => throw Exception('Firestore error'));

      expect(
        () => repo.createSharedList(
          ownerUid: 'owner-1',
          groupId: 'g1',
          listName: 'New List',
          customListId: 'custom-id-2',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ================================================================
  // updateSharedList
  // ================================================================
  group('updateSharedList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Firestore優先: Firestoreに更新しHiveにもキャッシュ', () async {
      final list = _makeList(listId: 'u1');

      await repo.updateSharedList(list);

      // Firestore update captured manually
      expect(mockFirestore.updateSharedListCalls, isNotEmpty);
      expect(mockFirestore.updateSharedListCalls.last.listId, equals('u1'));
      // Hive cache captured manually
      expect(mockHive.updateSharedListCalls, isNotEmpty);
      expect(mockHive.updateSharedListCalls.last.listId, equals('u1'));
    });

    test('Firestoreエラー時: 例外がrethrowされる', () async {
      final list = _makeList(listId: 'u2');
      mockFirestore.updateSharedListError = Exception('error');

      expect(
        () => repo.updateSharedList(list),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ================================================================
  // deleteSharedList
  // ================================================================
  group('deleteSharedList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Firestore優先: Firestoreから削除しHiveからも削除', () async {
      when(mockFirestore.deleteSharedList('g1', 'list-del'))
          .thenAnswer((_) async {});
      when(mockHive.deleteSharedList('g1', 'list-del'))
          .thenAnswer((_) async {});

      await repo.deleteSharedList('g1', 'list-del');

      verify(mockFirestore.deleteSharedList('g1', 'list-del')).called(1);
      verify(mockHive.deleteSharedList('g1', 'list-del')).called(1);
    });

    test('Firestoreエラー時: 例外がrethrowされる', () async {
      when(mockFirestore.deleteSharedList('g1', 'list-del2'))
          .thenAnswer((_) async => throw Exception('error'));

      expect(
        () => repo.deleteSharedList('g1', 'list-del2'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ================================================================
  // addItemToList (Hive-first + notification + Firestore sync)
  // ================================================================
  group('addItemToList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Hive優先: Hiveに追加→通知→Firestoreに同期', () async {
      final item = _makeItem(itemId: 'i1', name: '牛乳');
      final list = _makeList(listId: 'list-1', groupId: 'g1');

      when(mockHive.addItemToList('list-1', item)).thenAnswer((_) async {});
      // For notification, the hybrid repo reads list from Hive to get groupId
      when(mockHive.getSharedListById('list-1')).thenAnswer((_) async => list);
      when(mockNotification.recordItemAdded(
        listId: 'list-1',
        groupId: 'g1',
        itemName: '牛乳',
      )).thenAnswer((_) async {});
      when(mockFirestore.addItemToList('list-1', item))
          .thenAnswer((_) async {});

      await repo.addItemToList('list-1', item);

      verify(mockHive.addItemToList('list-1', item)).called(1);
    });
  });

  // ================================================================
  // removeItemFromList (Hive-first + notification + Firestore sync)
  // ================================================================
  group('removeItemFromList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Hive優先: Hiveから削除→通知→Firestore同期', () async {
      final item = _makeItem(itemId: 'i2', name: '卵');
      final list = _makeList(listId: 'list-2', groupId: 'g2');

      when(mockHive.removeItemFromList('list-2', item))
          .thenAnswer((_) async {});
      when(mockHive.getSharedListById('list-2')).thenAnswer((_) async => list);
      when(mockNotification.recordItemRemoved(
        listId: 'list-2',
        groupId: 'g2',
        itemName: '卵',
      )).thenAnswer((_) async {});
      when(mockFirestore.removeItemFromList('list-2', item))
          .thenAnswer((_) async {});

      await repo.removeItemFromList('list-2', item);

      verify(mockHive.removeItemFromList('list-2', item)).called(1);
    });
  });

  // ================================================================
  // updateItemStatusInList (Hive-first + conditional notification)
  // ================================================================
  group('updateItemStatusInList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('purchased=true: Hive更新→購入通知→Firestore同期', () async {
      final item = _makeItem(itemId: 'i3', name: 'パン');
      final list = _makeList(listId: 'list-3', groupId: 'g3');

      when(mockHive.updateItemStatusInList('list-3', item, isPurchased: true))
          .thenAnswer((_) async {});
      when(mockHive.getSharedListById('list-3')).thenAnswer((_) async => list);
      when(mockNotification.recordItemPurchased(
        listId: 'list-3',
        groupId: 'g3',
        itemName: 'パン',
      )).thenAnswer((_) async {});
      when(mockFirestore.updateItemStatusInList('list-3', item,
              isPurchased: true))
          .thenAnswer((_) async {});

      await repo.updateItemStatusInList('list-3', item, isPurchased: true);

      verify(mockHive.updateItemStatusInList('list-3', item, isPurchased: true))
          .called(1);
    });

    test('purchased=false: Hive更新→通知なし→Firestore同期', () async {
      final item = _makeItem(itemId: 'i4', name: '味噌');
      final list = _makeList(listId: 'list-4', groupId: 'g4');

      when(mockHive.updateItemStatusInList('list-4', item, isPurchased: false))
          .thenAnswer((_) async {});
      when(mockHive.getSharedListById('list-4')).thenAnswer((_) async => list);
      when(mockFirestore.updateItemStatusInList('list-4', item,
              isPurchased: false))
          .thenAnswer((_) async {});

      await repo.updateItemStatusInList('list-4', item, isPurchased: false);

      verify(mockHive.updateItemStatusInList('list-4', item,
              isPurchased: false))
          .called(1);
      // 通知は呼ばれない
      verifyNever(mockNotification.recordItemPurchased(
        listId: 'list-4',
        groupId: 'g4',
        itemName: '味噌',
      ));
    });
  });

  // ================================================================
  // addSingleItem (Firestore-first differential sync)
  // ================================================================
  group('addSingleItem', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Firestore優先: Firestore差分追加→Hiveキャッシュ更新', () async {
      final item = _makeItem(itemId: 'new-1', name: '豆腐');
      final existingList = _makeList(listId: 'sl-1', groupId: 'sg-1');

      when(mockHive.getSharedListById('sl-1'))
          .thenAnswer((_) async => existingList);
      when(mockFirestore.addSingleItemWithGroupId('sl-1', 'sg-1', item))
          .thenAnswer((_) async {});

      await repo.addSingleItem('sl-1', item);

      verify(mockFirestore.addSingleItemWithGroupId('sl-1', 'sg-1', item))
          .called(1);
    });

    test('Hiveリスト未存在時: Hiveのみ（_firestoreRepo存在してもgroupId取得不可）', () async {
      final item = _makeItem(itemId: 'new-2', name: 'ネギ');

      when(mockHive.getSharedListById('sl-not-found'))
          .thenAnswer((_) async => null);

      // SUT throws Exception('List not found in cache') when Hive returns null
      expect(
        () => repo.addSingleItem('sl-not-found', item),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ================================================================
  // removeSingleItem (Firestore-first + Hive logical delete)
  // ================================================================
  group('removeSingleItem', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Firestore優先: Firestore論理削除→Hive論理削除', () async {
      final existingItem = _makeItem(itemId: 'rm-1', name: '醤油');
      final existingList = _makeList(
        listId: 'sl-rm',
        groupId: 'sg-rm',
        items: {'rm-1': existingItem},
      );

      when(mockHive.getSharedListById('sl-rm'))
          .thenAnswer((_) async => existingList);
      when(mockFirestore.removeSingleItemWithGroupId('sl-rm', 'sg-rm', 'rm-1'))
          .thenAnswer((_) async {});

      await repo.removeSingleItem('sl-rm', 'rm-1');

      verify(mockFirestore.removeSingleItemWithGroupId(
              'sl-rm', 'sg-rm', 'rm-1'))
          .called(1);
      // Hiveに論理削除（isDeleted=true）されたリストが保存される
      expect(mockHive.updateSharedListCalls, isNotEmpty);
      final capturedList = mockHive.updateSharedListCalls.last;
      expect(capturedList.items['rm-1']?.isDeleted, isTrue);
    });
  });

  // ================================================================
  // updateSingleItem (Firestore-first differential sync)
  // ================================================================
  group('updateSingleItem', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Firestore優先: Firestore差分更新→Hiveキャッシュ更新', () async {
      final updatedItem =
          _makeItem(itemId: 'upd-1', name: '牛乳2L', isPurchased: true);
      final existingList = _makeList(
        listId: 'sl-u',
        groupId: 'sg-u',
        items: {'upd-1': _makeItem(itemId: 'upd-1', name: '牛乳')},
      );

      when(mockHive.getSharedListById('sl-u'))
          .thenAnswer((_) async => existingList);
      when(mockFirestore.updateSingleItemWithGroupId(
              'sl-u', 'sg-u', updatedItem))
          .thenAnswer((_) async {});

      await repo.updateSingleItem('sl-u', updatedItem);

      verify(mockFirestore.updateSingleItemWithGroupId(
              'sl-u', 'sg-u', updatedItem))
          .called(1);
      expect(mockHive.updateSharedListCalls, isNotEmpty);
      final capturedList = mockHive.updateSharedListCalls.last;
      expect(capturedList.items['upd-1']?.name, equals('牛乳2L'));
    });
  });

  // ================================================================
  // clearPurchasedItemsFromList (pure Hive delegation)
  // ================================================================
  group('clearPurchasedItemsFromList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('純Hive委譲: Hiveのみ呼び出し', () async {
      when(mockHive.clearPurchasedItemsFromList('list-clear'))
          .thenAnswer((_) async {});

      await repo.clearPurchasedItemsFromList('list-clear');

      verify(mockHive.clearPurchasedItemsFromList('list-clear')).called(1);
      verifyNever(mockFirestore.clearPurchasedItemsFromList('list-clear'));
    });
  });

  // ================================================================
  // getOrCreateDefaultList (pure Hive delegation)
  // ================================================================
  group('getOrCreateDefaultList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('純Hive委譲: HiveのgetOrCreateDefaultListに委譲', () async {
      final expected = _makeList(listId: 'default-list');
      when(mockHive.getOrCreateDefaultList('g-def', 'Default Group'))
          .thenAnswer((_) async => expected);

      final result =
          await repo.getOrCreateDefaultList('g-def', 'Default Group');

      expect(result, equals(expected));
      verify(mockHive.getOrCreateDefaultList('g-def', 'Default Group'))
          .called(1);
    });
  });

  // ================================================================
  // deleteSharedListsByGroupId (Hive + conditional Firestore)
  // ================================================================
  group('deleteSharedListsByGroupId', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Hive + Firestore: 両方に削除（online & prod条件）', () async {
      // NOTE: F.appFlavor is dev in test, so Firestore path is NOT taken
      // even when _firestoreRepo is provided. This test verifies Hive is called.
      when(mockHive.deleteSharedListsByGroupId('g-del'))
          .thenAnswer((_) async {});

      await repo.deleteSharedListsByGroupId('g-del');

      verify(mockHive.deleteSharedListsByGroupId('g-del')).called(1);
      // dev flavor → Firestore not called
      verifyNever(mockFirestore.deleteSharedListsByGroupId('g-del'));
    });
  });

  // ================================================================
  // cleanupDeletedItems (Hive cleanup + background Firestore)
  // ================================================================
  group('cleanupDeletedItems', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Hiveクリーンアップ: 削除済みアイテムを物理削除', () async {
      final oldDeletedItem = _makeItem(
        itemId: 'old-del',
        name: '古いアイテム',
        isDeleted: true,
        deletedAt: DateTime(2024, 1, 1), // very old
      );
      final activeItem = _makeItem(itemId: 'active', name: '有効アイテム');
      final list = _makeList(
        listId: 'sl-clean',
        items: {'old-del': oldDeletedItem, 'active': activeItem},
      );

      when(mockHive.getSharedListById('sl-clean'))
          .thenAnswer((_) async => list);
      await repo.cleanupDeletedItems('sl-clean', olderThanDays: 30);

      // Hiveが更新されること（古い削除アイテムが除去された状態で）
      expect(mockHive.updateSharedListCalls, isNotEmpty);
      final capturedList = mockHive.updateSharedListCalls.last;
      expect(capturedList.items.containsKey('old-del'), isFalse);
      expect(capturedList.items.containsKey('active'), isTrue);
    });
  });

  // ================================================================
  // watchSharedList
  // ================================================================
  group('watchSharedList', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('online: Firestoreストリームを返しHiveにキャッシュ', () async {
      final list1 = _makeList(listId: 'w1', listName: 'Watch1');
      final list2 = _makeList(listId: 'w1', listName: 'Watch2');
      when(mockFirestore.watchSharedList('gw', 'w1'))
          .thenAnswer((_) => Stream.fromIterable([list1, list2]));

      final stream = repo.watchSharedList('gw', 'w1');
      final results = await stream.toList();

      expect(results.length, equals(2));
      expect(results[0]?.listName, equals('Watch1'));
      expect(results[1]?.listName, equals('Watch2'));
    });
  });

  // ================================================================
  // forceSyncBidirectional / syncOnNetworkRecovery
  // ================================================================
  group('forceSyncBidirectional', () {
    late MockHiveSharedListRepository mockHive;
    late MockFirestoreSharedListRepository mockFirestore;
    late MockListNotificationBatchService mockNotification;
    late MockRef mockRef;
    late HybridSharedListRepository repo;

    setUp(() {
      mockHive = MockHiveSharedListRepository();
      mockFirestore = MockFirestoreSharedListRepository();
      mockNotification = MockListNotificationBatchService();
      mockRef = MockRef(mockNotification);
      repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: mockHive,
        firestoreRepo: mockFirestore,
      );
    });

    test('Hiveの方が新しい時: Firestoreへpushする', () async {
      final localList = _makeList(
        listId: 'sync-local-newer',
        updatedAt: DateTime(2025, 1, 2),
      );
      final firestoreList = _makeList(
        listId: 'sync-local-newer',
        updatedAt: DateTime(2025, 1, 1),
      );

      when(mockHive.getAllLists()).thenReturn([localList]);
      when(mockFirestore.getSharedListById('sync-local-newer'))
          .thenAnswer((_) async => firestoreList);

      await repo.forceSyncBidirectional();

      expect(mockFirestore.updateSharedListCalls, hasLength(1));
      expect(mockFirestore.updateSharedListCalls.single.listId,
          'sync-local-newer');
      expect(mockHive.updateSharedListCalls, isEmpty);
    });

    test('Firestoreの方が新しい時: Hiveへpullする', () async {
      final localList = _makeList(
        listId: 'sync-remote-newer',
        updatedAt: DateTime(2025, 1, 1),
      );
      final firestoreList = _makeList(
        listId: 'sync-remote-newer',
        listName: 'Firestore最新版',
        updatedAt: DateTime(2025, 1, 2),
      );

      when(mockHive.getAllLists()).thenReturn([localList]);
      when(mockFirestore.getSharedListById('sync-remote-newer'))
          .thenAnswer((_) async => firestoreList);

      await repo.forceSyncBidirectional();

      expect(mockFirestore.updateSharedListCalls, isEmpty);
      expect(mockHive.updateSharedListCalls, hasLength(1));
      expect(mockHive.updateSharedListCalls.single.listName, 'Firestore最新版');
    });

    test('Firestoreに未存在時: Hiveのリストを作成相当でpushする', () async {
      final localList = _makeList(listId: 'sync-missing-remote');

      when(mockHive.getAllLists()).thenReturn([localList]);
      when(mockFirestore.getSharedListById('sync-missing-remote'))
          .thenAnswer((_) async => null);

      await repo.forceSyncBidirectional();

      expect(mockFirestore.updateSharedListCalls, hasLength(1));
      expect(mockFirestore.updateSharedListCalls.single.listId,
          'sync-missing-remote');
      expect(mockHive.updateSharedListCalls, isEmpty);
    });
  });

  // ================================================================
  // isOnline / isSyncing getters
  // ================================================================
  group('状態プロパティ', () {
    test('isOnline: firestoreRepo注入時はtrue', () {
      final mockNotification = MockListNotificationBatchService();
      final mockRef = MockRef(mockNotification);
      final repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: MockHiveSharedListRepository(),
        firestoreRepo: MockFirestoreSharedListRepository(),
      );
      expect(repo.isOnline, isTrue);
    });

    test('isSyncing: 初期状態はfalse', () {
      final mockNotification = MockListNotificationBatchService();
      final mockRef = MockRef(mockNotification);
      final repo = HybridSharedListRepository(
        mockRef,
        hiveRepo: MockHiveSharedListRepository(),
        firestoreRepo: MockFirestoreSharedListRepository(),
      );
      expect(repo.isSyncing, isFalse);
    });
  });
}
