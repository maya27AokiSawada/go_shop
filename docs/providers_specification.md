# Go Shop - Flutter Shopping List App 仕様書

## プロジェクト概要

**アプリケーション名**: Go Shop  
**説明**: Firebaseバックエンドを使用したFlutter製買い物リストアプリ  
**作成日**: 2024年  
**最終更新**: 2025年9月26日  
**バージョン**: 1.0.0+1  

### 主要機能
- ユーザー認証（Firebase Auth）
- グループベースの買い物リスト共有
- メンバー管理機能
- ローカル/リモートデータストレージ（Hive/Firestore）
- リアルタイム状態管理（Riverpod）

---

## アーキテクチャ

### フレームワーク・ライブラリ
- **Flutter**: 3.9.2 (メインフレームワーク)
- **Firebase**: 
  - Core: ^4.1.1
  - Auth: ^6.1.0 
  - Firestore: ^6.0.2
- **状態管理**: Riverpod ^3.0.0
- **ローカルDB**: Hive ^2.2.3
- **コード生成**: 
  - Freezed ^2.4.1
  - JSON Serializable ^6.7.1
  - Riverpod Generator ^3.0.0-dev.1

### アーキテクチャパターン
- **Repository Pattern**: データレイヤーの抽象化
- **Provider Pattern**: Riverpodによる状態管理
- **Layered Architecture**: UI - Provider - Repository - Model

---

## データモデル

### 1. SharedGroup（購入グループ）
```dart
@HiveType(typeId: 2)
@freezed
class SharedGroup with _$SharedGroup {
  const factory SharedGroup({
    @HiveField(0) required String groupName,     // グループ名
    @HiveField(1) required String groupId,      // グループID
    @HiveField(2) String? ownerName,            // オーナー名
    @HiveField(3) String? ownerEmail,           // オーナーメール
    @HiveField(4) String? ownerUid,             // FirebaseUID
    @HiveField(5) List<SharedGroupMember>? members,  // メンバーリスト
  }) = _SharedGroup;
}
```

### 2. SharedGroupMember（グループメンバー）
```dart
@HiveType(typeId: 1)
@freezed
class SharedGroupMember with _$SharedGroupMember {
  const factory SharedGroupMember({
    @HiveField(0) @Default('') String memberId,    // メンバーID
    @HiveField(1) required String name,            // 名前
    @HiveField(2) required String contact,         // 連絡先
    @HiveField(3) required SharedGroupRole role, // 役割
    @HiveField(4) @Default(false) bool isSignedIn, // サインイン状態
  }) = _SharedGroupMember;
}
```

### 3. SharedGroupRole（役割）
```dart
@HiveType(typeId: 0)
enum SharedGroupRole {
  @HiveField(0) leader,   // リーダー
  @HiveField(1) parent,   // 親
  @HiveField(2) child,    // 子供
}
```

### 4. SharedList（買い物リスト）
```dart
@HiveType(typeId: 10)
@freezed
class SharedList with _$SharedList {
  const factory SharedList({
    @HiveField(0) required String ownerUid,
    @HiveField(1) required String groupId,
    @HiveField(2) required String groupName,
    @HiveField(3) required List<SharedItem> items,
  }) = _SharedList;
}
```

### 5. SharedItem（買い物アイテム）
```dart
@HiveType(typeId: 11)
@freezed
class SharedItem with _$SharedItem {
  const factory SharedItem({
    @HiveField(0) required String itemId,
    @HiveField(1) required String name,
    @HiveField(2) @Default(1) int quantity,
    @HiveField(3) @Default(false) bool isPurchased,
    @HiveField(4) String? addedBy,
    @HiveField(5) DateTime? addedAt,
    @HiveField(6) String? purchasedBy,
    @HiveField(7) DateTime? purchasedAt,
  }) = _SharedItem;
}
```

---

## プロバイダー仕様

### 1. AuthProvider
**ファイル**: `lib/providers/auth_provider.dart`

```dart
// AuthServiceのインスタンスプロバイダー
final authProvider = Provider<AuthService>((ref) => AuthService());

// Firebase認証状態の監視プロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

**機能**:
- Firebase認証状態の監視
- サインイン/サインアウト機能
- ユーザー情報の取得

### 2. SharedGroupProvider
**ファイル**: `lib/providers/purchase_group_provider.dart`

```dart
// リポジトリプロバイダー
final SharedGroupRepositoryProvider = Provider<SharedGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    throw UnimplementedError('FirestoreSharedGroupRepository is not implemented yet');
  } else {
    return HiveSharedGroupRepository(ref);  
  }
});

// 現在のグループIDプロバイダー
final currentGroupIdProvider = Provider<String>((ref) => 'currentGroup');

// メインのグループ管理プロバイダー
final SharedGroupProvider = AsyncNotifierProvider<SharedGroupNotifier, SharedGroup>(
  () => SharedGroupNotifier(),
);

// すべてのグループ取得プロバイダー
final allGroupsProvider = FutureProvider<List<SharedGroup>>((ref) async {
  final repository = ref.read(SharedGroupRepositoryProvider);
  return await repository.getAllGroups();
});
```

**SharedGroupNotifierメソッド**:
- `updateGroup(SharedGroup group)`: グループ更新
- `addMember(SharedGroupMember member)`: メンバー追加
- `removeMember(SharedGroupMember member)`: メンバー削除
- `updateMembers(List<SharedGroupMember> members)`: メンバーリスト更新
- `setMyId(String myId)`: 自分のID設定
- `createGroup()`: グループ作成
- `deleteGroup(String groupId)`: グループ削除

### 3. SharedListProvider
**ファイル**: `lib/providers/shopping_list_provider.dart`

```dart
// Hive Boxプロバイダー
final sharedListBoxProvider = Provider<Box<SharedList>>((ref) {
  return Hive.box<SharedList>('sharedLists');
});

// メインの買い物リスト管理プロバイダー
final sharedListProvider = AsyncNotifierProvider<SharedListNotifier, SharedList>(
  () => SharedListNotifier(),
);

// フィルタープロバイダー
final purchasedItemsProvider = Provider<List<SharedItem>>((ref) => /* ... */);
final unpurchasedItemsProvider = Provider<List<SharedItem>>((ref) => /* ... */);
final memberItemsProvider = Provider.family<List<SharedItem>, String>((ref, memberId) => /* ... */);
```

---

## Repository パターン

### 1. SharedGroupRepository (抽象クラス)
**ファイル**: `lib/datastore/purchase_group_repository.dart`

```dart
abstract class SharedGroupRepository {
  Future<SharedGroup> initializeGroup();
  Future<SharedGroup> addMember(SharedGroupMember member);
  Future<SharedGroup> removeMember(SharedGroupMember member);
  Future<SharedGroup> setMemberId(SharedGroupMember member, String newId);
  Future<SharedGroup> updateMembers(List<SharedGroupMember> members);
  Future<List<SharedGroup>> getAllGroups();
  Future<SharedGroup> createGroup(String groupId, String groupName, SharedGroupMember member);
  Future<SharedGroup> deleteGroup(String groupId);
  Future<SharedGroup> setMyId(String myId);
  Future<SharedGroup> getGroup(String groupId);
  Future<SharedGroup> updateGroup(SharedGroup group);
}
```

### 2. HiveSharedGroupRepository (実装クラス)
**ファイル**: `lib/datastore/hive_purchase_group_repository.dart`

**特徴**:
- Hiveローカルストレージ使用
- 開発環境用データストレージ
- オフライン対応

### 3. 今後の拡張: FirestoreSharedGroupRepository
- Firestore Cloud Database使用
- 本番環境用データストレージ
- リアルタイム同期対応

---

## UI コンポーネント

### ページ構成
1. **HomePage** (`lib/pages/home_page.dart`)
   - 認証フォーム
   - ユーザー情報保存
   - ナビゲーション

2. **SharedGroupPage** (`lib/pages/purchase_group_page.dart`)
   - グループ管理
   - メンバーの追加・編集・削除
   - グループ名・リスト名編集

3. **SharedListPage** (`lib/pages/shopping_list_page.dart`)
   - 買い物リスト表示
   - アイテムの追加・削除・購入状態変更

4. **SignedInPage** (`lib/pages/signed_in_page.dart`)
   - ログイン後のメインページ

### ウィジェット
1. **MemberListTileWidget** (`lib/widgets/member_list_tile_widget.dart`)
   - メンバー情報表示用リストタイル

2. **NewMemberInputForm** (`lib/widgets/new_member_input_form.dart`)
   - 新規メンバー追加フォーム

3. **SharedListWidget** (`lib/widgets/shopping_list_widget.dart`)
   - 買い物リスト表示ウィジェット

4. **FamilyMemberWidget** (`lib/widgets/family_member_widget.dart`)
   - 家族メンバー表示ウィジェット

---

## 認証サービス

### AuthService
**ファイル**: `lib/helper/auth_service.dart`

**主要メソッド**:
```dart
class AuthService {
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<User?> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  User? get currentUser;
  String? get getCurrentUid;
  bool get isLoggedIn;
}
```

### MockAuthService  
**ファイル**: `lib/helper/mock_auth_service.dart`
- テスト・開発用モック認証サービス
- UserMockクラス使用

---

## エラー状況と対応課題

### 現在のエラー
1. **Riverpod Generator互換性問題**
   - `FutureProviderRef` 未定義エラー
   - Generatorバージョン競合

2. **SharedGroupPage**
   - `memberID` vs `memberId` プロパティ名不一致
   - null安全性チェック不足
   - `updatedGroup` 変数未定義

3. **HomePage**
   - `email` 変数未定義
   - `saveDefaultGroupProvider` メソッド未実装

### 対応方針
1. Riverpod Generatorの使用を一時的に停止
2. 従来のProvider構文に変更
3. プロパティ名の統一
4. Null安全性の強化

---

## 開発環境設定

### Flutter SDK
- バージョン: 3.9.2
- Dart SDK: 3.9.0

### ビルドツール
- build_runner: ^2.4.0
- コード生成時: `dart run build_runner build --delete-conflicting-outputs`

### フレーバー設定
**ファイル**: `lib/flavors.dart`
```dart
enum Flavor { dev, prod }

class F {
  static Flavor? appFlavor;
  static String get title => switch(appFlavor) {
    Flavor.dev => 'Go Shop Dev',
    Flavor.prod => 'Go Shop',
    null => 'title'
  };
}
```

---

## 今後の実装予定

### 優先度高
1. エラー修正とビルド安定化
2. FirestoreRepository実装
3. リアルタイム同期機能

### 優先度中
1. UI/UXの改善
2. エラーハンドリング強化
3. テストコード追加

### 優先度低
1. 多言語対応
2. プッシュ通知
3. データエクスポート機能

---

## 技術的備考

### Hiveデータベース構造
- TypeID 0: SharedGroupRole (enum)
- TypeID 1: SharedGroupMember
- TypeID 2: SharedGroup  
- TypeID 10: SharedList
- TypeID 11: SharedItem

### Firebase設定
- 設定ファイル: `lib/firebase_options.dart`
- Android/iOS/Web対応

### コード生成ファイル
- `*.g.dart`: Hive TypeAdapter
- `*.freezed.dart`: Freezed クラス生成
- `*.riverpod.dart`: Riverpod Generator（一時停止中）

---

*この仕様書は開発状況に合わせて随時更新されます。*
