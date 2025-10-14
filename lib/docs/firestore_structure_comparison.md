// lib/docs/firestore_structure_comparison.md

# Firestore Structure Comparison Analysis

## 現在の構造: フラット構造
```
/users/{ownerUid}/
  ├── purchaseGroups/{groupId}
  └── shoppingLists/{listId}
```

### メリット
1. **クエリ効率**: 全ショッピングリストを一度に取得可能
2. **クロスグループ操作**: 複数グループのリストを横断的に操作
3. **シンプルな参照**: listIdだけでダイレクトアクセス
4. **スケーラビリティ**: グループ数が増えてもクエリ複雑度が変わらない
5. **移行コスト**: 既存のマルチリスト実装と互換性が高い

### デメリット
1. **論理的結合**: グループとリストの関係が間接的
2. **孤児リスト**: グループ削除時にリストが残る可能性
3. **権限管理**: グループベースのアクセス制御が複雑

## 提案構造: ネスト構造
```
/users/{ownerUid}/purchaseGroups/{groupId}/
  ├── (group metadata)
  └── shoppingLists/{listId}
```

### メリット
1. **論理的構造**: グループとリストの関係が明確
2. **データ整合性**: グループ削除時に自動的にリストも削除
3. **権限管理**: グループレベルでのアクセス制御が自然
4. **データ局所性**: 関連データが物理的に近い

### デメリット
1. **クエリ複雑度**: 複数グループのリストを取得する際に複数クエリが必要
2. **パフォーマンス**: グループ数×リスト数のクエリコスト
3. **移行コスト**: 既存実装の大幅な変更が必要
4. **柔軟性**: リストをグループ間で移動するのが困難

## 具体的な操作例

### 1. 全リスト取得
**フラット構造**:
```dart
// 1回のクエリで全リスト取得
final allLists = await FirestoreCollections
    .getUserShoppingLists(ownerUid).get();
```

**ネスト構造**:
```dart
// グループごとに個別クエリが必要
final allLists = <ShoppingList>[];
for (final group in groups) {
  final groupLists = await FirestoreCollections
      .getUserPurchaseGroups(ownerUid)
      .doc(group.groupId)
      .collection('shoppingLists')
      .get();
  allLists.addAll(groupLists.docs.map(...));
}
```

### 2. グループ削除
**フラット構造**:
```dart
// 手動でリストのクリーンアップが必要
await group.reference.delete();
// 関連するshoppingListIdsのリストも削除
for (final listId in group.shoppingListIds) {
  await FirestoreCollections.getShoppingListDoc(ownerUid, listId).delete();
}
```

**ネスト構造**:
```dart
// グループ削除で自動的にサブコレクションも削除される
await group.reference.delete(); // 自動的にshoppingListsも削除
```

### 3. 権限管理
**フラット構造**:
```dart
// リストごとにグループIDを確認してアクセス権限をチェック
final list = await getShoppingListDoc(ownerUid, listId).get();
final groupId = list.data()['groupId'];
final hasAccess = await checkGroupAccess(ownerUid, groupId, userId);
```

**ネスト構造**:
```dart
// パスから自動的にグループIDが分かり、権限チェックが簡単
final hasAccess = await checkGroupAccess(ownerUid, groupId, userId);
if (hasAccess) {
  final list = await getGroupShoppingList(ownerUid, groupId, listId).get();
}
```

## パフォーマンス比較

### 読み取り操作
| 操作 | フラット構造 | ネスト構造 |
|------|-------------|------------|
| 全リスト取得 | 1クエリ | N×クエリ (Nはグループ数) |
| 特定リスト取得 | 1クエリ | 1クエリ |
| グループ内リスト | 1クエリ + フィルタ | 1クエリ |

### 書き込み操作
| 操作 | フラット構造 | ネスト構造 |
|------|-------------|------------|
| リスト作成 | 2操作 (リスト + グループ更新) | 1操作 |
| グループ削除 | N+1操作 | 1操作 (自動削除) |
| リスト移動 | 3操作 | 削除+作成 |

## 推奨案: フラット構造を維持

### 理由
1. **既存実装との互換性**: 現在のマルチリスト実装が活用可能
2. **Go Shopの特性**: 家族・小グループ向けで、グループ数は少ない想定
3. **UI要件**: 複数グループのリストを横断的に表示する可能性
4. **開発効率**: 既存コードベースを最大限活用

### 改善提案
フラット構造の欠点を以下で補完:

```dart
// データ整合性の確保
class ShoppingListCleanupService {
  /// 孤児リストを定期的にクリーンアップ
  Future<void> cleanupOrphanedLists(String ownerUid) async {
    final allLists = await FirestoreCollections.getUserShoppingLists(ownerUid).get();
    final allGroups = await FirestoreCollections.getUserPurchaseGroups(ownerUid).get();
    
    final validGroupIds = allGroups.docs.map((doc) => doc.id).toSet();
    
    for (final listDoc in allLists.docs) {
      final list = ShoppingList.fromFirestoreData(listDoc.data());
      if (!validGroupIds.contains(list.groupId)) {
        await listDoc.reference.delete();
        print('Orphaned list deleted: ${list.listId}');
      }
    }
  }
}

// 権限管理の簡化
class FirestorePermissionService {
  Future<bool> canAccessShoppingList(String ownerUid, String listId, String userId) async {
    final listDoc = await FirestoreCollections.getShoppingListDoc(ownerUid, listId).get();
    if (!listDoc.exists) return false;
    
    final list = ShoppingList.fromFirestoreData(listDoc.data()!);
    return await canAccessGroup(ownerUid, list.groupId, userId);
  }
}
```

## 結論
Go Shopの用途（家族・小グループ）とパフォーマンス要件を考慮すると、**フラット構造を維持することを推奨**します。必要に応じて上記の改善提案を実装してデメリットを補完します。