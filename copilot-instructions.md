# GitHub Copilot 開発ガイドライン

このファイルは、GitHub Copilotが開発を支援する際に従うべきルールとベストプラクティスを定義します。

---

## 🚨 機密情報の取り扱い（最重要）

### Commit/Push前の必須チェックリスト

**すべてのcommit/push操作の前に、以下の機密情報が含まれていないことを確認してください：**

#### 1. APIキーと認証情報

- ❌ Firebase API Keys（`AIzaSy...`で始まる文字列）
- ❌ Google Cloud API Keys
- ❌ Sentry DSN（公開可能だが、コメントで明示すること）
- ❌ その他のサードパーティAPIキー

#### 2. 認証・パスワード

- ❌ Gmail appパスワード（`extensions/firestore-send-email.env`）
- ❌ データベースパスワード
- ❌ 秘密鍵やトークン
- ❌ OAuth Client Secrets

#### 3. プラットフォーム固有の設定ファイル

- ❌ `lib/firebase_options_goshopping.dart` - Firebase設定
- ❌ `extensions/firestore-send-email.env` - Gmailパスワード
- ❌ `ios/Runner/GoogleService-Info.plist` - iOS Firebase設定
- ❌ `android/app/google-services.json` - Android Firebase設定
- ❌ `android/key.properties` - Android署名鍵情報

#### 4. 証明書と鍵ファイル

- ❌ `*.jks` - Androidキーストア
- ❌ `*.keystore` - Androidキーストア
- ❌ `*.p12` - iOS証明書
- ❌ `*.mobileprovision` - iOSプロビジョニングプロファイル

### Commit前の確認コマンド

```bash
# Commit対象ファイルを確認
git status

# 差分を詳細確認（機密情報が含まれていないか目視チェック）
git diff --cached

# 特定の機密文字列を検索
git diff --cached | grep -i "AIzaSy"
git diff --cached | grep -i "password"
git diff --cached | grep -i "secret"
git diff --cached | grep -i "token"
```

### .gitignoreの必須設定

以下のパターンが`.gitignore`に含まれていることを確認：

```gitignore
# 機密情報
*.env
!*.env.template
lib/firebase_options_goshopping.dart
extensions/firestore-send-email.env

# iOS機密ファイル
ios/Runner/GoogleService-Info.plist
ios_backup/GoogleService-Info.plist
*.mobileprovision
*.p12

# Android機密ファイル
android/app/google-services.json
android/key.properties
*.jks
*.keystore

# その他
*.jar
local.properties
```

### テンプレートファイルの使用

機密情報を含むファイルは、テンプレートファイル（`.template`）を作成してコミット：

```bash
# 悪い例
git add ios/Runner/GoogleService-Info.plist

# 良い例
git add ios/Runner/GoogleService-Info.plist.template
```

---

## 📋 コーディング規約

### Flutter/Dartのベストプラクティス

1. **Null Safety**: 常にnull safetyを意識したコードを書く
2. **Immutable**: 可能な限り`final`、`const`を使用
3. **依存性注入**: Riverpodを使用したDI設計
4. **型安全性**: `dynamic`の使用を最小限に

### コミットメッセージ規約

```
<type>(<scope>): <subject>

例:
feat(auth): ログイン機能を実装
fix(whiteboard): 描画の同期エラーを修正
docs(security): セキュリティガイドラインを更新
refactor(ui): ホーム画面のレイアウトを改善
```

**Type**:

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント更新のみ
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルド・補助ツール更新
- `security`: セキュリティ関連

---

## 🔒 セキュリティベストプラクティス

### 1. API Keyの制限

Firebase/Google Cloud API Keyには必ず制限を設定：

- Androidアプリ制限: パッケージ名 + SHA-1証明書フィンガープリント
- iOSアプリ制限: Bundle ID
- HTTPリファラ制限: 許可ドメインのみ

### 2. 環境変数の使用

```dart
// 悪い例
const apiKey = "AIzaSyCOrH6NiWn6nUhpdgnZ328hQ9Yel-ECFf4";

// 良い例（環境変数から読み込み）
final apiKey = const String.fromEnvironment('FIREBASE_API_KEY');
```

### 3. 機密情報の分離

開発環境と本番環境で異なる設定ファイルを使用：

- `firebase_options_dev.dart`（.gitignore対象外でもOK - dev用）
- `firebase_options_goshopping.dart`（.gitignore必須 - 本番用）

---

## 🧪 テスト方針

### 必須テスト

1. **Unit Test**: すべてのビジネスロジック
2. **Integration Test**: 主要なユーザーフロー
3. **Widget Test**: 重要なUI コンポーネント

### テスト実行

```bash
# 全テスト実行
flutter test

# 特定のテスト実行
flutter test test/services/auth_service_test.dart
```

---

## 📦 依存関係管理

### パッケージ更新

```bash
# 依存関係の更新確認
flutter pub outdated

# 更新実行
flutter pub upgrade

# pubspec.lockをコミット
git add pubspec.lock
```

---

## 🚀 デプロイ前チェックリスト

- [ ] すべてのテストが通過
- [ ] 機密情報が含まれていないことを確認
- [ ] API Key制限が設定済み
- [ ] セキュリティドキュメントを更新
- [ ] CHANGELOGを更新

---

## 📚 参考ドキュメント

- [セキュリティガイドライン](docs/SECURITY_ACTION_REQUIRED.md)
- [プロジェクト構造](README.md)
- [Flutter公式ドキュメント](https://flutter.dev/docs)
- [Firebase Security](https://firebase.google.com/docs/projects/api-keys)

---

**最終更新**: 2026-02-17
**Important**: このファイルはAI支援開発のガイドラインです。すべての開発者が従うべき規則を定義しています。
