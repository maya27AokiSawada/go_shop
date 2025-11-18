# Go Shop - AI Coding Agent Instructions

## Project Overview
Go Shopは家族・グループ向けの買い物リスト共有Flutterアプリです。Firebase Auth（ユーザー認証）とCloud Firestore（データベース）を使用し、Hiveをローカルキャッシュとして併用するハイブリッド構成です。

## Architecture & Key Components

### State Management - Riverpod Patterns
```dart
// AsyncNotifierProvider pattern (primary)
final purchaseGroupProvider = AsyncNotifierProvider<PurchaseGroupNotifier, PurchaseGroup>(
  () => PurchaseGroupNotifier(),
);

// Repository abstraction via Provider
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    // Production: Use Firestore with Hive cache (hybrid mode)
    return FirestorePurchaseGroupRepository(ref);
  } else {
    // Development: Use Hive only for faster local testing
    return HivePurchaseGroupRepository(ref);
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
class HivePurchaseGroupRepository implements PurchaseGroupRepository {
  final Ref _ref;
  HivePurchaseGroupRepository(this._ref);

  Box<PurchaseGroup> get _box => _ref.read(purchaseGroupBoxProvider);
}
```

### Data Models - Freezed + Hive Integration
Models use both `@freezed` and `@HiveType` annotations:
```dart
@HiveType(typeId: 1)
@freezed
class PurchaseGroupMember with _$PurchaseGroupMember {
  const factory PurchaseGroupMember({
    @HiveField(0) @Default('') String memberId,  // Note: memberId not memberID
    @HiveField(1) required String name,
    // ...
  }) = _PurchaseGroupMember;
}
```

**Hive TypeIDs**: 0=PurchaseGroupRole, 1=PurchaseGroupMember, 2=PurchaseGroup, 3=ShoppingItem, 4=ShoppingList

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
2. **Null Safety**: Guard against `purchaseGroup.members` being null
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
  'groupId': String,       // purchaseGroupId
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
bool isDefaultGroup(PurchaseGroup group, User? currentUser) {
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
   - Clear Hive boxes (PurchaseGroup + ShoppingList)
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
- `lib/pages/home_page.dart` (mode switcher added)
- `lib/screens/home_screen.dart` (BottomNavigationBar labels)
- `lib/widgets/app_initialize_widget.dart` (mode initialization)
- `lib/models/user_settings.dart` (appMode field added)

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

Focus on maintaining consistency with existing patterns rather than introducing new architectural approaches.
