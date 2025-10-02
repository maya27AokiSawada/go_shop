import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firestore_purchase_group.dart';
import '../models/firestore_shopping_list.dart';
import '../flavors.dart';

class FirestorePurchaseGroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _groupsCollection => _firestore.collection('purchaseGroups');
  CollectionReference get _listsCollection => _firestore.collection('shoppingLists');

  // PurchaseGroupを作成
  Future<FirestorePurchaseGroup> createPurchaseGroup({
    required String groupName,
    required String ownerUid,
    required String ownerEmail,
  }) async {
    final newGroup = FirestorePurchaseGroup(
      id: '', // Firestoreで自動生成
      groupName: groupName,
      ownerUid: ownerUid,
      ownerEmail: ownerEmail,
      memberUids: [ownerUid], // オーナーをメンバーに追加
    );

    final docRef = await _groupsCollection.add(newGroup.toFirestore());
    return newGroup.copyWith(id: docRef.id);
  }

  // PurchaseGroupを取得
  Future<FirestorePurchaseGroup?> getPurchaseGroup(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    if (doc.exists) {
      return FirestorePurchaseGroup.fromFirestore(doc);
    }
    return null;
  }

  // ユーザーが参加しているPurchaseGroupを取得
  Future<List<FirestorePurchaseGroup>> getUserPurchaseGroups(String uid, String? email) async {
    final query = await _groupsCollection.where('memberUids', arrayContains: uid).get();
    final groups = <FirestorePurchaseGroup>[];
    
    for (final doc in query.docs) {
      final group = FirestorePurchaseGroup.fromFirestore(doc);
      groups.add(group);
    }

    // メールアドレスでの招待もチェック
    if (email != null) {
      final invitedQuery = await _groupsCollection
          .where('invitedUsers', arrayContainsAny: [{'email': email}])
          .get();
      
      for (final doc in invitedQuery.docs) {
        final group = FirestorePurchaseGroup.fromFirestore(doc);
        if (group.invitedUsers.any((user) => user.email == email && !user.isConfirmed)) {
          groups.add(group);
        }
      }
    }

    return groups;
  }

  // PurchaseGroupを更新
  Future<FirestorePurchaseGroup> updatePurchaseGroup(FirestorePurchaseGroup group) async {
    await _groupsCollection.doc(group.id).update(group.toFirestore());
    return group;
  }

  // 招待ユーザーを追加
  Future<FirestorePurchaseGroup> addInvitation({
    required String groupId,
    required String email,
    String role = 'member',
  }) async {
    final group = await getPurchaseGroup(groupId);
    if (group == null) throw Exception('Purchase group not found');

    final updatedGroup = group.addInvitation(email: email, role: role);
    return await updatePurchaseGroup(updatedGroup);
  }

  // 招待を確定（UID設定）し、グループのShoppingListに権限を同期
  Future<FirestorePurchaseGroup> confirmInvitation({
    required String groupId,
    required String email,
    required String uid,
  }) async {
    final group = await getPurchaseGroup(groupId);
    if (group == null) throw Exception('Purchase group not found');

    final updatedGroup = group.confirmInvitation(email: email, uid: uid);
    
    // グループのShoppingListに権限を同期
    await _syncShoppingListPermissions(updatedGroup);
    
    return await updatePurchaseGroup(updatedGroup);
  }

  // 確定済み招待をクリーンアップ
  Future<FirestorePurchaseGroup> cleanupConfirmedInvitations(String groupId) async {
    final group = await getPurchaseGroup(groupId);
    if (group == null) throw Exception('Purchase group not found');

    final updatedGroup = group.cleanupConfirmedInvitations();
    return await updatePurchaseGroup(updatedGroup);
  }

  // PurchaseGroupを削除
  Future<void> deletePurchaseGroup(String groupId) async {
    // 関連するShoppingListも削除
    final group = await getPurchaseGroup(groupId);
    if (group != null) {
      for (final listId in group.shoppingListIds) {
        await _listsCollection.doc(listId).delete();
      }
    }
    
    await _groupsCollection.doc(groupId).delete();
  }

  // ShoppingListを作成し、グループに関連付け
  Future<FirestoreShoppingList> createShoppingListForGroup({
    required String groupId,
    required String listName,
    required String ownerUid,
  }) async {
    final group = await getPurchaseGroup(groupId);
    if (group == null) throw Exception('Purchase group not found');

    // ShoppingListを作成
    final newList = FirestoreShoppingList(
      id: '', // Firestoreで自動生成
      ownerUid: ownerUid,
      groupId: groupId,
      listName: listName,
      // 権限はgroupIdベースで管理されるためauthorizedUidsは不要
    );

    final docRef = await _listsCollection.add(newList.toFirestore());
    final createdList = newList.copyWith(id: docRef.id);

    // グループのShoppingListリストに追加
    final updatedGroup = group.addShoppingList(docRef.id);
    await updatePurchaseGroup(updatedGroup);

    return createdList;
  }

  // グループのShoppingList一覧を取得
  Future<List<FirestoreShoppingList>> getGroupShoppingLists(String groupId) async {
    final group = await getPurchaseGroup(groupId);
    if (group == null) return [];

    final lists = <FirestoreShoppingList>[];
    for (final listId in group.shoppingListIds) {
      final doc = await _listsCollection.doc(listId).get();
      if (doc.exists) {
        lists.add(FirestoreShoppingList.fromFirestore(doc));
      }
    }

    return lists;
  }

  // ShoppingListの権限をグループメンバーと同期（現在は不要）
  // groupIdベースのアクセス制御のため、明示的な同期は不要
  Future<void> _syncShoppingListPermissions(FirestorePurchaseGroup group) async {
    // グループメンバーの変更は自動的にアクセス権限に反映される
    // ため、明示的な同期処理は不要
    return;
  }

  // リアルタイムリスナー
  Stream<FirestorePurchaseGroup?> watchPurchaseGroup(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (doc.exists) {
        return FirestorePurchaseGroup.fromFirestore(doc);
      }
      return null;
    });
  }

  // ユーザーのPurchaseGroup一覧をリアルタイム監視
  Stream<List<FirestorePurchaseGroup>> watchUserPurchaseGroups(String uid) {
    return _groupsCollection
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestorePurchaseGroup.fromFirestore(doc))
          .toList();
    });
  }

  // グループのShoppingList一覧をリアルタイム監視
  Stream<List<FirestoreShoppingList>> watchGroupShoppingLists(String groupId) {
    return _listsCollection
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestoreShoppingList.fromFirestore(doc))
          .toList();
    });
  }
}

// プロバイダー定義
final firestorePurchaseGroupRepositoryProvider = Provider<FirestorePurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.dev) {
    throw UnimplementedError('FirestorePurchaseGroupRepository is not available in dev mode');
  }
  return FirestorePurchaseGroupRepository();
});

// 特定のPurchaseGroupを監視するプロバイダー
final watchPurchaseGroupProvider = StreamProvider.family<FirestorePurchaseGroup?, String>((ref, groupId) {
  if (F.appFlavor == Flavor.dev) {
    throw UnimplementedError('Firestore watching is not available in dev mode');
  }
  final repository = ref.read(firestorePurchaseGroupRepositoryProvider);
  return repository.watchPurchaseGroup(groupId);
});

// ユーザーのPurchaseGroup一覧を監視するプロバイダー
final watchUserPurchaseGroupsProvider = StreamProvider.family<List<FirestorePurchaseGroup>, String>((ref, uid) {
  if (F.appFlavor == Flavor.dev) {
    throw UnimplementedError('Firestore watching is not available in dev mode');
  }
  final repository = ref.read(firestorePurchaseGroupRepositoryProvider);
  return repository.watchUserPurchaseGroups(uid);
});

// グループのShoppingList一覧を監視するプロバイダー
final watchGroupShoppingListsProvider = StreamProvider.family<List<FirestoreShoppingList>, String>((ref, groupId) {
  if (F.appFlavor == Flavor.dev) {
    throw UnimplementedError('Firestore watching is not available in dev mode');
  }
  final repository = ref.read(firestorePurchaseGroupRepositoryProvider);
  return repository.watchGroupShoppingLists(groupId);
});
