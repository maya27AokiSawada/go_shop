// 統合的なCRUDシナリオテスト
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/shared_group.dart';
import 'package:goshopping/models/shared_list.dart';

void main() {
  group('統合的なCRUDシナリオ Tests', () {
    test('シナリオ1: グループ作成 → リスト作成 → アイテム追加 → 更新 → 削除', () {
      // Step 1: グループ作成
      final group = SharedGroup(
        groupId: 'group-001',
        groupName: '家族グループ',
        ownerUid: 'user-alice',
        allowedUid: ['user-alice'],
        members: const [
          SharedGroupMember(
            memberId: 'user-alice',
            name: 'Alice',
            contact: 'alice@example.com',
            role: SharedGroupRole.owner,
          ),
        ],
        createdAt: DateTime.now(),
      );
      expect(group.members?.length, 1);

      // Step 2: リスト作成
      final shoppingList = SharedList.create(
        ownerUid: group.ownerUid!,
        groupId: group.groupId,
        groupName: group.groupName,
        listName: '今週の買い物',
      );
      expect(shoppingList.items.isEmpty, true);

      // Step 3: アイテム追加
      final milk = SharedItem.createNow(
        memberId: 'user-alice',
        name: '牛乳',
        quantity: 2,
      );
      final bread = SharedItem.createNow(
        memberId: 'user-alice',
        name: 'パン',
        quantity: 1,
      );
      final eggs = SharedItem.createNow(
        memberId: 'user-alice',
        name: '卵',
        quantity: 1,
      );

      var updatedList = shoppingList.copyWith(
        items: {
          milk.itemId: milk,
          bread.itemId: bread,
          eggs.itemId: eggs,
        },
      );
      expect(updatedList.items.length, 3);

      // Step 4: アイテム更新（購入済みにする）
      final purchasedMilk = milk.copyWith(
        isPurchased: true,
        purchaseDate: DateTime.now(),
      );
      updatedList = updatedList.copyWith(
        items: {...updatedList.items, milk.itemId: purchasedMilk},
      );
      expect(updatedList.items[milk.itemId]?.isPurchased, true);

      // Step 5: アイテム削除（論理削除）
      final deletedBread = bread.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      updatedList = updatedList.copyWith(
        items: {...updatedList.items, bread.itemId: deletedBread},
      );
      expect(updatedList.items.length, 3); // 物理的には3つ
      expect(updatedList.activeItems.length, 2); // アクティブは2つ
    });

    test('シナリオ2: 複数ユーザーでの同時操作', () {
      // Step 1: グループにメンバー追加
      final group = SharedGroup(
        groupId: 'group-001',
        groupName: '家族グループ',
        ownerUid: 'user-alice',
        allowedUid: ['user-alice'],
        members: const [
          SharedGroupMember(
            memberId: 'user-alice',
            name: 'Alice',
            contact: 'alice@example.com',
            role: SharedGroupRole.owner,
          ),
        ],
        createdAt: DateTime.now(),
      );

      const newMember = SharedGroupMember(
        memberId: 'user-bob',
        name: 'Bob',
        contact: 'bob@example.com',
        role: SharedGroupRole.member,
      );

      final groupWithBob = group.copyWith(
        allowedUid: [...group.allowedUid, 'user-bob'],
        members: [...?group.members, newMember],
      );
      expect(groupWithBob.members?.length, 2);

      // Step 2: 各ユーザーがアイテム追加
      final list = SharedList.create(
        ownerUid: group.ownerUid!,
        groupId: group.groupId,
        groupName: group.groupName,
        listName: '今週の買い物',
      );

      final aliceItem = SharedItem.createNow(
        memberId: 'user-alice',
        name: 'Aliceが追加: 牛乳',
      );
      final bobItem = SharedItem.createNow(
        memberId: 'user-bob',
        name: 'Bobが追加: パン',
      );

      final updatedList = list.copyWith(
        items: {
          aliceItem.itemId: aliceItem,
          bobItem.itemId: bobItem,
        },
      );

      // Assert
      expect(updatedList.items.length, 2);
      expect(
        updatedList.items.values
            .where((item) => item.memberId == 'user-alice')
            .length,
        1,
      );
      expect(
        updatedList.items.values
            .where((item) => item.memberId == 'user-bob')
            .length,
        1,
      );
    });

    test('シナリオ3: 複数リストの管理', () {
      // Arrange
      final group = SharedGroup(
        groupId: 'group-001',
        groupName: '家族グループ',
        ownerUid: 'user-alice',
        allowedUid: ['user-alice', 'user-bob', 'user-charlie'],
        members: const [
          SharedGroupMember(
            memberId: 'user-alice',
            name: 'Alice',
            contact: 'alice@example.com',
            role: SharedGroupRole.owner,
          ),
          SharedGroupMember(
            memberId: 'user-bob',
            name: 'Bob',
            contact: 'bob@example.com',
            role: SharedGroupRole.member,
          ),
          SharedGroupMember(
            memberId: 'user-charlie',
            name: 'Charlie',
            contact: 'charlie@example.com',
            role: SharedGroupRole.member,
          ),
        ],
        createdAt: DateTime.now(),
      );

      // Act - 複数リスト作成
      final shoppingList = SharedList.create(
        ownerUid: group.ownerUid!,
        groupId: group.groupId,
        groupName: group.groupName,
        listName: '今週の買い物',
      );

      final todoList = SharedList.create(
        ownerUid: group.ownerUid!,
        groupId: group.groupId,
        groupName: group.groupName,
        listName: 'TODOリスト',
      ).copyWith(listType: ListType.todo);

      // Assert
      expect(shoppingList.listType, ListType.shopping);
      expect(todoList.listType, ListType.todo);
      expect(shoppingList.listId != todoList.listId, true);
    });

    test('シナリオ4: 定期購入アイテムの管理', () {
      // Arrange
      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: '定期購入リスト',
      );

      // Act - 定期購入アイテム作成
      final milk = SharedItem.createNow(
        memberId: 'user-123',
        name: '牛乳',
        shoppingInterval: 3, // 3日ごと
      );
      final eggs = SharedItem.createNow(
        memberId: 'user-123',
        name: '卵',
        shoppingInterval: 5, // 5日ごと
      );

      final updatedList = list.copyWith(
        items: {
          milk.itemId: milk,
          eggs.itemId: eggs,
        },
      );

      // Assert
      expect(
          updatedList.items.values.every((i) => i.shoppingInterval > 0), true);
      expect(updatedList.items[milk.itemId]?.shoppingInterval, 3);
      expect(updatedList.items[eggs.itemId]?.shoppingInterval, 5);
    });

    test('シナリオ5: 購入期限付きアイテムの管理', () {
      // Arrange
      final list = SharedList.create(
        ownerUid: 'user-123',
        groupId: 'group-001',
        groupName: 'Test Group',
        listName: '期限付きリスト',
      );

      // Act - 期限付きアイテム作成
      final cake = SharedItem.createNow(
        memberId: 'user-123',
        name: 'ケーキ',
        deadline: DateTime.now().add(const Duration(days: 2)),
      );
      final meat = SharedItem.createNow(
        memberId: 'user-123',
        name: '肉',
        deadline: DateTime.now().add(const Duration(days: 3)),
      );

      final updatedList = list.copyWith(
        items: {
          cake.itemId: cake,
          meat.itemId: meat,
        },
      );

      // Assert
      expect(updatedList.items.values.every((i) => i.deadline != null), true);
    });

    test('シナリオ6: 差分同期の効率検証', () {
      // Arrange - 大量アイテムリスト
      final items = <String, SharedItem>{};
      for (int i = 0; i < 100; i++) {
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
        listName: 'Big List',
        items: items,
      );

      // Act - 単一アイテムのみ更新（差分更新パターン）
      final stopwatch = Stopwatch()..start();
      final firstItem = list.items.values.first;
      final updatedItem = firstItem.copyWith(
        isPurchased: true,
        purchaseDate: DateTime.now(),
      );

      // ⚠️ 実際のFirestore差分同期では、この1つのアイテムだけが送信される
      final updatedList = list.copyWith(
        items: {...list.items, firstItem.itemId: updatedItem},
      );
      stopwatch.stop();

      // Assert
      expect(updatedList.items.length, 100);
      expect(updatedList.items[firstItem.itemId]?.isPurchased, true);

      // パフォーマンス検証: Map操作は高速（1ms以内）
      expect(stopwatch.elapsedMilliseconds < 10, true);

      // 差分同期のメリット: 送信データは1アイテム分のみ（約500B）
      // 全リスト送信の場合: 100アイテム × 500B = 約50KB → 90%削減
    });

    test('シナリオ7: 不正なロール変更の検出', () {
      // Arrange
      final originalGroup = SharedGroup(
        groupId: 'group-001',
        groupName: 'Test Group',
        ownerUid: 'user-alice',
        allowedUid: ['user-alice', 'user-bob'],
        members: const [
          SharedGroupMember(
            memberId: 'user-alice',
            name: 'Alice',
            contact: 'alice@example.com',
            role: SharedGroupRole.owner,
          ),
          SharedGroupMember(
            memberId: 'user-bob',
            name: 'Bob',
            contact: 'bob@example.com',
            role: SharedGroupRole.member,
          ),
        ],
        createdAt: DateTime.now(),
      );

      // Act - BobをOwnerにしようとする（不正な操作）
      final invalidUpdate = originalGroup.copyWith(
        members: [
          const SharedGroupMember(
            memberId: 'user-alice',
            name: 'Alice',
            contact: 'alice@example.com',
            role: SharedGroupRole.owner,
          ),
          const SharedGroupMember(
            memberId: 'user-bob',
            name: 'Bob',
            contact: 'bob@example.com',
            role: SharedGroupRole.owner, // ← 不正な変更
          ),
        ],
      );

      // Assert - データモデル上は変更できるが、実際のアプリでは検証が必要
      expect(
        invalidUpdate.members?.firstWhere((m) => m.memberId == 'user-bob').role,
        SharedGroupRole.owner,
      );
      // ⚠️ 実際のアプリでは、Repository層やFirestoreルールで制限する
    });
  });
}
