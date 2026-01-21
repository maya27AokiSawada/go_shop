# GoShopping - AI Coding Agent Instructions

## Recent Implementations (2026-01-20)

### 1. UI/UX改善とサインイン必須仕様への最適化 ✅

**Purpose**: ユーザビリティ向上と認証必須アプリとしての最適化

**Key Changes**:

#### ホワイトボードUI改善

- **ツールバーコンパクト化**: 縦幅を約40%削減
  - パディング: `all(8)` → `symmetric(horizontal: 8, vertical: 4)`
  - 段間スペース: 8 → 4
  - 色ボタン: 36×36 → 32×32
  - IconButton: `padding: EdgeInsets.zero` + `size: 20`
- **色プリセット削減**: 8色 → 6色（teal、brownを削除）
- **横向き対応**: 十分なスペースがある場合は全アイコンを表示

#### 認証フロー最適化

- **未認証時の無駄な処理を削除**:
  - `createDefaultGroup()`に未認証チェック追加
  - `user == null`の場合は早期リターン
  - Firestore接続試行、Hive初期化待機を回避
- **アプリバー表示改善**:
  - 未認証時: 「未サインイン」と表示
  - 認証済み時: 「○○ さん」と表示

#### ホーム画面改善

- **アプリ名統一**: 「Go Shop」 → 「GoShopping」
- **パスワードリセット復活**: サインイン画面にリンク追加

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` (ツールバーコンパクト化)
- `lib/pages/settings_page.dart` (プロバイダーimport追加)
- `lib/providers/purchase_group_provider.dart` (未認証チェック)
- `lib/pages/home_page.dart` (タイトル変更、パスワードリセット)
- `lib/widgets/common_app_bar.dart` (認証状態表示)

**Pattern**:

```dart
// ✅ 未認証チェックパターン
Future<void> createDefaultGroup(User? user) async {
  if (user == null) {
    Log.info('⚠️ 未認証状態のためデフォルトグループ作成をスキップ');
    return;
  }
  // 以降の処理...
}

// ✅ アプリバー表示パターン
Future<String> _buildTitle(user) async {
  if (showUserName) {
    if (user == null) {
      return '未サインイン';
    }
    final userName = await UserPreferencesService.getUserName();
    return userName != null ? '$userName さん' : 'ホーム';
  }
  // ...
}
```

---

## Recent Implementations (2026-01-16)

### 1. 手書きホワイトボード機能完全実装（future ブランチ） ✅

**Purpose**: 差別化機能として、グループ共有・個人用ホワイトボードを実装

**Implementation Architecture**:

- **Package**: `signature: ^5.5.0` - 描画 UI
- **Drawing Engine**: SignatureController + CustomPaint レイヤーシステム
- **Storage**: Hybrid approach（カスタムモデル + Firestore JSON）
- **Sync**: Firestore `whiteboards` collection
- **Hive TypeID**: 15-17（DrawingStroke, DrawingPoint, Whiteboard）

**Key Features**:

- ✅ スクロール可能キャンバス（1x ～ 4x）
- ✅ スクロールロック機能（描画モード ⇄ スクロールモード切替）
- ✅ 複数色対応（8 色カラーピッカー）
- ✅ 線幅調整（1.0 ～ 10.0）
- ✅ グループ共有ホワイトボード
- ✅ 個人用ホワイトボード
- ✅ 閲覧専用モード（他メンバーのホワイトボード）
- ✅ ホワイトボード更新通知システム

**Key Files**:

#### Data Models

- `lib/models/whiteboard.dart` - 3 つの Freezed モデル（DrawingStroke, DrawingPoint, Whiteboard）
- `lib/models/shared_group.dart` - グループ階層フィールド追加（parentGroupId, childGroupIds, memberPermissions）
- `lib/models/permission.dart` - 8 ビット権限システム

#### Repository & Provider

- `lib/datastore/whiteboard_repository.dart` - Firestore CRUD
- `lib/providers/whiteboard_provider.dart` - StreamProvider でリアルタイム更新

#### UI Components

- `lib/pages/whiteboard_editor_page.dart` - フルスクリーンエディター（スクロール可能、レイヤーシステム）
- `lib/widgets/whiteboard_preview_widget.dart` - プレビュー表示
- `lib/widgets/member_tile_with_whiteboard.dart` - メンバータイル＋個人ホワイトボードアクセス

**Commits**: `2bae86a`, `d6fe034`, `de72177`, `1825466`, `e26559f`

---

### 2. ホワイトボード更新通知システム実装 ✅

**Purpose**: ホワイトボード保存時にグループメンバーへ自動通知

**Implementation**:

- `lib/services/notification_service.dart`: `NotificationType.whiteboardUpdated` 追加
- `sendWhiteboardUpdateNotification()`: バッチ通知送信
- `_handleWhiteboardUpdated()`: 通知受信ハンドラー
- `lib/pages/whiteboard_editor_page.dart`: 保存時に通知送信

**Commit**: `de72177`

---

### 3. テストドキュメント作成 ✅

**Purpose**: クローズドテスト準備

**Created Files**:

- `docs/knowledge_base/test_procedures_v2.md` - 29 テストプロシージャ
- `docs/knowledge_base/test_checklist_template.md` - 41 項目チェックリスト

**Commit**: `1825466`

---

### 4. サインアップ時のユーザー名保存タイミング修正 ✅

**Problem**: ディスプレイ名入力後、メールアドレスの前半が使われる

**Root Cause**: Firebase Auth 登録時に`authStateChanges`発火 →`createDefaultGroup()`実行 →Preferences 未保存

**Solution**:

- Firebase Auth 登録**前**に Preferences へユーザー名を保存
- 保存順序: Preferences クリア → ユーザー名事前保存 → Hive クリア → Auth 登録

**Modified Files**:

- `lib/pages/home_page.dart` - 保存タイミング移動
- `lib/services/firestore_user_name_service.dart` - デバッグログ強化

**Commit**: `e26559f`

---

## Recent Implementations (2026-01-01)

### 1. Windows デスクトップサポート追加 ✅

**Purpose**: Windows 版アプリのビルドを可能にする

**Implementation**:

- `flutter config --enable-windows-desktop` で Windows デスクトップを有効化
- `flutter create --platforms=windows,android,web,ios,linux .` で全プラットフォームサポートを追加
- ビルドタスクを `.vscode/tasks.json` に追加
  - Build Windows
  - Build Android (APK/Debug APK)
  - Build Web
  - Build All Platforms

**Generated Folders**:

- `windows/` - CMake 設定、C++ソースコード
- `linux/` - Linux デスクトップサポート
- `web/` - Web アプリサポート

### 2. Firebase 設定ファイル生成 ✅

**Problem**: `lib/firebase_options.dart` が存在せずビルドエラー

**Solution**:

- FlutterFire CLI で自動生成: `flutterfire configure --project=gotoshop-572b7`
- 全プラットフォーム対応の Firebase App ID を登録

**Registered Platforms**:

- Windows: `1:895658199748:web:6833ceb2b8f29b0518d791`
- Android: `1:895658199748:android:9bc037ca25d380a018d791`
- iOS: `1:895658199748:ios:bfaf69f877e39c6418d791`
- Web: `1:895658199748:web:d24f3552522ea53318d791`

**Generated File**: `lib/firebase_options.dart`

### 3. CMake 設定の更新 ✅

**Problem**: Firebase C++ SDK の CMake 互換性エラー

**Solution**:

- `windows/CMakeLists.txt` の CMake 最小バージョンを `3.14` → `3.15` に更新
- `CMAKE_POLICY_VERSION_MINIMUM` を `3.15` に設定

### 4. リスト作成の二重送信防止 ✅

**Problem**: リスト作成ボタンの複数回タップで重複作成される可能性

**Implementation** (`lib/widgets/shopping_list_header_widget.dart`):

- `StatefulBuilder` でダイアログの状態管理
- `isSubmitting` フラグで処理中を制御
- 処理中はボタン無効化＋ローディングスピナー表示
- バリデーションエラー時は `isSubmitting` をリセット

**Pattern**:

```dart
bool isSubmitting = false;

StatefulBuilder(
  builder: (context, setDialogState) => AlertDialog(
    actions: [
      ElevatedButton(
        onPressed: isSubmitting ? null : () async {
          if (isSubmitting) return;
          setDialogState(() { isSubmitting = true; });

          try {
            // 処理
            await repository.createSharedList(...);
          } catch (e) {
            setDialogState(() { isSubmitting = false; });
          }
        },
        child: isSubmitting
            ? CircularProgressIndicator(strokeWidth: 2)
            : Text('作成'),
      ),
    ],
  ),
)
```

**Note**: グループ作成（`group_creation_with_copy_dialog.dart`）は既に `_isLoading` で二重送信防止済み

---

## 🚀 Quick Start for AI Agents (January 2026)

**Naming Conventions**:

- Use `sharedGroup`, `sharedList`, and `sharedItem` for models and related components.
- The refactoring from `shoppingList` and `shoppingItem` is mostly complete. Ensure new code follows the `shared` naming convention.

**Hive TypeIDs**:

- 0: SharedGroupRole
- 1: SharedGroupMember
- 2: SharedGroup
- 3: SharedItem
- 4: SharedList
- 6: UserSettings

**Architecture**:

- The app uses a hybrid repository pattern (Hive for local cache, Firestore for remote).
- Data is read from Hive first (cache-first), then synced from Firestore.
- UI-related logic should be in the `pages` and `widgets` directories.
- Business logic is managed by Riverpod `Notifier` classes in the `providers` directory.
- Data access is handled by repositories in the `datastore` directory.
