# ホワイトボード ストローク保存処理フロー

**作成日**: 2026-02-04
**対象**: Windows版ホワイトボード描画システム

## 概要

Windows版ホワイトボードにおけるストローク（描画線）の保存処理フローを詳細に記録。
問題：描画モード切り替え時にストロークが繋がる現象の調査用。

---

## 🎨 データ構造

### SignatureController (signature パッケージ)

- **役割**: ユーザーのタッチ/マウス入力を受け取り、描画を管理
- **保持データ**: `List<Point>` - 連続した点のリスト
- **特徴**: すべての点が単一リストで管理される（ストローク分割なし）

### DrawingStroke (カスタムモデル)

```dart
@HiveType(typeId: 15)
@freezed
class DrawingStroke {
  strokeId: String          // UUID v4（一意識別子）
  points: List<DrawingPoint> // ストローク内の点リスト
  colorValue: int           // 色（Color.value）
  strokeWidth: double       // 線幅
  createdAt: DateTime       // 作成日時
  authorId: String          // 作成者UID
  authorName: String        // 作成者名
}
```

### State管理

- `_workingStrokes: List<DrawingStroke>` - 現在編集中のストロークリスト
- `_controller: SignatureController?` - 現在の描画セッション
- `_history: List<List<DrawingStroke>>` - Undo/Redo履歴
- `_historyIndex: int` - 現在の履歴位置

---

## 📊 処理フロー全体像

```
[ユーザー描画]
    ↓
[SignatureController.points に蓄積]
    ↓
[モード切り替え or 保存ボタン]
    ↓
[_captureCurrentDrawing()] ← 🔥 重要ポイント1
    ↓
[DrawingConverter.captureFromSignatureController()] ← 🔥 重要ポイント2
    ↓
[DrawingStroke生成（距離ベース分割）]
    ↓
[_workingStrokes.addAll(strokes)]
    ↓
[_controller?.clear()] ← 🔥 重要ポイント3 (2026-02-04追加)
    ↓
[_saveToHistory()]
    ↓
[保存ボタン押下時のみ] → [_saveWhiteboard()]
    ↓
[FirestoreSharedListRepository.addStrokesToWhiteboard()]
```

---

## 🔍 詳細処理フロー

### 1. 描画開始（initState）

```dart
// whiteboard_editor_page.dart (initState)
_controller = SignatureController(
  penStrokeWidth: _strokeWidth,
  penColor: _selectedColor,
);

// 既存ストロークを作業リストに復元
if (_currentWhiteboard.strokes.isNotEmpty) {
  _workingStrokes.addAll(_currentWhiteboard.strokes);
}

// 初期状態を履歴に保存
_saveToHistory(); // _history[0] = 既存ストロークのコピー
```

**初期状態**:

- `_workingStrokes`: Firestoreから読み込んだ既存ストローク
- `_controller.points`: 空リスト
- `_history`: [[既存ストローク]]
- `_historyIndex`: 0

---

### 2. ユーザーが描画

```dart
// signature パッケージが自動処理
Signature(
  controller: _controller,
  backgroundColor: Colors.transparent,
)
```

**描画中の状態**:

- `_controller.points`: タッチ座標が連続して追加される
  - 例: `[Point(100, 200), Point(101, 201), Point(102, 202), ...]`
- `_workingStrokes`: 変化なし（まだキャプチャしていない）

---

### 3. モード切り替え（描画 → スクロール）

#### 3-1. ボタン押下

```dart
// whiteboard_editor_page.dart (_buildToolbar)
IconButton(
  icon: Icon(_isScrollLocked ? Icons.brush : Icons.open_with),
  onPressed: () async {
    // Windows版の場合
    if (Platform.isWindows) {
      // 1. 状態切り替え
      setState(() {
        _isScrollLocked = !_isScrollLocked;
      });

      // 2. 描画データキャプチャ
      if (!_isScrollLocked) { // 描画モード終了時
        try {
          _captureCurrentDrawing(); // 🔥 ここで呼ばれる
        } catch (e) {
          AppLogger.error('❌ [MODE_TOGGLE] 描画キャプチャエラー: $e');
        }
      }
    }
  },
)
```

#### 3-2. \_captureCurrentDrawing()

```dart
void _captureCurrentDrawing() {
  if (_controller == null || _controller!.isEmpty) {
    return; // 何も描かれていなければスキップ
  }

  final currentUser = ref.read(authStateProvider).value;
  if (currentUser == null) return;

  try {
    // 🔥 重要: SignatureController → DrawingStroke変換
    final strokes = DrawingConverter.captureFromSignatureController(
      controller: _controller!,
      authorId: currentUser.uid,
      authorName: currentUser.displayName ?? 'Unknown',
      strokeColor: _selectedColor,
      strokeWidth: _strokeWidth,
      scale: _canvasScale,
    );

    // 作業リストに追加
    if (strokes.isNotEmpty) {
      _workingStrokes.addAll(strokes);
      AppLogger.info('📸 [WHITEBOARD] ${strokes.length}個のストロークをキャプチャ');

      // 履歴に保存
      _saveToHistory();

      // 🔥 2026-02-04追加: SignatureControllerをクリア
      _controller?.clear();
      AppLogger.info('🧹 [WHITEBOARD] SignatureControllerクリア完了');
    }
  } catch (e) {
    AppLogger.error('❌ [WHITEBOARD] 描画キャプチャエラー: $e');
  }
}
```

**キャプチャ後の状態**:

- `_controller.points`: **空リスト**（clear()実行済み）← 🔥 2026-02-04修正
- `_workingStrokes`: 既存 + 新規キャプチャしたストローク
- `_history`: [..., [既存+新規]]

---

### 4. DrawingConverter.captureFromSignatureController()

```dart
// utils/drawing_converter.dart
static List<DrawingStroke> captureFromSignatureController({
  required SignatureController controller,
  required String authorId,
  required String authorName,
  required Color strokeColor,
  required double strokeWidth,
  double scale = 1.0,
}) {
  try {
    final points = controller.points; // SignatureControllerから点を取得
    if (points.isEmpty) return [];

    // 🔥 ストローク分割ロジック（距離ベース）
    const double breakThreshold = 200.0; // 200px以上離れていたら別ストローク

    final List<DrawingStroke> strokes = [];
    List<DrawingPoint> currentStrokePoints = [];

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      if (currentStrokePoints.isNotEmpty) {
        // 前の点との距離を計算
        final prevPoint = points[i - 1];
        final distance = (point.offset - prevPoint.offset).distance;

        // 距離が200px超えたら別ストローク
        if (distance > breakThreshold) {
          // 現在のストロークを保存
          strokes.add(DrawingStroke(
            strokeId: _uuid.v4(), // 新しいUUID
            points: currentStrokePoints,
            colorValue: strokeColor.value,
            strokeWidth: strokeWidth,
            createdAt: DateTime.now(),
            authorId: authorId,
            authorName: authorName,
          ));
          // 新しいストローク開始
          currentStrokePoints = [];
        }
      }

      // スケーリング前の座標に変換
      currentStrokePoints.add(DrawingPoint(
        x: point.offset.dx / scale,
        y: point.offset.dy / scale,
      ));
    }

    // 最後のストロークを追加
    if (currentStrokePoints.isNotEmpty) {
      strokes.add(DrawingStroke(
        strokeId: _uuid.v4(),
        points: currentStrokePoints,
        colorValue: strokeColor.value,
        strokeWidth: strokeWidth,
        createdAt: DateTime.now(),
        authorId: authorId,
        authorName: authorName,
      ));
    }

    return strokes;
  } catch (e, stackTrace) {
    print('❌ [DRAWING_CONVERTER] エラー: $e');
    return [];
  }
}
```

**ストローク分割の動作**:

```
入力: [Point(0,0), Point(1,1), Point(2,2), Point(250,250), Point(251,251)]
            ↓
分割判定:
  - Point(0,0) → Point(1,1): distance = 1.4 < 200 → 同じストローク
  - Point(1,1) → Point(2,2): distance = 1.4 < 200 → 同じストローク
  - Point(2,2) → Point(250,250): distance = 350 > 200 → 🔥 ストローク分割！
  - Point(250,250) → Point(251,251): distance = 1.4 < 200 → 新しいストローク
            ↓
出力: [
  DrawingStroke(strokeId: uuid1, points: [0,0 / 1,1 / 2,2]),
  DrawingStroke(strokeId: uuid2, points: [250,250 / 251,251])
]
```

---

### 5. 次回描画開始時（スクロール → 描画）

```dart
// モード切り替えボタン押下（スクロール → 描画）
if (!_isScrollLocked) { // スクロールモード中
  AppLogger.info('🔒 [MODE_TOGGLE] 描画モード開始');
}

setState(() {
  _isScrollLocked = !_isScrollLocked; // 描画モードに変更
});
```

**次回描画の状態**:

- `_controller.points`: **空リスト**（前回clear()済み） ← 🔥 2026-02-04修正
- `_workingStrokes`: 前回までのストロークを保持
- ユーザーが新しく描画を開始 → `_controller.points`に新しい点が追加される

**問題が発生する場合の原因**:

- `_controller.points`が空でない場合、次回描画時に前回の最終点と新しい点が繋がる
- `captureFromSignatureController()`は`controller.points`のすべての点を処理する
- 前回の点が残っていると、距離判定で「前回最終点 → 新規1点目」の距離が計算される

---

### 6. 保存ボタン押下時

```dart
// whiteboard_editor_page.dart (_saveWhiteboard)
Future<void> _saveWhiteboard() async {
  if (_isSaving) return;

  setState(() => _isSaving = true);

  try {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) throw Exception('ユーザーが認証されていません');

    // 🔥 現在の描画をキャプチャ
    final currentStrokes = DrawingConverter.captureFromSignatureController(
      controller: _controller!,
      authorId: currentUser.uid,
      authorName: currentUser.displayName ?? 'Unknown',
      strokeColor: _selectedColor,
      strokeWidth: _strokeWidth,
      scale: _canvasScale,
    );

    // 🔥 新しいストローク = 作業中ストローク + 現在の描画
    final newStrokes = [..._workingStrokes, ...currentStrokes];

    if (newStrokes.isEmpty) {
      AppLogger.info('📋 [SAVE] 新しいストロークなし、保存をスキップ');
      setState(() => _isSaving = false);
      return;
    }

    // 🔥 Firestoreに保存
    await repository.addStrokesToWhiteboard(
      groupId: widget.groupId,
      whiteboardId: _currentWhiteboard.whiteboardId,
      newStrokes: newStrokes,
    );

    // 保存成功後の処理
    _workingStrokes.clear();
    _workingStrokes.addAll(newStrokes);
    _saveToHistory();
    _controller?.clear();

    setState(() {});
  } catch (e, stackTrace) {
    AppLogger.error('❌ ホワイトボード保存エラー: $e');
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}
```

---

## 🐛 問題の原因分析

### 問題: モード切り替え後にストロークが繋がる

#### 発生条件

1. 描画モードで線を描く
2. スクロールモードに切り替える
3. 再び描画モードに戻る
4. 新しい線を描く → **前の線と繋がる**

#### 原因の候補（2026-02-04時点）

**候補1: SignatureController.clear()のタイミング問題** ✅ 修正済み

```dart
// 修正前
_captureCurrentDrawing(); // キャプチャのみ
// _controller.points に前回の点が残る

// 修正後（2026-02-04）
_captureCurrentDrawing(); // キャプチャ + clear()内蔵
// _controller.points が空になる
```

**候補2: 距離ベース分割の閾値問題**

- 現在の閾値: 200px
- 問題: モード切り替え時にclear()が実行されない場合、前回最終点と新規1点目の距離が200px以下だと同一ストロークと判定される
- 解決策: clear()を確実に実行すれば、この問題は発生しない

**候補3: 複数箇所でのcaptureFromSignatureController()呼び出し**

- `_captureCurrentDrawing()`: モード切り替え時
- `_saveWhiteboard()`: 保存ボタン押下時
- 両方で`controller.points`を読み取る
- もし`_captureCurrentDrawing()`でclearし忘れると、`_saveWhiteboard()`で再度同じ点を読み取る可能性

**候補4: SignatureControllerの再作成タイミング**

```dart
// 色・線幅変更時にSignatureControllerを再作成
void _buildColorButton(Color color) {
  onPressed: () {
    _captureCurrentDrawing(); // 現在の描画を保存

    setState(() {
      _selectedColor = color;
      _controller?.dispose();
      _controller = SignatureController(
        penStrokeWidth: _strokeWidth,
        penColor: _selectedColor,
      );
      _controllerKey++;
    });
  }
}
```

- 色変更時は新しいコントローラーが作成されるため、点は繋がらない
- モード切り替え時はコントローラーを再作成しない（パフォーマンス最適化）
- → clear()だけで十分なはず

---

## 🔧 修正履歴

### 2026-02-04: SignatureController.clear()追加

**修正箇所**: `whiteboard_editor_page.dart` `_captureCurrentDrawing()`

```dart
// 修正内容
if (strokes.isNotEmpty) {
  _workingStrokes.addAll(strokes);
  _saveToHistory();

  // 🔥 追加: キャプチャ後はSignatureControllerをクリア
  _controller?.clear();
  AppLogger.info('🧹 [WHITEBOARD] SignatureControllerクリア完了');
}
```

**期待される効果**:

- モード切り替え時に`_captureCurrentDrawing()`が呼ばれると、自動的に`clear()`が実行される
- 次回描画開始時に`_controller.points`が空であることが保証される
- 前回の点と新規の点が繋がることがなくなる

**検証方法**:

1. Windows版アプリを起動
2. 描画モードで緑の線を描く
3. スクロールモードに切り替える
4. 描画モードに戻る
5. 新しい緑の線を描く
6. → **前の線と繋がらないことを確認**

---

## 🔍 追加調査が必要な点

### 1. clear()が確実に実行されているか？

**確認方法**:

```dart
void _captureCurrentDrawing() {
  // ...

  if (strokes.isNotEmpty) {
    _workingStrokes.addAll(strokes);
    _saveToHistory();

    // 🔥 デバッグログ追加
    AppLogger.info('🧹 [BEFORE_CLEAR] controller.points.length = ${_controller?.points.length ?? 0}');
    _controller?.clear();
    AppLogger.info('🧹 [AFTER_CLEAR] controller.points.length = ${_controller?.points.length ?? 0}');
  }
}
```

**期待されるログ**:

```
📸 [WHITEBOARD] 1個のストロークをキャプチャ
🧹 [BEFORE_CLEAR] controller.points.length = 50
🧹 [AFTER_CLEAR] controller.points.length = 0
```

---

### 2. 距離ベース分割の動作確認

**現在の閾値**: 200px

**問題のシナリオ**:

- ユーザーが200px以内の近い位置で複数回描画を開始
- 距離判定で同一ストロークと誤認される可能性

**解決策の候補**:

1. **ペンアップ検出を実装**（推奨）
   - SignatureControllerの`onDrawEnd`コールバックを利用
   - ペンを離した時点で明示的にストロークを終了
   - 距離ベース分割を補助的に使用

2. **閾値を調整**
   - 200px → 100px に引き下げ
   - ただし、高速タッチで点が飛ぶと誤分割の可能性

3. **時間ベース分割を追加**
   - 点間の時間差が1秒以上なら別ストロークと判定
   - 距離ベースと併用

---

### 3. 複数呼び出しの重複キャプチャ

**問題**:

- `_captureCurrentDrawing()`でキャプチャ＋clear()
- 直後に`_saveWhiteboard()`を呼ぶと、`controller.points`が空のはず
- しかし、何らかの理由で再度点が追加される可能性

**検証方法**:

```dart
// _saveWhiteboard()の冒頭でログ追加
AppLogger.info('💾 [SAVE_START] controller.points.length = ${_controller?.points.length ?? 0}');
```

**期待される値**:

- モード切り替え後すぐに保存: `controller.points.length = 0`
- 描画後に保存: `controller.points.length > 0`

---

## 📝 推奨される次のアクション

1. **デバッグログ追加**
   - `_captureCurrentDrawing()` の前後で `controller.points.length` を記録
   - モード切り替えボタン押下時のログ強化

2. **ペンアップ検出の実装検討**
   - SignatureControllerの`onDrawEnd`を利用
   - ペンを離した瞬間にストロークを確定

3. **ストローク分割ロジックの見直し**
   - 距離ベース（200px）+ 時間ベース（1秒）の併用
   - または、ペンアップ検出に完全移行

4. **実機テスト**
   - Windows版で再現テスト
   - Android版でも同様の問題が発生するか確認

---

## 🎯 まとめ

### 現在の実装（2026-02-04）

**ストローク保存の流れ**:

```
ユーザー描画 → SignatureController.points に蓄積
↓
モード切り替え → _captureCurrentDrawing()
↓
DrawingConverter.captureFromSignatureController()
↓
距離ベース分割（200px閾値）→ DrawingStroke生成
↓
_workingStrokes.addAll(strokes)
↓
_controller?.clear() ← 🔥 2026-02-04追加
↓
_saveToHistory()
```

**修正のポイント**:

- `_captureCurrentDrawing()`の最後で必ず`clear()`を実行
- これにより次回描画時に前回の点が残らない

**まだ問題が発生する場合の原因候補**:

1. 距離ベース分割の閾値（200px）が不適切
2. ペンアップが検出されていない（時間差なく連続描画）
3. SignatureControllerの内部状態が正しくクリアされていない
4. 複数箇所での`captureFromSignatureController()`呼び出しによる重複

**次の検証ステップ**:

- デバッグログを追加して実際の動作を確認
- ペンアップ検出の実装を検討
- 閾値の調整または分割ロジックの変更
