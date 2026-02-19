// test/widgets/shared_list_page_simple_test.dart
//
// 買い物リストページの簡素化Widget Test
// リスト表示、アイテム追加、チェック、スクロール、削除のジェスチャーをテスト
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用の簡素化された買い物リストモデル
class TestShoppingItem {
  final String id;
  final String name;
  bool isPurchased;
  final String memberName;

  TestShoppingItem({
    required this.id,
    required this.name,
    this.isPurchased = false,
    this.memberName = 'テストユーザー',
  });
}

/// テスト用の簡素化された買い物リストWidget
class SimpleShoppingListWidget extends StatefulWidget {
  final List<TestShoppingItem> items;
  final Function(String name) onAddItem;
  final Function(String id) onToggleItem;
  final Function(String id) onDeleteItem;

  const SimpleShoppingListWidget({
    super.key,
    required this.items,
    required this.onAddItem,
    required this.onToggleItem,
    required this.onDeleteItem,
  });

  @override
  State<SimpleShoppingListWidget> createState() =>
      _SimpleShoppingListWidgetState();
}

class _SimpleShoppingListWidgetState extends State<SimpleShoppingListWidget> {
  void _showAddItemDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイテム追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'アイテム名を入力',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onAddItem(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物リスト'),
      ),
      body: widget.items.isEmpty
          ? const Center(
              child: Text('アイテムがありません'),
            )
          : ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return InkWell(
                  onLongPress: () {
                    // 長押しで削除確認ダイアログ
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('削除確認'),
                        content: Text('${item.name}を削除しますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('キャンセル'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              widget.onDeleteItem(item.id);
                              Navigator.of(context).pop();
                            },
                            child: const Text('削除'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Checkbox(
                      value: item.isPurchased,
                      onChanged: (_) => widget.onToggleItem(item.id),
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration: item.isPurchased
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isPurchased ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text('登録者: ${item.memberName}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

void main() {
  group('Shopping List Page - Basic UI Tests', () {
    testWidgets('✅ Empty list shows placeholder message',
        (WidgetTester tester) async {
      // ARRANGE: 空のリスト
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: const [],
            onAddItem: (_) {},
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ASSERT: プレースホルダーメッセージが表示される
      expect(find.text('アイテムがありません'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('✅ List displays items correctly', (WidgetTester tester) async {
      // ARRANGE: 3つのアイテム
      final items = [
        TestShoppingItem(id: '1', name: '牛乳'),
        TestShoppingItem(id: '2', name: 'パン'),
        TestShoppingItem(id: '3', name: '卵', isPurchased: true),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: items,
            onAddItem: (_) {},
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ASSERT: すべてのアイテムが表示される
      expect(find.text('牛乳'), findsOneWidget);
      expect(find.text('パン'), findsOneWidget);
      expect(find.text('卵'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('👆 Tap checkbox toggles item purchase status',
        (WidgetTester tester) async {
      String? toggledItemId;

      // ARRANGE: 1つの未購入アイテム
      final items = [
        TestShoppingItem(id: '1', name: '牛乳', isPurchased: false),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: items,
            onAddItem: (_) {},
            onToggleItem: (id) {
              toggledItemId = id;
              items[0].isPurchased = !items[0].isPurchased;
            },
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ACT: チェックボックスをタップ
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // ASSERT: トグルコールバックが呼ばれた
      expect(toggledItemId, '1');
      expect(items[0].isPurchased, isTrue);
    });

    testWidgets('➕ Add item dialog opens and adds item',
        (WidgetTester tester) async {
      String? addedItemName;

      // ARRANGE: 空のリスト
      final items = <TestShoppingItem>[];

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: items,
            onAddItem: (name) {
              addedItemName = name;
              items.add(TestShoppingItem(
                id: DateTime.now().toString(),
                name: name,
              ));
            },
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ACT: FABをタップしてダイアログを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ASSERT: ダイアログが表示される
      expect(find.text('アイテム追加'), findsOneWidget);
      expect(find.text('アイテム名を入力'), findsOneWidget);

      // ACT: テキストを入力
      await tester.enterText(find.byType(TextField), '新しいアイテム');
      await tester.pump();

      // ACT: 追加ボタンをタップ
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // ASSERT: アイテムが追加された
      expect(addedItemName, '新しいアイテム');
      expect(items.length, 1);
      expect(items[0].name, '新しいアイテム');
    });

    testWidgets('📜 List scrolling works correctly',
        (WidgetTester tester) async {
      // ARRANGE: 50個のアイテム（スクロール可能）
      final items = List.generate(
        50,
        (index) => TestShoppingItem(
          id: '$index',
          name: 'アイテム $index',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: items,
            onAddItem: (_) {},
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ASSERT: 最初のアイテムが見える
      expect(find.text('アイテム 0'), findsOneWidget);
      expect(find.text('アイテム 40'), findsNothing);

      // ACT: 下にスクロール
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();

      // ASSERT: スクロールされた
      expect(find.text('アイテム 0'), findsNothing);
      // 最後の方のアイテムが見える
      final lastVisibleItem = find.text('アイテム 49');
      expect(lastVisibleItem, findsOneWidget);
    });

    testWidgets('🎯 Long press opens delete confirmation dialog',
        (WidgetTester tester) async {
      // ARRANGE: 1つのアイテム
      final items = [
        TestShoppingItem(id: '1', name: '牛乳'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: items,
            onAddItem: (_) {},
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ACT: アイテムを長押し
      await tester.longPress(find.text('牛乳'));
      await tester.pumpAndSettle();

      // ASSERT: 削除確認ダイアログが表示される
      expect(find.text('削除確認'), findsOneWidget);
      expect(find.text('牛乳を削除しますか？'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('🗑️ Delete item removes it from list',
        (WidgetTester tester) async {
      String? deletedItemId;

      // ARRANGE: 2つのアイテム
      final items = [
        TestShoppingItem(id: '1', name: '牛乳'),
        TestShoppingItem(id: '2', name: 'パン'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: items,
            onAddItem: (_) {},
            onToggleItem: (_) {},
            onDeleteItem: (id) {
              deletedItemId = id;
              items.removeWhere((item) => item.id == id);
            },
          ),
        ),
      );

      // ACT: 牛乳を長押し
      await tester.longPress(find.text('牛乳'));
      await tester.pumpAndSettle();

      // ACT: 削除ボタンをタップ
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // ASSERT: 削除コールバックが呼ばれた
      expect(deletedItemId, '1');
      expect(items.length, 1);
      expect(items[0].name, 'パン');
    });

    testWidgets('❌ Cancel button closes dialog without adding item',
        (WidgetTester tester) async {
      int addItemCallCount = 0;

      // ARRANGE
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: const [],
            onAddItem: (_) => addItemCallCount++,
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ACT: FABをタップしてダイアログを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ACT: テキストを入力
      await tester.enterText(find.byType(TextField), 'テスト');
      await tester.pump();

      // ACT: キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // ASSERT: アイテムが追加されていない
      expect(addItemCallCount, 0);
      expect(find.text('アイテム追加'), findsNothing);
    });

    testWidgets('⚠️ Empty input does not add item',
        (WidgetTester tester) async {
      int addItemCallCount = 0;

      // ARRANGE
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: const [],
            onAddItem: (_) => addItemCallCount++,
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ACT: FABをタップしてダイアログを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ACT: 空のまま追加ボタンをタップ
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // ASSERT: アイテムが追加されていない
      expect(addItemCallCount, 0);
      // ダイアログは閉じていない（入力エラー状態）
      expect(find.text('アイテム追加'), findsOneWidget);
    });
  });

  group('Shopping List Page - Visual State Tests', () {
    testWidgets('✨ Purchased items have strikethrough style',
        (WidgetTester tester) async {
      // ARRANGE: 購入済みアイテム
      final items = [
        TestShoppingItem(id: '1', name: '牛乳', isPurchased: true),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: items,
            onAddItem: (_) {},
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ASSERT: Text widgetを取得してスタイルを確認
      final textWidget = tester.widget<Text>(find.text('牛乳'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
      expect(textWidget.style?.color, Colors.grey);
    });

    testWidgets('📋 Unpurchased items have normal style',
        (WidgetTester tester) async {
      // ARRANGE: 未購入アイテム
      final items = [
        TestShoppingItem(id: '1', name: '牛乳', isPurchased: false),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleShoppingListWidget(
            items: items,
            onAddItem: (_) {},
            onToggleItem: (_) {},
            onDeleteItem: (_) {},
          ),
        ),
      );

      // ASSERT: 通常スタイル
      final textWidget = tester.widget<Text>(find.text('牛乳'));
      expect(textWidget.style?.decoration, isNull);
      expect(textWidget.style?.color, isNull);
    });
  });
}
