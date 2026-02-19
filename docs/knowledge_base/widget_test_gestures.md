# Flutter Widget Test - UIジェスチャーエミュレート完全ガイド

## 概要

FlutterのWidget Testでは、`WidgetTester`を使ってすべてのUIジェスチャーをエミュレート可能です。実機やエミュレータ不要で、高速かつ正確なテストが実行できます。

---

## 🎯 基本的なジェスチャーAPI

### 1. タップ（Tap）

```dart
// 基本的なタップ
await tester.tap(find.text('ボタン'));
await tester.pump(); // フレーム更新

// 特定の位置をタップ
await tester.tapAt(const Offset(100, 200));

// ダブルタップ
await tester.tap(find.text('ボタン'));
await tester.pump(const Duration(milliseconds: 50));
await tester.tap(find.text('ボタン'));
```

### 2. 長押し（Long Press）

```dart
// 長押し（デフォルト500ms）
await tester.longPress(find.text('アイテム'));
await tester.pumpAndSettle();

// カスタム長押し時間
await tester.press(find.text('アイテム'), Duration(seconds: 2));
```

### 3. ドラッグ（Drag）

```dart
// ドラッグ操作
await tester.drag(
  find.byType(ListView),
  const Offset(0, -300), // x, y方向の移動量
);
await tester.pumpAndSettle();

// 特定の位置からドラッグ
await tester.dragFrom(
  const Offset(100, 100), // 開始位置
  const Offset(0, -200),   // 移動量
);
```

### 4. フリング（Fling - 高速スクロール）

```dart
// 高速スクロール（フリング）
await tester.fling(
  find.byType(ListView),
  const Offset(0, -500), // 移動方向
  1000.0, // velocity（速度）
);
await tester.pumpAndSettle(); // アニメーション完了を待つ
```

### 5. スワイプ（Swipe）

```dart
// 左スワイプ（削除アクションなど）
await tester.drag(
  find.byType(Dismissible),
  const Offset(-300, 0),
);
await tester.pumpAndSettle();

// 右スワイプ
await tester.drag(
  find.byType(Dismissible),
  const Offset(300, 0),
);
```

### 6. ピンチズーム（Pinch Zoom）

```dart
// ピンチズーム（2本指操作）
final gesture1 = await tester.startGesture(const Offset(100, 100));
final gesture2 = await tester.startGesture(const Offset(200, 200));

// 指を広げる（ズームイン）
await gesture1.moveTo(const Offset(50, 50));
await gesture2.moveTo(const Offset(250, 250));
await tester.pump();

// ジェスチャー終了
await gesture1.up();
await gesture2.up();
```

---

## 📝 テキスト入力

### TextField入力

```dart
// テキスト入力
await tester.enterText(find.byType(TextField), 'テスト入力');
await tester.pump();

// TextFieldをタップしてフォーカス取得後に入力
await tester.tap(find.byType(TextField));
await tester.pump();
await tester.enterText(find.byType(TextField), 'フォーカス後入力');
```

### キーボード操作

```dart
import 'package:flutter/services.dart';

// Enterキー押下
await tester.sendKeyEvent(LogicalKeyboardKey.enter);

// Backspaceキー
await tester.sendKeyEvent(LogicalKeyboardKey.backspace);

// Ctrl+C（コピー）
await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
```

---

## ⏱️ タイミング制御

### pump系メソッド

```dart
// 1フレームだけ更新
await tester.pump();

// 指定時間経過後に更新
await tester.pump(const Duration(milliseconds: 500));

// すべてのアニメーション完了を待つ
await tester.pumpAndSettle();

// カスタムタイムアウト付きpumpAndSettle
await tester.pumpAndSettle(const Duration(seconds: 10));

// 複数フレーム更新
for (int i = 0; i < 10; i++) {
  await tester.pump(const Duration(milliseconds: 16)); // 60fps相当
}
```

---

## 🔍 要素の検索

### Finderの種類

```dart
// テキストで検索
find.text('ボタン')

// ウィジェットタイプで検索
find.byType(TextField)
find.byType(ElevatedButton)

// キーで検索
find.byKey(const Key('my-widget'))

// アイコンで検索
find.byIcon(Icons.add)

// ウィジェットインスタンスで検索
find.byWidget(myWidget)

// 条件付き検索
find.byWidgetPredicate((widget) => widget is Text && widget.data == 'test')

// 子孫要素を検索
find.descendant(
  of: find.byType(ListView),
  matching: find.text('アイテム'),
)

// 祖先要素を検索
find.ancestor(
  of: find.text('サブタイトル'),
  matching: find.byType(Card),
)
```

---

## ✅ アサーション（検証）

### 基本的な検証

```dart
// ウィジェットの存在確認
expect(find.text('ボタン'), findsOneWidget);
expect(find.text('ボタン'), findsNothing);
expect(find.text('アイテム'), findsNWidgets(3));
expect(find.text('リストアイテム'), findsWidgets); // 1つ以上

// ウィジェットのプロパティ検証
final TextField textField = tester.widget(find.byType(TextField));
expect(textField.controller?.text, equals('期待値'));
expect(textField.enabled, isTrue);

// 例外が発生しないことを確認
expect(tester.takeException(), isNull);
```

### 視覚的な検証

```dart
// ウィジェットが画面内に表示されているか
final renderObject = tester.renderObject(find.text('ボタン'));
expect(renderObject.paintBounds.isEmpty, isFalse);

// スクロール位置の確認
final ScrollController controller = tester.widget<Scrollable>(
  find.byType(Scrollable),
).controller as ScrollController;
expect(controller.offset, greaterThan(100));
```

---

## 🚨 Widget Lifecycle テスト（今回のケース）

### 問題: Widget disposal後のref使用

```dart
testWidgets('Widget disposal during async should not crash', (tester) async {
  await tester.pumpWidget(/* ... */);

  // ダイアログを開く
  await tester.tap(find.text('Open Dialog'));
  await tester.pumpAndSettle();

  // グループ作成を開始（async処理開始）
  await tester.enterText(find.byType(TextField), 'テストグループ');
  await tester.tap(find.text('作成'));

  // 🔥 CRITICAL: ダイアログを即座に閉じる（Widget disposal）
  await tester.pump(const Duration(milliseconds: 100));
  // Navigator.pop() シミュレート

  // さらにasync処理継続中
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 300));

  // VERIFY: '_dependents.isEmpty' assertionが発生しない
  expect(tester.takeException(), isNull);
});
```

---

## 🎭 モック・オーバーライド

### Riverpodプロバイダーのオーバーライド

```dart
testWidgets('Test with mock service', (tester) async {
  final mockService = MockNotificationService();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(mockService),
        authStateProvider.overrideWith((ref) => Stream.value(mockUser)),
      ],
      child: const MyApp(),
    ),
  );

  // テスト実行...

  // モックの呼び出し確認
  expect(mockService.notificationsSent, equals(3));
});
```

---

## 🏃 テスト実行方法

### コマンドライン

```bash
# すべてのテスト実行
flutter test

# 特定のファイルのみ
flutter test test/widgets/group_creation_with_copy_dialog_test.dart

# 特定のテストケースのみ（名前で絞り込み）
flutter test --name "Widget lifecycle"

# カバレッジレポート生成
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# VS Code統合
# テストファイルで右クリック → "Run Tests"
# または、テストケース上の "Run" ボタンをクリック
```

### よく使うテストオプション

```bash
# 詳細出力
flutter test --verbose

# 並列実行数指定
flutter test -j 4

# タイムアウト設定
flutter test --timeout 60s

# ランダム実行順序
flutter test --test-randomize-ordering-seed=random
```

---

## 📊 パフォーマンステスト

### フレームレート測定

```dart
testWidgets('Smooth scrolling performance', (tester) async {
  await tester.pumpWidget(/* ... */);

  // スクロール開始
  final timeline = await tester.binding.traceAction(() async {
    await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);
    await tester.pumpAndSettle();
  });

  // フレームレート解析
  final summary = TimelineSummary.summarize(timeline);
  summary.writeSummaryToFile('scrolling', pretty: true);

  // 90th percentileが16ms以下（60fps維持）
  expect(summary.summaryJson['90th_percentile_frame_build_time_millis'],
      lessThan(16));
});
```

---

## 🐛 デバッグテクニック

### Visual Debugging

```dart
// ウィジェットツリーを出力
debugDumpApp();

// レンダーツリーを出力
debugDumpRenderTree();

// レイヤーツリーを出力
debugDumpLayerTree();

// すべてのウィジェットを列挙
tester.allWidgets.forEach(print);

// 特定のウィジェットの詳細
print(tester.widget(find.byType(TextField)));
```

### スクリーンショット取得（Golden Test）

```dart
testWidgets('Screenshot test', (tester) async {
  await tester.pumpWidget(const MyWidget());

  // スクリーンショットを取得して比較
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('my_widget.png'),
  );
});
```

---

## 🎯 ベストプラクティス

### 1. 適切なpump使用

```dart
// ❌ Bad: pumpを忘れる
await tester.tap(find.text('ボタン'));
expect(find.text('結果'), findsOneWidget); // 失敗する可能性

// ✅ Good: pumpで更新
await tester.tap(find.text('ボタン'));
await tester.pump();
expect(find.text('結果'), findsOneWidget);
```

### 2. pumpAndSettle vs pump

```dart
// ❌ Bad: アニメーション完了を待たない
await tester.tap(find.text('ボタン'));
await tester.pump();
expect(find.text('ダイアログ'), findsOneWidget); // アニメーション中で失敗

// ✅ Good: アニメーション完了を待つ
await tester.tap(find.text('ボタン'));
await tester.pumpAndSettle();
expect(find.text('ダイアログ'), findsOneWidget);
```

### 3. Finder再利用

```dart
// ❌ Bad: 毎回find実行
await tester.tap(find.text('ボタン'));
await tester.pump();
final button = tester.widget(find.text('ボタン'));

// ✅ Good: Finderを変数に保存
final buttonFinder = find.text('ボタン');
await tester.tap(buttonFinder);
await tester.pump();
final button = tester.widget(buttonFinder);
```

### 4. Widgetの存在確認

```dart
// ❌ Bad: 存在確認なしでタップ
await tester.tap(find.text('ボタン'));

// ✅ Good: 存在確認してからタップ
expect(find.text('ボタン'), findsOneWidget);
await tester.tap(find.text('ボタン'));
```

---

## 🔗 関連リソース

- [Flutter Widget Testing公式ドキュメント](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [WidgetTester API Reference](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [mockito](https://pub.dev/packages/mockito) - モッキングライブラリ
- [patrol](https://pub.dev/packages/patrol) - 高度なテスト自動化

---

## 📝 プロジェクト内のテスト例

- `test/widgets/group_creation_with_copy_dialog_test.dart` - Widget lifecycle、ジェスチャー、プラットフォーム固有テスト
