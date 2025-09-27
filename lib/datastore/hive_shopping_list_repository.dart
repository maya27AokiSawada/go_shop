import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/shopping_list.dart';
import '../providers/hive_provider.dart';
import '../flavors.dart';

final String currentListId = F.appFlavor == Flavor.dev ? 'currentList' : 'currentList';

class HiveShoppingListRepository {
  final Ref ref;
  
  HiveShoppingListRepository(this.ref);
  
  Box<ShoppingList> get box => ref.read(shoppingListBoxProvider);

  Future<ShoppingList> getList(String listId) async {
    final list = box.get(listId);
    if (list != null) {
      return list;
    }
    
    final defaultList = ShoppingList(
      ownerUid: 'defaultUser',
      groupId: listId,
      groupName: 'Default List',
      items: [],
    );
    await box.put(listId, defaultList);
    return defaultList;
  }

  Future<ShoppingList> updateList(ShoppingList shoppingList) async {
    await box.put(shoppingList.groupId, shoppingList);
    return shoppingList;
  }

  Future<ShoppingList> addItem(ShoppingItem item) async {
    final currentList = box.get(currentListId);
    if (currentList != null) {
      final updatedItems = [...currentList.items, item];
      final updatedList = currentList.copyWith(items: updatedItems);
      await box.put(currentListId, updatedList);
      return updatedList;
    }
    throw Exception('No current list found');
  }

  Future<ShoppingList> removeItem(String itemId) async {
    final currentList = box.get(currentListId);
    if (currentList != null) {
      final updatedItems = currentList.items.where((item) => item.memberId != itemId).toList();
      final updatedList = currentList.copyWith(items: updatedItems);
      await box.put(currentListId, updatedList);
      return updatedList;
    }
    throw Exception('No current list found');
  }

  Future<ShoppingList> toggleItemPurchase(String itemName) async {
    final currentList = box.get(currentListId);
    if (currentList != null) {
      final updatedItems = currentList.items.map((item) {
        if (item.name == itemName) {
          return item.copyWith(
            isPurchased: !item.isPurchased,
            purchaseDate: !item.isPurchased ? DateTime.now() : null,
          );
        }
        return item;
      }).toList();
      
      final updatedList = currentList.copyWith(items: updatedItems);
      await box.put(currentListId, updatedList);
      return updatedList;
    }
    throw Exception('No current list found');
  }

  Future<void> deleteList(String listId) async {
    await box.delete(listId);
  }

  List<ShoppingList> getAllLists() {
    return box.values.toList();
  }
}