import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer show log;
import '../models/shared_list.dart';
import 'shared_list_repository.dart';
import '../providers/firestore_provider.dart';

class FirestoreSharedListRepository implements SharedListRepository {
  final FirebaseFirestore _firestore;

  FirestoreSharedListRepository(Ref ref)
      : _firestore = ref.read(firestoreProvider);

  // サブコレクションへの参照を返すメソッド
  CollectionReference _collection(String groupId) => _firestore
      .collection('SharedGroups')
      .doc(groupId)
      .collection('sharedLists');

  @override
  Future<SharedList> createSharedList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
  }) async {
    final newList = SharedList.create(
      ownerUid: ownerUid,
      groupId: groupId,
      groupName: listName, // groupNameはlistNameと同じで初期化
      listName: listName,
      description: description ?? '',
      items: {},
    );

    try {
      // Windows版Firestoreのスレッド問題を回避
      await Future.microtask(() async {
        await _collection(groupId)
            .doc(newList.listId)
            .set(_sharedListToFirestore(newList));
      });
      developer.log(
          '🆕 Firestoreに新規リスト作成: ${newList.listName} (ID: ${newList.listId})');
      return newList;
    } catch (e) {
      developer.log('❌ Firestoreへのリスト作成失敗: $e');
      rethrow;
    }
  }

  /// 既存のSharedListオブジェクトをFirestoreに保存（IDはそのまま使用）
  Future<void> saveSharedListWithId(SharedList list) async {
    // Windows版Firestoreのスレッド問題を回避
    await Future.microtask(() async {
      await _collection(list.groupId)
          .doc(list.listId)
          .set(_sharedListToFirestore(list));
    });
    developer
        .log('💾 Firestoreに既存IDでリスト保存: ${list.listName} (ID: ${list.listId})');
  }

  @override
  Future<SharedList?> getSharedListById(String listId) async {
    // コレクショングループクエリを使用して、groupIdが不明でもリストを検索
    final querySnapshot = await _firestore
        .collectionGroup('sharedLists')
        .where('listId', isEqualTo: listId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return _sharedListFromFirestore(querySnapshot.docs.first);
    }

    developer.log('⚠️ Firestoreにリストが見つからない (ID: $listId)');
    return null;
  }

  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) async {
    final query = await _collection(groupId).get();
    final lists =
        query.docs.map((doc) => _sharedListFromFirestore(doc)).toList();
    developer.log('📋 Firestoreからグループ「$groupId」のリスト取得: ${lists.length}個');
    return lists;
  }

  @override
  Future<void> updateSharedList(SharedList list) async {
    // Windows版Firestoreのスレッド問題を回避
    await Future.microtask(() async {
      await _collection(list.groupId)
          .doc(list.listId)
          .update(_sharedListToFirestore(list));
    });
    developer.log('💾 Firestoreでリスト更新: ${list.listName} (ID: ${list.listId})');
  }

  @override
  Future<void> deleteSharedList(String groupId, String listId) async {
    // Windows版Firestoreのスレッド問題を回避
    await Future.microtask(() async {
      await _collection(groupId).doc(listId).delete();
    });
    developer.log('🗑️ Firestoreからリスト削除 (groupId: $groupId, listId: $listId)');
  }

  @override
  Future<void> deleteSharedListsByGroupId(String groupId) async {
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
  Future<void> addItemToList(String listId, SharedItem item) async {
    final list = await getSharedListById(listId);
    if (list == null) {
      throw Exception('リストが見つかりません (ID: $listId)');
    }
    await _collection(list.groupId).doc(listId).update({
      'items': FieldValue.arrayUnion([_sharedItemToFirestore(item)])
    });
    developer.log('➕ Firestoreにアイテム追加: ${item.name} → リストID「$listId」');
  }

  @override
  Future<void> removeItemFromList(String listId, SharedItem item) async {
    final list = await getSharedListById(listId);
    if (list == null) {
      throw Exception('リストが見つかりません (ID: $listId)');
    }
    await _collection(list.groupId).doc(listId).update({
      'items': FieldValue.arrayRemove([_sharedItemToFirestore(item)])
    });
    developer.log('➖ Firestoreからアイテム削除: ${item.name} ← リストID「$listId」');
  }

  @override
  Future<void> updateItemStatusInList(String listId, SharedItem item,
      {required bool isPurchased}) async {
    // Firestoreでの配列内要素の更新は複雑なため、リスト全体を読み書きする
    final list = await getSharedListById(listId);
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
      await updateSharedList(list.copyWith(items: updatedItems));
      developer.log(
          '✅ Firestoreでアイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"}');
    }
  }

  // --- Helper ---
  Map<String, dynamic> _sharedListToFirestore(SharedList list) {
    // 🆕 Map形式をFirestoreのMapとして保存
    final itemsMap = <String, Map<String, dynamic>>{};
    list.items.forEach((itemId, item) {
      itemsMap[itemId] = _sharedItemToFirestore(item);
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

  SharedList _sharedListFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 🆕 Firestoreの items を Map<String, SharedItem> に変換
    final itemsData = data['items'] as Map<String, dynamic>? ?? {};
    final items = <String, SharedItem>{};

    itemsData.forEach((itemId, itemData) {
      items[itemId] =
          _sharedItemFromFirestore(itemData as Map<String, dynamic>);
    });

    return SharedList(
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

  Map<String, dynamic> _sharedItemToFirestore(SharedItem item) {
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

  SharedItem _sharedItemFromFirestore(Map<String, dynamic> data) {
    return SharedItem(
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
  Future<SharedList?> getSharedList(String groupId) async {
    // This method is ambiguous in a multi-list context.
    // We'll get the first list found for the group.
    final lists = await getSharedListsByGroup(groupId);
    return lists.isNotEmpty ? lists.first : null;
  }

  @override
  Future<void> addItem(SharedList list) async {
    // This method is for single-list architecture. Use addItemToList instead.
    throw UnimplementedError("Use addItemToList for multi-list architecture.");
  }

  @override
  Future<void> clearSharedList(String groupId) async {
    // This is ambiguous. Do you clear all lists in a group?
    throw UnimplementedError("Clearing lists by group ID is not defined yet.");
  }

  @override
  Future<void> addSharedItem(String groupId, SharedItem item) async {
    // Ambiguous. Which list to add to?
    throw UnimplementedError("Use addItemToList with a specific listId.");
  }

  @override
  Future<void> removeSharedItem(String groupId, SharedItem item) async {
    // Ambiguous. Which list to remove from?
    throw UnimplementedError("Use removeItemFromList with a specific listId.");
  }

  @override
  Future<void> updateSharedItemStatus(String groupId, SharedItem item,
      {required bool isPurchased}) async {
    // Ambiguous. Which list to update in?
    throw UnimplementedError(
        "Use updateItemStatusInList with a specific listId.");
  }

  @override
  Future<void> clearPurchasedItemsFromList(String listId) async {
    final list = await getSharedListById(listId);
    if (list != null) {
      // 🆕 activeItemsから未購入のみ残す（Map形式）
      final remainingItems = <String, SharedItem>{};
      list.activeItems.where((item) => !item.isPurchased).forEach((item) {
        remainingItems[item.itemId] = item;
      });

      await updateSharedList(list.copyWith(items: remainingItems));
      developer.log('🧹 Firestoreから購入済みアイテムクリア: リスト「${list.listName}」');
    }
  }

  @override
  Future<SharedList> getOrCreateList(String groupId, String groupName) async {
    final lists = await getSharedListsByGroup(groupId);
    if (lists.isNotEmpty) {
      return lists.first;
    }
    return createSharedList(
        ownerUid: 'defaultUser', // Should be properly set
        groupId: groupId,
        listName: '$groupNameのデフォルトリスト');
  }

  @override
  Future<SharedList> getOrCreateDefaultList(
      String groupId, String groupName) async {
    // getOrCreateListと同じ実装（後方互換性のため）
    return getOrCreateList(groupId, groupName);
  }

  // === Realtime Sync Methods ===
  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) {
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
        final list = _sharedListFromFirestore(snapshot);
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
  /// groupIdを指定して単一アイテムを追加（コレクショングループクエリ回避版）
  Future<void> addSingleItemWithGroupId(
      String listId, String groupId, SharedItem item) async {
    developer.log(
        '🔄 [FIRESTORE_DIFF] Adding single item with groupId: ${item.name}');
    developer
        .log('📋 [FIRESTORE_DIFF] Target groupId: $groupId, listId: $listId');

    await _collection(groupId).doc(listId).update({
      'items.${item.itemId}': _itemToFirestore(item),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    developer.log('✅ [FIRESTORE_DIFF] Item added to Firestore');
  }

  @override
  Future<void> addSingleItem(String listId, SharedItem item) async {
    developer.log('🔄 [FIRESTORE_DIFF] Adding single item: ${item.name}');

    // Firestoreでは部分更新としてMapのキーを追加
    // items.{itemId} = item.toJson()

    // まずローカルキャッシュからgroupIdを取得（高速）
    SharedList? list;
    try {
      list = await getSharedListById(listId);
    } catch (e) {
      developer.log(
          '⚠️ [FIRESTORE_DIFF] Local cache miss, trying Firestore query: $e');
      // キャッシュにない場合、コレクショングループクエリで検索
      final querySnapshot = await _firestore
          .collectionGroup('sharedLists')
          .where('listId', isEqualTo: listId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('List not found: $listId');
      }

      list = _sharedListFromFirestore(querySnapshot.docs.first);
    }

    if (list == null) throw Exception('List not found: $listId');

    developer.log('📋 [FIRESTORE_DIFF] Target groupId: ${list.groupId}');
    await _collection(list.groupId).doc(listId).update({
      'items.${item.itemId}': _itemToFirestore(item),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    developer.log('✅ [FIRESTORE_DIFF] Item added to Firestore');
  }

  /// groupIdを指定して単一アイテムを削除（コレクショングループクエリ回避版）
  Future<void> removeSingleItemWithGroupId(
      String listId, String groupId, String itemId) async {
    developer.log(
        '🔄 [FIRESTORE_DIFF] Logically deleting item with groupId: $itemId');
    developer
        .log('📋 [FIRESTORE_DIFF] Target groupId: $groupId, listId: $listId');

    // 論理削除: isDeleted = true に更新
    await _collection(groupId).doc(listId).update({
      'items.$itemId.isDeleted': true,
      'items.$itemId.deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    developer.log('✅ [FIRESTORE_DIFF] Item logically deleted');
  }

  @override
  Future<void> removeSingleItem(String listId, String itemId) async {
    developer.log('🔄 [FIRESTORE_DIFF] Logically deleting item: $itemId');

    // まずローカルキャッシュからgroupIdを取得
    SharedList? list;
    try {
      list = await getSharedListById(listId);
    } catch (e) {
      developer.log(
          '⚠️ [FIRESTORE_DIFF] Local cache miss, trying Firestore query: $e');
      final querySnapshot = await _firestore
          .collectionGroup('sharedLists')
          .where('listId', isEqualTo: listId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        developer.log('⚠️ [FIRESTORE_DIFF] List not found: $listId');
        return;
      }

      list = _sharedListFromFirestore(querySnapshot.docs.first);
    }

    if (list == null) return;

    final item = list.items[itemId];
    if (item == null) {
      developer.log('⚠️ [FIRESTORE_DIFF] Item not found: $itemId');
      return;
    }

    developer.log('📋 [FIRESTORE_DIFF] Target groupId: ${list.groupId}');
    // 論理削除: isDeleted = true に更新
    await _collection(list.groupId).doc(listId).update({
      'items.$itemId.isDeleted': true,
      'items.$itemId.deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    developer.log('✅ [FIRESTORE_DIFF] Item logically deleted');
  }

  /// groupIdを指定して単一アイテムを更新（コレクショングループクエリ回避版）
  Future<void> updateSingleItemWithGroupId(
      String listId, String groupId, SharedItem item) async {
    developer.log(
        '🔄 [FIRESTORE_DIFF] Updating single item with groupId: ${item.name}');
    developer
        .log('📋 [FIRESTORE_DIFF] Target groupId: $groupId, listId: $listId');

    await _collection(groupId).doc(listId).update({
      'items.${item.itemId}': _itemToFirestore(item),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    developer.log('✅ [FIRESTORE_DIFF] Item updated in Firestore');
  }

  @override
  Future<void> updateSingleItem(String listId, SharedItem item) async {
    developer.log('🔄 [FIRESTORE_DIFF] Updating single item: ${item.name}');

    // まずローカルキャッシュからgroupIdを取得
    SharedList? list;
    try {
      list = await getSharedListById(listId);
    } catch (e) {
      developer.log(
          '⚠️ [FIRESTORE_DIFF] Local cache miss, trying Firestore query: $e');
      final querySnapshot = await _firestore
          .collectionGroup('sharedLists')
          .where('listId', isEqualTo: listId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        developer.log('⚠️ [FIRESTORE_DIFF] List not found: $listId');
        return;
      }

      list = _sharedListFromFirestore(querySnapshot.docs.first);
    }

    if (list == null) return;

    developer.log('📋 [FIRESTORE_DIFF] Target groupId: ${list.groupId}');
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

    // まずローカルキャッシュからgroupIdを取得
    SharedList? list;
    try {
      list = await getSharedListById(listId);
    } catch (e) {
      developer.log(
          '⚠️ [FIRESTORE_CLEANUP] Local cache miss, trying Firestore query: $e');
      final querySnapshot = await _firestore
          .collectionGroup('sharedLists')
          .where('listId', isEqualTo: listId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        developer.log('⚠️ [FIRESTORE_CLEANUP] List not found: $listId');
        return;
      }

      list = _sharedListFromFirestore(querySnapshot.docs.first);
    }

    if (list == null) return;

    // 削除済みアイテムを物理削除（全体を保存し直す）
    await updateSharedList(list);

    developer.log('✅ [FIRESTORE_CLEANUP] Cleanup completed');
  }

  /// SharedItemをFirestore形式に変換
  Map<String, dynamic> _itemToFirestore(SharedItem item) {
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
