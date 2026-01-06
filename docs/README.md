# Docs フォルダ構造

このフォルダには Go Shop プロジェクトのドキュメントが格納されています。

## フォルダ構成

```
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

**例**:
- `github_actions_ci_cd.md` - CI/CD設定ガイド
- `riverpod_best_practices.md` - Riverpodベストプラクティス
- `firestore_architecture.md` - Firestoreアーキテクチャ
- `authentication_flow_analysis.md` - 認証フロー解析

### 📋 specifications/

プロジェクトの仕様書、設計書、機能定義などを格納しています。

**主な内容**:
- 開発計画
- 機能仕様（招待システム、通知システムなど）
- Providerの仕様
- メンバーメッセージ機能の設計

**例**:
- `development_plan.md` - 開発計画
- `invitation_system.md` - 招待システム仕様
- `notification_system.md` - 通知システム仕様
- `providers_specification.md` - Provider仕様

## ドキュメント追加ガイドライン

### 日報を追加する場合

```bash
# 該当月のフォルダに追加
docs/daily_reports/YYYY-MM/daily_report_YYYYMMDD.md
```

### ナレッジベースを追加する場合

技術的な内容、ガイド、トラブルシューティング、実装レポートなど：

```bash
docs/knowledge_base/your_document_name.md
```

### 仕様書を追加する場合

機能仕様、設計書、開発計画など：

```bash
docs/specifications/your_specification_name.md
```

## 整理履歴

- **2026-01-06**: docsフォルダを3つのカテゴリに整理
  - 日報を月別フォルダに分類
  - ナレッジベースとプロジェクト仕様を分離
  - 計75+ファイルを分類・移動
