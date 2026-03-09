# Docs フォルダ構造

このフォルダには Go Shop プロジェクトのドキュメントが格納されています。

## フォルダ構成

```text
docs/
├── daily_reports/          # 日報（月別整理）
│   ├── 2025-10/           # 2025年10月の日報
│   ├── 2025-11/           # 2025年11月の日報
│   ├── 2025-12/           # 2025年12月の日報
│   └── 2026-01/           # 2026年1月の日報
├── knowledge_base/         # ナレッジベース（技術文書・ガイド）
└── specifications/         # プロジェクト仕様・設計書
```

## 各フォルダの役割

### 📅 daily_reports/

開発日報を月別に整理しています。

**命名規則**: `daily_report_YYYYMMDD.md`

**例**: `daily_report_20251225.md` → `2025-12/daily_report_20251225.md`

### 📚 knowledge_base/

技術的なナレッジ、トラブルシューティングガイド、実装レポートなどを格納しています。

**主な内容**:

- ビルド・デプロイガイド
- 認証フローの解析
- エラー修正ガイド
- Firebase/Firestore関連ドキュメント
- リファクタリング計画
- テストチェックリスト
- ユーザーガイド

日付付きの実装レポート、単発のデバッグ結果、テスト実行ログは `daily_reports/` に寄せています。

**例**:

- `github_actions_ci_cd.md` - CI/CD設定ガイド
- `riverpod_best_practices.md` - Riverpodベストプラクティス
- `firestore_architecture.md` - Firestoreアーキテクチャ
- `authentication_flow_analysis.md` - 認証フロー解析
- `knowledge_base/README.md` - ナレッジベース索引

### 📚 knowledge_base 内の整理ルール

- 現在も参照するガイド、アーキテクチャ説明、運用メモを置く
- 実施日が明確なレポート、引継ぎ、単発テスト記録は `daily_reports/` に移す
- 棚上げ設計は `knowledge_base/` に残してよいが、現行仕様としては扱わない

## knowledge_base 索引

- [knowledge_base/README.md](knowledge_base/README.md)

### 📋 specifications/

プロジェクトの仕様書、設計書、機能定義などを格納しています。

**主な内容**:

- 機能仕様（招待システム、通知システムなど）
- アーキテクチャリファレンス
- 法的ドキュメント

**例**:

- `invitation_system.md` - 招待システム仕様
- `network_failure_handling_flow.md` - ネットワーク障害時フロー
- `notification_system.md` - 通知システム仕様
- `provider_classes_reference.md` - Providerリファレンス

履歴化した開発計画は `daily_reports/`、当面棚上げの設計メモは `knowledge_base/` に移しています。

## ドキュメント追加ガイドライン

### 日報を追加する場合

```text
# 該当月のフォルダに追加
docs/daily_reports/YYYY-MM/daily_report_YYYYMMDD.md
```

### ナレッジベースを追加する場合

技術的な内容、ガイド、トラブルシューティング、実装レポートなど：

```text
docs/knowledge_base/your_document_name.md
```

### 仕様書を追加する場合

機能仕様、設計書、開発計画など：

```text
docs/specifications/your_specification_name.md
```

## 整理履歴

- **2026-01-06**: docsフォルダを3つのカテゴリに整理
  - 日報を月別フォルダに分類
  - ナレッジベースとプロジェクト仕様を分離
  - 計75+ファイルを分類・移動
