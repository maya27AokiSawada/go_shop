import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firestore_shopping_list.dart';
import '../models/shopping_list.dart';
import 'shopping_list_repository.dart';
import '../flavors.dart';

class FirestoreShoppingListRepository implements ShoppingListRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _collection => _firestore.collection('shoppingLists');

  // ShoppingListを作成
  Future<FirestoreShoppingList> createShoppingList({
    required String ownerUid,
    required String groupId,
    required String listName,
    List<Map<String, dynamic>>? items,
  }) async {
    final newList = FirestoreShoppingList(
      id: '', // Firestoreで自動生成
      ownerUid: ownerUid,
      groupId: groupId,
      listName: listName,
      items: items ?? [],
    );

    final docRef = await _collection.add(newList.toFirestore());
    return newList.copyWith(id: docRef.id);
  }

  // ShoppingListを取得
  Future<FirestoreShoppingList?> getShoppingList(String listId) async {
    final doc = await _collection.doc(listId).get();
    if (doc.exists) {
      return FirestoreShoppingList.fromFirestore(doc);
    }
    return null;
  }

  // ユーザーがアクセス可能なShoppingListを取得（groupIdベース）
  Future<List<FirestoreShoppingList>> getUserShoppingListsByGroupIds(List<String> groupIds) async {
    if (groupIds.isEmpty) return [];
    
    final query = await _collection.where('groupId', whereIn: groupIds).get();
    final lists = <FirestoreShoppingList>[];
    
    for (final doc in query.docs) {
      final list = FirestoreShoppingList.fromFirestore(doc);
      lists.add(list);
    }

    return lists;
  }

  // 特定のグループのShoppingListを取得
  Future<List<FirestoreShoppingList>> getShoppingListsByGroupId(String groupId) async {
    final query = await _collection.where('groupId', isEqualTo: groupId).get();
    final lists = <FirestoreShoppingList>[];
    
    for (final doc in query.docs) {
      final list = FirestoreShoppingList.fromFirestore(doc);
      lists.add(list);
    }

    return lists;
  }

  // ShoppingListを更新
  Future<FirestoreShoppingList> updateShoppingList(FirestoreShoppingList list) async {
    await _collection.doc(list.id).update(list.toFirestore());
    return list;
  }

  // 招待ユーザーを追加（非推奨: PurchaseGroupで招待管理すること）
  Future<FirestoreShoppingList> addInvitation({
    required String listId,
    required String email,
  }) async {
    throw UnimplementedError(
      'Invitation feature should be managed through PurchaseGroup, not ShoppingList'
    );
  }

  // 招待を確定（UID設定）（非推奨: PurchaseGroupで招待管理すること）
  Future<FirestoreShoppingList> confirmInvitation({
    required String listId,
    required String email,
    required String uid,
  }) async {
    throw UnimplementedError(
      'Invitation confirmation should be managed through PurchaseGroup, not ShoppingList'
    );
  }

  // 確定済み招待をクリーンアップ（非推奨: PurchaseGroupで招待管理すること）
  Future<FirestoreShoppingList> cleanupConfirmedInvitations(String listId) async {
    throw UnimplementedError(
      'Invitation cleanup should be managed through PurchaseGroup, not ShoppingList'
    );
  }

  // ShoppingListを削除
  Future<void> deleteShoppingList(String listId) async {
    await _collection.doc(listId).delete();
  }

  // リアルタイムリスナー
  Stream<FirestoreShoppingList?> watchShoppingList(String listId) {
    return _collection.doc(listId).snapshots().map((doc) {
      if (doc.exists) {
        return FirestoreShoppingList.fromFirestore(doc);
      }
      return null;
    });
  }

  // グループのShoppingList一覧をリアルタイム監視
  Stream<List<FirestoreShoppingList>> watchGroupShoppingLists(String groupId) {
    return _collection
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestoreShoppingList.fromFirestore(doc))
          .toList();
    });
  }

  // リストを取得または作成
  @override
  Future<ShoppingList> getOrCreateList(String groupId, String groupName) async {
    // 既存のリストを検索
    final querySnapshot = await _collection
        .where('groupId', isEqualTo: groupId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      // 既存のリストが存在する場合
      final firestoreList = FirestoreShoppingList.fromFirestore(querySnapshot.docs.first);
      return ShoppingList(
        ownerUid: firestoreList.ownerUid,
        groupId: firestoreList.groupId,
        groupName: groupName,
        items: firestoreList.items.map((item) => ShoppingItem(
          memberId: item['memberId'] ?? '',
          name: item['name'] ?? '',
          quantity: item['quantity'] ?? 1,
          registeredDate: DateTime.tryParse(item['registeredDate'] ?? '') ?? DateTime.now(),
          purchaseDate: DateTime.tryParse(item['purchaseDate'] ?? ''),
          isPurchased: item['isPurchased'] ?? false,
          shoppingInterval: item['shoppingInterval'] ?? 0,
          deadline: DateTime.tryParse(item['deadline'] ?? ''),
        )).toList(),
      );
    } else {
      // 新しいリストを作成
      final firestoreList = await createShoppingList(
        ownerUid: 'defaultUser', // PurchaseGroupから取得すべき
        groupId: groupId,
        listName: '${groupName}のリスト',
        items: [],
      );
      return ShoppingList(
        ownerUid: firestoreList.ownerUid,
        groupId: firestoreList.groupId,
        groupName: groupName,
        items: [],
      );
    }
  }
}

// プロバイダー定義
final firestoreShoppingListRepositoryProvider = Provider<FirestoreShoppingListRepository>((ref) {
  if (F.appFlavor == Flavor.dev) {
    throw UnimplementedError('FirestoreShoppingListRepository is not available in dev mode');
  }
  return FirestoreShoppingListRepository();
});

// 特定のShoppingListを監視するプロバイダー
final watchShoppingListProvider = StreamProvider.family<FirestoreShoppingList?, String>((ref, listId) {
  if (F.appFlavor == Flavor.dev) {
    throw UnimplementedError('Firestore watching is not available in dev mode');
  }
  final repository = ref.read(firestoreShoppingListRepositoryProvider);
  return repository.watchShoppingList(listId);
});

// グループのShoppingList一覧を監視するプロバイダー
final watchGroupShoppingListsProvider = StreamProvider.family<List<FirestoreShoppingList>, String>((ref, groupId) {
  if (F.appFlavor == Flavor.dev) {
    throw UnimplementedError('Firestore watching is not available in dev mode');
  }
  final repository = ref.read(firestoreShoppingListRepositoryProvider);
  return repository.watchGroupShoppingLists(groupId);
});
