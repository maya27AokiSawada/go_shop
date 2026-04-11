# プライバシーポリシー

**最終更新日: 2026年4月9日**

GoShopping（以下「本アプリ」）は、maya27AokiSawada（以下「開発者」）が提供する買い物リスト・TODOリスト共有アプリケーションです。本プライバシーポリシーは、本アプリにおける個人情報の取り扱いについて説明します。

## 1. 収集する情報

### 1.1 アカウント情報

- メールアドレス
- パスワード（暗号化して保存）
- ディスプレイネーム（任意設定）

### 1.2 アプリ利用情報

- グループ情報（グループ名、メンバー情報）
- リスト情報（リスト名、アイテム情報）※買い物リストモードおよびTODOリストモードの両方を含む
- アプリ設定情報（表示モード、通知設定など）

### 1.3 デバイス情報

- デバイスモデル
- OS バージョン
- アプリバージョン
- クラッシュレポート（エラー発生時）

### 1.4 位置情報（任意）

- 概略位置情報（市区町村レベル）
- 目的: 地域に関連する広告配信の最適化
- 使用パッケージ: geolocator
- 収集頻度: 広告読み込み時のみ（1時間キャッシュ）
- 精度: LocationAccuracy.low（約30km範囲）

**重要**: 位置情報の収集は広告表示の最適化のみに使用され、買い物リスト機能には一切使用されません。初回起動時に位置情報へのアクセス許可をリクエストしますが、拒否してもアプリの全機能を利用できます。

## 2. 情報の利用目的

### 2.1 サービス提供

- ユーザー認証
- 買い物リスト・TODOリストの保存・同期
- グループメンバー間の共有機能
- 通知配信

### 2.2 サービス改善

- アプリの安定性向上
- バグ修正
- 機能改善

### 2.3 広告配信

- 地域に関連する広告の表示
- 広告パフォーマンスの測定

#### 広告表示のポリシー

本アプリはインタースティシャル広告（全画面広告）を表示しますが、**新規インストールから90日間は表示しません**。90日経過後は以下の条件を満たした場合にのみ表示されます。

- 1日の表示回数: 最大3回
- 前回表示からの間隔: 30分以上

## 3. 情報の保存場所

### 3.1 Firebase サービス（Google Cloud Platform）

- 認証情報: Firebase Authentication
- アプリデータ: Cloud Firestore
- クラッシュレポート（Android/iOS）: Firebase Crashlytics
- クラッシュレポート（Windows）: Sentry
- データセンター: 東京リージョン（asia-northeast1）

#### Cloud Firestore に保存される具体的なデータ

以下のデータが Cloud Firestore に保存されます。

| データ種別     | 保存内容                                      |
| -------------- | --------------------------------------------- |
| アカウント情報 | メールアドレス、ディスプレイネーム            |
| グループ情報   | グループ名、グループID、メンバーのUID・表示名 |
| 買い物リスト   | リスト名、各アイテム名・購入状態              |
| ホワイトボード | 描画ストロークデータ                          |
| 通知履歴       | 通知本文、送受信者UID、タイムスタンプ         |

### 3.2 ローカルストレージ（デバイス内）

- オフライン時のキャッシュデータ
- アプリ設定情報

## 4. 情報の共有

### 4.1 データの隔離

Cloud Firestore に保存されたデータは **本アプリのプロジェクト専用のデータベースに格納されており、他のアプリやサービスとは隔離されています**。本アプリとは無関係の第三者サービスや他のアプリが当該データベースに直接アクセスすることはできません。

### 4.2 共有する場合

本アプリは以下の場合を除き、個人情報を第三者に提供しません。

- **ユーザーの同意がある場合**: グループ招待機能を利用した場合
- **法令に基づく場合**: 法的要請がある場合

### 4.3 将来的なデータ活用について

将来的に、流通・小売業者など外部サービスへの統計データ（購買傾向・人気アイテムの集計など）の提供を検討する可能性があります。その際は**個人を特定できない形に加工したうえで**提供し、実施前に**改めてユーザーの同意を取得します**。同意なしに統計データを外部提供することはありません。

### 4.4 第三者サービス

#### Firebase（Google LLC）

- 目的: ユーザー認証、データ保存、クラッシュレポート
- プライバシーポリシー: <https://firebase.google.com/support/privacy>

#### AdMob（Google LLC）

- 目的: 広告配信
- プライバシーポリシー: <https://support.google.com/admob/answer/6128543>

#### Sentry（Functional Software, Inc.）

- 目的: クラッシュレポート・エラー監視（主に Windows 環境）
- 収集情報: クラッシュ発生時のスタックトレース、デバイス情報、OSバージョン、アプリバージョン
- プライバシーポリシー: <https://sentry.io/privacy/>

### 4.5 運営者によるアクセス

運営者（システム管理者）がユーザーデータにアクセスする目的は、**デバッグ・障害対応（バグの原因調査、クラッシュ解析など）およびバックアップ運用に限定されます**。マーケティング利用・第三者への販売・目的外の分析など、上記以外の目的でユーザーデータにアクセスすることはありません。

アクセスする場合も以下の目的の範囲内のみです。

- **デバッグ・障害対応**: バグ原因調査、クラッシュログ解析、不具合再現
- **バックアップ運用**: データの安全性確保、バージョンアップ時のスキーマ移行
- **セキュリティ監査**: 不正利用の検出、脆弱性対応
- **ユーザーサポート**: 問い合わせ対応時の事実確認（ユーザーの要請がある場合のみ）

これらのアクセスは暗号化された通信で行われ、アクセスログが記録されます。個人情報は必要最小限のみ閲覧し、第三者への提供や目的外利用は一切行いません。

## 5. データの保持期間

- **アカウント情報**: アカウント削除まで
- **買い物リストデータ**: ユーザーが削除するまで
- **クラッシュレポート**: 90日間
- **ローカルキャッシュ**: アプリアンインストールまで

## 6. データの削除

### 6.1 アカウント削除

ユーザーはいつでもアカウントを削除できます。アカウント削除後、以下のデータが削除されます。

- アカウント情報
- 個人の買い物リストデータ
- グループ情報（オーナーの場合）

### 6.2 削除方法

#### アプリ内からの削除（推奨）

1. アプリ内「設定」→「アカウント削除」を選択
2. 削除確認ダイアログで「削除する」を選択
3. 最終確認で「完全に削除」を選択
4. 即座にアカウントとデータが削除されます

#### メールでの削除依頼

アプリにアクセスできない場合は、以下の方法でもお問い合わせいただけます:

1. **メール**: maya27aokisawada@maya27aokisawada.net にアカウント削除のご依頼を送信
2. **件名**: 「GoShopping アカウント削除依頼」
3. **記載事項**: 登録メールアドレス

通常、ご連絡から3営業日以内にアカウントとデータを削除いたします。

## 7. セキュリティ

本アプリは以下のセキュリティ対策を実施しています。

- パスワードの暗号化保存
- 通信の暗号化（HTTPS/TLS）
- Firebase Security Rules によるアクセス制御
- 定期的なセキュリティ更新

### 7.1 データのアクセス制御

Cloud Firestore に保存されたデータへのアクセスは Firebase Security Rules により厳格に制御されています。

- **グループデータ（グループ名・リスト名・アイテム名など）**: そのグループに所属するメンバー（`allowedUid` に登録されたユーザー）のみ読み書きが可能です。グループに参加していないユーザーは一切アクセスできません。
- **ユーザープロファイル（メールアドレス・ディスプレイネーム）**: 本人のみ読み書きが可能です。
- **通知データ**: 送信先として指定されたユーザー本人のみ読み取りが可能です。
- **システム管理者（開発者）によるアクセス**: §4.3 に記載した目的（メンテナンス・セキュリティ監査・ユーザーサポート）に限り、最小限の範囲でアクセスします。

### 7.2 ディスプレイネームについて

ディスプレイネームはグループメンバー全員に表示されます。プライバシー保護のため、**本名ではなくニックネームの使用を強く推奨します**。本名を設定した場合でも本アプリの機能は正常に動作しますが、グループを共有するすべてのメンバーにその名前が表示されることをご了承ください。

## 8. 子どものプライバシー

本アプリは13歳未満の子どもを対象としていません。13歳未満の子どもの個人情報を意図的に収集することはありません。

## 9. 権利

ユーザーには以下の権利があります。

- 個人情報の開示請求
- 個人情報の訂正請求
- 個人情報の削除請求
- 個人情報の利用停止請求

## 10. プライバシーポリシーの変更

本プライバシーポリシーは、法令の変更やサービス内容の変更に伴い、予告なく変更される場合があります。重要な変更がある場合は、アプリ内で通知します。

## 11. お問い合わせ

本プライバシーポリシーに関するご質問は、以下の連絡先までお願いします。

**開発者**: maya27AokiSawada
**メールアドレス**: maya27aokisawada@maya27aokisawada.net
**GitHub**: <https://github.com/maya27AokiSawada/go_shop>

---

## プライバシーポリシー（英語版 / English Version）

# Privacy Policy

**Last Updated: April 7, 2026**

GoShopping (hereinafter "the App") is a shopping list sharing application provided by maya27AokiSawada (hereinafter "the Developer"). This Privacy Policy explains how we handle personal information in the App.

## 1. Information We Collect

### 1.1 Account Information

- Email address
- Password (encrypted storage)
- Display name (optional)

### 1.2 App Usage Information

- Group information (group names, member information)
- Shopping list information (list names, item information)
- App settings (display mode, notification settings, etc.)

### 1.3 Device Information

- Device model
- OS version
- App version
- Crash reports (when errors occur)

### 1.4 Location Information (Optional)

- Approximate location (city level)
- Purpose: Optimizing region-related ad delivery
- Package used: geolocator
- Collection frequency: Only during ad loading (1-hour cache)
- Accuracy: LocationAccuracy.low (approximately 30km range)

**Important**: Location information is used solely for advertising optimization and is never used for shopping list features. You will be asked for location access permission on first launch, but you can use all app features even if you deny it.

## 2. How We Use Information

### 2.1 Service Provision

- User authentication
- Shopping list storage and synchronization
- Sharing features among group members
- Notification delivery

### 2.2 Service Improvement

- App stability enhancement
- Bug fixes
- Feature improvements

### 2.3 Advertising

- Display of region-related ads
- Ad performance measurement

## 3. Where Information Is Stored

### 3.1 Firebase Services (Google Cloud Platform)

- Authentication: Firebase Authentication
- App data: Cloud Firestore
- Crash reports: Firebase Crashlytics
- Data center: Tokyo region (asia-northeast1)

#### Data Specifically Stored in Cloud Firestore

The following data is stored in Cloud Firestore:

| Data Type           | Content                                                |
| ------------------- | ------------------------------------------------------ |
| Account information | Email address, display name                            |
| Group information   | Group name, group ID, member UIDs and display names    |
| Shopping lists      | List names, item names, purchase status                |
| Whiteboard          | Drawing stroke data                                    |
| Notifications       | Notification message, sender/recipient UIDs, timestamp |

### 3.2 Local Storage (On Device)

- Offline cache data
- App settings

## 4. Information Sharing

### 4.1 Data Isolation

Data stored in Cloud Firestore is **stored in a database dedicated exclusively to this app's project and is isolated from all other apps and services**. Third-party services or other apps unrelated to this app cannot directly access this database.

### 4.2 When We Share

We do not provide personal information to third parties except in the following cases:

- **With user consent**: When using group invitation features
- **Legal requirements**: When legally required

### 4.3 Future Data Utilization

We may consider providing statistical data (such as purchase trends or popular item aggregates) to external services such as distribution or retail operators in the future. In such cases, data will be **anonymized so that individuals cannot be identified**, and **we will obtain your explicit consent before doing so**. We will never share statistical data with external parties without your consent.

### 4.4 Third-Party Services

The App uses the following services:

#### Firebase (Google LLC)

- Purpose: User authentication, data storage, crash reporting
- Privacy Policy: <https://firebase.google.com/support/privacy>

#### AdMob (Google LLC)

- Purpose: Ad delivery
- Privacy Policy: <https://support.google.com/admob/answer/6128543>

**Ad Display Policy**: Interstitial (full-screen) ads are **not shown for the first 90 days after installation**. After 90 days, ads are shown only when all of the following conditions are met:

- Maximum 3 times per day
- At least 30 minutes since the last ad was shown

### 4.5 Operator Access

The operator (system administrator) accesses user data **solely for the purposes of debugging and incident response (e.g., investigating bug causes, analyzing crash logs) and backup operations**. User data will never be accessed for marketing purposes, sold to third parties, or analyzed for any purpose other than those stated above.

When access is required, it is strictly limited to the following purposes:

- **Debugging & Incident Response**: Bug investigation, crash log analysis, issue reproduction
- **Backup Operations**: Ensuring data safety, schema migration during version upgrades
- **Security Audits**: Detection of unauthorized use, vulnerability response
- **User Support**: Fact-checking when responding to inquiries (only upon user request)

These accesses are conducted via encrypted communication and access logs are recorded. Personal information is accessed only to the minimum extent necessary and is never provided to third parties or used for purposes other than those stated.

## 5. Data Retention Period

- **Account information**: Until account deletion
- **Shopping list data**: Until deleted by user
- **Crash reports**: 90 days
- **Local cache**: Until app uninstallation

## 6. Data Deletion

### 6.1 Account Deletion

Users can delete their account at any time. After account deletion, the following data will be deleted:

- Account information
- Personal shopping list data
- Group information (if owner)

### 6.2 Deletion Method

#### In-App Deletion (Recommended)

1. Go to "Settings" → "Delete Account" in the app
2. Select "Delete" in the confirmation dialog
3. Select "Complete Deletion" in the final confirmation
4. Your account and data will be deleted immediately

#### Deletion Request by Email

If you cannot access the app, you can also contact us using the following method:

1. **Email**: Send an account deletion request to maya27aokisawada@maya27aokisawada.net
2. **Subject**: "GoShopping Account Deletion Request"
3. **Required Information**: Your registered email address

We will delete your account and data within 3 business days of receiving your request.

## 7. Security

The App implements the following security measures:

- Encrypted password storage
- Encrypted communication (HTTPS/TLS)
- Access control via Firebase Security Rules
- Regular security updates

### 7.1 Data Access Control

Access to data stored in Cloud Firestore is strictly controlled by Firebase Security Rules.

- **Group data (group names, list names, item names, etc.)**: Only members belonging to that group (users registered in `allowedUid`) can read or write. Users not in the group have no access whatsoever.
- **User profile (email address, display name)**: Accessible only by the account holder.
- **Notification data**: Only the intended recipient can read their own notifications.
- **System administrator (developer) access**: Limited to the purposes described in §4.3 (maintenance, security audits, user support), with access minimized to what is strictly necessary.

### 7.2 About Display Names

Display names are visible to all members of any group you join. To protect your privacy, **we strongly recommend using a nickname rather than your real name**. The app works normally even if you use your real name, but please be aware that it will be visible to all members of shared groups.

## 8. Children's Privacy

The App is not intended for children under 13. We do not intentionally collect personal information from children under 13.

## 9. Your Rights

Users have the following rights:

- Request disclosure of personal information
- Request correction of personal information
- Request deletion of personal information
- Request suspension of personal information use

## 10. Changes to Privacy Policy

This Privacy Policy may be changed without notice due to legal changes or service updates. Significant changes will be notified within the app.

## 11. Contact

For questions about this Privacy Policy, please contact:

**Developer**: maya27AokiSawada
**Email**: maya27aokisawada@maya27aokisawada.net
**GitHub**: <https://github.com/maya27AokiSawada/go_shop>
