This file contains instructions for the Copilot.

**Naming Conventions**:
- Use `sharedGroup`, `sharedList`, and `sharedItem` for models and related components.
- The refactoring from `shoppingList` and `shoppingItem` is mostly complete. Ensure new code follows the `shared` naming convention.

**Hive TypeIDs**:
- 0: SharedGroupRole
- 1: SharedGroupMember
- 2: SharedGroup
- 3: SharedItem
- 4: SharedList

**Architecture**:
- The app uses a hybrid repository pattern (Hive for local cache, Firestore for remote).
- Data is read from Hive first (cache-first), then synced from Firestore.
- UI-related logic should be in the `pages` and `widgets` directories.
- Business logic is managed by Riverpod `Notifier` classes in the `providers` directory.
- Data access is handled by repositories in the `datastore` directory.