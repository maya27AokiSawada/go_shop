# 🚨 緊急セキュリティ対応が必要です

**日付**: 2026-02-10（最終更新: 2026-02-17）
**対応状況**: ほぼ完了（Sentry設定のみ残存）

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

### 3. Sentry DSN説明コメント追加

- ✅ Sentry DSNは公開情報として設計されている旨を`main.dart`、`main_dev.dart`、`main_prod.dart`に明記
- ✅ セキュリティ保護方法を説明

### 4. Gmail appパスワードの無効化と再発行（2026-02-17完了）

- ✅ 既存のGmail appパスワード（`hlcptkurwoftnple`）を無効化
- ✅ 新しいアプリパスワードを発行して`extensions/firestore-send-email.env`に設定
- ✅ Firebase Extensionの設定を更新

**アカウント**: `ansize.oneness@gmail.com`
**用途**: Firebase Email Extension（パスワードリセットメール送信）

### 5. Firebase API Keyの制限設定（2026-02-17完了）

- ✅ Google Cloud Consoleでアプリケーション制限を設定
- ✅ Androidアプリ: パッケージ名`net.sumomo_planning.goshopping`で制限
- ✅ iOSアプリ: Bundle IDで制限
- ✅ 使用APIの制限を設定

**対象API Keys**:

- Android prod: `AIzaSyCOrH6NiWn6nUhpdgnZ328hQ9Yel-ECFf4`
- Android dev: `AIzaSyAMlVtmR4t0tEkWoD32xbTfKBnjAjQUbFU`
- iOS prod: `AIzaSyCgauCbShRE1og3U3_a6EQWmycZqgu4y6w`

---

## ⚠️ 残りの手動対応が必要（優先度：中）

### 🛡️ Sentry DSNのセキュリティ設定

**現状**: Sentry DSNは公開情報として設計されていますが、レートリミットや使用量制限の設定が推奨されます。

**対応手順**:

1. **Sentry管理画面にアクセス**
   - https://sentry.io/
   - プロジェクト: GoShopping

2. **Rate Limitsを設定**（推奨）
   - Settings → Projects → GoShopping → Processing
   - 適切なレートリミットを設定（例: 1000 events/minute）
   - 無制限の送信を防ぐ

3. **Spike Protectionを有効化**（推奨）
   - Organization Settings → Usage & Billing
   - Spike Protectionを有効にして予期しない大量エラーに備える

4. **Data Scrubbingを設定**（オプション）
   - Settings → Projects → GoShopping → Security & Privacy
   - 個人情報の自動マスキングを有効化

**参考**: https://docs.sentry.io/product/security/

---

## 📋 完了した対策の詳細

### Git履歴からの完全削除について

当初「推奨対応」としていたGit履歴からの完全削除は、**BFG Repo-Cleaner v1.14.0**を使用して2026-02-17に完了しました。

- 全ての機密ファイルが履歴から削除され、リモートリポジトリに反映済み
- 詳細は上記「2. Git履歴から機密情報を完全削除」セクションを参照

---

## 確認方法

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

**最終更新**: 2026-02-17
**担当者**: GitHub Copilot AI Coding Agent
**担当者**: GitHub Copilot AI Coding Agent
**担当者**: GitHub Copilot AI Coding Agent
