# 開発日報 - 2026年03月26日

## 📅 本日の目標

- [x] ホワイトボード全消去が他端末へ反映されない不具合の根本修正
- [x] 一時的なネット障害後、再入時に保存ボタンが効かない不具合の根本修正
- [x] 翌日用の実機テストチェックリストを更新
- [x] 日報と関連ドキュメントを更新してコミット・プッシュ

---

## ✅ 完了した作業

### 1. 全消去後に他端末で旧描画が復活する問題の修正 ✅

**Purpose**: ホワイトボード全消去後に他端末でも確実に空状態が反映されるようにする

**Background**:
描画追加は他端末に同期される一方で、全消去だけは他端末側に残存する症状があった。
Firestore 側ではストロークサブコレクションが空になっているのに、受信側 UI が旧描画を再構成していた。

**Problem / Root Cause**:

```dart
// ❌ Firestoreにないローカルstrokeを無条件に残していた
for (final entry in localMap.entries) {
  if (!firestoreMap.containsKey(entry.key)) {
    mergedMap[entry.key] = entry.value;
  }
}
```

全消去後は Firestore が空配列を返すため、他端末のローカル保存済み stroke まで
「未保存」と同じように再マージされ、旧描画が復活していた。

**Solution**:

```dart
// ✅ 未保存strokeIdに含まれるローカルstrokeだけを保持
final unsavedLocalMap = {
  for (final entry in localMap.entries)
    if (_unsavedStrokeIds.contains(entry.key)) entry.key: entry.value,
};

for (final entry in unsavedLocalMap.entries) {
  if (!firestoreMap.containsKey(entry.key)) {
    mergedMap[entry.key] = entry.value;
  }
}
```

**検証結果**:

| テスト | 結果 |
|---|---|
| ユーザー報告 | 全消去の他端末反映が改善した |
| 静的エラーチェック | 問題なし |

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` - Firestore 受信マージ処理を修正

**Commit**: `832e39e`
**Status**: ✅ 完了・ユーザー確認済み

---

### 2. ネット障害後の再入で保存ボタンが効かない問題の修正 ✅

**Purpose**: 保存失敗後にネット回復して再入した場合でも、残っている描画を再送できるようにする

**Background**:
すもも端末で一時的なネット障害中に保存失敗した後、編集画面を閉じて再入すると描画自体は残るが、
保存ボタンを押しても保存対象が 0 件になり再送されなかった。

**Problem / Root Cause**:

```dart
// ❌ 再入時はキャッシュ済み描画だけ復元し、未保存strokeIdは空のまま
if (_currentWhiteboard.strokes.isNotEmpty) {
  _workingStrokes.addAll(_currentWhiteboard.strokes);
  _unsavedStrokeIds.clear();
}
```

個人用ホワイトボードでは再入時にキャッシュの描画は表示されるが、
未保存 strokeId を別管理していなかったため、保存ボタン側では
`newStrokes.isEmpty` になっていた。

**Solution**:

```dart
// ✅ 個人用ボードは未保存strokeIdも別キャッシュする
PersonalWhiteboardCacheService.savePendingStrokeIds(
  cacheKey,
  _unsavedStrokeIds,
);

final pendingStrokeIds =
    await PersonalWhiteboardCacheService.loadPendingStrokeIds(cacheKey);
_unsavedStrokeIds.addAll(
  _workingStrokes
      .where((stroke) => pendingStrokeIds.contains(stroke.strokeId))
      .map((stroke) => stroke.strokeId),
);
```

さらに、ペンアップ・モード切替・Undo/Redo・画面離脱前にも draft キャッシュを同期し、
再入時の取りこぼしを防止した。

**検証結果**:

| テスト | 結果 |
|---|---|
| ユーザー報告 | 再入後の保存が動作することを確認済み |
| 静的エラーチェック | 問題なし |

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` - 未保存 strokeId の復元・キャッシュ同期追加
- `lib/services/personal_whiteboard_cache_service.dart` - pending strokeId の保存・読込 API を追加

**Commit**: `832e39e`
**Status**: ✅ 完了・ユーザー確認済み

---

### 3. 翌日用実機テストチェックリストの更新 ✅

**Purpose**: 2026-03-27 に実施する実機検証で、今回の修正ポイントを漏れなく確認できるようにする

**Background**:
2026-03-26 の実機テストは当日未実施だったため、翌日用にチェックリストを更新する必要があった。

**Solution**:

```md
- 全消去の他端末反映修正
- 一時的ネット障害後の再入保存修正
- 消去後の旧描画再表示なし
- ネット回復後の再入で保存ボタン再送可能
```

20260326 版を 20260327 版へ差し替え、翌日の重点確認項目として追記した。

**Modified Files**:

- `docs/daily_reports/2026-03/device_test_checklist_20260327.md` - 翌日用チェックリストを作成・更新
- `docs/daily_reports/2026-03/device_test_checklist_20260326.md` - 旧版を削除

**Status**: ✅ 完了

---

## 🐛 発見された問題

### 全消去後に他端末で旧描画が復活する問題 ✅

- **症状**: 端末 A の全消去が端末 B に反映されず、旧描画が残る
- **原因**: Firestore にないローカル stroke を無条件に再マージしていた
- **対処**: 未保存 strokeId に含まれるローカル stroke のみ保持するよう修正
- **状態**: 修正完了

### ネット障害後の再入で保存ボタンが効かない問題 ✅

- **症状**: 描画は残るが、再入後に保存ボタンを押しても保存対象が 0 件になる
- **原因**: 未保存 strokeId がキャッシュされず、再入時に復元されていなかった
- **対処**: 個人用ボードの pending strokeId キャッシュを追加し、再入時に復元
- **状態**: 修正完了

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ ホワイトボード全消去の他端末未反映（完了日: 2026-03-26）
2. ✅ ネット障害後の再入で保存ボタンが効かない（完了日: 2026-03-26）

### 対応中 🔄

1. 🔄 実機総合テストの再実施（Priority: High）

### 未着手 ⏳

1. ⏳ iOS ホワイトボード描画確認（Priority: Medium）

### 翌日継続 ⏳

- ⏳ 2026-03-27 実機チェックリストの消化

---

## 💡 技術的学習事項

### Firestore 空スナップショットとローカル下書きの扱い

**問題パターン**:

```dart
// Firestoreに存在しないローカルstrokeを全部残す
for (final entry in localMap.entries) {
  if (!firestoreMap.containsKey(entry.key)) {
    mergedMap[entry.key] = entry.value;
  }
}
```

**正しいパターン**:

```dart
// 未保存strokeIdに入っているローカルstrokeだけ残す
for (final entry in localMap.entries) {
  if (_unsavedStrokeIds.contains(entry.key) &&
      !firestoreMap.containsKey(entry.key)) {
    mergedMap[entry.key] = entry.value;
  }
}
```

**教訓**: Firestore が空を返したときは「全削除が正しく同期された」ケースと「ローカル未保存が残っている」ケースを分けて扱う必要がある。

### 再入復元時は表示データだけでなく保存対象の状態も持ち越す

**問題パターン**:

```dart
_workingStrokes.addAll(cachedWhiteboard.strokes);
_unsavedStrokeIds.clear();
```

**正しいパターン**:

```dart
await PersonalWhiteboardCacheService.savePendingStrokeIds(
  cacheKey,
  _unsavedStrokeIds,
);
final pendingStrokeIds =
    await PersonalWhiteboardCacheService.loadPendingStrokeIds(cacheKey);
```

**教訓**: キャッシュで表示だけ復元しても、保存対象メタデータを失うと再送不能になる。UI 状態と保存状態はセットで保持する。

---

## 🗓 翌日（2026-03-27）の予定

1. 20260327 実機テストチェックリストの重点項目を実施
2. 全消去同期とネット回復後再入保存を 2 端末以上で再確認
3. 未確認の回帰項目を消化し、必要なら追加入力ログを検討

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `docs/daily_reports/2026-03/daily_report_20260326.md` | 2026-03-26 の作業内容と学習事項を記録 |
| `docs/daily_reports/2026-03/device_test_checklist_20260327.md` | 翌日用チェックリストへ更新し、全消去同期と再入保存の検証項目を追加 |
| `instructions/30_whiteboard.md` | 全消去時のマージ条件と、個人用ボードの pending strokeId 復元ルールを追記 |