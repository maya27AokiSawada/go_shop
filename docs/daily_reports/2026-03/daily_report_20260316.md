# 開発日報 - 2026年03月16日

## 📅 本日の目標

- [x] 共有ホワイトボード保存時にスピナーが戻らない問題を解消する
- [x] 個人用ホワイトボード保存時に残っていたスピナー問題と UI 劣化を解消する
- [x] ホワイトボードプレビューとユーザー切替まわりの Android / Windows 実機回帰を確認する
- [x] 本日分の実機テストチェックリストを作成し、確認結果を反映する
- [ ] ネットワーク監視バナーの誤検知を修正する
- [ ] iOS ホワイトボード描画連続性を確認する

---

## ✅ 完了した作業

### 1. ホワイトボード保存スピナー復帰不良を修正 ✅

**Purpose**: 共有ホワイトボード保存後にスピナーが戻らず、操作が完了したように見えない問題を解消する。

**Background**: SH-54D 実機確認で、共有ホワイトボードの保存自体は成功しているのに、保存ボタン押下後のスピナーが復帰しない現象があった。

**Problem / Root Cause**:

保存処理の write-only 経路で `runTransaction()` を使っており、端末や回線状態によってサーバー応答待ちが長引き、UI 側の保存完了復帰が遅延していた。

```dart
// ❌ Before
await _firestore.runTransaction((transaction) async {
  final snapshot = await transaction.get(docRef);
  // ... currentStrokes merge ...
  transaction.update(docRef, updateData);
});
```

**Solution**:

ホワイトボード保存は差分追加の `get + update` に統一し、保存成功後の通知送信は UI の復帰をブロックしないよう非同期化した。

```dart
// ✅ After
await _addStrokesWithoutTransaction(
  groupId: groupId,
  whiteboardId: whiteboardId,
  newStrokes: newStrokes,
);

unawaited(
  notificationService.sendWhiteboardUpdateNotification(
    groupId: widget.groupId,
    whiteboardId: _currentWhiteboard.whiteboardId,
    isGroupWhiteboard: _currentWhiteboard.isGroupWhiteboard,
    ownerId: _currentWhiteboard.ownerId,
  ),
);
```

**検証結果**:

| テスト                                              | 結果 |
| --------------------------------------------------- | ---- |
| SH-54D で共有ホワイトボード保存後にスピナーが消える | PASS |
| 保存後に他端末プレビュー / 編集画面が維持される     | PASS |
| Windows / Android 間で描画反映が継続する            | PASS |

**Modified Files**:

- `lib/datastore/whiteboard_repository.dart` - ホワイトボード保存を `runTransaction()` 依存から通常の `get + update` に統一
- `lib/pages/whiteboard_editor_page.dart` - 保存後の通知送信を非同期化し、保存復帰をブロックしないよう変更

**Commit**: `0d18c29`
**Status**: ✅ 完了・実機確認済み

---

### 2. 個人用ホワイトボード保存直後の自己反映による UI 劣化を修正 ✅

**Purpose**: 個人用ホワイトボード保存後にスピナーが残ったり、その後 UI 反応が悪くなる問題を解消する。

**Background**: 共有ホワイトボードのスピナー問題は解消したが、個人用ホワイトボードでは保存直後の体感がまだ悪く、スピナー残留と UI 劣化が報告された。

**Problem / Root Cause**:

個人用ホワイトボードには共有ボードのような編集ロックによる自己反映抑止がないため、自分の保存直後に Firestore listener が同じ内容を再度取り込み、履歴保存と再描画を二重に走らせていた。

```dart
// ❌ Before
if (!mounted || latest == null) return;

if (_hasEditLock) return;

setState(() {
  _currentWhiteboard = latest;
  _mergeStrokesFromFirestore(latest.strokes);
  _saveToHistory();
});
```

**Solution**:

個人用ホワイトボード保存直後の自己反映スナップショットを 1 回だけスキップするフラグを追加し、Firestore 保存完了直後に `_isSaving` を先に `false` へ戻すよう変更した。

```dart
// ✅ After
if (_suppressNextPersonalSnapshot &&
    _currentWhiteboard.isPersonalWhiteboard) {
  _suppressNextPersonalSnapshot = false;
  _currentWhiteboard = latest;
  return;
}

if (mounted) {
  setState(() => _isSaving = false);
  spinnerReleased = true;
}
```

**検証結果**:

| テスト                                           | 結果 |
| ------------------------------------------------ | ---- |
| 個人用ホワイトボードで保存後にスピナーが残らない | PASS |
| 保存後に UI の反応低下が発生しない               | PASS |
| 個人用ホワイトボードを開いて通常保存できる       | PASS |

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` - 個人用ホワイトボードの自己反映スキップと保存スピナー早期解除を追加

**Commit**: `0d18c29`
**Status**: ✅ 完了・実機確認済み

---

### 3. ホワイトボード関連 Provider / プレビューの回帰耐性を改善 ✅

**Purpose**: ホワイトボードプレビュー取得失敗時に UI を完全に消さず、不要な監視を残さないようにする。

**Background**: ユーザー切替後のホワイトボードプレビュー欠落を追っていた際、Provider の寿命とエラー時の UI フォールバックが弱かった。

**Solution**:

ホワイトボード関連 Provider を `autoDispose` 化し、プレビュー取得失敗時は空表示ではなくエラープレースホルダーを返すようにした。

```dart
// ✅ After
final watchGroupWhiteboardProvider = StreamProvider.autoDispose.family<
    Whiteboard?, String>((ref, groupId) {
  final repository = ref.read(whiteboardRepositoryProvider);
  return repository.watchGroupWhiteboard(groupId);
});

error: (error, stack) {
  AppLogger.error('❌ ホワイトボードプレビューエラー: $error');
  return _buildErrorPlaceholder();
},
```

**検証結果**:

| テスト                                                   | 結果 |
| -------------------------------------------------------- | ---- |
| Pixel 9 でユーザー切替後の WB プレビュー欠落が再現しない | PASS |
| グループ詳細へ戻ってもプレビュー表示が維持される         | PASS |

**Modified Files**:

- `lib/providers/whiteboard_provider.dart` - Future / Stream Provider を `autoDispose` 化
- `lib/widgets/whiteboard_preview_widget.dart` - エラー時のプレースホルダー表示を追加

**Commit**: `0d18c29`
**Status**: ✅ 完了・実機確認済み

---

### 4. 2026-03-16 実機テストチェックリストを作成し、結果を反映 ✅

**Purpose**: 本日確認した Android / Windows 回帰結果をその場で残し、未確認項目を翌日以降へ持ち越せるようにする。

**Background**: 本日は作業所環境のため iOS 実機 / Simulator 確認ができず、Android / Windows 側の復元・ホワイトボード・ユーザー切替を優先確認した。

**Solution**:

3/16 用の実機テストチェックリストを新規作成し、共有ホワイトボード・個人用ホワイトボード・ユーザー切替の確認結果を追記した。

```markdown
### 5.2 個人ホワイトボード / 共有ホワイトボード

- [x] 共有ホワイトボードを開ける
- [x] 個人ホワイトボードを開ける
- [x] 保存できる対象では通常どおり保存できる

備考:

- 個人用ホワイトボードでも保存スピナーは残らず、保存後のUI反応低下も確認されなかった
```

**検証結果**:

| 確認項目                                               | 結果   |
| ------------------------------------------------------ | ------ |
| 別ユーザー再サインイン後に新ユーザーのグループのみ表示 | PASS   |
| 共有ホワイトボード保存後に他端末へ反映                 | PASS   |
| 個人用ホワイトボード保存後にスピナー / UI 劣化なし     | PASS   |
| `SharedGroup box is not open` ログ確認                 | 未実施 |
| 閲覧専用時の描画禁止                                   | 未実施 |
| 再保存後の重複ストローク有無                           | 未実施 |

**Modified Files**:

- `docs/daily_reports/2026-03/device_test_checklist_20260316.md` - 当日用チェックリスト新規作成、確認結果追記

**Commit**: `0d18c29`
**Status**: ✅ 完了・記録済み

---

## 🐛 発見された問題

### ネットワーク監視バナーが一時的な名前解決失敗をオフラインと誤判定する可能性 ⚠️

- **症状**: オレンジの接続エラーバナーが出ることがあるが、同期自体は通り、手動同期で解消する
- **原因**: Firestore / gRPC の `Failed to resolve name` が一時的に発生し、`network_monitor_service.dart` が強めに offline 判定している可能性が高い
- **対処**: 今日は原因整理まで実施。判定ロジックの緩和は未着手
- **状態**: 調査完了・修正未着手

### iOS ホワイトボード描画連続性は未確認 ⏳

- **症状**: iOS 実機 / Simulator で線分分断の最終確認がまだできていない
- **原因**: 本日は作業所環境で Mac がなく、iOS テスト不可
- **対処**: 3/16 用チェックリストに持ち越し項目を整理済み
- **状態**: 未着手

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ 共有ホワイトボード保存後のスピナー復帰不良を修正（完了日: 2026-03-16）
2. ✅ 個人用ホワイトボード保存後のスピナー残留と UI 劣化を修正（完了日: 2026-03-16）
3. ✅ ホワイトボード Provider / プレビューの回帰耐性改善（完了日: 2026-03-16）
4. ✅ 3/16 実機テストチェックリスト作成と結果反映（完了日: 2026-03-16）

### 対応中 🔄

1. 🔄 ネットワーク監視バナーの誤検知整理（Priority: Medium）

### 未着手 ⏳

1. ⏳ iOS ホワイトボード描画連続性確認（Priority: High）
2. ⏳ 閲覧専用時に描画できないことの確認（Priority: Medium）
3. ⏳ 再保存後の重複ストローク有無確認（Priority: Medium）
4. ⏳ `SharedGroup box is not open` 再発ログ確認（Priority: Medium）

### 翌日継続 ⏳

- ⏳ ネットワーク監視バナー判定の緩和方針整理
- ⏳ iOS 環境でのホワイトボード線分断確認

---

## 💡 技術的学習事項

### 個人用ホワイトボードでは保存直後の自己反映スナップショットを抑止する

**問題パターン**:

```dart
// ❌ 個人用ホワイトボードでも自分の保存直後の snapshot をそのまま再処理
setState(() {
  _currentWhiteboard = latest;
  _mergeStrokesFromFirestore(latest.strokes);
  _saveToHistory();
});
```

**正しいパターン**:

```dart
// ✅ 個人用ホワイトボード保存直後は 1 回だけ自己反映をスキップ
if (_suppressNextPersonalSnapshot &&
    _currentWhiteboard.isPersonalWhiteboard) {
  _suppressNextPersonalSnapshot = false;
  _currentWhiteboard = latest;
  return;
}
```

**教訓**: 共有ボードでは編集ロックが自己反映抑止になるが、個人用ボードには同等の防波堤がない。保存直後の自己反映は明示的に抑止しないと、履歴保存と再描画が二重に走って UI 体感を悪化させる。

---

### Firestore write-only 保存で `runTransaction()` を使わない

**問題パターン**:

```dart
// ❌ write-only なのに runTransaction() へ依存
await _firestore.runTransaction((transaction) async {
  final snapshot = await transaction.get(docRef);
  transaction.update(docRef, updateData);
});
```

**正しいパターン**:

```dart
// ✅ get + update に寄せて UI 復帰遅延を避ける
await _addStrokesWithoutTransaction(
  groupId: groupId,
  whiteboardId: whiteboardId,
  newStrokes: newStrokes,
);
```

**教訓**: ホワイトボード保存のような差分追加では、サーバー応答前提の `runTransaction()` は UI 復帰遅延の原因になりやすい。編集ロックや単独編集前提があるなら、通常の `get + update` の方が実運用で安定する。

---

### `Failed to resolve name` は Firebase / gRPC の一時的な名前解決失敗

**問題パターン**:

```text
W/ManagedChannelImpl: Failed to resolve name
V/NativeCrypto: Broken pipe
```

**正しい見方**:

```text
- 200 は正常レスポンス
- Failed to resolve name は DNS / 名前解決の一時失敗
- 同期自体が成功しているなら、恒久障害ではなく監視側の誤検知寄り
```

**教訓**: `Failed to resolve name` は即データ破損や保存失敗を意味しない。手動同期で回復し、実際の Firestore 操作が通るなら、ネットワーク監視の offline 判定条件を疑うべき。

---

## 🗓 翌日（2026-03-17）の予定

1. `network_monitor_service.dart` の offline 判定を見直し、オレンジバナーの誤検知を減らす
2. 自宅 Mac 環境で iOS ホワイトボード描画連続性を確認する
3. 閲覧専用時の描画禁止と再保存後の重複ストローク有無を実機確認する
4. `SharedGroup box is not open` の再発ログ有無を確認する
