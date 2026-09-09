# 開発日報 - 2026年09月09日

## 📅 本日の目標

- [x] EULA 等の運営者を株式会社Ansize → 木之本すもも企画（個人事業）へ変更し、全公開文書の一貫性を確保する
- [x] 規約類の最終更新日を 2026-07-01 に統一する
- [x] 特定商取引法に基づく表記を新設し、特商法違反にならない事業者情報を設定する
- [x] Google Play リアルタイム デベロッパー通知（RTDN）を実装し、更新・解約・失効・返金をサーバー側で権限へ反映する
- [~] グループメンバーの `name` / `contact` を暗号化する（Phase 0〜2 完了。Phase 3 以降は次回）
- [x] 本日の作業を日報にまとめて `sumomo-planning` へコミットする

---

## ✅ 完了した作業

### 1. 運営者を「木之本すもも企画」へ統一（コミット `dd2033a6`）✅

**Purpose**: 運営者を株式会社Ansize から個人事業「木之本すもも企画（Kinomoto Sumomo Planning）」へ変更。
ユーザーが `eula.md` を先行編集済みだったため、残りの公開文書・アプリ内表記の一貫性を確認して追随させる。

**調査結果（変更前に残っていた `Ansize` 参照）**:

- `terms_of_service.md`: 第12条（日）と Article 12（英）が `株式会社Ansize` / `Ansize Co., Ltd.` のまま
- `privacy_policy.md`: 英語冒頭が `Ansize Co., Ltd.`、英語の削除依頼先に `ansize.oneness@gmail.com` が残存（日本語側は編集済み）
- `data_deletion.md`: ファイル全体が未編集（運営者・メール 5 箇所）。アプリの [`common_app_bar.dart`](../../../lib/widgets/common_app_bar.dart) から直接リンクされる文書
- `daily_reports/**` と `SECURITY_ACTION_REQUIRED.md` にも記述があるが、履歴・インシデント記録のため変更対象外

**Solution**:

| ファイル | 変更 |
|---|---|
| `docs/specifications/eula.md` | 英語冒頭の二重スペース修正、最終更新日を 2026-07-01 に |
| `docs/specifications/terms_of_service.md` | 第12条 / Article 12 を `木之本すもも企画` / `Kinomoto Sumomo Planning` に。日英の最終更新日を 2026-07-01 に |
| `docs/specifications/privacy_policy.md` | 英語冒頭を `Kinomoto Sumomo Planning` に、英語の削除依頼先から `ansize.oneness@gmail.com` を除去。日英の最終更新日を 2026-07-01 に（日本語版は 2026-08-12 からの変更・ユーザー判断で統一） |
| `docs/specifications/data_deletion.md` | 運営者・メール 5 箇所を `木之本すもも企画` / `info@sumomo-planning.net`（削除依頼先は `support@sumomo-planning.net`）に。最終更新日を 2026-07-01 に |
| `docs/specifications/README.md` | 法的文書一覧の日付を 2026-07-01 に更新、`tokushoho.md` の行を追加 |
| `docs/DEVELOPER.md` | 開発元テーブルを整形、代表者・ふりがなを追記 |
| `lib/l10n/app_texts*.dart`（5ファイル） | l10n キー `commercialDisclosure` を追加（ja/en/pt/zh_hans） |
| `lib/widgets/common_app_bar.dart` | 「法的情報」リンク一覧に特商法表記を追加（日英 URL 出し分け） |
| `lib/widgets/settings/purchase_plan_panel.dart` | 購入画面のリンク行を `Row` → `Wrap` にして特商法表記リンクを追加（3項目でのオーバーフロー回避） |

**Verified**:

- `docs/specifications/` 配下から `Ansize` / `ansize` / `株式会社` が消え、表記が統一（日本語＝木之本すもも企画、英語＝Kinomoto Sumomo Planning、運営者メール＝info@sumomo-planning.net、開発者・削除依頼＝support@sumomo-planning.net）
- `flutter analyze lib/l10n lib/widgets/common_app_bar.dart lib/widgets/settings/purchase_plan_panel.dart` → 新規の警告・エラーなし（既存の file_names / strict_top_level_inference のみ）

**Status**: ✅ 完了・`dd2033a6` として `sumomo-planning` へ push 済み

---

### 2. 特定商取引法に基づく表記の新設 ✅

**Purpose**: サブスクリプション（Premium 月額 / 年額）を販売しているため、特商法11条の広告表示義務を満たす
「特定商取引法に基づく表記」を用意し、購入者が閲覧できる導線を張る。

**Solution**:

- `docs/specifications/tokushoho.md` を新規作成（日本語主体 + English summary）。記載項目:
  - 販売事業者: 木之本すもも企画 / **運営統括責任者: 金ヶ江 真也（かながえ しんや）**（`PROFILE.md` の戸籍名・ユーザー確認済み。個人事業は屋号だけでなく本名の記載が必須）
  - 所在地・電話番号・メール（`DEVELOPER.md` と一致）
  - 販売価格: Premium 月額 200円（税込）/ 年額 1,500円（税込）← [`purchase_service.dart`](../../../lib/services/purchase_service.dart) の値と一致
  - 支払方法・支払時期・提供時期・自動更新・解約方法（iOS/Android 別）・返品返金・動作環境・特別条件
- アプリ内導線（作業1と同一コミット）: `common_app_bar.dart` の法的リンク一覧、`purchase_plan_panel.dart` の購入画面リンク行に追加

**仮置き（ユーザー要確認）**:

- 電話受付時間「平日 10:00〜17:00（土日祝・年末年始を除く）」
- サービス提供時期「通常は数分以内」
- 英語表記の氏名 `Shinya Kanagae` / ローマ字住所
- Android の対応 OS バージョンは「各ストア掲載ページ参照」（`minSdk` が `flutter.minSdkVersion` 依存で確定値なし）

**Status**: ✅ 文書・導線ともに完了（`dd2033a6`）。上記仮置き値の確定は次回以降

---

### 3. Google Play リアルタイム デベロッパー通知（RTDN）の実装 ✅

**Purpose**: `verifyPurchase`（Callable）は購入時点の検証のみで、Pub/Sub を消費する関数が存在せず、
解約・返金・保留・失効・自動更新をサーバーが検知できなかった（`daily_report_20260905.md` の
「Priority: High」課題）。RTDN を購読して `purchaseReceipts` と `users/{uid}.purchaseType` を継続反映する。

**Solution**:

| ファイル | 変更 |
|---|---|
| `functions/play_rtdn.js`（新規） | RTDN 1 通の処理本体。`parseDeveloperNotification` / `resolveSubscriptionActive` / `handlePlayRtdn` を export |
| `functions/receipt_verification.js` | `fetchGoogleSubscriptionV2()`（subscriptionsv2 の生照会）を追加、`ACTIVE_GOOGLE_STATES` を export |
| `functions/index.js` | `onMessagePublished`（topic 既定 `play-rtdn` / `PLAY_RTDN_TOPIC` で上書き可）の `playRtdnHandler` を追加 |
| `functions/test/play_rtdn.test.js`（新規） | 15 ケース（最小 Firestore フェイク使用） |
| `SETUP.md` | 「5.2 Google Play RTDN」節を追加（トピック作成・IAM・Play Console 入力・デプロイ手順） |

**処理仕様**:

- 通知は uid を含まないため、`sha256("google_play:" + purchaseToken)` で `purchaseReceipts/{key}` を引いて uid を特定。
  ローカルレシートが無ければスキップ（初回購入はクライアントの `verifyPurchase` が付与する）
- `notificationType` に依存せず Android Publisher API を再照会して現在状態を判定（Google 推奨）
  - 有効（`ACTIVE` / `IN_GRACE_PERIOD` / `CANCELED` かつ期限内）→ `subscribe` / 新 `expiresAt` に更新（`source: "rtdn"`）
  - 無効（`EXPIRED` / `ON_HOLD` / `PAUSED` / `REVOKED` 等）→ レシートに失効印。**そのレシートがユーザーの現在の権限源のときだけ** `purchaseType` を `free` に（別トークンで再購読済みなら user は触らない）
- `voidedPurchaseNotification`（返金・チャージバック）→ `revoked` として同じダウングレード経路
- `oneTimeProductNotification`（旧買い切り）→ 記録のみ（サーバー検証対象外）
- エラー方針: ペイロード不正（`RtdnError`）は ack して破棄、ストア照会・Firestore の一時障害は例外を投げて Pub/Sub 再送（`retry: true`）

**Verified**:

- `cd functions && npm test` → **25 / 25 パス**（既存 10 + 新規 15）
- `node --check` 全対象ファイル OK、`firebase-functions@7.3.2` に `onMessagePublished` の存在を確認

**残作業（コード外・手動）**:

1. `gcloud pubsub topics create play-rtdn --project goshopping-48db9`
2. 配信 SA `google-play-developer-notifications@system.gserviceaccount.com` に `roles/pubsub.publisher` を付与
3. `firebase deploy --only functions:playRtdnHandler`
4. Play Console →「収益化のセットアップ」→「Google Play 請求サービス」でトピック名 `projects/goshopping-48db9/topics/play-rtdn` を入力、通知の内容は「定期購入と取り消し済みの購入のみ」、「テスト通知を送信」で疎通確認
5. ライセンス（Base64 RSA 公開鍵）欄は操作不要（サーバー検証済みのため未使用）

**Status**: ✅ 実装・テスト完了。GCP / Play Console 側の設定とデプロイは次回

---

### 4. グループメンバー情報の暗号化（Phase 0〜1 + Phase 2 設計）⏸ 中断中

**Purpose**: `SharedGroups/{groupId}` に平文保存されているメンバーの `name` / `contact`、
および重複するトップレベル `ownerName` / `ownerEmail` を、既存のグループ共通鍵で暗号化する。
共有アイテム名（`SharedLists.items[].name`）と同じ仕組みを踏襲。

**決定事項（ユーザー確認済み）**:

- 対象: `members[].name` / `members[].contact` + トップレベル `ownerName` / `ownerEmail`
- 進め方: 先に Firestore シリアライズを 1 コーデックへ一元化してから暗号化を差し込む
- 鍵スキーム: `memberUid` を含めない**グループ共通秘密**（`groupId + groupKey` 由来）。
  全メンバーが相互に読める必要があるため
- `memberEmails` 配列 / `invitations` コレクションは対象外

**影響しないと確認**: セキュリティルール（`allowedUid` ベース）、招待メール（`mailto:` +
`invitations` コレクション）、バックアップ/リストア（`ownerUid` のみ参照）。

**Phase 0（基盤）✅ コミット `c348ba1f`**:

| ファイル | 内容 |
|---|---|
| `lib/services/group_key_exchange_service.dart` | `encryptGroupField` / `decryptGroupField` / `isEncryptedGroupField` を追加。新方式で復号失敗時は keyless 秘密でフォールバック |
| `lib/datastore/shared_group_firestore_codec.dart`（新規） | `SharedGroup` / `SharedGroupMember` ⇄ Firestore マップ変換の一元化コーデック。`cipher` 注入時のみ暗号化。二重暗号化防止・移行期の平文パススルー込み |
| `lib/datastore/group_field_cipher.dart`（新規） | `GroupKeyExchangeService` を `GroupFieldCipher` に適合させるアダプター |
| テスト | コーデック 10 + 群フィールド暗号 5 |

**Phase 1（全経路をコーデック経由に統一・暗号化はまだ OFF）✅ コミット `7fc940a2`**:

`cipher: null` なので `encryptGroup` / `decryptGroup` は同一インスタンスを返し**挙動不変**。

| ファイル | 対応 |
|---|---|
| `shared_group_firestore_codec.dart` | module-level `sharedGroupFirestoreCodec()` / `configureSharedGroupCodec()` / `resetSharedGroupCodec()`（Phase 3 の一括切替口）。`encryptGroup` / `decryptGroup` / `encryptMembers` / `decryptMembers` フックを追加 |
| `firestore_shared_group_repository.dart` | `_groupToFirestore` / `_groupFromFirestore` を codec 委譲に。旧ヘルパー4つを撤去 |
| `sync_service.dart` / `user_initialization_service.dart` / `firestore_migration_service.dart` | write に `encryptGroup`、Firestore→Hive 反映に `decryptGroup` |
| `notification_service.dart` | 招待受諾時のメンバー追記 write に `encryptMembers` |
| `firestore_group_sync_service.dart` | `watchUserGroups`（UI が購読する `SharedGroups` 監視）に `decryptGroup` |
| `firestore_helper.dart` | `fetchGroup` / `fetchUserGroups` に `decryptGroup`（元の計画に無かった経路） |
| `enhanced_invitation_service.dart` | `SharedGroup.fromJson`×3 に `decryptGroup`、`.toJson()` write×2 に `encryptGroup`（同じく計画外で発見） |
| `firestore_shared_group_adapter.dart` | レガシー未参照。ヘッダーコメントで明示 |

変更不要と確認: `qr_invitation_service` / `invitation_monitor_service` /
`hybrid_shared_group_repository`（`_firestoreRepo` 経由）/ `notification_service` の read 2 箇所。

**Verified**: `flutter analyze lib/` で新規警告なし。`flutter test test/datastore/` ほか **173 件緑**。

**Phase 2 の設計方針を確定（鍵取得タイミング）**:

「参加時＋鍵更新通知受信時」だけでは**不十分**。鍵を受け取るタイミングは正しいが、
復号を成立させるには以下が必要（アイテム名暗号化が既にやっていることと同じ）:

1. **グループ読みの choke point で毎回ローカル永続鍵をキャッシュへ再ロード**
   （`_groupKeyCache` はプロセス内のみ。再起動で空 → `decryptGroup` は現在同期のため
   空鍵で復号失敗 → 暗号文が UI に出る）。`decryptGroup` の非同期版で
   `getPersistedGroupKey` を prime するか、read ループで groupId ごとに 1 回 prime。
2. **メンバー表示の最初の入口（グループ一覧 / メンバー管理画面ロード）でも鍵解決を呼ぶ**
   （現状の解決は共有リストを開いたとき／通知受信時が主）。
3. 読み時の世代チェックで自己修復（`shouldRefreshGroupKey` 相当）。
4. 2 台目の端末 / 再インストールは `resolveGroupKeyForMember`（recovery envelope）だが、
   上記 1・2 の prime 経路がこれを兼ねる。
5. cipher アダプターには **provider シングルトンの `GroupKeyExchangeService`** を渡す
   （`new` すると別キャッシュになりアイテム側で温めた鍵が効かない）。

詳細は `docs/development_plan/group_member_encryption_implementation_plan.md`（更新済み）。

**Phase 2（decrypt-only。書き込みは平文のまま）✅ コミット `<pending>`**:

| ファイル | 対応 |
|---|---|
| `shared_group_firestore_codec.dart` | `GroupFieldCipher.primeKey` を追加。コーデックに `primeKey` / `decryptGroupPrimed` / `decryptGroupsPrimed` と `encryptOnWrite` フラグ（`encryptsOnWrite` getter）。`encryptOnWrite: false` で書き込み時は暗号化しない |
| `group_field_cipher.dart` | `GroupKeyServiceFieldCipher.primeKey` = `getPersistedGroupKey`。`sharedGroupCodecProvider`（**provider シングルトンの `GroupKeyExchangeService`** を注入・`encryptOnWrite: false`）を追加 |
| `firestore_shared_group_repository.dart` | `getAllGroups` / `getGroupById` / `deleteGroup` で `primeKey` 後に変換 |
| `firestore_group_sync_service.dart` | `watchUserGroups` の `.map` → `.asyncMap` で groupId ごとに prime |
| `sync_service.dart` / `user_initialization_service.dart` / `firestore_helper.dart` / `enhanced_invitation_service.dart` | `decryptGroup` → `await decryptGroupPrimed` |
| `app_initialize_widget.dart` | `_performAppInitialization` 先頭で `ref.read(sharedGroupCodecProvider)` |

**判断**: グループ一覧 / メンバー管理画面は `allGroupsProvider`（Hive・平文）を読むため個別の
鍵解決は**不要**。Firestore→Hive 同期（`user_initialization_service` / `sync_service`）と
live stream（`firestore_group_sync_service.watchUserGroups`）の両方が復号済みになったため、
UI に届く時点で平文。

**Verified**: `flutter analyze lib/` 新規警告なし。`flutter test test/datastore/` ほか
**176 件緑**。コーデックテストに Phase 2 分（`decryptGroupPrimed` の prime 呼び出し、
decrypt-only モード）を追加。

**Status**: ✅ Phase 0〜2 完了・コミット済み。**Phase 3（`encryptOnWrite: true` 化 →
書き込み暗号化 ON）+ Phase 4（既存平文の再暗号化パス）は次回**。
Phase 2 は decrypt-only リリースとして先に配布する。

---

## 🗓 翌日（2026-09-10）の予定

1. `play-rtdn` トピック作成 + IAM 付与 + `playRtdnHandler` デプロイ
2. Play Console の請求サービス設定にトピック名を入力し「テスト通知」で疎通確認（ログに `[play-rtdn] テスト通知を受信`）
3. Sandbox / 内部テストで「解約 → 失効」が `users/{uid}.purchaseType=free` に反映されることを実機確認
4. **グループメンバー暗号化 Phase 3**（`sharedGroupCodecProvider` を `encryptOnWrite: true` に）+ **Phase 4**（既存平文データの再暗号化パスを `hybrid_shared_group_repository` に追加）+ 実機 2 端末テスト
5. iOS の App Store Server Notifications V2 対応を設計する
6. 特商法表記の仮置き値（電話受付時間・提供時期・英語表記）を確定する
7. （9/8 からの継続）サブスク審査結果の確認と、必要なら iOS の年払いボタン表示の実機確認

---

## 📝 ドキュメント / 変更ファイル一覧

### コミット `dd2033a6`（運営者統一 + 特商法表記）

| ファイル | 更新内容 |
|---|---|
| `docs/specifications/eula.md` | 英語冒頭の整形、最終更新日 2026-07-01 |
| `docs/specifications/terms_of_service.md` | 第12条 / Article 12 の運営者名、最終更新日 2026-07-01 |
| `docs/specifications/privacy_policy.md` | 英語冒頭の運営者名、`ansize.oneness@gmail.com` 除去、最終更新日 2026-07-01 |
| `docs/specifications/data_deletion.md` | 運営者・メール 5 箇所、最終更新日 2026-07-01 |
| `docs/specifications/tokushoho.md` | **新規**: 特定商取引法に基づく表記（日英） |
| `docs/specifications/README.md` | 法的文書一覧の日付更新、`tokushoho.md` 追加 |
| `docs/DEVELOPER.md` | 開発元テーブルの整形、代表者・ふりがな追記 |
| `lib/l10n/app_texts.dart` ほか 4 ロケール | l10n キー `commercialDisclosure` 追加 |
| `lib/widgets/common_app_bar.dart` | 法的リンク一覧に特商法表記を追加 |
| `lib/widgets/settings/purchase_plan_panel.dart` | 購入画面リンクを `Wrap` 化し特商法表記を追加 |

### コミット `914564e6`（RTDN 実装 + 日報）

| ファイル | 更新内容 |
|---|---|
| `functions/play_rtdn.js` | **新規**: RTDN 処理本体 |
| `functions/test/play_rtdn.test.js` | **新規**: RTDN テスト 15 件 |
| `functions/receipt_verification.js` | `fetchGoogleSubscriptionV2()` 追加、`ACTIVE_GOOGLE_STATES` を export |
| `functions/index.js` | `onMessagePublished` の `playRtdnHandler` 追加 |
| `SETUP.md` | 「5.2 Google Play RTDN」節を追加 |
| `docs/daily_reports/2026-09/daily_report_20260909.md` | **新規**: 本日の日報 |

### コミット `c348ba1f`（グループメンバー暗号化 Phase 0）

| ファイル | 更新内容 |
|---|---|
| `lib/services/group_key_exchange_service.dart` | `encryptGroupField` / `decryptGroupField` / `isEncryptedGroupField` |
| `lib/datastore/shared_group_firestore_codec.dart` | **新規**: 一元化コーデック |
| `lib/datastore/group_field_cipher.dart` | **新規**: cipher アダプター |
| `test/datastore/shared_group_firestore_codec_test.dart` / `test/services/group_key_exchange_field_test.dart` | **新規**: 単体テスト |
| `docs/development_plan/group_member_encryption_implementation_plan.md` | **新規**: 実装計画 |

### コミット `7fc940a2`（グループメンバー暗号化 Phase 1）

| ファイル | 更新内容 |
|---|---|
| `lib/datastore/shared_group_firestore_codec.dart` | module-level 切替口 + `encryptGroup` / `decryptGroup` / `encryptMembers` / `decryptMembers` |
| `lib/datastore/firestore_shared_group_repository.dart` | 変換を codec 委譲に |
| `lib/services/{sync_service,user_initialization_service,firestore_migration_service,notification_service,firestore_group_sync_service,enhanced_invitation_service}.dart` | read に `decryptGroup` / write に `encryptGroup` |
| `lib/utils/firestore_helper.dart` | read に `decryptGroup` |
| `lib/datastore/firestore_shared_group_adapter.dart` | レガシー明示コメント |
| `docs/development_plan/group_member_encryption_implementation_plan.md` | Phase 1 完了・Phase 2 設計を反映 |

### コミット `<pending>`（グループメンバー暗号化 Phase 2 = decrypt-only）

| ファイル | 更新内容 |
|---|---|
| `lib/datastore/shared_group_firestore_codec.dart` | `GroupFieldCipher.primeKey` / `decryptGroupPrimed` / `decryptGroupsPrimed` / `encryptOnWrite` フラグ |
| `lib/datastore/group_field_cipher.dart` | `primeKey` 実装 + `sharedGroupCodecProvider`（provider シングルトン注入・decrypt-only） |
| `lib/datastore/firestore_shared_group_repository.dart` | read 3 メソッドで `primeKey` 後に変換 |
| `lib/services/firestore_group_sync_service.dart` | `watchUserGroups` を `.asyncMap` 化して prime |
| `lib/services/{sync_service,user_initialization_service,enhanced_invitation_service}.dart` / `lib/utils/firestore_helper.dart` | `decryptGroup` → `await decryptGroupPrimed` |
| `lib/widgets/app_initialize_widget.dart` | 初期化先頭で `sharedGroupCodecProvider` を read |
| `test/datastore/shared_group_firestore_codec_test.dart` | Phase 2 分のテスト追加 |
| `docs/development_plan/group_member_encryption_implementation_plan.md` | Phase 2 完了を反映 |

### 本コミット（日報追記）

| ファイル | 更新内容 |
|---|---|
| `docs/daily_reports/2026-09/daily_report_20260909.md` | 作業4に Phase 2 実装の詳細を追記、翌日予定を更新 |

### 未追跡・本コミット対象外

- `pubspec.lock`: `intl` / `matcher` / `meta` / `test_api` / `vector_math` の transitive 版数差分のみ。本日の作業と無関係のため据え置き
