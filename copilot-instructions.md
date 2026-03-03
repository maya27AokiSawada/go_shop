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

## 🖼️ UI Overflow Prevention & Responsive Layout（2026-02-28追加）

### Critical Rule 1: Column/Row Overflow Prevention

**問題**: 固定サイズのUI要素がデバイスの画面サイズを超えるとRenderFlex overflowエラーが発生

**AS10L事例** (2026-02-28発見):

- デバイス: Amazon Kindle Fire HD 10.1 (1024x600, 10.1インチ)
- エラー: `A RenderFlex overflowed by 122 pixels on the bottom`
- 原因: 固定280x280pxのスキャンエリア + カメラプレビュー + ツールバー = 画面高600pxを超過

**Before (Overflow発生)**:

```dart
// ❌ 固定サイズで overflow
body: Stack(
  children: [
    // Camera preview (full height)
    // ...
    Center(
      child: Container(
        width: 280,   // ← 固定サイズ
        height: 280,  // ← 固定サイズ
        decoration: BoxDecoration(border: ...),
      ),
    ),
  ],
)
```

**After (Responsive)**:

```dart
// ✅ SafeArea + MediaQuery で responsive化
final screenSize = MediaQuery.of(context).size;
final scanAreaSize = (screenSize.width * 0.7).clamp(200.0, 300.0);

body: SafeArea(  // ← システムUI（ノッチ、ステータスバー）を避ける
  child: Stack(
    children: [
      // Camera preview
      Center(
        child: Container(
          width: scanAreaSize,   // ← 動的サイズ
          height: scanAreaSize,  // ← 動的サイズ
          decoration: BoxDecoration(border: ...),
        ),
      ),
    ],
  ),
)
```

### Critical Rule 2: Always Use SafeArea for Full-Screen UIs

**SafeAreaの重要性**:

- デバイスノッチ（切り欠き）を避ける
- ステータスバーの高さを考慮
- ナビゲーションバーの高さを考慮
- システムジェスチャーエリアを避ける

**必須パターン**:

```dart
// ✅ Scaffold + SafeArea
Scaffold(
  body: SafeArea(  // ← 必須
    child: YourContent(),
  ),
)

// ❌ SafeAreaなし（ノッチに重なる可能性）
Scaffold(
  body: YourContent(),
)
```

### Critical Rule 3: SingleChildScrollView + mainAxisSize.min

**ColumnがScrollableな場合の必須パターン**:

```dart
// ✅ 正しい: SingleChildScrollView + mainAxisSize.min
SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,  // ← 重要: 必要最小サイズ
    children: [
      Widget1(),
      Widget2(),
      Widget3(),
    ],
  ),
)

// ❌ 間違い: mainAxisSize.max（デフォルト）
SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.max,  // ← overflow発生
    children: [...],
  ),
)
```

**理由**:

- `mainAxisSize.max`: Columnが親の高さ全体を占有しようとする → ScrollViewと競合
- `mainAxisSize.min`: Columnが子要素の高さ合計のみを使用 → ScrollViewと共存

### Critical Rule 4: MediaQueryによる動的サイズ算出

**推奨パターン**:

```dart
// ✅ 画面サイズに応じた動的サイズ
final screenWidth = MediaQuery.of(context).size.width;
final screenHeight = MediaQuery.of(context).size.height;

// 画面幅の70%、ただし200-300pxの範囲内
final scanAreaSize = (screenWidth * 0.7).clamp(200.0, 300.0);

// 画面高さの50%、ただし最小400px
final contentHeight = (screenHeight * 0.5).clamp(400.0, screenHeight);
```

**Clampの使い方**:

```dart
// clamp(min, max): 値をmin～maxの範囲内に制限
(screenWidth * 0.7).clamp(200.0, 300.0)
// 例:
// - screenWidth = 320 → 224.0 → 224.0（200-300の範囲内）
// - screenWidth = 240 → 168.0 → 200.0（最小値200）
// - screenWidth = 500 → 350.0 → 300.0（最大値300）
```

### Critical Rule 5: Empty State Testing

**必須テスト項目**:

- ✅ 空のリスト（グループ0件、リスト0件、アイテム0件）
- ✅ 低解像度デバイス（600px以下の高さ）
- ✅ 小型デバイス（物理サイズ7～10インチ）
- ✅ 縦向き・横向き両方

**推奨テストデバイス**:
| デバイスタイプ | 解像度例 | 物理サイズ | 優先度 |
| -------------- | -------------- | ---------- | ------ |
| スマホ（小） | 720x1280 | 5-6インチ | 高 |
| タブレット（小）| 1024x600 | 7-10インチ | **最高** |
| スマホ（大） | 1080x2400 | 6-7インチ | 中 |
| タブレット（大）| 1920x1200 | 10-12インチ| 低 |

**AS10L教訓**: 10.1インチでも解像度が1024x600と低いため、固定サイズUIは危険

### Critical Rule 6: 物理サイズ ≠ 論理ピクセル密度

**重要な理解**:

```dart
// ❌ Wrong: 物理サイズで判断
if (deviceInches >= 10) {
  // 大きな画面と判断 → 間違い
}

// ✅ Correct: 論理ピクセル（MediaQuery）で判断
final screenHeight = MediaQuery.of(context).size.height;
if (screenHeight >= 800) {
  // 十分な高さと判断
}
```

**AS10L vs Pixel 9 比較**:
| デバイス | 物理サイズ | 解像度 | 論理高さ | 判定 |
| ---------- | ---------- | ----------- | -------- | ---- |
| AS10L | 10.1インチ | 1024x600 | ~600dp | ❌ 小 |
| Pixel 9 | 6.24インチ | 1080x2424 | ~900dp | ✅ 大 |

**結論**: 物理サイズではなく、MediaQueryの論理ピクセルで判断すること

---

## 🐛 Debugging with Crashlytics Breadcrumbs（2026-02-28追加）

### Critical Rule 1: Breadcrumbs First Approach

**問題発生時の調査順序**:

1. ✅ **Crashlyticsのbreadcrumbs確認**（最優先）
2. ✅ クラッシュログのスタックトレース分析
3. ✅ Widget treeの`debugCreator`から呼び出し元特定
4. ✅ ソースコードの該当箇所確認

**AS10L事例の突破口**:

```
Crashlytics Breadcrumbs:
[UI]    group_list_widget.dart:133  // ← 空状態UI分岐
[UI]    accept_invitation_widget.dart:350  // ← QRスキャナー表示
💡 この2つのログから「空状態のQRスキャン」が問題と判明
```

### Critical Rule 2: 効果的なBreadcrumb配置

**推奨配置箇所**:

```dart
// ✅ Widget buildメソッドの分岐点
@override
Widget build(BuildContext context) {
  FirebaseCrashlytics.instance.log('[UI] group_list_widget.dart:${lineNumber}');

  if (groups.isEmpty) {
    FirebaseCrashlytics.instance.log('[UI] Empty state: showing InitialSetupWidget');
    return const InitialSetupWidget();
  }

  return ListView.builder(...);
}

// ✅ 重要なユーザーアクション
void _onButtonPressed() {
  FirebaseCrashlytics.instance.log('[ACTION] Button pressed: $buttonName');
  performAction();
}

// ✅ 状態遷移
setState(() {
  FirebaseCrashlytics.instance.log('[STATE] Changing from $oldState to $newState');
  state = newState;
});
```

### Critical Rule 3: Widget Tree Analysis from debugCreator

**Widget treeの読み方**:

```
A RenderFlex overflowed by 122 pixels on the bottom.
The overflowing RenderFlex has an orientation of Axis.vertical.

🔍 debugCreatorパターン解析:
Column ← SingleChildScrollView ← ... ← AcceptInvitationWidget
                                    ← InitialSetupWidget
                                    ← GroupListWidget@1f3e5

💡 結論: GroupListWidget → InitialSetupWidget → AcceptInvitationWidget
        の順で呼び出し → AcceptInvitationWidget内のColumnでoverflow
```

**Widget tree解析テクニック**:

1. エラーメッセージの`debugCreator`セクションを探す
2. Widget名の階層を逆順に追う（下から上へ）
3. 各Widgetのソースファイルを確認
4. 呼び出しチェーンを再構築

### Critical Rule 4: Root Cause Chain Analysis

**単一原因ではなく連鎖を探す**:

AS10L事例の連鎖:

```
1️⃣ 招待QRスキャン完了
   ↓
2️⃣ グループ追加（0 → 1）
   ↓
3️⃣ GroupListWidgetが再ビルド
   ↓
4️⃣ groups.isEmpty == false → ListView表示
   ↓
5️⃣ しかしQRスキャナーダイアログはまだ表示中（dismissされていない）
   ↓
6️⃣ 両方のUIが重なり、合計高さが画面高を超過
   ↓
🚨 RenderFlex overflow発生
```

**デバッグ時の思考プロセス**:

- ❌ "なぜColumnがoverflowした？" → 直接原因のみ
- ✅ "なぜこのタイミングでこのWidgetが表示された？" → 根本原因の連鎖

### Critical Rule 5: Device-Specific Testing Priority

**優先度付きテスト戦略**:

1. **最優先**: 低解像度タブレット（AS10L等、600px台）
2. **高優先**: 小型スマホ（720x1280等）
3. **通常優先**: 標準スマホ（1080x2400等）
4. **低優先**: 高解像度タブレット（1920x1200等）

**理由**: 低解像度デバイスは市場シェアは低いが、UIの限界を最も早く露呈する

---

## 🐛 デバッグ教訓: NetworkMonitorService修正 (2026-03-03)

### 複数バグの連鎖発見プロセス

**状況**: オフライン処理実装後の実機テストで「グループ作成成功後もバナー消えない」＋「リトライボタン効かない」

**調査手法**:

1. **詳細ログ追加**: 実行フローを可視化

   ```dart
   AppLogger.info('🔍 [NETWORK_MONITOR] 初回接続チェック開始');
   AppLogger.info('🔄 [NETWORK_MONITOR] オフライン検出 → 自動リトライ開始');
   ```

2. **ログ分析**: 「何が実行されていないか」に注目
   - コンストラクタは呼ばれているが、`checkFirestoreConnection()`のログがない → **Bug #1発見**
   - `_updateStatus()`は呼ばれているが、`startAutoRetry()`のログがない → **Bug #2発見**
   - `checkFirestoreConnection()`でpermission-deniedエラー → **Bug #3発見**

3. **根本原因特定**: コードを読み解く
   - Bug #1: コンストラクタで`checkFirestoreConnection()`を呼び出していない
   - Bug #2: `_updateStatus()`で`startAutoRetry()`を呼び出していない
   - Bug #3: `SharedGroups.limit(1)`クエリがメンバーシップチェック必須だが認証前に実行

**教訓**:

- ✅ 実行されていないメソッドに注目（ログがないことでバグを特定）
- ✅ 独立した3つのバグが同時に存在する可能性を考慮
- ✅ 段階的修正（1つずつ修正・検証）

### 構文エラーの連鎖と影響

**Syntax Error #1 - 重複括弧（Line 108）**:

```dart
// 修正作業中に`}`を重複入力
      }
      }  // ❌ 重複 → try-catch構造破壊
```

**影響**:

- "Type 'on' not found"エラー
- 15+のエラー連鎖（catch句、TimeoutException、FirebaseExceptionすべてが未定義扱い）

**教訓**:

- ✅ 複雑構造（try-catch、if-else、switch）編集時は括弧対応を慎重に確認
- ✅ 1つの構文エラーが複数のエラーメッセージを生成する
- ✅ エラーメッセージの「最初の1つ」に注目（根本原因はそこにある）

**Syntax Error #2 - Final修飾子（Line 48）**:

```dart
// 状態フィールドに`final`宣言
final NetworkStatus _currentStatus = NetworkStatus.online;  // ❌

// ↓ これが呼ばれると...
_currentStatus = newStatus;  // Error: setter未定義
```

**影響**:

- 全ネットワーク状態遷移がブロック
- `online` → `offline`の遷移が不可能
- 全機能が停止

**教訓**:

- ✅ `final`は「初期化後に変更不可」を意味する
- ✅ Mutableな状態フィールドには`final`を使用しない
- ✅ 設計時点で状態管理パターンを明確化

### ベストプラクティス

#### 1. ログファースト開発

問題発生時は「推測」ではなく「ログ」で実行フローを可視化：

```dart
// ❌ 推測: 「たぶんこのメソッドが呼ばれているはず」
void someMethod() {
  doSomething();
}

// ✅ ログ: 「実際に呼ばれているか確認」
void someMethod() {
  AppLogger.info('🔍 [DEBUG] someMethod開始');
  doSomething();
  AppLogger.info('✅ [DEBUG] someMethod完了');
}
```

#### 2. 段階的修正戦略

複数バグを同時修正せず、1つずつ修正・検証：

```
❌ 一括修正: Bug #1,#2,#3を同時修正 → どれが効果あったか不明

✅ 段階的修正:
   1. Bug #1修正 → テスト → ログ確認 → 効果確認
   2. Bug #2修正 → テスト → ログ確認 → 効果確認
   3. Bug #3修正 → テスト → ログ確認 → 効果確認
```

#### 3. 構文チェック原則

編集後は必ずコンパイル確認（ホットリロード不可）：

```bash
# 編集後すぐに実行
flutter analyze

# または
dart analyze
```

#### 4. 括弧対応確認

複雑構造の編集時は括弧マッチングをチェック：

```dart
try {
  if (condition) {
    doSomething();
  }
}  // ← この'}'がtryのものか、ifのものか確認
catch (e) {
  // ...
}
```

**エディタのサポート機能活用**:

- VS Code: 括弧上にカーソル → 対応する括弧がハイライト
- VS Code: `Ctrl+Shift+[` で対応する括弧にジャンプ

#### 5. 修飾子の理解

`final`/`const`は用途を理解して使用：

```dart
// ✅ 定数: finalまたはconst
final String apiEndpoint = 'https://api.example.com';

// ✅ 初期化後変更なし: final
final TextEditingController controller = TextEditingController();

// ❌ 状態フィールド: finalは不可
final NetworkStatus _currentStatus = NetworkStatus.online;  // NG
NetworkStatus _currentStatus = NetworkStatus.online;  // OK
```

### Permission設計パターン

**問題**: SharedGroupsクエリでpermission-denied発生（認証済みでも）

**原因**: Firestoreルールでメンバーシップチェック必須だが、認証チェック前にクエリ実行

**解決**: 認証状態に応じたクエリ先選択

```dart
// ✅ 認証状態別クエリパターン
if (currentUser != null) {
  // 認証済み: 自分のドキュメント（オーナー常に読取可）
  await Firestore.doc('users/${currentUser.uid}').get();
} else {
  // 未認証: 公開コレクション（誰でも読取可）
  await Firestore.collection('furestorenews').limit(1).get();
}
```

**教訓**:

- ✅ 接続チェック用のクエリは認証状態に関わらず実行可能なものを選択
- ✅ 認証済みユーザーは自分のドキュメントをクエリ（permission確実）
- ✅ 未認証は公開コレクションをクエリ（誰でも読取可）

### 実機テストの重要性

**教訓**: Windows開発環境ではエラーが発生せず、Android実機で初めて発覚

**理由**:

- Windows版はFirestore制限が緩い可能性
- 実機はネットワーク環境が異なる
- 実機は認証状態が異なる

**ベストプラクティス**:

- ✅ オフライン処理実装後は必ず実機テスト
- ✅ 機内モードでのテスト
- ✅ Wi-Fi/モバイル通信の切り替えテスト
- ✅ 異なるOSバージョンでのテスト

---

**最終更新**: 2026-03-03
**Important**: このファイルはAI支援開発のガイドラインです。すべての開発者が従うべき規則を定義しています。
