// lib/datastore/repository/shared_list_repository.dart
import '../models/shared_list.dart';

abstract class SharedListRepository {
  // === Legacy Methods (for backward compatibility) ===
  @deprecated
  Future<SharedList?> getSharedList(String groupId);
  Future<void> addItem(SharedList list);
  @deprecated
  Future<void> clearSharedList(String groupId);
  @deprecated
  Future<void> addSharedItem(String groupId, SharedItem item);
  @deprecated
  Future<void> removeSharedItem(String groupId, SharedItem item);
  @deprecated
  Future<void> updateSharedItemStatus(String groupId, SharedItem item,
      {required bool isPurchased});
  @deprecated
  Future<SharedList> getOrCreateList(String groupId, String groupName);

  // === New Multi-List Methods ===
  /// Create a new shopping list for a group
  Future<SharedList> createSharedList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
  });

  /// Get a specific shopping list by listId
  Future<SharedList?> getSharedListById(String listId);

  /// Get all shopping lists for a specific group
  Future<List<SharedList>> getSharedListsByGroup(String groupId);

  /// Update an entire shopping list
  Future<void> updateSharedList(SharedList list);

  /// Delete a shopping list by listId
  Future<void> deleteSharedList(String groupId, String listId);
  Future<void> deleteSharedListsByGroupId(String groupId);

  /// Add item to a specific shopping list (by listId)
  Future<void> addItemToList(String listId, SharedItem item);

  /// Remove item from a specific shopping list (by listId)
  Future<void> removeItemFromList(String listId, SharedItem item);

  /// Update item status in a specific shopping list
  Future<void> updateItemStatusInList(String listId, SharedItem item,
      {required bool isPurchased});

  // 🆕 Map-based differential sync methods
  /// Add single item to list (Map differential sync)
  Future<void> addSingleItem(String listId, SharedItem item);

  /// Remove single item from list (Map differential sync - logical delete)
  Future<void> removeSingleItem(String listId, String itemId);

  /// Update single item in list (Map differential sync)
  Future<void> updateSingleItem(String listId, SharedItem item);

  /// Physically delete items marked as deleted (cleanup)
  Future<void> cleanupDeletedItems(String listId, {int olderThanDays = 30});

  /// Clear all purchased items from a specific shopping list
  Future<void> clearPurchasedItemsFromList(String listId);

  /// Get or create default list for a group (backward compatibility)
  Future<SharedList> getOrCreateDefaultList(String groupId, String groupName);

  // === Realtime Sync Methods ===
  /// Watch a specific shopping list for realtime updates
  /// Returns a Stream that emits the latest SharedList data whenever it changes
  /// Returns null if the list doesn't exist
  Stream<SharedList?> watchSharedList(String groupId, String listId);
}
