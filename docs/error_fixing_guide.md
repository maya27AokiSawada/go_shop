# エラー修正手順書

## 現在発生中の主要エラー

### 1. purchase_group_page.dart のエラー

#### エラー内容
```dart
// エラー: memberID プロパティが存在しない
= editedMember.copyWith(memberID: member.memberID);

// エラー: updatedGroup 変数が未定義
await ref.read(purchaseGroupProvider.notifier).updateMembers(updatedGroup.members);

// エラー: null安全性違反
itemCount: purchaseGroup.members.length,  // members が null の可能性
```

#### 修正方法
```dart
// 1. memberID → memberId に修正
= editedMember.copyWith(memberId: member.memberId);

// 2. updatedGroup の定義修正
final updatedGroup = purchaseGroup; // 現在のグループを使用

// 3. null安全性対応
itemCount: purchaseGroup.members?.length ?? 0,
final member = purchaseGroup.members![index];
```

### 2. home_page.dart のエラー

#### エラー内容
```dart
// エラー: email 変数未定義
if (userName.isNotEmpty && email.isNotEmpty) {

// エラー: saveDefaultGroupProvider メソッド未定義
await ref.read(saveDefaultGroupProvider(defaultGroup).future);
```

#### 修正方法
```dart
// 1. email 変数の定義
final email = emailController.text;

// 2. saveDefaultGroupProvider の実装
final saveDefaultGroupProvider = FutureProvider.family<void, PurchaseGroup>((ref, group) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  await repository.updateGroup(group);
});
```

### 3. Riverpod Generator エラー

#### エラー内容
```dart
// エラー: FutureProviderRef が未定義
Future<Box<PurchaseGroup>> purchaseGroupBox(PurchaseGroupBoxRef ref) async {
```

#### 修正方法
```dart
// Generator を使わない従来の方法
final purchaseGroupBoxProvider = FutureProvider<Box<PurchaseGroup>>((ref) async {
  return Hive.openBox<PurchaseGroup>('purchaseGroups');
});
```

## 修正優先度

### 最高優先度
1. ビルドエラーの解消（コンパイル不可状態）
2. プロパティ名の統一（memberId vs memberID）
3. null安全性対応

### 高優先度
1. Riverpod Generator の問題解決
2. 未定義変数・メソッドの実装
3. 状態管理の一貫性確保

### 中優先度
1. エラーハンドリングの改善
2. UI/UXの向上
3. コードの最適化

## 修正後の動作確認手順

1. ビルドエラー確認
```bash
flutter analyze
dart run build_runner build --delete-conflicting-outputs
```

2. 実行テスト
```bash
flutter run
```

3. 機能テスト
- 認証フロー
- グループ作成・編集
- メンバー管理
- データ永続化

## 技術的注意点

### Riverpod 3.0 の変更点
- StateProvider の構文変更
- Generator の安定性問題
- 旧バージョンとの互換性

### Hive データベース
- Box の初期化タイミング
- TypeAdapter の登録
- データマイグレーション

### Firebase 設定
- 認証設定の確認
- Firestore ルール
- セキュリティ設定