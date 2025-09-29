# Go Shop - AI Coding Agent Instructions

## Project Overview
Go Shopは家族・グループ向けの買い物リスト共有Flutterアプリです。Firebase AuthとHive（ローカルDB）を使用し、将来的にFirestoreへの移行を予定しています。

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
    throw UnimplementedError('FirestorePurchaseGroupRepository is not implemented yet');
  } else {
    return HivePurchaseGroupRepository(ref);  
  }
});
```

⚠️ **Critical**: Riverpod Generator is currently disabled due to version conflicts. Use traditional Provider syntax only.

### Data Layer - Repository Pattern
- **Abstract**: `lib/datastore/purchase_group_repository.dart`
- **Hive Implementation**: `lib/datastore/hive_purchase_group_repository.dart`  
- **Firestore**: Not implemented yet, use `throw UnimplementedError()`

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
F.appFlavor = Flavor.dev;  // Set in main()
```

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

### Firebase Integration (Future)
Firebase is configured but not actively used. Current auth is placeholder. When implementing:
- Replace `lib/firebase_options.dart` dummy values
- Implement Firestore repository variants
- Use Flavor switching for data source selection

## Common Issues & Solutions
- **Build failures**: Check for Riverpod Generator imports, remove them
- **Missing variables**: Ensure controllers and providers are properly defined before use  
- **Null reference errors**: Always null-check `members` lists and async data
- **Property not found**: Verify `memberId` vs `memberID` consistency across codebase

Focus on maintaining consistency with existing patterns rather than introducing new architectural approaches.