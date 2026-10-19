# ユーザー管理・設定指示書

> 共通ルールは `00_project_common.md` を先に読むこと。

---

## 1. 認証フロー詳細

認証フローの順序は `00_project_common.md` §2 を参照すること。
以下は補足ルール。

- **Firestore 同期完了前に「グループ0件」と UI 判定してはならない**
- `authStateChanges()` は Hive box 初期化より先に発火することがある
  → `forceSyncProvider` / `allGroupsProvider` を触る前に box の open を確認する
- サインイン後は `waitForSafeInitialization()` が `_firestoreRepo` の準備を保証するまで CRUD を呼ばない

---

## 2. ユーザー名の取得・保存

### 優先順位

```text
Firestore /users/{uid}.displayName
  → SharedPreferences
    → UserSettings (Hive)
      → Firebase Auth displayName
        → email prefix
          → UID（最終フォールバック）
```

### ユーザー名保存は Firebase Auth 登録の**前に SharedPreferences をクリア**してから行う

```dart
// サインアップ時の正しい順序
await UserPreferencesService.clearAllUserInfo();  // ← 先にクリア
await SharedGroupBox.clear();
await auth.signUp(email, password);
await UserPreferencesService.saveUserName(userName);  // ← Auth 後に保存
await user.updateDisplayName(userName);
```

---

## 3. アカウント削除

### 必須手順

1. **再認証**（`EmailAuthProvider.credential()` → `reauthenticateWithCredential()`）
   - `requires-recent-login` エラー対策
2. **2段階確認ダイアログ**（誤操作防止）
3. **Batch 分割削除**
   - Batch 1: サブコレクション（sharedLists, whiteboards）を削除 → commit
   - Batch 2: 親グループ削除 + メンバー離脱 + 通知 + user プロファイル削除 → commit

> ⚠️ **注意**: `/invitations` トップレベルコレクション（レガシー）は `allow read, write: if false` で全拒否のためクエリ不可。v3.x 以降は `SharedGroups/{groupId}/invitations/` サブコレクションに移行済みのため Batch 2 から除外すること。アクセスすると `permission-denied` 例外が発生し後続の `user.delete()` がブロックされる。

### Batch を分割する理由

サブコレクションと親ドキュメントを同一 Batch で削除すると、
サブコレクション削除時の権限チェックで親ドキュメントへの `get()` が失敗して
`permission-denied` になる。

### オーナーグループと参加グループの扱い

```dart
// オーナーグループ → 完全削除
batch2.delete(group.reference);

// 参加グループ（メンバーとして参加） → allowedUid から自分を外すだけ
batch2.update(group.reference, {
  'allowedUid': FieldValue.arrayRemove([currentUser.uid]),
});
```

---

## 4. AppMode（買い物リスト ⇄ TODO 切替）

- `AppModeSettings.config.{property}` を使って用語を動的に切り替える
- UI にグループ名・リスト名・アイテム名をハードコードする **禁止**
- モード切替は `AppModeSettings.setMode()` + `appModeNotifierProvider` 更新
- 設定値は Hive の `UserSettings` に永続化

---

## 4a. AppUIMode（single / multi UI 切替）

### 概要

| モード             | 用途                                            | 差異                                                       |
| ------------------ | ----------------------------------------------- | ---------------------------------------------------------- |
| `AppUIMode.single` | 家族・カップル向けシンプルUI（グループ1つ固定） | FAB非表示、リストDropdown→Text固定、add/deleteボタン非表示 |
| `AppUIMode.multi`  | 従来の複数グループUI                            | 全機能有効                                                 |

### ファイル構成

| ファイル                                               | 役割                                                 |
| ------------------------------------------------------ | ---------------------------------------------------- |
| `lib/config/app_ui_mode_config.dart`                   | `AppUIMode` enum + `AppUIModeSettings` singleton     |
| `lib/providers/app_ui_mode_provider.dart`              | `appUIModeProvider` (StateProvider)                  |
| `lib/widgets/settings/app_ui_mode_switcher_panel.dart` | 設定画面のモード切替UIパネル（プレミアムゲート付き） |
| `lib/widgets/single_group_creation_dialog.dart`        | サインアップ後シングルモードのグループ作成ダイアログ |

### 永続化

- Hive `UserSettings.appUIMode` (`HiveField(9)`) に `int` で保存（0=single, 1=multi）
- SharedPreferences / Firestore `/users/{uid}.appUIMode` とも双方向同期
- 起動時に `app_initialize_widget.dart` で Hive → `AppUIModeSettings` → Provider に初期化

### ルール

- モード判定は `ref.watch(appUIModeProvider) == AppUIMode.single` を使う
- `isSingle` が true のとき、グループ追加 FAB・リストDropdown・add/deleteボタンを非表示にする
- single → multi 変更は Free / Premium 共通で利用可能。Free プランのグループ数・メンバー数上限は各操作側で適用する
- ただし広告同意がなく広告を表示できない無料ユーザー（UMP の `canRequestAds()` が `false`）は single → multi を禁止する。判定は `multiModeBlockedByAdConsentProvider`（`lib/providers/ad_consent_provider.dart`）。`AppUIModeSwicherPanel` はスイッチを無効化し、注意文と「広告への同意を行う」ボタン（`AdService.requestConsentAgain()`）を表示する。課金ユーザー（Premium 等で広告非表示）は同意がなくてもマルチモードに切り替えられる。注意文は `PurchasePlanPanel.isAvailable` が `true` の環境では「Premium プランに加入しても利用できる」旨も表示する（iOS は課金パネル非表示中のため表示しない）。同意を拒否した EEA ユーザーや米国州でオプトアウトしたユーザーは制限付き広告が配信されるため対象外。multi → single は常に可能。同意状態を変える操作の後は provider を `invalidate` する
- multi → single 変更は確認ダイアログを必ず表示する
- **Hive に新フィールドを追加したら `UserSettingsAdapterOverride` の `read()` と `write()` を必ず更新する**（null安全のため `(fields[N] as Type?) ?? defaultValue` パターンを使う）
- **新規ユーザーのデフォルトは `appUIMode: 0`（シングルモード）**。`firestore_user_name_service.dart` の `saveUserName()` で新規ドキュメント作成時に `appUIMode: 0` を明示設定すること。SharedPreferences に前ユーザーの stale な値（`1` = multi）が残っていても上書きされる。
- **サインアップ直後は `_syncUserProfile` の非同期完了を待たずに 3 箇所を即座に設定すること**（stale 値が UI に反映される時間を排除する）:

```dart
// ✅ サインアップ成功直後（sign_up_form.dart / home_page.dart）
AppUIModeSettings.setMode(AppUIMode.single);
ref.read(appUIModeProvider.notifier).state = AppUIMode.single;
await UserPreferencesService.saveAppUIMode(0);
```

- `user_initialization_service.dart` の `_syncUserProfile()` は、Firestore にデータがなくローカルにある場合（新規ユーザー直後）は `localAppUIMode` を使わず `appUIMode: 0` を強制書き込みすること（`localAppUIMode` は前ユーザーの stale 値の可能性があるため）。

### グループの自動選択（シングルモード対応）

`allGroupsProvider` は返却リストを `updatedAt` 降順でソートする。
これにより `SelectedGroupIdNotifier` が SharedPreferences に保存済みIDを持たない場合（新規端末サインイン等）、`availableGroups.first` が「最近更新されたグループ」になる。

```dart
// ✅ allGroupsProvider（shared_group_provider.dart）での実装パターン
deduplicatedGroups.sort((a, b) =>
    (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
```

- Firestore リアルタイムリスナー更新時も同じソートを適用すること
- `updatedAt` が null のグループは `DateTime(0)`（最古）として扱う

---

## 5. DeviceIdService

- プレフィックスは **SharedPreferences に永続化**する（再生成禁止）
- Android ID が 8 文字未満でも安全に処理する
- iOS の `identifierForVendor` は null になりうる → フォールバック UUID を使う

---

## 6. 設定画面のウィジェット構成

`lib/pages/settings_page.dart` は薄いオーケストレーターとして機能し、
実装の実体は `lib/widgets/settings/` の各ファイルに分割されている。

| ファイル                           | 役割                                                           | Widget 種別              |
| ---------------------------------- | -------------------------------------------------------------- | ------------------------ |
| `auth_status_panel.dart`           | 認証状態表示パネル                                             | `ConsumerWidget`         |
| `firestore_sync_status_panel.dart` | Firestore 同期状態表示                                         | `ConsumerWidget`         |
| `app_mode_switcher_panel.dart`     | アプリモード切替（リスト ⇄ TODO）                              | `ConsumerWidget`         |
| `purchase_plan_panel.dart`         | 課金プラン表示・購入UIパネル（比較表・購入ボタン・復元ボタン） | `ConsumerStatefulWidget` |
| `notification_settings_panel.dart` | 通知設定                                                       | `ConsumerWidget`         |
| `privacy_settings_panel.dart`      | プライバシー設定（プライバシーポリシー/利用規約リンク）        | `StatelessWidget`        |
| `whiteboard_settings_panel.dart`   | ホワイトボードカラー設定                                       | `ConsumerWidget`         |
| `ad_privacy_options_panel.dart`    | 広告の同意変更・取り消し（UMP、EEA等で必要な場合のみ表示）     | `ConsumerStatefulWidget` |
| `feedback_section.dart`            | フィードバックフォームリンク                                   | `StatefulWidget`         |
| `feedback_debug_section.dart`      | フィードバックデバッグ情報（dev のみ）                         | `StatefulWidget`         |
| `developer_tools_section.dart`     | 開発者ツールパネル（dev のみ）                                 | `ConsumerWidget`         |
| `data_maintenance_section.dart`    | データクリーンアップ・マイグレーション（dev のみ）             | `ConsumerStatefulWidget` |
| `account_deletion_section.dart`    | アカウント削除（認証済みのみ）                                 | `ConsumerStatefulWidget` |

### ルール

- 新しい設定機能は `settings_page.dart` に直接書かず、`lib/widgets/settings/` に専用ファイルを作成すること
- `dev` 専用 UI は `if (F.appFlavor == Flavor.dev) ...` ブロックで囲む
- `AccountDeletionSection` は `User user`（non-nullable）を受け取る
- `DataMaintenanceSection` / `DeveloperToolsSection` は `User? user` を受け取る

---

## 7. 禁止事項

- サインアウト前に Hive / SharedPreferences をクリアしないまま Auth を解除する
- Firestore 同期前に「グループ0件」と確定してページ遷移・UI 構築する
- アカウント削除を再認証なしで実行する
- Batch 分割なしにサブコレクションと親を同時削除する
- 設定機能のロジックを `settings_page.dart` 本体に直接書く（→ `lib/widgets/settings/` に分割する）
- **`createNewGroup()` 呼び出し後に `allGroupsProvider.future` を await する**
  - `createNewGroup()` は完了時に `allGroupsProvider` の state を直接更新する
  - この更新で `SharedGroupPage` が再ビルドされ、ダイアログ等のウィジェットが破棄される可能性がある
  - 破棄後に `future` の await が再開すると `_dependents.isEmpty: is not true` アサーションでクラッシュする
  - ✅ 代替: `ref.read(allGroupsProvider).valueOrNull ?? []` で同期的に現在値を取得する
  - ✅ 代替: 非同期処理の前に必要な `ref.read()` をすべて取得しておく

---

## 8. アプリ内課金（In-App Purchase）

### 課金タイプ（`lib/models/purchase_type.dart`）

| enum 値                  | Firestore 値  | 広告制御                           | 価格                                                  |
| ------------------------ | ------------- | ---------------------------------- | ----------------------------------------------------- |
| `PurchaseType.free`      | `'free'`      | バナー・インタースティシャルあり   | 無料                                                  |
| `PurchaseType.subscribe` | `'subscribe'` | **全広告非表示**                   | Premium月額（日本: ¥200/月、その他: おおむねUS$2/月） |
| `PurchaseType.purchase`  | `'purchase'`  | **全広告非表示**                   | 早期ダウンロード特典（1年間・アプリ内販売なし）       |
| `PurchaseType.family`    | `'family'`    | **全広告非表示**                   | 家族特典（Premium 利用者のクーポンで付与・無料）       |

### 有効なPremium商品ID

| 商品ID (Android / iOS)                                       | 種別                               | 価格                                                                           |
| ------------------------------------------------------------ | ---------------------------------- | ------------------------------------------------------------------------------ |
| `goshopping_premium_monthly` / `goshopping2_premium_monthly` | 自動更新サブスクリプション（月額） | ストアのローカル価格を表示。未取得時は日本語で¥200/月、その他でUS$2/月         |
| `goshopping-premium-annual` / `goshopping2_premium_annual`   | 自動更新サブスクリプション（年額） | ストアのローカル価格を表示。未取得時は日本語で¥1,500/年、その他でUS$14.99/year |

- iOS の SKU は `goshopping2_` 接頭辞、Android は従来どおり。`_ProductIds` が `Platform.isIOS` で分岐し、サーバー検証（`functions/`）も両方の ID を許可リストに含める。
- `PurchaseService` は現在、上記の月額・年額 SKU を商品情報取得の対象にする。
- `goshopping_subscribe` はレガシー定義であり、新規購入UIには表示しない。

### 早期ダウンロード特典（`goshopping_onetime_1000`）

- Google Play の1回限りのアイテム（Android のみ）。**アプリ内では販売しない**。プロモーションコードの引き換えで付与するため、`_ProductIds.all`（商品情報取得の対象）に含めず、購入ボタンも作らない。
- 特典内容は「引き換えから1年間、広告非表示＋グループ数・メンバー数がPremium同等」。`purchaseType: 'purchase'` として付与する。
- 引き換えた購入は購入ストリーム、または「購入を復元」で届く。`verifyPurchase` Callable が `purchases.products` API で検証し、`purchaseVerification.expiresAt` に引き換え日時の1年後を保存して acknowledge する。
- 1回限りのアイテムはストアから失効通知が届かない。スケジュール関数 `expireEarlyDownloadBenefits`（毎日 JST 03:00）が、期限を過ぎたユーザーを `purchaseType: 'free'` に戻す。期限後に復元しても `verifyPurchase` が拒否する。
- クライアントの Hive 側では `purchase` の期限を切らない。Firestore が `free` に戻った時点で `purchaseSyncProvider` が反映する。
- Free / Premium の特典、上限、価格、新規受付予定の公開上の正本は `docs/specifications/premium_plan.md` とする。アプリ内では `SubscriptionSalesConfig.premiumPlanDetailsUrl` を使って同ページへ誘導し、説明文や上限値を各画面へ重複定義しない。
- 実際に強制するグループ数・メンバー数の上限は `lib/config/subscription_limits.dart` を正とする。公開ページの上限説明を変更するときは、この実装値との一致を確認する。

### 家族特典クーポン（`functions/family_coupon.js`）

- Premium（`purchaseType: subscribe`）のユーザーに固有のクーポン（`XXXX-XXXX`）を1つ発行する。早期ダウンロード特典（`purchase`）と家族特典（`family`）のユーザーには発行しない。
- クーポンを入力したユーザーが、発行者が参加しているグループのどれかに参加していれば（**入力時のみ確認**）、`purchaseType: family`（Premium 同等・全広告非表示）になる。入力後にグループを抜けても、発行者の Premium が有効な間は特典が続く。
- 同時に特典を受けられるのは5人まで。発行者は設定画面から家族を解除でき、解除すると枠が空く。
- 自分で課金している（`subscribe` / `purchase`）ユーザーが入力した場合は `purchaseType` を上書きせず、`familyBenefit` だけ記録する。自分の課金が切れて `free` になったら `family` に戻す。
- 有効な別の家族特典を利用中のユーザーは入力できない。停止中（発行者の Premium が無効）なら新しいクーポンに乗り換えられる。
- 発行・入力・解除は Callable（`issueFamilyCoupon` / `redeemFamilyCoupon` / `removeFamilyMember`、App Check 必須）だけで行う。クライアントは `familyCoupon` / `familyBenefit` / `purchaseType` を書き込めない（Security Rules で保護）。`familyCoupons` コレクションはクライアントから読み書き不可。
- Firestore トリガー `syncFamilyBenefits`（`users/{uid}` の書き込み）が、発行者の Premium の有効/無効に合わせて家族の `purchaseType` を `family` / `free` に切り替える。アカウント削除時はクーポンと特典のつながりを片付ける。トリガーのリージョンは Firestore のロケーションと同じにする。
- 設定画面の `FamilyCouponPanel` に表示する。iOS は課金パネルと同じく既定で非表示（`FamilyCouponPanel.isAvailable` = `PurchasePlanPanel.isAvailable`）。

```
familyCoupons/{code}: { sponsorUid, createdAt }
users/{sponsorUid}.familyCoupon: { code, members: { <uid>: { displayName, grantedAt } }, createdAt }
users/{memberUid}.familyBenefit: { sponsorUid, sponsorDisplayName, grantedAt }  // 誰の家族として特典を受けているか
```

### Firestore スキーマ（`/users/{uid}`）

```
purchaseType: 'free' | 'subscribe' | 'purchase' | 'family'  // 課金タイプ（デフォルト: omitted → free）
```

### プレ公開期間（2026年中）の新規受付ブロック

- Premiumの新規受付は **2027年1月開始**。2026年中はプレ公開期間として新規購入をブロックする。
- 課金開始日は Firestore の `appConfig/subscription` ドキュメントの `salesStartDate`（Timestamp 型）で管理する。読み取りは認証済みユーザーのみ、書き込みは Firebase Console / Admin SDK のみ。
- `PurchaseService.refreshSalesStartDate()` が課金開始日を読み出す。`PurchasePlanPanel` の初期化時に呼び出す。
- ドキュメント・フィールドが未設定、または取得に失敗した場合は `SubscriptionSalesConfig.defaultSalesStartDate`（2027年1月1日、端末のローカル時刻）を使う。
- `PurchaseService.isSalesOpen` が `false` の間、`buyPremiumMonthly()` / `buyPremiumYearly()` はストア購入UIを開かずに案内メッセージを返す。
- `PurchasePlanPanel` は購入ボタンの代わりに「プレ公開中」「課金はyyyy年M月開始予定」の案内を表示する（年月は課金開始日から生成）。
- 「購入を復元」と、購入ストリームで届いた取引の検証は期間中も止めない（既存のPremium利用者を維持するため）。

### 課金フロー

1. Android / iOSではアプリ起動直後に `PurchaseService.initialize()` を実行し、購入ストリームを購読する。設定画面を開くまで購読を遅延させない。
2. 認証済みユーザーの設定画面に `PurchasePlanPanel` を表示し、ストア利用可否と月額SKUの商品情報を反映する。 iOS は `PurchasePlanPanel.isAvailable` が `false` となり既定で非表示。`--dart-define=IOS_PURCHASE_PANEL=true`（2027年1月の提出ビルド用）または `--dart-define=IAP_SALES_OPEN=true`（Sandbox テスト用）を付けたビルドのみ表示する。
3. 「Premiumを有効化」で `PurchaseService.buyPremiumMonthly()` が `PurchaseParam` を使ってストア購入UIを開く。購入開始だけではMultiモードへ切り替えない。
4. 購入または復元の完了後、`_handlePurchase()` がストアの検証データを `verifyPurchase` Callableへ送る。
5. FunctionsがGoogle Play Developer APIまたはApple署名済みStoreKit 2取引を検証し、成功時だけAdmin SDKで `purchaseType: subscribe` を保存する。
6. Google PlayはFunctions側でacknowledgeする。App Storeは検証成功後にクライアントが取引をfinishする。
7. `purchaseTypeProvider`（`StreamProvider`）がFirestore変化を検知してUIを自動更新する。
8. `purchaseSyncProvider` がHiveの `SubscriptionState` へ反映し、`isPremiumActiveProvider`、Free/Premiumの上限、広告表示を更新する。Firestoreの明示的な `free` は、有効な無料体験中を除いてローカルにも即時反映する。
9. 「購入を復元」は `PurchaseService.restorePurchases()` を実行し、復元取引も同じCallableで再検証する。
10. Google Playが購入開始を受け付けない場合は、既所有購入の可能性を考慮して自動的に `restorePurchases()` を実行する。復元された購入トークンも必ず既存のFunctions検証へ送る。

### クライアント側の課金状態管理

- Firestoreの `purchaseType` を課金権限の正とし、SharedPreferencesのキャッシュで明示的な `free` を上書きしない。
- 認証状態の変更時は `purchaseTypeProvider` が購読対象ユーザーを切り替える。
- 月額PremiumはHiveに35日間のオフライン猶予として保存し、Firestoreから有料状態を受信するたびに期限を更新する。
- 購入UIは `pending` / `purchased` / `restored` / `canceled` / `error` を表示し、処理中の多重操作を禁止する。
- ストアへ接続できても月額SKUを取得できない場合は購入ボタンを無効化し、ストアアカウントとアプリの配布元を確認する案内を表示する。復元ボタンは利用可能なまま維持する。
- Google Playのprod商品を使うE2E確認は、prod packageをPlay Storeのテストトラックからインストールして行う。applicationIdが異なるdev packageやローカルインストールAPKでprod SKUの取得を前提にしない。

### 広告チェックの原則

- `shouldShowSignInAd()`: 課金チェック → testingStatus確認 → インストール90日猶予 → 日次上限・間隔チェック
- `shouldShowBannerAd()`: 課金チェックのみ（`hidesBannerAds`）
- `hidesInterstitialAds` が `true`（subscribe/purchase）→ インタースティシャルをスキップ
- `hidesBannerAds` が `true`（subscribe のみ）→ バナーをスキップ
- **`FeedbackPromptService.isTestingActive()` が `true`（Firestore `testingStatus/active.isTestingActive`）のとき、90日猶予チェックをスキップする**（開発・テスト用バイパス）

### 広告の同意（UMP / 欧州の規制）

- `AdService.initialize()` は UMP の同意確認（必要なら同意フォーム表示）を先に行い、`canRequestAds()` が `true` のときだけ `MobileAds.instance.initialize()` と広告読み込みを行う
- `shouldShowBannerAd()` も `canRequestAds()` が `false` ならバナーを出さない
- 同意の変更・取り消し入口は設定画面の `AdPrivacyOptionsPanel`。`getPrivacyOptionsRequirementStatus()` が `required` のときだけ表示する（AdMob の要件のため削除しない）
- AdMob コンソールの「プライバシーとメッセージ」→「欧州の規制」で GDPR メッセージを公開しておく必要がある
- 米国の州規制（CCPA 等）も同じ入口で対応する。AdMob コンソールの「米国の州規制」メッセージを公開すると、対象州のユーザーに `AdPrivacyOptionsPanel` が表示され、オプトアウトフォームが開く（起動時の同意フォームは出ない）
- dev では `.env` に `ADMOB_UMP_DEBUG_GEOGRAPHY=eea`（EEA・英国）/ `us`（米国の規制対象州）/ `other` と `ADMOB_UMP_TEST_DEVICE_IDS=<ログに出るID>` を設定すると、日本から各地域の同意フローを確認できる（旧設定の `ADMOB_UMP_DEBUG_EEA=true` は `eea` と同じ扱い）
- デバッグ地域を切り替えた後は、アプリのデータを消去するか `ConsentInformation.instance.reset()` で同意状態を初期化してから確認する
- 同意状況は `users/{uid}.adConsent` に保存する（`AdService.syncAdConsentToFirestore()`）。保存タイミングは起動時の同意確認後・同意フォーム再表示後・プライバシー設定フォーム後・サインイン/ユーザー切替時。前回保存時から変化がなければ書き込まない
- ユーザードキュメントが未作成の場合は作成せずスキップする（`update()` を使う。新規作成時の初期値 `appUIMode: 0` 等を飛ばさないため）

```
adConsent: {
  consentStatus: 'notRequired' | 'obtained' | 'required' | 'unknown',  // UMP の ConsentStatus
  canRequestAds: bool,
  privacyOptionsRequired: bool,  // EEA・英国・米国の規制対象州など
  platform: 'android' | 'ios',
  updatedAt: Timestamp,
}
```

### 広告テストバイパスの手順

1. Firestore コンソール → `testingStatus/active` ドキュメント → `isTestingActive: true` に設定
2. アプリでサインイン → インタースティシャル広告が表示されることを確認
3. 確認後は必ず `isTestingActive: false` に戻す（本番ユーザーへの影響防止）

### セキュリティ注意事項

- `purchaseType` / `purchaseVerification` / `familyCoupon` / `familyBenefit` はSecurity Rulesでクライアント書き込みを禁止し、Functionsの Admin SDK だけが更新する。
- raw purchase token / StoreKit JWSはFirestoreへ保存しない。SHA-256指紋だけを保存し、同じ購入の別Firebaseユーザーへの使い回しを拒否する。
- `verifyPurchase` CallableはFirebase AuthとApp Checkを必須とする。
- Functions側では初回検証だけでなく、Google Play RTDN / App Store Server Notificationsによる更新、解約、返金、猶予期間、保留、失効の反映も行う。
