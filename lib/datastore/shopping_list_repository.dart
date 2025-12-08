// lib/datastore/repository/shopping_list_repository.dart
import '../models/shopping_list.dart';

abstract class ShoppingListRepository {
  // === Legacy Methods (for backward compatibility) ===
  @deprecated
  Future<ShoppingList?> getShoppingList(String groupId);
  Future<void> addItem(ShoppingList list);
  @deprecated
  Future<void> clearShoppingList(String groupId);
  @deprecated
  Future<void> addShoppingItem(String groupId, ShoppingItem item);
  @deprecated
  Future<void> removeShoppingItem(String groupId, ShoppingItem item);
  @deprecated
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item,
      {required bool isPurchased});
  @deprecated
  Future<ShoppingList> getOrCreateList(String groupId, String groupName);

  // === New Multi-List Methods ===
  /// Create a new shopping list for a group
  Future<ShoppingList> createShoppingList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
  });

  /// Get a specific shopping list by listId
  Future<ShoppingList?> getShoppingListById(String listId);

  /// Get all shopping lists for a specific group
  Future<List<ShoppingList>> getShoppingListsByGroup(String groupId);

  /// Update an entire shopping list
  Future<void> updateShoppingList(ShoppingList list);

  /// Delete a shopping list by listId
  Future<void> deleteShoppingList(String groupId, String listId);
  Future<void> deleteShoppingListsByGroupId(String groupId);

  /// Add item to a specific shopping list (by listId)
  Future<void> addItemToList(String listId, ShoppingItem item);

  /// Remove item from a specific shopping list (by listId)
  Future<void> removeItemFromList(String listId, ShoppingItem item);

  /// Update item status in a specific shopping list
  Future<void> updateItemStatusInList(String listId, ShoppingItem item,
      {required bool isPurchased});

  // 🆕 Map-based differential sync methods
  /// Add single item to list (Map differential sync)
  Future<void> addSingleItem(String listId, ShoppingItem item);

  /// Remove single item from list (Map differential sync - logical delete)
  Future<void> removeSingleItem(String listId, String itemId);

  /// Update single item in list (Map differential sync)
  Future<void> updateSingleItem(String listId, ShoppingItem item);

  /// Physically delete items marked as deleted (cleanup)
  Future<void> cleanupDeletedItems(String listId, {int olderThanDays = 30});

  /// Clear all purchased items from a specific shopping list
  Future<void> clearPurchasedItemsFromList(String listId);

  /// Get or create default list for a group (backward compatibility)
  Future<ShoppingList> getOrCreateDefaultList(String groupId, String groupName);

  // === Realtime Sync Methods ===
  /// Watch a specific shopping list for realtime updates
  /// Returns a Stream that emits the latest ShoppingList data whenever it changes
  /// Returns null if the list doesn't exist
  Stream<ShoppingList?> watchShoppingList(String groupId, String listId);
}
