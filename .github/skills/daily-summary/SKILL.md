---
name: daily-summary
description: >
  その日の作業内容を開発日報として整理し、関連ドキュメントを最新化する。
  日報、daily update、進捗報告、status update、ふりかえり、EOD summary、今日のまとめ等の依頼が来たときに使う。
  出力先: docs/daily_reports/YYYY-MM/ ディレクトリ
license: Proprietary
metadata:
  owner: team
  version: "3.0"
---

# Daily Summary Skill

## When to Use

- ユーザーが「今日のまとめ」「日報」「EOD」「進捗共有」「status update」などを求めたとき
- 当日のセッション中の作業を開発日報としてまとめたいとき

## 作業定義（3ステップ）

「今日のまとめ」は以下の **3つのステップ** をすべて実行することを意味する。

### Step 1: 日報を書く

ファイル名: `daily_report_YYYYMMDD.md`
保存先: `docs/daily_reports/YYYY-MM/`

当日のセッションコンテキスト（会話履歴・ツール実行結果・ファイル変更・コミット）を情報源として日報を作成する。テンプレートは後述。

### Step 2: 指示書・仕様書の更新

当日の作業内容を確認し、以下のドキュメントに **反映すべき変更がないか** 判断する。

| 対象ドキュメント           | パス                                      | 更新が必要なケース                       |
| -------------------------- | ----------------------------------------- | ---------------------------------------- |
| プロジェクト共通指示書     | `instructions/00_project_common.md`       | アーキテクチャ変更、共通ルール追加・変更 |
| グループ・リスト・アイテム | `instructions/20_groups_lists_items.md`   | データモデル変更、CRUD操作の仕様変更     |
| ホワイトボード             | `instructions/30_whiteboard.md`           | ホワイトボード機能の仕様変更             |
| QR・通知                   | `instructions/40_qr_and_notifications.md` | 招待フロー変更、通知仕様変更             |
| ユーザー・設定             | `instructions/50_user_and_settings.md`    | ユーザー管理・認証・設定の仕様変更       |
| テスト・CI                 | `instructions/90_testing_and_ci.md`       | テスト戦略変更、CI設定変更               |
| Copilot指示書              | `.github/copilot-instructions.md`         | プロジェクトルール変更、新方針追加       |
| README                     | `README.md`                               | 機能追加・セットアップ手順変更           |

**判断基準**:

- 新しい機能やサービスを追加した → 該当する指示書に記載を追加
- 既存の仕様を変更した → 該当する指示書の記載を更新
- バグ修正で動作仕様が明確になった → 指示書に正しい仕様を明記
- アンチパターンを発見・修正した → 指示書の禁止事項に追加
- 変更が軽微（リファクタリングのみ、コメント追加等）→ **更新不要**

更新不要と判断した場合は、日報に「指示書更新: なし（理由: 〇〇）」と記載する。

### Step 3: コミット＆プッシュ

日報と更新したドキュメントをすべてコミットし、`future` ブランチにプッシュする。

```bash
git add docs/daily_reports/ instructions/ .github/copilot-instructions.md README.md
git commit -m "docs: 日報 YYYY-MM-DD + ドキュメント更新"
git push origin future
```

---

## 日報テンプレート

# 開発日報 - YYYY年MM月DD日

## 📅 本日の目標

- [x] 完了した目標をチェックボックスで示す
- [ ] 未完了の目標もチェックボックスで示す

---

## ✅ 完了した作業

### 1. 作業タイトル ✅

**Purpose**: この作業の目的を1行で

**Background**: 前提情報・経緯（必要に応じて）

**Problem / Root Cause**:

（問題の原因をコードブロック付きで説明）

```dart
// ❌ 問題のあったコード
```

````

**Solution**:

（修正内容をコードブロック付きで説明）

```dart
// ✅ 修正後のコード
```

**検証結果**: テスト結果やログ出力

**Modified Files**:

- `lib/path/to/file.dart` （変更内容の簡潔な説明）

**Commit**: `ハッシュ` （コミット済みの場合）
**Status**: ✅ 完了・検証済み

---

### 2. 次の作業タイトル ✅

（同じ構成で記述）

---

## 🐛 発見された問題

### 問題タイトル（修正済みなら ✅、未修正なら ⚠️）

- **症状**: 何が起きたか
- **原因**: 原因の概要
- **対処**: 修正内容
- **状態**: 修正完了 / 未着手 / 調査中

（問題がなければ「（なし）」）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ バグ名（完了日: YYYY-MM-DD）
2. ✅ バグ名（完了日: YYYY-MM-DD）

### 対応中 🔄

1. 🔄 バグ名（Priority: High/Medium/Low）

### 未着手 ⏳

1. ⏳ バグ名（Priority: High/Medium/Low）

### 翌日継続 ⏳

- ⏳ 継続タスク名

---

## 💡 技術的学習事項

### 学習トピック名

**問題パターン**:

```dart
// 問題のあるコード例
```

**正しいパターン**:

```dart
// 正しいコード例
```

**教訓**: 1〜2文で要約

---

## 🗓 翌日（YYYY-MM-DD）の予定

1. タスク名（優先度順）
2. タスク名

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `instructions/XX_xxx.md` | 変更の要約 |
| （更新なし） | 理由: 〇〇 |

````

## Guidance

### Step 1: 日報作成ルール

- 言語は**日本語**で統一する
- 完了作業は**詳細に**記述する（Background、Root Cause、Solution、Modified Files、Status を含める）
- コードの問題と修正は `❌ Before` / `✅ After` パターンのコードブロックで示す
- テスト結果がある場合はテーブル形式（`| テスト | 結果 |`）で記載する
- **Modified Files** セクションには変更したファイルパスを列挙する
- **Commit** ハッシュがあれば記録する（なければ省略可）
- バグ対応進捗は**累積管理**する（前日から引き継いだ項目も含める）
- 技術的学習事項にはコードブロック付きの具体例を入れる
- 事実と推測を混ぜない。不明点は「不明」と明示する
- 当日のセッション中のコンテキスト（会話内容、ツール実行結果、ファイル変更履歴）を情報源として活用する

### Step 2: 指示書・仕様書の更新ルール

- 更新前に必ず該当ファイルを読んで現在の内容を確認する
- 既存の構成・フォーマットを維持したまま差分だけ追記・修正する
- 大幅な構成変更が必要な場合はユーザーに確認してから実行する
- 更新した場合は日報の「📝 ドキュメント更新」セクションに変更内容を記載する
- 更新不要の場合もその旨と理由を日報に明記する

### Step 3: コミット＆プッシュルール

- 日報ファイル＋更新ドキュメントをまとめて1コミットにする
- コミットメッセージ形式: `docs: 日報 YYYY-MM-DD + ドキュメント更新`（ドキュメント更新がない場合は `docs: 日報 YYYY-MM-DD`）
- `future` ブランチにプッシュする（copilot-instructions.md の Git Push Policy に従う）

## Examples

### Input

「今日の日報作って」

### Output

````markdown
# 開発日報 - 2026年03月05日

## 📅 本日の目標

- [x] リポジトリ層のユニットテスト実施
- [x] 機内モードでのグループ作成バグ修正
- [ ] 総合テストチェックリスト セクション3実施

---

## ✅ 完了した作業

### 1. リポジトリ層ユニットテスト実装 ✅

**Purpose**: HybridSharedGroupRepository / HybridSharedListRepository のユニットテスト追加

**Implementation**:

- DI対応リファクタリング（FirebaseAuth / FirebaseFirestore をコンストラクタ注入）
- Group Repository: 29テスト作成・全パス
- List Repository: 29テスト作成・全パス

**Modified Files**:

- `lib/datastore/hybrid_purchase_group_repository.dart`
- `lib/datastore/hybrid_shared_list_repository.dart`
- `test/unit/datastore/hybrid_purchase_group_repository_test.dart`（新規）
- `test/unit/datastore/hybrid_shared_list_repository_test.dart`（新規）

**Status**: ✅ 完了（58/58テスト成功）

---

### 2. 機内モードでのグループ作成スピナーフリーズ修正 ✅

**Purpose**: 機内モードでグループ作成するとダークオーバーレイとスピナーから戻ってこない問題を修正

**Root Cause**:

- `FirestoreSharedGroupRepository.createGroup()` の `runTransaction()` フォールバックがオフライン時にハング

**Solution**:

- Fix 1: `runTransaction()` フォールバック削除
- Fix 2: Firestore書き込みに10秒タイムアウト + Hiveフォールバック追加
- Fix 3: ユーザー名取得の `.get()` に3秒タイムアウト追加

**Modified Files**:

- `lib/datastore/firestore_purchase_group_repository.dart`
- `lib/datastore/hybrid_purchase_group_repository.dart`
- `lib/providers/purchase_group_provider.dart`

**Status**: ✅ 完了・0エラー・全58テスト成功

---

## 🐛 発見された問題

（なし）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ 機内モードスピナーフリーズ（2026-03-05）
2. ✅ HybridRepo Firestore再初期化バグ（2026-03-04）

### 翌日継続 ⏳

- ⏳ 総合テストチェックリスト セクション3〜12

---

## 💡 技術的学習事項

### Firestore runTransaction() はオフラインで無期限ハングする

**問題パターン**:

```dart
// ❌ runTransaction() はサーバー応答を必須とするため機内モードでハング
await _firestore.runTransaction((transaction) async {
  await transaction.set(docRef, data);
});
```
````

**正しいパターン**:

```dart
// ✅ 通常の .set() はFirestore SDKのオフラインキューに入る
await docRef.set(data);
```

**教訓**: 書き込み操作に `runTransaction()` を使うとオフライン時にハングする。通常の `.set()` / `.update()` はFirestore SDKが自動的にオフラインキューに入れてくれる。

---

## 🗓 翌日（2026-03-06）の予定

1. 総合テストチェックリスト セクション3〜12 実施
2. テスト結果に応じたバグ修正

```

```
