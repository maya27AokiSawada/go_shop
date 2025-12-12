import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as developer;
import '../models/shared_list.dart';
import '../providers/hive_provider.dart';
import '../providers/auth_provider.dart';
import '../helpers/validation_service.dart';
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
      developer.log('⚠️ Box not available (normal during restart): $e');
      rethrow;
    } catch (e) {
      developer.log('❌ Failed to access SharedList box: $e');
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
      developer.log(
          '💾 HiveSharedListRepository: データを保存 - Key: ${list.listId}, Items: ${list.activeItems.length}個'); // 🆕 activeItems使用
      developer.log('📦 Box contents after save: ${box.length} lists total');

      // 保存確認
      final saved = box.get(list.listId);
      if (saved != null) {
        developer.log(
            '✅ 保存確認成功: ${saved.activeItems.length}個のアイテム'); // 🆕 activeItems使用
      } else {
        developer.log('❌ 保存確認失敗: データが見つかりません');
      }
    } catch (e) {
      developer.log('❌ HiveSharedListRepository: 保存エラー - $e');
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
      developer.log('🗑️ アイテム削除: ${item.name} (${updatedItems.length}個残存)');
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
      developer
          .log('✅ アイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"}');
    }
  }

  // 追加のヘルパーメソッド（抽象クラスには無いが便利）
  Future<void> deleteList(String groupId) async {
    final userKey = _getUserSpecificKey(groupId);
    await box.delete(userKey);
    developer.log('🗑️ リスト削除: $userKey');
  }

  List<SharedList> getAllLists() {
    final lists = box.values.toList();
    developer.log('📋 全リスト取得: ${lists.length}個');
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
  }) async {
    try {
      // Create new shopping list with generated listId
      final newList = SharedList.create(
        ownerUid: ownerUid,
        groupId: groupId,
        groupName:
            listName, // Note: groupName is required, use listName for now
        listName: listName,
        description: description ?? '',
        items: {}, // 🆕 Map形式
      );

      // Save to Hive using listId as key
      await box.put(newList.listId, newList);
      developer.log('🆕 新規リスト作成: ${newList.listName} (ID: ${newList.listId})');

      // `SharedGroup`から`sharedListIds`が削除されたため、この処理は不要
      // final SharedGroupBox = ref.read(SharedGroupBoxProvider);
      // final SharedGroup = SharedGroupBox.get(groupId);
      // if (SharedGroup != null) {
      //   final updatedSharedListIds = <String>[
      //     ...(SharedGroup.sharedListIds ?? []),
      //     newList.listId
      //   ];
      //   final updatedGroup =
      //       SharedGroup.copyWith(sharedListIds: updatedSharedListIds);
      //   await SharedGroupBox.put(groupId, updatedGroup);
      //   developer.log(
      //       '📝 グループ「${SharedGroup.groupName}」にリストID追加: ${newList.listId}');
      // }

      return newList;
    } catch (e) {
      developer.log('❌ リスト作成エラー: $e');
      rethrow;
    }
  }

  @override
  Future<SharedList?> getSharedListById(String listId) async {
    try {
      final list = box.get(listId);
      developer
          .log('🔍 リスト取得 (ID: $listId): ${list != null ? "成功" : "見つからない"}');
      return list;
    } catch (e) {
      developer.log('❌ リスト取得エラー (ID: $listId): $e');
      return null;
    }
  }

  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) async {
    try {
      // HiveのBox全体をスキャンし、groupIdが一致するものをフィルタリング
      final lists =
          box.values.where((list) => list.groupId == groupId).toList();

      developer.log('📋 グループ「$groupId」のリスト取得 (Hive): ${lists.length}個');
      return lists;
    } catch (e) {
      developer.log('❌ グループリスト取得エラー (Hive, Group: $groupId): $e');
      return [];
    }
  }

  @override
  Future<void> updateSharedList(SharedList list) async {
    try {
      await box.put(list.listId, list);
      developer.log('💾 リスト更新: ${list.listName} (ID: ${list.listId})');
    } catch (e) {
      developer.log('❌ リスト更新エラー (ID: ${list.listId}): $e');
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

        // `SharedGroup`から`sharedListIds`が削除されたため、この処理は不要
        // final SharedGroupBox = ref.read(SharedGroupBoxProvider);
        // final SharedGroup = SharedGroupBox.get(list.groupId);
        // if (SharedGroup != null) {
        //   final updatedSharedListIds = (SharedGroup.sharedListIds ?? [])
        //       .where((id) => id != listId)
        //       .toList()
        //       .cast<String>();
        //   final updatedGroup =
        //       SharedGroup.copyWith(sharedListIds: updatedSharedListIds);
        //   await SharedGroupBox.put(list.groupId, updatedGroup);
        //   developer
        //       .log('📝 グループ「${SharedGroup.groupName}」からリストID削除: $listId');
        // }

        developer.log(
            '🗑️ リスト削除: ${list.listName} (groupId: $groupId, listId: $listId)');
      } else {
        developer.log('⚠️ 削除対象リストが見つからない (groupId: $groupId, listId: $listId)');
      }
    } catch (e) {
      developer.log('❌ リスト削除エラー (ID: $listId): $e');
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
      developer.log('➕ アイテム追加: ${item.name} → リスト「${list.listName}」');
    } catch (e) {
      developer.log('❌ アイテム追加エラー (ListID: $listId): $e');
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
      developer.log('➖ アイテム削除: ${item.name} ← リスト「${list.listName}」');
    } catch (e) {
      developer.log('❌ アイテム削除エラー (ListID: $listId): $e');
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

      developer.log(
          '✅ アイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"} (リスト: ${list.listName})');
    } catch (e) {
      developer.log('❌ アイテムステータス更新エラー (ListID: $listId): $e');
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
      developer.log(
          '🧹 購入済みアイテムクリア: リスト「${list.listName}」 (残り: ${remainingItems.length}個)');
    } catch (e) {
      developer.log('❌ 購入済みアイテムクリアエラー (ListID: $listId): $e');
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
        developer.log('📋 デフォルトリスト取得: ${existingLists.first.listName}');
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

      developer.log('🆕 デフォルトリスト作成: ${defaultList.listName}');
      return defaultList;
    } catch (e) {
      developer.log('❌ デフォルトリスト取得/作成エラー (Group: $groupId): $e');
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
        developer.log(
            '🗑️ Group $groupId lists deleted from Hive: ${keysToDelete.length} lists');
      }
    } catch (e) {
      developer.log(
          '❌ Error deleting shopping lists by group ID $groupId from Hive: $e');
      rethrow;
    }
  }

  // === Realtime Sync Methods ===
  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) {
    // Hive doesn't support native streams, so we'll return a periodic polling stream
    developer.log('🔴 [HIVE_REALTIME] ポーリング開始: listId=$listId');

    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getSharedListById(listId);
    }).asyncMap((future) => future);
  }

  // 🆕 Map-based Differential Sync Methods
  @override
  Future<void> addSingleItem(String listId, SharedItem item) async {
    developer.log('🔄 [HIVE_DIFF] Adding single item: ${item.name}');

    final list = await getSharedListById(listId);
    if (list == null) throw Exception('List not found: $listId');

    final updatedItems = Map<String, SharedItem>.from(list.items);
    updatedItems[item.itemId] = item;

    final updatedList = list.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await updateSharedList(updatedList);
    developer.log('✅ [HIVE_DIFF] Item added to Hive');
  }

  @override
  Future<void> removeSingleItem(String listId, String itemId) async {
    developer.log('🔄 [HIVE_DIFF] Logically deleting item: $itemId');

    final list = await getSharedListById(listId);
    if (list == null) return;

    final item = list.items[itemId];
    if (item == null) {
      developer.log('⚠️ [HIVE_DIFF] Item not found: $itemId');
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
    developer.log('✅ [HIVE_DIFF] Item logically deleted in Hive');
  }

  @override
  Future<void> updateSingleItem(String listId, SharedItem item) async {
    developer.log('🔄 [HIVE_DIFF] Updating single item: ${item.name}');

    final list = await getSharedListById(listId);
    if (list == null) return;

    final updatedItems = Map<String, SharedItem>.from(list.items);
    updatedItems[item.itemId] = item;

    final updatedList = list.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await updateSharedList(updatedList);
    developer.log('✅ [HIVE_DIFF] Item updated in Hive');
  }

  @override
  Future<void> cleanupDeletedItems(String listId,
      {int olderThanDays = 30}) async {
    developer.log('🧹 [HIVE_CLEANUP] Starting cleanup for list: $listId');

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
      developer.log('🧹 [HIVE_CLEANUP] No items to cleanup');
      return;
    }

    final cleanedList = list.copyWith(
      items: cleanedItems,
      updatedAt: DateTime.now(),
    );

    await updateSharedList(cleanedList);
    developer.log('🧹 [HIVE_CLEANUP] Removed $removedCount items from Hive');
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
