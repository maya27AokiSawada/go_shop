import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list.dart';
import '../providers/auth_provider.dart';
import 'shopping_list_repository.dart';
import 'hive_shopping_list_repository.dart';
import '../main.dart'; // For logger access

/// Firebase同期機能付きShoppingListRepository
/// ログイン状態ではFirestoreと同期し、オフラインではHiveを使用
class FirebaseSyncShoppingListRepository implements ShoppingListRepository {
  final Ref ref;
  final HiveShoppingListRepository _hiveRepo;
  
  FirebaseSyncShoppingListRepository(this.ref) 
    : _hiveRepo = HiveShoppingListRepository(ref);
  
  /// 現在のユーザーを取得
  User? get _currentUser {
    final authState = ref.read(authStateProvider);
    return authState.when(
      data: (user) => user,
      loading: () => null,
      error: (_, __) => null,
    );
  }
  
  /// Firestoreコレクション参照を取得
  CollectionReference? _getUserShoppingListsCollection() {
    final user = _currentUser;
    if (user == null) return null;
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('groups');
  }

  @override
  Future<ShoppingList?> getShoppingList(String groupId) async {
    logger.i('FirebaseSyncRepo: Reading ShoppingList for group: $groupId');
    
    // ログイン状態ならFirebaseから同期を試行
    final user = _currentUser;
    if (user != null) {
      try {
        await _syncFromFirebase(groupId);
        logger.i('Firebase sync completed - Returning from Hive');
        return await _hiveRepo.getShoppingList(groupId);
      } catch (e) {
        logger.e('Firebase sync error: $e - Returning from Hive');
        return await _hiveRepo.getShoppingList(groupId);
      }
    }
    
    // ログインしていない場合はHiveから直接読み込み
    logger.i('Not logged in - Reading from Hive only');
    return await _hiveRepo.getShoppingList(groupId);
  }

  @override
  Future<void> addItem(ShoppingList list) async {
    logger.i('FirebaseSyncRepo: Starting ShoppingList save');
    
    // Save to Hive first
    await _hiveRepo.addItem(list);
    logger.i('Hive save completed');
    
    // Sync to Firebase if logged in
    final user = _currentUser;
    if (user != null) {
      try {
        await _syncToFirebase(list);
        logger.i('Firebase sync completed');
      } catch (e) {
        logger.e('Firebase sync error: $e');
        // Local save succeeded, don't throw error for Firebase issues
      }
    } else {
      logger.i('Not logged in - Skipping Firebase sync');
    }
  }

  @override
  Future<void> clearShoppingList(String groupId) async {
    await _hiveRepo.clearShoppingList(groupId);
    
    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getShoppingList(groupId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        logger.e('Firebase sync error during clear: $e');
      }
    }
  }

  @override
  Future<void> addShoppingItem(String groupId, ShoppingItem item) async {
    await _hiveRepo.addShoppingItem(groupId, item);
    
    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getShoppingList(groupId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        logger.e('Firebase sync error during add item: $e');
      }
    }
  }

  @override
  Future<void> removeShoppingItem(String groupId, ShoppingItem item) async {
    await _hiveRepo.removeShoppingItem(groupId, item);
    
    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getShoppingList(groupId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        logger.e('Firebase sync error during remove item: $e');
      }
    }
  }

  @override
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item, {required bool isPurchased}) async {
    await _hiveRepo.updateShoppingItemStatus(groupId, item, isPurchased: isPurchased);
    
    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getShoppingList(groupId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        logger.e('Firebase sync error during item status update: $e');
      }
    }
  }

  /// FirebaseからHiveに同期
  Future<void> _syncFromFirebase(String groupId) async {
    final collection = _getUserShoppingListsCollection();
    if (collection == null) return;
    
    try {
      logger.i('🔥 Firebase -> Hive sync started');
      
      final doc = await collection.doc(groupId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final firebaseList = _mapToShoppingList(data);
        
        // Compare with current Hive data
        final hiveList = await _hiveRepo.getShoppingList(groupId);
        
        if (hiveList == null || _shouldUpdateFromFirebase(hiveList, firebaseList)) {
          await _hiveRepo.addItem(firebaseList);
          logger.i('🔥 Firebase -> Hive sync completed');
        } else {
          logger.i('Hive data is current - Skipping sync');
        }
      } else {
        logger.i('No data on Firebase side');
      }
    } catch (e) {
      logger.e('Firebase read error: $e');
      rethrow;
    }
  }

  /// HiveからFirebaseに同期
  Future<void> _syncToFirebase(ShoppingList list) async {
    final collection = _getUserShoppingListsCollection();
    if (collection == null) return;
    
    try {
      logger.i('🔥 Hive -> Firebase sync started');
      final data = _shoppingListToMap(list);
      await collection.doc(list.groupId).set(data, SetOptions(merge: true));
      logger.i('🔥 Hive -> Firebase sync completed');
    } catch (e) {
      logger.e('Firebase write error: $e');
      rethrow;
    }
  }

  /// ShoppingListをFirestore用のMapに変換
  Map<String, dynamic> _shoppingListToMap(ShoppingList list) {
    return {
      'ownerUid': list.ownerUid,
      'groupId': list.groupId,
      'groupName': list.groupName,
      'items': list.items.map((item) => {
        'memberId': item.memberId,
        'name': item.name,
        'quantity': item.quantity,
        'registeredDate': item.registeredDate.toIso8601String(),
        'purchaseDate': item.purchaseDate?.toIso8601String(),
        'isPurchased': item.isPurchased,
        'shoppingInterval': item.shoppingInterval,
      }).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// FirestoreのMapをShoppingListに変換
  ShoppingList _mapToShoppingList(Map<String, dynamic> data) {
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final items = itemsData.map((itemData) {
      final itemMap = itemData as Map<String, dynamic>;
      return ShoppingItem(
        memberId: itemMap['memberId'] ?? '',
        name: itemMap['name'] ?? '',
        quantity: itemMap['quantity'] ?? 1,
        registeredDate: DateTime.parse(itemMap['registeredDate'] ?? DateTime.now().toIso8601String()),
        purchaseDate: itemMap['purchaseDate'] != null 
            ? DateTime.parse(itemMap['purchaseDate'])
            : null,
        isPurchased: itemMap['isPurchased'] ?? false,
        shoppingInterval: itemMap['shoppingInterval'] ?? 0,
      );
    }).toList();

    return ShoppingList(
      ownerUid: data['ownerUid'] ?? '',
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      items: items,
    );
  }

  /// Firebaseからの更新が必要かどうかを判断
  bool _shouldUpdateFromFirebase(ShoppingList hiveList, ShoppingList firebaseList) {
    // 簡単な比較: アイテム数やアイテムの内容が異なる場合は更新
    if (hiveList.items.length != firebaseList.items.length) {
      return true;
    }
    
    // より詳細な比較も可能だが、とりあえずアイテム数の比較のみ
    return false;
  }

  // HiveShoppingListRepositoryの追加メソッドを委譲
  Future<void> deleteList(String groupId) async {
    await _hiveRepo.deleteList(groupId);
    
    final user = _currentUser;
    if (user != null) {
      try {
        final collection = _getUserShoppingListsCollection();
        await collection?.doc(groupId).delete();
      } catch (e) {
        logger.e('Firebase delete error: $e');
      }
    }
  }

  List<ShoppingList> getAllLists() {
    return _hiveRepo.getAllLists();
  }

  Future<ShoppingList> getOrCreateList(String groupId, String groupName) async {
    // ログイン状態なら先にFirebaseから同期を試行
    final user = _currentUser;
    if (user != null) {
      try {
        await _syncFromFirebase(groupId);
      } catch (e) {
        logger.e('Firebase sync error during get or create: $e');
      }
    }
    
    return await _hiveRepo.getOrCreateList(groupId, groupName);
  }
}