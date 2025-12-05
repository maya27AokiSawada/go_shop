# Go Shop - AI Coding Agent Instructions

## Project Overview
Go Shopは家族・グループ向けの買い物リスト共有Flutterアプリです。Firebase Auth（ユーザー認証）とCloud Firestore（データベース）を使用し、Hiveをローカルキャッシュとして併用するハイブリッド構成です。

## Architecture & Key Components

### State Management - Riverpod Patterns
```dart
// AsyncNotifierProvider pattern (primary)
final SharedGroupProvider = AsyncNotifierProvider<SharedGroupNotifier, SharedGroup>(
  () => SharedGroupNotifier(),
);

// Repository abstraction via Provider
final SharedGroupRepositoryProvider = Provider<SharedGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    // Production: Use Firestore with Hive cache (hybrid mode)
    return FirestoreSharedGroupRepository(ref);
  } else {
    // Development: Use Hive only for faster local testing
    return HiveSharedGroupRepository(ref);
  }
});
```

⚠️ **Critical**: Riverpod Generator is currently disabled due to version conflicts. Use traditional Provider syntax only.

### Data Layer - Repository Pattern
- **Abstract**: `lib/datastore/purchase_group_repository.dart`
- **Hive Implementation**: `lib/datastore/hive_purchase_group_repository.dart` (dev環境)
- **Firestore Implementation**: `lib/datastore/firestore_purchase_group_repository.dart` (prod環境)
- **Sync Service**: `lib/services/sync_service.dart` - Firestore ⇄ Hive同期を一元管理

Repository constructors must accept `Ref` for Riverpod integration:
```dart
class HiveSharedGroupRepository implements SharedGroupRepository {
  final Ref _ref;
  HiveSharedGroupRepository(this._ref);

  Box<SharedGroup> get _box => _ref.read(SharedGroupBoxProvider);
}
```

### Data Models - Freezed + Hive Integration
Models use both `@freezed` and `@HiveType` annotations:
```dart
@HiveType(typeId: 1)
@freezed
class SharedGroupMember with _$SharedGroupMember {
  const factory SharedGroupMember({
    @HiveField(0) @Default('') String memberId,  // Note: memberId not memberID
    @HiveField(1) required String name,
    // ...
  }) = _SharedGroupMember;
}
```

**Hive TypeIDs**: 0=SharedGroupRole, 1=SharedGroupMember, 2=SharedGroup, 3=ShoppingItem, 4=ShoppingList

### Environment Configuration
Use `lib/flavors.dart` for environment switching:
```dart
F.appFlavor = Flavor.dev;   // Hive only (local development)
F.appFlavor = Flavor.prod;  // Firestore + Hive hybrid (production)
```

**Current Setting**: `Flavor.prod` - Firestore with Hive caching enabled

## Critical Development Patterns

### Initialization Sequence
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  F.appFlavor = Flavor.dev;
  await _initializeHive();  // Must pre-open all Boxes
  runApp(ProviderScope(child: MyApp()));
}
```

### Error-Prone Areas to Avoid
1. **Property Naming**: Always use `memberId`, never `memberID`
2. **Null Safety**: Guard against `SharedGroup.members` being null
3. **Hive Box Access**: Ensure Boxes are opened in `_initializeHive()` before use
4. **Riverpod Generator**: DO NOT use - causes build failures

### Build & Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs  # For *.g.dart files
flutter analyze  # Check for compilation errors
```

Generated files: `*.g.dart` (Hive adapters), `*.freezed.dart` (Freezed classes)

## Development Workflows

### When Adding New Models
1. Add both `@HiveType(typeId: X)` and `@freezed` annotations
2. Register adapter in `main.dart`'s `_initializeHive()`
3. Open corresponding Box in initialization
4. Run code generation

### When Creating Providers
- Use traditional syntax, avoid Generator
- Follow `AsyncNotifierProvider` pattern for data state
- Inject Repository via `Provider<Repository>` pattern
- Access Hive Boxes through `ref.read(boxProvider)`

### Firebase Integration (Current Status)
Firebase is **actively used** in production environment:
- **Firebase Auth**: User authentication and session management
- **Cloud Firestore**: Primary database for groups, lists, and items
- **Hybrid Architecture**: Firestore (prod) + Hive cache for offline support
- **Sync Service**: `lib/services/sync_service.dart` handles bidirectional sync
- **Configuration**: `lib/firebase_options.dart` contains real credentials

Development workflow:
- `Flavor.dev`: Hive-only mode for fast local testing
- `Flavor.prod`: Full Firestore integration with Hive fallback

### QR Invitation System
**Single Source of Truth**: Use `qr_invitation_service.dart` only (旧招待システムは削除済み)

#### Invitation Data Structure
Firestore: `/invitations/{invitationId}`
```dart
{
  'invitationId': String,  // Generated ID
  'token': String,         // Same as invitationId (for Invitation model)
  'groupId': String,       // SharedGroupId
  'groupName': String,
  'invitedBy': String,     // inviter UID
  'inviterName': String,
  'securityKey': String,   // For validation
  'invitationToken': String, // JWT-like token
  'maxUses': 5,            // Max invitation slots
  'currentUses': 0,        // Current usage count
  'usedBy': [],            // Array of acceptor UIDs
  'status': 'pending',     // pending | accepted | expired
  'createdAt': Timestamp,
  'expiresAt': DateTime,   // 24 hours from creation
  'type': 'secure_qr_invitation',
  'version': '3.0'
}
```

#### Key Files
- **Service**: `lib/services/qr_invitation_service.dart`
  - `createQRInvitationData()`: Create invitation in Firestore
  - `acceptQRInvitation()`: Process invitation acceptance
  - `_updateInvitationUsage()`: Increment currentUses, add to usedBy
  - `_validateInvitationSecurity()`: Validate with securityKey

- **UI**: `lib/widgets/group_invitation_dialog.dart`
  - StreamBuilder for real-time invitation list
  - Display remainingUses (maxUses - currentUses)
  - QR code generation with `qr_flutter`
  - Delete and copy actions

- **Scanner**: `lib/widgets/accept_invitation_widget.dart`
  - QR scanning only (manual input removed)
  - Calls `acceptQRInvitation()` with invitationData

#### Critical Patterns
1. **Invitation Creation**:
   ```dart
   await _firestore.collection('invitations').doc(invitationId).set({
     ...invitationData,
     'maxUses': 5,
     'currentUses': 0,
     'usedBy': [],
   });
   ```

2. **Usage Update** (Atomic):
   ```dart
   await _firestore.collection('invitations').doc(invitationId).update({
     'currentUses': FieldValue.increment(1),
     'usedBy': FieldValue.arrayUnion([acceptorUid]),
     'lastUsedAt': FieldValue.serverTimestamp(),
   });
   ```

3. **Security Validation**:
   ```dart
   final securityKey = providedKey ?? invitationData['securityKey'];
   if (!_securityService.validateSecurityKey(securityKey, storedKey)) {
     throw Exception('Security validation failed');
   }
   ```

4. **Real-time List Display**:
   ```dart
   StreamBuilder<QuerySnapshot>(
     stream: _firestore.collection('invitations')
       .where('groupId', isEqualTo: groupId)
       .where('status', isEqualTo: 'pending')
       .snapshots(),
   )
   ```

#### Invitation Model Integration
- `lib/models/invitation.dart` provides:
  - `remainingUses`: getter for (maxUses - currentUses)
  - `isValid`: checks !isExpired && !isMaxUsesReached
  - `isMaxUsesReached`: currentUses >= maxUses

⚠️ **DELETED FILES** (Do not reference):
- ~~`invitation_repository.dart`~~
- ~~`firestore_invitation_repository.dart`~~
- ~~`invitation_provider.dart`~~
- ~~`invitation_management_dialog.dart`~~

### Default Group System (Updated: 2025-11-17)
**デフォルトグループ** = ユーザー専用のプライベートグループ

#### Identification Rules
**統一ヘルパー使用必須**: `lib/utils/group_helpers.dart`
```dart
bool isDefaultGroup(SharedGroup group, User? currentUser) {
  // Legacy support
  if (group.groupId == 'default_group') return true;

  // Official specification
  if (currentUser != null && group.groupId == currentUser.uid) return true;

  return false;
}
```

**判定条件**:
1. `groupId == 'default_group'` (レガシー対応)
2. `groupId == user.uid` (正式仕様)

#### Key Characteristics
- **groupId**: `user.uid` (ユーザー固有)
- **groupName**: `{userName}グループ` (例: "mayaグループ")
- **syncStatus**: `SyncStatus.local` (Firestoreに同期しない)
- **Deletion Protected**: UI/Repository/Providerの3層で保護
- **No Invitation**: 招待機能は無効化

#### Creation Logic
**AllGroupsNotifier.createDefaultGroup()** (`lib/providers/purchase_group_provider.dart`):
```dart
final defaultGroupId = user?.uid ?? 'local_default';
final defaultGroupName = '$displayNameグループ';

await hiveRepository.createGroup(
  defaultGroupId,  // Use user.uid directly
  defaultGroupName,
  ownerMember,
);
```

**Automatic Creation Triggers**:
1. App startup (if no groups exist)
2. User sign-in (via `authStateChanges()`)
3. UID change with data clear (explicit call in `user_id_change_helper.dart`)

#### Legacy Migration (Automatic)
**UserInitializationService** (STEP2-0):
```dart
// Migrate 'default_group' → user.uid on app startup
if (legacyGroupExists && !uidGroupExists) {
  final migratedGroup = legacyGroup.copyWith(
    groupId: user.uid,
    syncStatus: SyncStatus.local,
  );
  await hiveRepository.saveGroup(migratedGroup);
  await hiveRepository.deleteGroup('default_group');
}
```

#### Critical Implementation Points
1. **Always use helper method**: `isDefaultGroup(group, currentUser)`
2. **Never hardcode check**: Avoid `group.groupId == 'default_group'` directly
3. **Deletion prevention**: Check in UI, Repository, and Provider layers
4. **UID change handling**: Explicitly call `createDefaultGroup()` after data clear

**Modified Files** (2025-11-17):
- `lib/utils/group_helpers.dart` (new)
- `lib/helpers/user_id_change_helper.dart`
- `lib/services/user_initialization_service.dart`
- `lib/widgets/group_list_widget.dart`
- `lib/pages/group_member_management_page.dart`
- `lib/providers/purchase_group_provider.dart`
- `lib/datastore/hive_purchase_group_repository.dart`

### UID Change Detection & Data Migration
**Flow** (`lib/helpers/user_id_change_helper.dart`):
1. Detect UID change in `app_initialize_widget.dart`
2. Show `UserDataMigrationDialog` (初期化 / 引継ぎ)
3. If "初期化" selected:
   - Clear Hive boxes (SharedGroup + ShoppingList)
   - Call `SelectedGroupIdNotifier.clearSelection()`
   - Sync from Firestore (download new user's data)
   - **Create default group** (explicit call)
   - Invalidate providers sequentially

**Critical**: After UID change data clear, must explicitly create default group as `authStateChanges()` doesn't fire for existing login.

### App Mode & Terminology System (Added: 2025-11-18)
**アプリモード機能** = 買い物リストモード ⇄ TODOタスク管理モード切り替え

#### Architecture
**Central Configuration**: `lib/config/app_mode_config.dart`
```dart
enum AppMode { shopping, todo }

class AppModeConfig {
  final AppMode mode;

  String get groupName => mode == shopping ? 'グループ' : 'チーム';
  String get listName => mode == shopping ? 'リスト' : 'プロジェクト';
  String get itemName => mode == shopping ? 'アイテム' : 'タスク';
  // 50+ terminology mappings
}

class AppModeSettings {
  static AppMode _currentMode = AppMode.shopping;
  static AppModeConfig get config => AppModeConfig(_currentMode);
  static void setMode(AppMode mode) => _currentMode = mode;
}
```

#### Persistence Layer
**UserSettings Model** (`lib/models/user_settings.dart`):
```dart
@HiveField(5) @Default(0) int appMode;  // 0=shopping, 1=todo
```

**Mode Switching Flow**:
1. User taps mode button in `home_page.dart`
2. Save to Hive via `userSettingsRepository.saveSettings()`
3. Update global state: `AppModeSettings.setMode(newMode)`
4. Trigger UI refresh: `ref.read(appModeNotifierProvider.notifier).state = newMode`
5. All widgets using `AppModeSettings.config.*` update instantly

#### UI Integration Pattern
**Before** (hardcoded):
```dart
Text('グループ')
```

**After** (dynamic):
```dart
Text(AppModeSettings.config.groupName)  // 'グループ' or 'チーム'
```

#### Key Components
- **Config Provider**: `lib/providers/app_mode_notifier_provider.dart`
  - `appModeNotifierProvider`: StateProvider for triggering UI rebuilds
  - Watch this provider in screens that need immediate updates

- **Mode Switcher UI**: `lib/pages/home_page.dart` (lines 560-600)
  - SegmentedButton with shopping/todo options
  - Saves to Hive + updates AppModeSettings + invalidates providers

- **Initialization**: `lib/widgets/app_initialize_widget.dart`
  - Loads saved mode from Hive on app startup
  - Sets `AppModeSettings.setMode()` before UI renders

#### Critical Rules
1. **Always use config**: `AppModeSettings.config.{property}` for all UI text
2. **Never hardcode**: No `'グループ'` or `'リスト'` strings in widgets
3. **Import required**: `import '../config/app_mode_config.dart';`
4. **Watch provider**: For instant updates, `ref.watch(appModeNotifierProvider)`

#### Terminology Coverage (50+ terms)
- **Group**: groupName, createGroup, selectGroup, groupMembers
- **List**: listName, createList, selectList, shoppingList
- **Item**: itemName, addItem, itemList, itemCount
- **Actions**: createAction, editAction, deleteAction, shareAction
- **UI Labels**: All buttons, dialogs, snackbars, navigation labels

**Files Modified** (2025-11-18):
- `lib/config/app_mode_config.dart` (new - 345 lines)
- `lib/providers/app_mode_notifier_provider.dart` (new)
- `lib/pages/home_page.dart` (mode switcher removed - moved to settings)
- `lib/pages/settings_page.dart` (mode switcher added)
- `lib/screens/home_screen.dart` (BottomNavigationBar labels)
- `lib/widgets/app_initialize_widget.dart` (mode initialization)
- `lib/models/user_settings.dart` (appMode field added)

### UI Organization (Updated: 2025-11-19)
**Screen Separation**: Settings-related UI moved from home to dedicated settings page

**home_page.dart** (Authentication & Core Features):
- Login status display
- Firestore sync status display
- News & Ads panel
- Username panel
- Sign-in panel (when unauthenticated)
- Sign-out button (when authenticated)

**settings_page.dart** (Configuration & Development):
- Login status display
- Firestore sync status display
- **App mode switcher** (Shopping List ⇄ TODO Sharing)
- **Privacy settings** (Secret mode toggle)
- **Developer tools** (Test scenario execution)

**Critical Implementation**:
- App mode switcher uses `Consumer` pattern to watch `appModeNotifierProvider`
- Ensures UI updates immediately when mode changes
```dart
Consumer(
  builder: (context, ref, child) {
    final currentMode = ref.watch(appModeNotifierProvider);
    return SegmentedButton<AppMode>(
      selected: {currentMode},
      // ...
    );
  },
)
```

#### Access Control Integration
**Pre-signup restrictions**:
- `GroupVisibilityMode.defaultOnly`: Only default group visible
- `canCreateGroup() = false`: Group creation disabled
- User can only use default group (local-only)

**Post-signup capabilities**:
- `GroupVisibilityMode.all`: All groups visible
- `canCreateGroup() = true`: Group creation enabled
- Default group syncs to Firestore with `groupId = user.uid`

**Firestore Safety**:
- Default group uses `user.uid` as document key (unique per user)
- **Multiple default groups physically impossible** in Firestore
- Each user can only have ONE default group synced to Firestore

## Common Issues & Solutions
- **Build failures**: Check for Riverpod Generator imports, remove them
- **Missing variables**: Ensure controllers and providers are properly defined before use
- **Null reference errors**: Always null-check `members` lists and async data
- **Property not found**: Verify `memberId` vs `memberID` consistency across codebase
- **Default group not appearing**: Ensure `createDefaultGroup()` called after UID change data clear
- **App mode UI not updating**: Wrap SegmentedButton in `Consumer` to watch `appModeNotifierProvider`
- **Group/List sync delays**: Under investigation - check Firestore fetch time vs Hive save time

## Known Issues (As of 2025-11-22)
- None currently

## Recent Implementations (2025-11-22)

### Realtime Sync Feature (Phase 1 - Completed)
**Implementation**: Shopping list items sync instantly across devices without screen transitions.

#### Architecture
- **Firestore `snapshots()`**: Real-time Stream API for live updates
- **StreamBuilder**: Flutter widget for automatic UI rebuilds on data changes
- **HybridRepository**: Auto-switches between Firestore Stream (online) and 30-second polling (offline/dev)

#### Key Files
**Repository Layer**:
- `lib/datastore/shopping_list_repository.dart`: Added `watchShoppingList()` abstract method
- `lib/datastore/firestore_shopping_list_repository.dart`: Firestore `snapshots()` implementation
- `lib/datastore/hybrid_shopping_list_repository.dart`: Online/offline auto-switching
- `lib/datastore/hive_shopping_list_repository.dart`: 30-second polling fallback
- `lib/datastore/firebase_shopping_list_repository.dart`: Delegates to Hive polling

**UI Layer**:
- `lib/pages/shopping_list_page_v2.dart`: StreamBuilder integration
  - Removed `invalidate()` calls (causes current list to clear)
  - Added latest data fetch before item addition (`repository.getShoppingListById()`)
  - Fixed sync timing issue that caused item count limits

**QR System**:
- `lib/widgets/qr_invitation_widgets.dart`: Added `groupAllowedUids` parameter
- `lib/widgets/qr_code_panel_widget.dart`: Updated QRInviteButton usage

#### Critical Patterns
1. **StreamBuilder Usage**:
```dart
StreamBuilder<ShoppingList?>(
  stream: repository.watchShoppingList(groupId, listId),
  initialData: currentList,  // Prevents flicker
  builder: (context, snapshot) {
    final liveList = snapshot.data ?? currentList;
    // Auto-updates on Firestore changes
  },
)
```

2. **Item Addition (Latest Data Fetch)**:
```dart
// ❌ Wrong: Uses stale currentListProvider data
final updatedList = currentList.copyWith(items: [...currentList.items, newItem]);

// ✅ Correct: Fetch latest from Repository
final latestList = await repository.getShoppingListById(currentList.listId);
final updatedList = latestList.copyWith(items: [...latestList.items, newItem]);
await repository.updateShoppingList(updatedList);
// StreamBuilder auto-detects update, no invalidate needed
```

3. **Hybrid Cache Update**:
```dart
// watchShoppingList caches Firestore data to Hive
return _firestoreRepo!.watchShoppingList(groupId, listId).map((firestoreList) {
  if (firestoreList != null) {
    _hiveRepo.updateShoppingList(firestoreList);  // Not addItem!
  }
  return firestoreList;
});
```

#### Problems Solved
1. **Build errors**: Missing `watchShoppingList()` implementations in all Repository classes
2. **Current list clears**: Removed `ref.invalidate()` that cleared StreamBuilder's initialData
3. **Item count limit**: Fixed by fetching latest data before addition (sync timing issue)
4. **Cache corruption**: Fixed `addItem` → `updateShoppingList` in HybridRepository

#### Performance
- **Windows → Android**: Instant reflection (< 1 second)
- **Self-device**: Current list maintained, no screen transitions
- **9+ items**: Successfully tested, no limits

#### Design Document
`docs/shopping_list_realtime_sync_design.md` (361 lines)
- Phase 1: Basic realtime sync (✅ Completed 2025-11-22)
- Phase 2: Optimization (pending)
- Phase 3: Performance tuning (pending)

## Next Implementation (Planned for 2025-11-25+)

### Shopping Item UI Enhancements
**Goal**: Enable currently disabled features in `ShoppingItem` model

#### 1. Deadline (Shopping Deadline) Feature
**Model Field**: `DateTime? deadline`

**Planned Implementation**:
- Deadline picker dialog (date + time)
- Visual indicators:
  - Red badge for overdue items
  - Yellow badge for items due soon (< 3 days)
  - Countdown display ("2日後" / "期限切れ")
- Sort by deadline option
- Deadline notification (optional)

**UI Components**:
- Deadline icon in item card
- Swipe action for quick deadline setting
- Filter/sort dropdown

#### 2. Periodic Purchase (Shopping Interval) Feature
**Model Field**: `int? shoppingInterval` (days between purchases)

**Planned Implementation**:
- Interval setting dialog:
  - Weekly (7 days)
  - Bi-weekly (14 days)
  - Monthly (30 days)
  - Custom days
- Next purchase date calculation:
  - Based on `purchaseDate` + `shoppingInterval`
  - Display "次回購入予定: 11/30"
- Periodic item badge (🔄 icon)
- Auto-reminder when next purchase date approaches
- Statistics: "前回購入から○日経過"

**UI Components**:
- Periodic purchase toggle in add/edit dialog
- Badge display on item cards
- "Repurchase now" quick action

#### 3. Enhanced Item Card UI
**Planned Layout**:
```
┌─────────────────────────────────────┐
│ [✓] 牛乳 x2          🔄 [期限:2日後] │  ← Checkbox, Name, Badges
│     前回購入: 11/20   次回: 11/27    │  ← Purchase info
│     登録者: maya                     │  ← Member info
└─────────────────────────────────────┘
```

**Interaction Enhancements**:
- Swipe left: Delete
- Swipe right: Edit
- Long press: Detailed view with history
- Tap: Toggle purchase status

#### 4. Optional Enhancements
- Category tags (食品、日用品、etc.)
- Priority levels (high/medium/low)
- Notes field for additional details
- Photo attachment
- Price tracking

#### Implementation Strategy
1. **Start with Deadline**: Simpler feature, no calculations
2. **Add Periodic Purchase**: Requires date calculations
3. **Enhanced UI**: Integrate both features with rich card design
4. **Testing**: Ensure Firestore sync works with new fields

#### Files to Modify
- `lib/pages/shopping_list_page_v2.dart`: Enhanced item cards
- `lib/widgets/shopping_item_tile.dart` (new): Separate widget for item display
- `lib/widgets/item_edit_dialog.dart`: Add deadline/interval pickers
- `lib/models/shopping_item.dart`: Already has fields, no changes needed
- `lib/datastore/*_shopping_list_repository.dart`: No changes (fields already synced)

#### Design Considerations
- Maintain realtime sync (Phase 1 implementation)
- Ensure deadline/interval data syncs to Firestore
- Keep UI responsive with StreamBuilder pattern
- Add proper validation (deadline must be future date, interval > 0)

## ShoppingList Map Format & Differential Sync (Implemented: 2025-11-25)

### Architecture Overview
**From**: `List<ShoppingItem>` (Array-based, full list sync)
**To**: `Map<String, ShoppingItem>` (Dictionary-based, item-level sync)

**Purpose**: Enable real-time differential sync - send only changed items instead of entire list.

### Data Structure

#### ShoppingItem Model
```dart
@HiveType(typeId: 3)
@freezed
class ShoppingItem with _$ShoppingItem {
  const factory ShoppingItem({
    @HiveField(0) required String name,
    @HiveField(1) @Default(false) bool isPurchased,
    // ... existing fields ...

    // 🆕 New Fields (Phase 1-11)
    @HiveField(8) required String itemId,           // UUID v4, unique identifier
    @HiveField(9) @Default(false) bool isDeleted,   // Soft delete flag
    @HiveField(10) DateTime? deletedAt,             // Deletion timestamp
  }) = _ShoppingItem;
}
```

#### ShoppingList Model
```dart
@HiveField(3) @Default({}) Map<String, ShoppingItem> items,

// 🆕 New Getters
List<ShoppingItem> get activeItems =>
    items.values.where((item) => !item.isDeleted).toList();

int get deletedItemCount =>
    items.values.where((item) => item.isDeleted).length;

bool get needsCleanup => deletedItemCount > 10;
```

### Backward Compatibility

**Custom TypeAdapter** (`lib/adapters/shopping_item_adapter_override.dart`):
```dart
class ShoppingItemAdapterOverride extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 3;  // Override default ShoppingItemAdapter

  @override
  ShoppingItem read(BinaryReader reader) {
    final fields = <int, dynamic>{/* read fields */};

    return ShoppingItem(
      // Existing fields...
      itemId: (fields[8] as String?) ?? _uuid.v4(),  // 🔥 Auto-generate if null
      isDeleted: fields[9] as bool? ?? false,        // 🔥 Default value
      deletedAt: fields[10] as DateTime?,            // 🔥 Nullable allowed
    );
  }
}
```

**Registration** (main.dart):
```dart
void main() async {
  // 🔥 Register BEFORE default adapter initialization
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ShoppingItemAdapterOverride());
  }
  await UserSpecificHiveService.initializeAdapters();
  runApp(const ProviderScope(child: MyApp()));
}
```

### Differential Sync API

**Repository Methods** (`shopping_list_repository.dart`):
```dart
abstract class ShoppingListRepository {
  // 🔥 Send single item (not entire list)
  Future<void> addSingleItem(String listId, ShoppingItem item);

  // 🔥 Soft delete by itemId only
  Future<void> removeSingleItem(String listId, String itemId);

  // 🔥 Update single item (not entire list)
  Future<void> updateSingleItem(String listId, ShoppingItem item);

  // 🔥 Physical delete of soft-deleted items (30+ days old)
  Future<void> cleanupDeletedItems(String listId, {int olderThanDays = 30});
}
```

**Usage Pattern** (shopping_list_page_v2.dart):
```dart
// ❌ Old: Full list sync
await repository.updateShoppingList(currentList.copyWith(
  items: [...currentList.items, newItem],
));

// ✅ New: Differential sync
await repository.addSingleItem(currentList.listId, newItem);
```

### Maintenance Services

#### ListCleanupService
```dart
// Auto-cleanup on app startup (5 seconds delay)
final cleanupService = ListCleanupService(ref);
final deletedCount = await cleanupService.cleanupAllLists(
  olderThanDays: 30,
  forceCleanup: false,  // Only cleanup if needsCleanup == true
);
```

#### ShoppingListDataMigrationService
```dart
// Migrate old List<ShoppingItem> data to Map<String, ShoppingItem>
final migrationService = ShoppingListDataMigrationService(ref);
final status = await migrationService.checkMigrationStatus();
// status: { total: 10, migrated: 8, remaining: 2 }

await migrationService.migrateToMapFormat();  // With auto-backup
```

**UI Integration** (settings_page.dart):
- データメンテナンスセクション
- クリーンアップ実行ボタン
- 移行状況確認ボタン
- データ移行実行ボタン

### Critical Implementation Rules

1. **Always use `activeItems` getter for UI display**:
   ```dart
   // ❌ Wrong: Shows deleted items
   for (var item in currentList.items.values) { ... }

   // ✅ Correct: Shows only active items
   for (var item in currentList.activeItems) { ... }
   ```

2. **Use differential sync methods**:
   ```dart
   // ❌ Wrong: Sends entire list
   final updatedItems = {...currentList.items, newItem.itemId: newItem};
   await repository.updateShoppingList(currentList.copyWith(items: updatedItems));

   // ✅ Correct: Sends only new item
   await repository.addSingleItem(currentList.listId, newItem);
   ```

3. **Never modify items Map directly**:
   ```dart
   // ❌ Wrong: Direct mutation
   currentList.items[itemId] = updatedItem;

   // ✅ Correct: Use copyWith
   final updatedItems = Map<String, ShoppingItem>.from(currentList.items);
   updatedItems[itemId] = updatedItem;
   await repository.updateSingleItem(currentList.listId, updatedItem);
   ```

4. **Soft delete, not hard delete**:
   ```dart
   // ❌ Wrong: Remove from Map
   final updatedItems = Map<String, ShoppingItem>.from(currentList.items);
   updatedItems.remove(itemId);

   // ✅ Correct: Mark as deleted
   await repository.removeSingleItem(currentList.listId, itemId);
   // Repository marks item.isDeleted = true internally
   ```

### Performance Benefits

| Metric | Before (List) | After (Map) | Improvement |
|--------|--------------|-------------|-------------|
| Network payload (add 1 item) | Full list (~10KB) | Single item (~1KB) | 90% reduction |
| Sync time (1 item) | 500ms | 50ms | 10x faster |
| Item lookup complexity | O(n) | O(1) | Constant time |
| Conflict resolution | Full list merge | Item-level merge | Safer |

### Migration Path

**Phase 1-11 (Completed 2025-11-25)**:
- ✅ Data structure conversion (List → Map)
- ✅ Backward compatibility (ShoppingItemAdapterOverride)
- ✅ Differential sync API implementation
- ✅ Maintenance services (cleanup, migration)
- ✅ UI integration (settings page)
- ✅ Build & runtime testing

**Phase 12+ (Future)**:
- Real-time sync with Firestore `snapshots()`
- StreamBuilder integration
- Automatic conflict resolution

### Debugging Tips

**Check Hive field count**:
```bash
# ShoppingItem should have 11 fields (8 → 11)
dart run build_runner build --delete-conflicting-outputs
# Look for: "typeId = 3, numFields = 11"
```

**Verify adapter registration**:
```dart
// In main.dart, check console output:
// ✅ ShoppingItemAdapterOverride registered
```

**Inspect active vs deleted items**:
```dart
print('Total items: ${currentList.items.length}');
print('Active items: ${currentList.activeItems.length}');
print('Deleted items: ${currentList.deletedItemCount}');
print('Needs cleanup: ${currentList.needsCleanup}');
```

## Home Page UI & Authentication (Updated: 2025-12-03)

### Authentication Flow Separation
**ホーム画面で「アカウント作成」と「サインイン」を完全に分離**

#### UI Structure
```
Initial Screen:
┌─────────────────────────────────┐
│   🎒 Go Shop                    │
│   買い物リスト共有アプリ          │
├─────────────────────────────────┤
│   📋 プライバシー情報             │
├─────────────────────────────────┤
│  [👤 アカウント作成] (ElevatedButton)  │
│  [🔑 サインイン] (OutlinedButton)      │
└─────────────────────────────────┘
```

#### Account Creation Mode (`_isSignUpMode = true`)
**必須項目**: ディスプレイネーム + メール + パスワード

```dart
Future<void> _signUp() async {
  // 1. Firebase Authに登録
  await ref.read(authProvider).signUp(email, password);

  // 2. SharedPreferencesに保存
  await UserPreferencesService.saveUserName(userName);

  // 3. Firebase Auth displayNameを更新
  await user.updateDisplayName(userName);
  await user.reload();
}
```

**表示内容**:
- ✅ ディスプレイネーム入力フィールド（必須・バリデーション付き）
- ✅ メールアドレス入力
- ✅ パスワード入力（6文字以上）
- ✅ 「アカウントを作成」ボタン
- ✅ 「サインインへ」切り替えリンク

#### Sign-In Mode (`_isSignUpMode = false`)
**必須項目**: メール + パスワード（ディスプレイネーム不要）

```dart
Future<void> _signIn() async {
  // 1. Firebase Authでサインイン
  await ref.read(authProvider).signIn(email, password);

  // 2. Firebase AuthからSharedPreferencesに反映
  if (user?.displayName != null) {
    await UserPreferencesService.saveUserName(user.displayName!);
  }
}
```

**表示内容**:
- ✅ メールアドレス入力
- ✅ パスワード入力
- ✅ 「サインイン」ボタン
- ✅ 「アカウント作成へ」切り替えリンク

#### Mode Switching UI
```dart
Container(
  decoration: BoxDecoration(
    color: _isSignUpMode ? Colors.blue.shade50 : Colors.grey.shade100,
  ),
  child: Row(
    children: [
      Icon(_isSignUpMode ? Icons.person_add : Icons.login),
      Text(_isSignUpMode ? 'アカウント作成' : 'サインイン'),
      TextButton(
        onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
        child: Text(_isSignUpMode ? 'サインインへ' : 'アカウント作成へ'),
      ),
    ],
  ),
)
```

#### Error Handling (Improved Messages)
**アカウント作成時**:
- `email-already-in-use` → 「このメールアドレスは既に使用されています」
- `weak-password` → 「パスワードが弱すぎます」
- `invalid-email` → 「メールアドレスの形式が正しくありません」

**サインイン時**:
- `user-not-found` → 「ユーザーが見つかりません。アカウント作成が必要です」
- `wrong-password` / `invalid-credential` → 「メールアドレスまたはパスワードが正しくありません」

#### Critical Implementation Points
1. **ディスプレイネーム必須化** (アカウント作成時のみ)
   - バリデーションで空文字をブロック
   - SharedPreferences + Firebase Auth両方に保存

2. **サインイン時の自動反映**
   - Firebase AuthのdisplayNameが存在すればPreferencesに反映
   - 未設定でもサインイン可能（後から設定可能）

3. **モード切り替え**
   - `_isSignUpMode`フラグで動的にUI切り替え
   - フォームリセットで入力内容をクリア

4. **視覚的フィードバック**
   - アカウント作成成功時: 「ようこそ、○○さん」
   - サインイン成功時: 「サインインしました」

## Realtime Sync Feature (Completed: 2025-11-22)

### Implementation Status
**Phase 1**: Shopping list items sync instantly across devices without screen transitions. ✅

#### Architecture
- **Firestore `snapshots()`**: Real-time Stream API for live updates
- **StreamBuilder**: Flutter widget for automatic UI rebuilds on data changes
- **HybridRepository**: Auto-switches between Firestore Stream (online) and 30-second polling (offline/dev)

#### Key Files
**Repository Layer**:
- `lib/datastore/shopping_list_repository.dart`: Added `watchShoppingList()` abstract method
- `lib/datastore/firestore_shopping_list_repository.dart`: Firestore `snapshots()` implementation
- `lib/datastore/hybrid_shopping_list_repository.dart`: Online/offline auto-switching
- `lib/datastore/hive_shopping_list_repository.dart`: 30-second polling fallback
- `lib/datastore/firebase_shopping_list_repository.dart`: Delegates to Hive polling

**UI Layer**:
- `lib/pages/shopping_list_page_v2.dart`: StreamBuilder integration
  - Removed `invalidate()` calls (causes current list to clear)
  - Added latest data fetch before item addition (`repository.getShoppingListById()`)
  - Fixed sync timing issue that caused item count limits

#### Performance
- **Windows → Android**: Instant reflection (< 1 second)
- **Self-device**: Current list maintained, no screen transitions
- **Multiple items**: Successfully tested with 9+ items, no limits
- **Network efficiency**: 90% payload reduction with differential sync

#### Design Document
`docs/shopping_list_realtime_sync_design.md`
- Phase 1: Basic realtime sync (✅ Completed 2025-11-22)
- Phase 2: Optimization (pending)
- Phase 3: Performance tuning (pending)

## User Settings & Backward Compatibility (Updated: 2025-12-03)

### UserSettings Model & Adapter Override
**Problem**: Adding new HiveFields breaks backward compatibility with existing data.

**Solution**: Custom TypeAdapter with null-safe defaults.

```dart
// lib/adapters/user_settings_adapter_override.dart
class UserSettingsAdapterOverride extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 6;

  @override
  UserSettings read(BinaryReader reader) {
    final fields = <int, dynamic>{/* read fields */};

    return UserSettings(
      // Existing fields...
      enableListNotifications: (fields[6] as bool?) ?? true,  // 🔥 Default value
      appMode: (fields[5] as int?) ?? 0,  // 🔥 Default value
    );
  }
}
```

**Registration** (main.dart):
```dart
void main() async {
  // 🔥 Register BEFORE default adapter initialization
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(UserSettingsAdapterOverride());
  }
  await UserSpecificHiveService.initializeAdapters();
}
```

**Skip in UserSpecificHiveService**:
```dart
// lib/services/user_specific_hive_service.dart
if (typeId == 6) continue;  // UserSettingsAdapterOverride takes priority
```

### Logging System Standardization
**AppLogger統一** (main.dart):
- ✅ 18箇所のprint文をAppLogger.info/error/warningに変更
- ✅ Firebase初期化ログの統一
- ✅ アダプター登録ログの統一

```dart
// ❌ Before:
print('🔄 Firebase初期化開始...');

// ✅ After:
AppLogger.info('🔄 Firebase初期化開始...');
```

### User Name Display & Persistence
**home_page.dart**:
```dart
@override
void initState() {
  super.initState();
  _loadUserName();  // Load from SharedPreferences
}

Future<void> _loadUserName() async {
  final savedUserName = await UserPreferencesService.getUserName();
  if (savedUserName != null && savedUserName.isNotEmpty) {
    setState(() { userNameController.text = savedUserName; });
  }
}
```

**Data Flow**:
1. サインアップ時: `UserPreferencesService.saveUserName()` + `user.updateDisplayName()`
2. サインイン時: Firebase Auth → SharedPreferences反映
3. アプリ起動時: SharedPreferencesから自動ロード

## Known Issues (As of 2025-12-04)
- None currently

## Recent Implementations (2025-12-04)

### 1. Periodic Purchase Auto-Reset Feature ✅
**Purpose**: Automatically reset purchased items with periodic purchase intervals back to unpurchased state after the specified days.

#### Implementation Files
- **New Service**: `lib/services/periodic_purchase_service.dart` (209 lines)
  - `resetPeriodicPurchaseItems()`: Reset all lists
  - `resetPeriodicPurchaseItemsForList()`: Reset specific list
  - `_shouldResetItem()`: Reset judgment logic
  - `getPeriodicPurchaseInfo()`: Debug statistics

#### Automatic Execution
- **File**: `lib/widgets/app_initialize_widget.dart`
- **Timing**: 5 seconds after app startup (background)
- **Target**: All groups, all lists

#### Manual Execution
- **File**: `lib/pages/settings_page.dart`
- **Location**: Data maintenance section
- **Button**: "定期購入リセット実行" with result dialog

#### Reset Conditions
1. `isPurchased = true`
2. `shoppingInterval > 0`
3. `purchaseDate + shoppingInterval days <= now`

#### Reset Actions
- `isPurchased` → `false`
- `purchaseDate` → `null`
- Sync to both Firestore + Hive

### 2. Shopping Item User ID Fix ✅
**Problem**: Fixed `memberId` was hardcoded as `'dev_user'` when adding items.

**Solution**:
- **File**: `lib/pages/shopping_list_page_v2.dart`
- **Fix**: Get current Firebase Auth user from `authStateProvider`
- **Implementation**:
  ```dart
  final currentUser = ref.read(authStateProvider).value;
  final currentMemberId = currentUser?.uid ?? 'anonymous';

  final newItem = ShoppingItem.createNow(
    memberId: currentMemberId, // ✅ Actual user UID
    name: name,
    quantity: quantity,
    // ...
  );
  ```

### 3. SharedGroup Member Name Verification ✅
**Verification**: Confirmed that the past issue of hardcoded "ユーザー" string has been fixed.

**Result**: ✅ All implementations are correct
- Default group creation: Firestore → SharedPreferences → Firebase Auth → Email priority
- New group creation: SharedPreferences → Firestore → Firebase Auth
- Invitation acceptance: SharedPreferences → Firestore → Firebase Auth → Email

**Conclusion**: Current implementation correctly sets actual user names. The "ユーザー" fallback is only used when all retrieval methods fail.

### 4. AdMob Integration ✅
**Purpose**: Implement production AdMob advertising.

#### AdMob App ID Configuration
- **App ID**: Configured via `.env` file (`ADMOB_APP_ID`)
- **Android**: Configured in `AndroidManifest.xml`
- **iOS**: Configured in `Info.plist` with `GADApplicationIdentifier` key

#### Banner Ad Unit ID Configuration
- **Ad Unit ID**: Configured via `.env` file (`ADMOB_BANNER_AD_UNIT_ID` or `ADMOB_TEST_BANNER_AD_UNIT_ID`)
- **File**: `lib/services/ad_service.dart` (`_bannerAdUnitId`)

#### Home Page Banner Ad Implementation
- **New Widget**: `HomeBannerAdWidget`
  - Hidden until ad loaded
  - White background with light gray border
  - "広告" label display
  - Automatic memory management (dispose)

- **Placement**: `lib/pages/home_page.dart`
  - Position: Between news panel and username panel
  - Display: Authenticated users only

---

## Common Issues & Solutions
- **Build failures**: Check for Riverpod Generator imports, remove them
- **Missing variables**: Ensure controllers and providers are properly defined before use
- **Null reference errors**: Always null-check `members` lists and async data
- **Property not found**: Verify `memberId` vs `memberID` consistency across codebase
- **Default group not appearing**: Ensure `createDefaultGroup()` called after UID change data clear
- **App mode UI not updating**: Wrap SegmentedButton in `Consumer` to watch `appModeNotifierProvider`
- **Item count limits**: Always fetch latest data with `repository.getShoppingListById()` before updates
- **Current list clears on update**: Never use `ref.invalidate()` with StreamBuilder, it clears initialData
- **UserSettings read errors**: Ensure UserSettingsAdapterOverride is registered before other adapters
- **Display name not showing**: Check initState calls `_loadUserName()` in home_page.dart
- **AdMob not showing**: Verify App ID in AndroidManifest.xml/Info.plist, rebuild app completely
- **DropdownButton not updating**: Use `value` property instead of `initialValue` for reactive updates
- **UI shows stale data after invalidate**: Wait for provider refresh with `await ref.read(provider.future)`

## Critical Flutter/Riverpod Patterns (Added: 2025-12-05)

### DropdownButtonFormField - Reactive Updates
⚠️ **Critical**: Use `value` property for reactive updates, NOT `initialValue`

**Problem**: `initialValue` only sets the value once at widget creation and ignores subsequent state changes.

**Solution**: Use `value` property which reactively updates when provider state changes.

```dart
// ❌ Wrong: Non-reactive, ignores state changes
DropdownButtonFormField<String>(
  initialValue: ref.watch(currentListProvider)?.listId,
  items: lists.map((list) =>
    DropdownMenuItem(value: list.listId, child: Text(list.listName))
  ).toList(),
)

// ✅ Correct: Reactive, updates when provider changes
DropdownButtonFormField<String>(
  value: ref.watch(currentListProvider)?.listId,
  items: lists.map((list) =>
    DropdownMenuItem(value: list.listId, child: Text(list.listName))
  ).toList(),
)
```

**When to use**:
- Any UI that needs to reflect provider state changes
- Dropdown menus showing current selection
- Forms that update based on external state

### Async Timing Control with Riverpod
⚠️ **Critical**: `ref.invalidate()` only triggers refresh, does NOT wait for completion

**Problem**: When using `ref.invalidate()`, the provider refresh is asynchronous. UI may rebuild with stale data before Firestore fetch completes.

**Example Scenario**:
```dart
// User creates new shopping list
await repository.createShoppingList(newList);

// Set as current list
ref.read(currentListProvider.notifier).selectList(newList);

// Invalidate list provider to refresh from Firestore
ref.invalidate(groupShoppingListsProvider);

// ❌ Problem: Widget rebuilds HERE with stale data
// The dropdown shows null because lists array doesn't contain newList yet
```

**Solution**: Wait for provider refresh to complete before continuing

```dart
// ❌ Wrong: UI rebuilds with stale data
ref.invalidate(groupShoppingListsProvider);
// Widget rebuilds here, lists array still old

// ✅ Correct: Wait for refresh to complete
ref.invalidate(groupShoppingListsProvider);
await ref.read(groupShoppingListsProvider.future);
// Widget rebuilds here, lists array includes new data
```

**Real-world Example** (from `shopping_list_header_widget.dart`):
```dart
// After creating new list
await repository.createShoppingList(newList);
ref.read(currentListProvider.notifier).selectList(newList);

// Invalidate and WAIT for list refresh
ref.invalidate(groupShoppingListsProvider);
try {
  await ref.read(groupShoppingListsProvider.future);
  Log.info('✅ リスト一覧更新完了 - 新しいリストを含む');
} catch (e) {
  Log.error('❌ リスト一覧更新エラー: $e');
}

// Now dropdown will show newList correctly
```

**When to use**:
- After creating new entities that should appear in lists
- When UI depends on updated provider data
- Before navigating to screens that require fresh data

### StateNotifier State Preservation
⚠️ **Warning**: `ref.invalidate(stateNotifierProvider)` clears the state entirely

**Problem**: Invalidating a StateNotifier provider resets its state to initial value.

**Example**:
```dart
// currentListProvider is a StateNotifier
ref.invalidate(currentListProvider);
// ❌ currentList becomes null, losing user's selection
```

**Solution**: Only invalidate dependent data providers, not state holders

```dart
// ✅ Correct: Preserve current selection, refresh list data only
ref.invalidate(groupShoppingListsProvider);  // Refresh list data
await ref.read(groupShoppingListsProvider.future);
// currentListProvider maintains its state
```

**Pattern**:
- Keep StateNotifier providers for UI state (selections, current values)
- Use separate AsyncNotifier providers for data fetching
- Only invalidate data providers, let state providers persist

### Debugging Async Timing Issues
**Add strategic logging** to identify timing problems:

```dart
// Log when setting state
Log.info('📝 カレントリストを設定: ${list.listName} (${list.listId})');

// Log when building UI
Log.info('🔍 [DEBUG] _buildDropdown - currentValue: ${currentValue}, validValue: ${validValue}, items.length: ${items.length}');

// Log after provider refresh
await ref.read(provider.future);
Log.info('✅ プロバイダー更新完了');
```

**Common timing issue pattern**:
```
15:10:03.402 - 📝 Set current value: ABC
15:10:03.413 - 🔍 [DEBUG] validValue: null, items.length: 5  ← No ABC yet
15:10:03.693 - ✅ Got 6 items  ← ABC now included
15:10:03.718 - 🔍 [DEBUG] validValue: null, items.length: 6  ← Still null!
```

This indicates: Provider updated, but UI needs to wait for completion before rebuilding.

**Related Files**:
- `lib/widgets/shopping_list_header_widget.dart`: DropdownButton reactive updates, async timing control
- `lib/providers/current_list_provider.dart`: StateNotifier state preservation
- `lib/widgets/group_list_widget.dart`: Reference implementation of proper timing control

Focus on maintaining consistency with existing patterns rather than introducing new architectural approaches.

