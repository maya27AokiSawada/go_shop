# 開発日報 - 2026年04月03日

## 📅 本日の目標

- [x] 実機総合テスト チェックリスト作成
- [x] テスト 2.1〜2.3 実施
- [x] updatedAt バージョンチェック UX 改善
- [x] テスト 3.1〜4.1 実施
- [x] テスト 4.2 実施（QR 招待）
- [x] テスト 4.3 実施（買い物リスト）
- [ ] テスト 4.4〜10 実施（翌日以降）

---

## ✅ 完了した作業

### 1. 実機総合テスト チェックリスト作成 ✅

**Purpose**: セッションコンテキストから総合テストの全手順チェックリストを生成

**Solution**: `docs/daily_reports/2026-04/device_test_checklist_20260403.md` を新規作成（テスト 2.1〜10 + NG 判定条件 + まとめテーブル）

**Status**: ✅ 完了

---

### 2. updatedAt バージョンチェック UX 改善 ✅

**Purpose**: ホワイトボード再入時に Firestore を毎回取得せず、バージョンが一致すればキャッシュから即時復元する

**Background**: 再入のたびに Firestore からスト ロークを再フェッチしており、スピナー表示時間が不必要に長かった

**Problem / Root Cause**:

```dart
// ❌ バージョン一致でスキップしたが _workingStrokes が空のまま表示された
if (cachedVersion == serverVersion) {
  return; // ← キャッシュからの復元なし
}
```

**Solution**:

```dart
// ✅ バージョン一致時はメモリキャッシュから復元、空なら Firestore フォールバック
if (cachedVersion == serverVersion) {
  final cached = personalCacheService.getMemoryCachedWhiteboard(boardId);
  if (cached != null && cached.isNotEmpty) {
    setState(() => _workingStrokes = cached);
    return;
  }
}
await _loadInitialStrokes(); // フォールバック
```

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart`（initState にバージョンチェック追加、`_loadInitialStrokes` 後に `saveStrokesVersion` 呼び出し）
- `lib/services/personal_whiteboard_cache_service.dart`（`_strokesVersionCache`、`getMemoryCachedStrokesVersion()`、`saveStrokesVersion()`、`loadStrokesVersion()` 追加）

**Commit**: `b9413ab`
**Status**: ✅ 完了・検証済み

---

### 3. ホワイトボード全消去の別端末反映なしバグ修正 ✅

**Purpose**: 同一ユーザーの別端末で全消去が即時反映されない問題の修正

**Problem / Root Cause**:

```dart
// ❌ 編集者本人のボードではリスナーを早期リターンしていた
if (isEditablePersonalWhiteboard) {
  return; // ← _strokesSubscription が未起動のまま
}
```

**Solution**:

```dart
// ✅ アーリーリターンを削除。常に _strokesSubscription を開始
// isEditablePersonalWhiteboard かどうかに関わらず Firestore をリッスン
_startStrokesSubscription(boardId, groupId);
```

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart`（`_startWhiteboardListener()` のアーリーリターン削除）

**Commit**: `b9413ab`
**Status**: ✅ 完了・検証済み

---

### 4. QR スキャン自己招待ガード追加 ✅

**Purpose**: 自分自身の QR コードをスキャンした場合にダイアログを出さずオレンジ Snackbar で知らせる

**Problem / Root Cause**: `acceptQRInvitation()` 内の同一ユーザーチェックがダイアログ受諾後の処理であり、ダイアログが表示されてから初めてエラーになっていた

**Solution**:

```dart
// ✅ _handleQRScan() でダイアログ表示前にガード
final inviterUid = invitationData['inviterUid'] as String?;
if (currentUser != null && inviterUid == currentUser.uid) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('自分自身の招待コードはスキャンできません'),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

**Modified Files**:

- `lib/widgets/qr_invitation_widgets.dart`（`_handleQRScan()` に自己招待ガード追加）

**Status**: ✅ 完了・未コミット（本日まとめコミットに含める）

---

### 5. QR スキャン「すでにグループメンバー」分岐のブラックアウト修正 ✅

**Purpose**: 「すでにグループメンバー」分岐で MobileScanner が停止されずブラックアウトが発生していた問題の修正

**Background**: Pixel 9 でグループのQRコードをスキャンするとブラックアウトが発生。logcat 調査により `accept_invitation_widget.dart:341`「すでにグループメンバー」分岐で止まっていることを特定

**Problem / Root Cause**:

```dart
// ❌ _controller.stop() なしで pop() → カメラプレビューが残留してブラックアウト
if (existingGroup.allowedUid.contains(user.uid)) {
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(...);
  return;
}
```

**Solution**:

```dart
// ✅ 成功時パターンと同様に navigator/messenger を先に取得 → stop → pop
final navigator = Navigator.of(context);
final messenger = ScaffoldMessenger.maybeOf(context);
try {
  await _controller.stop();
} catch (e) {
  Log.warning('⚠️ [QR_SCAN] カメラ停止エラー: $e');
}
navigator.pop();
messenger?.showSnackBar(...);
```

**Modified Files**:

- `lib/widgets/accept_invitation_widget.dart`（「すでにグループメンバー」分岐に `_controller.stop()` 追加）

**Status**: ✅ 完了・未コミット（本日まとめコミットに含める）

---

### 6. 買い物リスト削除権限制御の実装 ✅

**Purpose**: リスト削除が全メンバーに許可されていた問題を修正し、グループオーナーまたはリスト作成者のみ削除可能にする

**Background**: テスト 4.3 実施中に、権限のないメンバーでもリスト削除ボタンが表示・実行できることを発見

**Problem / Root Cause**: `shared_list_header_widget.dart` の削除ボタン表示条件が `currentList != null` のみで、権限チェックなし

**Solution**:

```dart
// ✅ build() で削除権限を計算（グループオーナー OR リスト作成者）
final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;
final canDeleteCurrentList = currentUid != null &&
    currentList != null &&
    (currentUid == currentGroup?.ownerUid ||
        currentUid == currentList.ownerUid);

// ✅ canDelete が true の場合のみ削除ボタンを表示
if (currentList != null && canDelete)
  IconButton(icon: Icon(Icons.delete_outline, ...), ...)

// ✅ _showDeleteListDialog() にも二重ガード追加
final canDelete = currentUid != null &&
    (currentUid == group?.ownerUid || currentUid == listToDelete.ownerUid);
if (!canDelete) { Log.warning(...); return; }
```

**Modified Files**:

- `lib/widgets/shared_list_header_widget.dart`（`build()` に `canDeleteCurrentList` 計算追加、`_buildListDropdown` に `canDelete` パラメータ追加、`_showDeleteListDialog` に二重ガード追加）

**Status**: ✅ 完了・未コミット（本日まとめコミットに含める）

---

### 7. アイテム編集権限なし時の赤 Snackbar 追加 ✅

**Purpose**: 権限のないメンバーがアイテムをダブルタップしても何も起きず UX が悪い問題を改善

**Solution**:

```dart
// ✅ 権限なし時に赤いSnackBar（0.5秒）を表示してから return
if (!canEdit) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('編集権限がありません'),
      backgroundColor: Colors.red,
      duration: Duration(milliseconds: 500),
    ),
  );
  return;
}
```

**Modified Files**:

- `lib/pages/shared_list_page.dart`（`_SharedItemTile.onDoubleTap` に Snackbar 追加）

**Status**: ✅ 完了・未コミット（本日まとめコミットに含める）

---

## 🐛 発見された問題

### ブラックアウト — QR スキャン「すでにグループメンバー」分岐 ✅ 修正済み

- **症状**: QR スキャン後に Pixel 9 がブラックアウト
- **原因**: `_controller.stop()` なしで `Navigator.pop()` を呼んだためカメラプレビューが残留
- **対処**: `accept_invitation_widget.dart` に `_controller.stop()` を追加
- **状態**: 修正完了・検証済み

### リスト削除権限なし ✅ 修正済み

- **症状**: 権限のないメンバーがリストを削除できた
- **原因**: 削除ボタンの表示・実行に権限チェックなし
- **対処**: グループオーナーまたはリスト `ownerUid` 一致時のみ削除ボタン表示・実行可
- **状態**: 修正完了・検証済み

---

## 📊 テスト進捗

| テスト  | 内容                         | 結果                   |
| ------- | ---------------------------- | ---------------------- |
| 2.1     | 多重タップ防止 + スピナー    | ✅ OK                  |
| 2.2     | 終了時自動保存               | ✅ OK                  |
| 2.3     | PopScope 移行                | ✅ OK                  |
| 3.1     | 描画・保存・同期             | ✅ OK                  |
| 3.2     | 全消去機能                   | ✅ OK（バグ修正後）    |
| 3.3     | 個人ボードのプライバシー制御 | ✅ OK                  |
| 3.4     | 編集ロック                   | ✅ OK（廃止済み・N/A） |
| 3.5     | ストローク監視               | ✅ OK                  |
| 3.6     | 初回スピナー                 | ✅ OK                  |
| 4.1     | サインイン / サインアウト    | ✅ OK                  |
| 4.2     | グループ管理・QR 招待        | ✅ OK（バグ修正後）    |
| 4.3     | 買い物リスト                 | ✅ OK（バグ修正後）    |
| 4.4〜10 | —                            | ⏳ 未実施              |

---

## 💡 技術的学習事項

### MobileScanner の停止なしで pop() するとブラックアウトになる

**問題パターン**:

```dart
// ❌ stop() なしで pop() → カメラ残留
Navigator.of(context).pop();
```

**正しいパターン**:

```dart
// ✅ navigator/messenger を先取得 → stop() → pop()
final navigator = Navigator.of(context);
final messenger = ScaffoldMessenger.maybeOf(context);
try { await _controller.stop(); } catch (_) {}
navigator.pop();
messenger?.showSnackBar(...);
```

**教訓**: MobileScanner を使う全ての分岐（正常・スキップ・エラー）で必ず `_controller.stop()` を呼ぶこと。

---

## 🗓 翌日（2026-04-04）の予定

1. テスト 4.4 設定画面
2. テスト 5.1〜5.3 通知システム
3. テスト 6.1〜6.3 データ同期
4. テスト 7 ネットワーク監視バナー
5. テスト 8 サインイン切替
6. テスト 9 UI/UX
7. テスト 10 ErrorLogService

---

## 📝 ドキュメント更新

| ドキュメント                              | 更新内容                                                          |
| ----------------------------------------- | ----------------------------------------------------------------- |
| `instructions/40_qr_and_notifications.md` | QR スキャン時のカメラ停止パターンを追記                           |
| `instructions/20_groups_lists_items.md`   | リスト削除権限ルール（グループオーナー OR リスト ownerUid）を追記 |
