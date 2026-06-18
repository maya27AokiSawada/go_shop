# GoShopping - AI Coding Agent Instructions

## 指示書の構成

詳細なアーキテクチャ・ルール・アンチパターンは `instructions/` フォルダを参照すること。
**実装・修正前に必ず該当ファイルを読むこと。**

| ファイル                                  | 内容                                         |
| ----------------------------------------- | -------------------------------------------- |
| `instructions/00_project_common.md`       | アーキテクチャ・認証・Riverpod・共通禁止事項 |
| `instructions/20_groups_lists_items.md`   | グループ・リスト・アイテム管理               |
| `instructions/30_whiteboard.md`           | ホワイトボード・編集ロック                   |
| `instructions/40_qr_and_notifications.md` | QR招待・通知                                 |
| `instructions/50_user_and_settings.md`    | ユーザー管理・設定・アカウント削除           |
| `instructions/90_testing_and_ci.md`       | テスト戦略・CI/CD                            |

---

## Firebase プロジェクト設定

| Flavor        | 用途         | 設定方針                                         |
| ------------- | ------------ | ------------------------------------------------ |
| `Flavor.prod` | 本番リリース | 実際の Firebase 設定値は tracked file に書かない |
| `Flavor.dev`  | 開発・テスト | 実際の Firebase 設定値は tracked file に書かない |

- 設定ファイル: `lib/firebase_options.dart`（動的切替実装済み、追跡除外前提）
- 環境変数: `.env`（AdMob / Sentry / 補助設定。追跡除外前提）
- セットアップ手順: `SETUP.md`
- Firebase MCP Server: `.vscode/settings.json` に設定済み（`npx -y firebase-tools@latest mcp`）

---

## ⚠️ Critical Project Rules

### Git Push Policy

**IMPORTANT**: Always follow this push strategy unless explicitly instructed otherwise:

- **Default**: Push to `oneness` branch only

  ```bash
  git push origin oneness
  ```

- **When explicitly instructed**: Push to both `oneness` and `main`
  ```bash
  git push origin oneness
  git push origin oneness:main
  ```

**Reasoning**: `oneness` branch is for active development and testing. `main` branch receives stable, tested changes only when explicitly approved by the user.

### Method Signature Changes Policy

⚠️ **CRITICAL - NEVER CHANGE METHOD SIGNATURES WITHOUT USER APPROVAL**:

**IMPORTANT**: メソッドやコンストラクタの呼び出しシグネチャ（引数の追加・削除・型変更・順序変更など）を変更する場合は、**必ずユーザーに確認を求めること**。

**禁止事項**:

- ❌ AIの判断で勝手にメソッドシグネチャを変更する
- ❌ 「既存の呼び出し箇所を全て更新します」と提案せずに実装する
- ❌ リファクタリング名目でシグネチャを変更する

**必須手順**:

1. ✅ シグネチャ変更が必要な理由を明確に説明する
2. ✅ 影響を受けるファイルと呼び出し箇所を列挙する
3. ✅ ユーザーの承認を得てから実装する
4. ✅ 変更後は必ず全ての呼び出し箇所を更新する

**例外**:

- 新規作成するメソッドやクラス（既存コードに影響なし）
- ユーザーが明示的に「シグネチャを変更してください」と指示した場合

**Reasoning**: シグネチャ変更は広範囲に影響し、コンパイルエラーやランタイムエラーの原因となるため、ユーザーの明示的な承認が必要です。

---

### Sensitive Information Policy

⚠️ **機密情報の取り扱いルール**:

このリポジトリは**公開リポジトリ**のため、機密情報の管理を徹底すること。

**gitignore 対象（コミット禁止）**:

- `google-services.json`, `GoogleService-Info.plist`（Firebase設定）
- `lib/firebase_options.dart`（APIキー含む）
- `*.env`, `key.properties`（認証情報）
- `*.txt`（ログ・デバッグファイル）
- `extensions/*.env`（メール送信や拡張機能の認証情報）

**ドキュメント・コード内の禁止事項**:

- ❌ APIキー・シークレットキーを平文で記載しない
- ❌ Firebase Project ID / Project Number / Sentry DSN を tracked file に直書きしない
- ❌ メールアドレス・個人情報を不必要に記載しない
- ❌ パスワード・トークンを記載しない
- ❌ `// TEMPORARY` などの本番不適切なコードをコミットしない

**必須対応**:

- ✅ 機密情報が既にコミット済みの場合はマスキング（`AIzaSy********************`など）して再コミット
- ✅ APIキーはローテーション後にローカルファイル（gitignore済み）のみに保存
- ✅ Sentry を使う場合も `SENTRY_DSN` は `.env` や CI Secret にのみ保存する
- ✅ Firestore Security Rulesは本番前に必ず厳格版を適用・デプロイ
- ✅ APIキーの受け渡しはチャット外（ローカルファイル参照）で行う

**設定場所の原則**:

- Firebase 実値: `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/GoogleService-Info-*.plist`
- AdMob / Sentry 実値: `.env`
- CI 用の実値: GitHub Secrets / Environment Secrets（例: `DOT_ENV`）

**APIキー更新手順**:

- `SETUP.md` の手順に従い、追跡除外ファイルをローカルで更新する
- 実際のキーや DSN は tracked docs に転記しない

---
