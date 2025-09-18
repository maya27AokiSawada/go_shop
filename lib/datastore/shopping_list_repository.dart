// lib/datastore/repository/shopping_list_repository.dart
import 'package:go_shopping/models/shopping_list.dart';

abstract class ShoppingListRepository {
  Future<ShoppingList?> getShoppingList();
  Future<void> addItem(ShoppingList list);
  Future<void> clearShoppingList();
  Future<void> addShoppingItem(ShoppingItem item);
  Future<void> removeShoppingItem(ShoppingItem item);
  Future<void> updateShoppingItemStatus(ShoppingItem item, {required bool isPurchased});
}