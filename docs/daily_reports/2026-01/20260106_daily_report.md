# 日報 - 2026年1月6日

## 📋 実施内容

### 1. GitHub Actions CI/CD 環境構築完了 ✅

**目的**: oneness ブランチへの push 時に自動 Android APK ビルドを実現

**実装内容**:
- ランナー環境を `ubuntu-latest` に変更（当初 windows-latest で失敗）
- PowerShell 構文から bash Here-Document 構文に変更
- Flavor 指定追加（`--flavor dev`）と APK パス修正
- GitHub Secrets 設定（FIREBASE_OPTIONS_DART, GOOGLE_SERVICES_JSON, DOT_ENV）

**技術的ポイント**:
```yaml
# bash Here-Document構文
- name: Create google-services.json
  run: |
    cat << 'EOF' > android/app/google-services.json
    ${{ secrets.GOOGLE_SERVICES_JSON }}
    EOF
```

**成果**: ✅ ビルド成功・APK 生成確認

**ドキュメント**: `docs/knowledge_base/github_actions_ci_cd.md`

### 2. ドキュメント整理（77ファイル） ✅

**実施内容**:
- docs フォルダを 3 カテゴリに分類
  - `daily_reports/` - 日報（36ファイル、月別整理）
    - 2025-10/ (7ファイル)
    - 2025-11/ (13ファイル)
    - 2025-12/ (14ファイル)
    - 2026-01/ (2ファイル)
  - `knowledge_base/` - ナレッジベース（33ファイル）
  - `specifications/` - プロジェクト仕様（8ファイル）

**成果物**: `docs/README.md`（追加ガイドライン付き）

### 3. プライバシーポリシー・利用規約作成 ✅

**目的**: Google Play クローズドベータテスト準備

**作成ドキュメント**:
- `docs/specifications/privacy_policy.md`
  - 位置情報の詳細説明（広告最適化のみ、任意、30km精度）
  - Firebase/AdMob 利用明記
  - データ削除方法
  - 日本語版 + 英語版

- `docs/specifications/terms_of_service.md`
  - サービス内容（5つの主要機能）
  - 禁止事項（10項目）
  - 免責事項（ベータテスト中の注意）
  - 有料プラン導入後も広告付き無料プラン継続を明記
  - 日本語版 + 英語版

**メールアドレス**: maya27aokisawada@maya27AokiSawada.net

### 4. ユーザー名設定バグ修正 ✅

**問題**: 新規サインアップ時に前ユーザーの名前がデフォルトグループに表示される

**原因**: `authStateChanges` 発火時に SharedPreferences がまだクリアされていなかった

**修正内容** (`lib/pages/home_page.dart`):
```dart
// 修正後の順序
1. SharedPreferences.clear()
2. Hive.clear()
3. Firebase Auth.signUp()
4. 👉 UserPreferencesService.saveUserName("すもも")（即座に保存）
5. user.updateDisplayName("すもも")
6. Firestore.ensureUserProfileExists("すもも")
7. authStateChanges → createDefaultGroup() 実行
```

**検証**: ✅ Pixel9 でテスト成功

### 5. グループ削除通知機能実装 ✅

**問題**: オーナーがグループ削除しても参加メンバーの端末から削除されない

**実装内容** (`lib/services/notification_service.dart`):
- `NotificationType.groupDeleted` 通知受信時の処理追加
- Hive からグループを削除
- 選択中グループが削除された場合は別のグループに自動切替
- グループがない場合はデフォルトグループ作成

**必要なインポート追加**:
- `purchase_group_provider.dart` - selectedGroupIdProvider
- `hive_shared_group_repository.dart` - hiveSharedGroupRepositoryProvider

### 6. CI/CD トリガーブランチ変更 ✅

**変更内容**:
```yaml
# Before
on:
  push:
    branches: [oneness]

# After
on:
  push:
    branches: [main]
```

**理由**: 開発中は oneness で自由に作業、main マージ時のみビルド実行

### 7. Kotlin バージョン更新 ✅

**変更内容**: `android/settings.gradle.kts`
```kotlin
// Before
id("org.jetbrains.kotlin.android") version "2.0.21" apply false

// After
id("org.jetbrains.kotlin.android") version "2.1.0" apply false
```

**理由**: 非推奨警告対応

### 8. プロバイダー重複定義の修正 ✅

**問題**: `SharedGroupRepositoryProvider` が 2 箇所で定義されていた
- `purchase_group_provider.dart`
- `hive_shared_group_repository.dart`

**修正**:
- `hive_shared_group_repository.dart` から重複定義を削除
- `saveDefaultGroupProvider` も削除（未使用）
- インポート衝突を完全解消

### 9. pubspec.yaml アセットパス修正 ✅

**問題**: ドキュメント整理後にビルドエラー

**修正**:
```yaml
# Before
assets:
  - docs/user_guide.md

# After
assets:
  - docs/knowledge_base/user_guide.md
```

## 🐛 修正したバグ

1. **CI/CD ビルドエラー**:
   - PowerShell 構文 → bash 構文
   - Flavor 指定不足 → `--flavor dev` 追加
   - APK パス不一致 → `app-dev-release.apk` に修正

2. **ユーザー名設定バグ**:
   - タイミングレース問題
   - SharedPreferences 保存順序修正

3. **インポートエラー**:
   - 存在しないファイルインポート削除
   - プロバイダー重複定義解消
   - 名前衝突解決

## 📊 成果

### コード品質
- ✅ ビルドエラー 0 件
- ✅ プロバイダー設計改善（重複削除）
- ✅ インポート整理

### ドキュメント
- ✅ 77 ファイル整理完了
- ✅ プライバシーポリシー・利用規約完備
- ✅ CI/CD セットアップガイド作成

### Play ストア準備
- ✅ 自動ビルド環境構築
- ✅ 法的ドキュメント完備
- ✅ 主要バグ修正完了

## 🎯 次のステップ

### 1. クローズドベータテスト開始（優先度: HIGH）
- [ ] Play Console でアプリ登録
- [ ] スクリーンショット撮影（5-8枚）
- [ ] アプリ説明文作成
- [ ] ベータテスター招待（5-10名）

### 2. 動作確認（優先度: MEDIUM）
- [x] ユーザー名設定バグ修正確認
- [x] グループ削除通知動作確認
- [ ] 2デバイス間同期テスト

### 3. 今後の機能追加（優先度: LOW）
- ホワイトボード機能（2-3週間規模）
- アイテム削除権限チェック
- Firestore ユーザー情報構造簡素化

## 💭 所感

### 良かった点
- CI/CD 環境を完全に構築できた
- ドキュメントが整理され、管理しやすくなった
- Play ストア準備が整った

### 改善点
- ビルドエラーの試行錯誤に時間がかかった
- プロバイダー重複定義は早期に発見すべきだった

### 学んだこと
- GitHub Actions の bash 構文（Here-Document）
- Flutter flavor 指定の重要性
- プロバイダー設計のベストプラクティス

## 📝 コミット一覧

1. `bd9e793` - ci: Initial CI/CD setup
2. `dbec044` - ci: Change CI runner from windows-latest to ubuntu-latest
3. `06c8a20` - ci: Fix shell syntax for ubuntu-latest (PowerShell to bash)
4. `1e365fa` - ci: Add flavor specification for Android APK build
5. `3fdc7bd` - docs: Add GitHub Actions CI/CD setup guide
6. `d00e0a3` - docs: Reorganize docs folder structure
7. `5ae957b` - docs: Add Privacy Policy and Terms of Service for closed beta
8. `efe31e2` - docs: Add email address and clarify ad-supported free plan continuity
9. `1cd4130` - fix: Update user_guide.md asset path after docs reorganization
10. `1d9df59` - fix: Ensure user name is saved to Preferences before authStateChanges triggers
11. `2d16fb1` - feat: Implement group deletion notification to all members
12. `6514321` - ci: Change build trigger from oneness to main branch only
13. `daa7081` - chore: Update Kotlin version from 2.0.21 to 2.1.0
14. `87b1c00` - fix: Correct provider imports in notification_service.dart
15. `90eb8ca` - fix: Add correct import for hiveSharedGroupRepositoryProvider
16. `a4d9bdf` - fix: Resolve SharedGroupRepositoryProvider import conflict
17. `485a6b9` - refactor: Remove duplicate SharedGroupRepositoryProvider definition

## ⏰ 作業時間

- CI/CD 環境構築: 約3時間
- ドキュメント整理: 約1時間
- バグ修正・機能実装: 約2時間
- **合計**: 約6時間

---

**作成者**: GitHub Copilot
**日付**: 2026年1月6日
