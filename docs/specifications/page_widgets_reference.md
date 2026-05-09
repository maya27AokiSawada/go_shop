# ページウィジェットリファレンス

**作成日**: 2026-02-19
**最終更新**: 2026-02-19

## 📖 概要

本ドキュメントは、GoShoppingプロジェクトの全ページウィジェット（画面）の一覧と概要を提供します。アプリの全体構造、画面遷移、主要機能の理解に役立ちます。

**凡例**:

- 🏠 メイン画面
- 📋 データ表示・管理画面
- ⚙️ 設定・管理画面
- 🎨 編集・作成画面
- 📊 履歴・統計画面
- 🧪 テスト・デバッグ画面
- 💎 プレミアム機能画面
- 📖 情報・ヘルプ画面

**総ページ数**: 17個（本番用11個 + テスト/デバッグ用6個）

---

## 本番用ページ（Production Pages）

### 1. HomePage 🏠

**ファイル**: `lib/pages/home_page.dart` (971行)

**種類**: ConsumerStatefulWidget

**目的**: アプリのメイン画面。認証UI、ユーザー名設定、ニュース＋広告表示を統合

**主要機能**:

- **認証UI**:
  - アカウント作成（ディスプレイネーム + メール + パスワード）
  - サインイン（メール + パスワード）
  - サインアウト
  - パスワードリセット
  - メールアドレス記憶機能
- **ユーザー名パネル**: SharedPreferencesから自動ロード、Firestore同期
- **ニュース＋広告パネル**: NewsAndAdsPanelWidget統合
- **アプリ起動カウント**: AppLaunchService統合

**ナビゲーション**:

- `BottomNavigationBar` → ホーム/グループ/リスト/設定の4画面切り替え
- メインエントリーポイント（アプリ起動時に表示）

**特徴**:

- ✅ 二段階認証モード切り替え（`_isSignUpMode`フラグ）
- ✅ データクリーンアップ（サインアップ前に Hive + SharedPreferences クリア）
- ✅ Firestore優先同期（サインイン時に`forceSyncProvider`実行）
- ✅ エラーハンドリング強化（Firebase Authエラーコード日本語化）

**使用ウィジェット**:

- `UserNamePanelWidget` - ユーザー名表示＋編集
- `NewsAndAdsPanelWidget` - ニュース＋広告統合表示

**プロバイダー依存**:

- `authStateProvider` - 認証状態監視
- `authProvider` - サインアップ/サインイン/サインアウト
- `allGroupsProvider` - グループ同期
- `forceSyncProvider` - 強制Firestore同期

---

### 2. SharedListPage 📋

**ファイル**: `lib/pages/shared_list_page.dart` (1181行)

**種類**: ConsumerStatefulWidget

**目的**: 共有リスト画面。グループとリストを選択してアイテム管理

**主要機能**:

- **カレントグループ初期化**: SharedPreferencesから復元、なければ最初のグループを自動選択
- **グループ変更検出**: `didChangeDependencies()`でグループ切り替えを監視
- **リスト・アイテム表示**: StreamBuilderでリアルタイム更新
- **アイテム操作**:
  - 追加（ダブルタップ防止、モーダルダイアログ）
  - 購入状態切り替え（タップ）
  - 編集・削除（長押しメニュー）
- **期限・購入間隔設定**: SharedItemの詳細機能
- **ソート機能**: 未購入優先、期限順、登録順

**ナビゲーション**:

- `BottomNavigationBar` → 買い物リストタブ経由
- `SharedListHeaderWidget` → グループ・リスト選択ドロップダウン

**特徴**:

- ✅ カレントグループの完全な自動初期化
- ✅ グループ変更時のcurrentListProviderクリア
- ✅ Modal Bottom Sheetでアイテム追加UI
- ✅ 差分同期（`addSingleItem()`, `updateSingleItem()`, `removeSingleItem()`）
- ✅ `repository.getSharedListById()`で最新データ取得（同期タイミング問題回避）

**使用ウィジェット**:

- `SharedListHeaderWidget` - グループ・リスト選択UI
- `SharedItemEditModal` - アイテム編集モーダル

**プロバイダー依存**:

- `selectedGroupIdProvider` - カレントグループID
- `currentListProvider` - カレントリスト
- `allGroupsProvider` - 全グループ取得
- `groupSharedListsProvider` - グループ内リスト一覧
- `authStateProvider` - 現在ユーザー取得（memberId設定用）

---

### 3. SettingsPage ⚙️

**ファイル**: `lib/pages/settings_page.dart` (173行、各機能はセクションウィジェットに委譲)

**種類**: ConsumerStatefulWidget

**目的**: 設定画面。認証状態、言語設定、ホワイトボード設定、アカウント管理を統合

**主要機能**:

- **認証状態パネル**: AuthStatusPanel（サインイン状態表示）
- **Firestore同期状態パネル**: FirestoreSyncStatusPanel（同期状態表示）
- **アプリUIモード切り替え**: AppUiModeSwitcherPanel
- **アプリモード切り替え**: AppModeSwitcherPanel（買い物リスト ⇄ TODOタスク管理）
- **言語設定**: LanguageSettingsPanel（日本語 / English 切り替え）
- **ホワイトボード設定**: WhiteboardSettingsPanel（カスタム色等）
- **フィードバック**: FeedbackSection
- **開発者ツール**: DeveloperToolsSection、FeedbackDebugSection
- **データメンテナンス**: DataMaintenanceSection
- **アカウント削除**: AccountDeletionSection（2段階確認＋Firebase再認証）

> **Note**: `PrivacySettingsPanel`（シークレットモード）は2026-05-01に削除済み。

**ナビゲーション**:

- `BottomNavigationBar` → 設定タブ経由
- `NotificationHistoryPage` → 通知設定から遷移
- `ErrorHistoryPage` → エラー履歴ボタン経由
- `PremiumPage` → プレミアムプラン管理ボタン経由
- `HelpPage` → ヘルプボタン経由

**特徴**:

- ✅ セクション分割により本体ファイルが軽量（173行）
- ✅ 言語設定（日本語/英語）
- ✅ ホワイトボード描画色のカスタム設定
- ✅ アカウント削除の完全実装（再認証、サブコレクション削除、親グループ削除）

**使用ウィジェット**:

- `AuthStatusPanel` - 認証状態表示
- `FirestoreSyncStatusPanel` - 同期状態表示
- `AppUiModeSwitcherPanel` - UIモード切り替え
- `AppModeSwitcherPanel` - アプリモード切り替え
- `LanguageSettingsPanel` - 言語設定
- `WhiteboardSettingsPanel` - ホワイトボード設定
- `FeedbackSection` - フィードバック
- `AccountDeletionSection` - アカウント削除
- `DeveloperToolsSection` - 開発者ツール

**プロバイダー依存**:

- `authStateProvider` - 現在ユーザー
- `firestoreSyncStatusProvider` - 同期状態
- `appModeNotifierProvider` - アプリモード

---

### 4. GroupInvitationPage 🎨

**ファイル**: `lib/pages/group_invitation_page.dart` (308行)

**種類**: ConsumerStatefulWidget

**目的**: グループ招待画面。QRコード生成、招待タイプ選択、招待管理

**主要機能**:

- **QRコード生成**: QRInvitationServiceで軽量招待データ作成
- **招待タイプ切り替え**: individual（1人招待） / friend（友達招待）
- **QRコード表示**: 250x250サイズ、qr_flutterパッケージ使用
- **招待データ内容**:
  - `invitationId`: Firestore招待ドキュメントID
  - `sharedGroupId`: グループID
  - `securityKey`: セキュリティキー
  - `type`: 招待タイプ
  - `version`: 3.1（軽量版）

**ナビゲーション**:

- `GroupMemberManagementPage` → 招待ボタン経由
- `AcceptInvitationWidget` → QRスキャン経由で招待受諾

**特徴**:

- ✅ QRコード軽量化（v3.1: 5フィールド、~150文字）
- ✅ Firestore招待データ参照方式（QRコードには最小限の情報のみ）
- ✅ エラーハンドリング（招待生成失敗時の表示）
- ✅ リアルタイム再生成（招待タイプ変更時）

**使用ウィジェット**:

- `QrImageView` (qr_flutter) - QRコード表示

**プロバイダー依存**:

- `qrInvitationServiceProvider` - QR招待サービス

---

### 5. GroupMemberManagementPage 📋

**ファイル**: `lib/pages/group_member_management_page.dart` (640行)

**種類**: ConsumerStatefulWidget

**目的**: グループメンバー管理画面。メンバー一覧、役割管理、招待、ホワイトボードアクセス

**主要機能**:

- **メンバー一覧表示**: タイル形式、役割バッジ付き
- **ホワイトボードプレビュー**: グループ共有ホワイトボード表示（上部）
- **個人ホワイトボードアクセス**: MemberTileWithWhiteboard（ダブルタップ）
- **メンバー招待**: 招待ボタン → GroupInvitationPage遷移
- **グループコピー**: コピーボタン → GroupCreationWithCopyDialog表示
- **役割管理**: MemberTileWithWhiteboard内蔵のロール変更ダイアログ（タップ → ロール選択）
- **メンバー削除**: 削除ボタン（オーナー・管理者のみ、オーナーは削除不可）
- **権限チェック**: `_canInviteMembers()`, `_canManageMembers()`, `_canRemoveMembers()`

> **Note**: `MemberRoleManagementWidget`は廃止。ロール変更は`MemberTileWithWhiteboard`内のダイアログで行う。

**ナビゲーション**:

- `SharedGroupPage` → グループリストの⚙️ボタン経由
- `GroupInvitationPage` → 招待ボタン経由
- `WhiteboardEditorPage` → ホワイトボードタップ経由

**特徴**:

- ✅ リアルタイム更新（allGroupsProviderでメンバー情報取得）
- ✅ 役割ベースアクセス制御（オーナー・管理者・パートナー・メンバー）
- ✅ ホワイトボード統合（グループ＋個人）
- ✅ 役割ラベル・ダイアログテキストの多言語対応（l10n）

**使用ウィジェット**:

- `WhiteboardPreviewWidget` - グループホワイトボードプレビュー
- `MemberTileWithWhiteboard` - メンバータイル＋個人ホワイトボード＋ロール変更ダイアログ
- `GroupCreationWithCopyDialog` - グループコピーダイアログ

**プロバイダー依存**:

- `allGroupsProvider` - グループ情報取得
- `authStateProvider` - 現在ユーザー（権限判定用）

---

### 6. WhiteboardEditorPage 🎨

**ファイル**: `lib/pages/whiteboard_editor_page.dart` (1556行)

**種類**: ConsumerStatefulWidget

**目的**: ホワイトボード編集画面。フルスクリーン、リアルタイム同期、編集ロック管理

**主要機能**:

- **描画エンジン**: Signatureパッケージ（CustomPaint + SignatureController）
- **レイヤーシステム**:
  - 背景レイヤー: CustomPaintで保存済みストローク描画
  - 前景レイヤー: Signatureで現在の描画セッション
- **2段構成ツールバー**:
  - 上段: 色選択（6色）＋モード切り替え
  - 下段: 線幅5段階＋ズーム（±ボタン）＋全消去
- **編集ロック**:
  - 自分が編集開始 → ロック取得
  - 他ユーザーが編集中 → ロック表示、読み取り専用
  - 30秒タイムアウト → 自動解放
- **Undo/Redo履歴**: 履歴スタック管理（最大50履歴）
- **差分保存**:
  - 未保存ストローク追跡（`_unsavedStrokeIds`）
  - 差分送信で90%ネットワーク削減
- **リアルタイム同期**: Firestore `snapshots()`でストローク監視

**ナビゲーション**:

- `GroupMemberManagementPage` → ホワイトボードプレビュータップ経由
- `MemberTileWithWhiteboard` → 個人ホワイトボードダブルタップ経由

**特徴**:

- ✅ 固定キャンバスサイズ（1280x720、16:9比率）
- ✅ 複数色ストローク対応（ストローク毎に色・線幅保持）
- ✅ ペンアップ時の自動ストローク分割
- ✅ 編集ロックによる同時編集制御
- ✅ プラットフォーム別対応（Windows: 通常update、Android/iOS: トランザクション）
- ✅ カスタム色対応（設定から読み込み）
- ✅ プライバシー切り替え（グループ共有 ⇄ 個人専用）

**使用ウィジェット**:

- `Signature` (signatureパッケージ) - 描画UI
- なし（全て自前実装）

**プロバイダー依存**:

- `whiteboardProvider` - ホワイトボードデータ
- `authStateProvider` - 現在ユーザー
- `userSettingsProvider` - カスタム色設定
- `whiteboardEditLockProvider` - 編集ロックサービス

---

### 7. NotificationHistoryPage 📊

**ファイル**: `lib/pages/notification_history_page.dart` (423行)

**種類**: ConsumerStatefulWidget

**目的**: 通知履歴画面。Firestore通知データをリアルタイム表示、既読管理

**主要機能**:

- **リアルタイム通知表示**: StreamBuilderでFirestore `snapshots()` 監視
- **通知タイプ別表示**:
  - `listCreated`: 緑アイコン（playlist_add）
  - `listDeleted`: 赤アイコン（delete）
  - `listRenamed`: 青アイコン（edit）
  - `groupMemberAdded`: 紫アイコン（person_add）
  - `itemAdded`: 緑アイコン（add_shopping_cart）
  - その他: グレーアイコン（notifications）
- **時間差表示**: たった今、3分前、2日前、1週間前
- **既読管理**:
  - タップで既読マーク
  - チェックボタンで既読マーク
  - 既読通知の一括削除
- **エラーハンドリング**: インデックスエラー詳細表示

**ナビゲーション**:

- `SettingsPage` → 通知設定パネルの「通知履歴を見る」ボタン経由

**特徴**:

- ✅ Firestoreリアルタイムリスナー（最新100件）
- ✅ 未読/既読状態管理（`read`フィールド）
- ✅ Firebase Console URLリンク表示（インデックスエラー時）
- ✅ 通知タイプ別アイコン・色カスタマイズ

**使用ウィジェット**:

- なし（全て自前実装）

**プロバイダー依存**:

- `authStateProvider` - 現在ユーザー（userId取得）

**Firestore依存**:

- Collection: `notifications`
- Index: `userId + read + timestamp (desc)`

---

### 8. ErrorHistoryPage 📊

**ファイル**: `lib/pages/error_history_page.dart` (487行)

**種類**: ConsumerStatefulWidget

**目的**: エラー履歴画面。SharedPreferencesベースのローカルエラーログ表示

**主要機能**:

- **エラーログ表示**: SharedPreferencesから最新20件取得
- **エラータイプ別表示**:
  - `permission`: 赤アイコン（lock）
  - `network`: オレンジアイコン（wifi_off）
  - `sync`: 青アイコン（sync_problem）
  - `validation`: 黄色アイコン（warning）
  - `operation`: グレーアイコン（error）
- **時間差表示**: たった今、3分前、2時間前
- **既読管理**:
  - タップで既読マーク
  - 既読エラーの一括削除
- **再読み込み**: 更新ボタン

**ナビゲーション**:

- `SettingsPage` → エラー履歴ボタン経由

**特徴**:

- ✅ ローカルストレージ完結（SharedPreferences）
- ✅ コストゼロ（Firestore不使用）
- ✅ 最新20件自動保存
- ✅ エラータイプ別アイコン・色カスタマイズ

**使用ウィジェット**:

- なし（全て自前実装）

**プロバイダー依存**:

- なし（ErrorLogService直接使用）

---

### 9. NewsPage 📖

**ファイル**: `lib/pages/news_page.dart` (194行)

**種類**: ConsumerStatefulWidget

**目的**: ニュース・特売情報表示画面。位置情報ベースの情報提供

**主要機能**:

- **現在地表示**: Geolocatorで位置情報取得、緯度経度表示
- **位置情報ベース広告**: AdServiceで30km圏内広告優先表示
- **ニュース表示**: 今後の拡張ポイント（現在はプレースホルダー）
- **特売情報**: 今後の拡張ポイント

**ナビゲーション**:

- `BottomNavigationBar` → ニュースタブ経由（将来実装予定）

**特徴**:

- ✅ 位置情報取得（LOW精度）
- ✅ AdService統合
- ✅ カード形式のUI

**使用ウィジェット**:

- なし（全て自前実装）

**プロバイダー依存**:

- `adServiceProvider` - 位置情報取得

---

### 10. PremiumPage 💎

**ファイル**: `lib/pages/premium_page.dart` (491行)

**種類**: ConsumerWidget

**目的**: プレミアムプラン管理画面。サブスクリプション状態表示、プラン選択

**主要機能**:

- **プレミアムステータス表示**: 現在のプラン、有効期限
- **広告プレビュー**: 非プレミアムユーザー向け広告表示
- **特典一覧**:
  - 広告非表示
  - 複数グループ作成（無制限）
  - 優先サポート
  - 今後の新機能優先アクセス
- **料金プラン**:
  - 月額: 300円
  - 年額: 3000円（2ヶ月分お得）
- **デバッグコントロール**:
  - プレミアム状態トグル
  - 有効期限設定
  - 購入ウィジェット表示

**ナビゲーション**:

- `SettingsPage` → プレミアムプラン管理ボタン経由

**特徴**:

- ✅ プレミアム状態可視化（緑色/オレンジ色カード）
- ✅ AdBannerWidget統合（非プレミアム時）
- ✅ 購入UI統合（Google Play Billing、将来実装）

**使用ウィジェット**:

- `AdBannerWidget` - 広告プレビュー表示

**プロバイダー依存**:

- `subscriptionProvider` - サブスクリプション状態管理

---

### 11. HelpPage 📖

**ファイル**: `lib/pages/help_page.dart` (824行)

**種類**: ConsumerStatefulWidget

**目的**: ヘルプページ。ユーザーガイド、検索機能、UI操作説明

**主要機能**:

- **検索機能**: テキスト検索でヘルプセクションをフィルタリング
- **ヘルプセクション**:
  - はじめに（概要、主な機能）
  - UI操作ガイド（画面別操作説明）
  - グループ管理（作成、選択、削除）
  - ショッピングリスト（リスト作成、アイテム追加）
  - QR招待（QRコード生成、スキャン）
  - ホワイトボード（描画、保存、共有）
  - 通知（通知設定、履歴確認）
  - トラブルシューティング（同期エラー、表示エラー）
- **外部マークダウンコンテンツ**: assetsからロード（将来実装）

**ナビゲーション**:

- `SettingsPage` → ヘルプボタン経由

**特徴**:

- ✅ 検索機能（キーワードマッチング）
- ✅ セクション折りたたみ（ExpansionTile）
- ✅ マークダウン対応（将来実装）

**使用ウィジェット**:

- なし（全て自前実装）

**プロバイダー依存**:

- なし

---

## テスト・デバッグページ（Test/Debug Pages）

### 12. TestGroupPage 🧪

**ファイル**: `lib/pages/test_group_page.dart` (114行)

**種類**: ConsumerWidget

**目的**: グループ選択テストページ。UIコンポーネントの動作確認

**主要機能**:

- **グループ選択ドロップダウンテスト**: 3つのサンプルグループ
- **ボタンテスト**: タップ動作確認、SnackBar表示
- **ログ出力**: AppLogger.info()でタップイベントログ

**使用場所**: 開発・テスト環境のみ

**特徴**:

- ✅ シンプルなUI確認用
- ✅ ログ出力で動作検証

---

### 13. DebugEmailTestPage 🧪

**ファイル**: `lib/pages/debug_email_test_page.dart` (732行)

**種類**: StatefulWidget

**目的**: メール送信テストページ。Firestore Email Extension動作確認

**主要機能**:

- **メール送信フォーム**: 宛先、件名、本文入力
- **Firestore `mail` collection書き込み**: Extension経由でメール送信
- **送信ステータス監視**: `delivery.state`フィールド監視（PENDING/SUCCESS/ERROR）
- **エラー詳細表示**: `delivery.error`フィールド内容表示
- **Firebase診断情報**: FirebaseDiagnosticsヘルパー使用

**使用場所**: 開発・デバッグ環境のみ

**特徴**:

- ✅ Firestore Email Extension検証
- ✅ リアルタイム送信ステータス監視
- ✅ 詳細なエラー情報表示

---

### 14. EnhancedInvitationTestPage 🧪

**ファイル**: `lib/pages/enhanced_invitation_test_page.dart` (378行)

**種類**: ConsumerStatefulWidget

**目的**: 拡張招待システムテストページ。複数グループ招待、階層構造テスト

**主要機能**:

- **複数グループ招待**: MultiGroupInvitationDialog統合
- **階層グループ作成**: 親グループ指定、子グループ作成
- **拡張グループプロバイダー**: enhancedGroupProvider使用
- **メール招待**: EnhancedInvitationService統合

**使用場所**: 開発・テスト環境のみ

**特徴**:

- ✅ 拡張招待機能検証
- ✅ グループ階層構造検証

---

### 15. HybridSyncTestPage 🧪

**ファイル**: `lib/pages/hybrid_sync_test_page.dart` (810行)

**種類**: ConsumerStatefulWidget

**目的**: ハイブリッド同期システムテストページ。Firestore ⇄ Hive同期検証

**主要機能**:

- **同期ステータス表示**: SyncStatusWidget統合
- **Firestore環境情報**: プロジェクトID、コレクション名表示
- **グループCRUDテスト**: 作成、取得、更新、削除
- **Firestore直接書き込み**: テストグループ作成
- **Hive直接読み取り**: ローカルキャッシュ確認
- **同期トリガー**: 手動同期実行

**使用場所**: 開発・テスト環境のみ

**特徴**:

- ✅ Firestore-firstアーキテクチャ検証
- ✅ Hiveキャッシュ動作確認
- ✅ 同期タイミング検証

---

### 16. SharedGroupPage 🧪

**ファイル**: `lib/pages/shared_group_page.dart` (206行)

**種類**: ConsumerStatefulWidget

**目的**: グループ管理画面（旧UI）。GroupListWidget統合版

**主要機能**:

- **グループリスト表示**: GroupListWidget使用
- **シークレットモード対応**: dataVisibilityProviderでアクセス制御
- **QRスキャナー起動**: QRScannerScreen遷移
- **新規グループ作成**: GroupCreationWithCopyDialog表示
- **FABボタン**: QRスキャナー + グループ作成

**使用場所**: 本番環境（代替UI）

**特徴**:

- ✅ セキュリティプロバイダー統合
- ✅ GroupListWidget再利用

---

### 17. SharedGroupPageSimple 🧪

**ファイル**: `lib/pages/shared_group_page_simple.dart` (144行)

**種類**: ConsumerWidget

**目的**: グループ管理画面（簡易版）。シンプルなUI構成

**主要機能**:

- **グループ選択**: GroupSelectorWidget使用
- **グループ詳細表示**: 選択中グループの情報表示
- **グループ追加ダイアログ**: シンプルなダイアログUI

**使用場所**: 開発・テスト環境のみ

**特徴**:

- ✅ IntrinsicHeightでドロップダウン動的サイズ
- ✅ ConsumerWidgetでシンプルな実装

---

## 📊 統計情報

### ページタイプ別分類

| カテゴリ                   | 個数 | 主要ページ                                                                                                                |
| -------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------- |
| **メイン画面**             | 1    | HomePage                                                                                                                  |
| **データ表示・管理画面**   | 4    | SharedListPage, GroupMemberManagementPage, NewsPage, PremiumPage                                                          |
| **設定・管理画面**         | 1    | SettingsPage                                                                                                              |
| **編集・作成画面**         | 2    | WhiteboardEditorPage, GroupInvitationPage                                                                                 |
| **履歴・統計画面**         | 2    | NotificationHistoryPage, ErrorHistoryPage                                                                                 |
| **情報・ヘルプ画面**       | 1    | HelpPage                                                                                                                  |
| **テスト・デバッグページ** | 6    | TestGroupPage, DebugEmailTestPage, EnhancedInvitationTestPage, HybridSyncTestPage, SharedGroupPage, SharedGroupPageSimple |

### ウィジェットタイプ別

| タイプ                     | 個数 |
| -------------------------- | ---- |
| **ConsumerStatefulWidget** | 11   |
| **ConsumerWidget**         | 3    |
| **StatefulWidget**         | 3    |

### 行数統計（Top 5）

| ページ                   | 行数 |
| ------------------------ | ---- |
| **SettingsPage**         | 2665 |
| **WhiteboardEditorPage** | 1902 |
| **SharedListPage**       | 1181 |
| **HomePage**             | 931  |
| **HelpPage**             | 824  |

---

## 🔗 ナビゲーション構造

### BottomNavigationBar（メインナビゲーション）

```
TabBar:
  [0] ホーム → HomePage
  [1] グループ → SharedGroupPage
  [2] 買い物リスト → SharedListPage
  [3] 設定 → SettingsPage
```

### 主要画面遷移

```
HomePage
├─ サインアップ → Firebase Auth登録
└─ サインイン → Firebase Auth認証

SharedListPage
├─ SharedListHeaderWidget → グループ・リスト選択
└─ SharedItemEditModal → アイテム編集

SettingsPage
├─ NotificationHistoryPage → 通知履歴
├─ ErrorHistoryPage → エラー履歴
├─ PremiumPage → プレミアムプラン
└─ HelpPage → ヘルプ

SharedGroupPage
├─ GroupMemberManagementPage → メンバー管理
│   ├─ GroupInvitationPage → QR招待
│   └─ WhiteboardEditorPage → ホワイトボード編集
└─ GroupCreationWithCopyDialog → グループ作成

GroupInvitationPage
└─ AcceptInvitationWidget（QRスキャナー） → 招待受諾
```

---

## 🎯 重要な設計パターン

### 1. 認証状態管理

**全ページ共通**:

```dart
final authState = ref.watch(authStateProvider);
authState.when(
  data: (user) {
    final isAuthenticated = user != null;
    // 認証状態に応じたUI表示
  },
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => ErrorWidget(err),
);
```

### 2. カレントグループ・リスト管理

**SharedListPage, GroupMemberManagementPage**:

```dart
final selectedGroupId = ref.watch(selectedGroupIdProvider);
final currentList = ref.watch(currentListProvider);

// グループ変更検出
@override
void didChangeDependencies() {
  if (_previousGroupId != currentGroupId) {
    ref.read(currentListProvider.notifier).clearSelection();
  }
}
```

### 3. リアルタイム同期

**WhiteboardEditorPage, NotificationHistoryPage**:

```dart
StreamBuilder<Whiteboard?>(
  stream: repository.watchWhiteboard(groupId, whiteboardId),
  builder: (context, snapshot) {
    final data = snapshot.data;
    // リアルタイム更新UI
  },
)
```

### 4. エラーハンドリング

**全ページ共通**:

```dart
try {
  await repository.operation();
} catch (e, stackTrace) {
  AppLogger.error('エラー: $e', stackTrace);
  await ErrorLogService.logOperationError('操作名', 'エラー: $e');
  SnackBarHelper.showError(context, 'エラーが発生しました');
}
```

### 5. ダイアログパターン

**SharedListPage, GroupInvitationPage**:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => SharedItemEditModal(
    onSave: (item) {
      repository.addSingleItem(listId, item);
      Navigator.pop(context);
    },
  ),
);
```

### 6. Firestore-First読み込み

**HomePage, SharedListPage**:

```dart
// サインイン時
await ref.read(forceSyncProvider.future); // Firestore → Hive同期
ref.invalidate(allGroupsProvider); // プロバイダー無効化
await Future.delayed(const Duration(milliseconds: 500)); // UI更新待機
```

---

## 🚀 今後の拡張ポイント

### 高優先度

1. **NewsPage強化**: ニュースコンテンツ配信システム実装
2. **PremiumPage統合**: Google Play Billing実装、決済フロー
3. **HelpPage拡張**: マークダウンコンテンツ動的ロード

### 中優先度

4. **通知機能拡充**: プッシュ通知、バックグラウンド処理
5. **エラーログFirestore連携**: ErrorHistoryPageのクラウド同期
6. **ホワイトボード機能拡張**: テンプレート、エクスポート

### 低優先度

7. **テストページの本番環境除外**: ビルド時の条件分岐
8. **UI/UXの統一**: マテリアルデザイン3対応

---

## 📖 関連ドキュメント

- [データクラスリファレンス](data_classes_reference.md) - 26個のデータモデル
- [ウィジェットクラスリファレンス](widget_classes_reference.md) - 42個のウィジェット
- [Recent Implementations (copilot-instructions.md)](../../.github/copilot-instructions.md) - 実装履歴

---

## 📝 メンテナンスガイド

### 新規ページ追加時の手順

1. `lib/pages/`に新規ファイル作成
2. 本ドキュメントに追加（アルファベット順）
3. ナビゲーション構造図を更新
4. 統計情報を更新

### ページ削除時の手順

1. ファイル削除
2. 本ドキュメントから削除
3. ナビゲーション構造図を更新
4. 依存関係のあるページを確認・修正

### 大規模変更時のチェックリスト

- [ ] 全画面遷移の動作確認
- [ ] 認証フローの動作確認
- [ ] プロバイダー依存関係の確認
- [ ] エラーハンドリングの確認
- [ ] ナビゲーション構造の確認
