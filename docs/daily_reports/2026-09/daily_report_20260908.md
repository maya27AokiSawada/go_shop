# 開発日報 - 2026年09月08日

## 📅 本日の目標

- [x] iOS のサブスク商品IDを `goshopping2_` 接頭辞へ変更し、コードベース全体の一貫性を確保する
- [x] ビルド番号を 34 へ更新し、AAB / IPA のリリースビルドを生成する
- [x] 内部テスト（TestFlight）ビルド34で出た「未登録の商品ID」エラーを調査する
- [x] README を含むドキュメントをビルド34に合わせて更新する
- [x] 本日の作業を日報にまとめて `sumomo-planning` へコミットする

---

## ✅ 完了した作業

### 1. iOS サブスク商品IDの `goshopping2_` 接頭辞化と一貫性確保 ✅

**Purpose**: App Store Connect 側で iOS のサブスク商品IDを
`goshopping2_premium_monthly` / `goshopping2_premium_annual` に変更したため、
クライアント・StoreKit 設定・サーバー検証・ドキュメントを追随させる。Android は変更なし。

**変更前の状態（調査結果）**:

- 手動変更されていたのは `functions/receipt_verification.js` の年額 iOS ID のみ（`PREMIUM_ANNUAL_IOS_ID = "goshopping2_premium_annual"`）。
- iOS の**月額** ID はどこにも反映されておらず、Dart の `_ProductIds.premiumMonthly` は Android/iOS 共通の定数のままだった。
- `ios/Runner/GoShop.storekit` は旧 `goshopping_premium_*` のまま。

**Solution**:

| ファイル | 変更 |
|---|---|
| `lib/services/purchase_service.dart` | 月額を `premiumMonthlyAndroid`（`goshopping_premium_monthly`）/ `premiumMonthlyIOS`（`goshopping2_premium_monthly`）に分割し、`Platform.isIOS` 分岐の getter 化（年額と同じ形）。`premiumYearlyIOS` を `goshopping_premium_annual` → `goshopping2_premium_annual` に。`supportedPremium` に 4 SKU すべてを列挙 |
| `functions/receipt_verification.js` | `PREMIUM_MONTHLY_IOS_ID = "goshopping2_premium_monthly"` を追加し `module.exports` に公開（※このファイルは同時にインデント 4→2 スペースの全体整形も入っている） |
| `functions/index.js` | `SUPPORTED_PREMIUM_PRODUCT_IDS` 許可リストに iOS 月額 ID を追加 |
| `ios/Runner/GoShop.storekit` | 2 つの `productID` を `goshopping2_premium_monthly` / `goshopping2_premium_annual` に |
| `test/providers/subscription_lifecycle_test.dart` | Android/iOS × 月額/年額の 4 SKU すべてが `isSupportedProductId` で受理され `purchaseTypeForProductId` が `subscribe` を返すことを検証するテストを追加 |
| `SETUP.md` | App Store 側手順に「iOS は `goshopping2_` 接頭辞」を明記 |
| `instructions/50_user_and_settings.md` | 「有効なPremium商品ID」表を Android / iOS × 月額 / 年額に更新。`goshopping_premium_yearly` の記述を削除 |

**Verified**:

- `flutter test test/services/purchase_service_test.dart test/providers/subscription_lifecycle_test.dart` → 14 件パス
- `functions/` `npm test` → 10 件パス
- `flutter analyze lib/services/purchase_service.dart lib/widgets/settings/purchase_plan_panel.dart` → 既存の `_purchaseTypeForProduct` 未使用警告のみ（今回の変更起因ではない）

**Status**: ✅ 完了

---

### 2. ビルド番号 34 へ更新し、AAB / IPA をリリースビルド ✅

**Purpose**: サブスク商品ID変更を反映した内部テスト用ビルドを生成する。

**Result**:

- `pubspec.yaml` を `version: 1.1.0+33` → `1.1.0+34` に更新。
- **AAB**: `flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod --build-number=34`
  → `build/app/outputs/bundle/prodRelease/app-prod-release.aab`（約 80.3MB）
- **IPA**: `flutter build ipa --release --flavor prod --dart-define=FLAVOR=prod --build-number=34 --export-method app-store`
  → `** ARCHIVE SUCCEEDED **` / `** EXPORT SUCCEEDED **`
  → `build/ios/ipa/go_shop.ipa`（約 44MB）、`build/ios/archive/Runner.xcarchive`（約 432.6MB）
  → バージョン `1.1.0 (34)`、Bundle ID `net.sumomo-planning.goshopping`、Deployment Target 15.0
- Gradle の Kotlin Gradle Plugin 非推奨警告（`cloud_functions` / `firebase_*` ほか）は出るがビルドは正常終了。将来の Flutter で対応が必要。

**Status**: ✅ ビルド成功

---

### 3. 内部テスト（TestFlight）ビルド34「未登録の商品ID」エラーの調査 ✅

**Symptom**: 内部テストの iOS ビルド34 で設定画面の**年払いボタンが表示されない**（月額ボタンは表示）。
ログに `未登録の商品ID: [...]`（[`purchase_service.dart`](../../../lib/services/purchase_service.dart) の `queryProductDetails` の `notFoundIDs`）。

**切り分け**:

1. ビルド34の `App.framework/App` を `strings` で確認 → `goshopping2_premium_monthly` / `goshopping2_premium_annual` が埋め込み済み、`CFBundleVersion = 34` を確認。旧 Android 定数（`goshopping_premium_monthly` / `goshopping-premium-annual`）も残るが、これは `_ProductIds` の Android 用 `const` フィールドが同一クラスにあるため AOT に文字列として含まれるだけで、iOS 実行時は参照されない。
2. `lib/widgets/settings/purchase_plan_panel.dart` を確認 → 年払いボタンは
   `!_isLoading && _isStoreAvailable && _isPremiumYearlyProductAvailable` で出し分け。
   `_isPremiumYearlyProductAvailable` は「ストアから `goshopping2_premium_annual` を取得できたか」。UI 側にハードコード ID は無く、Android で両ボタンが出るのは両商品が取得できているため。UI コードのバグではない。
3. 月額ボタンが出る = `goshopping2_premium_monthly` は取得成功 = `Platform.isIOS` 経路・有料App契約・伝播は正常。**年払いのみ取得失敗**。

**Root Cause**: **App Store Connect の年払いサブスクの製品IDがスペルミス**。
`goshopping2_premium_anuual`（`annual` = a-n-**n**-u-a-l のところ `anuual` = a-n-**u**-u-a-l）で登録されており、
アプリが要求する正しい `goshopping2_premium_annual` と不一致 → `notFoundIDs` → ボタン非表示。
月額 `goshopping2_premium_monthly` は正しいスペルのため取得できていた。

**Solution（ストア側・コード変更なし）**:

- App Store Connect の製品IDは作成後に変更不可のため、`goshopping2_premium_annual` で年払いサブスクを作成し直す。
- 誤字の `goshopping2_premium_anuual` は未提出（審査準備完了止まり）のため削除可。
- アプリ / StoreKit 設定 / サーバー検証はすべて正しいスペル `goshopping2_premium_annual` のため、ビルド35 は不要。

**Status**: ✅ 原因特定 → 正しい製品IDで登録し直し、ビルド34と共にサブスクプランを審査提出済み。

---

### 4. README / ドキュメントをビルド34に合わせて更新 ✅

**Purpose**: バージョン表記とサブスク仕様の記述を現状に合わせる。

**Modified Files**:

- `README.md`
  - 「現在のアプリバージョンは `1.1.0+28`」→ `1.1.0+34`
  - Premium の記述を「月額のみ」から「月額・年払い」に更新
  - iOS が `goshopping2_` 接頭辞、Android が `goshopping_` / `goshopping-` 表記で `PurchaseService` が `Platform.isIOS` で分岐する旨を追記
  - 「最近の主な成果」に Premium 年払いプラン追加と商品ID分岐、Functions 検証の月額・年額対応を追記
- `SETUP.md` / `instructions/50_user_and_settings.md`（作業1で更新済み）

**Status**: ✅ 完了

---

## 🗓 翌日（2026-09-09）の予定

1. サブスク審査の結果を確認し、リジェクト時は指摘に対応する
2. 正しい `goshopping2_premium_annual` が Sandbox / TestFlight で取得でき、iOS の設定画面に年払いボタンが表示されることを実機確認する
3. Premium 月額 / 年払いの購入・復元・`verifyPurchase` サーバー検証を E2E で確認する
4. Android 内部テストで年払い（`goshopping-premium-annual`）の購入・復元を確認する

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `docs/daily_reports/2026-09/daily_report_20260908.md` | 本日の日報を新規作成 |
| `docs/daily_reports/2026-09/daily_report_20260907.md` | 前日分の見出しの iOS 年額 SKU 表記を `goshopping2_premium_annual` に修正（ユーザー編集分） |
| `README.md` | アプリバージョンを `1.1.0+34` に更新。Premium 月額・年払いの記述と iOS/Android 商品ID分岐、最近の成果を追記 |
| `SETUP.md` | App Store 側手順に iOS は `goshopping2_` 接頭辞である旨を明記 |
| `instructions/50_user_and_settings.md` | 「有効なPremium商品ID」表を Android / iOS × 月額 / 年額に更新 |
| `lib/services/purchase_service.dart` | 月額 SKU を Android / iOS 分岐、`supportedPremium` を 4 SKU に |
| `functions/index.js` / `functions/receipt_verification.js` | サーバー検証の許可商品IDに iOS 月額 `goshopping2_premium_monthly` を追加（`receipt_verification.js` はインデント整形も同時に混在） |
| `ios/Runner/GoShop.storekit` | `productID` を `goshopping2_premium_monthly` / `goshopping2_premium_annual` に |
| `test/providers/subscription_lifecycle_test.dart` | Android/iOS × 月額/年額の 4 SKU 変換テストを追加 |
| `pubspec.yaml` | `version: 1.1.0+34` へ更新 |
