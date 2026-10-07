# AGENTS.md - Developer Rules for Gemini

## 重要指示 (Critical Instructions)

Gemini Code Assist およびその他のコーディングエージェント（Agents）は、実装やコード修正、Git操作を行う前に、必ず **GitHub Copilot 用の指示書および設計ルール** を参照し、それに従ってください。

本プロジェクトの最重要ルール、アーキテクチャ、アンチパターン、およびワークフローは、すべて以下のファイルに定義されています。これらを最優先事項として厳格に遵守してください。

### 1. 共通指示書 (Common Instructions)

- [copilot-instructions.md](copilot-instructions.md) / [.github/copilot-instructions.md](copilot-instructions.md)
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

## リリース目標バージョン (Release Target Version)

- **現在のビルド目標バージョン**: `1.2.0+44`
- **ストア公開目標**: バージョン `1.2.0`
- ビルド番号（`+N`）は Android の `versionCode` になるため、バージョン本体（`x.y.z`）が上がってもリセットせず通番で増やす（Google Play は過去より小さい `versionCode` を受け付けない）。
- バージョンの実体は `pubspec.yaml` の `version: x.y.z+N`。この節の値を変更できるのはユーザーの指示があったときのみ。

### sumomo-planning ブランチへプッシュするときのルール

1. プッシュ前に `pubspec.yaml` の `version` と、上記のビルド目標バージョンを必ず照合する。
2. プッシュ対象のコミットにコード変更（`lib/`、`android/`、`ios/`、`windows/`、`pubspec.yaml` の依存関係など、ビルド成果物に影響する変更）が含まれているのに `pubspec.yaml` の `version` が更新されていない場合は、プッシュせずにユーザーへ質問する（バージョン/ビルド番号を上げるか、そのままプッシュしてよいか）。
3. `pubspec.yaml` の `version` がビルド目標バージョンと食い違っている場合も、勝手に合わせず、どちらが正しいかユーザーへ質問する。
4. ドキュメントのみの変更（`docs/`、`instructions/`、`*.md` など）はバージョン更新不要。
5. ビルド番号を上げてビルド目標が変わった場合は、この節の「現在のビルド目標バージョン」も同じコミットで更新する。

---

## Gemini specific rules

- 回答やコード生成、リファクタリング、ファイルの編集を行う前に、上記の該当ドキュメントを読み込み、現行プロジェクトの設計方針や Riverpod の実装パターンに矛盾がないか確認してください。
- 矛盾や確認事項がある場合は、勝手に進めず、まずはユーザーに質問してください。
