# CRUD処理ユニットテスト

GoShoppingアプリのグループ・リスト・アイテムCRUD処理の包括的なユニットテストです。

## テストファイル構成

### 1. SharedGroup CRUD Tests

**ファイル**: `test/datastore/shared_group_repository_test.dart`

**テスト内容**:

- ✅ グループの作成（createGroup）
- ✅ グループの取得（getGroupById）
- ✅ 全グループ取得（getAllGroups）
- ✅ グループの更新（updateGroup）
- ✅ グループの削除（deleteGroup）
- ✅ デフォルトグループ削除保護
- ✅ エッジケース（存在しないグループ、重複ID等）
- ✅ 複数ユーザー同時アクセス

**実行コマンド**:

```bash
flutter test test/datastore/shared_group_repository_test.dart
```

### 2. SharedList CRUD Tests

**ファイル**: `test/datastore/shared_list_repository_test.dart`

**テスト内容**:

- ✅ リストの作成（createSharedList）
- ✅ リストの取得（getSharedListById）
- ✅ グループ別リスト取得（getSharedListsByGroup）
- ✅ リストの更新（updateSharedList）
- ✅ リストの削除（deleteSharedList）
- ✅ **差分同期**: 単一アイテム追加（addSingleItem）
- ✅ **差分同期**: 単一アイテム更新（updateSingleItem）
- ✅ **差分同期**: 単一アイテム削除（removeSingleItem）
- ✅ 複数アイテムの効率的な更新
- ✅ エッジケース（存在しないリスト、重複削除等）
- ✅ パフォーマンステスト（100個のアイテム）

**実行コマンド**:

```bash
flutter test test/datastore/shared_list_repository_test.dart
```

### 3. Integration CRUD Tests

**ファイル**: `test/datastore/integration_crud_test.dart`

**テスト内容**:

- ✅ フルCRUDシナリオ（グループ→リスト→アイテム→削除）
- ✅ 複数ユーザー同時操作シナリオ
- ✅ 定期購入アイテムシナリオ
- ✅ アイテム削除と復元シナリオ
- ✅ エラーハンドリング（孤立リスト、削除済みグループ等）
- ✅ パフォーマンステスト（10グループ x 10リスト x 10アイテム）

**実行コマンド**:

```bash
flutter test test/datastore/integration_crud_test.dart
```

## 全テスト実行

### 全CRUDテストを実行

```bash
flutter test test/datastore/
```

### 全テスト（プロジェクト全体）を実行

```bash
flutter test
```

### カバレッジ付きテスト実行

```bash
flutter test --coverage
```

## モック生成

テストで使用するモッククラスを生成:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 必要な依存関係

`pubspec.yaml`に以下を追加済み:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  fake_cloud_firestore: ^3.1.3
  build_runner: ^2.4.0
```

## テスト実行前の準備

1. **依存関係インストール**:

   ```bash
   flutter pub get
   ```

2. **モック生成**:

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **テスト実行**:
   ```bash
   flutter test
   ```

## テストカバレッジ

### 現在のカバレッジ目標

| レイヤー     | 目標カバレッジ |
| ------------ | -------------- |
| Repository層 | 90%以上        |
| CRUD操作     | 100%           |
| エッジケース | 80%以上        |

### カバレッジレポート生成

```bash
# カバレッジ計測
flutter test --coverage

# HTMLレポート生成（lcovパッケージ必要）
genhtml coverage/lcov.info -o coverage/html

# レポート表示（Windowsの場合）
start coverage/html/index.html
```

## テスト設計思想

### 1. Firestore-First Architecture対応

- FakeFirebaseFirestoreを使用した実際のFirestore操作のシミュレーション
- Firestoreのトランザクション動作の検証

### 2. 差分同期の検証

- Map<String, SharedItem>形式の効率的な更新テスト
- 単一アイテム更新による90%ネットワーク削減の確認

### 3. エッジケースの網羅

- 存在しないID
- 重複操作
- 同時実行
- 大量データ

### 4. パフォーマンステスト

- 100個のアイテム追加
- 10x10x10の大規模データ作成
- 実行時間計測

## トラブルシューティング

### モック生成エラー

```bash
# キャッシュクリア
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### テスト失敗時

1. `flutter clean`でビルドキャッシュクリア
2. `flutter pub get`で依存関係再取得
3. モック再生成
4. テスト再実行

### Firestore関連エラー

- `fake_cloud_firestore`パッケージのバージョン確認
- Firestoreルールのシミュレーション制限に注意

## CI/CD統合

GitHub Actionsでのテスト実行例（`.github/workflows/flutter-ci.yml`）:

```yaml
- name: Run CRUD tests
  run: flutter test test/datastore/
```

## 次のステップ

- [ ] Provider層のテスト追加
- [ ] UI層のウィジェットテスト
- [ ] エンドツーエンドテスト
- [ ] モックサーバーを使用した統合テスト
