# 開発日報 - 2026年04月09日

## 📅 本日の目標

- [x] Firestore セキュリティルールの監査と修正
- [x] プライバシーポリシーを実装と整合させる
- [x] TODOモードのUIテキスト修正（「買い物リスト」ハードコード除去）

---

## ✅ 完了した作業

---

### 1. Firestore セキュリティルール修正・デプロイ ✅

**Purpose**: セキュリティ監査で発見した2つの過剰許可ルールを修正し、本番環境にデプロイ

**Background**: `firestore.rules` のレビュー中に、認証済みユーザーが不必要にアクセスできるコレクションが2つ存在することが判明した。

**Problem / Root Cause**:

```firestore
// ❌ 問題1: レガシー /invitations コレクション（トップレベル）が全認証ユーザに読み書き可能
match /invitations/{invitationId} {
  allow read, write: if request.auth != null;
}

// ❌ 問題2: testingStatus が全認証ユーザに書き込み可能
match /testingStatus/{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;  // 過剰許可
}
```

**Solution**:

```firestore
// ✅ 修正後: /invitations トップレベルをロック（QR招待はサブパス使用のため不要）
match /invitations/{invitationId} {
  allow read, write: if false;
}

// ✅ 修正後: testingStatus 書き込みを無効化
match /testingStatus/{document=**} {
  allow read: if request.auth != null;
  allow write: if false;
}
```

**補足**: QR招待フローは `SharedGroups/{gid}/invitations/{id}` サブパスを使用しているため、トップレベル `/invitations` はレガシー残留でありロックしても機能影響なし。

**Modified Files**:

- `firestore.rules`

**Commit**: `fe60401`（`fix(firestore): lock legacy invitations collection + restrict testingStatus write`）
**Deploy**: `goshopping-48db9`（prod）にデプロイ済み
**Status**: ✅ 完了・本番反映済み

---

### 2. プライバシーポリシーを実装と整合させる ✅

**Purpose**: プライバシーポリシー文書に実装上の事実と比べた乖離があったため是正

**Background**: アプリ内にプライバシーポリシーへのリンクを追加した際（2026-04-08）に通読し、記載漏れ・事実と異なる記述を複数発見。

**Problem**:

| 箇所                | 問題                                     |
| ------------------- | ---------------------------------------- |
| §1.1 アプリ説明     | TODOモードへの言及なし                   |
| §1.2 収集する情報   | リスト情報の説明が買い物に限定されていた |
| §2.1 利用目的       | TODOモード向け言及なし                   |
| §3.1 クラッシュ解析 | Sentry（Windows向け）が未記載            |
| §4.4 データ提供先   | Sentry が未記載                          |

**Solution**:

- アプリ説明を「買い物リスト・TODOリスト共有アプリ」に変更
- §1.2 / §2.1 の「買い物」を「タスク・買い物」等に汎化
- §3.1 に「Sentry（Windows のみ）」を追記
- §4.4 に Sentry を追加
- 最終更新日を 2026年4月9日 に更新

**Modified Files**:

- `docs/specifications/privacy_policy.md`

**Commit**: `e400be0`（`docs(privacy): add TODO mode, Sentry, and fix descriptions to match implementation`）
**Status**: ✅ 完了

---

### 3. TODOモードのUIテキスト修正（8ファイル） ✅

**Purpose**: TODOモード時に「買い物リスト」と表示されてしまうハードコード文字列を、`AppModeSettings.config.sharedList` を使った動的テキストに置き換える

**Background**: アプリはショッピングモードとTODOモードの2モードをサポートしており、モードに応じて「買い物リスト」「タスクリスト」と自動切り替えされる仕組みが `AppModeSettings` として実装済み。しかし、一部のウィジェット・ダイアログ等でハードコードされた「買い物リスト」が残存していた。

**Problem**:

```dart
// ❌ TODOモードでも「買い物リスト」と表示されてしまう
const Text('買い物リストがありません')
const Text('全ての買い物リスト')
```

**Solution**:

```dart
// ✅ モードに応じて動的切替
Text('${AppModeSettings.config.sharedList}がありません')
Text('全ての${AppModeSettings.config.sharedList}')

// ✅ スプラッシュ/ログイン画面（AppModeSettings 未初期化の可能性あり）は中立表現に
const Text('リスト共有アプリ')   // 「買い物リスト共有アプリ」から変更
'家族のリスト'                   // 「家族の買い物リスト」から変更
```

**修正ポリシー**:

| 画面種別                     | 方針                                       | 理由                                      |
| ---------------------------- | ------------------------------------------ | ----------------------------------------- |
| 認証済み・初期化後の画面     | `AppModeSettings.config.sharedList` を使用 | AppModeSettings が確実に初期化済み        |
| スプラッシュ・ログイン前画面 | 「リスト」等の中立表現をハードコード       | Hive 未初期化時にアクセスされる可能性あり |

**注意点**: `const Text(...)` の中で `AppModeSettings.config.*` を使う場合は `const` を外し、`TextStyle` 等に個別に `const` を付ける。

**Modified Files**:

| ファイル                                             | 変更内容                                                                        |
| ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| `lib/widgets/shared_list_header_widget.dart`         | `import` 追加、「買い物リストがありません」「新しい買い物リストを作成」を動的化 |
| `lib/widgets/common_app_bar.dart`                    | `import` 追加、ヘルプ・アバウトダイアログ内テキストを動的化                     |
| `lib/helpers/auth_state_helper.dart`                 | `import` 追加、ウェルカム文・機能紹介テキストを汎化                             |
| `lib/widgets/initial_setup_widget.dart`              | `import` 追加、初期セットアップ説明文を動的化                                   |
| `lib/widgets/hive_initialization_wrapper.dart`       | 「家族の買い物リスト」→「家族のリスト」（中立表現）                             |
| `lib/pages/home_page.dart`                           | `import` 追加、ログイン画面・プライバシー説明・ホーム説明を修正                 |
| `lib/widgets/settings/account_deletion_section.dart` | `import` 追加、削除確認ダイアログ内「全ての買い物リスト」を動的化               |
| `lib/widgets/settings/data_maintenance_section.dart` | `import` 追加、同期メッセージ・Hiveクリア確認ダイアログを動的化                 |

**Commit**: `c60768c`（`fix(ui): make list-related UI text dynamic based on AppMode (TODO/shopping)`）
**Status**: ✅ 完了・`oneness` / `main` にプッシュ済み

---

## 🐛 発見された問題

### 1. `home_page.dart` に未使用 import が残存 ⚠️

- **症状**: `package:hive/hive.dart`、`../models/shared_group.dart`、`../models/shared_list.dart` が未使用と警告
- **原因**: 以前のリファクタリングで使用箇所が削除されたが import が残ったと思われる（元々存在していた）
- **対処**: 今回の作業スコープ外のため対応せず
- **状態**: 未着手（優先度: Low）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Firestore セキュリティルール過剰許可（2026-04-09）
2. ✅ プライバシーポリシー Sentry 未記載（2026-04-09）
3. ✅ TODOモード時の「買い物リスト」ハードコード表示（2026-04-09）

### 未着手 ⏳

1. ⏳ `home_page.dart` 未使用 import 3件（Priority: Low）

---

## 💡 技術的学習事項

### AppModeSettings を使う際の `const` 制約

**問題パターン**:

```dart
// ❌ コンパイルエラー: const 内で動的値は使えない
const Text('${AppModeSettings.config.sharedList}がありません')
```

**正しいパターン**:

```dart
// ✅ Text から const を外し、内部の style 等に const を付ける
Text(
  '${AppModeSettings.config.sharedList}がありません',
  style: const TextStyle(fontSize: 14),
)

// ✅ Row の子に動的 Text がある場合、Row 自体も const を外す
Row(
  children: [
    const Icon(Icons.check),
    Text('${AppModeSettings.config.sharedList}作成'),
  ],
)
```

**教訓**: `const` は全ウィジェットツリーが定数であることを要求する。動的値を1つでも含む場合、そのウィジェットおよび親ウィジェットの `const` を外す必要がある。

---

### スプラッシュ/ログイン前画面での AppModeSettings の扱い

**問題パターン**:

- Hive 未初期化状態で `AppModeSettings.config` を呼ぶとクラッシュの可能性

**正しいパターン**:

```dart
// ✅ Hive 初期化前の画面（スプラッシュ、ログイン）→ 中立テキストをリテラルで記述
const Text('リスト共有アプリ')       // × '買い物リスト共有アプリ'
Text('家族のリスト')                  // × '家族の買い物リスト'

// ✅ 認証済み・Hive 初期化後の画面 → 動的テキストを使用
Text('${AppModeSettings.config.sharedList}がありません')
```

**教訓**: 初期化ライフサイクルを意識し、Hive 初期化完了まで `AppModeSettings.config` を使わないようにする。スプラッシュ・ログイン画面は必ず中立表現にする。

---

## 🗓 翌日（2026-04-10）の予定

1. `home_page.dart` 未使用 import の整理（優先度: Low）
2. TODOモード UI の通しテスト（実機確認）

---

## 📝 ドキュメント更新

| ドキュメント                            | 更新内容                                                                                                                                   |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `docs/specifications/privacy_policy.md` | Sentry 追記・TODOモード追記・更新日修正（作業2として実施）                                                                                 |
| `instructions/` その他                  | 更新なし（理由: Firestore ルール修正はセキュリティ設定でアーキテクチャ変更なし。UIテキスト修正はリファクタリングに相当し既存仕様変更なし） |
