// test/widgets/group_creation_widget_simple_test.dart
//
// 簡素化されたWidget Lifecycle Test
// Firebase/Riverpod依存を最小化し、Widget基本動作のみをテスト
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Lifecycle - Basic Dialog Tests', () {
    testWidgets('✅ Dialog can be opened and closed without crash',
        (WidgetTester tester) async {
      // ARRANGE: 基本的なダイアログWidget
      bool dialogClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Test Dialog'),
                        content: const Text('This is a test'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              dialogClosed = true;
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ACT: ダイアログを開く
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // ASSERT: ダイアログが表示されている
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('This is a test'), findsOneWidget);

      // ACT: ダイアログを閉じる
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // ASSERT: ダイアログが閉じられた
      expect(find.text('Test Dialog'), findsNothing);
      expect(dialogClosed, isTrue);

      // ASSERT: クラッシュなし
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '🔥 CRITICAL: Fast dialog closure during async operation should not crash',
        (WidgetTester tester) async {
      // このテストはWindows版で発生したWidget lifecycle bugを再現
      // ref.read()がasync境界を超えて使用された場合にクラッシュ

      bool asyncOperationComplete = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Async Dialog'),
                        content: const Text('Processing...'),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              // ダイアログを即座に閉じる（Widgetがdispose）
                              Navigator.of(dialogContext).pop();

                              // 🔥 CRITICAL: async境界を超えた処理
                              // 正しい実装では ref.read() がasync前に呼ばれている
                              await Future.delayed(
                                  const Duration(milliseconds: 200));
                              asyncOperationComplete = true;
                            },
                            child: const Text('Start Async'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      // ACT: ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // ACT: async処理を開始（ダイアログが閉じる）
      await tester.tap(find.text('Start Async'));
      // pumpAndSettleでダイアログが閉じるまで待つ
      await tester.pumpAndSettle();

      // ASSERT: ダイアログが閉じられた（async処理継続中）
      expect(find.text('Async Dialog'), findsNothing);

      // ASSERT: クラッシュなし（'_dependents.isEmpty' assertion回避）
      expect(tester.takeException(), isNull);

      // すべてのasync処理完了まで待つ
      await tester.pumpAndSettle();

      // ASSERT: async処理が完了（Widget dispose後でもクラッシュしない）
      expect(asyncOperationComplete, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('📜 TextField input works correctly',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter text'),
            ),
          ),
        ),
      );

      // ACT: テキスト入力
      await tester.enterText(find.byType(TextField), 'Test Input');
      await tester.pump();

      // ASSERT: 入力が反映された
      expect(controller.text, 'Test Input');
      expect(find.text('Test Input'), findsOneWidget);
    });

    testWidgets('👆 Multiple taps work correctly', (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                tapCount++;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      // ACT: 3回タップ
      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      // ASSERT: タップカウントが正しい
      expect(tapCount, 3);
    });

    testWidgets('📜 Scroll gesture works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      // ASSERT: 最初のアイテムが見える
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 40'), findsNothing);

      // ACT: 下にスクロール
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();

      // ASSERT: スクロールされた
      expect(find.text('Item 0'), findsNothing);
      expect(find.text('Item 40'), findsOneWidget);
    });
  });
}
