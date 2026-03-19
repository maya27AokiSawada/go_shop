# 開発日報 - 2026年03月18日

## 📅 本日の目標

- [x] 個人用ホワイトボードの `isPrivate` スイッチが切り替わらないバグを根本修正する
- [x] `watchWhiteboard` の楽観的更新が保存直後に上書きされる問題を修正する
- [x] 編集ロック初期化タイミングによる自端末誤判定を修正する
- [x] `_releaseEditLock()` の UI 先行リセットを確実に動かす
- [ ] ホワイトボード Firestore ロック・同期の簡素化（arrayUnion + ソフトロック）を実装する

---

## ✅ 完了した作業

### 1. `setWhiteboardPrivate()` の stale return を修正 ✅

**Purpose**: `isPrivate` 切替後にFirestore再取得の結果にかかわらず常に意図した値が返るようにする。

**Background**: 実機（SH-54D / Pixel 9）で個人用ホワイトボードの「編集可 / 編集不可」スイッチを切り替えても画面が元に戻る症状が報告された。

**Problem / Root Cause**:

`setWhiteboardPrivate()` が `reloaded` を取得した場合は `copyWith` を適用せずそのまま返していた。Firestore からの再取得が完了している場合でも `isPrivate` が意図した値に上書きされない経路が存在した。

```dart
// ❌ Before: reloaded が non-null の場合 copyWith が適用されない
final reloaded = await getWhiteboardById(groupId, whiteboardId);
return reloaded ??
    (fallbackWhiteboard ?? Whiteboard(...))
        .copyWith(
          isPrivate: isPrivate,
          ...
        );
```

**Solution**:

`reloaded` が non-null でも必ず `.copyWith(isPrivate: isPrivate)` を適用するよう修正した。

```dart
// ✅ After: 常に isPrivate を上書き
return (reloaded ?? fallbackWhiteboard ?? Whiteboard(...))
    .copyWith(
      isPrivate: isPrivate,
      updatedAt: DateTime.now(),
    );
```

**Modified Files**:

- `lib/datastore/whiteboard_repository.dart` - `setWhiteboardPrivate()` の return ロジック修正

**Commit**: `3a34843`
**Status**: ✅ 実装完了・実機確認待ち

---

### 2. `watchWhiteboard()` に `hasPendingWrites` フィルターを追加 ✅

**Purpose**: 保存処理直後に Firestore SDK がローカル pending write スナップショットを流すことで楽観的 UI 更新が上書きされる問題を防ぐ。

**Problem / Root Cause**:

`watchWhiteboard()` がすべてのスナップショットを処理していたため、`set()` / `update()` の直後に SDK が返す pending write（`metadata.hasPendingWrites = true`）のスナップショットで `_currentWhiteboard` が古いデータに戻されることがあった。これが「スイッチが元に戻る」症状の最大の原因。

```dart
// ❌ Before: pending write も処理してしまう
Stream<Whiteboard?> watchWhiteboard(...) {
  return _collection(groupId).doc(whiteboardId).snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return Whiteboard.fromFirestore(snapshot.data()!, snapshot.id);
  });
}
```

**Solution**:

`.where((snapshot) => !snapshot.metadata.hasPendingWrites)` フィルターを追加した。

```dart
// ✅ After: pending write スナップショットはスキップ
Stream<Whiteboard?> watchWhiteboard(...) {
  return _collection(groupId).doc(whiteboardId)
      .snapshots()
      .where((snapshot) => !snapshot.metadata.hasPendingWrites)
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return Whiteboard.fromFirestore(snapshot.data()!, snapshot.id);
  });
}
```

**Modified Files**:

- `lib/datastore/whiteboard_repository.dart` - `watchWhiteboard()` に pending write フィルター追加

**Commit**: `3a34843`
**Status**: ✅ 実装完了

---

### 3. `_setPrivate()` での `updated.copyWith(isPrivate: isPrivate)` 強制適用 ✅

**Purpose**: Fix 1 の戻り値が万が一 stale であっても画面上の値は意図した値に固定されるよう、belt-and-suspenders として追加修正した。

```dart
// ❌ Before: setWhiteboardPrivate() の戻り値をそのまま使う
setState(() {
  _currentWhiteboard = updated;
});

// ✅ After: isPrivate を明示的に強制
setState(() {
  _currentWhiteboard = updated.copyWith(isPrivate: isPrivate);
});
```

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` - `_setPrivate()` の setState を修正

**Commit**: `3a34843`
**Status**: ✅ 実装完了

---

### 4. `_loadCurrentDeviceId()` 完了後に `_watchEditLock()` を起動する順序修正 ✅

**Purpose**: `_currentDeviceId == null` の状態で `_watchEditLock()` が走ると自端末の lock を他端末のものと誤判定する問題を修正する。

**Problem / Root Cause**:

`unawaited(_loadCurrentDeviceId())` で deviceId 取得と `_watchEditLock()` 起動が並行していたため、deviceId 未取得のまま最初の lock スナップショットを受け取ることがあった。

```dart
// ❌ Before: 並行起動で deviceId が未取得のまま lock 判定が走る
unawaited(_loadCurrentDeviceId());
_watchEditLock();
```

**Solution**:

`_loadCurrentDeviceId()` の完了コールバック内で `_watchEditLock()` を起動するよう変更した。

```dart
// ✅ After: deviceId 取得完了後に lock 監視開始
_loadCurrentDeviceId().then((_) {
  if (!mounted) return;
  _watchEditLock();
});
```

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` - initState の初期化順序を修正

**Commit**: `3a34843`
**Status**: ✅ 実装完了

---

### 5. `_releaseEditLock()` の UI 状態先行リセット ✅

**Purpose**: ロック解除の Firestore 通信遅延があっても画面は即座にスクロールモードへ戻れるようにする。

```dart
// ✅ After: UI をまず先にリセット、通信は後ろで行う
if (mounted) {
  setState(() {
    _hasEditLock = false;
    _isEditingLocked = false;
    _currentEditor = null;
  });
}

try {
  await lockService.releaseEditLock(...).timeout(const Duration(seconds: 3));
} catch (e) {
  // フォールバック: forceReleaseEditLock を試みる
}
```

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` - `_releaseEditLock()` の setState 位置を try ブロック前に移動

**Commit**: `3a34843`
**Status**: ✅ 実装完了

---

### 6. `releaseEditLock()` を同一ユーザー別端末からも解除可能に修正 ✅

**Purpose**: 同じ Firebase アカウントの別端末が残した stale lock を解除できるようにする。

**Problem**: `currentDeviceId != lockDeviceId` の場合に解除を拒否していたため、端末切り替え後に自分の stale lock が残り続けるケースがあった。

```dart
// ❌ Before: userId + deviceId 完全一致のみ解除許可
if (currentUserId == userId &&
    (currentDeviceId == null || currentDeviceId == deviceId)) {
  // 解除
}

// ✅ After: 同一ユーザーなら別端末からでも解除許可
if (currentUserId == userId) {
  // 解除
}
```

**Modified Files**:

- `lib/services/whiteboard_edit_lock_service.dart` - `releaseEditLock()` / `_releaseEditLockWithoutTransaction()` の判定条件を変更

**Commit**: `3a34843`
**Status**: ✅ 実装完了

---

### 7. 通知クエリのタイムアウトを `Future.any()` で確実に保証 ✅

**Purpose**: Firestore のネイティブ SDK がブロックすると `.timeout()` が効かない場合があるため、`Future.any()` で確実なタイムアウトを保証する。

```dart
// ✅ After
final snapshot = await Future.any([
  _firestore.collection('notifications')
      .where('userId', isEqualTo: currentUser.uid)
      .where('timestamp', isGreaterThan: lastSyncTime)
      .get(),
  Future<QuerySnapshot<Map<String, dynamic>>>.delayed(
    const Duration(seconds: 5),
    () => throw TimeoutException('Firestore通知クエリが5秒でタイムアウト'),
  ),
]);
```

**Modified Files**:

- `lib/services/notification_service.dart` - 通知クエリのタイムアウト処理を `Future.any()` に変更

**Commit**: `3a34843`
**Status**: ✅ 実装完了

---

## 💡 議論・検討のみ（未実装）

### ホワイトボード Firestore ロック・同期の簡素化（arrayUnion + ソフトロック）⏳

**概要**: ストローク線画は強整合性が不要という前提で下記の方向性を確認した。

- `addStrokesToWhiteboard()` を `FieldValue.arrayUnion(...)` 単発書き込みに置き換えて `get+update` フェッチを廃止
- `runTransaction` ベースの排他ロックを削除し「誰が描いているか通知するだけ」のソフトロックへ
- TTL を 1時間 → 5分に短縮

設計確認を行ったが実装は翌日以降へ持ち越し。

---

## 🐛 発見された問題

### Firestore pending write による楽観的 UI 上書き ✅ 解決済み

- **症状**: `isPrivate` スイッチを ON にしても即座に OFF に戻る
- **原因**: `watchWhiteboard()` が pending write スナップショット（SDK の save 直後の自己反映）も処理していた
- **対処**: `hasPendingWrites` フィルター追加 (Fix 2A)
- **状態**: 修正完了（`3a34843`）

### 編集ロック初期化タイミング競合 ✅ 解決済み

- **症状**: 初回 lock スナップショット受信時に自端末の lock を他端末のものと誤判定する
- **原因**: `_currentDeviceId` が null のまま `_watchEditLock()` が走っていた
- **対処**: `_loadCurrentDeviceId()` の完了を待ってから `_watchEditLock()` を起動 (Fix 4)
- **状態**: 修正完了（`3a34843`）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ `isPrivate` スイッチが切り替わらない（完了日: 2026-03-18）
2. ✅ `watchWhiteboard` pending write フィルター欠落（完了日: 2026-03-18）
3. ✅ `_currentDeviceId` 未取得での lock 誤判定（完了日: 2026-03-18）
4. ✅ ペンモード占有ロックを全ボードへ拡張（完了日: 2026-03-17）
5. ✅ 同一ユーザー別端末 lock 誤認（userId のみ）（完了日: 2026-03-17）
6. ✅ ペンモード OFF の UI 先行復帰（完了日: 2026-03-17）

### 翌日継続 ⏳

1. ⏳ ホワイトボード Firestore ロック・同期の簡素化（arrayUnion + ソフトロック）
2. ⏳ Android / Windows 実機でペンモード ON / OFF の最終回帰確認

---

## 📝 Technical Learning

### Firestore `hasPendingWrites` の挙動

`docRef.update()` や `set()` を呼んだ直後、SDK はそのローカル確定値を含むスナップショットを即座に stream に流す。このとき `metadata.hasPendingWrites = true`。サーバーが ACK を返すと `hasPendingWrites = false` のスナップショットが追加で流れる。

UI を更新した直後にリスナーが「古い状態」を再適用してしまう症状は多くの場合 pending write の取り扱いが原因である。対応パターン:

```dart
// 読み取り専用リスナーには pending write を無視するフィルターを追加
.snapshots()
.where((s) => !s.metadata.hasPendingWrites)
```

または `includeMetadataChanges: false`（デフォルト）をそのまま使いつつ、write 後に一定時間リスナーの上書きを抑制するフラグで対処する（`_suppressNextPersonalSnapshot` パターン）。

### Future.any() と .timeout() の違い

`.timeout()` は Dart の Stream/Future レベルでタイマーを貼るが、ネイティブ SDK が C++ スレッドをブロックしている場合は効かないことがある。`Future.any([query.get(), Future.delayed(5s, () => throw TimeoutException(...))])` で確実に Dart レベルのタイムアウトを保証できる。
