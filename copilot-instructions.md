# Go Shop - AI Coding Agent Instructions

## Project Overview
Go Shopは家族・グループ向けの買い物リスト共有Flutterアプリです。Firebase AuthとHive（ローカルDB）を使用し、将来的にFirestoreへの移行を予定しています。

## Architecture & Key Components

### 🛡️ Crash-Proof Repository System
HybridPurchaseGroupRepositoryは安定性最優先の初期化システムを実装：

```dart
// InitializationStatus enum による詳細状態管理
enum InitializationStatus {
  notStarted, initializingHive, hiveReady, initializingFirestore,
  fullyReady, hiveOnlyMode, criticalError
}

// リトライメカニズム（指数バックオフ、最大3回、15秒タイムアウト）
Future<void> _attemptFirestoreInitializationWithRetry()

// プログレス通知システム（UI統合）
void setInitializationProgressCallback(Function(InitializationStatus, String?) callback)
```

### Environment Configuration
- **Flavor.dev**: Hiveのみモード（安定動作確認済み）
- **Flavor.prod**: Firestore統合モード（crash-proof機能テスト中）

### UI応答性アーキテクチャ (2024-11-01 重要修正)
```dart
// AllGroupsNotifier - UI専用の高速データアクセス
class AllGroupsNotifier extends AsyncNotifier<List<PurchaseGroup>> {
  @override
  Future<List<PurchaseGroup>> build() async {
    // ❌ 旧実装: waitForSafeInitialization()でUIブロッキング
    // ✅ 新実装: 直接Hiveアクセスで即座に表示
    final hiveRepo = ref.read(hivePurchaseGroupRepositoryProvider);
    final allGroups = await hiveRepo.getAllGroups();
    return allGroups; // 即座にデータ返却、UI応答性確保
  }
}

// TestScenarioWidget - 安全性重視の包括テスト
// waitForSafeInitialization()を使用して完全初期化待機
```

### 基本方針
- **安定性最優先**: クラッシュ防止、ローディングスピナー許容
- **ユーザー体験重視**: 詳細な進行状況表示、適切なエラーメッセージ
- **フォールバック戦略**: Firestore接続失敗時はHiveのみモードで継続

## Repository Design
- **Hive+Firestore ハイブリッド設計**: 安全なフォールバック機能付き
- **デフォルトグループ**: プライベートリスト（Hive主体、Firestoreバックアップ）
- **ユーザー情報**: SharedPreferences保存、Firestore同期
- **同期方針**: 不整合時はオーナーUID基準でローカル/Firestore優先決定
## State Management - Riverpod Patterns
```dart
// AsyncNotifierProvider pattern (primary)
final purchaseGroupProvider = AsyncNotifierProvider<PurchaseGroupNotifier, PurchaseGroup>(
  () => PurchaseGroupNotifier(),
);

// Repository abstraction via Provider
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    return HybridPurchaseGroupRepository(ref); // Crash-proof implementation
  } else {
    return HivePurchaseGroupRepository(ref);
  }
});
```

⚠️ **Critical**: Riverpod Generator is currently disabled due to version conflicts. Use traditional Provider syntax only.

### Data Layer - Repository Pattern
- **Abstract**: `lib/datastore/purchase_group_repository.dart`
- **Hive Implementation**: `lib/datastore/hive_purchase_group_repository.dart`
- **Hybrid Implementation**: `lib/datastore/hybrid_purchase_group_repository.dart` (crash-proof)
- **Firestore**: Not implemented yet, use `throw UnimplementedError()`

Repository constructors must accept `Ref` for Riverpod integration:
```dart
class HybridPurchaseGroupRepository implements PurchaseGroupRepository {
  final Ref _ref;
  HybridPurchaseGroupRepository(this._ref);

  Box<PurchaseGroup> get _box => _ref.read(purchaseGroupBoxProvider);

  // UI応答性のための非ブロッキングメソッド
  Future<List<PurchaseGroup>> getAllGroupsForUI() async {
    return await _getAllGroupsInternal(); // 初期化待機をスキップ
  }
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

## Firestore Structure
- `/users/{uid}/` (UID一致時のみアクセス可能)
    - `userProfile`: ユーザープロフィール情報
    - `purchaseGroups`: ユーザー所属グループIDリスト
- `/purchaseGroups/{groupId}/`
    - `purchaseGroupクラスデータ` (allowedUidsにUID含む場合のみアクセス可能)
    - `shoppingLists/{listId}/`
    - `allowedUids`: グループアクセス可能ユーザーIDリスト
    - `acceptedUids`: 招待受諾ユーザーとセキュリティキーのマップ
- **ID生成**: UID=FirebaseAuth自動、groupId/listId=UUIDv4
## Critical Development Patterns

### Initialization Sequence
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  F.appFlavor = Flavor.dev;  // Set in main()
  await _initializeHive();  // Must pre-open all Boxes
  runApp(ProviderScope(child: MyApp()));
}
```

### Crash-Proof Implementation
```dart
// TestScenarioWidgetでのcrash-proofテスト
final hybridRepo = repository as HybridPurchaseGroupRepository;
hybridRepo.setInitializationProgressCallback((status, message) {
  // UI更新: ローディングスピナー、プログレス表示
});
await hybridRepo.waitForSafeInitialization(); // 15秒タイムアウト付き
```

### ⚠️ Critical Error-Prone Areas & Anti-Patterns

#### 🚫 Riverpod Anti-Patterns (過去の失敗例)
**絶対にやってはいけないこと:**

1. **Riverpod Generator使用** - ❌ NEVER USE
   ```dart
   // ❌ BAD: これまで何度もビルドエラーの原因
   @riverpod
   class SomeNotifier extends _$SomeNotifier { }

   // ✅ GOOD: 従来のProvider構文のみ使用
   final someProvider = AsyncNotifierProvider<SomeNotifier, SomeData>(
     () => SomeNotifier(),
   );
   ```

2. **Provider間の循環依存** - 過去に複数回発生
   ```dart
   // ❌ BAD: 無限ループ・メモリリーク発生
   final providerA = Provider((ref) => ref.read(providerB));
   final providerB = Provider((ref) => ref.read(providerA));

   // ✅ GOOD: 依存関係を一方向に設計
   final baseProvider = Provider((ref) => BaseService());
   final derivedProvider = Provider((ref) => DerivedService(ref.read(baseProvider)));
   ```

3. **Consumer内での不適切なref.read()** - 頻発する問題
   ```dart
   // ❌ BAD: build内でref.read()するとリビルド時に状態が失われる
   Consumer(builder: (context, ref, child) {
     final data = ref.read(dataProvider); // 危険！
     return Text(data.toString());
   })

   // ✅ GOOD: ref.watch()で監視
   Consumer(builder: (context, ref, child) {
     final data = ref.watch(dataProvider);
     return data.when(
       data: (value) => Text(value.toString()),
       loading: () => CircularProgressIndicator(),
       error: (err, stack) => Text('Error: $err'),
     );
   })
   ```

4. **AsyncNotifier内でのawait忘れ** - データ競合の元凶
   ```dart
   // ❌ BAD: await忘れで状態不整合
   class BadNotifier extends AsyncNotifier<List<Item>> {
     @override
     Future<List<Item>> build() async {
       repository.loadData(); // await忘れ！
       return [];
     }
   }

   // ✅ GOOD: 必ずawaitを使用
   class GoodNotifier extends AsyncNotifier<List<Item>> {
     @override
     Future<List<Item>> build() async {
       return await repository.loadData();
     }
   }
   ```

5. **Provider dispose忘れ** - メモリリーク頻発
   ```dart
   // ❌ BAD: リソースリーク
   final streamProvider = StreamProvider.autoDispose((ref) {
     final controller = StreamController<String>();
     // dispose処理なし - リーク！
     return controller.stream;
   });

   // ✅ GOOD: 適切なdispose処理
   final streamProvider = StreamProvider.autoDispose((ref) {
     final controller = StreamController<String>();
     ref.onDispose(() {
       controller.close();
     });
     return controller.stream;
   });
   ```

#### 🚫 Other Critical Anti-Patterns

6. **Property Naming**: Always use `memberId`, never `memberID` - 過去に複数回のタイポ修正
7. **Null Safety**: Guard against `purchaseGroup.members` being null - NullPointerException頻発
8. **Hive Box Access**: Ensure Boxes are opened in `_initializeHive()` before use - 初期化順序エラー
9. **Firebase初期化順序**: WidgetsFlutterBinding.ensureInitialized()より先は危険
10. **Async/Await Chain**: 過度なネストでデッドロック発生経験あり

#### 💡 Riverpod Best Practices (学習済み)
```dart
// ✅ Repository injection pattern
final repositoryProvider = Provider<SomeRepository>((ref) {
  return F.appFlavor == Flavor.prod
    ? HybridRepository(ref)
    : HiveRepository(ref);
});

// ✅ Error handling with AsyncValue
final dataProvider = AsyncNotifierProvider<DataNotifier, List<Data>>(
  () => DataNotifier(),
);

// ✅ Safe state updates
class DataNotifier extends AsyncNotifier<List<Data>> {
  @override
  Future<List<Data>> build() async {
    try {
      return await ref.read(repositoryProvider).loadAll();
    } catch (e, stack) {
      // ログ出力 + 安全なフォールバック
      AppLogger.error('Data load failed: $e');
      return [];
    }
  }
}
```

### Build & Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs  # For *.g.dart files
flutter analyze  # Check for compilation errors
```

## Current Development Status

### ✅ Completed
- InitializationStatus enum定義（7状態の詳細管理）
- リトライメカニズム実装（指数バックオフ、3回試行、15秒タイムアウト）
- 進行状況通知システム（UI統合、詳細ログ）
- TestScenarioWidget UI統合（ローディングスピナー、プログレス表示）
- **UI応答性問題の完全解決** (2024-11-01):
  - AllGroupsNotifierの`waitForSafeInitialization()`ブロッキング問題を解決
  - HybridRepositoryに`getAllGroupsForUI()`メソッド追加（非ブロッキング）
  - 通常UI用の直接Hiveアクセス実装（即座にデータ表示）
  - テスト環境の安全性維持（初期化待機継続）
  - メモリリーク修正（TestScenarioWidget dispose問題）

### 🔄 Current Focus
- **Flavor.prod本格テスト**: Firestore初期化エラー検証
- リトライ機能、タイムアウト処理、Hiveのみフォールバック動作確認
- **UI/UX最適化**: データ表示の即応性とテスト安全性の両立

### Development Workflows

#### When Adding New Riverpod Providers
⚠️ **重要**: 過去の失敗を繰り返さないためのチェックリスト

1. **Provider構文確認**:
   ```bash
   # ❌ Generator使用のチェック
   grep -r "@riverpod\|@Riverpod" lib/  # これが見つかったら削除！

   # ✅ 従来構文のみ使用確認
   grep -r "AsyncNotifierProvider\|Provider\|StateProvider" lib/
   ```

2. **循環依存チェック**:
   ```dart
   // 新しいProvider追加前に依存関係図を描く
   // A → B → C → A のような循環を避ける
   ```

3. **メモリリーク防止**:
   ```dart
   // StreamControllerやTimerを使用する場合は必ずdispose処理
   final someProvider = StreamProvider.autoDispose((ref) {
     // ref.onDispose(() { /* cleanup */ }); を忘れずに！
   });
   ```

4. **コンパイルエラーチェック**:
   ```bash
   flutter analyze
   # Riverpod関連エラーは即座に修正（放置すると連鎖エラー）
   ```

#### When Testing Crash-Proof Features
1. Use TestScenarioWidget for comprehensive testing
2. Monitor initialization progress with status callbacks
3. Verify graceful fallback to Hive-only mode
4. Test retry mechanisms and timeout handling
5. **Riverpod state consistency**: Check AsyncValue states during initialization

#### Firebase Integration (Future)
Firebase is configured but not actively used. Current auth is placeholder. When implementing:
- Replace `lib/firebase_options.dart` dummy values
- Implement Firestore repository variants
- Use Flavor switching for data source selection

## Test Strategy
- **Primary**: TestScenarioWidgetでのcrash-proof機能検証
- **Repository単体テスト**: 安全初期化、リトライ、フォールバック
- **UI統合テスト**: プログレス表示、エラーハンドリング、ユーザー体験
- **本番環境テスト**: Flavor.prodでのFirestore統合エラー処理
- **🔥 Riverpod State Testing**: AsyncValue状態遷移、Provider依存関係、メモリリーク検証

### 🚨 Pre-Commit チェックリスト (過去の失敗防止)
```bash
# 1. Riverpod Generator使用チェック（絶対禁止）
find lib/ -name "*.dart" -exec grep -l "@riverpod\|@Riverpod" {} \; | wc -l
# → 0であること必須

# 2. コンパイルエラーチェック
flutter analyze --no-fatal-infos
# → No issues found であること

# 3. Provider循環依存チェック
# → 手動でProvider依存関係図を確認

# 4. メモリリーク潜在チェック
grep -r "StreamController\|Timer" lib/ --include="*.dart" | grep -v "ref.onDispose"
# → StreamController/Timer使用箇所にdispose処理があること確認
```

**Golden Rule**: 過去の失敗パターンを絶対に繰り返さない。安定性 > 新機能追加。Riverpod Generatorは触らない。

Focus on maintaining crash-proof stability and comprehensive error handling rather than introducing new architectural approaches.
