import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as developer;
import '../models/shopping_list.dart';
import '../providers/hive_provider.dart';
import '../providers/auth_provider.dart';
import '../helpers/validation_service.dart';
import 'shopping_list_repository.dart';

class HiveShoppingListRepository implements ShoppingListRepository {
  final Ref ref;

  HiveShoppingListRepository(this.ref);

  Box<ShoppingList> get box {
    try {
      if (!Hive.isBoxOpen('shoppingLists')) {
        throw StateError(
            'ShoppingList box is not open. This may occur during app restart.');
      }
      return ref.read(shoppingListBoxProvider);
    } on StateError catch (e) {
      developer.log('⚠️ Box not available (normal during restart): $e');
      rethrow;
    } catch (e) {
      developer.log('❌ Failed to access ShoppingList box: $e');
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
  Future<ShoppingList?> getShoppingList(String groupId) async {
    final userKey = _getUserSpecificKey(groupId);
    return box.get(userKey);
  }

  @override
  Future<void> addItem(ShoppingList list) async {
    try {
      final userKey = _getUserSpecificKey(list.groupId);
      await box.put(userKey, list);
      developer.log(
          '💾 HiveShoppingListRepository: データを保存 - Key: $userKey, Items: ${list.items.length}個');
      developer.log('📦 Box contents after save: ${box.length} lists total');

      // 保存確認
      final saved = box.get(userKey);
      if (saved != null) {
        developer.log('✅ 保存確認成功: ${saved.items.length}個のアイテム');
      } else {
        developer.log('❌ 保存確認失敗: データが見つかりません');
      }
    } catch (e) {
      developer.log('❌ HiveShoppingListRepository: 保存エラー - $e');
      rethrow;
    }
  }

  @override
  Future<void> clearShoppingList(String groupId) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
    if (list != null) {
      final clearedList = list.copyWith(items: []);
      await box.put(userKey, clearedList);
    }
  }

  @override
  Future<void> addShoppingItem(String groupId, ShoppingItem item) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
    if (list != null) {
      // アイテム名の重複チェック
      final validation = ValidationService.validateItemName(
          item.name, list.items, item.memberId);
      if (validation.hasError) {
        throw Exception(validation.errorMessage);
      }

      final updatedItems = [...list.items, item];
      final updatedList = list.copyWith(items: updatedItems);
      await box.put(userKey, updatedList);
    } else {
      // PurchaseGroupから情報を取得して新規リストを作成
      final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
      final purchaseGroup = purchaseGroupBox.get(groupId);

      final newList = ShoppingList.create(
        ownerUid: purchaseGroup?.ownerUid ?? 'defaultUser',
        groupId: groupId,
        groupName: purchaseGroup?.groupName ?? 'Shopping List',
        listName: purchaseGroup?.groupName ?? 'Shopping List',
        description: '',
        items: [item],
      );
      await box.put(userKey, newList);
    }
  }

  @override
  Future<void> removeShoppingItem(String groupId, ShoppingItem item) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
    if (list != null) {
      // より厳密な比較でアイテムを特定（登録日時も考慮）
      final updatedItems = list.items
          .where((existingItem) => !(existingItem.name == item.name &&
              existingItem.memberId == item.memberId &&
              existingItem.registeredDate == item.registeredDate))
          .toList();
      final updatedList = list.copyWith(items: updatedItems);
      await box.put(userKey, updatedList);
      developer.log('🗑️ アイテム削除: ${item.name} (${updatedItems.length}個残存)');
    }
  }

  @override
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item,
      {required bool isPurchased}) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
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

  List<ShoppingList> getAllLists() {
    final lists = box.values.toList();
    developer.log('📋 全リスト取得: ${lists.length}個');
    return lists;
  }

  @override
  Future<ShoppingList> getOrCreateList(String groupId, String groupName) async {
    final userKey = _getUserSpecificKey(groupId);
    final existingList = box.get(userKey);
    if (existingList != null) {
      // 既存のリストがある場合、PurchaseGroupと同期して更新するかチェック
      final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
      final purchaseGroup = purchaseGroupBox.get(groupId);

      if (purchaseGroup != null &&
          existingList.groupName != purchaseGroup.groupName) {
        // グループ名が変更されている場合は更新
        final updatedList = existingList.copyWith(
          groupName: purchaseGroup.groupName,
          ownerUid: purchaseGroup.ownerUid ?? existingList.ownerUid,
        );
        await box.put(userKey, updatedList);
        return updatedList;
      }
      return existingList;
    }

    // 新規作成時はPurchaseGroupから情報を取得
    final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
    final purchaseGroup = purchaseGroupBox.get(groupId);

    final defaultList = ShoppingList.create(
      ownerUid: purchaseGroup?.ownerUid ?? 'defaultUser',
      groupId: groupId,
      groupName: purchaseGroup?.groupName ?? groupName,
      listName: purchaseGroup?.groupName ?? groupName,
      description: 'デフォルトリスト',
      items: [],
    );
    await box.put(userKey, defaultList);
    return defaultList;
  }

  // PurchaseGroupとの同期メソッド
  Future<void> syncWithPurchaseGroup(String groupId) async {
    final userKey = _getUserSpecificKey(groupId);
    final list = box.get(userKey);
    final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
    final purchaseGroup = purchaseGroupBox.get(groupId);

    if (list != null && purchaseGroup != null) {
      // groupNameやownerUidが異なる場合は同期
      if (list.groupName != purchaseGroup.groupName ||
          list.ownerUid != purchaseGroup.ownerUid) {
        final syncedList = list.copyWith(
          groupName: purchaseGroup.groupName,
          ownerUid: purchaseGroup.ownerUid ?? list.ownerUid,
        );
        await box.put(userKey, syncedList);
      }
    }
  }

  // ShoppingItemのmemberIdが有効かチェック
  bool isValidMemberId(String groupId, String memberId) {
    final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
    final purchaseGroup = purchaseGroupBox.get(groupId);

    if (purchaseGroup?.members == null) return false;

    return purchaseGroup!.members!.any((member) => member.memberId == memberId);
  }

  // === New Multi-List Methods Implementation ===

  @override
  Future<ShoppingList> createShoppingList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
  }) async {
    try {
      // Create new shopping list with generated listId
      final newList = ShoppingList.create(
        ownerUid: ownerUid,
        groupId: groupId,
        groupName:
            listName, // Note: groupName is required, use listName for now
        listName: listName,
        description: description ?? '',
        items: [],
      );

      // Save to Hive using listId as key
      await box.put(newList.listId, newList);
      developer.log('🆕 新規リスト作成: ${newList.listName} (ID: ${newList.listId})');

      // `PurchaseGroup`から`shoppingListIds`が削除されたため、この処理は不要
      // final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
      // final purchaseGroup = purchaseGroupBox.get(groupId);
      // if (purchaseGroup != null) {
      //   final updatedShoppingListIds = <String>[
      //     ...(purchaseGroup.shoppingListIds ?? []),
      //     newList.listId
      //   ];
      //   final updatedGroup =
      //       purchaseGroup.copyWith(shoppingListIds: updatedShoppingListIds);
      //   await purchaseGroupBox.put(groupId, updatedGroup);
      //   developer.log(
      //       '📝 グループ「${purchaseGroup.groupName}」にリストID追加: ${newList.listId}');
      // }

      return newList;
    } catch (e) {
      developer.log('❌ リスト作成エラー: $e');
      rethrow;
    }
  }

  @override
  Future<ShoppingList?> getShoppingListById(String listId) async {
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
  Future<List<ShoppingList>> getShoppingListsByGroup(String groupId) async {
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
  Future<void> updateShoppingList(ShoppingList list) async {
    try {
      await box.put(list.listId, list);
      developer.log('💾 リスト更新: ${list.listName} (ID: ${list.listId})');
    } catch (e) {
      developer.log('❌ リスト更新エラー (ID: ${list.listId}): $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteShoppingList(String listId) async {
    try {
      final list = box.get(listId);
      if (list != null) {
        // Remove from Hive
        await box.delete(listId);

        // `PurchaseGroup`から`shoppingListIds`が削除されたため、この処理は不要
        // final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
        // final purchaseGroup = purchaseGroupBox.get(list.groupId);
        // if (purchaseGroup != null) {
        //   final updatedShoppingListIds = (purchaseGroup.shoppingListIds ?? [])
        //       .where((id) => id != listId)
        //       .toList()
        //       .cast<String>();
        //   final updatedGroup =
        //       purchaseGroup.copyWith(shoppingListIds: updatedShoppingListIds);
        //   await purchaseGroupBox.put(list.groupId, updatedGroup);
        //   developer
        //       .log('📝 グループ「${purchaseGroup.groupName}」からリストID削除: $listId');
        // }

        developer.log('🗑️ リスト削除: ${list.listName} (ID: $listId)');
      } else {
        developer.log('⚠️ 削除対象リストが見つからない (ID: $listId)');
      }
    } catch (e) {
      developer.log('❌ リスト削除エラー (ID: $listId): $e');
      rethrow;
    }
  }

  @override
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    try {
      final list = box.get(listId);
      if (list == null) {
        throw Exception('リストが見つかりません (ID: $listId)');
      }

      // Validation
      final validation = ValidationService.validateItemName(
          item.name, list.items, item.memberId);
      if (validation.hasError) {
        throw Exception(validation.errorMessage);
      }

      final updatedList = list.copyWith(
        items: [...list.items, item],
        updatedAt: DateTime.now(),
      );
      await box.put(listId, updatedList);
      developer.log('➕ アイテム追加: ${item.name} → リスト「${list.listName}」');
    } catch (e) {
      developer.log('❌ アイテム追加エラー (ListID: $listId): $e');
      rethrow;
    }
  }

  @override
  Future<void> removeItemFromList(String listId, ShoppingItem item) async {
    try {
      final list = box.get(listId);
      if (list == null) {
        throw Exception('リストが見つかりません (ID: $listId)');
      }

      final updatedItems = list.items
          .where((existingItem) => !(existingItem.name == item.name &&
              existingItem.memberId == item.memberId &&
              existingItem.registeredDate == item.registeredDate))
          .toList();

      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      await box.put(listId, updatedList);
      developer.log('➖ アイテム削除: ${item.name} ← リスト「${list.listName}」');
    } catch (e) {
      developer.log('❌ アイテム削除エラー (ListID: $listId): $e');
      rethrow;
    }
  }

  @override
  Future<void> updateItemStatusInList(String listId, ShoppingItem item,
      {required bool isPurchased}) async {
    try {
      final list = box.get(listId);
      if (list == null) {
        throw Exception('リストが見つかりません (ID: $listId)');
      }

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

      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      await box.put(listId, updatedList);
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

      final unpurchasedItems =
          list.items.where((item) => !item.isPurchased).toList();
      final updatedList = list.copyWith(
        items: unpurchasedItems,
        updatedAt: DateTime.now(),
      );
      await box.put(listId, updatedList);
      developer.log(
          '🧹 購入済みアイテムクリア: リスト「${list.listName}」 (残り: ${unpurchasedItems.length}個)');
    } catch (e) {
      developer.log('❌ 購入済みアイテムクリアエラー (ListID: $listId): $e');
      rethrow;
    }
  }

  @override
  Future<ShoppingList> getOrCreateDefaultList(
      String groupId, String groupName) async {
    try {
      // Check if group has any existing lists
      final existingLists = await getShoppingListsByGroup(groupId);
      if (existingLists.isNotEmpty) {
        // Return the first list as default
        developer.log('📋 デフォルトリスト取得: ${existingLists.first.listName}');
        return existingLists.first;
      }

      // Create new default list
      final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
      final purchaseGroup = purchaseGroupBox.get(groupId);

      final defaultList = await createShoppingList(
        ownerUid: purchaseGroup?.ownerUid ?? 'defaultUser',
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
  Future<void> deleteShoppingListsByGroupId(String groupId) async {
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
}

// Repository Provider
final hiveShoppingListRepositoryProvider =
    Provider<HiveShoppingListRepository>((ref) {
  return HiveShoppingListRepository(ref);
});

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ref.read(hiveShoppingListRepositoryProvider);
});
