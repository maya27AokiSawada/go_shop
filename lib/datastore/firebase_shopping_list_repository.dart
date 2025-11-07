import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list.dart';
import '../providers/auth_provider.dart';
import '../helper/mock_auth_service.dart';
import 'shopping_list_repository.dart';
import 'hive_shopping_list_repository.dart';
import '../utils/app_logger.dart';

/// Firebase同期機�E付きShoppingListRepository
/// ログイン状態ではFirestoreと同期し、オフラインではHiveを使用
class FirebaseSyncShoppingListRepository implements ShoppingListRepository {
  final Ref ref;
  final HiveShoppingListRepository _hiveRepo;

  FirebaseSyncShoppingListRepository(this.ref)
      : _hiveRepo = HiveShoppingListRepository(ref);

  /// 現在のユーザーを取征E
  User? get _currentUser {
    // 開発フレーバ�EではMockAuthServiceを優允E
    final authService = ref.read(authProvider);
    AppLogger.info(
        'FirebaseRepo: AuthService type: ${authService.runtimeType}');

    if (authService is MockAuthService) {
      final mockUser = authService.currentUser;
      AppLogger.info(
          'FirebaseRepo: MockAuthService user: ${mockUser?.email} (uid: ${mockUser?.uid})');
      // devフレーバ�EでFirebase repositoryの使用は禁止
      throw UnimplementedError(
          'Firebase repository should not be used in dev mode. Use Hive repository instead.');
    }

    // 通常のFirebaseAuth
    final authState = ref.read(authStateProvider);
    return authState.when(
      data: (user) {
        AppLogger.info('FirebaseRepo: Using FirebaseAuth user: ${user?.email}');
        return user;
      },
      loading: () {
        AppLogger.info('FirebaseRepo: Auth loading...');
        return null;
      },
      error: (_, __) {
        AppLogger.warning('FirebaseRepo: Auth error');
        return null;
      },
    );
  }

  /// Firestoreコレクション参照を取得
  CollectionReference? _getUserShoppingListsCollection() {
    final user = _currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('shoppingLists');
  }

  @override
  Future<ShoppingList?> getShoppingList(String groupId) async {
    AppLogger.info(
        'FirebaseSyncRepo: Reading ShoppingList for group: $groupId');

    // ログイン状態ならFirebaseから同期を試衁E
    final user = _currentUser;
    if (user != null) {
      try {
        await _syncFromFirebase(groupId);
        AppLogger.info('Firebase sync completed - Returning from Hive');
        return await _hiveRepo.getShoppingList(groupId);
      } catch (e) {
        AppLogger.error('Firebase sync error: $e - Returning from Hive');
        return await _hiveRepo.getShoppingList(groupId);
      }
    }

    // ログインしてぁE��ぁE��合�EHiveから直接読み込み
    AppLogger.info('Not logged in - Reading from Hive only');
    return await _hiveRepo.getShoppingList(groupId);
  }

  @override
  Future<void> addItem(ShoppingList list) async {
    AppLogger.info('FirebaseSyncRepo: Starting ShoppingList save');

    // Save to Hive first
    await _hiveRepo.addItem(list);
    AppLogger.info('Hive save completed');

    // Sync to Firebase if logged in
    final user = _currentUser;
    if (user != null) {
      try {
        await _syncToFirebase(list);
        AppLogger.info('Firebase sync completed');
      } catch (e) {
        AppLogger.error('Firebase sync error: $e');
        // Local save succeeded, don't throw error for Firebase issues
      }
    } else {
      AppLogger.info('Not logged in - Skipping Firebase sync');
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
        AppLogger.error('Firebase sync error during clear: $e');
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
        AppLogger.error('Firebase sync error during add item: $e');
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
        AppLogger.error('Firebase sync error during remove item: $e');
      }
    }
  }

  @override
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item,
      {required bool isPurchased}) async {
    await _hiveRepo.updateShoppingItemStatus(groupId, item,
        isPurchased: isPurchased);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getShoppingList(groupId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        AppLogger.error('Firebase sync error during item status update: $e');
      }
    }
  }

  /// FirebaseからHiveに同期
  Future<void> _syncFromFirebase(String groupId) async {
    final collection = _getUserShoppingListsCollection();
    if (collection == null) return;

    try {
      AppLogger.info('🔥 Firebase -> Hive sync started');

      // 10秒�Eタイムアウトを設宁E
      final doc = await collection.doc(groupId).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.warning(
              '⏰ Firebase read timeout - continuing with Hive data');
          throw Exception('Firebase read timeout');
        },
      );

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final firebaseList = _mapToShoppingList(data);

        // Compare with current Hive data
        final hiveList = await _hiveRepo.getShoppingList(groupId);

        if (hiveList == null ||
            _shouldUpdateFromFirebase(hiveList, firebaseList)) {
          // 繰り返し購入アイチE��の処琁E��追加
          final processedList = _processRepeatPurchases(firebaseList);
          await _hiveRepo.addItem(processedList);
          AppLogger.info('🔥 Firebase -> Hive sync completed');
        } else {
          AppLogger.info('Hive data is current - Skipping sync');
        }
      } else {
        AppLogger.info('No data on Firebase side');
      }
    } catch (e) {
      AppLogger.error('⛁EFirebase read error: $e');
      // エラー時�EHiveから読み込み継続！EethrowしなぁE��E
    }
  }

  /// HiveからFirebaseに同期
  Future<void> _syncToFirebase(ShoppingList list) async {
    final collection = _getUserShoppingListsCollection();
    if (collection == null) return;

    try {
      AppLogger.info('🔥 Hive -> Firebase sync started');
      final data = _shoppingListToMap(list);

      // 10秒�Eタイムアウトを設宁E
      await collection
          .doc(list.groupId)
          .set(data, SetOptions(merge: true))
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.warning(
              '⏰ Firebase write timeout - data saved to Hive only');
          throw Exception('Firebase write timeout');
        },
      );

      AppLogger.info('🔥 Hive -> Firebase sync completed');
    } catch (e) {
      AppLogger.error('⛁EFirebase write error: $e');
      // エラー時�EHive保存�E完亁E��てぁE��ので続行！EethrowしなぁE��E
    }
  }

  /// ShoppingListをFirestore用のMapに変換
  Map<String, dynamic> _shoppingListToMap(ShoppingList list) {
    return {
      'ownerUid': list.ownerUid,
      'groupId': list.groupId,
      'groupName': list.groupName,
      'items': list.items
          .map((item) => {
                'memberId': item.memberId,
                'name': item.name,
                'quantity': item.quantity,
                'registeredDate': item.registeredDate.toIso8601String(),
                'purchaseDate': item.purchaseDate?.toIso8601String(),
                'isPurchased': item.isPurchased,
                'shoppingInterval': item.shoppingInterval,
                'deadline': item.deadline?.toIso8601String(),
              })
          .toList(),
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
        registeredDate: DateTime.parse(
            itemMap['registeredDate'] ?? DateTime.now().toIso8601String()),
        purchaseDate: itemMap['purchaseDate'] != null
            ? DateTime.parse(itemMap['purchaseDate'])
            : null,
        isPurchased: itemMap['isPurchased'] ?? false,
        shoppingInterval: itemMap['shoppingInterval'] ?? 0,
        deadline: itemMap['deadline'] != null
            ? DateTime.parse(itemMap['deadline'])
            : null,
      );
    }).toList();

    return ShoppingList.create(
      ownerUid: data['ownerUid'] ?? '',
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      listName: data['groupName'] ?? '',
      description: '',
      items: items,
    );
  }

  /// 繰り返し購入アイチE��の処琁E
  ShoppingList _processRepeatPurchases(ShoppingList list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final processedItems = <ShoppingItem>[];

    for (final item in list.items) {
      processedItems.add(item);

      // 繰り返し購入の条件をチェチE��
      if (item.shoppingInterval > 0 &&
          item.isPurchased &&
          item.purchaseDate != null) {
        final purchaseDate = DateTime(item.purchaseDate!.year,
            item.purchaseDate!.month, item.purchaseDate!.day);

        final nextPurchaseDate =
            purchaseDate.add(Duration(days: item.shoppingInterval));

        // 次回購入予定日が今日以降で、同じ名前�E未購入アイチE��が存在しなぁE��吁E
        if ((nextPurchaseDate.isBefore(today) ||
                nextPurchaseDate.isAtSameMomentAs(today)) &&
            !_hasUnpurchasedItemWithSameName(processedItems, item.name)) {
          // 1週間以冁E�E間隔の場合�E期限めE日後に、それ以外�E間隔刁E��長
          DateTime? newDeadline;
          if (item.shoppingInterval <= 7) {
            newDeadline = DateTime.now().add(const Duration(days: 1));
          } else if (item.deadline != null) {
            newDeadline =
                item.deadline!.add(Duration(days: item.shoppingInterval));
          }

          final newItem = ShoppingItem.createNow(
            memberId: item.memberId,
            name: item.name,
            quantity: item.quantity,
            isPurchased: false,
            shoppingInterval: item.shoppingInterval,
            deadline: newDeadline,
          );

          processedItems.add(newItem);
          AppLogger.info(
              '🔄 Created repeat purchase item: ${item.name} (${item.shoppingInterval} days interval)');
        }
      }
    }

    return list.copyWith(items: processedItems);
  }

  /// 同じ名前の未購入アイチE��が存在するかチェチE��
  bool _hasUnpurchasedItemWithSameName(List<ShoppingItem> items, String name) {
    return items.any((item) => item.name == name && !item.isPurchased);
  }

  /// Firebaseからの更新が忁E��かどぁE��を判断
  bool _shouldUpdateFromFirebase(
      ShoppingList hiveList, ShoppingList firebaseList) {
    // アイチE��数が異なる場合�E更新
    if (hiveList.items.length != firebaseList.items.length) {
      AppLogger.info(
          '📊 Item count differs: Hive=${hiveList.items.length}, Firebase=${firebaseList.items.length}');
      return true;
    }

    // 吁E��イチE��の冁E��を比輁E
    final hiveItemsSet = hiveList.items
        .map((item) => '${item.name}_${item.memberId}_${item.isPurchased}')
        .toSet();
    final firebaseItemsSet = firebaseList.items
        .map((item) => '${item.name}_${item.memberId}_${item.isPurchased}')
        .toSet();

    if (!hiveItemsSet.containsAll(firebaseItemsSet) ||
        !firebaseItemsSet.containsAll(hiveItemsSet)) {
      AppLogger.info('🔄 Item content differs - updating from Firebase');
      return true;
    }

    AppLogger.info('✁EHive and Firebase data are identical');
    return false;
  }

  // HiveShoppingListRepositoryの追加メソチE��を委譲
  Future<void> deleteList(String groupId) async {
    await _hiveRepo.deleteList(groupId);

    final user = _currentUser;
    if (user != null) {
      try {
        final collection = _getUserShoppingListsCollection();
        await collection?.doc(groupId).delete();
      } catch (e) {
        AppLogger.error('Firebase delete error: $e');
      }
    }
  }

  List<ShoppingList> getAllLists() {
    return _hiveRepo.getAllLists();
  }

  @override
  Future<ShoppingList> getOrCreateList(String groupId, String groupName) async {
    // ログイン状態なら�EにFirebaseから同期を試衁E
    final user = _currentUser;
    if (user != null) {
      try {
        await _syncFromFirebase(groupId);
      } catch (e) {
        AppLogger.error('Firebase sync error during get or create: $e');
      }
    }

    return await _hiveRepo.getOrCreateList(groupId, groupName);
  }

  // === Multi-List Methods - Not Implemented Yet ===

  @override
  Future<ShoppingList> createShoppingList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
  }) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<ShoppingList?> getShoppingListById(String listId) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<List<ShoppingList>> getShoppingListsByGroup(String groupId) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> updateShoppingList(ShoppingList list) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> deleteShoppingList(String listId) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> removeItemFromList(String listId, ShoppingItem item) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> updateItemStatusInList(String listId, ShoppingItem item,
      {required bool isPurchased}) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> clearPurchasedItemsFromList(String listId) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<ShoppingList> getOrCreateDefaultList(
      String groupId, String groupName) async {
    return await getOrCreateList(groupId, groupName);
  }

  @override
  Future<void> deleteShoppingListsByGroupId(String groupId) async {
    // Firebase実装では、グループ削除時に関連するショッピングリストも削除する
    // 現在はHiveリポジトリに委譲
    await _hiveRepo.deleteShoppingListsByGroupId(groupId);
  }
}
