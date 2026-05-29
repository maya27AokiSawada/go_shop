# AGENTS.md - Developer Rules for Gemini

## ⚠️ 重要指示 (Critical Instructions)

Gemini Code Assist およびその他のコーディングエージェント（Agents）は、実装やコード修正、Git操作を行う前に、必ず **GitHub Copilot 用の指示書および設計ルール** を参照し、それに従ってください。

本プロジェクトの最重要ルール、アーキテクチャ、アンチパターン、およびワークフローは、すべて以下のファイルに定義されています。これらを最優先事項として厳格に遵守してください。

### 1. 共通指示書 (Common Instructions)

- [copilot-instructions.md](copilot-instructions.md) / [.github/copilot-instructions.md](.github/copilot-instructions.md)
  - **Gitプッシュポリシー**: 原則 oneness ブランチへのみプッシュすること。明示的な指示がない限り main へ直接マージ/プッシュしない。
  - **メソッドシグネチャ変更ポリシー**: 既存メソッド、コンストラクタの引数や戻り値の型を変更する場合は、勝手に行わず必ず事前にユーザーの承認を得ること。
  - **機密情報の取り扱い定義**: APIキーや個人情報、ローカル設定ファイル（gitignore対象）のコミット厳禁。

### 2. 機能別・アーキテクチャ詳細ルール (Architecture & Feature Rules)

以下の instructions フォルダにあるドキュメントに、機能ごとのディレクトリ構造、状態管理（Riverpod）の適用方法、ホワイトボード編集ロック、QR招待、テスト手法などのルールがまとめられています。

- [instructions/00_project_common.md](instructions/00_project_common.md) - プロジェクト共通ルール・アーキテクチャ
- [instructions/20_groups_lists_items.md](instructions/20_groups_lists_items.md) - グループ・リスト・アイテム管理
- [instructions/30_whiteboard.md](instructions/30_whiteboard.md) - ホワイトボード・編集ロック
- [instructions/40_qr_and_notifications.md](instructions/40_qr_and_notifications.md) - QR招待・通知
- [instructions/50_user_and_settings.md](instructions/50_user_and_settings.md) - ユーザー管理・設定・アカウント削除
- [instructions/90_testing_and_ci.md](instructions/90_testing_and_ci.md) - テスト戦略・CI/CD

---

## 💡 Gemini specific rules

- 回答やコード生成、リファクタリング、ファイルの編集を行う前に、上記の該当ドキュメントを読み込み、現行プロジェクトの設計方針や Riverpod の実装パターンに矛盾がないか確認してください。
- 矛盾や確認事項がある場合は、勝手に進めず、まずはユーザーに質問してください。
