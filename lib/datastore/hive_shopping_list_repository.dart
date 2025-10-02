import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as developer;
import '../models/shopping_list.dart';
import '../providers/hive_provider.dart';
import 'shopping_list_repository.dart';

class HiveShoppingListRepository implements ShoppingListRepository {
  final Ref ref;
  
  HiveShoppingListRepository(this.ref);
  
  Box<ShoppingList> get box => ref.read(shoppingListBoxProvider);

  @override
  Future<ShoppingList?> getShoppingList(String groupId) async {
    return box.get(groupId);
  }

  @override
  Future<void> addItem(ShoppingList list) async {
    try {
      await box.put(list.groupId, list);
      developer.log('💾 HiveShoppingListRepository: データを保存 - Key: ${list.groupId}, Items: ${list.items.length}個');
      developer.log('📦 Box contents after save: ${box.length} lists total');
      
      // 保存確認
      final saved = box.get(list.groupId);
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
    final list = box.get(groupId);
    if (list != null) {
      final clearedList = list.copyWith(items: []);
      await box.put(groupId, clearedList);
    }
  }

  @override
  Future<void> addShoppingItem(String groupId, ShoppingItem item) async {
    final list = box.get(groupId);
    if (list != null) {
      final updatedItems = [...list.items, item];
      final updatedList = list.copyWith(items: updatedItems);
      await box.put(groupId, updatedList);
    } else {
      // PurchaseGroupから情報を取得して新規リストを作成
      final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
      final purchaseGroup = purchaseGroupBox.get(groupId);
      
      final newList = ShoppingList(
        ownerUid: purchaseGroup?.ownerUid ?? 'defaultUser',
        groupId: groupId,
        groupName: purchaseGroup?.groupName ?? 'Shopping List',
        items: [item],
      );
      await box.put(groupId, newList);
    }
  }

  @override
  Future<void> removeShoppingItem(String groupId, ShoppingItem item) async {
    final list = box.get(groupId);
    if (list != null) {
      // より厳密な比較でアイテムを特定（登録日時も考慮）
      final updatedItems = list.items.where((existingItem) => 
        !(existingItem.name == item.name && 
          existingItem.memberId == item.memberId &&
          existingItem.registeredDate == item.registeredDate)
      ).toList();
      final updatedList = list.copyWith(items: updatedItems);
      await box.put(groupId, updatedList);
      developer.log('🗑️ アイテム削除: ${item.name} (${updatedItems.length}個残存)');
    }
  }

  @override
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item, {required bool isPurchased}) async {
    final list = box.get(groupId);
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
      await box.put(groupId, updatedList);
      developer.log('✅ アイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"}');
    }
  }

  // 追加のヘルパーメソッド（抽象クラスには無いが便利）
  Future<void> deleteList(String groupId) async {
    await box.delete(groupId);
    developer.log('🗑️ リスト削除: $groupId');
  }

  List<ShoppingList> getAllLists() {
    final lists = box.values.toList();
    developer.log('📋 全リスト取得: ${lists.length}個');
    return lists;
  }

  @override
  Future<ShoppingList> getOrCreateList(String groupId, String groupName) async {
    final existingList = box.get(groupId);
    if (existingList != null) {
      // 既存のリストがある場合、PurchaseGroupと同期して更新するかチェック
      final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
      final purchaseGroup = purchaseGroupBox.get(groupId);
      
      if (purchaseGroup != null && existingList.groupName != purchaseGroup.groupName) {
        // グループ名が変更されている場合は更新
        final updatedList = existingList.copyWith(
          groupName: purchaseGroup.groupName,
          ownerUid: purchaseGroup.ownerUid ?? existingList.ownerUid,
        );
        await box.put(groupId, updatedList);
        return updatedList;
      }
      return existingList;
    }
    
    // 新規作成時はPurchaseGroupから情報を取得
    final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
    final purchaseGroup = purchaseGroupBox.get(groupId);
    
    final defaultList = ShoppingList(
      ownerUid: purchaseGroup?.ownerUid ?? 'defaultUser',
      groupId: groupId,
      groupName: purchaseGroup?.groupName ?? groupName,
      items: [],
    );
    await box.put(groupId, defaultList);
    return defaultList;
  }

  // PurchaseGroupとの同期メソッド
  Future<void> syncWithPurchaseGroup(String groupId) async {
    final list = box.get(groupId);
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
        await box.put(groupId, syncedList);
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
}

// Repository Provider
final hiveShoppingListRepositoryProvider = Provider<HiveShoppingListRepository>((ref) {
  return HiveShoppingListRepository(ref);
});

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ref.read(hiveShoppingListRepositoryProvider);
});
