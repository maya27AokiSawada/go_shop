// SharedList モデルのユニットテスト
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/shared_list.dart';

void main() {
  group('SharedList モデル CRUD Tests', () {
    test('SharedList - 正しく作成できる', () {
      // Act
      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: '買い物リスト',
        description: 'テスト用リスト',
      );

      // Assert
      expect(list.ownerUid, 'user-123');
      expect(list.groupId, 'group-001');
      expect(list.listName, '買い物リスト');
      expect(list.description, 'テスト用リスト');
      expect(list.items.isEmpty, true);
    });

    test('SharedList - copyWithで更新できる', () {
      // Arrange
      final original = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: 'Original List',
      );

      // Act
      final updated = original.copyWith(
        listName: 'Updated List',
        description: '更新済み',
      );

      // Assert
      expect(updated.listId, original.listId);
      expect(updated.listName, 'Updated List');
      expect(updated.description, '更新済み');
    });

    test('SharedItem - 正しく作成できる', () {
      // Act
      final item = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
        quantity: 2,
      );

      // Assert
      expect(item.memberId, 'user-123');
      expect(item.name, '牛乳');
      expect(item.quantity, 2);
      expect(item.isPurchased, false);
      expect(item.itemId.isNotEmpty, true);
    });

    test('SharedItem - 購入状態を更新できる', () {
      // Arrange
      final item = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
      );

      // Act
      final purchased = item.copyWith(
        isPurchased: true,
        purchaseDate: DateTime.now(),
      );

      // Assert
      expect(purchased.isPurchased, true);
      expect(purchased.purchaseDate, isNotNull);
    });

    test('SharedList - アイテム追加（Map形式）', () {
      // Arrange
      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: 'Shopping List',
      );

      final item1 = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
      );
      final item2 = SharedItem.createNow(
        memberId: 'user-123',
        name: 'パン',
      );

      // Act
      final updatedList = list.copyWith(
        items: {
          item1.itemId: item1,
          item2.itemId: item2,
        },
      );

      // Assert
      expect(updatedList.items.length, 2);
      expect(updatedList.items.containsKey(item1.itemId), true);
      expect(updatedList.items.containsKey(item2.itemId), true);
    });

    test('SharedList - アイテム更新（Map形式）', () {
      // Arrange
      final item = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
        quantity: 1,
      );

      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: 'Shopping List',
        items: {item.itemId: item},
      );

      // Act
      final updatedItem = item.copyWith(quantity: 3);
      final updatedList = list.copyWith(
        items: {...list.items, item.itemId: updatedItem},
      );

      // Assert
      expect(updatedList.items[item.itemId]?.quantity, 3);
    });

    test('SharedList - アイテム削除（論理削除）', () {
      // Arrange
      final item1 = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
      );
      final item2 = SharedItem.createNow(
        memberId: 'user-123',
        name: 'パン',
      );

      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: 'Shopping List',
        items: {
          item1.itemId: item1,
          item2.itemId: item2,
        },
      );

      // Act（論理削除）
      final deletedItem = item1.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      final updatedList = list.copyWith(
        items: {...list.items, item1.itemId: deletedItem},
      );

      // Assert
      expect(updatedList.items.length, 2); // 物理的には2つ
      expect(updatedList.activeItems.length, 1); // アクティブは1つ
      expect(updatedList.deletedItemCount, 1);
    });

    test('SharedList - activeItemsゲッター', () {
      // Arrange
      final item1 = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
      );
      final item2 = SharedItem.createNow(
        memberId: 'user-123',
        name: 'パン',
      );
      final deletedItem = SharedItem.createNow(
        memberId: 'user-123',
        name: '卵',
      ).copyWith(isDeleted: true, deletedAt: DateTime.now());

      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: 'Shopping List',
        items: {
          item1.itemId: item1,
          item2.itemId: item2,
          deletedItem.itemId: deletedItem,
        },
      );

      // Assert
      expect(list.items.length, 3);
      expect(list.activeItems.length, 2);
      expect(list.deletedItemCount, 1);
      expect(list.activeItems.any((item) => item.name == '卵'), false);
    });

    test('SharedItem - 定期購入アイテム作成', () {
      // Act
      final item = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
        shoppingInterval: 3, // 3日ごとに購入
      );

      // Assert
      expect(item.shoppingInterval, 3);
      expect(item.shoppingInterval > 0, true); // 定期購入アイテム
    });

    test('SharedItem - 購入期限設定', () {
      // Act
      final deadline = DateTime.now().add(const Duration(days: 3));
      final item = SharedItem.createNow(
        memberId: 'user-123',
        name: 'ケーキ',
        deadline: deadline,
      );

      // Assert
      expect(item.deadline, isNotNull);
      expect(item.deadline, deadline);
    });

    test('SharedList - パフォーマンステスト（100アイテム）', () {
      // Arrange
      final items = <String, SharedItem>{};
      for (int i = 0; i < 100; i++) {
        final item = SharedItem.createNow(
          memberId: 'user-123',
          name: 'アイテム$i',
        );
        items[item.itemId] = item;
      }

      // Act
      final stopwatch = Stopwatch()..start();
      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: 'Big List',
        items: items,
      );
      stopwatch.stop();

      // Assert
      expect(list.items.length, 100);
      expect(stopwatch.elapsedMilliseconds < 100, true); // 100ms以内
    });

    test('SharedList - 複数アイテム差分更新パターン', () {
      // Arrange
      final item1 = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
      );

      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: 'Shopping List',
        items: {item1.itemId: item1},
      );

      // Act - 新しいアイテムを追加（差分更新パターン）
      final newItem = SharedItem.createNow(
        memberId: 'user-123',
        name: 'パン',
      );
      final updatedList = list.copyWith(
        items: {...list.items, newItem.itemId: newItem},
      );

      // Assert
      expect(updatedList.items.length, 2);
      expect(updatedList.items.containsKey(item1.itemId), true);
      expect(updatedList.items.containsKey(newItem.itemId), true);
    });

    test('SharedList - パフォーマンステスト（1000アイテム差分更新）', () {
      // Arrange
      final items = <String, SharedItem>{};
      for (int i = 0; i < 1000; i++) {
        final item = SharedItem.createNow(
          memberId: 'user-123',
          name: 'アイテム$i',
        );
        items[item.itemId] = item;
      }

      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: 'Huge List',
        items: items,
      );

      // Act - 単一アイテム更新（差分更新パターン）
      final stopwatch = Stopwatch()..start();
      final itemToUpdate = list.items.values.first;
      final updatedItem = itemToUpdate.copyWith(quantity: 10);
      final updatedList = list.copyWith(
        items: {...list.items, itemToUpdate.itemId: updatedItem},
      );
      stopwatch.stop();

      // Assert
      expect(updatedList.items.length, 1000);
      expect(updatedList.items[itemToUpdate.itemId]?.quantity, 10);
      expect(stopwatch.elapsedMilliseconds < 50, true); // 50ms以内
    });
  });
}
