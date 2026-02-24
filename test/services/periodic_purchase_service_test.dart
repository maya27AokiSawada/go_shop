import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goshopping/models/shared_list.dart';
import 'package:goshopping/datastore/shared_list_repository.dart';
import 'package:goshopping/services/periodic_purchase_service.dart';
import 'package:goshopping/providers/purchase_group_provider.dart';
import 'package:goshopping/providers/shared_list_provider.dart';
import 'package:goshopping/models/shared_group.dart';

void main() {
  group('PeriodicPurchaseService - リセット条件判定（日付計算）', () {
    test('購入日から7日経過したアイテムはリセットされる', () async {
      // Arrange: 7日前に購入、間隔7日
      final purchaseDate = DateTime.now().subtract(const Duration(days: 7));
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: '牛乳',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 7,
      ).copyWith(purchaseDate: purchaseDate);

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 1, reason: '7日経過したアイテムはリセットされる');
    });

    test('購入日から6日しか経過していないアイテムはリセットされない', () async {
      // Arrange: 6日前に購入、間隔7日（まだ1日残っている）
      final purchaseDate = DateTime.now().subtract(const Duration(days: 6));
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: 'パン',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 7,
      ).copyWith(purchaseDate: purchaseDate);

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 0, reason: '6日目はまだリセットされない');
    });

    test('購入日から30日経過したアイテムはリセットされる', () async {
      // Arrange: 30日前に購入、間隔30日
      final purchaseDate = DateTime.now().subtract(const Duration(days: 30));
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: 'シャンプー',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 30,
      ).copyWith(purchaseDate: purchaseDate);

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 1, reason: '30日経過したアイテムはリセットされる');
    });

    test('購入日から100日経過（大幅超過）したアイテムでもリセットされる', () async {
      // Arrange: 100日前に購入、間隔7日（大幅超過）
      final purchaseDate = DateTime.now().subtract(const Duration(days: 100));
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: '卵',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 7,
      ).copyWith(purchaseDate: purchaseDate);

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 1, reason: '100日超過でもリセットされる');
    });
  });

  group('PeriodicPurchaseService - リセット対象外条件', () {
    test('未購入（isPurchased=false）のアイテムはリセット対象外', () async {
      // Arrange: 未購入アイテム
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: 'コーヒー',
        quantity: 1,
        isPurchased: false, // 未購入
        shoppingInterval: 7,
      );

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 0, reason: '未購入アイテムはリセットされない');
    });

    test('shoppingInterval=0（定期購入ではない）のアイテムはリセット対象外', () async {
      // Arrange: 定期購入ではないアイテム
      final purchaseDate = DateTime.now().subtract(const Duration(days: 10));
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: '単発購入品',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 0, // 定期購入ではない
      ).copyWith(purchaseDate: purchaseDate);

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 0, reason: 'shoppingInterval=0はリセットされない');
    });

    test('purchaseDate=nullのアイテムはリセット対象外', () async {
      // Arrange: 購入日が記録されていないアイテム
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: '購入日不明',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 7,
      ); // purchaseDateはnull

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 0, reason: 'purchaseDate=nullはリセットされない');
    });

    test('shoppingIntervalが負の値のアイテムはリセット対象外', () async {
      // Arrange: 不正な間隔値
      final purchaseDate = DateTime.now().subtract(const Duration(days: 10));
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: '不正データ',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: -7, // 負の値（不正）
      ).copyWith(purchaseDate: purchaseDate);

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 0, reason: '負の間隔値はリセットされない');
    });
  });

  group('PeriodicPurchaseService - 境界値テスト', () {
    test('間隔1日の最短定期購入でも正常に動作する', () async {
      // Arrange: 間隔1日（最短）で1日経過
      final purchaseDate = DateTime.now().subtract(const Duration(days: 1));
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: '毎日購入品',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 1, // 最短
      ).copyWith(purchaseDate: purchaseDate);

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 1, reason: '間隔1日で1日経過はリセットされる');
    });

    test('間隔365日の最長定期購入でも正常に動作する', () async {
      // Arrange: 間隔365日（最長想定）で365日経過
      final purchaseDate = DateTime.now().subtract(const Duration(days: 365));
      final item = SharedItem.createNow(
        memberId: 'test-user',
        name: '年次購入品',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 365, // 最長想定
      ).copyWith(purchaseDate: purchaseDate);

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {item.itemId: item},
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 1, reason: '間隔365日で365日経過はリセットされる');
    });
  });

  group('PeriodicPurchaseService - 複数アイテムの混在処理', () {
    test('リセット対象と対象外が混在した場合、対象のみリセットされる', () async {
      // Arrange: 5個のアイテム（2個がリセット対象、3個が対象外）
      final item1 = SharedItem.createNow(
        memberId: 'test-user',
        name: 'リセット対象1',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 7,
      ).copyWith(
          purchaseDate: DateTime.now().subtract(const Duration(days: 7)));

      final item2 = SharedItem.createNow(
        memberId: 'test-user',
        name: 'リセット対象2',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 14,
      ).copyWith(
          purchaseDate: DateTime.now().subtract(const Duration(days: 14)));

      final item3 = SharedItem.createNow(
        memberId: 'test-user',
        name: '対象外（未購入）',
        quantity: 1,
        isPurchased: false,
        shoppingInterval: 7,
      );

      final item4 = SharedItem.createNow(
        memberId: 'test-user',
        name: '対象外（定期購入ではない）',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 0,
      ).copyWith(
          purchaseDate: DateTime.now().subtract(const Duration(days: 10)));

      final item5 = SharedItem.createNow(
        memberId: 'test-user',
        name: '対象外（期限未達）',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 30,
      ).copyWith(
          purchaseDate: DateTime.now().subtract(const Duration(days: 5)));

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {
          item1.itemId: item1,
          item2.itemId: item2,
          item3.itemId: item3,
          item4.itemId: item4,
          item5.itemId: item5,
        },
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 2, reason: '5個中2個がリセットされる');
    });

    test('全アイテムがリセット対象の場合、全てリセットされる', () async {
      // Arrange: 3個全てがリセット対象
      final item1 = SharedItem.createNow(
        memberId: 'test-user',
        name: 'アイテム1',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 7,
      ).copyWith(
          purchaseDate: DateTime.now().subtract(const Duration(days: 7)));

      final item2 = SharedItem.createNow(
        memberId: 'test-user',
        name: 'アイテム2',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 14,
      ).copyWith(
          purchaseDate: DateTime.now().subtract(const Duration(days: 14)));

      final item3 = SharedItem.createNow(
        memberId: 'test-user',
        name: 'アイテム3',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 30,
      ).copyWith(
          purchaseDate: DateTime.now().subtract(const Duration(days: 30)));

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {
          item1.itemId: item1,
          item2.itemId: item2,
          item3.itemId: item3,
        },
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 3, reason: '全アイテムがリセットされる');
    });

    test('全アイテムが対象外の場合、何もリセットされない', () async {
      // Arrange: 3個全てが対象外
      final item1 = SharedItem.createNow(
        memberId: 'test-user',
        name: '未購入品',
        quantity: 1,
        isPurchased: false,
        shoppingInterval: 7,
      );

      final item2 = SharedItem.createNow(
        memberId: 'test-user',
        name: '単発購入品',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 0,
      );

      final item3 = SharedItem.createNow(
        memberId: 'test-user',
        name: '期限未達',
        quantity: 1,
        isPurchased: true,
        shoppingInterval: 30,
      ).copyWith(
          purchaseDate: DateTime.now().subtract(const Duration(days: 5)));

      final list = SharedList(
        listId: 'test-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: 'テストリスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {
          item1.itemId: item1,
          item2.itemId: item2,
          item3.itemId: item3,
        },
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 0, reason: '対象外アイテムのみの場合は0');
    });
  });

  group('PeriodicPurchaseService - エラーハンドリング', () {
    test('存在しないリストIDを指定した場合はエラーとならず0を返す', () async {
      // Arrange: 空のリスト
      final container = _createTestContainer(lists: []);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList('non-existent-id');

      // Assert
      expect(resetCount, 0, reason: '存在しないリストは0件リセット');
    });

    test('空のリストの場合は0を返す', () async {
      // Arrange: アイテムなしのリスト
      final list = SharedList(
        listId: 'empty-list',
        groupId: 'test-group',
        groupName: 'テストグループ',
        listName: '空リスト',
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        items: {}, // 空
      );

      final container = _createTestContainer(lists: [list]);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final resetCount =
          await service.resetPeriodicPurchaseItemsForList(list.listId);

      // Assert
      expect(resetCount, 0, reason: '空リストは0件リセット');
    });
  });

  group('PeriodicPurchaseService - 統計情報取得', () {
    test('getPeriodicPurchaseInfo()がエラーなく動作することを確認', () async {
      // Arrange - 空のリストでコンテナを作成
      final container = _createTestContainer(lists: []);

      // Act
      final service = container.read(periodicPurchaseServiceProvider);
      final info = await service.getPeriodicPurchaseInfo();

      // Assert - エラーが発生せず、必要なキーが存在することを確認
      expect(info, isNotNull, reason: '統計情報が返される');
      expect(info.containsKey('totalLists'), true,
          reason: 'totalListsキーが存在する');
      expect(info.containsKey('totalPeriodicItems'), true,
          reason: 'totalPeriodicItemsキーが存在する');
      expect(info.containsKey('readyToResetItems'), true,
          reason: 'readyToResetItemsキーが存在する');
      expect(info['totalLists'], greaterThanOrEqualTo(0),
          reason: 'totalListsは非負の値');
      expect(info['totalPeriodicItems'], greaterThanOrEqualTo(0),
          reason: 'totalPeriodicItemsは非負の値');
      expect(info['readyToResetItems'], greaterThanOrEqualTo(0),
          reason: 'readyToResetItemsは非負の値');
    });
  });
}

/// テスト用AllGroupsNotifier（モック）
class _MockAllGroupsNotifier extends AllGroupsNotifier {
  _MockAllGroupsNotifier() {
    state = const AsyncValue.data([
      SharedGroup(
        groupId: 'group1',
        groupName: 'テストグループ',
        ownerUid: 'test-user',
        members: [],
        allowedUid: ['test-user'],
      ),
    ]);
  }
}

/// テスト用ProviderContainerを作成
ProviderContainer _createTestContainer({required List<SharedList> lists}) {
  return ProviderContainer(
    overrides: [
      // SharedListRepositoryをモックに置き換え
      sharedListRepositoryProvider
          .overrideWithValue(_MockSharedListRepository(lists: lists)),

      // AllGroupsProviderをダミーデータに置き換え
      allGroupsProvider.overrideWith(() => _MockAllGroupsNotifier()),
    ],
  );
}

/// モックSharedListRepository
class _MockSharedListRepository implements SharedListRepository {
  final List<SharedList> lists;

  _MockSharedListRepository({required this.lists});

  @override
  Future<SharedList?> getSharedListById(String listId) async {
    try {
      return lists.firstWhere((list) => list.listId == listId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) async {
    return lists.where((list) => list.groupId == groupId).toList();
  }

  @override
  Future<void> updateSharedList(SharedList list) async {
    // テストでは実際の更新は不要（リセットカウント検証のみ）
  }

  // === 以下は未実装（テストで使用しない） ===
  @override
  Future<SharedList> createSharedList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
    String? customListId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteSharedList(String groupId, String listId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteSharedListsByGroupId(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> addSingleItem(String listId, SharedItem item) =>
      throw UnimplementedError();

  @override
  Future<void> removeSingleItem(String listId, String itemId) =>
      throw UnimplementedError();

  @override
  Future<void> updateSingleItem(String listId, SharedItem item) =>
      throw UnimplementedError();

  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) =>
      throw UnimplementedError();

  @override
  Future<void> cleanupDeletedItems(String listId, {int olderThanDays = 30}) =>
      throw UnimplementedError();

  @override
  Future<SharedList?> getSharedList(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> addItem(SharedList list) => throw UnimplementedError();

  @override
  Future<void> clearSharedList(String groupId) => throw UnimplementedError();

  @override
  Future<void> addSharedItem(String groupId, SharedItem item) =>
      throw UnimplementedError();

  @override
  Future<void> removeSharedItem(String groupId, SharedItem item) =>
      throw UnimplementedError();

  @override
  Future<void> updateSharedItemStatus(String groupId, SharedItem item,
          {required bool isPurchased}) =>
      throw UnimplementedError();

  @override
  Future<SharedList> getOrCreateList(String groupId, String groupName) =>
      throw UnimplementedError();

  @override
  Future<void> addItemToList(String listId, SharedItem item) =>
      throw UnimplementedError();

  @override
  Future<void> removeItemFromList(String listId, SharedItem item) =>
      throw UnimplementedError();

  @override
  Future<void> updateItemStatusInList(String listId, SharedItem item,
          {required bool isPurchased}) =>
      throw UnimplementedError();

  @override
  Future<void> clearPurchasedItemsFromList(String listId) =>
      throw UnimplementedError();

  @override
  Future<SharedList> getOrCreateDefaultList(String groupId, String groupName) =>
      throw UnimplementedError();
}
