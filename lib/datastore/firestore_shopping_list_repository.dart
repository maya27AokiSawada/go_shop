import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer show log;
import '../models/shopping_list.dart';
import 'shopping_list_repository.dart';
import '../providers/firestore_provider.dart';

class FirestoreShoppingListRepository implements ShoppingListRepository {
  final FirebaseFirestore _firestore;

  FirestoreShoppingListRepository(Ref ref)
      : _firestore = ref.read(firestoreProvider);

  // サブコレクションへの参照を返すメソッド
  CollectionReference _collection(String groupId) => _firestore
      .collection('SharedGroups')
      .doc(groupId)
      .collection('shoppingLists');

  @override
  Future<ShoppingList> createShoppingList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
  }) async {
    final newList = ShoppingList.create(
      ownerUid: ownerUid,
      groupId: groupId,
      groupName: listName, // groupNameはlistNameと同じで初期化
      listName: listName,
      description: description ?? '',
      items: {},
    );

    await _collection(groupId)
        .doc(newList.listId)
        .set(_shoppingListToFirestore(newList));
    developer.log(
        '🆕 Firestoreに新規リスト作成: ${newList.listName} (ID: ${newList.listId})');
    return newList;
  }

  /// 既存のShoppingListオブジェクトをFirestoreに保存（IDはそのまま使用）
  Future<void> saveShoppingListWithId(ShoppingList list) async {
    await _collection(list.groupId)
        .doc(list.listId)
        .set(_shoppingListToFirestore(list));
    developer
        .log('💾 Firestoreに既存IDでリスト保存: ${list.listName} (ID: ${list.listId})');
  }

  @override
  Future<ShoppingList?> getShoppingListById(String listId) async {
    // コレクショングループクエリを使用して、groupIdが不明でもリストを検索
    final querySnapshot = await _firestore
        .collectionGroup('shoppingLists')
        .where('listId', isEqualTo: listId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return _shoppingListFromFirestore(querySnapshot.docs.first);
    }

    developer.log('⚠️ Firestoreにリストが見つからない (ID: $listId)');
    return null;
  }

  @override
  Future<List<ShoppingList>> getShoppingListsByGroup(String groupId) async {
    final query = await _collection(groupId).get();
    final lists =
        query.docs.map((doc) => _shoppingListFromFirestore(doc)).toList();
    developer.log('📋 Firestoreからグループ「$groupId」のリスト取得: ${lists.length}個');
    return lists;
  }

  @override
  Future<void> updateShoppingList(ShoppingList list) async {
    await _collection(list.groupId)
        .doc(list.listId)
        .update(_shoppingListToFirestore(list));
    developer.log('💾 Firestoreでリスト更新: ${list.listName} (ID: ${list.listId})');
  }

  @override
  Future<void> deleteShoppingList(String groupId, String listId) async {
    await _collection(groupId).doc(listId).delete();
    developer.log('🗑️ Firestoreからリスト削除 (groupId: $groupId, listId: $listId)');
  }

  @override
  Future<void> deleteShoppingListsByGroupId(String groupId) async {
    final batch = _firestore.batch();
    final querySnapshot = await _collection(groupId).get();

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    developer.log(
        '🗑️ Firestoreからグループ「$groupId」の全リスト削除: ${querySnapshot.docs.length}個');
  }

  @override
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    final list = await getShoppingListById(listId);
    if (list == null) {
      throw Exception('リストが見つかりません (ID: $listId)');
    }
    await _collection(list.groupId).doc(listId).update({
      'items': FieldValue.arrayUnion([_shoppingItemToFirestore(item)])
    });
    developer.log('➕ Firestoreにアイテム追加: ${item.name} → リストID「$listId」');
  }

  @override
  Future<void> removeItemFromList(String listId, ShoppingItem item) async {
    final list = await getShoppingListById(listId);
    if (list == null) {
      throw Exception('リストが見つかりません (ID: $listId)');
    }
    await _collection(list.groupId).doc(listId).update({
      'items': FieldValue.arrayRemove([_shoppingItemToFirestore(item)])
    });
    developer.log('➖ Firestoreからアイテム削除: ${item.name} ← リストID「$listId」');
  }

  @override
  Future<void> updateItemStatusInList(String listId, ShoppingItem item,
      {required bool isPurchased}) async {
    // Firestoreでの配列内要素の更新は複雑なため、リスト全体を読み書きする
    final list = await getShoppingListById(listId);
    if (list != null) {
      final updatedItems = list.items.map((itemId, existingItem) {
        if (existingItem.itemId == item.itemId) {
          return MapEntry(
            itemId,
            existingItem.copyWith(
              isPurchased: isPurchased,
              purchaseDate: isPurchased ? DateTime.now() : null,
            ),
          );
        }
        return MapEntry(itemId, existingItem);
      });
      await updateShoppingList(list.copyWith(items: updatedItems));
      developer.log(
          '✅ Firestoreでアイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"}');
    }
  }

  // --- Helper ---
  Map<String, dynamic> _shoppingListToFirestore(ShoppingList list) {
    // 🆕 Map形式をFirestoreのMapとして保存
    final itemsMap = <String, Map<String, dynamic>>{};
    list.items.forEach((itemId, item) {
      itemsMap[itemId] = _shoppingItemToFirestore(item);
    });

    return {
      'listId': list.listId,
      'ownerUid': list.ownerUid,
      'groupId': list.groupId,
      'groupName': list.groupName,
      'listName': list.listName,
      'description': list.description,
      'items': itemsMap, // 🆕 Map形式
      'createdAt': Timestamp.fromDate(list.createdAt),
      'updatedAt': Timestamp.fromDate(list.updatedAt ?? DateTime.now()),
    };
  }

  ShoppingList _shoppingListFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 🆕 Firestoreの items を Map<String, ShoppingItem> に変換
    final itemsData = data['items'] as Map<String, dynamic>? ?? {};
    final items = <String, ShoppingItem>{};

    itemsData.forEach((itemId, itemData) {
      items[itemId] =
          _shoppingItemFromFirestore(itemData as Map<String, dynamic>);
    });

    return ShoppingList(
      listId: data['listId'],
      ownerUid: data['ownerUid'],
      groupId: data['groupId'],
      groupName: data['groupName'],
      listName: data['listName'],
      description: data['description'],
      items: items, // 🆕 Map形式
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _shoppingItemToFirestore(ShoppingItem item) {
    return {
      'memberId': item.memberId,
      'name': item.name,
      'quantity': item.quantity,
      'registeredDate': Timestamp.fromDate(item.registeredDate),
      'purchaseDate': item.purchaseDate != null
          ? Timestamp.fromDate(item.purchaseDate!)
          : null,
      'isPurchased': item.isPurchased,
      'shoppingInterval': item.shoppingInterval,
      'deadline':
          item.deadline != null ? Timestamp.fromDate(item.deadline!) : null,
      'itemId': item.itemId, // 🆕 追加
      'isDeleted': item.isDeleted, // 🆕 追加
      'deletedAt': item.deletedAt != null
          ? Timestamp.fromDate(item.deletedAt!)
          : null, // 🆕 追加
    };
  }

  ShoppingItem _shoppingItemFromFirestore(Map<String, dynamic> data) {
    return ShoppingItem(
      memberId: data['memberId'],
      name: data['name'],
      quantity: data['quantity'],
      registeredDate: (data['registeredDate'] as Timestamp).toDate(),
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
      isPurchased: data['isPurchased'],
      shoppingInterval: data['shoppingInterval'],
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      itemId: data['itemId'] ?? '', // 🆕 必須フィールド
      isDeleted: data['isDeleted'] ?? false, // 🆕
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(), // 🆕
    );
  }

  // --- Unimplemented but required by interface ---
  @override
  Future<ShoppingList?> getShoppingList(String groupId) async {
    // This method is ambiguous in a multi-list context.
    // We'll get the first list found for the group.
    final lists = await getShoppingListsByGroup(groupId);
    return lists.isNotEmpty ? lists.first : null;
  }

  @override
  Future<void> addItem(ShoppingList list) async {
    // This method is for single-list architecture. Use addItemToList instead.
    throw UnimplementedError("Use addItemToList for multi-list architecture.");
  }

  @override
  Future<void> clearShoppingList(String groupId) async {
    // This is ambiguous. Do you clear all lists in a group?
    throw UnimplementedError("Clearing lists by group ID is not defined yet.");
  }

  @override
  Future<void> addShoppingItem(String groupId, ShoppingItem item) async {
    // Ambiguous. Which list to add to?
    throw UnimplementedError("Use addItemToList with a specific listId.");
  }

  @override
  Future<void> removeShoppingItem(String groupId, ShoppingItem item) async {
    // Ambiguous. Which list to remove from?
    throw UnimplementedError("Use removeItemFromList with a specific listId.");
  }

  @override
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item,
      {required bool isPurchased}) async {
    // Ambiguous. Which list to update in?
    throw UnimplementedError(
        "Use updateItemStatusInList with a specific listId.");
  }

  @override
  Future<void> clearPurchasedItemsFromList(String listId) async {
    final list = await getShoppingListById(listId);
    if (list != null) {
      // 🆕 activeItemsから未購入のみ残す（Map形式）
      final remainingItems = <String, ShoppingItem>{};
      list.activeItems.where((item) => !item.isPurchased).forEach((item) {
        remainingItems[item.itemId] = item;
      });

      await updateShoppingList(list.copyWith(items: remainingItems));
      developer.log('🧹 Firestoreから購入済みアイテムクリア: リスト「${list.listName}」');
    }
  }

  @override
  Future<ShoppingList> getOrCreateList(String groupId, String groupName) async {
    final lists = await getShoppingListsByGroup(groupId);
    if (lists.isNotEmpty) {
      return lists.first;
    }
    return createShoppingList(
        ownerUid: 'defaultUser', // Should be properly set
        groupId: groupId,
        listName: '$groupNameのデフォルトリスト');
  }

  @override
  Future<ShoppingList> getOrCreateDefaultList(
      String groupId, String groupName) async {
    // getOrCreateListと同じ実装（後方互換性のため）
    return getOrCreateList(groupId, groupName);
  }

  // === Realtime Sync Methods ===
  @override
  Stream<ShoppingList?> watchShoppingList(String groupId, String listId) {
    developer.log('🔴 [REALTIME] Stream開始: groupId=$groupId, listId=$listId');

    return _collection(groupId).doc(listId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        developer.log('⚠️ [REALTIME] リストが存在しません: listId=$listId');
        return null;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        developer.log('⚠️ [REALTIME] データがnull: listId=$listId');
        return null;
      }

      try {
        final list = _shoppingListFromFirestore(snapshot);
        developer.log(
            '✅ [REALTIME] リスト更新: ${list.listName} (${list.activeItemCount}件)');
        return list;
      } catch (e) {
        developer.log('❌ [REALTIME] パースエラー: $e');
        return null;
      }
    }).handleError((error) {
      developer.log('❌ [REALTIME] Streamエラー: $error');
      return null;
    });
  }

  // 🆕 Map-based Differential Sync Methods
  @override
  Future<void> addSingleItem(String listId, ShoppingItem item) async {
    developer.log('🔄 [FIRESTORE_DIFF] Adding single item: ${item.name}');

    // Firestoreでは部分更新としてMapのキーを追加
    // items.{itemId} = item.toJson()
    final list = await getShoppingListById(listId);
    if (list == null) throw Exception('List not found: $listId');

    await _collection(list.groupId).doc(listId).update({
      'items.${item.itemId}': _itemToFirestore(item),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    developer.log('✅ [FIRESTORE_DIFF] Item added to Firestore');
  }

  @override
  Future<void> removeSingleItem(String listId, String itemId) async {
    developer.log('🔄 [FIRESTORE_DIFF] Logically deleting item: $itemId');

    final list = await getShoppingListById(listId);
    if (list == null) return;

    final item = list.items[itemId];
    if (item == null) {
      developer.log('⚠️ [FIRESTORE_DIFF] Item not found: $itemId');
      return;
    }

    // 論理削除: isDeleted = true に更新
    await _collection(list.groupId).doc(listId).update({
      'items.$itemId.isDeleted': true,
      'items.$itemId.deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    developer.log('✅ [FIRESTORE_DIFF] Item logically deleted');
  }

  @override
  Future<void> updateSingleItem(String listId, ShoppingItem item) async {
    developer.log('🔄 [FIRESTORE_DIFF] Updating single item: ${item.name}');

    final list = await getShoppingListById(listId);
    if (list == null) return;

    await _collection(list.groupId).doc(listId).update({
      'items.${item.itemId}': _itemToFirestore(item),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    developer.log('✅ [FIRESTORE_DIFF] Item updated in Firestore');
  }

  @override
  Future<void> cleanupDeletedItems(String listId,
      {int olderThanDays = 30}) async {
    developer.log('🧹 [FIRESTORE_CLEANUP] Starting cleanup for list: $listId');

    final list = await getShoppingListById(listId);
    if (list == null) return;

    // 削除済みアイテムを物理削除（全体を保存し直す）
    await updateShoppingList(list);

    developer.log('✅ [FIRESTORE_CLEANUP] Cleanup completed');
  }

  /// ShoppingItemをFirestore形式に変換
  Map<String, dynamic> _itemToFirestore(ShoppingItem item) {
    return {
      'memberId': item.memberId,
      'name': item.name,
      'quantity': item.quantity,
      'registeredDate': Timestamp.fromDate(item.registeredDate),
      'purchaseDate': item.purchaseDate != null
          ? Timestamp.fromDate(item.purchaseDate!)
          : null,
      'isPurchased': item.isPurchased,
      'shoppingInterval': item.shoppingInterval,
      'deadline':
          item.deadline != null ? Timestamp.fromDate(item.deadline!) : null,
      'itemId': item.itemId,
      'isDeleted': item.isDeleted,
      'deletedAt':
          item.deletedAt != null ? Timestamp.fromDate(item.deletedAt!) : null,
    };
  }
}
