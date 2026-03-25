# 開発日報 - 2026年03月25日

## 📅 本日の目標

- [x] ホワイトボード保存ボタングレーアウト（保存不可）バグの根本解決
- [x] strokes サブコレクション化によるスケーラビリティ改善
- [x] fire-and-forget 保存によるUI遅延ゼロ化
- [x] AppBar タイトルの UX 改善（○○さんのボード）
- [x] 初回読み込みスピナー追加
- [x] 本日の変更をイシューごとにコミット＆プッシュ
- [x] 翌日分テストチェックリスト作成

---

## ✅ 完了した作業

### 1. strokes サブコレクション化 ✅

**Purpose**: arrayUnion の O(n) ボトルネックを除去し、ストローク保存を O(1) にする

**Background**:
ストロークが増えるほど `arrayUnion` の Firestore サーバー側重複チェックが遅くなり、
3〜4 本のストロークで既に保存が 10 秒タイムアウトしていた。
watchdog タイマー（8秒）で `_isSaving=false` にリセットしても保存は完了していないため
ボタンがグレーアウトしたまま残る問題も発生していた。

**Root Cause**:

```
// ❌ 旧実装: 全ストロークを配列に arrayUnion → ストローク数に比例して遅い
await repo.updateWhiteboard(strokes: allStrokes)
// → Firestore サーバー側で全要素の重複チェック → O(n)
```

**Solution**:

```dart
// ✅ 新実装: 各ストロークを個別 doc として batch.set()
// パス: SharedGroups/{groupId}/whiteboards/{wbId}/strokes/{strokeId}
for (final stroke in newStrokes) {
  batch.set(strokesCollection.doc(stroke.strokeId), {
    'strokeId': stroke.strokeId,
    'points': [...],
    'createdAt': Timestamp.fromDate(stroke.createdAt),
    ...
  });
}
await batch.commit(); // O(1) × newStrokes.length
```

**Modified Files**:

- `lib/datastore/whiteboard_repository.dart` — `addStrokesToSubcollection`, `watchStrokesSubcollection`, `clearStrokesSubcollection` 追加
- `firestore.rules` — `/strokes/{strokeId}` サブコレクションのルール追加・デプロイ済み

**Commit**: `3920e10`
**Status**: ✅ 完了・動作確認済み（他端末反映 OK）

---

### 2. fire-and-forget 保存によるUIラグ ゼロ化 ✅

**Purpose**: `await batch.commit()` のサーバーACK待ち（〜10秒）を排除し、保存ボタンを即時復帰させる

**Background**:
サブコレクション化後も `await batch.commit()` がサーバーACKを待つため
1 ストロークでも UIが数秒〜10秒ブロックされていた。
Firestore のオフライン永続化を活用すればローカル書き込みは即時完了する。

**Problem / Root Cause**:

```dart
// ❌ 旧: サーバーACKを await で待つ
await repository.addStrokesToSubcollection(...);
setState(() { _isSaving = false; }); // ← サーバーACKまで到達しない
```

**Solution**:

```dart
// ✅ 新: fire-and-forget（Firestoreオフライン永続化でローカルは即時完了）
unawaited(
  repository.addStrokesToSubcollection(...).catchError((e) {
    if (mounted) SnackBarHelper.showError(context, '保存に失敗しました');
  }),
);
// await なし → 即座にUI解除
setState(() { _isSaving = false; _showSaveSpinner = false; });
```

**修正内容の副次効果**:

- 8秒 watchdog タイマーを削除（不要になった）
- `spinnerReleased` フラグを削除（不要になった）
- `FirebaseException` の個別 catch ブロックを削除（`.catchError()` に統一）
- `addStrokesToSubcollection` の `.timeout(10s)` を削除

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` — `_saveWhiteboard()` を fire-and-forget に書き換え
- `lib/datastore/whiteboard_repository.dart` — `.timeout()` 削除

**Commit**: `3920e10`
**Status**: ✅ 完了・動作確認済み

---

### 3. `watchStrokesSubcollection` の無音エラー問題修正 ✅

**Purpose**: strokes Stream が無音でエラー終了しストロークが表示されない問題を修正

**Problem / Root Cause**:

```dart
// ❌ 旧: .orderBy('createdAt') はインデックス未作成時に FAILED_PRECONDITION で死ぬ
// ❌ .where(!hasPendingWrites) は fire-and-forget の pending write を全部弾く
// ❌ .listen() に onError なし → エラーが無音で消える
return collection.orderBy('createdAt').snapshots()
    .where((s) => !s.metadata.hasPendingWrites)
    .map(...);
```

**Solution**:

```dart
// ✅ orderBy 廃止 → クライアントソートに変更
// ✅ hasPendingWrites フィルター廃止
// ✅ handleError + onError + cancelOnError: false で継続
return collection.snapshots()
    .handleError((e, stack) { AppLogger.error(...); })
    .map((snapshot) {
      return snapshot.docs.map(...).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
// listen 側
.listen(
  (strokes) { ... },
  onError: (e, stack) { AppLogger.error(...); },
  cancelOnError: false,
);
```

**Modified Files**:

- `lib/datastore/whiteboard_repository.dart`
- `lib/pages/whiteboard_editor_page.dart`

**Commit**: `3920e10`
**Status**: ✅ 完了・動作確認済み（閉じて開くと保存内容が復元されることを確認）

---

### 4. UX改善 — AppBar タイトル・初回読み込みスピナー ✅

**Purpose**: ホワイトボード画面の視認性と操作フィードバックを改善する

#### 4-1. AppBar タイトル変更

**変更前**: `個人用ホワイトボード`（誰のボードか不明）
**変更後**: `○○さんのボード`（所有者名を明示）

```dart
// WhiteboardEditorPage に ownerName パラメータ追加
final String? ownerName;

// AppBar タイトル
title: Text(
  _currentWhiteboard.isGroupWhiteboard
      ? 'グループ共通ホワイトボード'
      : widget.ownerName != null
          ? '${widget.ownerName}さんのボード'
          : '個人ボード',
),
```

#### 4-2. 初回読み込みスピナー

```dart
// _isLoadingStrokes フラグで制御
bool _isLoadingStrokes = true;

// 最初のスナップショット受信時に解除
if (mounted && _isLoadingStrokes) {
  setState(() { _isLoadingStrokes = false; });
}

// UI: ツールバーとキャンバスの間に表示
if (_isLoadingStrokes) const LinearProgressIndicator(minHeight: 2),
```

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart`
- `lib/widgets/member_tile_with_whiteboard.dart` — `ownerName: member.name` を追加

**Commit**: `0f798c1`
**Status**: ✅ 完了

---

### 5. whiteboard.dart `canEdit` 修正 ✅

**Purpose**: グループ共通ボードでもオーナー判定が機能するよう修正

**変更前**:

```dart
bool canEdit(String userId) {
  return isPersonalWhiteboard && ownerId == userId; // グループ共通は常に false
}
```

**変更後**:

```dart
bool canEdit(String userId) {
  return ownerId == userId; // isPersonalWhiteboard 条件を削除
}
```

**Modified Files**:

- `lib/models/whiteboard.dart`

**Commit**: `3920e10`
**Status**: ✅ 完了

---

### 6. ニュース表示修正・タイムアウト延長 ✅

**Purpose**: ホーム画面のニュース表示を正しいプロバイダーに統一し、タイムアウト起因のエラーを減らす

**変更前**:

```dart
final newsAsync = ref.watch(newsStreamProvider); // 旧プロバイダー
```

**変更後**:

```dart
final newsAsync = ref.watch(currentNewsProvider); // 統一
```

タイムアウト: 10秒 → 30秒に延長

**Modified Files**:

- `lib/widgets/news_widget.dart`
- `lib/services/firestore_news_service.dart`

**Commit**: `b3e1234`
**Status**: ✅ 完了

---

## 🐛 発見された問題

### `.listen()` に `onError` なしで Stream が無音終了（修正済み ✅）

- **症状**: `watchStrokesSubcollection` のリスナーがエラーで静かに死に、ストロークが表示されない
- **原因**: `.orderBy('createdAt')` が Firestore インデックス未作成時に `FAILED_PRECONDITION` を投げるが `onError` がないため無音で終了
- **対処**: `orderBy` をクライアントソートに変更、`handleError`・`onError`・`cancelOnError: false` を追加
- **状態**: 修正完了

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ ホワイトボード保存ボタングレーアウト（2026-03-25）
2. ✅ ストロークが増えると保存が遅い（arrayUnion → サブコレクション化、2026-03-25）
3. ✅ fire-and-forget 保存後に閉じると保存されない（hasPendingWritesフィルター削除、2026-03-25）
4. ✅ strokes Stream が無音エラー終了（orderBy + onError 修正、2026-03-25）

### 翌日継続 ⏳

- ⏳ strokes 読み込み遅延（Firestore ネットワーク遅延起因・当面許容）
- ⏳ iOS ホワイトボード描画テスト（端末未確保）

---

## 💡 技術的学習事項

### fire-and-forget と Firestore オフライン永続化

**問題パターン**:

```dart
// await batch.commit() は必ずサーバーACKを待つ
// → ネットワーク遅延分（数秒〜10秒）UIがブロックされる
await batch.commit();
setState(() { _isSaving = false; }); // ← 遅延する
```

**正しいパターン**:

```dart
// Firestoreオフライン永続化が有効な場合、ローカルへの書き込みは即時完了する
// unawaited でサーバーACKを待たずにUIを解除できる
unawaited(batch.commit().catchError((e) { /* エラーハンドリング */ }));
setState(() { _isSaving = false; }); // ← 即時
```

**教訓**: `await batch.commit()` はサーバーACK待ちである。モバイルアプリでUIをブロックさせないためには fire-and-forget + catchError パターンを使う。

---

### Stream の `onError` 省略は致命的

**問題パターン**:

```dart
stream.listen((data) { /* データ処理 */ });
// onError なし → エラーが投げられると StreamSubscription が無音終了
```

**正しいパターン**:

```dart
stream.listen(
  (data) { /* データ処理 */ },
  onError: (e, stack) { AppLogger.error('エラー: $e'); },
  cancelOnError: false, // エラーが起きてもリスナーを継続
);
```

**教訓**: Firestore の Stream は `FAILED_PRECONDITION`（インデックス未作成）等のエラーを投げることがある。`onError` なしでは無音終了してデバッグが困難になる。

---

## 🗓 翌日（2026-03-26）の予定

1. 翌日分テストチェックリスト（`device_test_checklist_20260326.md`）を実施
2. strokes 読み込み遅延の改善検討（必要に応じて）
3. iOS テスト環境確保検討

---

## 📝 ドキュメント更新

| ドキュメント                                                   | 更新内容                                                                               |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `instructions/30_whiteboard.md`                                | サブコレクション化・fire-and-forget・hasPendingWritesフィルター廃止・canEdit修正を反映 |
| `docs/daily_reports/2026-03/device_test_checklist_20260326.md` | 翌日分テストチェックリストを本日の仕様変更を盛り込んで新規作成                         |
