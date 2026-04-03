# グループ・リスト・アイテム管理指示書

> 共通ルールは `00_project_common.md` を先に読むこと。

---

## 1. 基本方針

- **CRUD はすべて Firestore 優先**
- Hive はキャッシュ用途のみ（write-through で更新する）
- **差分同期**（Map フィールド単位の更新）を必須とする
- Hybrid リポジトリで Firestore 失敗後も Hive 書き込みを必ず続行する

```dart
// ✅ 正しい — Firestore 失敗でも Hive は続行
try {
  await _firestoreRepo!.createGroup(...);
} catch (_) {}
await _hiveRepo.createGroup(...);
```

---

## 2. ID 生成

- グループ ID: `DeviceIdPrefix_timestamp`（例: `a3f8c9d2_1707835200000`）
- リスト ID: `DeviceIdPrefix_uuid8`（例: `a3f8c9d2_f3e1a7b4`）
- `DeviceIdService.generateGroupId()` / `generateListId()` を使う
- `timestamp.toString()` のみの実装は衝突リスクがあり **禁止**

---

## 3. SharedItem 差分同期（必須）

SharedItem は `Map<String, SharedItem>` 形式。**全件置換禁止**。

```dart
// ❌ 禁止 — リスト全体を送信（~5KB）
final updated = currentList.copyWith(items: {...currentList.items, newItem.itemId: newItem});
await repository.updateSharedList(updated);

// ✅ 正しい — 単一アイテムのみ送信（~500B）
await repository.addSingleItem(currentList.listId, newItem);
await repository.updateSingleItem(currentList.listId, updatedItem);
await repository.removeSingleItem(currentList.listId, itemId);  // 論理削除
```

Firestore 側は `items.{itemId}` フィールド単位で更新する:

```dart
await docRef.update({
  'items.${item.itemId}': _itemToFirestore(item),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### UI 表示では必ず `activeItems` ゲッターを使う

```dart
// ❌ 禁止 — 論理削除済みアイテムも表示される
for (var item in currentList.items.values) { ... }

// ✅ 正しい
for (var item in currentList.activeItems) { ... }
```

---

## 4. DropdownButton の重複値禁止

`DropdownButton` に同じ値が複数存在すると Flutter assertion error になる。
**Provider 層と UI 層の両方で groupId 重複除去を行う**。

```dart
// ✅ Provider 層: allGroupsProvider で重複除去
final uniqueGroups = <String, SharedGroup>{};
for (final group in filteredGroups) {
  uniqueGroups[group.groupId] = group;
}
return uniqueGroups.values.toList();

// ✅ UI 層: Dropdown items でも重複除去
items: existingGroups
    .fold<Map<String, SharedGroup>>({}, (map, g) {
      map[g.groupId] = g;
      return map;
    })
    .values
    .map((g) => DropdownMenuItem(value: g, child: Text(g.groupName)))
    .toList()
```

---

## 5. グループ削除・メンバー離脱

- **グループ削除**（オーナーのみ）
  - Firestore から削除
  - 全メンバーに `groupDeleted` 通知を送信
  - 受信側は Hive からも削除して UI を更新

- **グループ離脱**（メンバーのみ）
  - `members` 配列 + `allowedUid` 配列の**両方**から削除
  - オーナーは離脱不可（削除のみ）

---

## 5.1 リスト削除権限

- **削除可能なユーザー**: グループオーナー（`group.ownerUid == currentUid`）または リスト作成者（`list.ownerUid == currentUid`）
- **削除ボタンは権限あり時のみ表示する**（UI で非表示 + `_showDeleteListDialog` 内でも二重チェック）

```dart
// ✅ build() で canDelete を計算
final canDelete = currentUid != null &&
    (currentUid == currentGroup?.ownerUid ||
        currentUid == currentList.ownerUid);

// ✅ ボタン表示制御
if (currentList != null && canDelete)
  IconButton(icon: Icon(Icons.delete_outline), ...)
```

---

## 6. Hive クリーンアップ

`allowedUid` に現在ユーザーが含まれないグループは Hive から削除する。
**Firestore は削除しない**（他ユーザーが使用している可能性があるため）。

```dart
for (final group in await hiveRepository.getAllGroups()) {
  if (!group.allowedUid.contains(currentUserId)) {
    await hiveRepository.deleteGroup(group.groupId);  // Hive のみ
  }
}
```

---

## 7. 禁止事項まとめ

- `updateSharedList()` でアイテムの全件置換更新
- 権限チェック（`ownerUid` / `allowedUid`）なしの更新
- `invalidate()` せずに `FutureProvider` を再利用
- `runTransaction()` のオフライン使用（Windows では abort クラッシュ）
- Hive 切替直後の空状態を「0件確定」と見なす
