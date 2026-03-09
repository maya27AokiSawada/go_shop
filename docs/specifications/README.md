# GoShopping - Specifications & Reference Documentation

<!-- markdownlint-disable MD060 -->

**最終更新日**: 2026-03-09

このフォルダには、GoShoppingアプリのアーキテクチャリファレンス、機能仕様、法的ドキュメントが含まれています。

---

## 📚 アーキテクチャリファレンス（Architecture Reference）

GoShoppingアプリの全コードベースを6層に分けて体系的に整理したリファレンスドキュメント群です。新規開発者のオンボーディング、UI構成の理解、コンポーネント再利用の判断に活用できます。

### 完成済みリファレンス（Completed）

| #   | ファイル名                                                     | 概要                                                                                                                         | 作成日     |
| --- | -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------- |
| 1   | [data_classes_reference.md](data_classes_reference.md)         | **データモデル層**: 26個のデータクラス、HiveType ID一覧、Firestore連携パターン、差分同期の重要性                             | 2026-02-18 |
| 2   | [widget_classes_reference.md](widget_classes_reference.md)     | **UIコンポーネント層**: 42個のウィジェット、状態管理タイプ別分類、重要な設計パターン                                         | 2026-02-19 |
| 3   | [page_widgets_reference.md](page_widgets_reference.md)         | **画面構成層**: 17個のページウィジェット、BottomNavigationBar 4タブ構成、行数ランキング、設計パターン                        | 2026-02-19 |
| 4   | [service_classes_reference.md](service_classes_reference.md)   | **ビジネスロジック層**: 46個のサービス、66クラス、10カテゴリ、7デザインパターン、最近の実装・修正履歴                        | 2026-02-19 |
| 5   | [provider_classes_reference.md](provider_classes_reference.md) | **状態管理層**: 21ファイル、60+プロバイダー、9種類のRiverpodパターン、10カテゴリ、7アーキテクチャパターン、7使用ガイドライン | 2026-02-19 |

### 未完成リファレンス（Pending）

| #   | ファイル名（予定）              | 概要                                                                                                  | 予定日 |
| --- | ------------------------------- | ----------------------------------------------------------------------------------------------------- | ------ |
| 6   | repository_classes_reference.md | **データアクセス層**: 10-15個のリポジトリ、CRUDパターン、エラーハンドリング、プラットフォーム固有実装 | 未定   |

**アーキテクチャ層の依存関係**:

```text
Pages (17) → Widgets (42) → Providers (60+) → Services (46) → Repositories (10-15est) → Data Models (26)
                              ↑                                   ↓
                              └──────── Riverpod State Management ─────┘
```

---

## 📋 機能仕様ドキュメント（Feature Specifications）

### 現行仕様

| ファイル名                                                           | 概要                                                                                            | 最終更新 |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | -------- |
| [invitation_system.md](invitation_system.md)                         | QR招待システムの仕様（現行の招待方式の基準ドキュメント）                                        | -        |
| [network_failure_handling_flow.md](network_failure_handling_flow.md) | Firestore オフライン永続化を前提にしたネットワーク障害時の処理フロー                            | -        |
| [notification_system.md](notification_system.md)                     | 通知システムの仕様（Firestore `notifications`コレクション、通知タイプ、プラットフォーム別送信） | -        |

---

## 🗃️ 別置きドキュメント（Archived / Shelved）

| ファイル名                                                                                            | 概要                                                                             |
| ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| [development_plan_archive_20260309.md](../daily_reports/2026-03/development_plan_archive_20260309.md) | 2026-02-17 時点の開発計画スナップショット。履歴資料として `daily_reports` に移設 |
| [member_message_feature_shelved.md](../knowledge_base/member_message_feature_shelved.md)              | ホワイトボード機能へ方向転換したため当面棚上げにした伝言メッセージ設計           |

---

## ⚖️ 法的ドキュメント（Legal Documents）

| ファイル名                                 | 概要                                                                               | 言語         | 最終更新 |
| ------------------------------------------ | ---------------------------------------------------------------------------------- | ------------ | -------- |
| [privacy_policy.md](privacy_policy.md)     | プライバシーポリシー（個人情報の取り扱い、Firebase/AdMob利用、位置情報の詳細説明） | 日本語・英語 | -        |
| [terms_of_service.md](terms_of_service.md) | 利用規約（サービス利用条件、有料プラン導入後も広告付き無料プラン継続を明記）       | 日本語・英語 | -        |

---

## 📖 推奨閲覧順序（Recommended Reading Order）

### 新規開発者向け（For New Developers）

1. **アーキテクチャ概要**: [data_classes_reference.md](data_classes_reference.md) → データ構造を理解
2. **UI構成**: [page_widgets_reference.md](page_widgets_reference.md) → 画面全体の構成を把握
3. **状態管理**: [provider_classes_reference.md](provider_classes_reference.md) → Riverpodパターンを学習
4. **ビジネスロジック**: [service_classes_reference.md](service_classes_reference.md) → サービス層を理解
5. **UIコンポーネント**: [widget_classes_reference.md](widget_classes_reference.md) → コンポーネント再利用の判断

### 機能開発者向け（For Feature Developers）

1. **該当機能の仕様**: [invitation_system.md](invitation_system.md) / [notification_system.md](notification_system.md)
2. **プロバイダー**: [provider_classes_reference.md](provider_classes_reference.md) → 状態管理パターン確認
3. **サービス**: [service_classes_reference.md](service_classes_reference.md) → ビジネスロジック実装確認
4. **UIコンポーネント**: [widget_classes_reference.md](widget_classes_reference.md) → 既存ウィジェット確認

### メンテナンス担当者向け（For Maintainers）

1. **最近の実装**: [service_classes_reference.md](service_classes_reference.md) → Recent Implementations セクション
2. **クリティカルパターン**: [provider_classes_reference.md](provider_classes_reference.md) → Usage Guidelines セクション
3. **データ構造**: [data_classes_reference.md](data_classes_reference.md) → HiveType ID一覧、命名規則

---

## 🔗 関連ドキュメント（Related Documentation）

### docs/ ルートディレクトリ

- **[docs/README.md](../README.md)**: ドキュメント全体の目次（daily_reports、knowledge_base、specifications）
- **[docs/daily_reports/](../daily_reports/)**: 日報（2025年10月〜2026年2月、36ファイル、月別整理）
- **[docs/knowledge_base/](../knowledge_base/)**: ナレッジベース（33ファイル、技術Tips、トラブルシューティング）

### プロジェクトルート

- **[README.md](../../README.md)**: プロジェクト概要
- **[SETUP.md](../../SETUP.md)**: セットアップ手順
- **[HISTORY.md](../../HISTORY.md)**: 開発履歴
- **[.github/copilot-instructions.md](../../.github/copilot-instructions.md)**: AI Coding Agent指示書（アーキテクチャサマリー含む）

---

## 📊 ドキュメント統計（Documentation Statistics）

| カテゴリ                       | ファイル数 | 総行数（推定） | 最終更新日 |
| ------------------------------ | ---------- | -------------- | ---------- |
| **アーキテクチャリファレンス** | 5          | 7,950行        | 2026-02-19 |
| **機能仕様**                   | 3          | -              | -          |
| **法的ドキュメント**           | 2          | -              | -          |
| **合計**                       | 10         | -              | -          |

**アーキテクチャリファレンス詳細**:

- data_classes_reference.md: 500行
- widget_classes_reference.md: 650行
- page_widgets_reference.md: 1,100行
- service_classes_reference.md: 1,900行
- provider_classes_reference.md: 3,800行

---

## ✅ メンテナンス履歴（Maintenance History）

| 日付       | 更新内容                                                           |
| ---------- | ------------------------------------------------------------------ |
| 2026-02-19 | インデックスファイル（README.md）作成                              |
| 2026-02-19 | provider_classes_reference.md 作成（60+プロバイダー、3,800行）     |
| 2026-02-19 | service_classes_reference.md 作成（46サービス、66クラス、1,900行） |
| 2026-02-19 | page_widgets_reference.md 作成（17ページ、1,100行）                |
| 2026-02-19 | widget_classes_reference.md 作成（42ウィジェット、650行）          |
| 2026-02-18 | data_classes_reference.md 作成（26クラス、500行）                  |

---

**Note**: このインデックスファイルは定期的に更新されます。新しいドキュメントが追加された場合や、既存ドキュメントに大きな変更があった場合は、このREADME.mdも更新してください。
