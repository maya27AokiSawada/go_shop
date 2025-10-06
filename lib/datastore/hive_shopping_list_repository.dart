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
        throw StateError('ShoppingList box is not open. This may occur during app restart.');
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
          final userId = user.email ?? user.uid ?? 'anonymous';
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
      developer.log('💾 HiveShoppingListRepository: データを保存 - Key: $userKey, Items: ${list.items.length}個');
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
      final validation = ValidationService.validateItemName(item.name, list.items, item.memberId);
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
      
      final newList = ShoppingList(
        ownerUid: purchaseGroup?.ownerUid ?? 'defaultUser',
        groupId: groupId,
        groupName: purchaseGroup?.groupName ?? 'Shopping List',
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
      final updatedItems = list.items.where((existingItem) => 
        !(existingItem.name == item.name && 
          existingItem.memberId == item.memberId &&
          existingItem.registeredDate == item.registeredDate)
      ).toList();
      final updatedList = list.copyWith(items: updatedItems);
      await box.put(userKey, updatedList);
      developer.log('🗑️ アイテム削除: ${item.name} (${updatedItems.length}個残存)');
    }
  }

  @override
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item, {required bool isPurchased}) async {
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
      developer.log('✅ アイテムステータス更新: ${item.name} → ${isPurchased ? "購入済み" : "未購入"}');
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
      
      if (purchaseGroup != null && existingList.groupName != purchaseGroup.groupName) {
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
    
    final defaultList = ShoppingList(
      ownerUid: purchaseGroup?.ownerUid ?? 'defaultUser',
      groupId: groupId,
      groupName: purchaseGroup?.groupName ?? groupName,
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
}

// Repository Provider
final hiveShoppingListRepositoryProvider = Provider<HiveShoppingListRepository>((ref) {
  return HiveShoppingListRepository(ref);
});

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ref.read(hiveShoppingListRepositoryProvider);
});
