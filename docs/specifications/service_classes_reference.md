# サービスクラスリファレンス (Service Classes Reference)

**作成日**: 2026-02-19
**対象**: `lib/services/` 配下の全46サービスクラス
**目的**: ビジネスロジック層の全体像とサービス間連携を体系的に整理

---

## 📚 凡例 (Legend)

- **🔐 認証・ユーザー管理** - 認証フロー、ユーザープロファイル管理
- **👥 グループ・招待管理** - グループCRUD、招待システム、QRコード
- **🔔 通知・コミュニケーション** - リアルタイム通知、バッチ送信
- **🔄 データ同期・移行** - Firestore同期、スキーマ変更対応
- **💾 ストレージ・Hive** - ローカルDB初期化、データバージョン管理
- **🎨 ホワイトボード** - リアルタイム描画、編集ロック
- **📊 フィードバック・品質** - ユーザーフィードバック収集、エラー記録
- **🌐 プラットフォーム統合** - AdMob、Deep Link、Firebase診断
- **🧹 メンテナンス** - データクリーンアップ、定期購入リセット
- **📰 コンテンツ管理** - ニュース配信、位置情報連携

---

## 📋 サービス一覧 (アルファベット順)

### 1. 🔐 AccessControlService

**ファイル**: `lib/services/access_control_service.dart`

**目的**: ロールベースのアクセス制御（RBAC）を提供

**主要機能**:

- グループメンバーの権限チェック（owner/manager/editor/contributor/viewer）
- アイテム追加・編集・削除の可否判定
- リスト作成・削除の可否判定
- メンバー招待の可否判定

**使用場所**:

- `shared_list_page.dart` - アイテム操作権限チェック
- `group_member_management_page.dart` - メンバー管理権限チェック

**特徴**:

- Staticメソッドのみ（状態なし）
- `Permission.canDeleteItem()` 等のビットフラグ権限システムと統合

---

### 2. 📋 AcceptedInvitationService

**ファイル**: `lib/services/accepted_invitation_service.dart`
**行数**: 240行

**目的**: 受諾済み招待データをSharedPreferencesで管理

**主要機能**:

- 招待受諾履歴の保存（groupId + invitationId + acceptedAt）
- 重複招待チェック（同じ招待を再度受諾しない）
- 受諾履歴の取得・削除
- JSON形式での永続化（最大100件）

**使用場所**:

- `qr_invitation_service.dart` - QR招待受諾前の重複チェック
- `accept_invitation_widget.dart` - 招待受諾UI

**特徴**:

- SharedPreferencesベース（Firestore非依存）
- Freezedモデル `AcceptedInvitation` (HiveType 7) と連携

---

### 3. 📢 AdService

**ファイル**: `lib/services/ad_service.dart`
**行数**: 466行

**目的**: AdMob広告統合（バナー・インタースティシャル）

**主要機能**:

- バナー広告の作成・読み込み（`createBannerAd()`）
- インタースティシャル広告の表示（サインイン時等）
- 位置情報ベース広告最適化（30km圏内広告優先）
- 広告表示頻度制限（1日3回、30分間隔）
- ウィジェット提供: `HomeBannerAdWidget`, `LocalNewsAdWidget`

**Providerパターン**: `adServiceProvider`

**使用場所**:

- `home_page.dart` - ホームバナー広告表示
- `news_page.dart` - ローカルニュース広告表示

**特徴**:

- 位置情報キャッシュ（1時間有効）
- テスト/本番広告ID切り替え（環境変数: `ADMOB_APP_ID`, `ADMOB_BANNER_AD_UNIT_ID`）
- バッテリー効率化（位置情報は必要時のみ取得）

**技術詳細**:

- `geolocator` パッケージで位置情報取得（精度: LOW - 市区町村レベル）
- `google_mobile_ads` パッケージでAdMob統合

---

### 4. 📊 AppLaunchService

**ファイル**: `lib/services/app_launch_service.dart`
**行数**: 76行

**目的**: アプリ起動回数を追跡し、フィードバック催促判定に使用

**主要機能**:

- 起動回数カウント（SharedPreferences）
- フィードバック送信済みフラグ管理
- 起動回数リセット（デバッグ用）

**使用場所**:

- `app_initialize_widget.dart` - アプリ起動時に自動カウント
- `feedback_prompt_service.dart` - 催促判定で起動回数参照

**特徴**:

- Staticメソッド（状態なし）
- 起動回数は永続化（アプリ再インストールで初期化）

---

### 5. 🔐 AuthenticationService

**ファイル**: `lib/services/authentication_service.dart`
**行数**: 180行

**目的**: Firebase Auth認証フローを統括

**主要機能**:

- サインイン（`signInWithEmailAndPassword()`）
- サインアップ（`signUpWithEmailAndPassword()`）
- サインアウト（`signOut()`）
- 認証後処理（Firestore同期、データバージョンチェック、マイグレーション）

**使用場所**:

- `home_page.dart` - サインイン/サインアップ処理
- `auth_provider.dart` - Riverpod統合

**特徴**:

- Staticメソッドのみ
- サインイン/サインアップ後に自動的にFirestoreGroupSyncServiceを呼び出し
- データバージョン管理統合（DataVersionService）

---

### 6. 📊 DataVersionService

**ファイル**: `lib/services/data_version_service.dart`
**行数**: 104行

**目的**: Hiveデータスキーマバージョン管理とマイグレーション

**主要機能**:

- データバージョンチェック（SharedPreferences: `hive_data_version`）
- スキーマ変更時のHiveクリア（破壊的マイグレーション）
- バージョン不整合検出

**使用場所**:

- `hive_initialization_service.dart` - Hive初期化時にバージョンチェック
- `authentication_service.dart` - 認証後にバージョンチェック

**技術詳細**:

- 現在バージョン: `2` （buyingMemberId追加対応）
- 旧バージョン検出時は全Hiveデータを削除してFirestoreから再同期

**特徴**:

- マイグレーション失敗時のロールバックなし（シンプル設計）

---

### 7. 🌐 DeepLinkService

**ファイル**: `lib/services/deep_link_service.dart`
**行数**: 122行

**目的**: アプリ起動時のディープリンク処理（招待URL等）

**主要機能**:

- ディープリンクURL解析（`parseDeepLink()`）
- 招待リンク処理（`/invite/{invitationId}`パス）
- グループリンク処理（`/group/{groupId}`パス）

**使用場所**:

- `main.dart` - アプリ起動時に初期化（現在未統合）

**特徴**:

- `uni_links` パッケージ統合（現在コメントアウト）
- 将来的な機能拡張用に実装準備済み

---

### 8. 📱 DeviceIdService

**ファイル**: `lib/services/device_id_service.dart`
**行数**: 159行

**目的**: デバイス固有IDプレフィックスを生成（グループID/リストID衝突防止）

**主要機能**:

- プラットフォーム別デバイスID取得（Android/iOS/Windows/Linux/macOS）
- グループID生成（`generateGroupId()` - 例: `a3f8c9d2_1707835200000`）
- リストID生成（`generateListId()` - 例: `a3f8c9d2_f3e1a7b4`）
- SharedPreferences永続化（Windows/Linux/macOS用）

**使用場所**:

- `purchase_group_provider.dart` - グループ作成時
- `hybrid_shared_list_repository.dart` - リスト作成時

**技術詳細**:

- **Recent Fix (2026-02-19)**: iOS版のidentifierForVendor取得失敗時フォールバック実装
  - vendorId nullチェック追加
  - 長さ不足チェック追加
  - フォールバック: `ios` + UUID（5文字）= 8文字

**プラットフォーム別実装**:
| Platform | ID Source | Example | Persistence |
|----------|-----------|---------|-------------|
| Android | androidInfo.id | `a3f8c9d2_` | Factory reset時変更 |
| iOS | identifierForVendor | `f4b7c3d1_` | アプリ削除時変更 |
| Windows | SharedPreferences UUID | `win7a2c4_` | 永続化 |
| Linux | SharedPreferences UUID | `lnx5e9f2_` | 永続化 |
| macOS | SharedPreferences UUID | `mac3d8a6_` | 永続化 |

**特徴**:

- メモリキャッシュ（`_cachedPrefix`）でパフォーマンス最適化
- デバイスID取得失敗時のフォールバック実装

---

### 9. 📱 DeviceSettingsService

**ファイル**: `lib/services/device_settings_service.dart`
**行数**: 31行

**目的**: デバイス固有設定管理（Secret Mode等）

**主要機能**:

- Secret Mode設定の保存・取得（SharedPreferences）
- デバイス設定の初期化

**使用場所**:

- `settings_page.dart` - Secret Mode切り替え

**特徴**:

- Staticメソッドのみ
- 将来的な拡張用の基盤実装

---

### 10. 📧 EmailManagementService

**ファイル**: `lib/services/email_management_service.dart`
**行数**: 102行

**目的**: メールアドレス変更・プロファイル更新

**主要機能**:

- メールアドレス変更（`updateEmail()`）
- Firebase Auth + Firestore + SharedPreferences三層更新
- 結果モデル: `SavedEmailResult` (成功/失敗/エラー内容)

**使用場所**:

- `settings_page.dart` - メール変更UI（現在未統合）

**特徴**:

- Firebase Auth requires-recent-login エラー対応（再認証必要）

---

### 11. 🧪 EmailTestService

**ファイル**: `lib/services/email_test_service.dart`
**行数**: 259行

**目的**: パスワードリセットメール送信テスト・デバッグ

**主要機能**:

- テストメール送信（Firebase Extension: firestore-send-email）
- メール送信履歴表示（Firestore `mail` コレクション）
- 送信状態確認（PENDING/SUCCESS/ERROR）

**使用場所**:

- `debug_email_test_page.dart` - メールテスト画面

**技術詳細**:

- Firebase Extension依存: `firestore-send-email`
- SMTP設定: `extensions/firestore-send-email.env` (Git管理外)

**特徴**:

- 開発・デバッグ専用機能

---

### 12. 🎯 EnhancedInvitationService

**ファイル**: `lib/services/enhanced_invitation_service.dart`
**行数**: 335行

**目的**: 拡張招待機能（複数グループ同時招待、友達招待最適化）

**主要機能**:

- 複数グループ同時招待（`inviteToMultipleGroups()`）
- 友達招待専用機能（Friend招待最適化）
- グループ選択UI統合（`GroupInvitationOption`, `GroupInvitationData`）
- 結果モデル: `InvitationResult`, `PendingInvitation`

**使用場所**:

- `multi_group_invitation_dialog.dart` - 複数グループ招待UI
- `enhanced_invitation_test_page.dart` - テスト画面

**特徴**:

- QRInvitationServiceの上位レイヤー
- 友達招待専用パス（Individual/Friend招待タイプを区別）
- 複数招待のトランザクション処理

---

### 13. 🔥 ErrorLogService

**ファイル**: `lib/services/error_log_service.dart`
**行数**: 187行

**目的**: エラーログをSharedPreferencesに保存・管理（Firestore非依存）

**主要機能**:

- エラーログ保存（`logError()`, `logSyncError()`, `logNetworkError()`, `logValidationError()`, `logOperationError()`）
- 最新20件のみ保持（FIFO方式）
- エラーログ取得・既読化・削除
- エラータイプ分類（permission/network/sync/validation/operation）

**使用場所**:

- `error_history_page.dart` - エラー履歴表示
- `sync_service.dart` - Firestore同期エラー記録
- `firestore_shared_list_repository.dart` - CRUD失敗記録

**Recent Implementation (2026-01-07)**:

- 全リポジトリ層のcatchブロックにErrorLogService統合
- タイムアウトエラー・権限エラー・ネットワークエラーを分類記録

**特徴**:

- ローカル完結（コストゼロ）
- JSON形式で永続化
- エラートラブルシューティング支援

---

### 14. 📊 FeedbackPromptService

**ファイル**: `lib/services/feedback_prompt_service.dart`
**行数**: 83行

**目的**: ユーザーフィードバック収集の催促タイミング判定

**主要機能**:

- テスト実施状態チェック（Firestore: `/testingStatus/active`）
- 催促タイミング判定（5回目起動、その後20回ごと）
- テスト状態手動設定（`setTestingActive()`）

**使用場所**:

- `app_initialize_widget.dart` - アプリ起動時に催促判定
- `settings_page.dart` - テスト状態確認

**催促ロジック**:

- `isTestingActive = false` → 催促なし
- 5回起動 → 初回催促
- その後20回ごと（25回、45回、65回...）

**特徴**:

- Firestoreフラグ管理（クローズドベータテスト期間のみ有効）

---

### 15. 📊 FeedbackStatusService

**ファイル**: `lib/services/feedback_status_service.dart`
**行数**: 60行

**目的**: フィードバック送信済みフラグ管理

**主要機能**:

- フィードバック送信済みフラグの保存・取得（SharedPreferences）
- フラグリセット（デバッグ用）

**使用場所**:

- `app_initialize_widget.dart` - フィードバック送信状態確認
- `settings_page.dart` - フィードバックリセット

**特徴**:

- AppLaunchServiceと連携してフィードバック催促制御

---

### 16. 🔥 FirebaseDiagnosticsService

**ファイル**: `lib/services/firebase_diagnostics_service.dart`
**行数**: 151行

**目的**: Firebase/Firestore接続診断・トラブルシューティング

**主要機能**:

- Firebase初期化状態確認（`checkFirebaseInitialization()`）
- Firestore接続テスト（`testFirestoreConnection()`）
- 認証状態確認（`checkAuthentication()`）
- 総合診断（`runDiagnostics()`）
- 診断結果モデル: `DiagnosticsResult`, `ConnectionTestResult`

**使用場所**:

- `settings_page.dart` - Firebase診断UI
- デバッグ・トラブルシューティング時

**特徴**:

- 開発・デバッグ専用機能
- ネットワーク接続問題の切り分けに有用

---

### 17. 🔄 FirestoreGroupSyncService

**ファイル**: `lib/services/firestore_group_sync_service.dart`
**行数**: 270行

**目的**: Firestore・Hive間のグループデータ同期サービス

**主要機能**:

- サインイン時グループ同期（`syncGroupsOnSignIn()`）
- 特定グループ同期（`syncSpecificGroup()`）
- 全ての参加グループのフェッチ（`_fetchUserGroups()`）

**使用場所**:

- `authentication_service.dart` - 認証後に自動実行
- `user_initialization_service.dart` - ユーザー初期化時

**特徴**:

- Firestore `SharedGroups` コレクションから `allowedUid` でクエリ
- dev環境ではスキップ（prod環境のみ動作）

**技術詳細**:

- `allowedUid array-contains` クエリでグループフィルタリング
- 削除済みグループ（`isDeleted = true`）を除外

---

### 18. 🔄 FirestoreMigrationService

**ファイル**: `lib/services/firestore_migration_service.dart`
**行数**: 109行

**目的**: Firestoreスキーマ変更時のマイグレーション統括

**主要機能**:

- スキーマバージョン確認（Firestore: `/metadata/version`）
- マイグレーション実行（`runMigrations()`）
- 現在バージョン管理

**使用場所**:

- `authentication_service.dart` - 認証後にマイグレーションチェック

**特徴**:

- 将来的なスキーマ変更対応の基盤
- 現在マイグレーション未実装（V1のみ）

---

### 19. 📰 FirestoreNewsService

**ファイル**: `lib/services/firestore_news_service.dart`
**行数**: 224行

**目的**: ニュース・セール情報をFirestoreから配信

**主要機能**:

- ニュース記事取得（公開済み・有効期限内のみ）
- 位置情報ベースフィルタリング（30km圏内ニュース優先）
- AdMob広告統合（ニュース記事間に広告表示）

**使用場所**:

- `news_page.dart` - ニュース詳細表示
- `home_page.dart` - ホームニュースパネル

**技術詳細**:

- Firestore `news` コレクション
- フィールド: `title`, `content`, `isPublished`, `publishedAt`, `expiresAt`, `targetLocations`
- 位置情報照合: Haversine式で30km圏内判定

**特徴**:

- AdService統合（広告付きニュース配信）
- 位置情報キャッシュ（1時間有効）

---

### 20. 🔐 FirestoreUserNameService

**ファイル**: `lib/services/firestore_user_name_service.dart`
**行数**: 282行

**目的**: Firestoreユーザープロファイル（displayName）管理

**主要機能**:

- ユーザー名保存（`saveUserName()`）
- ユーザー名取得（`getUserName()`）
- プロファイル存在確認（`ensureUserProfileExists()`）
- カレントユーザー情報取得（`getCurrentUserInfo()`）

**Firestoreパス**:

- 現行: `/users/{uid}/profile/profile` (階層が深い)
- 将来的改善予定: `/users/{uid}` (シンプル化)

**使用場所**:

- `authentication_service.dart` - サインアップ時にプロファイル作成
- `qr_invitation_service.dart` - 招待時にユーザー名取得
- `notification_service.dart` - 通知送信時にユーザー名取得

**特徴**:

- Firebase Auth displayName との二重管理
- SharedPreferences / UserSettings と三層同期

---

### 21. 👥 GroupManagementService

**ファイル**: `lib/services/group_management_service.dart`
**行数**: 319行

**目的**: グループ関連の処理を管理するサービス

**主要機能**:

- デフォルトグループからユーザー名読み込み（`loadUserNameFromDefaultGroup()`）
- グループメンバー検索（owner優先、email一致優先）
- ユーザー名の優先順位決定

**Providerパターン**: `groupManagementServiceProvider`

**使用場所**:

- `home_page.dart` - サインイン時のユーザー名取得
- `settings_page.dart` - ユーザー名読み込み

**特徴**:

- 複雑なユーザー名取得ロジックの統合
- 認証状態とグループメンバーの照合

---

### 22. 💾 HiveInitializationService

**ファイル**: `lib/services/hive_initialization_service.dart`
**行数**: 145行

**目的**: Hiveローカルデータベースの初期化を統合管理

**主要機能**:

- Hive基本初期化（`initialize()`）
- アダプター登録（SharedGroup, SharedList, UserSettings, Whiteboard等）
- デフォルトBox開封（`sharedGroups`, `sharedLists`, `userSettings`）
- データバージョンチェック（DataVersionService統合）

**使用場所**:

- `main.dart` - アプリ起動最初に実行

**技術詳細**:

- プラットフォーム別初期化パス:
  - Web: IndexedDB
  - モバイル/デスクトップ: `{appDocDir}/hive_db/`
- 登録Adapter: SharedGroupRole(0), SharedGroupMember(1), SharedGroup(2), SharedItem(3), SharedList(4), UserSettings(6), DrawingStroke(15), DrawingPoint(16), Whiteboard(17)

**特徴**:

- アダプター重複登録防止（`Hive.isAdapterRegistered()`チェック）
- Hiveディレクトリ自動作成

---

### 23. 🧹 HiveLockCleaner

**ファイル**: `lib/services/hive_lock_cleaner.dart`
**行数**: 94行

**目的**: Hiveロックファイル（`.lock`）のクリーンアップ

**主要機能**:

- 古いロックファイル検出・削除（7日以上経過）
- ロックファイル一覧取得（`findLockFiles()`）
- クリーンアップ実行（`cleanupOldLocks()`）

**使用場所**:

- デバッグ・メンテナンス時（現在自動実行なし）

**特徴**:

- Hiveデータベースのロック問題解決用
- 開発・デバッグ専用機能

---

### 24. 👁️ InvitationMonitorService

**ファイル**: `lib/services/invitation_monitor_service.dart`
**行数**: 277行

**目的**: Firestore招待データをリアルタイム監視

**主要機能**:

- 招待コレクションリスナー起動（`startListening()`）
- 招待受諾・ステータス変更の自動検出
- ローカルキャッシュ更新（Hive同期）

**使用場所**:

- `group_invitation_page.dart` - 招待一覧のリアルタイム更新
- `group_invitation_dialog.dart` - 招待管理UI

**技術詳細**:

- Firestore `invitations` コレクションの `snapshots()` 監視
- クエリ: `where('groupId', isEqualTo:)` + `where('status', isEqualTo: 'pending')`

**特徴**:

- リアルタイム通知統合（招待受諾時に通知送信）
- 複数デバイス間での招待状態同期

---

### 25. 🔐 InvitationSecurityService

**ファイル**: `lib/services/invitation_security_service.dart`
**行数**: 231行

**目的**: 招待のセキュリティ管理（キー生成・検証）

**主要機能**:

- セキュリティキー生成（32文字ランダム文字列）
- 招待ID生成（`groupId-timestamp-random`）
- 招待トークン生成・解析（Base64エンコード）
- セキュリティキー検証（`validateSecurityKey()`）

**Providerパターン**: `invitationSecurityServiceProvider`

**使用場所**:

- `qr_invitation_service.dart` - QR招待データ生成時
- `invitation_service.dart` - 招待作成時

**技術詳細**:

- セキュリティキー: 32文字ランダム（大小英数字）
- トークンペイロード: `{groupId, type, key, inviter, timestamp}`
- 検証: 保存されたキーとの一致確認

**特徴**:

- `crypto` パッケージで暗号学的乱数生成（`Random.secure()`）
- データモデル: `InvitationTokenData`, `InvitationResponse`

---

### 26. 📤 InvitationService

**ファイル**: `lib/services/invitation_service.dart`
**行数**: 446行

**目的**: 招待システムの基本機能提供

**主要機能**:

- 招待作成（`createInvitation()`）
- 招待受諾（`acceptInvitation()`）
- 招待削除（`deleteInvitation()`）
- 招待履歴管理

**使用場所**:

- `group_invitation_dialog.dart` - 招待管理UI
- レガシー招待システム（現在は主に `qr_invitation_service.dart` 使用）

**特徴**:

- InvitationSecurityService統合
- Freezedモデル `Invitation` (Firestore連携)

---

### 27. 🔗 InviteCodeService

**ファイル**: `lib/services/invite_code_service.dart`
**行数**: 112行

**目的**: 招待コード（6桁英数字）生成・検証

**主要機能**:

- 招待コード生成（`generateInviteCode()` - 例: `AB12CD`）
- 招待コード検証（`validateInviteCode()`）
- Firestore `invitations` コレクションとの照合

**使用場所**:

- 招待コード手動入力機能（現在未統合）

**特徴**:

- 6文字大文字英数字（`ABCDEFGHJKLMNPQRSTUVWXYZ23456789` - 混同しやすい文字除外）
- QR招待の代替手段

---

### 28. 🧹 ListCleanupService

**ファイル**: `lib/services/list_cleanup_service.dart`
**行数**: 202行

**目的**: 買い物リストの論理削除アイテムクリーンアップ

**主要機能**:

- 全リストクリーンアップ（`cleanupAllLists()`）
- 指定日数以上経過した削除済みアイテムの物理削除（デフォルト: 30日）
- 自動クリーンアップ（アプリ起動時）
- 手動クリーンアップ（設定画面から）

**使用場所**:

- `app_initialize_widget.dart` - アプリ起動5秒後に自動実行
- `settings_page.dart` - 手動クリーンアップUI

**技術詳細**:

- `SharedList.needsCleanup` getter（削除済み10件以上で true）を参照
- Repository層の `cleanupDeletedItems()` を呼び出し

**特徴**:

- forceCleanupフラグで強制実行オプション
- クリーンアップ結果レポート（削除件数）

---

### 29. 📬 ListNotificationBatchService

**ファイル**: `lib/services/list_notification_batch_service.dart`
**行数**: 306行

**目的**: アイテム変更を5分間隔でバッチ送信（通知頻度抑制）

**主要機能**:

- アイテム追加・削除・購入完了をキューに蓄積
- 5分間隔で通知一括送信（`_sendBatchNotifications()`）
- リスト変更監視（StreamBuilder統合）

**Providerパターン**: `listNotificationBatchServiceProvider`

**使用場所**:

- `user_initialization_service.dart` - サービス起動
- `shared_list_page_v2.dart` - アイテム変更時にキュー追加

**技術詳細**:

- 内部データクラス: `_ListChange` (変更タイプ・タイムスタンプ・メタデータ)
- Timerによる定期実行（5分 = 300秒）

**特徴**:

- 通知スパム防止（5分以内の複数変更を1通にまとめる）
- NotificationService統合

---

### 30. 🔄 NotificationService

**ファイル**: `lib/services/notification_service.dart`
**行数**: 1074行

**目的**: リアルタイム通知システムの中核

**主要機能**:

- 各種通知送信（`sendNotification()`）
- 通知リスナー起動（`startListening()`）
- 通知タイプ別ハンドリング（グループ変更・招待受諾・リスト変更・アイテム変更等）
- グループ削除通知処理（Hive削除 + グループ自動切替）

**Providerパターン**: `notificationServiceProvider`

**通知タイプ（11種類）**:
| タイプ | 用途 | 送信タイミング |
|--------|------|----------------|
| `groupMemberAdded` | グループメンバー追加 | 即時 |
| `groupUpdated` | グループ情報更新 | 即時 |
| `invitationAccepted` | 招待受諾 | 即時 |
| `groupDeleted` | グループ削除 | 即時 |
| `syncConfirmation` | 同期確認 | 即時 |
| `listCreated` | リスト作成 | 即時 |
| `listDeleted` | リスト削除 | 即時 |
| `listRenamed` | リスト名変更 | 即時 |
| `itemAdded` | アイテム追加 | 5分間隔（バッチ） |
| `itemRemoved` | アイテム削除 | 5分間隔（バッチ） |
| `itemPurchased` | 購入完了 | 5分間隔（バッチ） |
| `whiteboardUpdated` | ホワイトボード更新 | 即時 |

**使用場所**:

- `user_initialization_service.dart` - リスナー起動
- `qr_invitation_service.dart` - 招待受諾通知送信
- `group_list_widget.dart` - グループ削除通知送信
- `shared_list_page_v2.dart` - リスト変更通知送信
- `notification_history_page.dart` - 通知履歴表示

**技術詳細**:

- Firestore `notifications` コレクション（サブコレクション）
- クエリ: `where('userId', isEqualTo:) + where('read', isEqualTo: false) + orderBy('timestamp', desc)`
- Firestoreインデックス: `userId + read + timestamp` (複合インデックス必須)

**Recent Implementation (2025-12-25)**:

- グループ削除通知ハンドリング追加（選択中グループが削除された場合のフォールバック）
- 通知履歴Firestoreインデックス修正（`timestamp`フィールド追加）

**特徴**:

- マルチデバイス対応（同一ユーザーの複数デバイス間で通知共有）
- 既読管理機能
- 通知データモデル: `NotificationData` クラス

---

### 31. 🔑 PasswordResetService

**ファイル**: `lib/services/password_reset_service.dart`
**行数**: 108行

**目的**: パスワードリセットメール送信（Firebase Auth連携）

**主要機能**:

- パスワードリセットメール送信（`sendPasswordResetEmail()`）
- Firebase Auth Extension統合（`firestore-send-email`）
- 送信結果: `PasswordResetResult` (成功/エラー)

**使用場所**:

- `home_page.dart` - パスワードリセットUI
- `settings_page.dart` - パスワード変更UI

**技術詳細**:

- Firebase Auth `sendPasswordResetEmail()` API
- 日本語メールテンプレート（Firebase Console設定）

**特徴**:

- Firebase Auth標準機能活用

---

### 32. 📤 PendingInvitationService

**ファイル**: `lib/services/pending_invitation_service.dart`
**行数**: 136行

**目的**: 未処理招待を管理（レガシー機能）

**主要機能**:

- 未処理招待の保存・取得（SharedPreferences）
- 招待処理結果モデル: `InvitationProcessResult`

**使用場所**:

- 現在未使用（QRInvitationServiceに移行）

**特徴**:

- レガシーコード（削除候補）

---

### 33. 🔄 PeriodicPurchaseService

**ファイル**: `lib/services/periodic_purchase_service.dart`
**行数**: 213行

**目的**: 定期購入アイテムの自動リセット

**主要機能**:

- 全リストの定期購入アイテムチェック（`resetPeriodicPurchaseItems()`）
- 特定リストのリセット（`resetPeriodicPurchaseItemsForList()`）
- リセット条件判定（購入日 + 定期購入間隔 <= 現在日時）

**使用場所**:

- `app_initialize_widget.dart` - アプリ起動5秒後に自動実行
- `settings_page.dart` - 手動リセットUI

**リセット条件**:

- `isPurchased = true`
- `shoppingInterval > 0`
- `purchaseDate + shoppingInterval日 <= 現在日時`

**リセット動作**:

- `isPurchased` → `false`
- `purchaseDate` → `null`
- Firestore + Hive両方更新

**特徴**:

- 定期購入アイテムの自動サイクル管理
- デバッグ情報提供（`getPeriodicPurchaseInfo()`）

---

### 34. 📲 QRInvitationService

**ファイル**: `lib/services/qr_invitation_service.dart`
**行数**: 1101行（最大規模）

**目的**: QRコード招待システムの完全実装

**主要機能**:

- セキュアQR招待データ作成（`createQRInvitationData()`）
- QR招待受諾（`acceptQRInvitation()`）
- QRデータエンコード・デコード（v3.1軽量版 - 150文字）
- QRコード画像生成（`generateQRWidget()` - 250px）
- 招待使用回数管理（最大5回、currentUses/maxUses）

**Providerパターン**: `qrInvitationServiceProvider`

**使用場所**:

- `group_invitation_dialog.dart` - QR招待生成UI
- `accept_invitation_widget.dart` - QRスキャナー
- `qr_code_panel_widget.dart` - QRパネル統合

**QRデータ構造（v3.1 - 軽量版）**:

```json
{
  "invitationId": "abc123",
  "sharedGroupId": "group_xyz",
  "securityKey": "secure_key",
  "type": "secure_qr_invitation",
  "version": "3.1"
}
```

**旧v3.0との違い**:

- Before: 17フィールド ~600文字（全データQR埋め込み）
- After: 5フィールド ~150文字（Firestore参照へ変更）
- QRサイズ: 200px → 250px（読み取り精度向上）
- データ削減: 75%削減

**招待処理フロー**:

1. QRデータデコード（v3.1: 軽量データ）
2. Firestoreから詳細取得（`invitations/{invitationId}`）
3. セキュリティキー検証
4. グループメンバー追加
5. 招待使用回数インクリメント（`currentUses++`）
6. 招待元に通知送信

**Recent Implementation (2025-12-06)**:

- v3.1軽量QRデータフォーマット実装（Firestore参照型）
- 後方互換性維持（v3.0, v2.0対応）
- Windows版手動入力対応（`windows_qr_scanner_simple.dart`連携）

**Recent Fix (2025-12-16)**:

- 重複招待チェック実装（同じグループに再度招待不可）
- `allowedUid`配列チェックで既存メンバー判定

**Recent Fix (2025-12-25)**:

- 招待受諾通知システム完全修正（permission-denied, インデックスエラー解消）
- 招待元側のみが招待使用回数更新（受諾側は通知送信のみ）

**特徴**:

- 最大級のサービス（1101行）
- InvitationSecurityService統合
- NotificationService統合
- AcceptedInvitationService統合（重複防止）

---

### 35. 💾 SharedListDataMigrationService

**ファイル**: `lib/services/shopping_list_data_migration_service.dart`
**行数**: 332行

**目的**: SharedListデータ構造移行（List<SharedItem> → Map<String, SharedItem>）

**主要機能**:

- 移行状況チェック（`checkMigrationStatus()`）
- Map形式への変換（`migrateToMapFormat()`）
- 自動バックアップ作成（Hive別Box: `old_sharedLists`）

**使用場所**:

- `settings_page.dart` - データメンテナンスUI

**移行理由**:

- 差分同期実現（アイテム単位更新 - 90%ネットワーク削減）
- O(n) → O(1) 検索性能向上

**技術詳細**:

- 旧形式: `List<SharedItem> items`
- 新形式: `Map<String, SharedItem> items` （itemIdをキーに）

**特徴**:

- 自動バックアップ（移行失敗時のロールバック用）
- 移行スキップオプション（`skipItemIdGeneration`）

---

### 36. 💾 SharedListMigrationService

**ファイル**: `lib/services/shopping_list_migration_service.dart`
**行数**: 75行

**目的**: SharedListスキーマ変更時のマイグレーション（レガシー）

**主要機能**:

- スキーマ変更検出
- マイグレーション実行

**使用場所**:

- 現在未使用（SharedListDataMigrationServiceに移行）

**特徴**:

- レガシーコード

---

### 37. 📝 SignupService

**ファイル**: `lib/services/signup_service.dart`
**行数**: 304行

**目的**: サインアップ処理の詳細実装

**主要機能**:

- サインアップフロー統括（`signUp()`）
- ユーザー名・メールアドレスのFirestore保存
- デフォルトグループ作成
- プロバイダー無効化

**使用場所**:

- `signup_dialog.dart` - サインアップUI
- `home_page.dart` - サインアップフロー

**特徴**:

- AuthenticationService統合
- UserInitializationService統合

---

### 38. 🔄 SyncService

**ファイル**: `lib/services/sync_service.dart`
**行数**: 284行

**目的**: Firestore ⇄ Hive データ同期の統括管理

**主要機能**:

- 全グループ同期（`syncAllGroupsFromFirestore()`）
- 特定グループ同期（`syncSpecificGroup()`）
- グループアップロード（`uploadGroupToFirestore()`）
- グループ削除マーク（`markGroupAsDeletedInFirestore()`）
- 同期結果: `SyncResult` (syncedCount, skippedCount)

**Providerパターン**: `syncServiceProvider`

**使用場所**:

- `settings_page.dart` - 手動同期ボタン
- `user_initialization_service.dart` - 自動同期

**技術詳細**:

- タイムアウト設定: 30秒（全グループ同期）、10秒（特定グループ同期）
- エラーハンドリング: TimeoutException, FirebaseException, 一般Exception分類

**Recent Implementation (2026-01-14)**:

- タイムアウト処理追加（30秒/10秒）
- ErrorLogService統合（エラー記録）

**特徴**:

- dev環境ではスキップ（prod環境のみ動作）
- 削除済みグループ除外（`isDeleted = true`）

---

### 39. 🔐 UserInfoService

**ファイル**: `lib/services/user_info_service.dart`
**行数**: 342行

**目的**: ユーザー情報の保存・読み込みを三層管理

**主要機能**:

- ユーザー情報保存（`saveUserInfo()`）
- 三層同期: SharedPreferences + UserSettings(Hive) + FirestoreUserNameService
- ユーザー情報読み込み（`loadUserInfo()`）
- 保存結果: `UserInfoSaveResult`

**使用場所**:

- `home_page.dart` - サインアップ時のユーザー情報保存
- `settings_page.dart` - ユーザー名変更UI

**特徴**:

- 三層同期の統括
- 複雑な優先順位ロジック（Firestore → SharedPreferences → UserSettings）

---

### 40. 🔧 UserInitializationService

**ファイル**: `lib/services/user_initialization_service.dart`
**行数**: 727行（最大級）

**目的**: アプリ起動時・認証時のユーザー初期化統括

**主要機能**:

- Firebase Auth状態監視（`startAuthStateListener()`）
- ユーザープロファイル同期（`_syncUserProfile()`）
- ユーザーデフォルト初期化（`_initializeUserDefaults()`）
- Firestore→Hive同期（`syncFromFirestoreToHive()`）
- 通知リスナー起動
- サインイン後の自動処理統括

**Providerパターン**: `userInitializationServiceProvider`

**初期化ステップ（STEP0-6）**:

- STEP0: Firestoreから全グループ取得
- STEP1: 削除済みグループ除外
- STEP2: Hive保存 + デフォルトグループ移行（legacy → UID）
- STEP3: allowedUid不一致グループ削除
- STEP4: Hive全データクリア + Firestore再同期
- STEP5: デフォルトグループ作成（存在しない場合）
- STEP6: 初期化完了フラグセット

**使用場所**:

- `app_initialize_widget.dart` - アプリ起動時
- `home_page.dart` - サインイン時

**特徴**:

- 最大規模の初期化ロジック（727行）
- FirestoreGroupSyncService統合
- NotificationService統合
- ListNotificationBatchService統合
- ListCleanupService統合

---

### 41. 🔐 UserNameInitializationService

**ファイル**: `lib/services/user_name_initialization_service.dart`
**行数**: 252行

**目的**: ユーザー名初期化ロジックの統合

**主要機能**:

- Firebase Authからユーザー名取得
- Firestoreプロファイルからユーザー名取得
- SharedPreferencesからユーザー名取得
- デフォルトグループからユーザー名取得
- ユーザー名の優先順位決定

**使用場所**:

- `home_page.dart` - サインイン時のユーザー名初期化

**特徴**:

- 複雑な優先順位ロジック
- FirestoreUserNameService統合

---

### 42. 🔐 UserNameManagementService

**ファイル**: `lib/services/user_name_management_service.dart`
**行数**: 280行

**目的**: ユーザー名変更の統合管理

**主要機能**:

- ユーザー名変更（`updateUserName()`）
- 三層更新: Firebase Auth + Firestore + SharedPreferences
- デフォルトグループのオーナー名更新

**使用場所**:

- `settings_page.dart` - ユーザー名変更UI

**特徴**:

- 三層同期の統括
- GroupManagementService統合

---

### 43. 🔐 UserPreferencesService

**ファイル**: `lib/services/user_preferences_service.dart`
**行数**: 242行

**目的**: SharedPreferencesベースのユーザー設定管理

**主要機能**:

- ユーザーID保存・取得・削除（`saveUserId()`, `getUserId()`）
- ユーザー名保存・取得・削除（`saveUserName()`, `getUserName()`）
- メールアドレス保存・取得・削除
- 全情報クリア（`clearAllUserInfo()`）

**使用場所**:

- ほぼ全てのサービス（ユーザー情報の基本アクセス層）
- `authentication_service.dart`
- `qr_invitation_service.dart`
- `notification_service.dart`

**特徴**:

- Staticメソッドのみ
- SharedPreferencesラッパー
- ユーザー情報の永続化基盤

---

### 44. 🔄 UserProfileMigrationService

**ファイル**: `lib/services/user_profile_migration_service.dart`
**行数**: 145行

**目的**: Firestoreユーザープロファイル構造の変更対応

**主要機能**:

- 旧構造（`/users/{uid}/profile/profile`）から新構造（`/users/{uid}`）へ移行
- プロファイルデータ移行（`migrateUserProfile()`）

**使用場所**:

- 現在未使用（将来的な構造簡素化時に使用予定）

**特徴**:

- 将来的なスキーマ変更対応の基盤

---

### 45. 💾 UserSpecificHiveService

**ファイル**: `lib/services/user_specific_hive_service.dart`
**行数**: 299行

**目的**: ユーザー固有のHive Boxを動的に管理

**主要機能**:

- ユーザー固有Hive Box開封（`openUserBox()` - 例: `sharedGroups_uid123`）
- アダプター動的登録（`initializeAdapters()`）
- 全ユーザーBox削除（`deleteAllUserBoxes()`）

**使用場所**:

- `main.dart` - アプリ起動時のアダプター登録
- 将来的なマルチユーザー対応時に活用予定

**技術詳細**:

- ユーザーごとに独立したHive Box作成
- Box名: `{boxName}_{userId}`

**特徴**:

- マルチユーザー対応の基盤
- 現在は単一ユーザーモード（単一Boxのみ使用）

---

### 46. 🎨 WhiteboardEditLockService

**ファイル**: `lib/services/whiteboard_edit_lock_service.dart`
**行数**: 473行

**目的**: ホワイトボード編集ロック管理（同時編集防止）

**主要機能**:

- 編集ロック取得（`acquireEditLock()` - 1時間有効）
- 編集ロック解放（`releaseEditLock()`）
- ロック状態確認（`checkEditLock()`）
- 編集中ユーザー情報取得（`getEditLockInfo()`）
- 古いロッククリーンアップ（`cleanupLegacyEditLocks()`）

**使用場所**:

- `whiteboard_editor_page.dart` - ホワイトボード編集開始/終了時

**技術詳細**:

- Firestore `whiteboards` サブコレクション内の `editLock` フィールド
- ロック構造: `{userId, userName, createdAt, expiresAt, updatedAt}`
- トランザクション処理（Android/iOS）
- Windows版対策: `runTransaction`でクラッシュするため通常update使用

**Recent Implementation (2026-01-31)**:

- Windows版トランザクション回避実装（`_acquireEditLockWithoutTransaction()`）
- プラットフォーム判定による処理分岐

**特徴**:

- ロック有効期限: 1時間
- 同一ユーザーの場合はロック延長
- 期限切れロック自動削除
- データモデル: `EditLockInfo` クラス

---

## 📊 統計情報

### サービス数統計

| カテゴリ                        | サービス数 | 主要サービス                                                                                       |
| ------------------------------- | ---------- | -------------------------------------------------------------------------------------------------- |
| **🔐 認証・ユーザー管理**       | 10         | AuthenticationService, UserInitializationService, UserPreferencesService, FirestoreUserNameService |
| **👥 グループ・招待管理**       | 9          | QRInvitationService, GroupManagementService, InvitationSecurityService, EnhancedInvitationService  |
| **🔔 通知・コミュニケーション** | 4          | NotificationService, ListNotificationBatchService, InvitationMonitorService                        |
| **🔄 データ同期・移行**         | 7          | SyncService, FirestoreGroupSyncService, SharedListDataMigrationService, FirestoreMigrationService  |
| **💾 ストレージ・Hive**         | 3          | HiveInitializationService, UserSpecificHiveService, HiveLockCleaner                                |
| **🎨 ホワイトボード**           | 1          | WhiteboardEditLockService                                                                          |
| **📊 フィードバック・品質**     | 3          | FeedbackPromptService, FeedbackStatusService, ErrorLogService                                      |
| **🌐 プラットフォーム統合**     | 4          | AdService, DeepLinkService, FirebaseDiagnosticsService, DeviceSettingsService                      |
| **🧹 メンテナンス**             | 3          | ListCleanupService, PeriodicPurchaseService, DataVersionService                                    |
| **📰 コンテンツ管理**           | 2          | FirestoreNewsService, DeviceIdService                                                              |
| **合計**                        | **46**     | -                                                                                                  |

### 規模別統計

| 行数範囲       | サービス数 | 代表例                                                               |
| -------------- | ---------- | -------------------------------------------------------------------- |
| **1000行以上** | 2          | QRInvitationService (1101行), NotificationService (1074行)           |
| **500-999行**  | 2          | UserInitializationService (727行), AdService (466行)                 |
| **300-499行**  | 8          | WhiteboardEditLockService (473行), EnhancedInvitationService (335行) |
| **200-299行**  | 8          | FirestoreGroupSyncService (270行), SyncService (284行)               |
| **100-199行**  | 14         | AuthenticationService (180行), ErrorLogService (187行)               |
| **100行未満**  | 12         | FeedbackPromptService (83行), DeviceSettingsService (31行)           |

**平均行数**: 約250行
**総行数**: 約11,500行（推定）

### プロバイダーパターン統計

| パターン               | サービス数 | 例                                                                   |
| ---------------------- | ---------- | -------------------------------------------------------------------- |
| **Provider**           | 15         | `final xxxServiceProvider = Provider<XxxService>((ref) => ...)`      |
| **StateProvider**      | 2          | `userInitializationStatusProvider`, `firestoreSyncStatusProvider`    |
| **Staticメソッドのみ** | 29         | `AuthenticationService`, `UserPreferencesService`, `ErrorLogService` |

---

## 🔗 重要な設計パターン

### 1. Staticサービスパターン

**目的**: 状態を持たないユーティリティサービス

**例**:

- `AuthenticationService` - Firebase Auth操作
- `UserPreferencesService` - SharedPreferences操作
- `ErrorLogService` - エラーログ記録
- `AccessControlService` - 権限チェック

**特徴**:

- Providerなし
- Staticメソッドのみ
- 依存注入不要

---

### 2. Providerサービスパターン

**目的**: 依存注入とライフサイクル管理

**例**:

```dart
final qrInvitationServiceProvider = Provider<QRInvitationService>((ref) {
  return QRInvitationService(ref);
});

class QRInvitationService {
  final Ref _ref;
  QRInvitationService(this._ref);

  // 他のサービスにアクセス
  InvitationSecurityService get _securityService =>
      _ref.read(invitationSecurityServiceProvider);
}
```

**特徴**:

- Riverpod統合
- 他サービスへの依存アクセス
- テスト容易性

---

### 3. リスナーサービスパターン

**目的**: Firestoreリアルタイム監視

**例**:

- `NotificationService.startListening()` - 通知リスナー
- `InvitationMonitorService.startListening()` - 招待リスナー

**パターン**:

```dart
StreamSubscription? _subscription;

void startListening() {
  _subscription = _firestore
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .listen((snapshot) {
    // データ変更時の処理
  });
}

void stopListening() {
  _subscription?.cancel();
}
```

**特徴**:

- `snapshots()` API使用
- StreamSubscription管理
- dispose時のキャンセル

---

### 4. 三層同期パターン

**目的**: SharedPreferences + Hive + Firestoreの一貫性保証

**例**:

- `UserInfoService.saveUserInfo()` - ユーザー情報三層保存
- `UserNameManagementService.updateUserName()` - ユーザー名三層更新

**パターン**:

```dart
// 1. SharedPreferences保存
await UserPreferencesService.saveUserName(userName);

// 2. Hive保存（UserSettings）
final userSettings = await userSettingsRepository.getUserSettings();
await userSettingsRepository.saveSettings(
  userSettings.copyWith(userName: userName),
);

// 3. Firestore保存
await FirestoreUserNameService.saveUserName(userName);

// 4. Firebase Auth更新
await user.updateDisplayName(userName);
```

**特徴**:

- 複数層の一貫性保証
- 失敗時のロールバック考慮

---

### 5. 初期化統括パターン

**目的**: アプリ起動時の複雑な初期化フロー管理

**例**:

- `UserInitializationService` - ユーザー初期化統括
- `HiveInitializationService` - Hive初期化統括

**パターン**:

```dart
class UserInitializationService {
  // 全体統括メソッド
  Future<void> initialize() async {
    // STEP0: Firestore同期
    await FirestoreGroupSyncService.syncGroupsOnSignIn();

    // STEP1: データバージョンチェック
    await DataVersionService.checkAndMigrateData();

    // STEP2: デフォルトグループ作成
    await _createDefaultGroup();

    // STEP3: リスナー起動
    _notificationService.startListening();
  }
}
```

**特徴**:

- 複数サービスの協調
- ステップ別実行
- エラーハンドリング統合

---

### 6. バッチ送信パターン

**目的**: 通知頻度抑制（スパム防止）

**例**:

- `ListNotificationBatchService` - アイテム変更通知を5分間隔でバッチ送信

**パターン**:

```dart
final List<_ListChange> _pendingChanges = [];
Timer? _batchTimer;

void queueChange(_ListChange change) {
  _pendingChanges.add(change);

  // 5分後にバッチ送信
  _batchTimer ??= Timer(const Duration(minutes: 5), () {
    _sendBatchNotifications();
  });
}

void _sendBatchNotifications() {
  // 同一リスト・同一タイプの変更をまとめる
  final grouped = _groupByListAndType(_pendingChanges);

  for (final entry in grouped.entries) {
    _notificationService.sendNotification(/* ... */);
  }

  _pendingChanges.clear();
  _batchTimer = null;
}
```

**特徴**:

- Timer管理
- 変更キュー蓄積
- グルーピングロジック

---

### 7. プラットフォーム分岐パターン

**目的**: プラットフォーム固有の処理

**例**:

- `DeviceIdService` - iOS/Android/Windows別実装
- `WhiteboardEditLockService` - Windowsトランザクション回避

**パターン**:

```dart
if (Platform.isAndroid) {
  // Android固有処理
  final androidInfo = await deviceInfo.androidInfo;
  prefix = androidInfo.id.substring(0, 8);
} else if (Platform.isIOS) {
  // iOS固有処理（エラーハンドリング込み）
  try {
    final iosInfo = await deviceInfo.iosInfo;
    prefix = iosInfo.identifierForVendor?.substring(0, 8) ?? fallback;
  } catch (e) {
    // iOSフォールバック
    prefix = 'ios' + uuid.v4().substring(0, 5);
  }
} else if (Platform.isWindows) {
  // Windows固有処理
  prefix = 'win' + uuid.v4().substring(0, 5);
}
```

**特徴**:

- プラットフォーム判定
- フォールバック実装
- プラットフォーム別エラーハンドリング

---

## 🔧 アーキテクチャ的価値

### 1. レイヤー分離

- **サービス層**: ビジネスロジック・外部API統合
- **リポジトリ層**: データ永続化（Firestore/Hive）
- **プロバイダー層**: 状態管理（Riverpod）
- **ウィジェット層**: UI表示

→ 関心の分離による保守性向上

---

### 2. 横断的関心事の統合

- **ErrorLogService**: 全リポジトリ層のエラー記録統合
- **NotificationService**: 全機能の通知送信統合
- **UserPreferencesService**: SharedPreferences操作の一元化
- **SyncService**: Firestore同期の統括

→ DRY原則・保守性向上

---

### 3. 疎結合設計

- **Provider依存注入**: サービス間の疎結合化
- **抽象インターフェース**: 将来的な実装切り替え容易
- **Staticメソッド**: 状態なしユーティリティの明確化

→ テスト容易性・拡張性

---

### 4. プラットフォーム対応

- **iOS固有対応**: identifierForVendor取得失敗時のフォールバック
- **Windows固有対応**: runTransactionクラッシュ回避
- **Android/iOS最適化**: 位置情報ベース広告

→ マルチプラットフォーム安定性

---

### 5. パフォーマンス最適化

- **バッチ送信**: 通知頻度抑制（5分間隔）
- **キャッシュ**: DeviceIdService（メモリキャッシュ）、AdService（位置情報1時間キャッシュ）
- **差分同期**: リアルタイム同期最適化

→ ネットワーク効率化・バッテリー効率化

---

## 📝 使用上の注意点

### 1. サービス初期化順序

**重要**: アプリ起動時の初期化順序を遵守

**正しい順序** (`main.dart`):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase初期化（最優先）
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Hive初期化
  await HiveInitializationService.initialize();

  // 3. SharedPreferences初期化（UserPreferencesService使用前に暗黙的実行）

  // 4. AdMob初期化（任意）
  await MobileAds.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

---

### 2. Providerアクセスパターン

**BuildContext内**: `ref.watch()` または `ref.listen()`
**非同期処理内**: `ref.read()`

**例**:

```dart
// ❌ Wrong: build()内でref.read()
Widget build(BuildContext context, WidgetRef ref) {
  final service = ref.read(serviceProvider); // 再ビルドされない
  return Text(service.data);
}

// ✅ Correct: build()内でref.watch()
Widget build(BuildContext context, WidgetRef ref) {
  final service = ref.watch(serviceProvider); // 自動再ビルド
  return Text(service.data);
}

// ✅ Correct: 非同期処理でref.read()
Future<void> onPressed() async {
  final service = ref.read(serviceProvider);
  await service.doSomething();
}
```

---

### 3. Firestoreクエリのインデックス

**NotificationService**: `userId + read + timestamp` 複合インデックス必須

**Firebase Consoleで設定**:

```json
{
  "collectionGroup": "notifications",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "read", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

自動デプロイ: `firebase deploy --only firestore:indexes`

---

### 4. リスナー管理

**必須**: サービス停止時にStreamSubscriptionをキャンセル

**例**:

```dart
class MyService {
  StreamSubscription? _subscription;

  void startListening() {
    _subscription = _firestore.collection('data').snapshots().listen((snapshot) {
      // 処理
    });
  }

  void dispose() {
    _subscription?.cancel(); // ✅ メモリリーク防止
  }
}
```

---

### 5. プラットフォーム判定

**Windows特有問題**: `runTransaction()` クラッシュ回避

**例** (WhiteboardEditLockService):

```dart
if (Platform.isWindows) {
  // Windows: 通常のupdate()を使用
  return await _acquireEditLockWithoutTransaction(...);
}

// Android/iOS: トランザクション使用
return await _firestore.runTransaction<bool>((transaction) async {
  // トランザクション処理
});
```

---

## 🚀 今後の拡張計画

### 1. サービス統合検討

**候補**:

- InvitationService → QRInvitationService統合（レガシー削除）
- PendingInvitationService → 削除（未使用）
- SharedListMigrationService → SharedListDataMigrationService統合

---

### 2. Firestoreスキーマ簡素化

**FirestoreUserNameService**:

- 現行: `/users/{uid}/profile/profile`
- 改善予定: `/users/{uid}` (1階層削減)

---

### 3. Deep Link統合

**DeepLinkService**:

- 現在未統合（コメントアウト）
- 招待URL直接アクセス機能の実装予定

---

### 4. マルチユーザー対応

**UserSpecificHiveService**:

- ユーザーごとに独立したHive Box
- アカウント切り替え機能の基盤

---

### 5. エラーログFirestore連携

**ErrorLogService**:

- 現在SharedPreferencesのみ
- 将来的にFirestoreへの自動送信（デバッグ効率化）

---

## 📚 関連ドキュメント

- **データモデル**: `docs/specifications/data_classes_reference.md` (26クラス)
- **ウィジェット**: `docs/specifications/widget_classes_reference.md` (42ウィジェット)
- **ページ**: `docs/specifications/page_widgets_reference.md` (17ページ)
- **Riverpodベストプラクティス**: `docs/knowledge_base/riverpod_best_practices.md`
- **Recent Implementations**: `.github/copilot-instructions.md` (Section 1-5)

---

**次のステップ**:

1. ⏳ プロバイダーリファレンス作成（`lib/providers/` - 状態管理層）
2. ⏳ リポジトリクラスリファレンス作成（`lib/datastore/` - データ永続化層）
3. ⏳ アーキテクチャ全体図作成（レイヤー間連携の可視化）

---

**文書作成者**: GitHub Copilot (Claude Sonnet 4.5)
**最終更新**: 2026-02-19
