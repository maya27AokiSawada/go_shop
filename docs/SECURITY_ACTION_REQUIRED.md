# 🚨 緊急セキュリティ対応が必要です

**日付**: 2026-02-10（最終更新: 2026-02-17）
**対応状況**: Git履歴クリーンアップ完了、手動設定変更が必要

---

## ✅ 完了済み（自動対応）

### 1. Git管理からの機密ファイル除外

- ✅ `lib/firebase_options_goshopping.dart` - Git管理から除外（`git rm --cached`）
- ✅ `extensions/firestore-send-email.env` - Git管理から除外（`git rm --cached`）
- ✅ `ios/Runner/GoogleService-Info.plist` - Git管理から除外（`git rm --cached`）
- ✅ `ios_backup/GoogleService-Info.plist` - Git管理から除外（`git rm --cached`）
- ✅ `.gitignore`に追加済み（今後は自動的に除外）

**Commits**:

- `2279996` - "security: 機密情報をGit管理から除外＋Sentry DSN説明追加"
- `31625c4` - "security: iOS版GoogleService-Info.plistをGit管理から除外（機密情報保護）"

### 2. Git履歴から機密情報を完全削除（2026-02-17完了）

**使用ツール**: BFG Repo-Cleaner v1.14.0

**削除対象ファイル**:

- ✅ `lib/firebase_options_goshopping.dart` - 295オブジェクトID変更
- ✅ `extensions/firestore-send-email.env` - 729オブジェクトID変更
- ✅ `ios/Runner/GoogleService-Info.plist` - 272オブジェクトID変更（3バージョン削除）

**更新されたブランチ**:

- ✅ `future`: ba47b36 → 3be13a8（強制更新）
- ✅ `main`: 8825c0a → 8ef2db2（強制更新）
- ✅ `oneness`: 670f6f7 → c1c7caf（強制更新）

**BFGレポート**: `C:\FlutterProject\go_shop.bfg-report\2026-02-17\`

**実行コマンド**:

```powershell
# BFG Repo-Cleanerで機密ファイルを全履歴から削除
cd C:\FlutterProject
java -jar bfg.jar --delete-files firebase_options_goshopping.dart --no-blob-protection go_shop
java -jar bfg.jar --delete-files firestore-send-email.env --no-blob-protection go_shop
java -jar bfg.jar --delete-files GoogleService-Info.plist --no-blob-protection go_shop

# reflogとガベージコレクション
cd go_shop
git reflog expire --expire=now --all
git gc --prune=now

# リモートに強制プッシュ
git push --force --all
```

### 2. Sentry DSN説明コメント追加

- ✅ Sentry DSNは公開情報として設計されている旨を`main.dart`、`main_dev.dart`、`main_prod.dart`に明記
- ✅ セキュリティ保護方法を説明

---

## ⚠️ 【緊急】手動対応が必要（優先度：最高）

### 🔥 1. Gmailアプリパスワードの無効化と再発行

**問題**: `extensions/firestore-send-email.env`に含まれていたGmailアプリパスワード（`hlcptkurwoftnple`）が過去のGit履歴に残っている可能性があります。

**対応手順**:

1. **今すぐGoogleアカウント管理画面にアクセス**
   - https://myaccount.google.com/apppasswords
   - アカウント: `ansize.oneness@gmail.com`

2. **既存のアプリパスワードを削除**
   - 「go_shop」や「Firebase」などの名前で作成されたアプリパスワードを全て削除

3. **新しいアプリパスワードを発行**
   - 新しいアプリパスワードを生成
   - `extensions/firestore-send-email.env`ファイルに記録（このファイルは`.gitignore`で保護済み）

4. **Firebase Extensionの設定を更新**
   ```bash
   # Firebase Consoleで更新するか、Firebase CLIで再設定
   firebase ext:configure firestore-send-email --project goshopping-48db9
   firebase ext:configure firestore-send-email --project gotoshop-572b7
   ```

**現在の使用状況**: Authのパスワードリセットメール送信のみ

---

## ⚠️ 手動対応が必要（優先度：高）

### 🔐 2. Firebase API Keyの制限設定

**問題**: `lib/firebase_options_goshopping.dart`に含まれていたFirebase API Keyが過去のGit履歴に残っています。

**対応手順**:

1. **Google Cloud Consoleにアクセス**
   - https://console.cloud.google.com/
   - プロジェクト: `goshopping-48db9` と `gotoshop-572b7`

2. **API KeysでFirebase API Keyを検索**
   - 「認証情報」→「APIキー」
   - `AIzaSyCOrH6NiWn6nUhpdgnZ328hQ9Yel-ECFf4`（prod）
   - `AIzaSyAMlVtmR4t0tEkWoD32xbTfKBnjAjQUbFU`（dev）

3. **APIキーの制限を設定**
   - **Androidアプリの制限**: パッケージ名を`net.sumomo_planning.goshopping`に制限
   - **iOSアプリの制限**: バンドルIDを制限
   - **HTTP refererの制限**（Web版）: 許可するドメインのみ設定

4. **API制限を設定**
   - 使用するFirebase APIのみを許可（不要なAPIへのアクセスを拒否）

**参考**: https://cloud.google.com/docs/authentication/api-keys#api_key_restrictions

---

### 🛡️ 3. Sentry DSNのセキュリティ設定

**問題**: Sentry DSNは公開情報として設計されていますが、レートリミットや許可ドメイン設定が必要です。

**対応手順**:

1. **Sentry管理画面にアクセス**
   - https://sentry.io/
   - プロジェクト: GoShopping

2. **Allowed Domainsを設定**
   - Settings → Client Keys (DSN)
   - 「Allowed Domains」に許可するドメインを設定
   - 例: `net.sumomo_planning.goshopping`、`localhost`

3. **レートリミットを設定**
   - Settings → Quotas
   - 適切なレートリミットを設定（無制限の送信を防ぐ）

---

## 📋 推奨対応（優先度：中）

### 4. Git履歴からの完全削除

現在のコミットで機密ファイルを削除しましたが、**Git履歴には残っています**。完全に削除するには以下のツールを使用してください。

#### オプション1: BFG Repo-Cleaner（推奨）

```bash
# BFGをダウンロード
# https://rtyley.github.io/bfg-repo-cleaner/

# ファイルを履歴から完全削除
java -jar bfg.jar --delete-files firebase_options_goshopping.dart
java -jar bfg.jar --delete-files firestore-send-email.env

# 履歴をクリーンアップ
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# リモートに強制プッシュ（⚠️ 慎重に）
git push --force --all
```

#### オプション2: git filter-branch

```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/firebase_options_goshopping.dart extensions/firestore-send-email.env" \
  --prune-empty --tag-name-filter cat -- --all

git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force --all
```

⚠️ **注意**: `git push --force`は他の開発者に影響を与えます。チームメンバーがいる場合は事前に通知してください。

---

## 🔍 確認方法

### 機密情報が履歴に残っているか確認

```bash
# Git履歴全体を検索
git log --all --full-history -p -S "hlcptkurwoftnple"
git log --all --full-history -p -S "AIzaSyCOrH6NiWn6nUhpdgnZ328hQ9Yel-ECFf4"

# ファイル履歴を確認
git log --all --full-history -- lib/firebase_options_goshopping.dart
git log --all --full-history -- extensions/firestore-send-email.env
```

### .gitignoreが正しく動作しているか確認

```bash
# Git管理外のファイルを確認
git status --ignored

# 機密ファイルがリストアップされていればOK
```

---

## 📚 セキュリティベストプラクティス

### 今後の対策

1. **環境変数の使用**
   - 機密情報は`.env`ファイルに記載
   - `.gitignore`で`.env`を除外
   - テンプレートファイル（`.env.template`）のみをGitにコミット

2. **定期的な監査**
   - 月1回のアクセスキー確認
   - 不要なアプリパスワードの削除
   - APIキー制限の見直し

3. **Dependabot有効化**
   - GitHub Dependabotで依存パッケージの脆弱性を自動検出

4. **Secretsスキャン**
   - GitHub Advanced Securityで機密情報の漏洩を自動検出

---

## 🆘 サポート

質問や不明点があれば、以下を参照してください：

- Firebase Security: https://firebase.google.com/docs/projects/api-keys
- Sentry Security: https://docs.sentry.io/product/security/
- BFG Repo-Cleaner: https://rtyley.github.io/bfg-repo-cleaner/

---

**最終更新**: 2026-02-10
**担当者**: GitHub Copilot AI Coding Agenthub.io/bfg-repo-cleaner/>

---

**最終更新**: 2026-02-10
**担当者**: GitHub Copilot AI Coding Agent
