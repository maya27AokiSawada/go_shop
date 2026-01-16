# 日報 2026-01-16 - ホワイトボードにスクロール可能なキャンバス＋スクロールロック機能実装

## 📅 作業日
2026年1月16日（木）

## 🎯 作業概要
ホワイトボード機能に拡張可能なキャンバスとスクロールバー、スクロールロック機能を実装（future ブランチ）

## ✅ 完了タスク

### 1. スクロール可能なキャンバス実装 ✅

**目的**: より大きなホワイトボードとして使用できるよう、画面サイズを超えるキャンバスを実装

**実装内容**:

#### 拡張可能なキャンバスサイズ
```dart
// キャンバススケール（画面サイズの倍数）
double _canvasScale = 2.0; // デフォルト: 2倍

// LayoutBuilderでキャンバスサイズを計算
final canvasWidth = constraints.maxWidth * _canvasScale;
final canvasHeight = constraints.maxHeight * _canvasScale;
```

**選択可能なサイズ**:
- **1x**: 画面サイズと同じ（スクロール不要）
- **2x**: 画面の2倍（デフォルト）
- **3x**: 画面の3倍
- **4x**: 画面の4倍

#### スクロールバーの実装
```dart
Scrollbar(
  controller: _horizontalScrollController,
  thumbVisibility: true, // 常にスクロールバーを表示
  trackVisibility: true,
  child: Scrollbar(
    controller: _verticalScrollController,
    thumbVisibility: true,
    trackVisibility: true,
    notificationPredicate: (notification) => notification.depth == 1,
    child: SingleChildScrollView(
      controller: _horizontalScrollController,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Container(
          width: canvasWidth,
          height: canvasHeight,
          // ... キャンバス内容
        ),
      ),
    ),
  ),
)
```

**特徴**:
- ✅ 縦横両方向のスクロール対応
- ✅ スクロールバーを常時表示（`thumbVisibility: true`）
- ✅ トラック（レール）も表示（`trackVisibility: true`）
- ✅ 2つのScrollbarの階層構造（`notificationPredicate`で制御）

---

### 2. キャンバスサイズ選択UI実装 ✅

**ツールバーに追加**:
```dart
DropdownButton<double>(
  value: _canvasScale,
  items: const [
    DropdownMenuItem(value: 1.0, child: Text('1x')),
    DropdownMenuItem(value: 2.0, child: Text('2x')),
    DropdownMenuItem(value: 3.0, child: Text('3x')),
    DropdownMenuItem(value: 4.0, child: Text('4x')),
  ],
  onChanged: (value) {
    if (value != null) {
      setState(() {
        _canvasScale = value;
      });
    }
  },
)
```

**配置**: ツールバー下段（線幅スライダーの右側）

---

### 3. グリッド線表示機能実装 ✅

**目的**: 大きなキャンバスで位置感覚をつかみやすくする

**実装内容**:
```dart
/// グリッド線オーバーレイ
Widget _buildGridOverlay(double width, double height) {
  return CustomPaint(
    size: Size(width, height),
    painter: GridPainter(
      gridSize: 50.0, // 50pxごとにグリッド線
      color: Colors.grey.withOpacity(0.2),
    ),
  );
}

/// グリッド線を描画するCustomPainter
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 縦線
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 横線
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
}
```

**特徴**:
- ✅ 50px間隔のグリッド線
- ✅ 半透明のグレー（`opacity: 0.2`）で邪魔にならない
- ✅ Stackの背景レイヤーとして配置

---

### 4. ScrollController管理 ✅

**追加したコントローラー**:
```dart
final ScrollController _horizontalScrollController = ScrollController();
final ScrollController _verticalScrollController = ScrollController();
```

**dispose処理**:
```dart
@override
void dispose() {
  _controller?.dispose();
  _horizontalScrollController.dispose();
  _verticalScrollController.dispose();
  super.dispose();
}
```

**理由**: メモリリーク防止のため、使用したScrollControllerは必ずdisposeする

---

### 5. スクロールロック機能実装 ✅

**目的**: スマホでタッチ操作時にスクロールと描画が競合する問題を解決

**実装内容**:

#### スクロールロックボタン追加
```dart
// スクロールロックフラグ
bool _isScrollLocked = false;

// ツールバーにボタン追加
IconButton(
  icon: Icon(
    _isScrollLocked ? Icons.lock : Icons.lock_open,
    color: _isScrollLocked ? Colors.blue : Colors.grey,
  ),
  onPressed: () {
    setState(() {
      _isScrollLocked = !_isScrollLocked;
    });
  },
  tooltip: _isScrollLocked ? 'スクロール無効（描画モード）' : 'スクロール有効',
)
```

#### スクロール制御
```dart
SingleChildScrollView(
  physics: _isScrollLocked
      ? const NeverScrollableScrollPhysics()  // ロック時: スクロール無効
      : const AlwaysScrollableScrollPhysics(), // 通常時: スクロール有効
  // ...
)
```

#### 描画制御（IgnorePointer）
```dart
Positioned.fill(
  child: IgnorePointer(
    ignoring: !_isScrollLocked, // スクロールロック時のみ描画可能
    child: Signature(
      controller: _controller!,
      backgroundColor: Colors.transparent,
    ),
  ),
)
```

**動作**:
- **🔓 スクロール有効（デフォルト）**: 描画不可、スクロール可能
- **🔒 スクロール無効（ロック）**: 描画可能、スクロール不可

**特徴**:
- ✅ 誤操作防止（スクロール中に意図せず描画してしまうことを防止）
- ✅ 明示的な操作（ユーザーが意識的にモード切替）
- ✅ 視覚的フィードバック（ロック時は青色のアイコン）

---

## 🏗️ アーキテクチャ

### レイヤー構造（Stackの順序）
```
Stack (children: [
  1. GridPainter (グリッド線 - 最背面)
  2. DrawingStrokePainter (保存済みストローク - 中間)
  3. Signature (現在の描画セッション - 最前面)
])
```

### スクロール構造（ネスト）
```
Scrollbar (横スクロール)
└─ Scrollbar (縦スクロール, notificationPredicate: depth == 1)
   └─ SingleChildScrollView (横)
      └─ SingleChildScrollView (縦)
         └─ Container (キャンバス)
            └─ Stack (描画レイヤー)
```

**notificationPredicate**:
- 内側のScrollbarが外側のスクロール通知に反応しないようにする
- `notification.depth == 1`で内側のスクロールのみ処理

---

## 📦 修正ファイル

### Modified Files (1ファイル)
- `lib/pages/whiteboard_editor_page.dart` (415行 → 558行)
  - ScrollController追加（横・縦）
  - `_canvasScale`プロパティ追加
  - `_isScrollLocked`プロパティ追加
  - LayoutBuilder + Scrollbar実装
  - スクロールロックボタン追加
  - IgnorePointer実装（描画制御）
  - DropdownButtonでキャンバスサイズ選択
  - GridPainterクラス追加
  - `_buildGridOverlay()`メソッド追加

---

## 🎨 機能仕様

### スクロール機能
- ✅ 横スクロール（左右）
- ✅ 縦スクロール（上下）
- ✅ スクロールバー常時表示
- ✅ トラック（レール）表示

### キャンバスサイズ
- ✅ 1x: 画面サイズ（スクロール不要）
- ✅ 2x: 画面の2倍（デフォルト）
- ✅ 3x: 画面の3倍
- ✅ 4x: 画面の4倍

### グリッド表示
- ✅ 50px間隔のグリッド線
- ✅ 半透明グレー（邪魔にならない）
- ✅ キャンバス全体に表示

### スクロールロック機能
- ✅ スクロールロックボタン（🔒/🔓）
- ✅ ロック時: 描画可能、スクロール不可
- ✅ 解除時: 描画不可、スクロール可能
- ✅ 誤操作防止（意図しない描画を防止）

### ツールバー（更新後）
```
┌──────────────────────────────────────────────────┐
│ 色: [●][●][●][●][●][●][●]                        │ 上段
├──────────────────────────────────────────────────┤
│ 太さ: [━━━━━●━━━━━] [1x▼] [🔒] [🗑️]             │ 下段
└──────────────────────────────────────────────────┘
```

---

## 🐛 解決した問題

### Issue 1: 構文エラー（カンマミス）
**症状**: `_captureCurrentDrawing(),` → カンマが不要
**原因**: コピペミス
**解決**: セミコロンに修正 `_captureCurrentDrawing();`

### Issue 2: ScrollControllerのメモリリーク
**対策**: dispose処理で明示的に破棄
```dart
_horizontalScrollController.dispose();
_verticalScrollController.dispose();
```

### Issue 3: `_selectedColor`が変更できない
**症状**: `final Color _selectedColor`でエラー
**原因**: finalキーワードで不変にしてしまった
**解決**: `Color _selectedColor`に修正

### Issue 4: スマホでスクロールしてしまい描画できない ⭐
**症状**: タッチするとスクロールが優先され、描画できない
**原因**: SingleChildScrollViewとSignatureのジェスチャー競合
**解決**: スクロールロックボタンを実装
  - `_isScrollLocked`フラグで制御
  - ロック時: `NeverScrollableScrollPhysics` + `IgnorePointer(ignoring: false)`
  - 解除時: `AlwaysScrollableScrollPhysics` + `IgnorePointer(ignoring: true)`

### Issue 5: Signatureがタッチイベントを受け取れない
**症状**: スクロールロックしても描画できない
**原因**: `Signature`が`Positioned.fill`でラップされていなかった
**解決**: `Positioned.fill`でラップしてタッチ領域を確保

### Issue 6: 余分な閉じ括弧
**症状**: Line 284-285に余分な`),`が2つ
**原因**: コード編集時のミス
**解決**: 余分な括弧を削除

---

## 📊 パフォーマンス指標

### キャンバスサイズ別メモリ使用量（予測）
- **1x**: ベースライン（スクロール不要）
- **2x**: 4倍のメモリ（面積が4倍）
- **3x**: 9倍のメモリ（面積が9倍）
- **4x**: 16倍のメモリ（面積が16倍）

### グリッド描画コスト
- **50px間隔**: 低コスト（線の本数が少ない）
- **半透明グレー**: ほぼ影響なし

### スクロール性能
- **ネスト構造**: Flutter標準の最適化が適用される
- **Scrollbar常時表示**: 追加のGPUコストはごくわずか

---

## 🚀 次のステップ（優先度順）

### 1. 実機動作確認 📱
- [ ] Android (SH 54D) でスクロール動作テスト
- [ ] 各キャンバスサイズでの描画テスト
- [ ] グリッド線表示確認
- [ ] スクロールバー表示確認

### 2. パフォーマンス計測 ⚡
- [ ] 大きなキャンバス（4x）での描画パフォーマンス
- [ ] 多数のストローク（100+）での描画速度
- [ ] スクロール時のフレームレート

### 3. UI/UX改善候補 🎨
- [ ] グリッド表示ON/OFFトグル
- [ ] グリッドサイズ変更（25px / 50px / 100px）
- [ ] ズーム機能（ピンチ操作）
- [ ] キャンバス中央へのクイック移動ボタン
- [ ] ミニマップ（現在位置表示）

### 4. 保存機能の拡張 💾
- [ ] スクロール位置の保存
- [ ] キャンバスサイズの保存
- [ ] グリッド設定の保存

---

## 💡 技術的学び

### 1. Scrollbarのネスト構造
**課題**: 縦横2つのScrollbarを同時に使用
**解決**: `notificationPredicate: (notification) => notification.depth == 1`

**理由**:
- 外側のScrollbarが内側のスクロール通知に反応しないようにする
- `depth == 1`で内側のScrollviewのみを処理

### 2. LayoutBuilderの活用
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final canvasWidth = constraints.maxWidth * _canvasScale;
    final canvasHeight = constraints.maxHeight * _canvasScale;
    // ...
  },
)
```

**用途**: 親要素のサイズに基づいてキャンバスサイズを計算

### 3. CustomPaintの重ね合わせ
```dart
Stack(
  children: [
    CustomPaint(painter: GridPainter(...)),        // グリッド
    CustomPaint(painter: DrawingStrokePainter(...)), // ストローク
    Signature(...),                                 // 現在の描画
  ],
)
```

**ポイント**: Stackの順序が描画順序を決定（上に行くほど前面）

### 4. ScrollControllerの責任
- **作成**: StatefulWidgetのフィールドとして宣言
- **使用**: ScrollbarとSingleChildScrollViewに渡す
- **破棄**: dispose()で必ずdispose()を呼ぶ

### 5. IgnorePointerでタッチイベント制御
```dart
IgnorePointer(
  ignoring: !_isScrollLocked, // trueでタッチイベント無視
  child: Signature(...),
)
```

**用途**: 条件に応じて子ウィジェットへのタッチイベントを制御

### 6. Positioned.fillでタッチ領域確保
```dart
Positioned.fill(
  child: Signature(...), // キャンバス全体がタッチ可能に
)
```

**重要性**: Signatureウィジェットは明示的にタッチ領域を確保する必要がある

---

## 🎯 成果

### 機能実装
- ✅ スクロール可能なキャンバス実装
- ✅ キャンバスサイズ選択（1x-4x）
- ✅ グリッド線表示機能
- ✅ スクロールロック機能実装 ⭐
- ✅ ScrollController管理

### コード品質
- ✅ メモリリーク対策（dispose処理）
- ✅ CustomPainter活用
- ✅ LayoutBuilder活用
- ✅ ネストScrollbarの正しい実装
- ✅ IgnorePointerでタッチイベント制御
- ✅ ジェスチャー競合の解決

### ユーザー体験
- ✅ スマホでの描画が可能に
- ✅ 誤操作防止（スクロール時の意図しない描画を防止）
- ✅ 明示的なモード切替（ロックボタン）

### ドキュメント
- ✅ 日報作成
- ✅ アーキテクチャ解説
- ✅ 技術的学び記録

---

## 📌 備考

### 今後の展開候補
1. **ズーム機能**: InteractiveViewerを使用（ピンチ操作）
2. **ミニマップ**: 小さなプレビューで現在位置を表示
3. **自動保存**: 一定間隔でFirestoreに自動保存
4. **共同編集**: リアルタイムで複数人が同時描画

### パフォーマンス注意点
- 4x以上のキャンバスは非推奨（メモリ消費大）
- ストローク数が1000を超えると描画遅延の可能性
- 対策: 古いストロークをまとめて画像化（今後の課題）

---

**作業時間**: 約2.5時間
**ブランチ**: future
**ステータス**: ✅ 実装完了・実機テスト完了（SH 54D）

**検証結果**:
- ✅ スクロール機能: 正常動作
- ✅ スクロールロック: 正常動作（ロック時のみ描画可能）
- ✅ 描画制御: 正常動作（スクロール時は描画不可）
- ✅ タッチ操作: 正常動作（Android実機で確認）

---

## 🔧 午後の追加作業

### 4. ホワイトボード機能バグ修正 ✅

#### 4-1. グループ可視性問題の解決
**問題**: まやユーザーでログイン時、「まや共有」グループが表示されない

**原因**: 
- Crashlytics初期化エラー（Windows版）でアプリバー構築が失敗
- group nullチェックが不十分

**修正内容**:
- `common_app_bar.dart`: グループ nullチェック強化
- `main.dart`: Windows版でCrashlytics無効化
- Firestoreクエリ処理の安定化

**コミット**: 2bae86a

---

#### 4-2. AppBarタイトル表示バグ修正
**問題**: グループ共有ホワイトボード起動時に「個人用ホワイトボード」と表示される

**原因**: Firestoreの`where`クエリがnull値に対応していない

**修正内容**:
- `isPersonal`パラメータに基づく条件分岐を追加
- `where('ownerId', isNull: true)`は非対応のため、クライアント側フィルタリング実装
- nullチェック処理を強化

**コミット**: d6fe034

---

#### 4-3. 他メンバーのホワイトボード閲覧機能実装
**問題**: グループ他メンバーのホワイトボードがダブルタップで表示されない

**修正内容**:
- `member_tile_with_whiteboard.dart`: `isCurrentUser`チェックを削除
- `whiteboard_editor_page.dart`: 閲覧専用モード実装
  - `canEdit`がfalseの場合、ツールバー非表示
  - Signatureウィジェット条件付き表示
  - オレンジ色の「閲覧専用」バー表示
  - 実際のキャンバス内容を表示（ロック画面ではなく）

**コミット**: d6fe034

---

### 5. ホワイトボード更新通知機能実装 ✅

**目的**: ホワイトボード保存時にグループメンバーへ自動通知

**実装内容**:

#### 5-1. NotificationServiceの拡張
```dart
// 新しい通知タイプ追加
enum NotificationType {
  // ... 既存の通知タイプ
  whiteboardUpdated('whiteboard_updated'), // ⚡ NEW
}

// 通知送信メソッド
Future<void> sendWhiteboardUpdateNotification({
  required String groupId,
  required String whiteboardId,
  required bool isGroupWhiteboard,
  String? ownerId,
}) async {
  // グループメンバー全員（編集者以外）に通知送信
  // バッチ処理で効率的に送信
}

// 通知受信ハンドラー
Future<void> _handleWhiteboardUpdated(NotificationData notification) async {
  // whiteboardId、editorName、isGroupWhiteboardをログ出力
  // 将来: プロバイダー無効化でリアルタイム更新
}
```

#### 5-2. ホワイトボードエディターへの統合
```dart
// 保存ボタンタップ時
await repository.updateWhiteboard(updatedWhiteboard);

// 通知送信（エラーがあっても保存は成功扱い）
try {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.sendWhiteboardUpdateNotification(
    groupId: widget.groupId,
    whiteboardId: whiteboardId,
    isGroupWhiteboard: !widget.isPersonal,
    ownerId: widget.isPersonal ? widget.userId : null,
  );
} catch (notificationError) {
  AppLogger.error('📤 通知送信エラー: $notificationError');
}
```

**コミット**: de72177

---

### 6. テストドキュメント更新 ✅

**目的**: ホワイトボード機能・通知システムをテスト手順書に追加

**作成ファイル**:

#### 6-1. test_procedures_v2.md
- バージョン: v2.0（v1.0から大幅拡張）
- 合計29テストプロシージャ（v1.0は15項目）
- 新規セクション:
  - 3.4 ホワイトボード機能テスト（6項目）
  - 3.5 通知システムテスト（3項目）
- 各テストに期待結果チェックボックス付き

#### 6-2. test_checklist_template.md
- 合計41項目の簡易チェックリスト
- 1行でテスト項目を記述
- パフォーマンス測定欄付き
- 問題記録表・合格率計算テーブル付き

**コミット**: 1825466

---

### 7. サインアップ時のユーザー名保存タイミング修正 ✅

**問題**: ディスプレイ名入力後、メールアドレスの前半が使われる

**原因**:
- Firebase Auth登録時に`authStateChanges`発火
- この時点でSharedPreferencesにユーザー名未保存
- `createDefaultGroup()`がデフォルト値（メールアドレス前半）を使用

**修正内容**:
- Firebase Auth登録**前**にPreferencesへユーザー名を保存
- 保存順序の最適化:
  1. SharedPreferences クリア
  2. ✅ ユーザー名・メールアドレスを事前保存（NEW）
  3. Hive クリア
  4. Firebase Auth 新規登録（authStateChanges発火）
  5. Firebase Auth displayName更新
  6. Firestore プロファイル作成

**デバッグログ強化**:
- 入力値の長さ確認
- 空文字チェック追加
- パラメータ追跡ログ追加

**コミット**: e26559f

---

## 📊 本日の成果サマリー

### 実装完了項目
1. ✅ スクロール可能キャンバス（1x～4x）
2. ✅ スクロールロック機能
3. ✅ グリッド線表示
4. ✅ グループ可視性バグ修正
5. ✅ AppBarタイトル表示バグ修正
6. ✅ 他メンバーホワイトボード閲覧機能
7. ✅ ホワイトボード更新通知システム
8. ✅ テストドキュメント作成（v2.0）
9. ✅ ユーザー名保存タイミング修正

### コミット履歴
- `2bae86a` - グループ可視性・Crashlytics修正
- `d6fe034` - AppBarタイトル＋閲覧専用モード実装
- `de72177` - ホワイトボード更新通知機能実装
- `1825466` - テストドキュメント作成
- `e26559f` - ユーザー名保存タイミング修正

### テスト準備完了
- 詳細テスト手順書: 29項目
- 簡易チェックリスト: 41項目
- 複数デバイス対応テストケース完備

---

**総作業時間**: 約7時間
**ブランチ**: future
**ステータス**: ✅ 週間作業完了・クローズドテスト準備完了

**来週の予定**:
- futureブランチの総合テスト実施
- クローズドテスト開始準備
- 必要に応じてバグ修正
