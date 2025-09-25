// lib/providers/shopping_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import '../providers/purchase_group_provider.dart';

// ShoppingListのBox管理
final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>('shoppingLists');
});

// ShoppingListの状態管理
final shoppingListProvider = AsyncNotifierProvider<ShoppingListNotifier, ShoppingList>(
  () => ShoppingListNotifier(),
);

class ShoppingListNotifier extends AsyncNotifier<ShoppingList> {
  static const String _key = 'current_list';

  @override
  Future<ShoppingList> build() async {
    final box = ref.read(shoppingListBoxProvider);
    final purchaseGroupAsync = ref.watch(purchaseGroupProvider);
    
    return await purchaseGroupAsync.when(
      data: (purchaseGroup) async {
        final savedList = box.get(_key);
        if (savedList != null) {
          // 既存リストのグループ情報を更新
          return ShoppingList(
            ownerUid: purchaseGroup.ownerUid ?? '',
            groupId: purchaseGroup.groupId,
            groupName: purchaseGroup.groupName,
            items: savedList.items,
          );
        } else {
          // 新しいリストを作成
          return ShoppingList(
            ownerUid: purchaseGroup.ownerUid ?? '',
            groupId: purchaseGroup.groupId,
            groupName: purchaseGroup.groupName,
            items: [],
          );
        }
      },
      loading: () => ShoppingList(
        ownerUid: '',
        groupId: 'loading',
        groupName: 'Loading...',
        items: [],
      ),
      error: (error, stack) => ShoppingList(
        ownerUid: '',
        groupId: 'error',
        groupName: 'Error',
        items: [],
      ),
    );
  }

  Future<void> addItem(ShoppingItem item) async {
    final currentList = await future;
    final updatedItems = [...currentList.items, item];
    final updatedList = ShoppingList(
      ownerUid: currentList.ownerUid,
      groupId: currentList.groupId,
      groupName: currentList.groupName,
      items: updatedItems,
    );
    
    state = AsyncValue.data(updatedList);
    await _saveToBox(updatedList);
  }

  Future<void> removeItem(ShoppingItem item) async {
    final currentList = await future;
    final updatedItems = currentList.items.where((i) =>
      i.memberId != item.memberId || i.name != item.name
    ).toList();
    
    final updatedList = ShoppingList(
      ownerUid: currentList.ownerUid,
      groupId: currentList.groupId,
      groupName: currentList.groupName,
      items: updatedItems,
    );
    
    state = AsyncValue.data(updatedList);
    await _saveToBox(updatedList);
  }

  Future<void> updateItem(ShoppingItem oldItem, ShoppingItem newItem) async {
    final currentList = await future;
    final updatedItems = currentList.items.map((item) {
      if (item.memberId == oldItem.memberId && item.name == oldItem.name) {
        return newItem;
      }
      return item;
    }).toList();
    
    final updatedList = ShoppingList(
      ownerUid: currentList.ownerUid,
      groupId: currentList.groupId,
      groupName: currentList.groupName,
      items: updatedItems,
    );
    
    state = AsyncValue.data(updatedList);
    await _saveToBox(updatedList);
  }

  Future<void> togglePurchased(ShoppingItem item) async {
    final currentList = await future;
    final updatedItems = currentList.items.map((i) {
      if (i.memberId == item.memberId && i.name == item.name) {
        return ShoppingItem(
          memberId: i.memberId,
          name: i.name,
          quantity: i.quantity,
          registeredDate: i.registeredDate,
          purchaseDate: i.isPurchased ? null : DateTime.now(),
          isPurchased: !i.isPurchased,
          shoppingInterval: i.shoppingInterval,
        );
      }
      return i;
    }).toList();
    
    final updatedList = ShoppingList(
      ownerUid: currentList.ownerUid,
      groupId: currentList.groupId,
      groupName: currentList.groupName,
      items: updatedItems,
    );
    
    state = AsyncValue.data(updatedList);
    await _saveToBox(updatedList);
  }

  Future<void> clearPurchasedItems() async {
    final currentList = await future;
    final unpurchasedItems = currentList.items.where((item) => !item.isPurchased).toList();
    
    final updatedList = ShoppingList(
      ownerUid: currentList.ownerUid,
      groupId: currentList.groupId,
      groupName: currentList.groupName,
      items: unpurchasedItems,
    );
    
    state = AsyncValue.data(updatedList);
    await _saveToBox(updatedList);
  }

  Future<void> _saveToBox(ShoppingList shoppingList) async {
    try {
      final box = ref.read(shoppingListBoxProvider);
      await box.put(_key, shoppingList);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// 購入済みアイテムのフィルタープロバイダー
final purchasedItemsProvider = Provider<List<ShoppingItem>>((ref) {
  final shoppingListAsync = ref.watch(shoppingListProvider);
  return shoppingListAsync.when(
    data: (list) => list.items.where((item) => item.isPurchased).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
});

// 未購入アイテムのフィルタープロバイダー
final unpurchasedItemsProvider = Provider<List<ShoppingItem>>((ref) {
  final shoppingListAsync = ref.watch(shoppingListProvider);
  return shoppingListAsync.when(
    data: (list) => list.items.where((item) => !item.isPurchased).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
});

// メンバー別アイテムのフィルタープロバイダー
final itemsByMemberProvider = Provider.family<List<ShoppingItem>, String>((ref, memberId) {
  final shoppingListAsync = ref.watch(shoppingListProvider);
  return shoppingListAsync.when(
    data: (list) => list.items.where((item) => item.memberId == memberId).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
});