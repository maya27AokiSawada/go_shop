# ウィジェットクラスリファレンス

**作成日**: 2026-02-19
**最終更新**: 2026-02-19

## 📖 概要

本ドキュメントは、GoShoppingプロジェクトで使用される全ウィジェットクラスの一覧と概要を提供します。新規開発者のオンボーディング、UI構成の理解、コンポーネント再利用の参考資料として活用してください。

**凡例**:

- 📱 画面全体/ページウィジェット
- 🎨 UI部品/コンポーネント
- ⚙️ 設定パネル
- 🔐 認証関連
- 📊 データ表示
- 🔄 同期・初期化
- 🎯 専用機能

**総ウィジェット数**: 42個

---

## A - AcceptInvitationWidget 🎯

**ファイル**: `lib/widgets/accept_invitation_widget.dart`

**種類**: ConsumerWidget

**目的**: QRコードスキャンによるグループ招待受諾UI

**主要機能**:

- プラットフォーム別QRスキャナー（iOS/Android: MobileScanner、Windows: 手動入力）
- QR招待データの検証・デコード
- 招待受諾処理の実行
- エラーハンドリング

**使用場所**:

- `group_invitation_page.dart` - QR招待受諾タブ
- 招待リンクからの遷移

---

## A - AdBannerWidget 🎨

**ファイル**: `lib/widgets/ad_banner_widget.dart`

**種類**: ConsumerWidget（2クラス: AdBannerWidget、HomeAdBannerWidget）

**目的**: AdMob広告バナーの表示

**主要機能**:

- AdMobサービス統合
- 位置情報ベース広告優先化（30km圏内）
- 広告読み込み状態管理
- 自動メモリ管理（dispose）

**使用場所**:

- `home_page.dart` - HomeAdBannerWidget（認証済みユーザー）
- 各ページの下部（必要に応じて）

---

## A - AppInitializeWidget 🔄

**ファイル**: `lib/widgets/app_initialize_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: アプリ起動時の初期化処理を統合管理

**主要機能**:

- データマイグレーションチェック（8ステップ）
- UserInitializationServiceの実行
- Firebase/Hive初期化
- 定期購入アイテム自動リセット（5秒後）
- 論理削除アイテムクリーンアップ
- アプリモード設定ロード
- UID変更検出・データ移行

**使用場所**:

- `main.dart` - MyAppウィジェットのルート

**特徴**: 初期化完了までローディング表示、エラー時は再初期化ボタン

---

## A - AuthPanelWidget 🔐

**ファイル**: `lib/widgets/auth_panel_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: サインアップ/サインイン切り替え式認証パネル

**主要機能**:

- サインアップモード/サインインモード切り替え
- ディスプレイネーム入力（サインアップ時のみ必須）
- メール・パスワード入力フォーム
- バリデーション（パスワード6文字以上）
- Firebase Auth統合
- エラーメッセージ表示

**使用場所**:

- `home_page.dart` - 未認証時の認証パネル

**特徴**: モード切り替えでUIが動的変化、二重送信防止

---

## A - AuthStatusPanel ⚙️

**ファイル**: `lib/widgets/settings/auth_status_panel.dart`

**種類**: ConsumerWidget

**目的**: 認証状態の表示パネル

**主要機能**:

- Firebase Auth認証状態表示
- ユーザーID・メールアドレス表示
- 認証済み/未認証のステータス表示

**使用場所**:

- `settings_page.dart` - 設定画面上部

---

## C - CommonAppBar 🎨

**ファイル**: `lib/widgets/common_app_bar.dart`

**種類**: ConsumerWidget（PreferredSizeWidget実装）

**目的**: 全画面共通のAppBar（同期状態表示、メニュー）

**主要機能**:

- 同期状態アイコン表示（4種類: synced/syncing/offline/notLoggedIn）
- ユーザー名表示（オプション）
- グループ名表示（オプション）
- フローティングメニュー（ヘルプ、バージョン情報、通知履歴、エラー履歴）
- 認証状態に応じた動的タイトル

**使用場所**:

- 全ページのAppBar（home_page、settings_page、group_invitation_page等）

**特徴**: SyncState enumで同期状態を統一管理、PopupMenuButtonで拡張メニュー

---

## D - DataMigrationWidget 🔄

**ファイル**: `lib/widgets/data_migration_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: UID変更時のデータ移行ダイアログ

**主要機能**:

- データ初期化/引継ぎ選択
- Hive/SharedPreferencesクリア
- Firestore再同期
- デフォルトグループ作成フロー

**使用場所**:

- `app_initialize_widget.dart` - UID変更検出時

**特徴**: ユーザー選択によってデータ保持/削除を制御

---

## E - EmailDiagnosticsWidget 🎯

**ファイル**: `lib/widgets/email_test_button.dart`

**種類**: ConsumerStatefulWidget

**目的**: Firebase Email Extension診断ツール

**主要機能**:

- メールテンプレート送信
- 送信ステータス確認
- 展開・折りたたみUI

**使用場所**:

- 開発者向けツール（settings_page等）

**特徴**: デバッグ用、本番環境では非表示

---

## G - GroupCreationWithCopyDialog 🎨

**ファイル**: `lib/widgets/group_creation_with_copy_dialog.dart`

**種類**: StatefulWidget（内部ダイアログ）

**目的**: 既存グループコピー機能付きグループ作成ダイアログ

**主要機能**:

- 新規グループ名入力
- 既存グループ選択（コピー元）
- メンバーコピー機能
- リストコピー機能（アイテム含む）
- 重複名バリデーション
- UI自動反映（ref.invalidate）

**使用場所**:

- `group_list_widget.dart` - グループ作成ボタン

**特徴**: チェックボックスでコピー範囲選択、エラーログ統合

---

## G - GroupInvitationDialog 🎯

**ファイル**: `lib/widgets/group_invitation_dialog.dart`

**種類**: StatefulWidget（内部ダイアログ）

**目的**: グループ招待一覧・QRコード表示ダイアログ

**主要機能**:

- Firestore招待リストのStreamBuilder表示
- QRコード生成（qr_flutter）
- 招待残り回数表示（maxUses - currentUses）
- 招待削除機能
- トークンコピー機能

**使用場所**:

- `group_invitation_page.dart` - グループ選択後の招待管理

**特徴**: リアルタイムリスナーで最新状態を自動反映

---

## G - GroupListWidget 📊

**ファイル**: `lib/widgets/group_list_widget.dart`

**種類**: ConsumerWidget

**目的**: グループ一覧表示（タップでメンバー管理画面へ）

**主要機能**:

- 全グループリスト表示
- 選択中グループのハイライト
- オーナー/メンバー表示
- グループ削除機能（オーナーのみ）
- メンバー離脱機能（メンバーのみ）
- グループ0個時の作成案内表示
- Firestore同期状態表示
- Freeプラン時のみ、リスト末尾にバナー広告を表示

**使用場所**:

- `shared_group_page.dart` - グループ管理画面

**特徴**: グループ数にかかわらず常に表示し、空状態の案内もこのウィジェットが担当する。広告表示は `shouldShowAdsProvider` によりFreeプランのログイン済みユーザーに限定する。

---

## G - GroupSelectorWidget 🎨

**ファイル**: `lib/widgets/group_selector_widget.dart`

**種類**: ConsumerWidget

**目的**: グループ選択ドロップダウン

**主要機能**:

- 全グループリスト取得
- DropdownButtonでグループ選択
- 選択変更時に currentGroupProvider 更新
- リスト一覧の自動リセット

**使用場所**:

- 各ページのグループ切り替えUI

**特徴**: ドロップダウン変更時に関連プロバイダー自動無効化

---

## H - HiveInitializationWrapper 🔄

**ファイル**: `lib/widgets/hive_initialization_wrapper.dart`

**種類**: ConsumerWidget

**目的**: Hive初期化完了待機ラッパー

**主要機能**:

- Hive初期化完了まで待機
- ローディング表示
- エラーハンドリング

**使用場所**:

- 特定のHive依存ウィジェット（必要に応じて）

---

## I - InitialSetupWidget 🎯

**ファイル**: `lib/widgets/initial_setup_widget.dart`

**種類**: ConsumerWidget

**目的**: グループ0個時の初回セットアップ画面

**主要機能**:

- 「最初のグループを作成」ボタン
- 「QRコードでグループに参加」ボタン
- ウェルカムメッセージ表示

**使用場所**:

- `group_list_widget.dart` - グループなし時に自動表示

**特徴**: デフォルトグループ機能廃止後の代替UI（2026-02-12）

---

## I - InvitationMonitorWidget 🔄

**ファイル**: `lib/widgets/invitation_monitor_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: 招待通知のリアルタイム監視

**主要機能**:

- Firestore `invitations`コレクション監視
- 招待受諾通知の自動処理
- 通知リスナー管理

**使用場所**:

- `home_page.dart`（バックグラウンド監視）

**特徴**: StreamBuilder で常時監視、自動同期トリガー

---

## I - InviteWidget 🎯

**ファイル**: `lib/widgets/invite_widget.dart`

**種類**: ConsumerWidget

**目的**: QR招待生成・表示ウィジェット

**主要機能**:

- QR招待データ生成（v3.1軽量版）
- QRコード表示（250x250px）
- 招待トークンコピー機能
- セキュリティキー表示

**使用場所**:

- `group_invitation_page.dart` - 招待生成タブ

**特徴**: Firestore統合、v3.0/v3.1互換性

---

## M - MemberRoleManagementWidget 🎨

**ファイル**: `lib/widgets/member_role_management_widget.dart`

**種類**: ConsumerWidget

**目的**: メンバー役割変更ダイアログ

**主要機能**:

- 役割選択（owner/manager/member/viewer）
- Firestore/Hive同期更新
- 権限エラーハンドリング

**使用場所**:

- `group_member_management_page.dart` - メンバータイル

---

## M - MemberSelectionDialog 🎨

**ファイル**: `lib/widgets/member_selection_dialog.dart`

**種類**: StatefulWidget（内部ダイアログ）

**目的**: 複数メンバー選択ダイアログ（コピー用）

**主要機能**:

- チェックボックスリスト表示
- 全選択/全解除機能
- 選択メンバー返却

**使用場所**:

- `group_creation_with_copy_dialog.dart` - メンバーコピー選択

---

## M - MemberTileWithWhiteboard 🎨

**ファイル**: `lib/widgets/member_tile_with_whiteboard.dart`

**種類**: ConsumerWidget

**目的**: メンバータイル＋個人ホワイトボードアクセス

**主要機能**:

- メンバー情報表示（名前、役割）
- ダブルタップで個人ホワイトボード起動
- ホイットボードプレビュー表示

**使用場所**:

- `group_member_management_page.dart` - メンバーリスト

**特徴**: ホワイトボード機能統合（future ブランチ）

---

## M - MultiGroupInvitationDialog 🎯

**ファイル**: `lib/widgets/multi_group_invitation_dialog.dart`

**種類**: StatefulWidget（内部ダイアログ）

**目的**: 複数グループ選択・招待生成

**主要機能**:

- グループ選択ドロップダウン
- QR招待生成
- 招待一覧表示

**使用場所**:

- 複数グループ管理時の招待機能

---

## N - NewsAndAdsPanelWidget 🎨

**ファイル**: `lib/widgets/news_and_ads_panel_widget.dart`

**種類**: ConsumerWidget

**目的**: ニュース＋広告の統合パネル

**主要機能**:

- NewsWidget表示
- AdBannerWidget表示
- レイアウト統合

**使用場所**:

- `home_page.dart` - ホーム画面上部

---

## N - NewsWidget 📊

**ファイル**: `lib/widgets/news_widget.dart`

**種類**: ConsumerWidget（2クラス: NewsWidget、CompactNewsWidget）

**目的**: お知らせ・ニュース表示

**主要機能**:

- Firestore `appNews`コレクション取得
- Markdownレンダリング
- 展開/折りたたみUI
- カテゴリ別フィルター
- 既読管理

**使用場所**:

- `home_page.dart` - ニュースパネル
- CompactNewsWidget: 簡易表示版

**特徴**: 最新5件表示、「もっと見る」ボタン

---

## O - OwnerMessageWidget 🎨

**ファイル**: `lib/widgets/owner_message_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: オーナーメッセージ表示パネル

**主要機能**:

- グループオーナーからのメッセージ表示
- 編集・保存機能（オーナーのみ）
- Firestore同期

**使用場所**:

- `group_member_management_page.dart` - グループ詳細

**特徴**: オーナー権限チェック、編集モード切替

---

## P - PaymentReminderWidget 🎨

**ファイル**: `lib/widgets/payment_reminder_widget.dart`

**種類**: ConsumerWidget

**目的**: 有料プラン案内・決済リマインダー

**主要機能**:

- 有料プラン情報表示
- 購入リンク
- 表示条件制御（無料プラン時）

**使用場所**:

- `settings_page.dart`（将来的に）

**特徴**: 有料プラン導入時に使用予定

---

## Q - QRCodePanelWidget 🎯

**ファイル**: `lib/widgets/qr_code_panel_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: QRコード生成・表示パネル

**主要機能**:

- QR招待データ生成
- QRコード表示（qr_flutter）
- トークンコピー機能
- セキュリティキー表示

**使用場所**:

- `group_invitation_page.dart` - 招待生成

**特徴**: Firestoreに招待データを保存、リアルタイム更新

---

## Q - QRInvitationWidgets 🎯

**ファイル**: `lib/widgets/qr_invitation_widgets.dart`

**種類**: 複数ウィジェット（QRInviteButton等）

**目的**: QR招待関連の各種UIコンポーネント

**主要機能**:

- QRInviteButton: 招待ボタン
- QRCodeDisplay: QRコード表示
- InvitationCard: 招待カード
- QRScanner: スキャナーUI

**使用場所**:

- 招待機能全般

**特徴**: 再利用可能なコンポーネント群

---

## S - SharedItemEditModal 🎨

**ファイル**: `lib/widgets/shared_item_edit_modal.dart`

**種類**: StatefulWidget（内部ダイアログ）

**目的**: アイテム編集モーダル

**主要機能**:

- アイテム名・数量編集
- 締切日時設定
- 定期購入間隔設定
- バリデーション

**使用場所**:

- `shopping_list_page_v2.dart` - アイテムタップ

**特徴**: SharedItem全フィールド編集対応

---

## S - SharedListHeaderWidget 🎨

**ファイル**: `lib/widgets/shared_list_header_widget.dart` / `shopping_list_header_widget.dart`

**種類**: ConsumerWidget（2ファイル、同一クラス名）

**目的**: リストヘッダー（リスト選択・作成）

**主要機能**:

- ドロップダウンでリスト選択
- リスト作成ダイアログ
- リスト削除機能
- リスト名変更機能
- 重複名チェック

**使用場所**:

- `shopping_list_page_v2.dart` - リストヘッダー

**特徴**: 差分同期対応、UI自動反映

---

## S - SignupDialog 🔐

**ファイル**: `lib/widgets/signup_dialog.dart`

**種類**: StatefulWidget（内部ダイアログ）

**目的**: サインアップ専用ダイアログ（旧実装）

**主要機能**:

- ディスプレイネーム・メール・パスワード入力
- Firebase Auth登録
- バリデーション

**使用場所**:

- 旧認証フロー（現在はAuthPanelWidgetで統合）

**特徴**: 単独ダイアログ形式

---

## S - SignupProcessingWidget 🔐

**ファイル**: `lib/widgets/signup_processing_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: サインアップ処理中のローディング表示

**主要機能**:

- ステップ別進捗表示
- エラーハンドリング
- 完了後の自動遷移

**使用場所**:

- `home_page.dart` - サインアップ処理時

**特徴**: プログレスバー、ステップインジケーター

---

## S - SyncStatusWidget 🔄

**ファイル**: `lib/widgets/sync_status_widget.dart`

**種類**: ConsumerWidget（2クラス: SyncStatusWidget、SyncManagementWidget）

**目的**: 同期状態表示・手動同期管理

**主要機能**:

- 同期アイコン表示（4種類）
- 手動同期ボタン
- 同期エラー表示
- タイムスタンプ表示

**使用場所**:

- `common_app_bar.dart` - AppBar内
- `settings_page.dart` - 設定画面

**特徴**: SyncManagementWidget: 詳細同期管理UI

---

## T - TestScenarioWidget 🎯

**ファイル**: `lib/widgets/test_scenario_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: 開発者向けテストシナリオ実行UI

**主要機能**:

- テストシナリオ一覧表示
- シナリオ実行ボタン
- 実行ログ表示
- Hive/Firestoreデバッグ

**使用場所**:

- `settings_page.dart` - 開発者ツールセクション

**特徴**: デバッグビルドのみ表示、本番環境では非表示

---

## U - UserDataMigrationDialog 🔄

**ファイル**: `lib/widgets/user_data_migration_dialog.dart`

**種類**: ConsumerWidget（内部ダイアログ）

**目的**: UID変更時のデータ移行選択ダイアログ

**主要機能**:

- データ初期化/引継ぎ選択
- 選択結果を親ウィジェットに返却

**使用場所**:

- `app_initialize_widget.dart` - UID変更検出時

**特徴**: シンプルな選択ダイアログ、DataMigrationWidgetと連携

---

## U - UserNamePanelWidget 🎨

**ファイル**: `lib/widgets/user_name_panel_widget.dart`

**種類**: ConsumerStatefulWidget

**目的**: ユーザー名表示・編集パネル

**主要機能**:

- ユーザー名表示
- 編集モード切替
- Firebase Auth + SharedPreferences更新
- 保存ボタン

**使用場所**:

- `home_page.dart` - ユーザー名パネル

**特徴**: リアルタイム編集、自動保存

---

## W - WhiteboardPreviewWidget 🎨

**ファイル**: `lib/widgets/whiteboard_preview_widget.dart`

**種類**: ConsumerWidget

**目的**: ホワイトボードプレビュー表示

**主要機能**:

- CustomPainterでストローク描画
- タップでフルスクリーンエディター起動
- リアルタイム同期（StreamProvider）
- ストローク数表示

**使用場所**:

- グループ情報エリア（future ブランチ）

**特徴**: グループ共有ホワイトボード機能統合

---

## W - WindowsQRScanner 🎯

**ファイル**: `lib/widgets/windows_qr_scanner.dart`

**種類**: StatefulWidget

**目的**: Windows版QRスキャナー（画像選択版）

**主要機能**:

- ファイルピッカーで画像選択
- 画像表示
- 手動入力フォールバック

**使用場所**:

- `accept_invitation_widget.dart` - Windowsプラットフォーム

**特徴**: カメラ非対応プラットフォーム用

---

## W - WindowsQRScannerSimple 🎯

**ファイル**: `lib/widgets/windows_qr_scanner_simple.dart`

**種類**: StatefulWidget

**目的**: Windows版QRスキャナー（手動入力専用）

**主要機能**:

- 画像選択ボタン
- 手動入力ダイアログ（8行TextField）
- JSON形式データ貼り付け

**使用場所**:

- `accept_invitation_widget.dart` - Windowsプラットフォーム

**特徴**: カメラ・QRデコード非対応環境用の代替UI

---

## 設定パネルウィジェット（widgets/settings/）

### AppModeSwitcherPanel ⚙️

**ファイル**: `lib/widgets/settings/app_mode_switcher_panel.dart`

**種類**: ConsumerWidget

**目的**: アプリモード切り替えパネル（買い物 ⇄ TODO）

**主要機能**:

- SegmentedButtonでモード切替
- AppModeSettings更新
- Hive保存

**使用場所**:

- `settings_page.dart` - モード切替セクション

---

### AuthStatusPanel ⚙️

**前述の通り**

---

### FirestoreSyncStatusPanel ⚙️

**ファイル**: `lib/widgets/settings/firestore_sync_status_panel.dart`

**種類**: ConsumerWidget

**目的**: Firestore同期状態詳細表示

**主要機能**:

- 同期状態表示（成功/失敗/同期中）
- 最終同期時刻表示
- 手動同期ボタン
- エラーログ表示

**使用場所**:

- `settings_page.dart` - Firestore同期セクション

---

### NotificationSettingsPanel ⚙️

**ファイル**: `lib/widgets/settings/notification_settings_panel.dart`

**種類**: ConsumerWidget

**目的**: 通知設定パネル

**主要機能**:

- リスト通知ON/OFF切替
- 通知履歴ボタン
- UserSettings連携

**使用場所**:

- `settings_page.dart` - 通知設定セクション

---

### PrivacySettingsPanel ⚙️

**ファイル**: `lib/widgets/settings/privacy_settings_panel.dart`

**種類**: ConsumerWidget

**目的**: プライバシー設定パネル

**主要機能**:

- シークレットモードON/OFF
- 位置情報使用許可
- データ収集設定

**使用場所**:

- `settings_page.dart` - プライバシーセクション

---

## 📊 ウィジェット分類統計

### カテゴリ別

| カテゴリ             | 個数 | 主要ウィジェット                                           |
| -------------------- | ---- | ---------------------------------------------------------- |
| **認証関連**         | 5    | AuthPanelWidget, SignupDialog, SignupProcessingWidget      |
| **グループ管理**     | 7    | GroupListWidget, GroupSelectorWidget, GroupCreationDialog  |
| **招待・QR**         | 8    | AcceptInvitationWidget, QRCodePanelWidget, InviteWidget    |
| **リスト・アイテム** | 3    | SharedListHeaderWidget, SharedItemEditModal                |
| **同期・初期化**     | 5    | AppInitializeWidget, SyncStatusWidget, DataMigrationWidget |
| **設定パネル**       | 5    | AppModeSwitcherPanel, NotificationSettingsPanel等          |
| **UI部品**           | 6    | CommonAppBar, NewsWidget, AdBannerWidget                   |
| **ホワイトボード**   | 2    | WhiteboardPreviewWidget, MemberTileWithWhiteboard          |
| **その他**           | 1    | TestScenarioWidget                                         |

### 状態管理タイプ別

| タイプ                     | 個数 |
| -------------------------- | ---- |
| **ConsumerWidget**         | 23   |
| **ConsumerStatefulWidget** | 11   |
| **StatefulWidget**         | 8    |

---

## 🔍 重要な設計パターン

### 1. Riverpod統合

全ウィジェットが`ConsumerWidget`または`ConsumerStatefulWidget`を継承し、Riverpodプロバイダーと統合。

```dart
class ExampleWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    // ...
  }
}
```

### 2. プラットフォーム別UI

```dart
if (Platform.isWindows) {
  return WindowsQRScannerSimple(onDetect: _processQRInvitation);
} else {
  return MobileScanner(onDetect: _processMobileScannerBarcode);
}
```

- `AcceptInvitationWidget`: iOS/Android（MobileScanner）、Windows（手動入力）
- 他のウィジェットでも必要に応じて分岐

### 3. StreamBuilder統合

リアルタイム同期が必要なウィジェットでFirestore `snapshots()`使用。

**例**:

- `GroupInvitationDialog`: 招待リスト監視
- `WhiteboardPreviewWidget`: ホワイトボードストローク監視

### 4. ダイアログ返却パターン

`showDialog()`の返り値で親ウィジェットにデータを渡す。

```dart
final result = await showDialog<Map<String, dynamic>>(
  context: context,
  builder: (context) => UserDataMigrationDialog(),
);

if (result?['action'] == 'clear') {
  // 初期化処理
}
```

### 5. エラーハンドリング

- `ErrorHandler.handleError()` 統合
- `SnackBarHelper.showError()` でユーザーフィードバック
- `ErrorLogService.logOperationError()` でログ記録

---

## 📝 メンテナンスガイド

### 新規ウィジェット追加時

1. **ファイル命名**: `{feature_name}_widget.dart`形式
2. **クラス命名**: `{FeatureName}Widget`形式
3. **Riverpod統合**: `ConsumerWidget`または`ConsumerStatefulWidget`を継承
4. **コメント追加**: クラス冒頭に目的・機能の簡潔な説明
5. **本リファレンス更新**: アルファベット順に挿入

### ウィジェット削除時

- 本リファレンスから対応項目を削除
- 使用場所の記載も確認・更新

### 機能変更時

- 主要機能・使用場所の記載を更新
- 特徴セクションに変更内容を追記

---

## 🎯 今後の拡張予定

### HIGH Priority

1. **ホワイトボードウィジェット群** (future ブランチ)
   - 編集ツールバー
   - カラーピッカー
   - ストローク履歴

2. **権限管理UI**
   - Permission表示ウィジェット
   - 権限変更ダイアログ

### MEDIUM Priority

3. **アイテムUI強化**
   - 締切表示バッジ
   - 定期購入インジケーター
   - カテゴリタグ

4. **統計・分析ウィジェット**
   - 購入履歴グラフ
   - メンバー活動統計

---

## 📌 関連ドキュメント

- **データクラスリファレンス**: `docs/specifications/data_classes_reference.md`
- **Riverpodベストプラクティス**: `docs/riverpod_best_practices.md`
- **アーキテクチャ概要**: `.github/copilot-instructions.md`
- **ホワイトボード設計**: `docs/specifications/whiteboard_stroke_save_flow.md`

---

**最終更新日**: 2026-02-19
**総ウィジェット数**: 42個（メイン37個 + 設定5個）
**作成者**: AI Coding Agent
**レビュー**: 次回セッション時
