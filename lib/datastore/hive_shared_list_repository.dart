import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/shared_list.dart';
import '../providers/hive_provider.dart';
import '../providers/auth_provider.dart';
import '../helpers/validation_service.dart';
import '../utils/app_logger.dart';
import 'shared_list_repository.dart';

class HiveSharedListRepository implements SharedListRepository {
  final Ref ref;

  HiveSharedListRepository(this.ref);

  Box<SharedList> get box {
    try {
      if (!Hive.isBoxOpen('sharedLists')) {
        throw StateError(
            'SharedList box is not open. This may occur during app restart.');
      }
      return ref.read(sharedListBoxProvider);
    } on StateError catch (e) {
      Log.warning('⚠️ Box not available (normal during restart): $e');
      rethrow;
    } catch (e, stackTrace) {
      Log.error('❌ Failed to access SharedList box: $e', e, stackTrace);
      rethrow;
    }
  }

  // ユーザーIDベースのキー生成
  String _getUserSpecificKey(String groupId) {
    // 認証状態からユーザーIDを取得
    final authState = ref.read(authStateProvider);
    return authState.when(
      data: (user) {
        if (user != null) {
          // Firebase UserまたはMockUserの場合、emailまたはuidを使用
          final userId = user.email ?? user.uid;
          return '${userId}_$groupId';
        }
        return 'anonymous_$groupId';
      },
      loading: () => 'loading_$groupId',
      error: (_, __) => 'error_$groupId',
    );
  }

  @override
  Future<SharedList?> getSharedList(String listId) async {
    // listIdで直接取得（新方式）
    return box.get(listId);
  }

  @override
  Future<void> addItem(SharedList list) async {
    try {
      // listIdをキーとして保存（updateSharedListと統一）
      await box.put(list.listId, list);
      Log.info(
          '💾 HiveSharedListRepository: データを保存 - Key: ${list.listId}, Items: ${list.activeItems.length}個'); // 🆕 activeItems使用
      Log.info('📦 Box contents after save: ${box.length} lists total');

      // 保存確認
      final saved = box.get(list.listId);
      if (saved != null) {
        Log.info(
            '✅ 保存確認成功: ${saved.activeItems.length}個のアイテム'); // 🆕 activeItems使用
      } else {
        Log.warning('❌ 保存確認失敗: データが見つかりません');
      }
    } catch (e, stackTrace) {
      Log.error('❌ HiveSharedListRepository: 保存エラー - $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearSharedList(String listId) async {
    // listIdで直接取得
    final list = box.get(listId);
    if (list != null) {
      final clearedList = list.copyWith(items: {});
      await box.put(listId, clearedList);
    }
  }

  @override
  Future<void> addSharedItem(String groupId, SharedItem item) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
    if (list != null) {
      // アイテム名の重複チェック
      final validation = ValidationService.validateItemName(
          item.name, list.items.values.toList(), item.memberId);
      if (validation.hasError) {
        throw Exception(validation.errorMessage);
      }

      final updatedItems = {...list.items, item.itemId: item};
      final updatedList = list.copyWith(items: updatedItems);
      await box.put(userKey, updatedList);
    } else {
      // SharedGroupから情報を取得して新規リストを作成
      final SharedGroupBox = ref.read(SharedGroupBoxProvider);
      final SharedGroup = SharedGroupBox.get(groupId);

      final newList = SharedList.create(
        ownerUid: SharedGroup?.ownerUid ?? 'defaultUser',
        groupId: groupId,
        groupName: SharedGroup?.groupName ?? 'Shopping List',
        listName: SharedGroup?.groupName ?? 'Shopping List',
        description: '',
        items: {item.itemId: item},
      );
      await box.put(userKey, newList);
    }
  }

  @override
  Future<void> removeSharedItem(String groupId, SharedItem item) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
    if (list != null) {
      // MapからitemIdで直接削除
      final updatedItems = Map<String, SharedItem>.from(list.items)
        ..remove(item.itemId);
      final updatedList = list.copyWith(items: updatedItems);
      await box.put(userKey, updatedList);
      Log.info('🗑️ アイテム削除: ${item.name} (${updatedItems.length}個残存)');
    }
  }

  @override
  Future<void> updateSharedItemStatus(String groupId, SharedItem item,
      {required bool isPurchased}) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
    if (list != null) {
      // 🆕 Map形式対応: itemIdで直接アクセス
      final updatedItems = Map<String, SharedItem>.from(list.items);
      if (updatedItems.containsKey(item.itemId)) {
        updatedItems[item.itemId] = updatedItems[item.itemId]!.copyWith(
          isPurchased: isPurchased,
          purchaseDate: isPurchased ? DateTime.now() : null,
        );
      }

      final updatedList = list.copyWith(items: updatedItems);
      await box.put(userKey, updatedList);
      Log.info('✅ アイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"}');
    }
  }

  // 追加のヘルパーメソッド（抽象クラスには無いが便利）
  Future<void> deleteList(String groupId) async {
    final userKey = _getUserSpecificKey(groupId);
    await box.delete(userKey);
    Log.info('🗑️ リスト削除: $userKey');
  }

  List<SharedList> getAllLists() {
    final lists = box.values.toList();
    Log.info('📋 全リスト取得: ${lists.length}個');
    return lists;
  }

  @override
  Future<SharedList> getOrCreateList(String groupId, String groupName) async {
    final userKey = _getUserSpecificKey(groupId);
    final existingList = box.get(userKey);
    if (existingList != null) {
      // 既存のリストがある場合、SharedGroupと同期して更新するかチェック
      final SharedGroupBox = ref.read(SharedGroupBoxProvider);
      final SharedGroup = SharedGroupBox.get(groupId);

      if (SharedGroup != null &&
          existingList.groupName != SharedGroup.groupName) {
        // グループ名が変更されている場合は更新
        final updatedList = existingList.copyWith(
          groupName: SharedGroup.groupName,
          ownerUid: SharedGroup.ownerUid ?? existingList.ownerUid,
        );
        await box.put(userKey, updatedList);
        return updatedList;
      }
      return existingList;
    }

    // 新規作成時はSharedGroupから情報を取得
    final SharedGroupBox = ref.read(SharedGroupBoxProvider);
    final SharedGroup = SharedGroupBox.get(groupId);

    final defaultList = SharedList.create(
      ownerUid: SharedGroup?.ownerUid ?? 'defaultUser',
      groupId: groupId,
      groupName: SharedGroup?.groupName ?? groupName,
      listName: SharedGroup?.groupName ?? groupName,
      description: 'デフォルトリスト',
      items: {}, // 🆕 Map形式
    );
    await box.put(userKey, defaultList);
    return defaultList;
  }

  // SharedGroupとの同期メソッド
  Future<void> syncWithSharedGroup(String groupId) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
    final SharedGroupBox = ref.read(SharedGroupBoxProvider);
    final SharedGroup = SharedGroupBox.get(groupId);

    if (list != null && SharedGroup != null) {
      // groupNameやownerUidが異なる場合は同期
      if (list.groupName != SharedGroup.groupName ||
          list.ownerUid != SharedGroup.ownerUid) {
        final syncedList = list.copyWith(
          groupName: SharedGroup.groupName,
          ownerUid: SharedGroup.ownerUid ?? list.ownerUid,
        );
        await box.put(userKey, syncedList);
      }
    }
  }

  // SharedItemのmemberIdが有効かチェック
  bool isValidMemberId(String groupId, String memberId) {
    final SharedGroupBox = ref.read(SharedGroupBoxProvider);
    final SharedGroup = SharedGroupBox.get(groupId);

    if (SharedGroup == null) return false;

    return SharedGroup.members?.any((member) => member.memberId == memberId) ??
        false;
  }

  // === New Multi-List Methods Implementation ===

  @override
  Future<SharedList> createSharedList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
    String? customListId, // 🆕 カスタムlistId（デバイスプレフィックス付き）
  }) async {
    try {
      // Create new shopping list with generated listId
      final newList = SharedList.create(
        ownerUid: ownerUid,
        groupId: groupId,
        groupName:
            listName, // Note: groupName is required, use listName for now
        listName: listName,
        listId: customListId, // 🆕 カスタムlistIdを使用
        description: description ?? '',
        items: {}, // 🆕 Map形式
      );

      // Save to Hive using listId as key
      await box.put(newList.listId, newList);
      Log.info('🆕 新規リスト作成: ${newList.listName} (ID: ${newList.listId})');

      return newList;
    } catch (e, stackTrace) {
      Log.error('❌ リスト作成エラー: $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<SharedList?> getSharedListById(String listId) async {
    try {
      final list = box.get(listId);
      Log.info('🔍 リスト取得 (ID: $listId): ${list != null ? "成功" : "見つからない"}');
      return list;
    } catch (e, stackTrace) {
      Log.error('❌ リスト取得エラー (ID: $listId): $e', e, stackTrace);
      return null;
    }
  }

  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) async {
    try {
      // HiveのBox全体をスキャンし、groupIdが一致するものをフィルタリング
      final lists =
          box.values.where((list) => list.groupId == groupId).toList();

      Log.info('📋 グループ「$groupId」のリスト取得 (Hive): ${lists.length}個');
      return lists;
    } catch (e, stackTrace) {
      Log.error('❌ グループリスト取得エラー (Hive, Group: $groupId): $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<void> updateSharedList(SharedList list) async {
    try {
      await box.put(list.listId, list);
      Log.info('💾 リスト更新: ${list.listName} (ID: ${list.listId})');
    } catch (e, stackTrace) {
      Log.error('❌ リスト更新エラー (ID: ${list.listId}): $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteSharedList(String groupId, String listId) async {
    try {
      final list = box.get(listId);
      if (list != null) {
        // Remove from Hive
        await box.delete(listId);

        Log.info(
            '🗑️ リスト削除: ${list.listName} (groupId: $groupId, listId: $listId)');
      } else {
        Log.warning('⚠️ 削除対象リストが見つからない (groupId: $groupId, listId: $listId)');
      }
    } catch (e, stackTrace) {
      Log.error('❌ リスト削除エラー (ID: $listId): $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addItemToList(String listId, SharedItem item) async {
    try {
      final list = box.get(listId);
      if (list == null) {
        throw Exception('リストが見つかりません (ID: $listId)');
      }

      // 🆕 ValidationはactiveItemsで行う
      final validation = ValidationService.validateItemName(
          item.name, list.activeItems, item.memberId);
      if (validation.hasError) {
        throw Exception(validation.errorMessage);
      }

      // 🆕 差分同期メソッドを使用
      await addSingleItem(listId, item);
      Log.info('➕ アイテム追加: ${item.name} → リスト「${list.listName}」');
    } catch (e, stackTrace) {
      Log.error('❌ アイテム追加エラー (ListID: $listId): $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeItemFromList(String listId, SharedItem item) async {
    try {
      final list = box.get(listId);
      if (list == null) {
        throw Exception('リストが見つかりません (ID: $listId)');
      }

      // 🆕 差分同期（論理削除）を使用
      await removeSingleItem(listId, item.itemId);
      Log.info('➖ アイテム削除: ${item.name} ← リスト「${list.listName}」');
    } catch (e, stackTrace) {
      Log.error('❌ アイテム削除エラー (ListID: $listId): $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateItemStatusInList(String listId, SharedItem item,
      {required bool isPurchased}) async {
    try {
      final list = box.get(listId);
      if (list == null) {
        throw Exception('リストが見つかりません (ID: $listId)');
      }

      // 🆕 差分同期メソッドを使用
      final updatedItem = item.copyWith(
        isPurchased: isPurchased,
        purchaseDate: isPurchased ? DateTime.now() : null,
      );
      await updateSingleItem(listId, updatedItem);

      Log.info(
          '✅ アイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"} (リスト: ${list.listName})');
    } catch (e, stackTrace) {
      Log.error('❌ アイテムステータス更新エラー (ListID: $listId): $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearPurchasedItemsFromList(String listId) async {
    try {
      final list = box.get(listId);
      if (list == null) {
        throw Exception('リストが見つかりません (ID: $listId)');
      }

      // 🆕 activeItemsから未購入のみ残す（Map形式）
      final remainingItems = <String, SharedItem>{};
      list.activeItems.where((item) => !item.isPurchased).forEach((item) {
        remainingItems[item.itemId] = item;
      });

      final updatedList = list.copyWith(
        items: remainingItems,
        updatedAt: DateTime.now(),
      );
      await box.put(listId, updatedList);
      Log.info(
          '🧹 購入済みアイテムクリア: リスト「${list.listName}」 (残り: ${remainingItems.length}個)');
    } catch (e, stackTrace) {
      Log.error('❌ 購入済みアイテムクリアエラー (ListID: $listId): $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<SharedList> getOrCreateDefaultList(
      String groupId, String groupName) async {
    try {
      // Check if group has any existing lists
      final existingLists = await getSharedListsByGroup(groupId);
      if (existingLists.isNotEmpty) {
        // Return the first list as default
        Log.info('📋 デフォルトリスト取得: ${existingLists.first.listName}');
        return existingLists.first;
      }

      // Create new default list
      final SharedGroupBox = ref.read(SharedGroupBoxProvider);
      final SharedGroup = SharedGroupBox.get(groupId);

      final defaultList = await createSharedList(
        ownerUid: SharedGroup?.ownerUid ?? 'defaultUser',
        groupId: groupId,
        listName: '$groupNameのリスト',
        description: 'デフォルトの買い物リスト',
      );

      Log.info('🆕 デフォルトリスト作成: ${defaultList.listName}');
      return defaultList;
    } catch (e, stackTrace) {
      Log.error('❌ デフォルトリスト取得/作成エラー (Group: $groupId): $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteSharedListsByGroupId(String groupId) async {
    try {
      // groupIdが一致するリストのキーを特定
      final keysToDelete =
          box.keys.where((key) => (box.get(key)?.groupId == groupId)).toList();

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        Log.info(
            '🗑️ Group $groupId lists deleted from Hive: ${keysToDelete.length} lists');
      }
    } catch (e, stackTrace) {
      Log.error(
          '❌ Error deleting shopping lists by group ID $groupId from Hive: $e',
          e,
          stackTrace);
      rethrow;
    }
  }

  // === Realtime Sync Constants ===
  // 🔴 [HIVE_REALTIME] Polling is no-op, returns empty stream.
  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) {
    Log.info('🔴 [HIVE_REALTIME] ポーリング開始: listId=$listId');

    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getSharedListById(listId);
    }).asyncMap((future) => future);
  }

  // 🆕 Map-based Differential Sync Methods
  @override
  Future<void> addSingleItem(String listId, SharedItem item) async {
    Log.info('🔄 [HIVE_DIFF] Adding single item: ${item.name}');

    final list = await getSharedListById(listId);
    if (list == null) throw Exception('List not found: $listId');

    final updatedItems = Map<String, SharedItem>.from(list.items);
    updatedItems[item.itemId] = item;

    final updatedList = list.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await updateSharedList(updatedList);
    Log.info('✅ [HIVE_DIFF] Item added to Hive');
  }

  @override
  Future<void> removeSingleItem(String listId, String itemId) async {
    Log.info('🔄 [HIVE_DIFF] Logically deleting item: $itemId');

    final list = await getSharedListById(listId);
    if (list == null) return;

    final item = list.items[itemId];
    if (item == null) {
      Log.warning('⚠️ [HIVE_DIFF] Item not found: $itemId');
      return;
    }

    final deletedItem = item.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
    );

    final updatedItems = Map<String, SharedItem>.from(list.items);
    updatedItems[itemId] = deletedItem;

    final updatedList = list.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await updateSharedList(updatedList);
    Log.info('✅ [HIVE_DIFF] Item logically deleted in Hive');
  }

  @override
  Future<void> updateSingleItem(String listId, SharedItem item) async {
    Log.info('🔄 [HIVE_DIFF] Updating single item: ${item.name}');

    final list = await getSharedListById(listId);
    if (list == null) return;

    final updatedItems = Map<String, SharedItem>.from(list.items);
    updatedItems[item.itemId] = item;

    final updatedList = list.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await updateSharedList(updatedList);
    Log.info('✅ [HIVE_DIFF] Item updated in Hive');
  }

  @override
  Future<void> cleanupDeletedItems(String listId,
      {int olderThanDays = 30}) async {
    Log.info('🧹 [HIVE_CLEANUP] Starting cleanup for list: $listId');

    final list = await getSharedListById(listId);
    if (list == null) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

    final cleanedItems = Map<String, SharedItem>.fromEntries(
      list.items.entries.where((entry) {
        final item = entry.value;
        if (!item.isDeleted) return true;
        if (item.deletedAt == null) return true;
        return item.deletedAt!.isAfter(cutoffDate);
      }),
    );

    final removedCount = list.items.length - cleanedItems.length;
    if (removedCount == 0) {
      Log.info('🧹 [HIVE_CLEANUP] No items to cleanup');
      return;
    }

    final cleanedList = list.copyWith(
      items: cleanedItems,
      updatedAt: DateTime.now(),
    );

    await updateSharedList(cleanedList);
    Log.info('🧹 [HIVE_CLEANUP] Removed $removedCount items from Hive');
  }
}

// Repository Provider
final hiveSharedListRepositoryProvider =
    Provider<HiveSharedListRepository>((ref) {
  return HiveSharedListRepository(ref);
});

final sharedListRepositoryProvider = Provider<SharedListRepository>((ref) {
  return ref.read(hiveSharedListRepositoryProvider);
});
