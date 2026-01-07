# Go Shop - Flutter Shopping List App 仕様書

## プロジェクト概要

**アプリケーション名**: Go Shop
**説明**: Firebaseバックエンドを使用したFlutter製買い物リストアプリ
**作成日**: 2024年
**最終更新**: 2026年1月7日
**バージョン**: 1.0.0+1

### 主要機能
- ユーザー認証（Firebase Auth）- 必須サインイン仕様
- グループベースの買い物リスト共有
- メンバー管理機能
- **Firestore-first Hybrid Architecture** (Firestore → Hive cache)
- リアルタイム状態管理（Riverpod）
- リアルタイム同期（Firestore `snapshots()`）
- QRコード招待システム（v3.1軽量版）
- アプリ間通知システム（Firestoreベース）
- **差分同期** (90%ネットワーク削減達成)

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
- **Firestore-first Hybrid Pattern**: Firestore優先読み込み + Hiveキャッシュ (2025-12実装)
- **Repository Pattern**: データレイヤーの抽象化 (Hybrid/Firestore/Hive)
- **Provider Pattern**: Riverpodによる状態管理
- **Layered Architecture**: UI - Provider - Repository - Model
- **Differential Sync**: Map-based単一アイテム更新（90%ネットワーク削減）

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
@HiveType(typeId: 4)
@freezed
class SharedList with _$SharedList {
  const factory SharedList({
    @HiveField(0) required String listId,
    @HiveField(1) required String listName,
    @HiveField(2) required String groupId,
    @HiveField(3) @Default({}) Map<String, SharedItem> items,  // Map型で差分同期対応
    @HiveField(4) String? ownerUid,
    @HiveField(5) DateTime? createdAt,
    @HiveField(6) DateTime? updatedAt,
  }) = _SharedList;

  // Getter for active items (isDeleted = false)
  List<SharedItem> get activeItems =>
      items.values.where((item) => !item.isDeleted).toList();
}
```

**重要**: `items`はMap<String, SharedItem>型を使用し、itemIdをキーとして管理。これにより差分同期（単一アイテムの追加・更新・削除）が可能。

### 5. SharedItem（買い物アイテム）
```dart
@HiveType(typeId: 3)
@freezed
class SharedItem with _$SharedItem {
  const factory SharedItem({
    @HiveField(0) required String name,
    @HiveField(1) @Default(false) bool isPurchased,
    @HiveField(2) @Default(1) int quantity,
    @HiveField(3) String? memberId,  // 登録者のUID
    @HiveField(4) DateTime? purchaseDate,
    @HiveField(5) DateTime? deadline,  // 買い物期限（未実装）
    @HiveField(6) String? memo,
    @HiveField(7) int? shoppingInterval,  // 定期購入間隔（日数）
    @HiveField(8) required String itemId,  // UUID v4
    @HiveField(9) @Default(false) bool isDeleted,  // 論理削除フラグ
    @HiveField(10) DateTime? deletedAt,  // 削除日時
  }) = _SharedItem;
}
```

**差分同期対応**:
- `itemId`: UUID v4で一意性保証
- `isDeleted`: 論理削除（物理削除は30日後に自動実行）
- Map型と組み合わせて単一アイテムの追加・更新・削除が可能

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
// リポジトリプロバイダー (Hybrid対応)
final SharedGroupRepositoryProvider = Provider<SharedGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    // Production: Firestore-first with Hive cache
    return HybridPurchaseGroupRepository(ref);
  } else {
    // Development: Hive only for faster local testing
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

### 3. HybridSharedGroupRepository (Firestore-first実装) ✅
**ファイル**: `lib/datastore/hybrid_purchase_group_repository.dart`

**特徴**:
- **Firestore優先読み込み**: 常に最新データを取得
- **Hiveキャッシュ**: オフライン時のフォールバック
- **認証必須**: prod環境では常にFirestore使用
- **自動切り替え**: Firestoreエラー時は自動的にHiveに切替

**実装パターン** (2025-12実装):
```dart
if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
  try {
    // 1. Firestoreから最新データ取得
    final firestoreData = await _firestoreRepo!.getData();

    // 2. Hiveにキャッシュ
    await _hiveRepo.saveData(firestoreData);

    return firestoreData;
  } catch (e) {
    // Firestoreエラー時はHiveフォールバック
    return await _hiveRepo.getData();
  }
}
```

### 4. FirestoreSharedListRepository (差分同期実装) ✅
**ファイル**: `lib/datastore/firestore_shared_list_repository.dart`

**差分同期メソッド** (2025-12実装):
```dart
// 単一アイテム追加 (~500B)
Future<void> addSingleItem(String listId, SharedItem item) async {
  await _collection(groupId).doc(listId).update({
    'items.${item.itemId}': _itemToFirestore(item),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

// 単一アイテム更新 (~500B)
Future<void> updateSingleItem(String listId, SharedItem item) async {
  await _collection(groupId).doc(listId).update({
    'items.${item.itemId}': _itemToFirestore(item),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

// 単一アイテム削除（論理削除） (~200B)
Future<void> removeSingleItem(String listId, String itemId) async {
  await _collection(groupId).doc(listId).update({
    'items.$itemId.isDeleted': true,
    'items.$itemId.deletedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

**パフォーマンス向上**:
- Before: 全リスト送信 (~5KB for 10 items)
- After: 単一アイテム送信 (~500B per item)
- **90%ネットワーク削減達成** 🎉

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

## 完了済み実装 (2025-12 ~ 2026-01)

### 1. Firestore-first Architecture 移行 ✅
- 全3層（SharedGroup/SharedList/SharedItem）でFirestore優先読み込み実装
- HybridRepository パターン確立
- 認証必須アプリケーション化

### 2. 差分同期実装 ✅
- Map<String, SharedItem>型への移行完了
- addSingleItem/updateSingleItem/removeSingleItem実装
- 90%ネットワーク削減達成

### 3. リアルタイム同期実装 ✅
- Firestore `snapshots()` による自動UI更新
- StreamBuilder統合
- デバイス間同期確認済み

### 4. QR招待システム完全実装 ✅
- QRコードv3.1（軽量版 - Firestore連携）
- 通知システム統合
- グループ削除通知対応

### 5. GitHub Actions CI/CD構築 ✅
- ubuntu-latest環境でのAndroid APKビルド自動化
- bash Here-Document構文採用
- main ブランチpush時の自動ビルド

### 既知の制限事項
1. **Riverpod Generator無効化**
   - バージョン競合により従来構文使用
   - 安定版リリース後に再検討

2. **定期購入機能**
   - データ構造は実装済み（shoppingInterval）
   - UI実装は未完了（優先度: LOW）

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

## 今後の実装予定 (2026年以降)

### 優先度高 (Q1 2026)
1. ✅ ~~エラー修正とビルド安定化~~ (完了)
2. ✅ ~~FirestoreRepository実装~~ (完了)
3. ✅ ~~リアルタイム同期機能~~ (完了)
4. Google Playクローズドベータテスト開始
5. ユーザーフィードバック収集・改善

### 優先度中 (Q2 2026)
1. メンバー伝言メッセージ機能（設計書作成済み）
2. ホワイトボード機能（スケッチ共有）
3. UI/UXの改善（ユーザーフィードバック反映）
4. エラーハンドリング強化
5. テストコード追加

### 優先度低 (Q3-Q4 2026)
1. 多言語対応（英語版）
2. プッシュ通知（FCM統合）
3. データエクスポート機能
4. 定期購入機能UI実装
5. カテゴリ・タグ機能

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
