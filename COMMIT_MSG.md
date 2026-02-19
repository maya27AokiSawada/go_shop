docs: ページウィジェットリファレンス作成 (2026-02-19)

## 目的

アプリ全体の画面構成とナビゲーション構造を体系的に整理し、
アプリアーキテクチャの理解を促進

## 実装内容

### 新規ファイル

- `docs/specifications/page_widgets_reference.md` (約1100行)

### ドキュメント構造

- 本番ページ（11個）の詳細ドキュメント
- テスト/デバッグページ（6個）の概要
- ナビゲーション構造図（BottomNavigationBar階層）
- 統計情報（カテゴリ別、Widgetタイプ別、行数ランキング）
- 重要な設計パターン（6つ）
- アーキテクチャ的価値の明文化

### 主要ページ

1. HomePage (931行) - 認証・ニュース統合メイン画面
2. SharedListPage (1181行) - 買い物リスト管理
3. SettingsPage (2665行) - 総合設定ハブ（6パネル統合）
4. WhiteboardEditorPage (1902行) - フルスクリーン描画エディター
5. GroupMemberManagementPage (683行) - メンバー管理・役割制御
6. その他6ページ（NotificationHistory, ErrorHistory, News, Premium, Help, GroupInvitation）

### 技術的価値

- アプリ全体のアーキテクチャ把握が容易
- ナビゲーションフローの理解促進
- ページ別の責務分担を明確化
- 設計パターンの一貫性確認
- 新規開発者のオンボーディング効率化

### ドキュメント統合

- copilot-instructions.md - セクション5追加
- daily_report_20260219.md - セクション5追加
- Modified Files - page_widgets_reference.md追加
- Status Summary - ドキュメントカバレッジ更新

## Modified Files

- docs/specifications/page_widgets_reference.md (新規作成)
- .github/copilot-instructions.md (セクション5追加)
- docs/daily_reports/2026-02/daily_report_20260219.md (セクション5追加)

## Documentation Coverage

- ✅ データクラスリファレンス（26クラス、約500行）- 2026-02-18
- ✅ ウィジェットクラスリファレンス（42ウィジェット、約650行）- 2026-02-19
- ✅ ページウィジェットリファレンス（17ページ、約1100行）- 2026-02-19
- ⏳ サービスクラスリファレンス（次回）
- ⏳ プロバイダーリファレンス（次回）
- ⏳ リポジトリクラスリファレンス（次回）

## Branch

future
