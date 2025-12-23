# Go Shop - CRUD処理ワークフロー & アーキテクチャ資料

**最終更新**: 2025-12-23
**アーキテクチャ**: Firestore-First Hybrid Pattern (2025-12-18 実装完了)

---

## 📋 目次

1. [アーキテクチャ概要](#アーキテクチャ概要)
2. [SharedGroup CRUD](#sharedgroup-crud)
3. [SharedList CRUD](#sharedlist-crud)
4. [SharedItem CRUD（差分同期）](#shareditem-crud差分同期)
5. [関連ファイル一覧](#関連ファイル一覧)
6. [データフロー図](#データフロー図)

---

## アーキテクチャ概要

### Firestore-First Hybrid Pattern

```
┌─────────────┐
│     UI      │  (Pages/Widgets)
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Provider   │  (Riverpod State Management)
└──────┬──────┘
       │
       ↓
┌──────────────────────┐
│  Hybrid Repository   │  ← ここで Firestore-first 判定
└──────────┬───────────┘
           │
    ┌──────┴──────┐
    ↓             ↓
┌────────────┐  ┌──────────┐
│ Firestore  │  │   Hive   │
│ Repository │  │ Cache    │
└────────────┘  └──────────┘
    (優先)        (フォールバック)
```

### 処理フロー（2025-12-18実装）

```dart
// ✅ Firestore-First Pattern
if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
  try {
    // 1. Firestoreから取得/更新
    final result = await _firestoreRepo!.operation();

    // 2. Hiveにキャッシュ
    await _hiveRepo.saveToCache(result);

    return result;
  } catch (e) {
    // 3. Firestoreエラー時はHiveフォールバック
    return await _hiveRepo.operation();
  }
}
```

**特徴**:
- ✅ 認証必須アプリ（常にオンライン前提）
- ✅ Firestoreが常に最新のデータソース
- ✅ Hiveは読み取り高速化用キャッシュ
- ✅ 90%データ転送削減（SharedItem差分同期）

---

## SharedGroup CRUD

### 📂 関連ファイル

#### Repository層
- **Abstract**: [`lib/datastore/shared_group_repository.dart`](../lib/datastore/shared_group_repository.dart)
- **Hybrid**: [`lib/datastore/hybrid_purchase_group_repository.dart`](../lib/datastore/hybrid_purchase_group_repository.dart) ⭐ **メイン実装**
- **Firestore**: [`lib/datastore/firestore_purchase_group_repository.dart`](../lib/datastore/firestore_purchase_group_repository.dart)
- **Hive**: [`lib/datastore/hive_shared_group_repository.dart`](../lib/datastore/hive_shared_group_repository.dart)

#### Provider層
- **Main**: [`lib/providers/purchase_group_provider.dart`](../lib/providers/purchase_group_provider.dart)
  - `allGroupsProvider` - 全グループ取得
  - `selectedGroupProvider` - 選択中グループ
  - `selectedGroupIdProvider` - 選択中グループID

#### UI層
- **Page**: [`lib/pages/shared_group_page.dart`](../lib/pages/shared_group_page.dart)
- **Widgets**:
  - [`lib/widgets/group_list_widget.dart`](../lib/widgets/group_list_widget.dart) - グループ一覧
  - [`lib/widgets/group_creation_with_copy_dialog.dart`](../lib/widgets/group_creation_with_copy_dialog.dart) - 作成ダイアログ
  - [`lib/widgets/group_selector_widget.dart`](../lib/widgets/group_selector_widget.dart) - 選択ドロップダウン

#### メンバー管理
- **Page**: [`lib/pages/group_member_management_page.dart`](../lib/pages/group_member_management_page.dart)

### 🔄 CRUD ワークフロー

#### ✅ Create（グループ作成）

```
[UI] group_creation_with_copy_dialog.dart
  ↓ ユーザーがグループ名入力
  ↓ ref.read(allGroupsProvider.notifier).createGroup()
  ↓
[Provider] purchase_group_provider.dart
  ↓ AllGroupsNotifier.createGroup()
  ↓
[Repository] hybrid_purchase_group_repository.dart
  ↓ HybridSharedGroupRepository.createGroup()
  ├─→ [Firestore] firestore_purchase_group_repository.dart
  │     ├─ collection('SharedGroups').doc(groupId).set()
  │     └─ allowedUid配列にownerUidを追加
  └─→ [Hive] hive_shared_group_repository.dart
        └─ SharedGroupBox.put(groupId, group)
  ↓
[Result] Firestoreに保存 → Hiveにキャッシュ
```

**コード例**:
```dart
// UI側
await ref.read(allGroupsProvider.notifier).createGroup(
  groupName: groupName,
  ownerMember: ownerMember,
);

// Repository側（Hybrid）
@override
Future<void> createGroup(String groupId, String groupName, SharedGroupMember owner) async {
  if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
    try {
      // 1. Firestoreに作成
      await _firestoreRepo!.createGroup(groupId, groupName, owner);

      // 2. Hiveにキャッシュ
      final createdGroup = await _firestoreRepo!.getGroupById(groupId);
      await _hiveRepo.saveGroup(createdGroup);
    } catch (e) {
      // Firestoreエラー時はHiveのみ
      await _hiveRepo.createGroup(groupId, groupName, owner);
    }
  }
}
```

#### 📖 Read（グループ取得）

```
[UI] group_list_widget.dart
  ↓ ref.watch(allGroupsProvider)
  ↓
[Provider] purchase_group_provider.dart
  ↓ AllGroupsNotifier.build()
  ↓
[Repository] hybrid_purchase_group_repository.dart
  ↓ HybridSharedGroupRepository.getAllGroups()
  ├─→ [Firestore] allowedUid配列でフィルタリング
  │     ├─ where('allowedUid', arrayContains: currentUserId)
  │     └─ 取得結果をHiveにキャッシュ
  └─→ [Hive] SharedGroupBox.values
  ↓
[Result] Firestore最新データ → UIに表示
```

**フィルタリング**:
```dart
// allowedUidフィルタリング（二重安全策）
final currentUser = ref.read(authStateProvider).value;
if (currentUser != null) {
  allGroups = allGroups.where((g) =>
    g.allowedUid.contains(currentUser.uid)
  ).toList();
}
```

#### ✏️ Update（グループ更新）

```
[UI] group_member_management_page.dart
  ↓ メンバー追加/削除/ロール変更
  ↓ ref.read(allGroupsProvider.notifier).updateGroup()
  ↓
[Provider] purchase_group_provider.dart
  ↓ AllGroupsNotifier.updateGroup()
  ↓
[Repository] hybrid_purchase_group_repository.dart
  ↓ HybridSharedGroupRepository.updateGroup()
  ├─→ [Firestore] doc(groupId).update()
  │     └─ members配列、allowedUid配列更新
  └─→ [Hive] SharedGroupBox.put(groupId, updatedGroup)
  ↓
[Result] Firestore更新 → Hiveキャッシュ更新
```

#### 🗑️ Delete（グループ削除）

```
[UI] group_list_widget.dart
  ↓ 削除確認ダイアログ
  ↓ ref.read(allGroupsProvider.notifier).deleteGroup()
  ↓
[Provider] purchase_group_provider.dart
  ↓ AllGroupsNotifier.deleteGroup()
  ↓ デフォルトグループチェック（削除禁止）
  ↓
[Repository] hybrid_purchase_group_repository.dart
  ↓ HybridSharedGroupRepository.deleteGroup()
  ├─→ [Firestore] doc(groupId).delete()
  │     ├─ グループドキュメント削除
  │     └─ サブコレクション(sharedLists)も削除
  └─→ [Hive] SharedGroupBox.delete(groupId)
  ↓
[Result] Firestore削除 → Hiveキャッシュ削除
```

**デフォルトグループ保護**:
```dart
// UI/Repository/Providerの3層で保護
if (isDefaultGroup(group, currentUser)) {
  throw Exception('デフォルトグループは削除できません');
}
```

---

## SharedList CRUD

### 📂 関連ファイル

#### Repository層
- **Abstract**: [`lib/datastore/shared_list_repository.dart`](../lib/datastore/shared_list_repository.dart)
- **Hybrid**: [`lib/datastore/hybrid_shared_list_repository.dart`](../lib/datastore/hybrid_shared_list_repository.dart) ⭐ **メイン実装**
- **Firestore**: [`lib/datastore/firestore_shared_list_repository.dart`](../lib/datastore/firestore_shared_list_repository.dart)
- **Hive**: [`lib/datastore/hive_shared_list_repository.dart`](../lib/datastore/hive_shared_list_repository.dart)

#### Provider層
- **Main**: [`lib/providers/shared_list_provider.dart`](../lib/providers/shared_list_provider.dart)
  - `sharedListRepositoryProvider` - Repository取得
  - `groupSharedListsProvider` - グループ内リスト一覧
- **Current**: [`lib/providers/current_list_provider.dart`](../lib/providers/current_list_provider.dart)
  - `currentListProvider` - 現在選択中のリスト

#### UI層
- **Page**: [`lib/pages/shared_list_page.dart`](../lib/pages/shared_list_page.dart)
- **Widget**: [`lib/widgets/shared_list_header_widget.dart`](../lib/widgets/shared_list_header_widget.dart)

### 🔄 CRUD ワークフロー

#### ✅ Create（リスト作成）

```
[UI] shared_list_header_widget.dart
  ↓ リスト作成ダイアログ
  ↓ repository.createSharedList()
  ↓
[Repository] hybrid_shared_list_repository.dart
  ↓ HybridSharedListRepository.createSharedList()
  ├─→ [Firestore] firestore_shared_list_repository.dart
  │     ├─ collection('SharedGroups/{groupId}/sharedLists')
  │     ├─ doc(listId).set({
  │     │     listName: name,
  │     │     items: {},  // ← Map形式で初期化
  │     │     createdAt: FieldValue.serverTimestamp(),
  │     │   })
  │     └─ サブコレクション構造
  └─→ [Hive] hive_shared_list_repository.dart
        └─ sharedListBox.put(listId, list)
  ↓
[UI] ref.invalidate(groupSharedListsProvider)
  ↓ await ref.read(groupSharedListsProvider.future) ← 🔥 更新完了待機
  ↓
[Result] ドロップダウンに新リスト表示
```

**タイミング制御**:
```dart
// ❌ Wrong: UI再構築が早すぎる
ref.invalidate(groupSharedListsProvider);
// ドロップダウン再構築（新リストまだ含まれない）

// ✅ Correct: 更新完了を待つ
ref.invalidate(groupSharedListsProvider);
await ref.read(groupSharedListsProvider.future);  // 🔥 待機
// ドロップダウン再構築（新リスト含まれる）
```

#### 📖 Read（リスト取得）

##### 単一リスト取得

```
[UI] shared_list_page.dart (StreamBuilder)
  ↓ repository.watchSharedList(groupId, listId)
  ↓
[Repository] hybrid_shared_list_repository.dart
  ↓ watchSharedList() → Stream<SharedList?>
  ├─→ [Firestore] snapshots() リアルタイムストリーム
  │     ├─ doc('SharedGroups/{groupId}/sharedLists/{listId}')
  │     ├─ .snapshots() でリアルタイム監視
  │     └─ データ変更時に自動通知
  └─→ [Hive] 30秒ポーリング（オフライン時）
  ↓
[UI] StreamBuilderが自動更新
```

**StreamBuilder統合**:
```dart
StreamBuilder<SharedList?>(
  stream: repository.watchSharedList(groupId, listId),
  initialData: currentList,  // 初期データでちらつき防止
  builder: (context, snapshot) {
    final liveList = snapshot.data ?? currentList;
    // Firestoreの変更を即座に反映
  },
)
```

##### リスト一覧取得

```
[UI] shared_list_header_widget.dart
  ↓ ref.watch(groupSharedListsProvider)
  ↓
[Provider] shared_list_provider.dart
  ↓ groupSharedListsProvider(groupId)
  ↓
[Repository] hybrid_shared_list_repository.dart
  ↓ getSharedListsByGroup(groupId)
  ├─→ [Firestore]
  │     ├─ collection('SharedGroups/{groupId}/sharedLists').get()
  │     └─ Hiveにキャッシュ
  └─→ [Hive] フォールバック
  ↓
[Result] リスト一覧をドロップダウンに表示
```

#### ✏️ Update（リスト更新）

```
[UI] shared_list_header_widget.dart
  ↓ リスト名変更ダイアログ
  ↓ repository.updateSharedList()
  ↓
[Repository] hybrid_shared_list_repository.dart
  ↓ updateSharedList(updatedList)
  ├─→ [Firestore]
  │     ├─ doc(listId).update({
  │     │     listName: newName,
  │     │     updatedAt: FieldValue.serverTimestamp(),
  │     │   })
  │     └─ items Map は変更しない
  └─→ [Hive] sharedListBox.put(listId, updatedList)
  ↓
[Result] StreamBuilderが自動更新（invalidate不要）
```

#### 🗑️ Delete（リスト削除）

```
[UI] shared_list_header_widget.dart
  ↓ 削除確認ダイアログ
  ↓ repository.deleteSharedList(groupId, listId)
  ↓
[Repository] hybrid_shared_list_repository.dart
  ↓ deleteSharedList(groupId, listId)  // 🔥 groupId必須
  ├─→ [Firestore]
  │     ├─ doc('SharedGroups/{groupId}/sharedLists/{listId}').delete()
  │     └─ 直接パス指定（collection group query不要）
  └─→ [Hive] sharedListBox.delete(listId)
  ↓
[Result] リストとアイテム全削除
```

**2025-12-08修正**:
```dart
// ❌ Old: Collection group query（PERMISSION_DENIED）
await collectionGroup('sharedLists')
  .where('listId', isEqualTo: listId)
  .get();

// ✅ New: Direct path（権限問題なし）
await _collection(groupId).doc(listId).delete();
```

---

## SharedItem CRUD（差分同期）

### 📂 関連ファイル

#### Repository層（SharedListRepositoryと統合）
- **Abstract**: [`lib/datastore/shared_list_repository.dart`](../lib/datastore/shared_list_repository.dart)
  - `addSingleItem()` - 単一アイテム追加
  - `updateSingleItem()` - 単一アイテム更新
  - `removeSingleItem()` - 単一アイテム削除（論理削除）
- **Hybrid**: [`lib/datastore/hybrid_shared_list_repository.dart`](../lib/datastore/hybrid_shared_list_repository.dart) ⭐ **差分同期実装**
- **Firestore**: [`lib/datastore/firestore_shared_list_repository.dart`](../lib/datastore/firestore_shared_list_repository.dart) - Map形式差分更新

#### UI層
- **Page**: [`lib/pages/shared_list_page.dart`](../lib/pages/shared_list_page.dart)
  - `_SharedItemsListWidget` - アイテム一覧
  - `_SharedItemTile` - アイテム1件表示

### 🚀 差分同期アーキテクチャ（2025-12-18実装）

#### データ構造

```dart
// SharedList Model
class SharedList {
  final String listId;
  final String listName;
  final Map<String, SharedItem> items;  // ← Map形式

  // ゲッター
  List<SharedItem> get activeItems =>
    items.values.where((item) => !item.isDeleted).toList();
}

// SharedItem Model
class SharedItem {
  final String itemId;       // UUID v4
  final String name;
  final int quantity;
  final bool isPurchased;
  final bool isDeleted;      // 論理削除フラグ
  final DateTime? deletedAt;
}
```

#### Firestoreデータ形式

```json
{
  "listId": "list_abc123",
  "listName": "今日の買い物",
  "items": {
    "item_xyz789": {
      "itemId": "item_xyz789",
      "name": "牛乳",
      "quantity": 2,
      "isPurchased": false,
      "isDeleted": false
    },
    "item_def456": {
      "itemId": "item_def456",
      "name": "パン",
      "quantity": 1,
      "isPurchased": true,
      "isDeleted": false
    }
  },
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 🔄 CRUD ワークフロー（差分同期）

#### ✅ Create（アイテム追加）

```
[UI] shared_list_page.dart
  ↓ アイテム追加ダイアログ
  ↓ repository.addSingleItem(listId, newItem)
  ↓
[Repository] hybrid_shared_list_repository.dart
  ↓ addSingleItem(listId, item)  // 🔥 単一アイテムのみ送信
  ├─→ [Firestore] firestore_shared_list_repository.dart
  │     ├─ doc(listId).update({
  │     │     'items.${item.itemId}': {  // ← フィールド単位更新
  │     │       itemId: item.itemId,
  │     │       name: item.name,
  │     │       quantity: item.quantity,
  │     │       ...
  │     │     },
  │     │     'updatedAt': FieldValue.serverTimestamp(),
  │     │   })
  │     └─ データ転送量: ~500B（リスト全体 ~5KBの90%削減）
  └─→ [Hive] items Mapに追加してキャッシュ
  ↓
[Result] StreamBuilderが自動更新（1秒以内で他デバイスにも反映）
```

**パフォーマンス**:
| 項目 | Before（List全体） | After（差分同期） | 改善率 |
|------|-------------------|------------------|--------|
| データ転送量 | ~5KB（10アイテム） | ~500B（1アイテム） | 90%削減 |
| 同期速度 | 500ms | 50ms | 10倍高速 |

**コード例**:
```dart
// ❌ Old: リスト全体送信
final updatedItems = {...currentList.items, newItem.itemId: newItem};
await repository.updateSharedList(
  currentList.copyWith(items: updatedItems)
);

// ✅ New: 差分同期（単一アイテムのみ）
await repository.addSingleItem(currentList.listId, newItem);
```

#### 📖 Read（アイテム取得）

```
[UI] shared_list_page.dart (StreamBuilder)
  ↓ StreamBuilder<SharedList?>
  ↓ repository.watchSharedList(groupId, listId)
  ↓
[Repository] Firestoreリアルタイムストリーム
  ↓ snapshots() でアイテム変更監視
  ↓
[UI] snapshot.dataからactiveItemsを取得
  ↓ liveList.activeItems（isDeleted=falseのみ）
  ↓ ソート処理（未購入優先 → 期限順）
  ↓
[Result] ListView.builderで表示
```

**アクティブアイテムフィルタリング**:
```dart
// ✅ Correct: 論理削除されたアイテムを除外
final activeItems = sortItems(liveList.activeItems);
// activeItems = items.values.where((item) => !item.isDeleted)

// ❌ Wrong: 削除済みアイテムも表示
for (var item in liveList.items.values) { ... }
```

#### ✏️ Update（アイテム更新）

##### 購入状態トグル

```
[UI] shared_list_page.dart (_SharedItemTile)
  ↓ Checkboxタップ
  ↓ repository.updateSingleItem(listId, updatedItem)
  ↓
[Repository] hybrid_shared_list_repository.dart
  ↓ updateSingleItem(listId, item)  // 🔥 単一アイテムのみ送信
  ├─→ [Firestore]
  │     ├─ doc(listId).update({
  │     │     'items.${item.itemId}.isPurchased': true,
  │     │     'items.${item.itemId}.purchaseDate': Timestamp.now(),
  │     │     'updatedAt': FieldValue.serverTimestamp(),
  │     │   })
  │     └─ 変更フィールドのみ送信（~200B）
  └─→ [Hive] items Mapを更新
  ↓
[Result] StreamBuilderが即座に更新（他デバイスも1秒以内）
```

##### 定期購入リセット（バックグラウンド）

```
[Service] periodic_purchase_service.dart
  ↓ アプリ起動5秒後に自動実行
  ↓ _shouldResetItem() で判定
  │   ├─ isPurchased = true
  │   ├─ shoppingInterval > 0
  │   └─ purchaseDate + interval日 <= now
  ↓
[Repository] updateSingleItem() で差分更新
  ├─ isPurchased → false
  ├─ purchaseDate → null
  └─ Firestoreに反映
  ↓
[Result] 期限到来アイテムが未購入に戻る
```

#### 🗑️ Delete（アイテム削除）

```
[UI] shared_list_page.dart (_SharedItemTile)
  ↓ 削除ボタンタップ
  ↓ 削除確認ダイアログ
  ↓ repository.removeSingleItem(listId, itemId)
  ↓
[Repository] hybrid_shared_list_repository.dart
  ↓ removeSingleItem(listId, itemId)  // 🔥 論理削除
  ├─→ [Firestore]
  │     ├─ doc(listId).update({
  │     │     'items.${itemId}.isDeleted': true,
  │     │     'items.${itemId}.deletedAt': Timestamp.now(),
  │     │     'updatedAt': FieldValue.serverTimestamp(),
  │     │   })
  │     └─ 物理削除しない（復元可能性保持）
  └─→ [Hive] isDeletedフラグ更新
  ↓
[UI] activeItemsから除外され非表示
```

**クリーンアップ（30日以上前の削除済みアイテム）**:
```
[Service] list_cleanup_service.dart
  ↓ アプリ起動時に自動実行
  ↓ cleanupDeletedItems(listId, olderThanDays: 30)
  ↓
[Repository]
  ├─ isDeleted = true
  ├─ deletedAt < (now - 30日)
  └─ items Mapから物理削除
  ↓
[Result] 古い削除済みアイテムのみFirestoreから削除
```

---

## 関連ファイル一覧

### 📦 Model層
- [`lib/models/shared_group.dart`](../lib/models/shared_group.dart) - グループモデル
- [`lib/models/shared_list.dart`](../lib/models/shared_list.dart) - リストモデル（items: Map<String, SharedItem>）
- [`lib/models/shared_item.dart`](../lib/models/shared_item.dart) - アイテムモデル（含: itemId, isDeleted）

### 🗄️ Repository層

#### SharedGroup
- [`lib/datastore/shared_group_repository.dart`](../lib/datastore/shared_group_repository.dart) - Abstract
- [`lib/datastore/hybrid_purchase_group_repository.dart`](../lib/datastore/hybrid_purchase_group_repository.dart) - Hybrid (メイン)
- [`lib/datastore/firestore_purchase_group_repository.dart`](../lib/datastore/firestore_purchase_group_repository.dart) - Firestore実装
- [`lib/datastore/hive_shared_group_repository.dart`](../lib/datastore/hive_shared_group_repository.dart) - Hiveキャッシュ

#### SharedList
- [`lib/datastore/shared_list_repository.dart`](../lib/datastore/shared_list_repository.dart) - Abstract
- [`lib/datastore/hybrid_shared_list_repository.dart`](../lib/datastore/hybrid_shared_list_repository.dart) - Hybrid (メイン)
- [`lib/datastore/firestore_shared_list_repository.dart`](../lib/datastore/firestore_shared_list_repository.dart) - Firestore実装（差分同期）
- [`lib/datastore/hive_shared_list_repository.dart`](../lib/datastore/hive_shared_list_repository.dart) - Hiveキャッシュ

### 🎛️ Provider層

#### SharedGroup
- [`lib/providers/purchase_group_provider.dart`](../lib/providers/purchase_group_provider.dart)
  - `allGroupsProvider` - AsyncNotifierProvider<AllGroupsNotifier, List<SharedGroup>>
  - `selectedGroupProvider` - Provider<SharedGroup?>
  - `selectedGroupIdProvider` - StateNotifierProvider<SelectedGroupIdNotifier, String?>
  - `syncStatusProvider` - Provider<SyncStatus>

#### SharedList
- [`lib/providers/shared_list_provider.dart`](../lib/providers/shared_list_provider.dart)
  - `sharedListRepositoryProvider` - Provider<SharedListRepository>
  - `groupSharedListsProvider` - FutureProvider.family<List<SharedList>, String>
- [`lib/providers/current_list_provider.dart`](../lib/providers/current_list_provider.dart)
  - `currentListProvider` - StateNotifierProvider<CurrentListNotifier, SharedList?>

#### 認証
- [`lib/providers/auth_provider.dart`](../lib/providers/auth_provider.dart)
  - `authStateProvider` - StreamProvider<User?>

### 🖥️ UI層

#### Pages
- [`lib/pages/shared_group_page.dart`](../lib/pages/shared_group_page.dart) - グループ一覧画面
- [`lib/pages/shared_list_page.dart`](../lib/pages/shared_list_page.dart) - リスト＆アイテム画面
- [`lib/pages/group_member_management_page.dart`](../lib/pages/group_member_management_page.dart) - メンバー管理

#### Widgets - SharedGroup
- [`lib/widgets/group_list_widget.dart`](../lib/widgets/group_list_widget.dart) - グループ一覧カード
- [`lib/widgets/group_creation_with_copy_dialog.dart`](../lib/widgets/group_creation_with_copy_dialog.dart) - グループ作成ダイアログ
- [`lib/widgets/group_selector_widget.dart`](../lib/widgets/group_selector_widget.dart) - グループ選択ドロップダウン
- [`lib/widgets/group_invitation_dialog.dart`](../lib/widgets/group_invitation_dialog.dart) - QR招待管理

#### Widgets - SharedList
- [`lib/widgets/shared_list_header_widget.dart`](../lib/widgets/shared_list_header_widget.dart) - リスト選択ヘッダー

### 🛠️ Services
- [`lib/services/sync_service.dart`](../lib/services/sync_service.dart) - Firestore⇄Hive同期管理
- [`lib/services/periodic_purchase_service.dart`](../lib/services/periodic_purchase_service.dart) - 定期購入リセット
- [`lib/services/list_cleanup_service.dart`](../lib/services/list_cleanup_service.dart) - 削除アイテムクリーンアップ

### 🧪 Helper
- [`lib/utils/group_helpers.dart`](../lib/utils/group_helpers.dart) - `isDefaultGroup()` など

---

## データフロー図

### 全体アーキテクチャ

```
┌────────────────────────────────────────────────────────────┐
│                         UI Layer                           │
├────────────────────────────────────────────────────────────┤
│  Pages:                                                    │
│  ┌─────────────────┐  ┌─────────────────┐                │
│  │ SharedGroupPage │  │ SharedListPage  │                │
│  │                 │  │ (StreamBuilder) │                │
│  └────────┬────────┘  └────────┬────────┘                │
│           │                    │                          │
│  Widgets: ↓                    ↓                          │
│  ┌──────────────┐    ┌──────────────────┐                │
│  │ GroupList    │    │ SharedItemTile   │                │
│  │ GroupCreation│    │ AddItemDialog    │                │
│  └──────────────┘    └──────────────────┘                │
└────────────┬───────────────────┬──────────────────────────┘
             │                   │
             ↓                   ↓
┌────────────────────────────────────────────────────────────┐
│                       Provider Layer                       │
├────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐                │
│  │ allGroupsProvider│  │ currentListProvider│             │
│  │ (AsyncNotifier) │  │ (StateNotifier) │                │
│  └────────┬────────┘  └────────┬────────┘                │
│           │                    │                          │
│  ┌────────────────────────────────────────┐               │
│  │   sharedListRepositoryProvider         │               │
│  │   (Hybrid Repository)                  │               │
│  └────────┬───────────────────────────────┘               │
└───────────┼────────────────────────────────────────────────┘
            │
            ↓
┌────────────────────────────────────────────────────────────┐
│                    Repository Layer                        │
├────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────┐          │
│  │  HybridSharedGroupRepository                 │          │
│  │  HybridSharedListRepository                  │          │
│  │                                              │          │
│  │  if (prod && firestore != null) {           │          │
│  │    ┌───────────────┐                        │          │
│  │    │ Firestore操作 │                        │          │
│  │    └───────┬───────┘                        │          │
│  │            ↓                                 │          │
│  │    ┌───────────────┐                        │          │
│  │    │ Hiveキャッシュ │                        │          │
│  │    └───────────────┘                        │          │
│  │  } else {                                   │          │
│  │    ┌───────────────┐                        │          │
│  │    │ Hive直接操作  │                        │          │
│  │    └───────────────┘                        │          │
│  │  }                                          │          │
│  └──────────────────────────────────────────────┘          │
└────────────┬───────────────────────────────────────────────┘
             │
    ┌────────┴────────┐
    ↓                 ↓
┌─────────────┐  ┌─────────────┐
│  Firestore  │  │    Hive     │
│  (Online)   │  │  (Cache)    │
└─────────────┘  └─────────────┘
```

### SharedItem差分同期フロー

```
[アイテム追加]
User Tap "追加" Button
  ↓
SharedListPage._showAddItemDialog()
  ↓
repository.addSingleItem(listId, newItem)
  ↓
HybridSharedListRepository.addSingleItem()
  ├─→ [Firestore]
  │   FirestoreSharedListRepository.addSingleItem()
  │     ├─ doc(listId).update({
  │     │   'items.${newItem.itemId}': {
  │     │     itemId: "item_xyz789",
  │     │     name: "牛乳",
  │     │     quantity: 2,
  │     │     isPurchased: false,
  │     │     isDeleted: false,
  │     │     ...
  │     │   }
  │     │ })
  │     └─ 送信データ: ~500B（単一アイテムのみ）
  │
  └─→ [Hive Cache]
      HiveSharedListRepository
        ├─ 既存リストを取得
        ├─ items Mapに新アイテム追加
        └─ sharedListBox.put(listId, updatedList)
  ↓
StreamBuilder<SharedList?> が自動検知
  ↓
_SharedItemsListWidget 再構築
  ↓
ListView に新アイテム表示（1秒以内）
  ↓
[他デバイス]
  Firestore snapshots() が変更検知
    ↓
  StreamBuilder 自動更新
    ↓
  他デバイスにも即座に反映
```

---

## 🎯 ベストプラクティス

### ✅ DO

1. **Firestore-First原則を守る**
   ```dart
   // ✅ Correct
   if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
     final result = await _firestoreRepo!.operation();
     await _hiveRepo.cache(result);
     return result;
   }
   ```

2. **差分同期メソッドを使う**
   ```dart
   // ✅ Correct: 単一アイテム送信
   await repository.addSingleItem(listId, newItem);

   // ❌ Wrong: リスト全体送信
   await repository.updateSharedList(listWithAllItems);
   ```

3. **activeItemsゲッターを使う**
   ```dart
   // ✅ Correct: 論理削除除外
   final items = liveList.activeItems;

   // ❌ Wrong: 削除済みも含む
   final items = liveList.items.values.toList();
   ```

4. **StreamBuilderでリアルタイム同期**
   ```dart
   // ✅ Correct: 自動更新
   StreamBuilder<SharedList?>(
     stream: repository.watchSharedList(groupId, listId),
     initialData: currentList,
     builder: (context, snapshot) { ... }
   )
   ```

5. **Providerの更新完了を待つ**
   ```dart
   // ✅ Correct: 更新完了待機
   ref.invalidate(groupSharedListsProvider);
   await ref.read(groupSharedListsProvider.future);
   ```

### ❌ DON'T

1. **Hiveを優先しない**
   ```dart
   // ❌ Wrong: Hive優先
   final hiveData = await _hiveRepo.getData();
   if (hiveData != null) return hiveData;
   ```

2. **リスト全体を送信しない**
   ```dart
   // ❌ Wrong: 5KB送信
   await repository.updateSharedList(listWithAllItems);
   ```

3. **Map直接変更しない**
   ```dart
   // ❌ Wrong: 直接変更
   currentList.items[itemId] = updatedItem;

   // ✅ Correct: copyWith使用
   await repository.updateSingleItem(listId, updatedItem);
   ```

4. **StreamBuilderで invalidate しない**
   ```dart
   // ❌ Wrong: 不要な invalidate
   await repository.addSingleItem(listId, item);
   ref.invalidate(currentListProvider);  // StreamBuilderが自動更新
   ```

---

## 📊 パフォーマンス指標

| 項目 | Before | After | 改善率 |
|------|--------|-------|--------|
| **アイテム追加** | リスト全体送信 (~5KB) | 単一アイテム送信 (~500B) | 90%削減 |
| **同期速度** | 500ms | < 1秒 | - |
| **ネットワーク効率** | 低（全体送信） | 高（差分のみ） | 90%向上 |
| **リアルタイム性** | 手動invalidate | 自動Stream更新 | 即座 |

---

## 🔧 トラブルシューティング

### Issue 1: UIが更新されない

**症状**: アイテム追加後、リストが更新されない

**原因**: StreamBuilderの使用忘れ or invalidate不要なのに使用

**解決**:
```dart
// ✅ Correct: StreamBuilderを使用
StreamBuilder<SharedList?>(
  stream: repository.watchSharedList(groupId, listId),
  builder: (context, snapshot) {
    final liveList = snapshot.data;
    // 自動更新される
  },
)
```

### Issue 2: データ転送量が多い

**症状**: アイテム1件追加で5KB送信

**原因**: `updateSharedList()` を使用している

**解決**:
```dart
// ❌ Wrong
await repository.updateSharedList(list.copyWith(items: {...}));

// ✅ Correct
await repository.addSingleItem(listId, newItem);
```

### Issue 3: 削除済みアイテムが表示される

**症状**: 削除したアイテムが画面に残る

**原因**: `activeItems` ゲッター未使用

**解決**:
```dart
// ❌ Wrong
final items = liveList.items.values.toList();

// ✅ Correct
final items = liveList.activeItems;  // isDeleted除外
```

---

## 📝 更新履歴

- **2025-12-23**: 初版作成（CRUD ワークフロー資料）
- **2025-12-18**: SharedItem 差分同期実装完了
- **2025-12-18**: SharedList CRUD Firestore-first 実装
- **2025-12-18**: SharedGroup CRUD Firestore-first 実装
- **2025-11-22**: StreamBuilder リアルタイム同期実装

---

## 参考リンク

- [copilot-instructions.md](../copilot-instructions.md) - プロジェクト全体のアーキテクチャ
- [daily_report_20251218.md](daily_report_20251218.md) - Firestore-First 実装日報
- [daily_report_20251219.md](daily_report_20251219.md) - リアルタイム同期検証日報
