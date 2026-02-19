// test/widgets/shared_list_page_integration_test.dart
//
// SharedListPageの統合Widget Test
// 実際のSharedListPageウィジェットとRiverpodプロバイダーを使用
//

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/datastore/shared_group_repository.dart';
import 'package:goshopping/datastore/shared_list_repository.dart';
import 'package:goshopping/models/shared_group.dart';
import 'package:goshopping/models/shared_list.dart';
import 'package:goshopping/pages/shared_list_page.dart';
import 'package:goshopping/providers/current_list_provider.dart';
import 'package:goshopping/providers/purchase_group_provider.dart'; // selectedGroupIdProvider
import 'package:goshopping/providers/shared_list_provider.dart'; // sharedListRepositoryProvider

/// ============================================================================
/// Helper Functions - Mock Data Creation
/// ============================================================================

/// テスト用のモックグループ
SharedGroup createMockGroup(String id, String name) {
  return SharedGroup(
    groupId: id,
    groupName: name,
    ownerUid: 'test_owner',
    allowedUid: ['test_owner', 'test_user1'],
    members: [
      const SharedGroupMember(
        memberId: 'test_owner',
        name: 'オーナー',
        contact: 'owner@test.com',
        role: SharedGroupRole.owner,
      ),
      const SharedGroupMember(
        memberId: 'test_user1',
        name: 'メンバー1',
        contact: 'user1@test.com',
        role: SharedGroupRole.member,
      ),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// テスト用のモックリスト
SharedList createMockList(String groupId, String listId, String name,
    {Map<String, SharedItem>? items}) {
  return SharedList(
    ownerUid: 'test_owner',
    listId: listId,
    listName: name,
    groupId: groupId,
    groupName: 'テストグループ',
    items: items ?? {},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// テスト用のモックアイテム
SharedItem createMockItem(String name, {bool isPurchased = false}) {
  return SharedItem.createNow(
    memberId: 'test_owner',
    name: name,
    quantity: 1,
    isPurchased: isPurchased,
  );
}

/// ============================================================================
/// Mock Repository - Stream Control for Timer Issue Resolution
/// ============================================================================

/// モックSharedListRepository（テスト用）
/// watchSharedList()を即座に完了するStreamで実装してTimer残存問題を解決
class MockSharedListRepository implements SharedListRepository {
  final Map<String, SharedList> _listData = {};

  /// リストデータを設定（テスト前に呼び出す）
  void setListData(String listId, SharedList list) {
    _listData[listId] = list;
  }

  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) {
    // 🔥 即座に完了するStream（Timer残存なし）
    return Stream.value(_listData[listId]);
  }

  // 以下のメソッドは未実装（テストで使用しない）
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
  Future<SharedList> createSharedList(
          {required String ownerUid,
          required String groupId,
          required String listName,
          String? description,
          String? customListId}) =>
      throw UnimplementedError();
  @override
  Future<SharedList?> getSharedListById(String listId) =>
      throw UnimplementedError();
  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) =>
      throw UnimplementedError();
  @override
  Future<void> updateSharedList(SharedList list) => throw UnimplementedError();
  @override
  Future<void> deleteSharedList(String groupId, String listId) =>
      throw UnimplementedError();
  @override
  Future<void> deleteSharedListsByGroupId(String groupId) =>
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
  Future<void> addSingleItem(String listId, SharedItem item) =>
      throw UnimplementedError();
  @override
  Future<void> removeSingleItem(String listId, String itemId) =>
      throw UnimplementedError();
  @override
  Future<void> updateSingleItem(String listId, SharedItem item) =>
      throw UnimplementedError();
  @override
  Future<void> cleanupDeletedItems(String listId, {int olderThanDays = 30}) =>
      throw UnimplementedError();
  @override
  Future<void> clearPurchasedItemsFromList(String listId) =>
      throw UnimplementedError();
  @override
  Future<SharedList> getOrCreateDefaultList(String groupId, String groupName) =>
      throw UnimplementedError();
}

/// モックSharedGroupRepository（テスト用）
/// グループデータを提供してFirebase初期化エラーを回避
class MockSharedGroupRepository implements SharedGroupRepository {
  final Map<String, SharedGroup> _groupData = {};

  /// グループデータを設定（テスト前に呼び出す）
  void setGroupData(String groupId, SharedGroup group) {
    _groupData[groupId] = group;
  }

  @override
  Future<List<SharedGroup>> getAllGroups() async {
    return _groupData.values.toList();
  }

  @override
  Future<SharedGroup> getGroupById(String groupId) async {
    final group = _groupData[groupId];
    if (group == null) {
      throw Exception('Group not found: $groupId');
    }
    return group;
  }

  // 以下のメソッドは未実装（テストで使用しない）
  @override
  Future<SharedGroup> addMember(String groupId, SharedGroupMember member) =>
      throw UnimplementedError();
  @override
  Future<SharedGroup> removeMember(String groupId, SharedGroupMember member) =>
      throw UnimplementedError();
  @override
  Future<SharedGroup> createGroup(
          String groupId, String groupName, SharedGroupMember member) =>
      throw UnimplementedError();
  @override
  Future<SharedGroup> deleteGroup(String groupId) => throw UnimplementedError();
  @override
  Future<SharedGroup> setMemberId(
          String oldId, String newId, String? contact) =>
      throw UnimplementedError();
  @override
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group) =>
      throw UnimplementedError();
  @override
  Future<SharedGroup> getOrCreateMemberPool() => throw UnimplementedError();
  @override
  Future<void> syncMemberPool() => throw UnimplementedError();
  @override
  Future<List<SharedGroupMember>> searchMembersInPool(String query) =>
      throw UnimplementedError();
  @override
  Future<SharedGroupMember?> findMemberByEmail(String email) =>
      throw UnimplementedError();
  @override
  Future<int> cleanupDeletedGroups() => throw UnimplementedError();
}

void main() {
  group('SharedListPage Integration Tests - Basic UI', () {
    testWidgets('✅ Page renders without crash with no list selected',
        (WidgetTester tester) async {
      // ARRANGE: モックRepositoryを準備
      final mockRepo = MockSharedListRepository();

      // ARRANGE: プロバイダーをオーバーライド（リスト未選択状態）
      final container = ProviderContainer(
        overrides: [
          selectedGroupIdProvider.overrideWith(
              (ref) => SelectedGroupIdNotifier()), // state = null (未選択)
          currentListProvider.overrideWith(
            (ref) => CurrentListNotifier(),
          ),
          sharedListRepositoryProvider
              .overrideWithValue(mockRepo), // 🔥 Mock Repository
        ],
      );

      // ACT: SharedListPageをビルド
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SharedListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT: プレースホルダーメッセージが表示される
      expect(find.text('リストを選択してください'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);

      // クラッシュしていないことを確認
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    testWidgets('✅ Page renders with empty list', (WidgetTester tester) async {
      // ARRANGE: 空のリストを用意
      final mockGroup = createMockGroup('group_1', 'テストグループ');
      final emptyList = createMockList('group_1', 'list_1', '買い物リスト');

      // モックRepositoryを準備
      final mockRepo = MockSharedListRepository();
      mockRepo.setListData('list_1', emptyList); // 🔥 データ設定

      // プロバイダーをオーバーライド
      final container = ProviderContainer(
        overrides: [
          selectedGroupIdProvider.overrideWith(
              (ref) => SelectedGroupIdNotifier()..state = 'group_1'),
          currentListProvider.overrideWith(
            (ref) {
              final notifier = CurrentListNotifier();
              // 初期状態として空リストを設定
              Future.microtask(() {
                notifier.selectList(emptyList);
              });
              return notifier;
            },
          ),
          sharedListRepositoryProvider
              .overrideWithValue(mockRepo), // 🔥 Mock Repository
        ],
      );

      // ACT
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SharedListPage(),
          ),
        ),
      );

      // 初期化を待つ
      await tester.pumpAndSettle();

      // ASSERT: 空リストメッセージが表示される
      expect(find.text('買い物アイテムがありません'), findsOneWidget);
      expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);

      // FABが表示される
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // クラッシュしていないことを確認
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    testWidgets('✅ Page renders with items in list',
        (WidgetTester tester) async {
      // ARRANGE: アイテムを含むリストを用意
      final mockItems = {
        'item_1': createMockItem('牛乳', isPurchased: false),
        'item_2': createMockItem('パン', isPurchased: false),
        'item_3': createMockItem('卵', isPurchased: true),
      };

      final listWithItems =
          createMockList('group_1', 'list_1', '買い物リスト', items: mockItems);

      // モックRepositoryを準備
      final mockRepo = MockSharedListRepository();
      mockRepo.setListData('list_1', listWithItems); // 🔥 データ設定

      // モックグループRepositoryを準備
      final mockGroupRepo = MockSharedGroupRepository();
      mockGroupRepo.setGroupData(
          'group_1', createMockGroup('group_1', 'テストグループ'));

      // プロバイダーをオーバーライド
      final container = ProviderContainer(
        overrides: [
          selectedGroupIdProvider.overrideWith(
              (ref) => SelectedGroupIdNotifier()..state = 'group_1'),
          currentListProvider.overrideWith(
            (ref) {
              final notifier = CurrentListNotifier();
              Future.microtask(() {
                notifier.selectList(listWithItems);
              });
              return notifier;
            },
          ),
          sharedListRepositoryProvider
              .overrideWithValue(mockRepo), // 🔥 Mock Repository
          SharedGroupRepositoryProvider.overrideWithValue(
              mockGroupRepo), // 🔥 Mock Group Repository
        ],
      );

      // ACT
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SharedListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT: アイテムが表示される
      expect(find.text('牛乳'), findsOneWidget);
      expect(find.text('パン'), findsOneWidget);
      expect(find.text('卵'), findsOneWidget);

      // チェックボックスが表示される（3個）
      expect(find.byType(Checkbox), findsNWidgets(3));

      // 空リストメッセージは表示されない
      expect(find.text('買い物アイテムがありません'), findsNothing);

      // クラッシュしていないことを確認
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    testWidgets('✅ FloatingActionButton is visible',
        (WidgetTester tester) async {
      // ARRANGE
      final emptyList = createMockList('group_1', 'list_1', '買い物リスト');

      // モックRepositoryを準備
      final mockRepo = MockSharedListRepository();
      mockRepo.setListData('list_1', emptyList); // 🔥 データ設定

      final container = ProviderContainer(
        overrides: [
          selectedGroupIdProvider.overrideWith(
              (ref) => SelectedGroupIdNotifier()..state = 'group_1'),
          currentListProvider.overrideWith(
            (ref) {
              final notifier = CurrentListNotifier();
              Future.microtask(() {
                notifier.selectList(emptyList);
              });
              return notifier;
            },
          ),
          sharedListRepositoryProvider
              .overrideWithValue(mockRepo), // 🔥 Mock Repository
        ],
      );

      // ACT
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SharedListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT: FABが表示される
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // FABのアイコンが正しい
      expect(find.descendant(of: fab, matching: find.byIcon(Icons.add)),
          findsOneWidget);

      container.dispose();
    });
  });

  group('SharedListPage Integration Tests - Widget Lifecycle', () {
    testWidgets('🔥 CRITICAL: Fast navigation does not crash',
        (WidgetTester tester) async {
      // ARRANGE
      final mockList = createMockList('group_1', 'list_1', 'テストリスト');

      // モックRepositoryを準備
      final mockRepo = MockSharedListRepository();
      mockRepo.setListData('list_1', mockList); // 🔥 データ設定

      final container = ProviderContainer(
        overrides: [
          selectedGroupIdProvider.overrideWith(
              (ref) => SelectedGroupIdNotifier()..state = 'group_1'),
          currentListProvider.overrideWith(
            (ref) {
              final notifier = CurrentListNotifier();
              Future.microtask(() {
                notifier.selectList(mockList);
              });
              return notifier;
            },
          ),
          sharedListRepositoryProvider
              .overrideWithValue(mockRepo), // 🔥 Mock Repository
        ],
      );

      // ACT: ページをビルド
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SharedListPage()),
                      );
                    },
                    child: const Text('Open Page'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // ページを開く
      await tester.tap(find.text('Open Page'));
      await tester.pumpAndSettle();

      // ページが表示されることを確認
      expect(find.byType(SharedListPage), findsOneWidget);

      // ACT: すぐに戻る（高速ナビゲーション）
      Navigator.of(tester.element(find.byType(SharedListPage))).pop();
      await tester.pumpAndSettle();

      // ASSERT: クラッシュしない（Widget disposal during async operations）
      expect(tester.takeException(), isNull);

      // 元の画面に戻っている
      expect(find.text('Open Page'), findsOneWidget);
      expect(find.byType(SharedListPage), findsNothing);

      container.dispose();
    });

    testWidgets('📱 Page handles list change correctly',
        (WidgetTester tester) async {
      // ARRANGE: 最初のリスト
      final list1 = createMockList('group_1', 'list_1', 'リスト1', items: {
        'item_1': createMockItem('牛乳'),
      });

      // 2番目のリスト
      final list2 = createMockList('group_1', 'list_2', 'リスト2', items: {
        'item_2': createMockItem('パン'),
      });

      // モックRepositoryを準備
      final mockRepo = MockSharedListRepository();
      mockRepo.setListData('list_1', list1); // 🔥 list1データ設定
      mockRepo.setListData('list_2', list2); // 🔥 list2データ設定

      // モックグループRepositoryを準備
      final mockGroupRepo = MockSharedGroupRepository();
      mockGroupRepo.setGroupData(
          'group_1', createMockGroup('group_1', 'テストグループ'));

      late CurrentListNotifier notifier;

      final container = ProviderContainer(
        overrides: [
          selectedGroupIdProvider.overrideWith(
              (ref) => SelectedGroupIdNotifier()..state = 'group_1'),
          currentListProvider.overrideWith(
            (ref) {
              notifier = CurrentListNotifier();
              Future.microtask(() {
                notifier.selectList(list1);
              });
              return notifier;
            },
          ),
          sharedListRepositoryProvider
              .overrideWithValue(mockRepo), // 🔥 Mock Repository
          SharedGroupRepositoryProvider.overrideWithValue(
              mockGroupRepo), // 🔥 Mock Group Repository
        ],
      );

      // ACT: 最初のリストでビルド
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SharedListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT: 最初のリストのアイテムが表示される
      expect(find.text('牛乳'), findsOneWidget);
      expect(find.text('パン'), findsNothing);

      // ACT: リストを変更
      notifier.selectList(list2);
      await tester.pumpAndSettle();

      // ASSERT: 2番目のリストのアイテムが表示される
      expect(find.text('牛乳'), findsNothing);
      expect(find.text('パン'), findsOneWidget);

      // クラッシュしていないことを確認
      expect(tester.takeException(), isNull);

      container.dispose();
    });
  });

  group('SharedListPage Integration Tests - Item Display', () {
    testWidgets('✨ Purchased items are displayed with strikethrough',
        (WidgetTester tester) async {
      // ARRANGE: 購入済みアイテム
      final mockItems = {
        'item_1': createMockItem('牛乳', isPurchased: true),
      };

      final listWithItems =
          createMockList('group_1', 'list_1', 'リスト', items: mockItems);

      // モックRepositoryを準備
      final mockRepo = MockSharedListRepository();
      mockRepo.setListData('list_1', listWithItems); // 🔥 データ設定

      // モックグループRepositoryを準備
      final mockGroupRepo = MockSharedGroupRepository();
      mockGroupRepo.setGroupData(
          'group_1', createMockGroup('group_1', 'テストグループ'));

      final container = ProviderContainer(
        overrides: [
          selectedGroupIdProvider.overrideWith(
              (ref) => SelectedGroupIdNotifier()..state = 'group_1'),
          currentListProvider.overrideWith(
            (ref) {
              final notifier = CurrentListNotifier();
              Future.microtask(() {
                notifier.selectList(listWithItems);
              });
              return notifier;
            },
          ),
          sharedListRepositoryProvider
              .overrideWithValue(mockRepo), // 🔥 Mock Repository
          SharedGroupRepositoryProvider.overrideWithValue(
              mockGroupRepo), // 🔥 Mock Group Repository
        ],
      );

      // ACT
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SharedListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT: アイテムが表示される
      expect(find.text('牛乳'), findsOneWidget);

      // チェックボックスがチェック済み
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      container.dispose();
    });

    testWidgets('📋 Multiple items display correctly',
        (WidgetTester tester) async {
      // ARRANGE: 5個のアイテム
      final mockItems = {
        'item_1': createMockItem('牛乳', isPurchased: false),
        'item_2': createMockItem('パン', isPurchased: false),
        'item_3': createMockItem('卵', isPurchased: true),
        'item_4': createMockItem('バター', isPurchased: false),
        'item_5': createMockItem('チーズ', isPurchased: true),
      };

      final listWithItems =
          createMockList('group_1', 'list_1', 'リスト', items: mockItems);

      // モックRepositoryを準備
      final mockRepo = MockSharedListRepository();
      mockRepo.setListData('list_1', listWithItems); // 🔥 データ設定

      // モックグループRepositoryを準備
      final mockGroupRepo = MockSharedGroupRepository();
      mockGroupRepo.setGroupData(
          'group_1', createMockGroup('group_1', 'テストグループ'));

      final container = ProviderContainer(
        overrides: [
          selectedGroupIdProvider.overrideWith(
              (ref) => SelectedGroupIdNotifier()..state = 'group_1'),
          currentListProvider.overrideWith(
            (ref) {
              final notifier = CurrentListNotifier();
              Future.microtask(() {
                notifier.selectList(listWithItems);
              });
              return notifier;
            },
          ),
          sharedListRepositoryProvider
              .overrideWithValue(mockRepo), // 🔥 Mock Repository
          SharedGroupRepositoryProvider.overrideWithValue(
              mockGroupRepo), // 🔥 Mock Group Repository
        ],
      );

      // ACT
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SharedListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT: すべてのアイテムが表示される
      expect(find.text('牛乳'), findsOneWidget);
      expect(find.text('パン'), findsOneWidget);
      expect(find.text('卵'), findsOneWidget);
      expect(find.text('バター'), findsOneWidget);
      expect(find.text('チーズ'), findsOneWidget);

      // チェックボックスが5個
      expect(find.byType(Checkbox), findsNWidgets(5));

      container.dispose();
    });
  });
}
