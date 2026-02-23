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

## 🎯 Widget Lifecycle Management（2026-02-23追加）

### Critical Rule 1: Widget Disposal後のcontext/ref操作

**問題**: Widget破棄後に`context`や`ref`を使用すると、アプリクラッシュや赤画面エラーが発生

```dart
// ❌ 間違ったパターン
try {
  await performAsyncOperation();

  if (context.mounted) {
    ref.invalidate(someProvider);  // ❌ widget破棄後は失敗
  }
} catch (e) {
  // エラーハンドリング
}
```

**理由**:

- `context.mounted`は**親Navigatorのマウント状態**をチェック
- **現在のwidgetが破棄されているかどうかは判定できない**
- Widget破棄後は`ref.invalidate()`, `ref.read()`, `setState()`などの操作が全て失敗

**正しいパターン**:

```dart
// ✅ 正しいパターン: 非同期操作完了後は何もしない
try {
  await performAsyncOperation();

  // Widget破棄の可能性がある場合：
  // - SnackBar: 表示しない（widget破棄済み）
  // - Navigator.pop: 実行しない（widget自動置換）
  // - ref.invalidate: 実行しない（ref操作不可）
  // - UI更新: Providerの監視で自動実行される

  Log.info('✅ 操作完了 - UI自動更新');
} catch (e) {
  // エラー時はwidgetがまだ存在している
  if (context.mounted) {
    SnackBarHelper.showError(context, 'エラー: $e');
  }
}
```

### Critical Rule 2: 0→1 Transition Widget Replacement

**InitialSetupWidgetの特異な動作**:

- `allGroupsProvider`がグループカウント0→1を検出すると、**自動的にwidget置換が発生**
- `app_initialize_widget.dart`が`InitialSetupWidget` → `GroupListWidget`に切り替え
- **非同期処理の最中にwidget破棄が発生**

**タイムライン例**:

```
0ms:   User taps "グループを作成"
10ms:  _createNewGroup() 呼び出し
20ms:  createNewGroup() が Firestore書き込み
30ms:  await allGroupsProvider.future 完了
35ms:  🔥 allGroupsProvider が groupCount: 0 → 1 を検出
40ms:  🔥 app_initialize_widget が InitialSetupWidget を GroupListWidget に置換
45ms:  🔥 InitialSetupWidget.dispose() 呼び出し
50ms:  ❌ context.mounted チェックをパス（親 Navigator は存在）
55ms:  ❌ SnackBar 表示（成功するが widget は既に破棄済み）
60ms:  ❌ ref.invalidate() 呼び出し
       🚨 Error: "Cannot use ref after widget was disposed"
```

**解決策**:

```dart
// lib/widgets/initial_setup_widget.dart (正しい実装)
try {
  // Step 1: 操作実行と同期完了を待機
  await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
  await ref.read(allGroupsProvider.future);

  Log.info('✅ グループ作成成功 - Firestore同期完了');

  // Step 2: 何もしない！
  // - Widget は自動的に破棄される
  // - UI は allGroupsProvider の監視で自動更新
  // - 手動の UI 操作は全て不要（かつ危険）

  Log.info('🎉 初回グループ作成完了 - GroupListWidgetへ自動切替');

} catch (e) {
  // エラー時のみ widget が存在している
  if (context.mounted) {
    SnackBarHelper.showError(context, 'グループ作成に失敗しました');
  }
}
```

### Critical Rule 3: AsyncNotifierProvider Await Pattern

**必須パターン**:

```dart
// ✅ 正しい: Provider更新完了を待機してから UI 操作
await ref.read(dataProvider.notifier).performOperation();
await ref.read(dataProvider.future);  // ← 重要: Provider更新完了を待機
// これで UI 操作が安全（widget が存在する場合）
```

**理由**:

- 最初の`await`: 操作完了（Firestore書き込み等）
- 2番目の`await`: Provider更新（データが consumer に配信される）
- 2番目の`await`がないと、UIが古いデータを表示

**間違った例**:

```dart
// ❌ 間違い: Provider更新を待たずに UI 操作
await ref.read(dataProvider.notifier).performOperation();
// await ref.read(dataProvider.future);  ← 欠落
ref.invalidate(dataProvider);  // 古いデータのまま無効化
```

### Critical Rule 4: SnackBar/Navigator Ordering

**原則**: `ref.invalidate()`の**前に** context依存の操作を実行

```dart
// ✅ 正しい順序
await operation();
await ref.read(provider.future);

if (context.mounted) {
  SnackBarHelper.showSuccess(context, 'Success!');  // ← 先に実行
}

ref.invalidate(provider);  // ← その後に無効化

if (context.mounted) {
  Navigator.of(context).pop();  // ← 最後にダイアログ閉じる
}
```

**間違った例**:

```dart
// ❌ 間違い: ref.invalidate後に context 操作
await operation();
ref.invalidate(provider);  // ← 先に無効化

if (context.mounted) {
  SnackBarHelper.showSuccess(context, 'Success!');  // ❌ エラー発生
}
```

**理由**: `ref.invalidate()`後に`context`操作を行うと、`_dependents.isEmpty`アサーションエラーが発生

### Widget Lifecycle Comparison

| Widget Type                   | Group Transition | Widget After Operation | Safe to use context/ref? |
| ----------------------------- | ---------------- | ---------------------- | ------------------------ |
| **SharedGroupPage**           | N → N+1          | ✅ Widget persists     | ✅ Yes                   |
| **InitialSetupWidget**        | 0 → 1            | ❌ Widget destroyed    | ❌ No                    |
| **GroupMemberManagementPage** | N → N            | ✅ Widget persists     | ✅ Yes                   |

**Key Difference**:

- 通常のWidget: 操作後もwidgetが存在 → context/ref操作可能
- InitialSetupWidget: 操作後にwidget破棄 → context/ref操作不可

### 実装チェックリスト

**非同期操作を含むwidgetメソッドを実装する際は、以下を確認：**

- [ ] `await ref.read(provider.notifier).operation()`で操作完了を待機
- [ ] `await ref.read(provider.future)`でProvider更新を待機
- [ ] SnackBar表示は`ref.invalidate()`の**前**に実行
- [ ] Widget破棄の可能性がある場合、context/ref操作を全て削除
- [ ] エラーハンドリングで`context.mounted`チェックを使用
- [ ] ログ出力で動作タイミングを追跡可能に

### デバッグテクニック

**効果的なログ配置**:

```dart
// ✅ 重要な操作の前後にログ
Log.info('📝 操作開始: $operationName');
await performOperation();
Log.info('✅ 操作成功');

// ✅ Widget破棄が予想される箇所
Log.info('💡 Widget破棄予定ポイント - 以降の処理はスキップされる可能性');

// ✅ エラー発生時の詳細
Log.error('❌ 操作失敗: $e');
Log.error('📍 スタックトレース: $stackTrace');
```

**Clean Buildの限界**:

```bash
# ❌ これらはWidget lifecycleの問題を解決しない
flutter clean
flutter pub get
flutter run

# ✅ Widget lifecycle問題はコード変更が必要
# - Build cacheの問題ではない
# - ランタイム動作の問題である
```

---

**最終更新**: 2026-02-23
**Important**: このファイルはAI支援開発のガイドラインです。すべての開発者が従うべき規則を定義しています。
