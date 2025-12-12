import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_list.dart';
import '../providers/auth_provider.dart';
import '../helpers/mock_auth_service.dart';
import 'shared_list_repository.dart';
import 'hive_shared_list_repository.dart';
import '../utils/app_logger.dart';

/// Firebase同期機�E付きSharedListRepository
/// ログイン状態ではFirestoreと同期し、オフラインではHiveを使用
class FirebaseSyncSharedListRepository implements SharedListRepository {
  final Ref ref;
  final HiveSharedListRepository _hiveRepo;

  FirebaseSyncSharedListRepository(this.ref)
      : _hiveRepo = HiveSharedListRepository(ref);

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
  CollectionReference? _getUserSharedListsCollection() {
    final user = _currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sharedLists');
  }

  @override
  Future<SharedList?> getSharedList(String groupId) async {
    AppLogger.info(
        'FirebaseSyncRepo: Reading SharedList for group: $groupId');

    // ログイン状態ならFirebaseから同期を試衁E
    final user = _currentUser;
    if (user != null) {
      try {
        await _syncFromFirebase(groupId);
        AppLogger.info('Firebase sync completed - Returning from Hive');
        return await _hiveRepo.getSharedList(groupId);
      } catch (e) {
        AppLogger.error('Firebase sync error: $e - Returning from Hive');
        return await _hiveRepo.getSharedList(groupId);
      }
    }

    // ログインしてぁE��ぁE��合�EHiveから直接読み込み
    AppLogger.info('Not logged in - Reading from Hive only');
    return await _hiveRepo.getSharedList(groupId);
  }

  @override
  Future<void> addItem(SharedList list) async {
    AppLogger.info('FirebaseSyncRepo: Starting SharedList save');

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
  Future<void> clearSharedList(String groupId) async {
    await _hiveRepo.clearSharedList(groupId);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getSharedList(groupId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        AppLogger.error('Firebase sync error during clear: $e');
      }
    }
  }

  @override
  Future<void> addSharedItem(String groupId, SharedItem item) async {
    await _hiveRepo.addSharedItem(groupId, item);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getSharedList(groupId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        AppLogger.error('Firebase sync error during add item: $e');
      }
    }
  }

  @override
  Future<void> removeSharedItem(String groupId, SharedItem item) async {
    await _hiveRepo.removeSharedItem(groupId, item);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getSharedList(groupId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        AppLogger.error('Firebase sync error during remove item: $e');
      }
    }
  }

  @override
  Future<void> updateSharedItemStatus(String groupId, SharedItem item,
      {required bool isPurchased}) async {
    await _hiveRepo.updateSharedItemStatus(groupId, item,
        isPurchased: isPurchased);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getSharedList(groupId);
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
    final collection = _getUserSharedListsCollection();
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
        final firebaseList = _mapToSharedList(data);

        // Compare with current Hive data
        final hiveList = await _hiveRepo.getSharedList(groupId);

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
  Future<void> _syncToFirebase(SharedList list) async {
    final collection = _getUserSharedListsCollection();
    if (collection == null) return;

    try {
      AppLogger.info('🔥 Hive -> Firebase sync started');
      final data = _sharedListToMap(list);

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

  /// SharedListをFirestore用のMapに変換
  Map<String, dynamic> _sharedListToMap(SharedList list) {
    return {
      'ownerUid': list.ownerUid,
      'groupId': list.groupId,
      'groupName': list.groupName,
      'items': list.items.entries
          .map((entry) => MapEntry(
                entry.key,
                {
                  'itemId': entry.value.itemId,
                  'memberId': entry.value.memberId,
                  'name': entry.value.name,
                  'quantity': entry.value.quantity,
                  'registeredDate':
                      entry.value.registeredDate.toIso8601String(),
                  'purchaseDate': entry.value.purchaseDate?.toIso8601String(),
                  'isPurchased': entry.value.isPurchased,
                  'shoppingInterval': entry.value.shoppingInterval,
                  'deadline': entry.value.deadline?.toIso8601String(),
                  'isDeleted': entry.value.isDeleted,
                  'deletedAt': entry.value.deletedAt?.toIso8601String(),
                },
              ))
          .map((e) => MapEntry(e.key, e.value))
          .fold<Map<String, dynamic>>({}, (map, entry) {
        map[entry.key] = entry.value;
        return map;
      }),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// FirestoreのMapをSharedListに変換
  SharedList _mapToSharedList(Map<String, dynamic> data) {
    final itemsData = data['items'] as Map<String, dynamic>? ?? {};
    final items = itemsData.map((key, value) {
      final itemMap = value as Map<String, dynamic>;
      return MapEntry(
        key,
        SharedItem(
          itemId: itemMap['itemId'] ?? key,
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
          isDeleted: itemMap['isDeleted'] ?? false,
          deletedAt: itemMap['deletedAt'] != null
              ? DateTime.parse(itemMap['deletedAt'])
              : null,
        ),
      );
    });

    return SharedList.create(
      ownerUid: data['ownerUid'] ?? '',
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      listName: data['groupName'] ?? '',
      description: '',
      items: items,
    );
  }

  /// 繰り返し購入アイテムの処理
  SharedList _processRepeatPurchases(SharedList list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final processedItems = Map<String, SharedItem>.from(list.items);

    for (final entry in list.items.entries) {
      final item = entry.value;

      // 繰り返し購入の条件をチェック
      if (item.shoppingInterval > 0 &&
          item.isPurchased &&
          item.purchaseDate != null) {
        final purchaseDate = DateTime(item.purchaseDate!.year,
            item.purchaseDate!.month, item.purchaseDate!.day);

        final nextPurchaseDate =
            purchaseDate.add(Duration(days: item.shoppingInterval));

        // 次回購入予定日が今日以降で、同じ名前の未購入アイテムが存在しない場合
        if ((nextPurchaseDate.isBefore(today) ||
                nextPurchaseDate.isAtSameMomentAs(today)) &&
            !_hasUnpurchasedItemWithSameName(
                processedItems.values.toList(), item.name)) {
          // 1週間以下の間隔の場合は期限を1日後に、それ以外は間隔分長く
          DateTime? newDeadline;
          if (item.shoppingInterval <= 7) {
            newDeadline = DateTime.now().add(const Duration(days: 1));
          } else if (item.deadline != null) {
            newDeadline =
                item.deadline!.add(Duration(days: item.shoppingInterval));
          }

          final newItem = SharedItem.createNow(
            memberId: item.memberId,
            name: item.name,
            quantity: item.quantity,
            isPurchased: false,
            shoppingInterval: item.shoppingInterval,
            deadline: newDeadline,
          );

          processedItems[newItem.itemId] = newItem;
          AppLogger.info(
              '🔄 Created repeat purchase item: ${item.name} (${item.shoppingInterval} days interval)');
        }
      }
    }

    return list.copyWith(items: processedItems);
  }

  /// 同じ名前の未購入アイチE��が存在するかチェチE��
  bool _hasUnpurchasedItemWithSameName(List<SharedItem> items, String name) {
    return items.any((item) => item.name == name && !item.isPurchased);
  }

  /// Firebaseからの更新が必要かどうかを判断
  bool _shouldUpdateFromFirebase(
      SharedList hiveList, SharedList firebaseList) {
    // アイテム数が異なる場合は更新
    if (hiveList.items.length != firebaseList.items.length) {
      AppLogger.info(
          '📊 Item count differs: Hive=${hiveList.items.length}, Firebase=${firebaseList.items.length}');
      return true;
    }

    // 各アイテムの内容を比較
    final hiveItemsSet = hiveList.items.values
        .map((item) => '${item.name}_${item.memberId}_${item.isPurchased}')
        .toSet();
    final firebaseItemsSet = firebaseList.items.values
        .map((item) => '${item.name}_${item.memberId}_${item.isPurchased}')
        .toSet();

    if (!hiveItemsSet.containsAll(firebaseItemsSet) ||
        !firebaseItemsSet.containsAll(hiveItemsSet)) {
      AppLogger.info('🔄 Item content differs - updating from Firebase');
      return true;
    }

    AppLogger.info('✅ Hive and Firebase data are identical');
    return false;
  }

  // HiveSharedListRepositoryの追加メソチE��を委譲
  Future<void> deleteList(String groupId) async {
    await _hiveRepo.deleteList(groupId);

    final user = _currentUser;
    if (user != null) {
      try {
        final collection = _getUserSharedListsCollection();
        await collection?.doc(groupId).delete();
      } catch (e) {
        AppLogger.error('Firebase delete error: $e');
      }
    }
  }

  List<SharedList> getAllLists() {
    return _hiveRepo.getAllLists();
  }

  @override
  Future<SharedList> getOrCreateList(String groupId, String groupName) async {
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
  Future<SharedList> createSharedList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
  }) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<SharedList?> getSharedListById(String listId) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> updateSharedList(SharedList list) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> deleteSharedList(String groupId, String listId) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> addItemToList(String listId, SharedItem item) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> removeItemFromList(String listId, SharedItem item) async {
    throw UnimplementedError(
        'FirebaseRepository multi-list support not implemented yet');
  }

  @override
  Future<void> updateItemStatusInList(String listId, SharedItem item,
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
  Future<SharedList> getOrCreateDefaultList(
      String groupId, String groupName) async {
    return await getOrCreateList(groupId, groupName);
  }

  @override
  Future<void> deleteSharedListsByGroupId(String groupId) async {
    // Firebase実装では、グループ削除時に関連するショッピングリストも削除する
    // 現在はHiveリポジトリに委譲
    await _hiveRepo.deleteSharedListsByGroupId(groupId);
  }

  // === Realtime Sync Methods ===
  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) {
    // Firebase版はHiveのポーリング方式にフォールバック
    return _hiveRepo.watchSharedList(groupId, listId);
  }

  // === Differential Sync Methods (Map Format) ===
  @override
  Future<void> addSingleItem(String listId, SharedItem item) async {
    await _hiveRepo.addSingleItem(listId, item);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getSharedListById(listId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        AppLogger.error('Firebase sync error during add single item: $e');
      }
    }
  }

  @override
  Future<void> removeSingleItem(String listId, String itemId) async {
    await _hiveRepo.removeSingleItem(listId, itemId);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getSharedListById(listId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        AppLogger.error('Firebase sync error during remove single item: $e');
      }
    }
  }

  @override
  Future<void> updateSingleItem(String listId, SharedItem item) async {
    await _hiveRepo.updateSingleItem(listId, item);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getSharedListById(listId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        AppLogger.error('Firebase sync error during update single item: $e');
      }
    }
  }

  @override
  Future<void> cleanupDeletedItems(String listId,
      {int olderThanDays = 30}) async {
    await _hiveRepo.cleanupDeletedItems(listId, olderThanDays: olderThanDays);

    final user = _currentUser;
    if (user != null) {
      try {
        final list = await _hiveRepo.getSharedListById(listId);
        if (list != null) {
          await _syncToFirebase(list);
        }
      } catch (e) {
        AppLogger.error('Firebase sync error during cleanup deleted items: $e');
      }
    }
  }
}
