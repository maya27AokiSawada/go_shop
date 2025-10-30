import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../models/shopping_list.dart';
import 'shopping_list_repository.dart';
import '../providers/firestore_provider.dart';

class FirestoreShoppingListRepository implements ShoppingListRepository {
  final FirebaseFirestore _firestore;

  FirestoreShoppingListRepository(Ref ref)
      : _firestore = ref.read(firestoreProvider);

  CollectionReference get _collection => _firestore.collection('shoppingLists');

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
      items: [],
    );

    await _collection
        .doc(newList.listId)
        .set(_shoppingListToFirestore(newList));
    developer.log(
        '🆕 Firestoreに新規リスト作成: ${newList.listName} (ID: ${newList.listId})');
    return newList;
  }

  @override
  Future<ShoppingList?> getShoppingListById(String listId) async {
    final doc = await _collection.doc(listId).get();
    if (doc.exists) {
      return _shoppingListFromFirestore(doc);
    }
    developer.log('⚠️ Firestoreにリストが見つからない (ID: $listId)');
    return null;
  }

  @override
  Future<List<ShoppingList>> getShoppingListsByGroup(String groupId) async {
    final query = await _collection.where('groupId', isEqualTo: groupId).get();
    final lists =
        query.docs.map((doc) => _shoppingListFromFirestore(doc)).toList();
    developer.log('📋 Firestoreからグループ「$groupId」のリスト取得: ${lists.length}個');
    return lists;
  }

  @override
  Future<void> updateShoppingList(ShoppingList list) async {
    await _collection.doc(list.listId).update(_shoppingListToFirestore(list));
    developer.log('💾 Firestoreでリスト更新: ${list.listName} (ID: ${list.listId})');
  }

  @override
  Future<void> deleteShoppingList(String listId) async {
    await _collection.doc(listId).delete();
    developer.log('🗑️ Firestoreからリスト削除 (ID: $listId)');
  }

  @override
  Future<void> deleteShoppingListsByGroupId(String groupId) async {
    final batch = _firestore.batch();
    final querySnapshot =
        await _collection.where('groupId', isEqualTo: groupId).get();

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    developer.log(
        '🗑️ Firestoreからグループ「$groupId」の全リスト削除: ${querySnapshot.docs.length}個');
  }

  @override
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    await _collection.doc(listId).update({
      'items': FieldValue.arrayUnion([_shoppingItemToFirestore(item)])
    });
    developer.log('➕ Firestoreにアイテム追加: ${item.name} → リストID「$listId」');
  }

  @override
  Future<void> removeItemFromList(String listId, ShoppingItem item) async {
    await _collection.doc(listId).update({
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
      final updatedItems = list.items.map((existingItem) {
        if (existingItem.name == item.name &&
            existingItem.memberId == item.memberId &&
            existingItem.registeredDate == item.registeredDate) {
          return existingItem.copyWith(
            isPurchased: isPurchased,
            purchaseDate: isPurchased ? DateTime.now() : null,
          );
        }
        return existingItem;
      }).toList();
      await updateShoppingList(list.copyWith(items: updatedItems));
      developer.log(
          '✅ Firestoreでアイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"}');
    }
  }

  // --- Helper ---
  Map<String, dynamic> _shoppingListToFirestore(ShoppingList list) {
    return {
      'listId': list.listId,
      'ownerUid': list.ownerUid,
      'groupId': list.groupId,
      'groupName': list.groupName,
      'listName': list.listName,
      'description': list.description,
      'items':
          list.items.map((item) => _shoppingItemToFirestore(item)).toList(),
      'createdAt': Timestamp.fromDate(list.createdAt),
      'updatedAt': Timestamp.fromDate(list.updatedAt ?? DateTime.now()),
    };
  }

  ShoppingList _shoppingListFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingList(
      listId: data['listId'],
      ownerUid: data['ownerUid'],
      groupId: data['groupId'],
      groupName: data['groupName'],
      listName: data['listName'],
      description: data['description'],
      items: (data['items'] as List<dynamic>)
          .map((itemData) =>
              _shoppingItemFromFirestore(itemData as Map<String, dynamic>))
          .toList(),
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
      final updatedItems =
          list.items.where((item) => !item.isPurchased).toList();
      await updateShoppingList(list.copyWith(items: updatedItems));
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
}
