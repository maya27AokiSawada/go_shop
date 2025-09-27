// lib/datastore/repository/shopping_list_repository.dart
import '../models/shopping_list.dart';

abstract class ShoppingListRepository {
  Future<ShoppingList?> getShoppingList(String groupId);
  Future<void> addItem(ShoppingList list);
  Future<void> clearShoppingList(String groupId);
  Future<void> addShoppingItem(String groupId, ShoppingItem item);
  Future<void> removeShoppingItem(String groupId, ShoppingItem item);
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item,
       {required bool isPurchased});
}
