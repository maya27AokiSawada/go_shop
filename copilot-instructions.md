# Go Shop - AI Coding Agent Instructions

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

### Git Push ポリシー (2026-07-01以降)

**最重要ルール:**
- **`oneness` ブランチは凍結されました。今後、このブランチへのコミットやプッシュは一切行わないでください。**
- 開発は `main` ブランチ、または `future` プレフィックスを持つブランチ (`future/feature-name` など) で行います。

**通常のワークフロー:**
1. `main` ブランチから新しい `future/` ブランチを作成します。
2. 作業完了後、`main` ブランチにマージします。

# 開発ブランチへのプッシュ
git push origin future/your-feature-name

# mainブランチへのマージ後
git push origin main

---

## Recent Implementations (2026-01-01)

### 1. Windowsデスクトップサポート追加 ✅

**Purpose**: Windows版アプリのビルドを可能にする

**Implementation**:
- `flutter config --enable-windows-desktop` でWindowsデスクトップを有効化
- `flutter create --platforms=windows,android,web,ios,linux .` で全プラットフォームサポートを追加
- ビルドタスクを `.vscode/tasks.json` に追加
  - Build Windows
  - Build Android (APK/Debug APK)
  - Build Web
  - Build All Platforms

**Generated Folders**:
- `windows/` - CMake設定、C++ソースコード
- `linux/` - Linuxデスクトップサポート
- `web/` - Webアプリサポート

### 2. Firebase設定ファイル生成 ✅

**Problem**: `lib/firebase_options.dart` が存在せずビルドエラー

**Solution**:
- FlutterFire CLIで自動生成: `flutterfire configure --project=gotoshop-572b7`
- 全プラットフォーム対応のFirebase App IDを登録

**Registered Platforms**:
- Windows: `1:895658199748:web:6833ceb2b8f29b0518d791`
- Android: `1:895658199748:android:9bc037ca25d380a018d791`
- iOS: `1:895658199748:ios:bfaf69f877e39c6418d791`
- Web: `1:895658199748:web:d24f3552522ea53318d791`

**Generated File**: `lib/firebase_options.dart`

### 3. CMake設定の更新 ✅

**Problem**: Firebase C++ SDK の CMake互換性エラー

**Solution**:
- `windows/CMakeLists.txt` のCMake最小バージョンを `3.14` → `3.15` に更新
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
