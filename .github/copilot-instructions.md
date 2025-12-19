# Go Shop - AI Coding Agent Instructions

## 🚀 Quick Start for AI Agents (December 2025)

**Project**: Flutter multi-platform shopping list sharing app (家族・グループ向け買い物リスト共有アプリ)
**Architecture**: Firestore-first hybrid (Firestore → Hive cache), authentication-required
**State Management**: Riverpod (traditional syntax, NO generator)
**Key Pattern**: Repository pattern with differential sync for 90% network reduction

**Critical Rules**:

1. **Firestore FIRST**: Always read from Firestore when authenticated, cache to Hive
2. **Differential sync**: Use `addSingleItem()`, NOT full list updates
3. **Auth flow order**: Clear data → Auth → Set name → Sync → Invalidate providers
4. **Hive cleanup**: Remove other users' groups, NEVER touch Firestore
5. **Push to `oneness`** only unless explicitly told to push to `main`

**Recent Major Changes (2025-12-17/18)**:

- ✅ All CRUD operations migrated to Firestore-first
- ✅ SharedItem differential sync implemented (Map-based field updates)
- ✅ Authentication flow completely overhauled with proper data cleanup
- ✅ Default group creation now checks Firestore before Hive

---

## ⚠️ Critical Project Rules

### Git Push Policy

**IMPORTANT**: Always follow this push strategy unless explicitly instructed otherwise:

- **Default**: Push to `oneness` branch only

  ```bash
  git push origin oneness
  ```

- **When explicitly instructed**: Push to both `oneness` and `main`
  ```bash
  git push origin oneness
  git push origin oneness:main
  ```

**Reasoning**: `oneness` branch is for active development and testing. `main` branch receives stable, tested changes only when explicitly approved by the user.

---

## Project Overview

Go Shop は家族・グループ向けの買い物リスト共有 Flutter アプリです。Firebase Auth（ユーザー認証）と Cloud Firestore（データベース）を使用し、Hive をローカルキャッシュとして併用するハイブリッド構成です。

**Current Status (December 2025)**: Authentication-required app with Firestore-first architecture for all CRUD operations.

## Architecture & Key Components

### 🔥 Critical Architecture Shift (December 2025)

**Firestore-First Hybrid Pattern** - All three data layers now prioritize Firestore:

1. **SharedGroup** (Groups) - `lib/datastore/hybrid_purchase_group_repository.dart`
2. **SharedList** (Shopping Lists) - `lib/datastore/hybrid_shared_list_repository.dart`
3. **SharedItem** (List Items) - Differential sync via `addSingleItem()`, `updateSingleItem()`, `removeSingleItem()`

**Pattern**:

```dart
// ✅ Correct: Firestore first, Hive cache second
if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
  try {
    // 1. Fetch from Firestore (always latest)
    final firestoreData = await _firestoreRepo!.getData();

    // 2. Cache to Hive (for next fast read)
    await _hiveRepo.saveData(firestoreData);

    return firestoreData;
  } catch (e) {
    // Firestore error → Hive fallback
    return await _hiveRepo.getData();
  }
}
```

**Why This Matters**:

- Authentication is mandatory - users are always online
- Firestore has the source of truth
- Hive is now purely a cache, not primary storage
- 90% reduction in data transfer via differential sync (Map-based updates)

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
- **Hive Implementation**: `lib/datastore/hive_purchase_group_repository.dart` (dev 環境)
- **Firestore Implementation**: `lib/datastore/firestore_purchase_group_repository.dart` (prod 環境)
- **Sync Service**: `lib/services/sync_service.dart` - Firestore ⇄ Hive 同期を一元管理

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

**Hive TypeIDs**: 0=SharedGroupRole, 1=SharedGroupMember, 2=SharedGroup, 3=SharedItem, 4=SharedList

### Environment Configuration

Use `lib/flavors.dart` for environment switching:

```dart
F.appFlavor = Flavor.dev;   // Firestore + Hive hybrid (development)
F.appFlavor = Flavor.prod;  // Firestore + Hive hybrid (production)
```

**Current Setting**: `Flavor.prod` - Firestore with Hive caching enabled

**Important Change (2025-12-08)**: Both `dev` and `prod` flavors now use Firebase/Firestore. The distinction is primarily for debug banners and future feature flags, not for data layer switching.

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
5. **Data Operations**: Always use differential sync methods for SharedItem operations (see below)

### ⚡ Differential Sync Pattern (December 2025)

**Critical**: SharedItem uses Map format with field-level updates, not full list replacement.

```dart
// ❌ Wrong: Sends entire list (~5KB for 10 items)
final updatedItems = {...currentList.items, newItem.itemId: newItem};
await repository.updateSharedList(currentList.copyWith(items: updatedItems));

// ✅ Correct: Sends only changed item (~500B)
await repository.addSingleItem(currentList.listId, newItem);
await repository.updateSingleItem(currentList.listId, updatedItem);
await repository.removeSingleItem(currentList.listId, itemId);  // Soft delete
```

**Implementation** (`lib/datastore/firestore_shared_list_repository.dart`):

```dart
// Field-level update - only sends modified item
await _collection(list.groupId).doc(listId).update({
  'items.${item.itemId}': _itemToFirestore(item),  // Single field update
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**Performance Impact**:

- Before: 10 items = ~5KB per operation
- After: 1 item = ~500B per operation
- **90% network reduction achieved**

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
- **groupName**: `{userName}グループ` (例: "maya グループ")
- **syncStatus**: `SyncStatus.local` (Firestore に同期しない)
- **Deletion Protected**: UI/Repository/Provider の 3 層で保護
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
   - Clear Hive boxes (SharedGroup + SharedList)
   - Call `SelectedGroupIdNotifier.clearSelection()`
   - Sync from Firestore (download new user's data)
   - **Create default group** (explicit call)
   - Invalidate providers sequentially

**Critical**: After UID change data clear, must explicitly create default group as `authStateChanges()` doesn't fire for existing login.

### App Mode & Terminology System (Added: 2025-11-18)

**アプリモード機能** = 買い物リストモード ⇄ TODO タスク管理モード切り替え

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
- **List**: listName, createList, selectList, sharedList
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
- **Item count limits**: Always fetch latest data with `repository.getSharedListById()` before updates
- **Current list clears on update**: Never use `ref.invalidate()` with StreamBuilder, it clears initialData
- **UserSettings read errors**: Ensure UserSettingsAdapterOverride is registered before other adapters
- **Display name not showing**: Check initState calls `_loadUserName()` in home_page.dart
- **AdMob not showing**: Verify App ID in AndroidManifest.xml/Info.plist, rebuild app completely
- **DropdownButton not updating**: Use `value` property instead of `initialValue` for reactive updates
- **UI shows stale data after invalidate**: Wait for provider refresh with `await ref.read(provider.future)`
- **List deletion not syncing**: Use `deleteSharedList(groupId, listId)` with both parameters to avoid collection group query PERMISSION_DENIED
- **Wrong user's groups showing**: Clear Hive + SharedPreferences before sign-out, use Firestore-first reads on sign-in

## 🔐 Authentication & Data Management (December 2025)

### Critical Authentication Flow

**Authentication is MANDATORY** - App requires sign-in to access all features.

#### Sign-Up Process Order (Critical!)

```dart
// lib/pages/home_page.dart
// ⚠️ MUST follow this exact order:

// 1. Clear ALL local data BEFORE Firebase Auth registration
await UserPreferencesService.clearAllUserInfo();
await SharedGroupBox.clear();
await sharedListBox.clear();

// 2. Create Firebase Auth account
await ref.read(authProvider).signUp(email, password);

// 3. Set display name in both Firebase Auth and SharedPreferences
await UserPreferencesService.saveUserName(userName);
await user.updateDisplayName(userName);
await user.reload();

// 4. Invalidate providers to trigger re-initialization
ref.invalidate(allGroupsProvider);
// ... other providers

// 5. Trigger Firestore→Hive sync
await ref.read(forceSyncProvider.future);
```

#### Sign-Out Process

```dart
// 1. Clear Hive + SharedPreferences first
await SharedGroupBox.clear();
await sharedListBox.clear();
await UserPreferencesService.clearAllUserInfo();

// 2. Invalidate all providers
ref.invalidate(allGroupsProvider);
ref.invalidate(selectedGroupProvider);
// ... other providers

// 3. Firebase Auth sign-out last
await ref.read(authProvider).signOut();
```

#### Sign-In Process with Firestore Priority

```dart
// 1. Sign in with Firebase Auth
await ref.read(authProvider).signIn(email, password);

// 2. Retrieve and save user name
final firestoreUserName = await FirestoreUserNameService.getUserName();
await UserPreferencesService.saveUserName(firestoreUserName);

// 3. Wait for network stabilization
await Future.delayed(const Duration(seconds: 1));

// 4. Force Firestore→Hive sync
await ref.read(forceSyncProvider.future);
ref.invalidate(allGroupsProvider);

// 5. Wait for provider refresh
await Future.delayed(const Duration(milliseconds: 500));
```

### 🔥 Firestore-First Default Group Creation

**Critical Pattern** (`lib/providers/purchase_group_provider.dart`):

```dart
// ✅ Correct: Check Firestore FIRST when signed in
if (user != null && F.appFlavor == Flavor.prod) {
  try {
    // 1. Query Firestore for existing default group (groupId = user.uid)
    final groupsSnapshot = await firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: user.uid)
        .get();

    final defaultGroupDoc = groupsSnapshot.docs.firstWhere(
      (doc) => doc.id == user.uid,
      orElse: () => throw Exception('No default group'),
    );

    // 2. Found in Firestore → Sync to Hive and return
    final firestoreGroup = SharedGroup.fromFirestore(defaultGroupDoc);
    await hiveRepository.saveGroup(firestoreGroup);

    // 3. Cleanup invalid groups in Hive
    await _cleanupInvalidHiveGroups(user.uid, hiveRepository);

    return;
  } catch (e) {
    // 4. Not found in Firestore → Create new
    await _createNewDefaultGroup(user);
  }
}

// ❌ Wrong: Checking Hive first (old pattern)
final existingGroups = await hiveRepository.getAllGroups();
if (existingGroups.any((g) => g.groupId == user.uid)) {
  return; // This misses Firestore updates!
}
```

### Hive Cleanup Strategy

**Purpose**: Remove other users' cached groups from local Hive storage.

```dart
Future<void> _cleanupInvalidHiveGroups(
  String currentUserId,
  HiveSharedGroupRepository hiveRepository,
) async {
  final allHiveGroups = await hiveRepository.getAllGroups();

  for (final group in allHiveGroups) {
    // Delete if current user NOT in allowedUid
    if (!group.allowedUid.contains(currentUserId)) {
      await hiveRepository.deleteGroup(group.groupId);  // ⚠️ Hive only, NOT Firestore
    }
  }
}
```

**⚠️ CRITICAL**: Never delete from Firestore during cleanup - other users may still need those groups!

## Known Issues (As of 2025-12-15)

### 1. TBA1011 Firestore Sync Error (Unresolved) ⚠️

**Symptom**: Red cloud icon with X mark (network disconnected state)

**Occurrence**: On Android device TBA1011 (JA5-TBA1011, Android 15)

**Error**: `Unable to resolve host firestore.googleapis.com`

**Status**:

- Network connectivity confirmed (ping tests pass)
- 2-second initialization delay implemented (ineffective)
- Device can function as QR generation device (Hive local-only mode)

**Suspected Causes**:

- Device-specific DNS configuration
- Private DNS settings
- Firestore SDK timing issues

**Workaround**: Use TBA1011 for local operations only, rely on other devices for Firestore sync

### 2. QR Code Scan Non-Responsiveness (Investigation) 🔍

**Symptom**: SH 54D doesn't respond when scanning QR codes from TBA1011

**Implemented Diagnostics**:

- MobileScanner debug logging added
- QR code size increased to 250px
- QR data reduced to 5 fields (v3.1 lightweight)

**Next Steps**:

- Verify debug logs show `onDetect` callbacks
- Test with v3.1 lightweight QR codes
- Check barcode detection count

---

## Recent Implementations (2025-12-18)

### 1. Firestore-First Architecture for All CRUD Operations ✅

**Completed**: Full migration from Hive-first to Firestore-first for all three data layers.

#### Phase 1: SharedGroup CRUD (Morning)

**Modified**: `lib/datastore/hybrid_purchase_group_repository.dart`

All 5 CRUD methods now follow Firestore-first pattern:

- `createGroup()`: Firestore create → Hive cache
- `getGroupById()`: Firestore fetch → Hive cache
- `getAllGroups()`: Firestore fetch → Hive cache + allowedUid filtering
- `updateGroup()`: Firestore update → Hive cache
- `deleteGroup()`: Firestore delete → Hive cache delete

**Simplification**: Removed `_isSharedGroup()` helper - unified to "prod + Firestore initialized" check.

**Commit**: `107c1e7`

#### Phase 2: SharedList CRUD (Afternoon)

**Modified**: `lib/datastore/hybrid_shared_list_repository.dart`

All 5 CRUD methods migrated:

- `createSharedList()`: Firestore create → Hive cache
- `getSharedListById()`: Firestore fetch → Hive cache (no groupId needed)
- `getSharedListsByGroup()`: Firestore fetch → Hive cache
- `updateSharedList()`: Firestore update → Hive cache
- `deleteSharedList()`: Firestore delete → Hive cache delete

**Testing**: Verified on SH 54D physical device - all CRUD operations working.

**Commit**: `b3b7838`

#### Phase 3: SharedItem Differential Sync (Late Afternoon)

**Background**: Map<String, SharedItem> format existed but HybridRepository was sending entire lists.

**Modified**: `lib/datastore/hybrid_shared_list_repository.dart`

Implemented true differential sync:

- `addSingleItem()`: Firestore field update (`items.{itemId}`) → Hive cache
- `removeSingleItem()`: Firestore soft delete (`items.{itemId}.isDeleted = true`) → Hive cache
- `updateSingleItem()`: Firestore field update → Hive cache

**Performance**:

- Before: 10 items = ~5KB per operation
- After: 1 item = ~500B per operation
- **90% network traffic reduction achieved** 🎉

**Commit**: `2c41315`

### 2. Double Submission Prevention ✅

**Problem**: Users could tap "Add Item" button multiple times during Firestore processing.

**Solution** (`lib/pages/shopping_list_page_v2.dart`):

```dart
bool isSubmitting = false;

ElevatedButton(
  onPressed: isSubmitting ? null : () async {
    setState(() { isSubmitting = true; });

    try {
      await repository.addSingleItem(listId, newItem);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { isSubmitting = false; });
    }
  },
  child: isSubmitting
    ? CircularProgressIndicator(strokeWidth: 2)
    : Text('追加'),
)
```

**Features**:

- Button disabled during processing
- Visual feedback (loading spinner)
- `context.mounted` check before dialog close
- Error recovery (re-enable button on failure)

**Commit**: `dcc60cb`

---

## Recent Implementations (2025-12-17)

### サインイン必須仕様への完全対応 ✅

**Overview**: Comprehensive authentication flow improvements with Firestore-first reads and Hive cleanup.

#### 1. User Name Setting Logic Fix

**Problem**: UI input "まや" → Firebase set "fatima.sumomo" (email prefix)

**Root Cause**: SharedPreferences cleared AFTER Firebase Auth registration

**Fix** (`lib/pages/home_page.dart`):

```dart
// ✅ Correct order:
// 1. Clear SharedPreferences + Hive FIRST
await UserPreferencesService.clearAllUserInfo();
await SharedGroupBox.clear();

// 2. THEN create Firebase Auth account
await authProvider.signUp(email, password);

// 3. Set display name
await UserPreferencesService.saveUserName(userName);
```

#### 2. Sign-Out Data Cleanup

**Added** (`lib/pages/home_page.dart` Lines 705-750):

```dart
// Complete cleanup on sign-out
await SharedGroupBox.clear();
await sharedListBox.clear();
await UserPreferencesService.clearAllUserInfo();
ref.invalidate(allGroupsProvider);
await authProvider.signOut();
```

#### 3. Firestore Priority on Sign-In

**Critical Change** (`lib/providers/purchase_group_provider.dart` Lines 765-825):

```dart
// 🔥 Check Firestore FIRST when creating default group
if (user != null && F.appFlavor == Flavor.prod) {
  try {
    final groupsSnapshot = await firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: user.uid)
        .get();

    // Found existing default group → sync to Hive
    if (groupsSnapshot.docs.any((doc) => doc.id == user.uid)) {
      await syncFromFirestore();
      await _cleanupInvalidHiveGroups(user.uid);
      return;
    }
  } catch (e) {
    // Not found → create new
  }
}
```

#### 4. Hive Cleanup Implementation

**New Method** (`lib/providers/purchase_group_provider.dart` Lines 1415-1448):

```dart
Future<void> _cleanupInvalidHiveGroups(
  String currentUserId,
  HiveSharedGroupRepository hiveRepository,
) async {
  final allHiveGroups = await hiveRepository.getAllGroups();

  for (final group in allHiveGroups) {
    if (!group.allowedUid.contains(currentUserId)) {
      await hiveRepository.deleteGroup(group.groupId);  // Hive only!
    }
  }
}
```

**Safety**: Deletes from Hive only, never Firestore (other users may still use those groups).

**Commits**:

- `4ba82a7`: User name setting logic fix
- `a5eb33c`: Sign-out data cleanup
- `09246b5`: Loading spinner for group list
- `1a869a3`: Firestore-first reads + Hive cleanup

---

## Recent Implementations (2025-12-16)

### 1. QR Invitation Duplicate Check Implementation ✅

**Purpose**: Prevent confusing "invitation accepted" message when scanning QR codes for already-joined groups.

**Implementation**:

- **File**: `lib/widgets/accept_invitation_widget.dart` (Lines 220-245)

  - Added member check logic immediately after QR scan
  - Check if `user.uid` exists in `existingGroup.allowedUid`
  - Show "すでに「○○」に参加しています" message for duplicate invitations
  - Close scanner screen without showing confirmation dialog
  - Added `mounted` check to fix BuildContext async error

- **File**: `lib/services/qr_invitation_service.dart` (Lines 464-481)
  - Removed duplicate check logic from service layer (UI layer now handles it)

**Test Results**:
✅ TBA1011 + SH 54D two-device physical test passed
✅ "すでに参加しています" message displays correctly
✅ WiFi simultaneous connection Firestore sync error resolved by switching to mobile network

**Commits**:

- 2e9d181: QR invitation duplicate check implementation
- e53b6d8: BuildContext async error fix
- 7c332d6: launch.json update (pushed to both oneness and main)

### 2. New Account Registration Hive Data Clear Fix ✅

**Problem**: Previous user's group and list data remained after sign-out → new account creation.

**Solution**:

- **File**: `lib/pages/home_page.dart` (Lines 92-106)
  - Added Hive box clear operations in signUp process
  - `SharedGroupBox.clear()`, `sharedListBox.clear()`
  - Provider invalidation: `ref.invalidate(allGroupsProvider)` etc.
  - 300ms delay to ensure UI update

**Verification**: ✅ Implemented and committed

### 3. User Name Setting Logic Issue (In Progress) ⚠️

**Problem**: UI input "まや" resulted in "fatima.sumomo" (email prefix) being set.

**Investigation & Fix Attempt**:

- **File**: `lib/services/firestore_user_name_service.dart` (Lines 223-249)
  - **Root Cause**: `ensureUserProfileExists()` ignored `userName` parameter when profile already existed
  - **Fix**: Added priority check for `userName` parameter
    ```dart
    if (userName != null && userName.isNotEmpty) {
      // Always use userName parameter (both for new creation and existing update)
      await docRef.set(dataToSave, SetOptions(merge: true));
      return;
    }
    ```

**Test Status**:

- TBA1011 debug launch successful (`flutter run -d JA0023942506007867 --flavor dev`)
- Test with "すもも" + `fatima.yatomi@outlook.com` → Same issue occurred
- **Status**: Not yet resolved, requires further investigation

**Next Investigation Points**:

- Verify `ensureUserProfileExists(userName: userName)` call in home_page.dart
- Check Firebase Auth displayName update timing
- Test after complete app restart (not just hot reload)
- Confirm actual Firestore write content via adb logcat

### 4. Test Checklist Creation ✅

**File**: `docs/test_checklist_20251216.md`

- 13 categories of comprehensive test items
- QR invitation duplicate check items added

### 5. Device Configuration Update ✅

**File**: `.vscode/launch.json`

- SH 54D IP address updated: 192.168.0.12:39955

**Commit**: 7c332d6

---

## Known Issues (As of 2025-12-16)

### User Name Setting Logic Bug (Under Investigation) ⚠️

**Symptom**: UI text input ignored, email prefix used instead

**Occurrence**: New account creation on Android device

**Status**:

- firestore_user_name_service.dart modified
- SetOptions(merge: true) implementation added
- Test execution pending (requires complete app restart)

**Suspected Causes**:

- home_page.dart signUp process may not pass userName parameter correctly
- Firebase Auth displayName update timing issue
- Hot reload not reflecting code changes

**Next Steps**:

- Debug home_page.dart signUp process
- Verify Firestore actual write content
- Test after complete app restart

---

## Recent Implementations (2025-12-15)

### 1. Android Gradle Build System Root Fix ✅

**Problem**: `flutter run` without flavor specification failed to produce APK

**Root Cause**: Ambiguous flavor dimension when assembling debug APK

**Solution (Fundamental Fix)**:

- Added `missingDimensionStrategy("default", "dev")` in `android/app/build.gradle.kts`
- Added `android.defaultFlavor=dev` in `android/gradle.properties`
- Created flavor-specific and device-specific launch configurations in `.vscode/launch.json`

**Modified Files**:

- `android/app/build.gradle.kts` (L47-49): Added missingDimensionStrategy
- `android/gradle.properties` (L5-6): Added defaultFlavor setting
- `.vscode/launch.json`: Complete rewrite with 6 configurations
- `android/app/src/main/AndroidManifest.xml` (L21): Added `usesCleartextTraffic="false"`
- `lib/main.dart` (L47-53): Added 2-second Android network initialization delay

**Result**:
✅ `flutter run` consistently uses dev flavor
✅ Device-specific debugging configurations available
✅ No more "Gradle build failed to produce an .apk file" errors

### 2. QR Code Invitation System Lightweight Implementation (v3.1) ✅

**Background**: QR codes contained 17 fields (~600 characters), causing complex QR patterns and poor scan reliability

**Implementation**:

#### QR Data Reduction (75% size reduction)

**Before (v3.0)**: 17 fields, ~600 characters (full invitation data in QR)
**After (v3.1)**: 5 fields, ~150 characters (minimal data + Firestore fetch)

```json
// v3.1 QR Code Data (lightweight)
{
  "invitationId": "abc123",
  "sharedGroupId": "group_xyz",
  "securityKey": "secure_key",
  "type": "secure_qr_invitation",
  "version": "3.1"
}
```

#### Firestore Integration

- Acceptor fetches full invitation details from Firestore using `invitationId`
- `securityKey` validates Firestore data (prevents tampering)
- Expiration and status checks performed on Firestore data

#### QR Code Size Optimization

- Increased from 200px to 250px (better scan reliability)
- Data reduction makes QR pattern simpler
- **Larger + Simpler QR = Faster Scanning**

#### Backward Compatibility

- Supports both v3.0 (full) and v3.1 (lightweight)
- Legacy invitations (v2.0 and earlier) still supported

**Modified Files**:

- `lib/services/qr_invitation_service.dart`:
  - `encodeQRData()`: Minimal data encoding (L160-171)
  - `decodeQRData()`: Made async, v3.1 support (L174-196)
  - `_fetchInvitationDetails()`: Fetch from Firestore (L199-257)
  - `_validateSecureInvitation()`: v3.1 lightweight validation (L260-328)
  - `generateQRWidget()`: Default size 250px (L331)
- `lib/widgets/accept_invitation_widget.dart`:
  - `_processQRInvitation()`: Use `decodeQRData()` with Firestore integration (L203-214)
  - Added comprehensive MobileScanner debug logs (L137-178)
- `lib/pages/group_invitation_page.dart`: QR size 250px (L241)
- `lib/widgets/invite_widget.dart`: QR size 250px (L63)
- `lib/widgets/qr_invitation_widgets.dart`: QR size 250px (L135)

**Verification**: Pending (requires testing on physical devices)

### 3. MobileScanner Debug Logging Enhancement ✅

**Purpose**: Diagnose QR scan non-responsiveness issue

**Added Logs**:

- `onDetect` callback invocation confirmation
- `_isProcessing` state tracking
- Barcode detection count display
- `rawValue` content preview (first 50 chars)
- JSON format validation result

**Modified File**: `lib/widgets/accept_invitation_widget.dart` (L137-178)

**Expected Diagnostics**:

- No `onDetect` logs → QR not detected (camera/resolution issue)
- `Barcode count: 0` → QR not decoded (size/quality issue)
- `rawValue: null` → Decode failure (data format issue)
- `JSON format detected` → Success

---

## Recent Implementations (2025-12-08)

### Shopping List Deletion Fix (Completed)

**Problem**: Deleted lists remained in Firestore and weren't removed from other devices.

**Root Cause**:

- `FirestoreSharedListRepository.deleteSharedList()` used collection group query
- `collectionGroup('sharedLists').where('listId', isEqualTo: listId)` caused `PERMISSION_DENIED`
- Firestore rules lacked collection group query permissions
- Deletion never reached Firestore

**Solution**:
Changed method signature from `deleteSharedList(String listId)` to `deleteSharedList(String groupId, String listId)`

**Modified Files**:

- `lib/datastore/shopping_list_repository.dart`: Abstract method signature
- `lib/datastore/firestore_shopping_list_repository.dart`: Direct path deletion
  ```dart
  await _collection(groupId).doc(listId).delete();
  ```
- `lib/datastore/hybrid_shopping_list_repository.dart`: Pass groupId to both repos
- `lib/datastore/hive_shopping_list_repository.dart`: Signature change
- `lib/datastore/firebase_shopping_list_repository.dart`: Signature change
- `lib/widgets/shopping_list_header_widget.dart`: UI call updated
- `lib/widgets/test_scenario_widget.dart`: Test call updated

**Commit**: `a1aa067` - "fix: deleteSharedList に groupId パラメータを追加"

**Verification**:
✅ Windows deletion → Firestore document removed
✅ Android device instantly reflects deletion
✅ Multiple device real-time sync confirmed

---

## Recent Implementations (2025-11-22)

### Realtime Sync Feature (Phase 1 - Completed)

**Implementation**: Shopping list items sync instantly across devices without screen transitions.

#### Architecture

- **Firestore `snapshots()`**: Real-time Stream API for live updates
- **StreamBuilder**: Flutter widget for automatic UI rebuilds on data changes
- **HybridRepository**: Auto-switches between Firestore Stream (online) and 30-second polling (offline/dev)

#### Key Files

**Repository Layer**:

- `lib/datastore/shopping_list_repository.dart`: Added `watchSharedList()` abstract method
- `lib/datastore/firestore_shopping_list_repository.dart`: Firestore `snapshots()` implementation
- `lib/datastore/hybrid_shopping_list_repository.dart`: Online/offline auto-switching
- `lib/datastore/hive_shopping_list_repository.dart`: 30-second polling fallback
- `lib/datastore/firebase_shopping_list_repository.dart`: Delegates to Hive polling

**UI Layer**:

- `lib/pages/shopping_list_page_v2.dart`: StreamBuilder integration
  - Removed `invalidate()` calls (causes current list to clear)
  - Added latest data fetch before item addition (`repository.getSharedListById()`)
  - Fixed sync timing issue that caused item count limits

**QR System**:

- `lib/widgets/qr_invitation_widgets.dart`: Added `groupAllowedUids` parameter
- `lib/widgets/qr_code_panel_widget.dart`: Updated QRInviteButton usage

#### Critical Patterns

1. **StreamBuilder Usage**:

```dart
StreamBuilder<SharedList?>(
  stream: repository.watchSharedList(groupId, listId),
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
final latestList = await repository.getSharedListById(currentList.listId);
final updatedList = latestList.copyWith(items: [...latestList.items, newItem]);
await repository.updateSharedList(updatedList);
// StreamBuilder auto-detects update, no invalidate needed
```

3. **Hybrid Cache Update**:

```dart
// watchSharedList caches Firestore data to Hive
return _firestoreRepo!.watchSharedList(groupId, listId).map((firestoreList) {
  if (firestoreList != null) {
    _hiveRepo.updateSharedList(firestoreList);  // Not addItem!
  }
  return firestoreList;
});
```

#### Problems Solved

1. **Build errors**: Missing `watchSharedList()` implementations in all Repository classes
2. **Current list clears**: Removed `ref.invalidate()` that cleared StreamBuilder's initialData
3. **Item count limit**: Fixed by fetching latest data before addition (sync timing issue)
4. **Cache corruption**: Fixed `addItem` → `updateSharedList` in HybridRepository

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

**Goal**: Enable currently disabled features in `SharedItem` model

#### 1. Deadline (Shopping Deadline) Feature

**Model Field**: `DateTime? deadline`

**Planned Implementation**:

- Deadline picker dialog (date + time)
- Visual indicators:
  - Red badge for overdue items
  - Yellow badge for items due soon (< 3 days)
  - Countdown display ("2 日後" / "期限切れ")
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
- Statistics: "前回購入から ○ 日経過"

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

## SharedList Map Format & Differential Sync (Implemented: 2025-11-25)

### Architecture Overview

**From**: `List<SharedItem>` (Array-based, full list sync)
**To**: `Map<String, SharedItem>` (Dictionary-based, item-level sync)

**Purpose**: Enable real-time differential sync - send only changed items instead of entire list.

### Data Structure

#### SharedItem Model

```dart
@HiveType(typeId: 3)
@freezed
class SharedItem with _$SharedItem {
  const factory SharedItem({
    @HiveField(0) required String name,
    @HiveField(1) @Default(false) bool isPurchased,
    // ... existing fields ...

    // 🆕 New Fields (Phase 1-11)
    @HiveField(8) required String itemId,           // UUID v4, unique identifier
    @HiveField(9) @Default(false) bool isDeleted,   // Soft delete flag
    @HiveField(10) DateTime? deletedAt,             // Deletion timestamp
  }) = _SharedItem;
}
```

#### SharedList Model

```dart
@HiveField(3) @Default({}) Map<String, SharedItem> items,

// 🆕 New Getters
List<SharedItem> get activeItems =>
    items.values.where((item) => !item.isDeleted).toList();

int get deletedItemCount =>
    items.values.where((item) => item.isDeleted).length;

bool get needsCleanup => deletedItemCount > 10;
```

### Backward Compatibility

**Custom TypeAdapter** (`lib/adapters/shopping_item_adapter_override.dart`):

```dart
class SharedItemAdapterOverride extends TypeAdapter<SharedItem> {
  @override
  final int typeId = 3;  // Override default SharedItemAdapter

  @override
  SharedItem read(BinaryReader reader) {
    final fields = <int, dynamic>{/* read fields */};

    return SharedItem(
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
    Hive.registerAdapter(SharedItemAdapterOverride());
  }
  await UserSpecificHiveService.initializeAdapters();
  runApp(const ProviderScope(child: MyApp()));
}
```

### Differential Sync API

**Repository Methods** (`shopping_list_repository.dart`):

```dart
abstract class SharedListRepository {
  // 🔥 Send single item (not entire list)
  Future<void> addSingleItem(String listId, SharedItem item);

  // 🔥 Soft delete by itemId only
  Future<void> removeSingleItem(String listId, String itemId);

  // 🔥 Update single item (not entire list)
  Future<void> updateSingleItem(String listId, SharedItem item);

  // 🔥 Physical delete of soft-deleted items (30+ days old)
  Future<void> cleanupDeletedItems(String listId, {int olderThanDays = 30});
}
```

**Usage Pattern** (shopping_list_page_v2.dart):

```dart
// ❌ Old: Full list sync
await repository.updateSharedList(currentList.copyWith(
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

#### SharedListDataMigrationService

```dart
// Migrate old List<SharedItem> data to Map<String, SharedItem>
final migrationService = SharedListDataMigrationService(ref);
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
   await repository.updateSharedList(currentList.copyWith(items: updatedItems));

   // ✅ Correct: Sends only new item
   await repository.addSingleItem(currentList.listId, newItem);
   ```

3. **Never modify items Map directly**:

   ```dart
   // ❌ Wrong: Direct mutation
   currentList.items[itemId] = updatedItem;

   // ✅ Correct: Use copyWith
   final updatedItems = Map<String, SharedItem>.from(currentList.items);
   updatedItems[itemId] = updatedItem;
   await repository.updateSingleItem(currentList.listId, updatedItem);
   ```

4. **Soft delete, not hard delete**:

   ```dart
   // ❌ Wrong: Remove from Map
   final updatedItems = Map<String, SharedItem>.from(currentList.items);
   updatedItems.remove(itemId);

   // ✅ Correct: Mark as deleted
   await repository.removeSingleItem(currentList.listId, itemId);
   // Repository marks item.isDeleted = true internally
   ```

### Performance Benefits

| Metric                       | Before (List)     | After (Map)        | Improvement   |
| ---------------------------- | ----------------- | ------------------ | ------------- |
| Network payload (add 1 item) | Full list (~10KB) | Single item (~1KB) | 90% reduction |
| Sync time (1 item)           | 500ms             | 50ms               | 10x faster    |
| Item lookup complexity       | O(n)              | O(1)               | Constant time |
| Conflict resolution          | Full list merge   | Item-level merge   | Safer         |

### Migration Path

**Phase 1-11 (Completed 2025-11-25)**:

- ✅ Data structure conversion (List → Map)
- ✅ Backward compatibility (SharedItemAdapterOverride)
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
# SharedItem should have 11 fields (8 → 11)
dart run build_runner build --delete-conflicting-outputs
# Look for: "typeId = 3, numFields = 11"
```

**Verify adapter registration**:

```dart
// In main.dart, check console output:
// ✅ SharedItemAdapterOverride registered
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
- ✅ パスワード入力（6 文字以上）
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
   - SharedPreferences + Firebase Auth 両方に保存

2. **サインイン時の自動反映**

   - Firebase Auth の displayName が存在すれば Preferences に反映
   - 未設定でもサインイン可能（後から設定可能）

3. **モード切り替え**

   - `_isSignUpMode`フラグで動的に UI 切り替え
   - フォームリセットで入力内容をクリア

4. **視覚的フィードバック**
   - アカウント作成成功時: 「ようこそ、○○ さん」
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

- `lib/datastore/shopping_list_repository.dart`: Added `watchSharedList()` abstract method
- `lib/datastore/firestore_shopping_list_repository.dart`: Firestore `snapshots()` implementation
- `lib/datastore/hybrid_shopping_list_repository.dart`: Online/offline auto-switching
- `lib/datastore/hive_shopping_list_repository.dart`: 30-second polling fallback
- `lib/datastore/firebase_shopping_list_repository.dart`: Delegates to Hive polling

**UI Layer**:

- `lib/pages/shopping_list_page_v2.dart`: StreamBuilder integration
  - Removed `invalidate()` calls (causes current list to clear)
  - Added latest data fetch before item addition (`repository.getSharedListById()`)
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

**AppLogger 統一** (main.dart):

- ✅ 18 箇所の print 文を AppLogger.info/error/warning に変更
- ✅ Firebase 初期化ログの統一
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
2. サインイン時: Firebase Auth → SharedPreferences 反映
3. アプリ起動時: SharedPreferences から自動ロード

## Known Issues (As of 2025-12-08)

- None currently

## Recent Implementations (2025-12-06)

### 1. Windows 版 QR スキャン手動入力対応 ✅

**Background**: Windows 版で`camera`や`google_mlkit_barcode_scanning`が非対応のため、QR コード自動読み取りが不可能。

**Implementation**:

- **New File**: `lib/widgets/windows_qr_scanner_simple.dart` (210 lines)
  - FilePicker 経由で画像ファイル選択
  - 画像からの QR コード自動検出は技術的に困難（image パッケージでは QR デコード非対応）
  - **手動入力ダイアログ**: 8 行 TextField で JSON 形式の QR コードデータを貼り付け
  - `widget.onDetect(manualInput)` → 招待処理実行

**Platform Detection**:

```dart
// accept_invitation_widget.dart
if (Platform.isWindows) {
  WindowsQRScannerSimple(onDetect: _processQRInvitation);
} else {
  MobileScanner(onDetect: _processMobileScannerBarcode);
}
```

**Manual Input Dialog**:

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('QRコードデータを入力'),
    content: TextField(
      maxLines: 8,
      decoration: InputDecoration(
        hintText: 'JSON形式でQRコードデータを貼り付け',
      ),
    ),
  ),
);
```

**Verified**: ✅ 画像選択 → 手動入力 → JSON 解析 → セキュリティ検証 → 招待受諾成功

### 2. グループメンバー名表示問題の修正 ✅

**Problem**: 招待受諾成功後、グループメンバーリストに「ユーザー」と表示される

**Root Cause**: `/users/{uid}/profile/profile`からユーザー名を取得していなかった

**Solution Implemented**:

#### 招待受諾側（qr_invitation_service.dart Line 280-320）

```dart
// Firestoreプロファイルから表示名を取得（最優先）
String? firestoreName;
try {
  final profileDoc = await _firestore
      .collection('users')
      .doc(acceptorUid)
      .collection('profile')
      .doc('profile')
      .get();

  if (profileDoc.exists) {
    firestoreName = profileDoc.data()?['displayName'] as String?;
  }
} catch (e) {
  Log.error('📤 [ACCEPTOR] Firestoreプロファイル取得エラー: $e');
}

// 名前の優先順位: Firestore → SharedPreferences → UserSettings → Auth.displayName → email → UID
final userName = (firestoreName?.isNotEmpty == true)
    ? firestoreName!
    : (prefsName?.isNotEmpty == true) ? prefsName! : ...;
```

#### 招待元側（notification_service.dart Line 279-310）

```dart
// acceptorNameが空または「ユーザー」の場合、Firestoreプロファイルから取得
String finalAcceptorName = acceptorName;
if (acceptorName.isEmpty || acceptorName == 'ユーザー') {
  try {
    final profileDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(acceptorUid)
        .collection('profile')
        .doc('profile')
        .get();

    if (profileDoc.exists) {
      final firestoreName = profileDoc.data()?['displayName'] as String?;
      if (firestoreName?.isNotEmpty == true) {
        finalAcceptorName = firestoreName!;
        AppLogger.info('📤 [OWNER] Firestoreから名前取得: $finalAcceptorName');
      }
    }
  } catch (e) {
    AppLogger.error('📤 [OWNER] Firestoreプロファイル取得エラー: $e');
  }
}

// メンバーリストに追加
updatedMembers.add(
  SharedGroupMember(
    memberId: acceptorUid,
    name: finalAcceptorName,  // ✅ Firestoreから取得した名前
    role: SharedGroupRole.member,
  ),
);
```

**Status**: 実装完了・動作確認済み ✅

**Verification (2025-12-08)**:

- ✅ 招待元側: グループメンバーリストに受諾ユーザーの名前が正しく表示
- ✅ 受諾側: グループメンバーリストに受諾ユーザーの名前が正しく表示
- ✅ Firestore プロファイル取得が正常動作

### 3. リスト作成後の自動選択機能 ✅

**Problem**: リスト作成後、ドロップダウンで新しく作成したリストが自動選択されない

**Root Cause**:

- `invalidate(groupSharedListsProvider)`でリスト一覧再取得開始
- UI が再ビルドされるタイミングで、まだ新しいリストが含まれていない
- `validValue = null` → ドロップダウンに反映されない

**Solution Implemented** (`shopping_list_header_widget.dart` Line 325-332):

```dart
// ダイアログを閉じた後、リスト一覧を更新して完了を待つ
ref.invalidate(groupSharedListsProvider);

// リスト一覧の更新完了を待つ（新しいリストが含まれるまで）
try {
  await ref.read(groupSharedListsProvider.future);
  Log.info('✅ リスト一覧更新完了 - 新しいリストを含む');
} catch (e) {
  Log.error('❌ リスト一覧更新エラー: $e');
}
```

**Expected Behavior**:

- `invalidate()`後にリスト一覧の更新完了を待機
- 新しいリストが lists 配列に含まれた状態で`_buildListDropdown`が再ビルド
- `validValue`が正しく設定され、DropdownButton に反映

**Status**: 実装完了・動作確認済み ✅

**Verification (2025-12-08)**:

- ✅ リスト作成側: 新しいリストがドロップダウンで選択された状態
- ✅ 共有されたユーザー側: 新しいリストがドロップダウンで選択された状態
- ✅ リスト一覧更新完了待機処理が正常動作

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

  final newItem = SharedItem.createNow(
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

**Purpose**: Implement production AdMob advertising with location-based ad prioritization.

#### AdMob App ID Configuration

- **App ID**: Configured via `.env` file (`ADMOB_APP_ID`)
- **Android**: Configured in `AndroidManifest.xml`
- **iOS**: Configured in `Info.plist` with `GADApplicationIdentifier` key

#### Banner Ad Unit ID Configuration

- **Ad Unit ID**: Configured via `.env` file (`ADMOB_BANNER_AD_UNIT_ID` or `ADMOB_TEST_BANNER_AD_UNIT_ID`)
- **File**: `lib/services/ad_service.dart` (`_bannerAdUnitId`)

#### Location-Based Ad Prioritization (Added: 2025-12-09) ✅

**Feature**: Prioritize ads within 30km radius on Android/iOS devices

**Implementation**:

- **Package**: `geolocator: ^12.0.0`
- **Permissions**:
  - Android: `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` in `AndroidManifest.xml`
  - iOS: `NSLocationWhenInUseUsageDescription` in `Info.plist`
- **Location Caching**: 1-hour cache to minimize battery drain
- **Fallback**: Standard ads shown if location unavailable
- **Target Range**: 30km radius (approximately 20-30 minutes by car)

**Usage**:

```dart
final adService = ref.read(adServiceProvider);
final bannerAd = await adService.createBannerAd(
  size: AdSize.banner,
  useLocation: true, // Enable location-based ads (30km radius)
);
```

**Key Methods**:

- `getCurrentLocation()`: Fetch device location with timeout (5 sec)
- `_cacheLocation()`: Cache location for 1 hour
- `_getCachedLocation()`: Retrieve cached location to reduce API calls

**Privacy**: Location accuracy set to `LocationAccuracy.low` (city-level, sufficient for 30km radius)

#### Home Page Banner Ad Implementation

- **New Widget**: `HomeBannerAdWidget`

  - Hidden until ad loaded
  - White background with light gray border
  - "広告" label display
  - Automatic memory management (dispose)
  - Location-based ad loading on Android/iOS

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
- **Item count limits**: Always fetch latest data with `repository.getSharedListById()` before updates
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
await repository.createSharedList(newList);

// Set as current list
ref.read(currentListProvider.notifier).selectList(newList);

// Invalidate list provider to refresh from Firestore
ref.invalidate(groupSharedListsProvider);

// ❌ Problem: Widget rebuilds HERE with stale data
// The dropdown shows null because lists array doesn't contain newList yet
```

**Solution**: Wait for provider refresh to complete before continuing

```dart
// ❌ Wrong: UI rebuilds with stale data
ref.invalidate(groupSharedListsProvider);
// Widget rebuilds here, lists array still old

// ✅ Correct: Wait for refresh to complete
ref.invalidate(groupSharedListsProvider);
await ref.read(groupSharedListsProvider.future);
// Widget rebuilds here, lists array includes new data
```

**Real-world Example** (from `shopping_list_header_widget.dart`):

```dart
// After creating new list
await repository.createSharedList(newList);
ref.read(currentListProvider.notifier).selectList(newList);

// Invalidate and WAIT for list refresh
ref.invalidate(groupSharedListsProvider);
try {
  await ref.read(groupSharedListsProvider.future);
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
ref.invalidate(groupSharedListsProvider);  // Refresh list data
await ref.read(groupSharedListsProvider.future);
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

---

## Recent Implementations (2025-12-10)

### Firebase Crashlytics Implementation ✅

**Purpose**: Automatic crash log collection for production error analysis

**Implementation**:

- Added `firebase_crashlytics: ^5.0.5` to `pubspec.yaml`
- Configured error handlers in `main.dart`:
  - `FlutterError.onError`: Flutter framework errors
  - `PlatformDispatcher.instance.onError`: Async errors
- Integrated with AppLogger for error logging

**Verification**:
✅ Initialization successful
✅ Error logs sent to Firebase Console confirmed

**Commit**: `41fe8ef` - "feat: Firebase Crashlytics 実装"

---

### Privacy Protection for Logging System ✅

**Background**: Preparing for external log transmission during testing requires personal information masking

#### AppLogger Extensions

Added privacy protection methods to `lib/utils/app_logger.dart`:

- `maskUserId(String? userId)`: Shows only first 3 characters (e.g., `abc***`)
- `maskName(String? name)`: Shows only first 2 characters (e.g., `すも***`)
- `maskGroup(String? groupName, String? groupId)`: Masks group info (e.g., `家族***(group_id)`)
- `maskList(String? listName, String? listId)`: Masks list info
- `maskItem(String? itemName, String? itemId)`: Masks item info
- `maskGroupId(String? groupId, {String? currentUserId})`: Masks only default group IDs (= UIDs)

#### Log Output Unification

- **Debug mode**: `debugPrint()` only (for VS Code Debug Console)
- **Release mode**: `logger` package detailed logs + `debugPrint()` (for production troubleshooting)
- Fixed duplicate log display issue

#### Personal Information Masking

**Modified Files**: 28 files

- User names → First 2 characters only
- UIDs → First 3 characters only
- Email addresses → First 2 characters only
- Group names → First 2 characters + ID
- List names → First 2 characters + ID
- Item names → First 2 characters + ID
- allowedUid arrays → Mask each element
- Default group groupIds → Masked (regular group IDs remain visible)

**Key Modified Files**:

- `lib/main.dart` (Firebase Auth current user)
- `lib/pages/home_page.dart` (signup/signin user names)
- `lib/pages/settings_page.dart` (user name loading)
- `lib/providers/auth_provider.dart` (auth-related user names/emails)
- `lib/providers/purchase_group_provider.dart` (group creation/selection UIDs/group names)
- `lib/services/notification_service.dart` (notification UIDs/group names)
- `lib/services/sync_service.dart` (sync group info)
- `lib/services/qr_invitation_service.dart` (invitation user names/UIDs/group info)
- `lib/services/user_initialization_service.dart` (user initialization UIDs/profile info)
- `lib/services/user_specific_hive_service.dart` (Hive initialization UIDs)
- Plus 18 other files (user services, widgets)

**Masking Examples**:

```dart
// Before
Log.info('ユーザー名: $userName');  // → "ユーザー名: すもも"
Log.info('UID: $userId');           // → "UID: abc123def456ghi789"
Log.info('allowedUid: $allowedUid'); // → "allowedUid: [abc123, def456, ghi789]"
Log.info('デフォルトグループID: $groupId'); // → "デフォルトグループID: abc123def456"

// After
Log.info('ユーザー名: ${AppLogger.maskName(userName)}');  // → "ユーザー名: すも***"
Log.info('UID: ${AppLogger.maskUserId(userId)}');         // → "UID: abc***"
Log.info('allowedUid: ${allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()}');
// → "allowedUid: [abc***, def***, ghi***]"
Log.info('デフォルトグループID: ${AppLogger.maskGroupId(groupId, currentUserId: user.uid)}');
// → "デフォルトグループID: abc***"
```

#### Technical Learnings

**1. Debug Console Log Display**

- **Problem**: `logger` package logs not showing in VS Code Debug Console
- **Cause**: `logger` outputs to stdout/stderr, not visible in Debug Console
- **Solution**: Use Flutter's `debugPrint()` concurrently

```dart
static void info(String message) {
  if (!kDebugMode) _instance.i(message);  // logger only in release mode
  debugPrint(message);  // Always use debugPrint (for VS Code display)
}
```

**2. Default Group groupId Design**

- **Issue**: Default group `groupId` equals user's UID, exposing personal info in logs
- **Solution**: Conditional masking with `maskGroupId()`

```dart
static String maskGroupId(String? groupId, {String? currentUserId}) {
  final isDefaultGroup = groupId == 'default_group' ||
                        (currentUserId != null && groupId == currentUserId);

  if (isDefaultGroup) {
    return maskUserId(groupId);  // Mask default group only
  }

  return groupId;  // Regular group IDs remain visible (shared identifiers)
}
```

---

## Known Issues (As of 2025-12-13)

### Android Firestore Sync Error (Unresolved)

**Symptom**: Android app shows red cloud icon with X mark (network disconnected state)

**Occurrence**: After successful APK installation on Android device (SH 54D, Android 15)

**Possible Causes**:

1. **Firebase Configuration Mismatch**:

   - `google-services.json` appId may differ between Windows and Android
   - Firebase project settings not properly configured for Android flavor

2. **Network Permissions**:

   - Internet permission may be missing in AndroidManifest.xml
   - Firestore connection timeout issues

3. **Authentication State**:

   - Auth credentials not properly saved/restored on Android
   - SharedPreferences or Hive data path issues on Android

4. **Firestore Security Rules**:
   - Android device ID or auth token not matching security rules

**Investigation Plan** (Next Session):

- Check Android logs with `flutter logs -d <device-id>`
- Verify Firebase Console error logs
- Confirm `firebase_options.dart` configuration
- Verify `google-services.json` appId
- Add Firestore connection debug logging

---

## Recent Implementations (2025-12-13)

### Android Build System Troubleshooting ✅

**Problem**: Android build failed with multiple errors

#### Issue 1: Build Cache Lock

**Error**:

```
java.io.IOException: Unable to delete directory 'C:\FlutterProject\go_shop\build'
Failed to delete some children. Process has files open.
```

**Cause**: Windows debug session locking build directory while attempting Android build

**Solution**: Skip `gradlew clean` and directly run `assembleDebug`:

```bash
cd android
./gradlew assembleDebug --no-daemon
```

#### Issue 2: Flutter Plugin Native Code Not Linked

**Error**:

```
error: package com.baseflow.geocoding does not exist
error: package io.flutter.plugins.googlemobileads does not exist
... (16 errors total)
```

**Root Cause**: `flutter pub get` not executed properly, GeneratedPluginRegistrant.java missing plugin references

**Solution**:

```bash
flutter pub get  # Re-fetch plugins
cd android
./gradlew assembleDebug --no-daemon  # Build directly
```

**Result**: ✅ BUILD SUCCESSFUL in 5m 22s

**Generated APKs**:

- `build\app\outputs\flutter-apk\app-dev-debug.apk`
- `build\app\outputs\flutter-apk\app-prod-debug.apk`

**Installed to**: Android device (SH 54D, Android 15 API 35)

### Technical Learnings

**Flutter Multi-Device Execution**:

- F5 debug launch limited to one device (VS Code restriction)
- Second device requires separate terminal: `flutter run -d <device-id>`
- Shared build directory causes lock conflicts during clean operations

**Gradle Best Practices**:

- Clean not always necessary: `./gradlew assembleDebug --no-daemon` works directly
- `--no-daemon` option prevents lingering Gradle processes and reduces memory usage

**Flutter APK Types**:

- **Debug APK**: Large size (includes debug symbols), for development/testing
- **Release APK**: Optimized size, for production distribution (`flutter build apk --release`)

---

## Recent Implementations (2025-12-12)

### Firestore Security Rules Fix for Shopping List Permissions ✅

**Background**: Windows Desktop users reported shopping lists not syncing to Firestore despite successful Hive saves.

**Problem**:

- Error: `[cloud_firestore/permission-denied] Missing or insufficient permissions`
- Lists created locally (Hive) but failed to sync to Firestore
- Initially thought to be Windows Firestore threading issue, but was actually permissions

**Root Cause**:

- `firestore.rules` used `isGroupMember()` function with `resource.data`
- **Critical Issue**: `resource` doesn't exist during new subcollection document creation
- Permission check always failed for new `sharedLists` documents

**Problematic Code** (firestore.rules L96-113):

```javascript
function isGroupMember(groupId) {
  return request.auth != null && (
    resource.data.ownerUid == request.auth.uid ||  // ❌ resource.data doesn't exist on creation
    request.auth.uid in resource.data.allowedUid
  );
}

match /sharedLists/{listId} {
  allow read, write: if isGroupMember(groupId);  // ❌ Always fails on create
}
```

**Solution Implemented**:
Changed to direct parent document reference using `get()` function:

```javascript
match /sharedLists/{listId} {
  allow read, create, update, delete: if request.auth != null && (
    get(/databases/$(database)/documents/SharedGroups/$(groupId)).data.ownerUid == request.auth.uid ||
    request.auth.uid in get(/databases/$(database)/documents/SharedGroups/$(groupId)).data.allowedUid
  );
}
```

**Deployment**:

```bash
firebase deploy --only firestore:rules
✅ cloud.firestore: rules file firestore.rules compiled successfully
✅ firestore: released rules firestore.rules to cloud.firestore
```

**Verification Results**:

- ✅ Lists instantly appear in UI (Hive cache)
- ✅ Lists sync to Firestore after 1-3 seconds (network delay)
- ✅ No more `permission-denied` errors
- ✅ Multi-device sync working as expected

**Modified Files**:

- `firestore.rules` (L96-113): sharedLists match block

**Key Learning**:

- Thread errors can be red herrings - always check actual error messages
- `resource.data` only exists for existing documents, not during creation
- Use `get()` to fetch parent document data for subcollection permissions

**Commit**: `67a90a1` - "fix: Firestore セキュリティルールで sharedLists のパーミッション修正"

---

## Recent Implementations (2025-12-17)

### サインイン必須仕様への完全対応 ✅

**Background**: アプリをサインイン状態でのみ動作する仕様に変更。しかし、デフォルトグループ作成時に Hive を優先チェックしており、Firestore の既存グループを見ていなかった。

#### 1. 認証フロー全体のデータ管理改善

**問題**: サインアウト → サインイン時に前ユーザーのグループが残る

**修正内容**:

**サインアップ処理** (`lib/pages/home_page.dart` Lines 82-150):

```dart
// 処理順序（重要！）
// 1. SharedPreferences + Hiveクリア（Firebase Auth登録前）
await UserPreferencesService.clearAllUserInfo();
await SharedGroupBox.clear();
await sharedListBox.clear();

// 2. Firebase Auth新規登録
await ref.read(authProvider).signUp(email, password);

// 3-9. プロバイダー無効化、displayName更新、Firestore同期
```

**サインアウト処理** (`lib/pages/home_page.dart` Lines 705-750):

```dart
// 1. Hive + SharedPreferencesクリア
await SharedGroupBox.clear();
await sharedListBox.clear();
await UserPreferencesService.clearAllUserInfo();

// 2. プロバイダー無効化
ref.invalidate(allGroupsProvider);

// 3. Firebase Authサインアウト
await ref.read(authProvider).signOut();
```

**サインイン処理** (`lib/pages/home_page.dart` Lines 187-250):

```dart
// サインイン（サインアウト時に既にHiveクリア済み）
await ref.read(authProvider).signIn(email, password);

// Firestore→Hive同期
await Future.delayed(const Duration(seconds: 1));
await ref.read(forceSyncProvider.future);
ref.invalidate(allGroupsProvider);
```

#### 2. 🔥 サインイン時の Firestore 優先読み込み実装

**問題**:

- `createDefaultGroup()`が Hive を先にチェック
- Firestore に既存のデフォルトグループがあるのに新規作成してしまう

**修正** (`lib/providers/purchase_group_provider.dart` Lines 765-825):

```dart
// 🔥 CRITICAL: サインイン状態ではFirestoreを優先チェック
if (user != null && F.appFlavor == Flavor.prod) {
  Log.info('🔥 [CREATE DEFAULT] サインイン状態 - Firestoreから既存グループ確認');

  try {
    // Firestoreから全グループ取得
    final firestore = FirebaseFirestore.instance;
    final groupsSnapshot = await firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: user.uid)
        .get();

    // デフォルトグループ（groupId = user.uid）が存在するか確認
    final defaultGroupDoc = groupsSnapshot.docs.firstWhere(
      (doc) => doc.id == defaultGroupId,
      orElse: () => throw Exception('デフォルトグループなし'),
    );

    // Firestoreにデフォルトグループが存在 → Hiveに同期して終了
    final firestoreGroup = SharedGroup(...);
    await hiveRepository.saveGroup(firestoreGroup);

    // 🔥 Hiveクリーンアップ実行
    await _cleanupInvalidHiveGroups(user.uid, hiveRepository);

    return;
  } catch (e) {
    // Firestoreにデフォルトグループなし → 新規作成
    await _cleanupInvalidHiveGroups(user.uid, hiveRepository);
  }
}
```

**動作フロー**:

1. サインイン状態では**Firestore を最初にチェック**
2. デフォルトグループ（groupId = user.uid）が存在すれば Hive に同期
3. 存在しなければ新規作成して Firestore + Hive に保存

#### 3. 🔥 Hive クリーンアップ機能実装

**目的**: Hive に残っている他ユーザーのグループを自動削除

**実装** (`lib/providers/purchase_group_provider.dart` Lines 1415-1448):

```dart
/// Hiveから不正なグループを削除（allowedUidに現在ユーザーが含まれないもの）
Future<void> _cleanupInvalidHiveGroups(
  String currentUserId,
  HiveSharedGroupRepository hiveRepository,
) async {
  try {
    final allHiveGroups = await hiveRepository.getAllGroups();

    int deletedCount = 0;
    for (final group in allHiveGroups) {
      // allowedUidに現在のユーザーが含まれているか確認
      if (!group.allowedUid.contains(currentUserId)) {
        Log.info('🗑️ [CLEANUP] Hiveから削除（Firestoreは保持）: ${group.groupName}');
        await hiveRepository.deleteGroup(group.groupId);  // ⚠️ Hiveのみ削除
        deletedCount++;
      }
    }

    if (deletedCount > 0) {
      Log.info('✅ [CLEANUP] ${deletedCount}個の不正グループをHiveから削除（Firestoreは保持）');
    }
  } catch (e) {
    Log.error('❌ [CLEANUP] Hiveクリーンアップエラー: $e');
  }
}
```

**重要**:

- **Firestore は削除しない**（他ユーザーが使用している可能性があるため）
- Hive ローカルキャッシュのみ削除

**実行タイミング**:

1. サインイン時の Firestore チェック後
2. デフォルトグループ新規作成前

#### 4. getAllGroups()での allowedUid フィルタリング

**二重の安全策** (`lib/providers/purchase_group_provider.dart` Lines 438-446):

```dart
// 🔥 CRITICAL: allowedUidに現在ユーザーが含まれないグループを除外
final currentUser = ref.read(authStateProvider).value;
if (currentUser != null) {
  allGroups = allGroups.where((g) => g.allowedUid.contains(currentUser.uid)).toList();
  if (invalidCount > 0) {
    Log.warning('⚠️ [ALL GROUPS] allowedUid不一致グループを除外: $invalidCount グループ');
  }
}
```

#### 5. デバッグログ強化

**データソース追跡** (`lib/datastore/hybrid_purchase_group_repository.dart`, `firestore_purchase_group_repository.dart`):

```dart
// Hybrid Repository
AppLogger.info('🔍 [HYBRID] _getAllGroupsInternal開始 - Flavor: ${F.appFlavor}, Online: $_isOnline');
AppLogger.info('📦 [HYBRID] Hiveから${cachedGroups.length}グループ取得');
for (var group in cachedGroups) {
  AppLogger.info('  📦 [HIVE] ${group.groupName} - allowedUid: [...]');
}

// Firestore Repository
AppLogger.info('🔥 [FIRESTORE_REPO] getAllGroups開始 - currentUserId: ***');
for (var doc in groupsSnapshot.docs) {
  AppLogger.info('  📄 [FIRESTORE_DOC] ${groupName} - allowedUid: [...]');
}
```

**Verification Results**:

- ✅ すもも/ファティマでサインアウト → サインイン
- ✅ それぞれ自分のグループのみ表示
- ✅ 他ユーザーのグループは表示されない
- ✅ Hive クリーンアップログ正常動作
- ✅ Firestore コンソールで他ユーザーのグループが保持されていることを確認

**Modified Files**:

- `lib/pages/home_page.dart` (サインアップ/サインイン/サインアウト処理)
- `lib/providers/purchase_group_provider.dart` (createDefaultGroup, getAllGroups, \_cleanupInvalidHiveGroups)
- `lib/datastore/hybrid_purchase_group_repository.dart` (デバッグログ追加)
- `lib/datastore/firestore_purchase_group_repository.dart` (デバッグログ追加)
- `lib/widgets/group_list_widget.dart` (ローディングウィジェット改善)

**Commits**:

- `4ba82a7` - "fix: ユーザー名設定ロジック修正（SharedPreferences/Hive クリア順序）"
- `a5eb33c` - "fix: サインアウト時の Hive/SharedPreferences クリア実装"
- `09246b5` - "feat: グループ画面ローディングスピナー追加"
- `1a869a3` - "fix: サインイン時の Firestore 優先読み込みと Hive クリーンアップ実装"

### Next Steps (2025-12-18 予定)

**優先タスク**: サインイン必須仕様への完全対応確認

**確認項目**:

1. グループ操作（作成/削除/メンバー管理）
2. リスト操作（作成/削除/選択）
3. アイテム操作（追加/削除/更新/購入状態トグル）
4. 招待機能（QR 作成/受諾）
5. 同期機能（Firestore→Hive、バックグラウンド同期）

**確認方法**:

- 各操作の冒頭で`currentUser`チェック
- `currentUser == null`の場合はエラーメッセージ or ログイン画面誘導
- UI 側でもサインアウト状態では操作ボタン無効化

---

## Recent Implementations (2025-12-18)

### 1. サインイン必須仕様への完全対応（全階層 Firestore 優先化） ✅

**Background**: サインイン必須アプリとして、Group/List/Item の全階層で Firestore 優先＋効率的な同期を実現。

#### Phase 1: SharedGroup CRUD Firestore 優先化（午前）

**目的**: Hive 優先から Firestore 優先への変更

**実装内容**:

- `hybrid_purchase_group_repository.dart`の 5 つの CRUD メソッドを Firestore 優先に変更
  - `createGroup()`: Firestore 作成 → Hive キャッシュ
  - `getGroupById()`: Firestore 取得 → Hive キャッシュ
  - `getAllGroups()`: Firestore 取得 → Hive キャッシュ＋ allowedUid フィルタリング
  - `updateGroup()`: Firestore 更新 → Hive キャッシュ
  - `deleteGroup()`: Firestore 削除 → Hive キャッシュ削除

**技術的改善**:

- `_isSharedGroup()`削除（不要な条件分岐を簡素化）
- 条件を「prod 環境かつ Firestore 初期化済み」のみに統一
- Firestore エラー時は Hive フォールバック（データ保護）

**コミット**: `107c1e7`

#### Phase 2: SharedList CRUD Firestore 優先化（午後前半）

**目的**: SharedList の全 CRUD 操作を Firestore 優先に統一

**実装内容**:

- `hybrid_shared_list_repository.dart`の 5 つの CRUD メソッドを Firestore 優先に変更
  - `createSharedList()`: Firestore 作成 → Hive キャッシュ
  - `getSharedListById()`: Firestore 取得 → Hive キャッシュ（groupId 不要化）
  - `getSharedListsByGroup()`: Firestore 取得 → Hive キャッシュ
  - `updateSharedList()`: Firestore 更新 → Hive キャッシュ
  - `deleteSharedList()`: Firestore 削除 → Hive キャッシュ削除

**動作テスト**:

- SH 54D で動作確認完了
- グループ・リスト・アイテムの作成削除が正常動作

**コミット**: `b3b7838`

#### Phase 3: SharedItem 差分同期最適化（午後後半）

**目的**: Map 形式の真の効率化（リスト全体送信 → 単一アイテム送信）

**背景**:

- SharedItem は Map<String, SharedItem>形式だが、従来はリスト全体を送信
- FirestoreSharedListRepository には既に差分同期メソッドが実装済みだったが、HybridSharedListRepository が活用していなかった

**実装内容**:

- `hybrid_shared_list_repository.dart`の 3 つのメソッドを Firestore 優先＋差分同期に変更
  - `addSingleItem()`: Firestore 差分追加（`items.{itemId}`のみ） → Hive キャッシュ
  - `removeSingleItem()`: Firestore 論理削除（`items.$itemId.isDeleted`のみ） → Hive キャッシュ
  - `updateSingleItem()`: Firestore 差分更新（`items.{itemId}`のみ） → Hive キャッシュ

**最適化効果**:

- **Before**: リスト全体送信（10 アイテム = ~5KB）
- **After**: 単一アイテム送信（1 アイテム = ~500B）
- **データ転送量約 90%削減達成** 🎉

**技術詳細**:

```dart
// Firestore差分更新の例（firestore_shared_list_repository.dart）
await _collection(list.groupId).doc(listId).update({
  'items.${item.itemId}': _itemToFirestore(item), // ← 単一フィールドのみ更新
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**コミット**: `2c41315`

### 2. アイテム追加ダイアログ二重送信防止 ✅

**問題**:

- アイテム追加処理中に「追加」ボタンを複数回タップ可能
- Firestore 処理待機中にダイアログが閉じない
- 結果的に同じアイテムが複数回追加される

**対策実装**:

```dart
// shopping_list_page_v2.dart
bool isSubmitting = false; // 🔥 二重送信防止フラグ

ElevatedButton(
  onPressed: isSubmitting ? null : () async {
    if (isSubmitting) return;

    // 🔥 送信開始：ボタン無効化
    setDialogState(() {
      isSubmitting = true;
    });

    try {
      await repository.addSingleItem(currentList.listId, newItem);

      // ダイアログを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // エラー時は送信フラグをリセット
      setDialogState(() {
        isSubmitting = false;
      });
    }
  },
  child: isSubmitting
    ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : const Text('追加'),
),
```

**特徴**:

- 処理中はボタンを無効化（`onPressed: null`）
- 視覚的フィードバック（ローディングスピナー表示）
- `context.mounted`チェックでダイアログ閉じる前に確認
- エラー時は送信フラグをリセット

**コミット**: `dcc60cb`

### Known Issues & Solutions

#### Issue 1: SH 54D の Firestore 接続問題 ⚠️

**症状**:

```
Unable to resolve host "firestore.googleapis.com": No address associated with hostname
```

**原因**: SH 54D 特有のネットワーク接続問題（Known Issue）

**対応**: モバイル通信に切り替えて解決 ✅

### Technical Learnings

1. **Firestore 差分同期の重要性**

   - Map 形式のデータ構造だけでは不十分
   - Firestore の更新 API も対応させる必要がある
   - `items.{itemId}`フィールド単位の更新で大幅な効率化

2. **Repository 層の役割分担**

   - **FirestoreRepository**: 差分同期メソッド提供（既に実装済み）
   - **HybridRepository**: それらを活用する（今回実装）

3. **UI/UX 改善の重要性**
   - 二重送信防止は必須機能
   - 視覚的フィードバック（ローディングスピナー）でユーザー体験向上

### Next Session Tasks（優先度順）

#### 1. Firestore ユーザー情報構造簡素化 📝

**現状**:

```
/users/{uid}/profile/profile  ← 無駄に深い
```

**改善案**:

```
/users/{uid}  ← シンプル
  ├─ displayName
  ├─ email
  ├─ createdAt
  └─ updatedAt
```

**理由**:

- ユーザー情報は増える可能性が低い
- サブコレクション不要（プロファイル 1 つだけ）
- 読み書きのパフォーマンス向上

**影響範囲**:

- `firestore_user_name_service.dart`
- `qr_invitation_service.dart`
- `firestore.rules`
- マイグレーション処理

#### 2. Firestore 同期時のローディング表示確認 🔄

**確認箇所**:

- グループ一覧読み込み時
- リスト一覧読み込み時
- サインイン・サインアップ時
- QR 招待受諾時

**実装済み**:

- アイテム追加ダイアログ（CircularProgressIndicator）

---
