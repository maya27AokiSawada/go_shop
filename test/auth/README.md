# 認証フローテスト

## 概要

このディレクトリには、Firebase Authenticationを使用したサインアップ・サインイン・サインアウトフローのユニットテストが含まれています。

## テストファイル構成

### 1. auth_flow_test.dart (20テスト)

認証フローの基本的な動作をテストします。

**テスト項目:**

- サインアップフロー (5テスト)
  - 正常系: メールアドレスとパスワードでアカウント作成
  - 異常系: 既に登録済みのメールアドレス (email-already-in-use)
  - 異常系: 弱いパスワード (weak-password)
  - 異常系: 不正なメールアドレス (invalid-email)
  - ユーザー名設定→Firebase Auth displayName更新

- サインインフロー (6テスト)
  - 正常系: メールアドレスとパスワードでサインイン
  - 異常系: ユーザーが見つからない (user-not-found)
  - 異常系: パスワードが間違っている (wrong-password)
  - 異常系: アカウントが無効 (user-disabled)
  - 異常系: 無効な認証情報 (invalid-credential)
  - UID変更検出フロー

- サインアウトフロー (2テスト)
  - 正常系: サインアウト処理
  - currentUserがnullになる

- パスワードリセットフロー (2テスト)
  - 正常系: パスワードリセットメール送信
  - 異常系: ユーザーが見つからない (user-not-found)

- 認証状態管理 (3テスト)
  - currentUser - ログイン前はnull
  - currentUser - ログイン後はUserオブジェクト
  - authStateChanges - ログイン状態の変化を検知

- 統合シナリオ (2テスト)
  - サインアップ→サインアウト→サインイン
  - 複数アカウント切り替え（UID変更検出）

### 2. auth_service_test.dart (18テスト)

認証サービス層の機能を詳細にテストします。

**テスト項目:**

- サインイン処理 (4テスト)
  - サインイン成功 - Userオブジェクトが返される
  - サインイン失敗 - FirebaseAuthExceptionをスロー
  - 空のメールアドレス
  - 空のパスワード

- サインアップ処理 (4テスト)
  - サインアップ成功 - 新規Userオブジェクトが作成される
  - メールアドレス既に使用中 (email-already-in-use)
  - 弱いパスワード (weak-password)
  - 不正なメールアドレス形式 (invalid-email)

- サインアウト処理 (2テスト)
  - サインアウト成功
  - サインアウト後 - currentUserがnullになる

- 認証状態 (2テスト)
  - 未ログイン状態 - currentUserはnull
  - ログイン状態 - currentUserはUserオブジェクト

- エラーハンドリング (4テスト)
  - ネットワークエラー (network-request-failed)
  - タイムアウトエラー (too-many-requests)
  - アカウント無効エラー (user-disabled)
  - 不明なエラー (operation-not-allowed)

- パフォーマンス (2テスト)
  - サインイン - レスポンスタイム < 5秒
  - 連続サインイン処理 - 3回連続でエラーなし

### 3. auth_integration_test.dart (9テスト)

認証フロー全体の統合テストです。

**テスト項目:**

- サインアップ完全フロー (2テスト)
  - 正常系（Auth登録→displayName設定→reload）
  - displayName設定失敗時もAuth登録は成功

- サインイン→サインアウトフロー (2テスト)
  - 正常系
  - すでにログアウト状態でもエラーなし

- マルチユーザー切り替えフロー (1テスト)
  - ユーザーA→サインアウト→ユーザーBサインイン

- エラーリカバリーフロー (2テスト)
  - サインイン失敗→リトライ成功
  - ネットワークエラー→リトライ成功

- 連続操作フロー (2テスト)
  - サインアップ→即座にサインアウト→サインイン
  - 複数回サインイン/サインアウト繰り返し

## テスト実行方法

### 全テストを実行

```bash
flutter test test/auth/
```

### 個別ファイルを実行

```bash
# 基本フローテスト
flutter test test/auth/auth_flow_test.dart

# サービス層テスト
flutter test test/auth/auth_service_test.dart

# 統合フローテスト
flutter test test/auth/auth_integration_test.dart
```

### モックファイル生成

テスト実行前に、モックファイルを生成する必要があります：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## テスト結果（2026-01-21実行）

### 実行結果サマリー

```
✅ 全47テスト成功

auth_flow_test.dart:      20テスト ✅
auth_service_test.dart:   18テスト ✅
auth_integration_test.dart: 9テスト ✅
```

### カバレッジ内容

- ✅ Firebase Auth基本操作（サインアップ・サインイン・サインアウト）
- ✅ エラーハンドリング（全主要エラーコード）
- ✅ UID変更検出フロー
- ✅ パスワードリセット
- ✅ 認証状態管理（authStateChanges）
- ✅ マルチユーザー切り替え
- ✅ エラーリカバリー
- ✅ パフォーマンステスト

## 技術詳細

### 使用パッケージ

- `flutter_test`: Flutterテストフレームワーク
- `mockito ^5.4.4`: Firebase Authモック生成
- `firebase_auth`: Firebase Authentication SDK

### モックオブジェクト

- `MockFirebaseAuth`: FirebaseAuthのモック
- `MockUser`: Userのモック
- `MockUserCredential`: UserCredentialのモック

### テストパターン

1. **Arrange**: テストデータとモックの準備
2. **Act**: テスト対象の実行
3. **Assert**: 結果の検証

```dart
test('サインイン - 正常系', () async {
  // Arrange
  when(mockAuth.signInWithEmailAndPassword(...))
      .thenAnswer((_) async => mockCredential);

  // Act
  final result = await authService.signIn(email, password);

  // Assert
  expect(result, isNotNull);
  expect(result?.uid, 'test-uid');
});
```

## トラブルシューティング

### モック生成エラー

```
Error: Method not found: 'StreamController'
```

→ `import 'dart:async';` を追加してください

### テスト実行エラー

```
Failed to load test file
```

→ `flutter pub run build_runner build --delete-conflicting-outputs` を実行してください

### Firebase Auth例外コード

テストで使用している主なエラーコード:

- `email-already-in-use`: メールアドレス既に使用中
- `weak-password`: パスワードが弱すぎる
- `invalid-email`: メールアドレス形式が不正
- `user-not-found`: ユーザーが見つからない
- `wrong-password`: パスワードが間違っている
- `invalid-credential`: 認証情報が無効
- `user-disabled`: ユーザーアカウントが無効
- `network-request-failed`: ネットワークエラー
- `too-many-requests`: リクエスト過多
- `operation-not-allowed`: 操作が許可されていない

## 今後の拡張予定

- [ ] 電話番号認証テスト
- [ ] ソーシャルログインテスト（Google, Apple, etc.）
- [ ] メール確認フローテスト
- [ ] セッション管理テスト
- [ ] マルチファクタ認証テスト
