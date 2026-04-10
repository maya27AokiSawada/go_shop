# 開発日報 - 2026年04月10日

## 📅 本日の目標

- [x] `home_page.dart` 未使用 import の整理（引き継ぎより）
- [x] `use_build_context_synchronously` lint 警告を修正
- [x] デバッグスクリプトの整理（`deprecated/` へ移動）
- [x] Firebase Cloud Functions: Firestore 自動バックアップ機能実装
- [x] ToDoモード UI の表示切り替え修正（タスク/買い物の表示を動的に変更）
- [x] `firebase_auth` バージョンアップ（Windowsビルドエラー修正）
- [ ] TODOモード UI の通しテスト（実機確認）

---

## ✅ 完了した作業

---

### 1. lint 警告修正① — 非推奨 API・unused_import・avoid_print 等 ✅

**Purpose**: `flutter analyze` で検出されたさまざまなカテゴリの lint 警告を一括修正

**Background**: 前日（2026-04-09）の作業後に `future` ブランチへ lint 修正コミットがあったことを引き継ぎ確認。`origin/oneness` に未反映の状態だった。

**Problem / Root Cause**:

```dart
// ❌ 非推奨API
color.withOpacity(0.5)           // → withValues(alpha:)
onPopInvoked                     // → onPopInvokedWithResult
color.value                      // → toARGB32()
@deprecated                      // → @Deprecated('message')

// ❌ 警告
import 'package:hive/hive.dart'; // unused_import
print('...')                     // avoid_print
```

**Solution**:

```dart
// ✅ 修正後
color.withValues(alpha: 0.5)
onPopInvokedWithResult
color.toARGB32()
@Deprecated('message')
// unused import を削除
AppLogger.info('...')  // print の代替
```

**Modified Files**:

- `lib/datastore/hybrid_shared_group_repository.dart`
- `lib/datastore/shared_list_repository.dart`
- `lib/pages/home_page.dart`（未使用 import 3件削除）
- `lib/pages/notification_history_page.dart`
- `lib/pages/whiteboard_editor_page.dart`
- `lib/services/qr_invitation_service.dart`
- `lib/utils/drawing_converter.dart`
- `lib/widgets/app_initialize_widget.dart`
- `lib/widgets/network_status_banner.dart`

**Commit**: `351356e`（`fix: lint警告修正（非推奨API・unused_import・avoid_print等）`）
**Status**: ✅ 完了

---

### 2. lint 警告修正② — use_build_context_synchronously ✅

**Purpose**: `await` をまたいで `BuildContext` を使用する箇所に `context.mounted` チェックを追加し、`use_build_context_synchronously` 警告を解消

**Background**: 前のコミット（`351356e`）で各種 lint を修正したが、`use_build_context_synchronously` 系の警告が未コミット状態で残っていた。セッション開始時に作業中変更（7ファイル）を発見してコミット・プッシュ。

**Problem / Root Cause**:

```dart
// ❌ await 後に BuildContext を使用（mounted チェックなし、または isMounted コールバック）
await someAsyncOperation();
UiHelper.showErrorMessage(context, 'エラー');  // コンテキストが無効の可能性

// ❌ 古い isMounted コールバックパターン
if (isMounted != null && isMounted!()) {
  UiHelper.showSuccessMessage(context, '成功');
}
```

**Solution**:

```dart
// ✅ await 後に context.mounted チェックを挿入
await someAsyncOperation();
if (!context.mounted) return;
UiHelper.showErrorMessage(context, 'エラー');

// ✅ isMounted パターン → context.mounted に統一
if (context.mounted) {
  UiHelper.showSuccessMessage(context, '成功');
}
```

**対応箇所**:

| ファイル                                       | 変更内容                                                       |
| ---------------------------------------------- | -------------------------------------------------------------- |
| `lib/providers/auth_provider.dart`             | await後のUI操作前に `context.mounted` チェック追加（16箇所）   |
| `lib/providers/home_page_auth_service.dart`    | `isMounted!()` → `context.mounted` に統一（6箇所）             |
| `lib/providers/home_page_auth_service_v2.dart` | await後に `context.mounted` チェック追加                       |
| `lib/pages/home_page.dart`                     | `mounted` → `context.mounted` 統一、エラーハンドラのネスト整理 |
| `lib/pages/group_member_management_page.dart`  | ScaffoldMessenger 前に `mounted` チェック追加（3箇所）         |
| `lib/helpers/dev_utils_helper.dart`            | await後に `context.mounted` チェック追加（2箇所）              |
| `lib/helpers/user_id_change_helper.dart`       | `context.mounted` チェック追加（1箇所）                        |

**Commit**: `4ea4b0d`（`fix(lint): use_build_context_synchronously 警告を修正`）
**Push**: `origin/future` + `origin/oneness` へ反映済み
**Status**: ✅ 完了

---

### 3. デバッグスクリプト整理 ✅

**Purpose**: ルートに散在していたデバッグ用 Dart スクリプトを `deprecated/` フォルダへ移動し、`analysis_options.yaml` から除外

**Background**: `debug_*.dart` などのデバッグ専用スクリプトがプロジェクトルートに残存しており、`flutter analyze` の対象になっていた。

**Solution**:

- `debug_android_groups.dart` 等 12ファイルを `deprecated/` へ移動
- `analysis_options.yaml` に `exclude: [deprecated/**]` を追加

**Modified Files**:

- `deprecated/` （12ファイル移動先）
- `analysis_options.yaml`

**Commits**: `58daab1`, `cd02773`
**Status**: ✅ 完了

---

### 4. Firebase Cloud Functions: Firestore 自動バックアップ機能実装 ✅

**Purpose**: 毎日 JST 00:00 に Firestore データを GCS へ自動バックアップする Cloud Functions 実装

**Background**: データ消失リスクへの対策として、スケジュール実行によるバックアップと、管理者・ユーザー向けリストア関数を追加。

**Implementation**:

| 関数名                     | 種別                       | 内容                                                                                                            |
| -------------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `scheduledFirestoreBackup` | Scheduled (毎日 00:00 JST) | SharedGroups / SharedLists / items / whiteboards / notifications を GCS へ JSON スナップショット保存。5日分保持 |
| `listBackups`              | Callable                   | バックアップ一覧取得                                                                                            |
| `restoreUserData`          | Callable                   | `ownerUid` 指定でユーザーのグループをリストア                                                                   |
| `restoreAllData`           | Callable                   | 全データリストア（管理者シークレット保護）                                                                      |

**Modified Files**:

- `functions/index.js`（新規）
- `functions/package.json`（新規）
- `functions/package-lock.json`（新規）
- `functions/.gitignore`（新規）
- `firebase.json`（functions 設定追加）

**Commit**: `cd444a9`
**Push**: `origin/future` + `origin/oneness` へ反映済み
**Status**: ✅ 完了（デプロイは別途必要）

---

### 5. ToDoモード UI 表示切り替え修正 ✅

**Purpose**: ToDoモード時にリスト画面・編集モーダルの文言やアイコンをタスク向けに切り替え

**Background**: ToDoモードでも「買い物アイテムを追加」「買い物アイテムがありません」等、買い物向けのテキストがそのまま表示されていた。

**Problem / Root Cause**:

```dart
// ❌ 常に買い物向けテキストを使用
return const _SharedListPlaceholder(
  icon: Icons.add_shopping_cart,
  message: '買い物アイテムがありません',
);

// ❌ モーダルも同様
Text(isEditMode ? 'アイテムを編集' : '買い物アイテムを追加')
```

**Solution**:

```dart
// ✅ listType で分岐（まず実装）→ appModeNotifierProvider で判定に修正
final isTodo = ref.watch(appModeNotifierProvider) == AppMode.todo;

return _SharedListPlaceholder(
  icon: isTodo ? Icons.checklist : Icons.add_shopping_cart,
  message: isTodo ? 'タスクがありません' : '買い物アイテムがありません',
);

// モーダルタイトルも動的に
isTodo ? (isEditMode ? 'タスクを編集' : 'タスクを追加')
       : (isEditMode ? 'アイテムを編集' : '買い物アイテムを追加')
```

**Note**: 最初は `currentListProvider?.listType == ListType.todo` で実装したが、より正確な `appModeNotifierProvider` を使う方式に修正。

**Modified Files**:

- `lib/pages/shared_list_page.dart`
- `lib/widgets/shared_item_edit_modal.dart`

**Commits**: `2921332`, `e5dacda`
**Status**: ✅ 実装完了（実機通しテストは翌日）

---

### 6. firebase_auth バージョンアップ（Windows ビルドエラー修正）✅

**Purpose**: `firebase_auth ^6.1.0` → `^6.3.0` にアップグレードして Windows ビルドエラーを解消

**Background**: `flutter build apk --release --flavor prod` を試みた際に Windows ビルド側でも依存関係エラーが発生。`firebase_auth 6.3.0` で修正済みだったため更新。

**Solution**:

```yaml
# ❌ Before
firebase_auth: ^6.1.0

# ✅ After
firebase_auth: ^6.3.0
```

**Modified Files**:

- `pubspec.yaml`

**Commit**: `9244266`
**Status**: ✅ 完了

---

## 🐛 発見された問題

### リリースビルド失敗 ⚠️

- **症状**: `flutter build apk --release --flavor prod` が exit code 1 で失敗
- **原因**: 調査中（`firebase_auth` アップグレード後も継続するか未確認）
- **状態**: 未解決・翌日調査予定

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Firestore セキュリティルール過剰許可（2026-04-09）
2. ✅ プライバシーポリシー Sentry 未記載（2026-04-09）
3. ✅ TODOモード時の「買い物リスト」ハードコード表示（2026-04-09）
4. ✅ lint 警告: 非推奨API・unused_import・avoid_print（2026-04-10 commit `351356e`）
5. ✅ lint 警告: use_build_context_synchronously（2026-04-10 commit `4ea4b0d`）
6. ✅ ToDoモード UI テキスト/アイコン切り替え漏れ（2026-04-10 commits `2921332`, `e5dacda`）

### 対応中 🔄

1. 🔄 リリースAPK ビルドエラー（Priority: High）

### 翌日継続 ⏳

- ⏳ TODOモード UI 通しテスト（実機確認）
- ⏳ Firebase Functions デプロイ
- ⏳ リリースAPK ビルドエラー原因調査

**問題パターン**:

```dart
// ❌ 古いパターン（StatefulWidget でなく、コールバックを外部から渡す）
final bool Function()? isMounted;
if (isMounted != null && isMounted!()) {
  UiHelper.showSuccessMessage(context, '成功');
}
```

**正しいパターン**:

```dart
// ✅ Flutter 3.7+ では context.mounted を使う
if (context.mounted) {
  UiHelper.showSuccessMessage(context, '成功');
}

// ✅ StatefulWidget の State 内では mounted または context.mounted どちらでもよいが統一する
if (!context.mounted) return;
ScaffoldMessenger.of(context).showSnackBar(...);
```

**教訓**: `isMounted` コールバックパターンは古い Flutter コードで見られる。`BuildContext.mounted` プロパティが導入されてからは不要になった。発見したら積極的にリファクタリングする。

---

### `use_build_context_synchronously` の修正ポリシー

- `await` が含まれる `async` メソッドで、await 完了後に `context` を使う箇所すべてに `if (!context.mounted) return;` を追加する
- `catch` ブロックの中でも `await` があれば同様に必要
- エラーログ（`ErrorLogService.logOperationError`）はコンテキスト不要なので、mounted チェックより前に実行してよい

---

## 🗓 翌日（2026-04-11）の予定

1. リリースAPK ビルドエラー原因調査・修正（Priority: High）
2. TODOモード UI の通しテスト（実機確認）
3. Firebase Functions デプロイ（`firebase deploy --only functions`）

---

## 📝 ドキュメント更新

| ドキュメント           | 更新内容                                                                               |
| ---------------------- | -------------------------------------------------------------------------------------- |
| `instructions/` その他 | 更新なし（理由: lint 修正・UI テキスト修正・バックアップ関数は仕様書レベルの変更なし） |
