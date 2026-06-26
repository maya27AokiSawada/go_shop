# GoShopping - Specifications & Reference Documentation

<!-- markdownlint-disable MD060 -->

**最終更新日**: 2026-06-26

このフォルダには、GoShoppingアプリのアーキテクチャリファレンス、機能仕様、法的ドキュメントが含まれています。

---

## 📚 アーキテクチャリファレンス（Architecture Reference）

GoShoppingアプリの構成を層ごとに整理したリファレンス群です。オンボーディング、既存実装の把握、改修時の影響範囲確認に使用します。

| ファイル名                                                     | 概要                                                                                     | 最終更新（ファイル） |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | -------------------- |
| [data_classes_reference.md](data_classes_reference.md)         | データモデル、HiveType ID、シリアライズ仕様、永続化ルール                                | 2026-04-14           |
| [widget_classes_reference.md](widget_classes_reference.md)     | UIコンポーネント一覧、責務分離、再利用方針                                               | 2026-04-14           |
| [page_widgets_reference.md](page_widgets_reference.md)         | ページ構成、画面遷移、主要ページの責務                                                   | 2026-05-09           |
| [service_classes_reference.md](service_classes_reference.md)   | サービス層の責務、ユースケース別ロジック、依存関係                                       | 2026-04-14           |
| [provider_classes_reference.md](provider_classes_reference.md) | Riverpod Provider構成、状態遷移、invalidate運用パターン                                  | 2026-04-14           |
| [porting_spec_kotlin_swift.md](porting_spec_kotlin_swift.md)   | Kotlin / Swift 移植時の設計要件、データ構造対応、オフライン/同期要件、禁止アンチパターン | 2026-06-23           |

**アーキテクチャ層の依存関係（概念）**:

```text
Pages -> Widgets -> Providers -> Services -> Repositories -> Data Models
                  ↑                          ↓
                  └──── Riverpod State Management ────┘
```

---

## 📋 機能仕様ドキュメント（Feature Specifications）

### 現行仕様

| ファイル名                                                           | 概要                                                                            | 最終更新   |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ---------- |
| [invitation_system.md](invitation_system.md)                         | QR招待システムの仕様（セキュリティキー、期限、受諾フロー、権限制御）            | 2026-06-26 |
| [network_failure_handling_flow.md](network_failure_handling_flow.md) | Firestore オフライン永続化を前提にしたネットワーク障害時の処理フロー            | 2026-04-14 |
| [notification_system.md](notification_system.md)                     | 通知システムの仕様（Firestore `notifications`、通知タイプ、既読管理、同期挙動） | 2026-06-26 |

---

## 🗃️ 別置きドキュメント（Archived / Shelved）

| ファイル名                                                                                            | 概要                                                                             |
| ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| [development_plan_archive_20260309.md](../daily_reports/2026-03/development_plan_archive_20260309.md) | 2026-02-17 時点の開発計画スナップショット。履歴資料として `daily_reports` に移設 |
| [member_message_feature_shelved.md](../knowledge_base/member_message_feature_shelved.md)              | ホワイトボード機能へ方向転換したため当面棚上げにした伝言メッセージ設計           |

---

## ⚖️ 法的ドキュメント（Legal Documents）

| ファイル名                                 | 概要                                                                               | 言語         | 最終更新   |
| ------------------------------------------ | ---------------------------------------------------------------------------------- | ------------ | ---------- |
| [privacy_policy.md](privacy_policy.md)     | プライバシーポリシー（個人情報の取り扱い、Firebase/AdMob利用、位置情報の詳細説明） | 日本語・英語 | 2026-05-11 |
| [terms_of_service.md](terms_of_service.md) | 利用規約（サービス利用条件、有料プラン導入後も広告付き無料プラン継続を明記）       | 日本語・英語 | 2026-05-11 |
| [data_deletion.md](data_deletion.md)       | データ・アカウント削除方法（Play Console データ削除 URL 用）                       | 英語・日本語 | 2026-04-14 |
| [eula.md](eula.md)                         | 使用許諾契約書（アプリ利用条件、禁止事項、ライセンス範囲）                         | 日本語・英語 | 2026-05-07 |

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
- **[docs/daily_reports/](../daily_reports/)**: 日報（2025年10月〜2026年6月、50+ファイル、月別整理）
- **[docs/knowledge_base/](../knowledge_base/)**: ナレッジベース（33ファイル、技術Tips、トラブルシューティング）

### プロジェクトルート

- **[README.md](../../README.md)**: プロジェクト概要
- **[SETUP.md](../../SETUP.md)**: セットアップ手順
- **[HISTORY.md](../../HISTORY.md)**: 開発履歴
- **[.github/copilot-instructions.md](../../.github/copilot-instructions.md)**: AI Coding Agent指示書（アーキテクチャサマリー含む）

---

## 📊 ドキュメント統計（Documentation Statistics）

| カテゴリ                       | ファイル数 | 総行数（実測） | 最終更新日 |
| ------------------------------ | ---------- | -------------- | ---------- |
| **アーキテクチャリファレンス** | 6          | 7,418行        | 2026-06-23 |
| **機能仕様**                   | 3          | 2,542行        | 2026-06-26 |
| **法的ドキュメント**           | 4          | 1,000行        | 2026-05-13 |
| **合計（README除く）**         | 13         | 10,960行       | 2026-06-26 |

**補足**:

- 本フォルダには上記13ファイルに加えて、インデックスの `README.md` があります（合計14ファイル）。
- 行数は `docs/specifications` 配下の Markdown ファイルを対象に実測しています。

---

## ✅ メンテナンス履歴（Maintenance History）

| 日付       | 更新内容                                                                     |
| ---------- | ---------------------------------------------------------------------------- |
| 2026-06-26 | invitation_system.md / notification_system.md を 2026-02以降の実装差分に同期 |
| 2026-06-26 | インデックスを現行ファイル構成に合わせて再整理（分類・更新日・統計を更新）   |
| 2026-02-19 | インデックスファイル（README.md）作成                                        |
| 2026-02-19 | provider_classes_reference.md 作成（60+プロバイダー、3,800行）               |
| 2026-02-19 | service_classes_reference.md 作成（46サービス、66クラス、1,900行）           |
| 2026-02-19 | page_widgets_reference.md 作成（17ページ、1,100行）                          |
| 2026-02-19 | widget_classes_reference.md 作成（42ウィジェット、650行）                    |
| 2026-02-18 | data_classes_reference.md 作成（26クラス、500行）                            |

---

**Note**: このインデックスファイルは定期的に更新されます。新しいドキュメントが追加された場合や、既存ドキュメントに大きな変更があった場合は、このREADME.mdも更新してください。
