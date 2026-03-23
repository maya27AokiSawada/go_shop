# lib/services — サービス層 ファイル一覧

アプリの業務ロジック・外部連携・データ管理を担うサービス層のファイル一覧です。

---

## 目次

1. [認証・アカウント管理](#1-認証アカウント管理)
2. [ユーザー情報管理](#2-ユーザー情報管理)
3. [データ同期（Firestore ⇄ Hive）](#3-データ同期firestore--hive)
4. [グループ管理・アクセス制御](#4-グループ管理アクセス制御)
5. [招待システム](#5-招待システム)
6. [通知](#6-通知)
7. [Hive 管理](#7-hive-管理)
8. [データマイグレーション](#8-データマイグレーション)
9. [リスト管理](#9-リスト管理)
10. [ネットワーク監視](#10-ネットワーク監視)
11. [Firebase 診断・ニュース](#11-firebase-診断ニュース)
12. [広告（AdMob）](#12-広告admob)
13. [デバイス管理](#13-デバイス管理)
14. [メール管理](#14-メール管理)
15. [その他ユーティリティ](#15-その他ユーティリティ)
16. [ホワイトボード](#16-ホワイトボード)

---

## 1. 認証・アカウント管理

| ファイル名                      | クラス名                 | 役割                                                                                   |
| ------------------------------- | ------------------------ | -------------------------------------------------------------------------------------- |
| `authentication_service.dart`   | `AuthenticationService`  | Firebase Auth を使ったサインイン・サインアップ・サインアウトを提供する                 |
| `signup_service.dart`           | `SignupService`          | サインアップ時の Hive / SharedPreferences クリアとデータ移行処理を担う                 |
| `password_reset_service.dart`   | `PasswordResetService`   | パスワードリセットメールの送信処理を行う                                               |
| `user_preferences_service.dart` | `UserPreferencesService` | SharedPreferences を使ってユーザー名・UID などの基本情報をローカルに保存・読み込みする |

---

## 2. ユーザー情報管理

| ファイル名                              | クラス名                        | 役割                                                                   |
| --------------------------------------- | ------------------------------- | ---------------------------------------------------------------------- |
| `firestore_user_name_service.dart`      | `FirestoreUserNameService`      | `/users/{uid}` ドキュメントに `displayName` / `email` を保存・取得する |
| `user_info_service.dart`                | `UserInfoService`               | 認証状態・グループ・リストをまたいだユーザー情報の集約処理を行う       |
| `user_initialization_service.dart`      | `UserInitializationService`     | サインイン後の Firestore→Hive データ復元・ユーザー固有の初期化を担う   |
| `user_name_initialization_service.dart` | `UserNameInitializationService` | アプリ起動時・サインイン後のユーザー名取得と Provider への反映を行う   |
| `user_name_management_service.dart`     | `UserNameManagementService`     | ユーザー名の変更・Firestore / グループメンバー名の更新を管理する       |

---

## 3. データ同期（Firestore ⇄ Hive）

| ファイル名                          | クラス名                    | 役割                                                                               |
| ----------------------------------- | --------------------------- | ---------------------------------------------------------------------------------- |
| `sync_service.dart`                 | `SyncService`               | Firestore ⇄ Hive 間の全体同期を一元管理する（`forceSyncProvider` の実体）          |
| `firestore_group_sync_service.dart` | `FirestoreGroupSyncService` | Firestore から取得したグループデータを Hive へ反映するグループ専用の同期処理を行う |

---

## 4. グループ管理・アクセス制御

| ファイル名                      | クラス名                 | 役割                                                                                       |
| ------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------ |
| `group_management_service.dart` | `GroupManagementService` | グループ作成・削除・メンバー操作など、グループ関連のビジネスロジックをまとめる             |
| `access_control_service.dart`   | `AccessControlService`   | 認証状態やグループロールに基づきグループ作成・招待・シークレットモードなどの権限を判定する |

---

## 5. 招待システム

| ファイル名                         | クラス名                    | 役割                                                                                              |
| ---------------------------------- | --------------------------- | ------------------------------------------------------------------------------------------------- |
| `qr_invitation_service.dart`       | `QRInvitationService`       | QR コード招待の生成・エンコード・デコード・受諾・使用回数更新を行う中心サービス                   |
| `invitation_service.dart`          | `InvitationService`         | 招待の基本的な送信・取得処理を提供する                                                            |
| `invitation_security_service.dart` | `InvitationSecurityService` | QR 招待の HMAC ベースのセキュリティキー生成・検証を行う                                           |
| `invitation_monitor_service.dart`  | `InvitationMonitorService`  | 受諾済み招待を監視し、対応するグループ・リストの同期を行う                                        |
| `enhanced_invitation_service.dart` | `EnhancedInvitationService` | メールアドレスを基に招待可能なグループを検索するなどの拡張招待処理を行う                          |
| `invite_code_service.dart`         | `InviteCodeService`         | QR 招待用の 8 桁セキュアコードを生成する                                                          |
| `accepted_invitation_service.dart` | `AcceptedInvitationService` | 受諾済み招待（`AcceptedInvitation`）を Hive で管理する                                            |
| `pending_invitation_service.dart`  | `PendingInvitationService`  | 未サインイン状態で受け取った招待情報を SharedPreferences に一時保存し、サインイン後に自動処理する |

---

## 6. 通知

| ファイル名                             | クラス名                       | 役割                                                                                                                  |
| -------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `notification_service.dart`            | `NotificationService`          | Firestore の `notifications` コレクションを使った通知の送信・受信・既読管理・各種グループ・リスト変更通知の送信を担う |
| `list_notification_batch_service.dart` | `ListNotificationBatchService` | リスト作成・削除・名称変更などの変更通知をバッチでまとめて送信する                                                    |

---

## 7. Hive 管理

| ファイル名                         | クラス名                    | 役割                                                                                     |
| ---------------------------------- | --------------------------- | ---------------------------------------------------------------------------------------- |
| `user_specific_hive_service.dart`  | `UserSpecificHiveService`   | ユーザー固有の Hive Box 初期化・スキーマバージョン管理・アダプター登録を行うシングルトン |
| `hive_initialization_service.dart` | `HiveInitializationService` | アプリ起動時に必要な Hive アダプターと Box を一括初期化する                              |
| `hive_lock_cleaner.dart`           | `HiveLockCleaner`           | Windows で残留しやすい Hive `.lock` ファイルを削除するクリーナー                         |

---

## 8. データマイグレーション

| ファイル名                                | クラス名                         | 役割                                                                                                 |
| ----------------------------------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `data_version_service.dart`               | `DataVersionService`             | `data_version` / `hive_schema_version` を SharedPreferences で管理し、初回起動と移行を区別する       |
| `shared_list_data_migration_service.dart` | `SharedListDataMigrationService` | SharedList の `List<SharedItem>` → `Map<String, SharedItem>` 形式移行を行う                          |
| `shared_list_migration_service.dart`      | `SharedListMigrationService`     | 旧デフォルトグループのリストを新デフォルトグループ（UID キー）に移行する                             |
| `firestore_migration_service.dart`        | `FirestoreDataMigrationService`  | Firestore のデータ構造（旧スキーマ → 新スキーマ）の移行処理を行う                                    |
| `user_profile_migration_service.dart`     | `UserProfileMigrationService`    | ユーザープロファイルを `/users/{uid}/profile/profile` の旧構造から `/users/{uid}` の新構造へ移行する |

---

## 9. リスト管理

| ファイル名                       | クラス名                  | 役割                                                                                                 |
| -------------------------------- | ------------------------- | ---------------------------------------------------------------------------------------------------- |
| `list_cleanup_service.dart`      | `ListCleanupService`      | 論理削除済み（`isDeleted = true`）のアイテムを一定日数経過後に物理削除するクリーンアップ処理を行う   |
| `periodic_purchase_service.dart` | `PeriodicPurchaseService` | 購入済みかつ定期購入間隔が設定されたアイテムを、購入日から指定間隔後に自動で未購入状態へリセットする |

---

## 10. ネットワーク監視

| ファイル名                     | クラス名                | 役割                                                                                                                           |
| ------------------------------ | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `network_monitor_service.dart` | `NetworkMonitorService` | Firestore への Ping を定期実行してオンライン / オフライン状態を判定し、一時的な名前解決失敗では即 offline と見なさず再試行する |

---

## 11. Firebase 診断・ニュース

| ファイル名                          | クラス名                     | 役割                                                                                 |
| ----------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------ |
| `firebase_diagnostics_service.dart` | `FirebaseDiagnosticsService` | Firebase 接続テストと詳細診断を提供するデバッグ用サービス                            |
| `firestore_news_service.dart`       | `FirestoreNewsService`       | Firestore の `furestorenews/current_news` ドキュメントからアプリ内ニュースを取得する |

---

## 12. 広告（AdMob）

| ファイル名        | クラス名    | 役割                                                                                                    |
| ----------------- | ----------- | ------------------------------------------------------------------------------------------------------- |
| `ad_service.dart` | `AdService` | AdMob バナー広告の作成・位置情報（30km 圏内優先）を使った広告ターゲティング・1 時間キャッシュを管理する |

---

## 13. デバイス管理

| ファイル名                     | クラス名                | 役割                                                                                                                    |
| ------------------------------ | ----------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `device_id_service.dart`       | `DeviceIdService`       | `device_info_plus` でプラットフォーム別のデバイス固有 8 文字プレフィックスを生成し、グループ ID・リスト ID の衝突を防ぐ |
| `device_settings_service.dart` | `DeviceSettingsService` | デバイス固有の永続設定を管理するシングルトン                                                                            |

---

## 14. メール管理

| ファイル名                      | クラス名                 | 役割                                                            |
| ------------------------------- | ------------------------ | --------------------------------------------------------------- |
| `email_management_service.dart` | `EmailManagementService` | メールアドレスの SharedPreferences への保存・読み込みを管理する |
| `email_test_service.dart`       | `EmailTestService`       | 開発・テスト用にメール送信動作確認を行う                        |

---

## 15. その他ユーティリティ

| ファイル名                     | クラス名                | 役割                                                                                                                |
| ------------------------------ | ----------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `app_launch_service.dart`      | `AppLaunchService`      | アプリの起動回数・初回起動日時・最終起動日時を SharedPreferences に記録する                                         |
| `deep_link_service.dart`       | `DeepLinkService`       | MethodChannel を通じてディープリンク URL を受け取り、Stream で配信する                                              |
| `error_log_service.dart`       | `ErrorLogService`       | エラーをコスト 0（SharedPreferences）でローカルに最新 20 件保管し、設定画面のエラー履歴ページで確認できるようにする |
| `feedback_prompt_service.dart` | `FeedbackPromptService` | Firestore の `/testingStatus/active` を参照し、テスト実施中かどうかを判定する                                       |
| `feedback_status_service.dart` | `FeedbackStatusService` | フィードバック送信済みフラグ・送信日時を SharedPreferences で管理する                                               |

---

## 16. ホワイトボード

| ファイル名                          | クラス名             | 役割                                                                                                                                                           |
| ----------------------------------- | -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `whiteboard_edit_lock_service.dart` | `WhiteboardEditLock` | Firestore の `editLock` フィールドを使ったホワイトボード編集ロックの取得・解放・強制引き継ぎ・監視を行う。`userId` + `deviceId` の両方でロック所有者を判定する |

---

## 補足

- 各サービスは `Provider` または `static メソッド` として提供されます。
- Riverpod の Provider 経由で利用するものは `xxxServiceProvider` という名前の変数が定義されています。
- テスト・開発向けのサービス（`email_test_service.dart`、`firebase_diagnostics_service.dart` など）は本番コードから呼ばれないよう注意してください。
