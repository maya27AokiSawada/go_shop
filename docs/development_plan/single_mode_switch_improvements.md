# シングルモード切り替え改善計画

**作成日**: 2026-05-02
**状態**: 📋 計画中
**目的**: マルチ→シングルモード切り替え時の UX 問題を修正する

---

## 📋 現状分析・課題

### 課題 1: シングルモード切り替え後にアイテム追加できない

**発生条件**: マルチモードからシングルモードに切り替えた直後、カレントリストが未選択の状態。

**現象**:
`shared_list_page.dart` の FAB タップ時に `currentListProvider` が `null` の場合、`texts.selectList` のエラースナックバーを表示して終了する。シングルモードではリスト選択 UI が簡略化されているため、ユーザーがリストを選択する手段がなく詰まる。

**該当コード**: `lib/pages/shared_list_page.dart`

```dart
final currentList = ref.read(currentListProvider);
if (currentList == null) {
  SnackBarHelper.showError(context, texts.selectList);
  return;  // ← シングルモードではここで詰まる
}
```

---

### 課題 2: カレントグループ未選択時の処理が不明確

**発生条件**: 何らかの理由でカレントグループ（`selectedGroupIdProvider`）が未選択の状態でシングルモードに入る。

**現象**:
`_SharedItemsListWidget` では `currentList == null || selectedGroupId == null` の場合はプレースホルダーを表示するが、その状態から復帰する手段がシングルモードでは提供されていない。

---

### 課題 3: モード切り替え時の前提条件チェックがない

**発生条件**: マルチ→シングルに切り替えようとしたとき、カレントグループまたはカレントリストが未選択。

**現象**:
`app_ui_mode_switcher_panel.dart` の `_onToggle` では確認ダイアログのみ出して切り替えを実行してしまう。切り替え後に上記の課題 1・2 の状態に陥る。

**該当コード**: `lib/widgets/settings/app_ui_mode_switcher_panel.dart`

```dart
// Multi → Single：確認ダイアログ（カレントグループ・リストのチェックなし）
final confirmed = await showDialog<bool>(...);
if (confirmed != true) return;
await _saveMode(ref, AppUIMode.single);  // ← 前提チェックなしで切り替え
```

---

## 🎯 解決方針

### 方針 A: シングルモード切り替え時の前提条件チェック（課題 3 → 1・2 を予防）

**場所**: `lib/widgets/settings/app_ui_mode_switcher_panel.dart` の `_onToggle`

**処理フロー（改修後）**:

```
Multi → Single 切り替えボタンタップ
  ↓
カレントグループ（selectedGroupIdProvider）が null?
  → Yes: エラーダイアログ「カレントグループを選択してから切り替えてください」→ 切り替えキャンセル
  ↓
カレントリスト（currentListProvider）が null?
  → Yes: エラーダイアログ「カレントリストを選択してから切り替えてください」→ 切り替えキャンセル
  ↓
確認ダイアログ（既存）
  ↓
_saveMode(AppUIMode.single) 実行
```

**UI**: `showDialog` でエラーを表示し、ユーザーに「OK」ボタンで閉じてもらう（押し戻し）。

---

### 方針 B: シングルモードでのカレントリスト自動作成（課題 1 のフォールバック対策）

万が一シングルモードでカレントリストが null になった場合（例：データ移行時、初回ログイン時など）に、FAB タップ時に自動でデフォルトリストを作成してからアイテム追加ダイアログを開く。

**場所**: `lib/pages/shared_list_page.dart` の FAB onPressed

**処理フロー（改修後）**:

```dart
onPressed: () async {
  final isSingle = ref.read(appUIModeProvider) == AppUIMode.single;
  var currentList = ref.read(currentListProvider);

  if (currentList == null && isSingle) {
    // シングルモードのみ：デフォルトリストを自動作成
    currentList = await _createDefaultList(context, ref);
    if (currentList == null) return; // 作成失敗
  } else if (currentList == null) {
    SnackBarHelper.showError(context, texts.selectList);
    return;
  }

  _showAddItemDialog(context, ref);
}
```

**自動作成するリスト**:

- リスト名: "買い物リスト"（日本語）/ "Shopping List"（英語）
- リストタイプ: `ListType.shopping`

---

## 📁 修正対象ファイル

| ファイル                                               | 修正内容                                                       |
| ------------------------------------------------------ | -------------------------------------------------------------- |
| `lib/widgets/settings/app_ui_mode_switcher_panel.dart` | 切り替え前にカレントグループ・リストの未選択チェックを追加     |
| `lib/pages/shared_list_page.dart`                      | シングルモード時のカレントリスト null → 自動作成フォールバック |

---

## 🚀 実装優先度・順序

1. **方針 A（切り替え前チェック）** — 根本的な予防策。先に実装する。
2. **方針 B（自動作成フォールバック）** — 防衛的実装。A の後に追加する。

---

## 📝 補足・注意事項

- 方針 A のエラーメッセージは l10n キーを追加する（`noCurrentGroupSelectBeforeSwitch`、`noCurrentListSelectBeforeSwitch` など）。
- 方針 B の自動作成は Firestore + Hive の両方に保存する必要がある（`groupSharedListsProvider` の既存ロジックを再利用すること）。
- カレントグループが選択されていない場合は、方針 B の自動リスト作成も不可能なため、エラーメッセージとともにグループ選択を促す画面遷移も検討する。
- シングルモード中のカレントグループ未選択は `shared_group_page.dart`（`isSingle` 分岐）にも関係するため、合わせて動作確認が必要。
