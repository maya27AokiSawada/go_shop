# 開発日報 - 2026年09月07日

## 📅 本日の目標

- [x] `flutter run --release` の実機起動失敗の原因を切り分ける
- [x] iOS `Release-prod` / `Profile-prod` に App Attest entitlements を配線する
- [x] 実機（iPhone 17e）でのサインイン失敗の根本原因を特定・修正する
- [x] 手元検証で App Check enforce 下でもサインインできる導線を用意する
- [x] グループ作成上限（Premium 20）の動作を確認し、失敗時のエラー通知を改善する
- [x] 購入ページのスクリーンショットを撮れる状態にする（有料App契約の承認待ち回避）
- [x] iOS 年払いプラン（`goshopping_premium_annual`）のクライアント／サーバー対応を反映する
- [x] TestFlight 用 release build 33（IPA）をビルドする
- [x] 本日の作業を日報にまとめて `sumomo-planning` へ反映する

---

## ✅ 完了した作業

### 1. `flutter run --release --flavor prod` 実機起動失敗の切り分け ✅

**Purpose**: 実機（iPhone 17e / iOS 26.6.1）へのデプロイで `Error running application` が出る原因を特定する。

**調査**:

- verbose ログを取得。Xcode build も `devicectl device install` も成功しており、`devicectl device process launch` だけが失敗していた。
- エラー本文：
  ```
  FBSOpenApplicationErrorDomain error 7
  NSLocalizedFailureReason = Unable to launch net.sumomo-planning.goshopping
                             because the device was not, or could not be, unlocked.
  BSErrorCodeDescription = Locked
  ```

**Root Cause**: 端末がロック中に `devicectl` がアプリ起動を要求し、SpringBoard に拒否されていた。署名・プロビジョニング・entitlements とは無関係。

**Solution**: 端末のロックを解除した状態で再実行。以降のビルド検証時は自動ロックを一時的に「なし」に設定して回避。

**Status**: ✅ 原因特定・回避手順を確立

---

### 2. App Attest entitlements の `Release-prod` / `Profile-prod` への配線 ✅

**Purpose**: 追加済みの `ios/Runner/RunnerRelease.entitlements` が、`flutter run/build --flavor prod` が使う `Release-prod` コンフィグに適用されていなかったため配線する。

**Problem / Root Cause**:

`CODE_SIGN_ENTITLEMENTS` が Runner ターゲットの `Release` コンフィグにしか設定されておらず、Xcode のビルドコンフィグは相互継承しないため、`Release-prod` / `Profile-prod` では entitlements が無効だった。結果として prod リリースビルドで App Attest（`AppleAppAttestProvider`）が機能しない状態だった。

**Solution**:

`ios/Runner.xcodeproj/project.pbxproj` の Runner ターゲット `Release-prod` / `Profile-prod` の両コンフィグに
`CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements;` を追加。
`xcodebuild -showBuildSettings` で 3 コンフィグ（`Release` / `Release-prod` / `Profile-prod`）とも解決されること、`Debug-prod` では未設定（Debug プロバイダを使うため不要）であることを確認。

**Modified Files**:

- `ios/Runner.xcodeproj/project.pbxproj`

**Status**: ✅ 配線完了・ビルド設定で確認

---

### 3. 実機サインイン失敗の根本原因特定・修正 ✅

**Purpose**: iPhone 17e の release ビルドでメール／パスワードのサインインが「サインインに失敗しました」で必ず失敗する原因を、デバイスログを取得して特定する。

**調査の流れ**:

1. `idevicesyslog` で `Runner` プロセスのログを取得し、サインイン試行時のエラー連鎖を確認。
2. App Check のトークン交換が失敗していた：
   ```
   [FirebaseAppCheck] exchangeAppAttestAttestation
   HTTP status code: 403
   { "error": { "code": 403, "message": "App attestation failed.", "status": "PERMISSION_DENIED" } }
   ```
3. Firebase Auth がフォールバックで **placeholder トークン**を送信 → identitytoolkit が
   `401 "Firebase App Check token is invalid." / reason: unauthorized` を返却。
4. アプリ側は `[firebase_auth/internal-error] Code=17999 (ERROR_INTERNAL_ERROR)` を受け取り、UI が「サインインに失敗しました」を表示。
5. `devicecheckd` のログに `Development environment override set.` が二度出力されていた。

**Root Cause**:

`ios/Runner/RunnerRelease.entitlements` に
`com.apple.developer.devicecheck.appattest-environment = development` が指定されていたため、端末は **development 環境**で App Attest 鍵を生成・アテストしていた。一方 Firebase App Check のバックエンドは Apple の **production** App Attest サーバでしか検証しないため、`exchangeAppAttestAttestation` が常に 403 になっていた。加えて Firebase Console 側で Authentication に App Check の enforce が有効なため、無効トークンだとサインイン自体が 401 で弾かれていた。

**Solution**:

- `RunnerRelease.entitlements` から `appattest-environment` キーを削除（キー未指定時、App Store / TestFlight 配布ビルドは自動的に production 環境になり、Firebase の検証が通る）。経緯をファイル内コメントに残置。
- `lib/main.dart` の App Check 初期化に `--dart-define=APP_CHECK_DEBUG=true` を追加。
  `kDebugMode || APP_CHECK_DEBUG` のときに Apple/Android とも Debug プロバイダを選択する。
  App Attest は配布ビルドの production 環境でしか Firebase 検証を通らないため、実機へ直接インストールしたローカルビルドで enforce 下の動作確認をするための導線。

**検証**: 実機で `--dart-define=APP_CHECK_DEBUG=true` ビルドし、コンソールに出力されたデバイス固有の App Check デバッグトークンを Firebase Console のデバッグトークンに登録 → サインイン成功を確認。

**Modified Files**:

- `ios/Runner/RunnerRelease.entitlements`（`appattest-environment` キー削除）
- `lib/main.dart`（`APP_CHECK_DEBUG` dart-define を追加）

**Status**: ✅ 実機でサインイン成功を確認

---

### 4. グループ作成上限の確認と失敗時エラー通知の改善 ✅

**Purpose**: 「Premium で最大 20 グループ、21 個目でブロック」の動作を実機で確認し、作成失敗時にユーザーへ理由が伝わるようにする。

**Result**:

- 上限ロジックは仕様どおり（`SubscriptionLimits`：Free 3 / Premium 20、`allGroupsProvider.createNewGroup` が上限で `Exception` を送出）。バグなし。
- 3 つのグループ作成ダイアログで、`catch` した `Exception`（上限到達など）が `SnackBar` に反映されない／`Exception: ` 接頭辞がそのまま表示される、という UX 上の不備を発見。
- 共通ヘルパー `SnackBarHelper.showError` へ統一し、`Exception: ` を除去したメッセージを表示するよう修正。

**Modified Files**:

- `lib/widgets/group_creation_with_copy_dialog.dart`（成功時は既存挙動、失敗時に `SnackBarHelper.showError` を追加）
- `lib/widgets/single_group_creation_dialog.dart`（生 `ScaffoldMessenger` → `SnackBarHelper.showError` に統一）
- `lib/widgets/initial_setup_widget.dart`（`showCustom` → `showError`、メッセージ整形）

**Status**: ✅ 修正完了

---

### 5. 購入ページのスクリーンショット取得対応（IAP_MOCK / StoreKit 設定） ✅

**Purpose**: App Store Connect の有料App契約が未有効で `queryProductDetails` が空を返し、購入パネルの価格・ボタンが表示できないため、契約承認を待たずにスクリーンショットを撮れるようにする。

**Solution（2 系統を用意）**:

- `PurchaseService` に `--dart-define=IAP_MOCK=true` を追加。`_initialize()` / `loadProducts()` がストア接続をスキップし、現在プラットフォームの Premium SKU に対応するダミー `ProductDetails`（¥200/月・¥1,500/年、日本語／英語切替）を注入する。購入処理自体はストア未接続なので成立しない、UI 確認・スクショ専用。
- `ios/Runner/GoShop.storekit`（StoreKit Configuration File）を新規追加し、`prod` スキームの Run アクションに `StoreKitConfigurationFileReference` を設定。ただし `flutter run` はスキームの StoreKit 設定を無視する（Xcode の Product ▸ Run または `xcodebuild test` のみ有効）ため、サンドボックス購入フロー確認用として残置。

**検証**: iPhone 17 Pro Max シミュレータで `--dart-define=IAP_MOCK=true` により購入パネルの価格表示・ボタン有効化を確認。実機でサインイン後のパネル表示も確認。

**Modified Files**:

- `lib/services/purchase_service.dart`（`IAP_MOCK` 分岐・`_mockProducts()`）
- `ios/Runner/GoShop.storekit`（新規）
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme`（StoreKit 設定参照）

**Status**: ✅ スクショ取得可能な状態に

---

### 6. iOS 年払いプラン（`goshopping2_premium_annual`）のクライアント／サーバー対応 ✅

**Purpose**: iOS は年額 SKU にアンダースコア表記（`goshopping_premium_annual`）を使うため、Android のハイフン表記（`goshopping-premium-annual`）と分岐させ、サーバー検証でも受理する。

**Result**:

- `_ProductIds` を `premiumYearlyAndroid` / `premiumYearlyIOS` に分割し、`premiumYearly` を `Platform.isIOS` で出し分け。`all` を getter 化、検証用に `supportedPremium`（全プラットフォーム分）を追加。
- `isSupportedProductId` / `purchaseTypeForProductId` を `supportedPremium.contains(...)` ベースに整理。
- フォールバック価格を実価格に更新（月額 `US$2` → `US$1.99`、年額 `¥2,000` / `US$20` → `¥1,500` / `US$14.99`）。
- Cloud Functions（`verifyPurchase`）の許可商品 ID セットに `PREMIUM_ANNUAL_IOS_ID` を追加。未追加だと iOS の年払い購入がサーバー検証で拒否されていた。
- 設定パネル（`PurchasePlanPanel`）に iOS 向けのサブスクリプション注意事項（自動更新・請求タイミング・解約方法）と、プライバシーポリシー／利用規約への外部リンクを追加。対応する文言を 5 言語の `AppTexts` に追加。

**Modified Files**:

- `lib/services/purchase_service.dart`
- `functions/index.js` / `functions/receipt_verification.js`
- `lib/widgets/settings/purchase_plan_panel.dart`
- `lib/l10n/app_texts.dart` / `app_texts_en.dart` / `app_texts_ja.dart` / `app_texts_pt.dart` / `app_texts_zh_hans.dart`

**Status**: ✅ 実装完了（実機での年払い購入 E2E は有料App契約有効化後に実施予定）

---

### 7. App Store 用スクリーンショットのアルファチャンネル問題 ✅

**Purpose**: シミュレータで撮影したスクリーンショットが App Store Connect に「サイズが正しくない」と表示されアップロードできない。

**Root Cause**: `xcrun simctl io screenshot` の PNG は RGBA（アルファチャンネル付き）で保存される。App Store Connect はアルファチャンネル付き画像を拒否するが、エラーメッセージが「サイズが不正」という紛らわしい表示になる。ピクセルサイズ（1320×2868）自体は 6.9 型スロットで正しかった。

**Solution**: ImageMagick でアルファを不透明背景に合成する一括変換スクリプトを用意（`magick in.png -background white -alpha remove -alpha off -strip out.png`）。変換後は `1320×2868 / RGB / hasAlpha:no` となりアップロード可能。
※ App Store Connect のメディアマネージャは、正しい画像でもフロントエンドの状態が固まって同種のエラーを誤表示することがあり、ページ再読み込みで解消する場合がある。

**Status**: ✅ 変換手順を確立（スクリプトはリポジトリ外に配置）

---

### 8. TestFlight 用 release build 33（IPA）のビルド ✅

**Purpose**: App Attest を production 環境化した状態で、TestFlight 配布用 IPA を生成する。

**Result**:

- `pubspec.yaml` のビルド番号を `32` → `33` に更新。
- `flutter build ipa --release --flavor prod --export-method app-store` を実行し、`** ARCHIVE SUCCEEDED **` / `** EXPORT SUCCEEDED **`。
- 生成物: `build/ios/ipa/go_shop.ipa`（約 42MB）。バージョン `1.1.0 (33)`、Bundle ID `net.sumomo-planning.goshopping`、Apple Distribution 署名（Team 9A34XAPY8W）、arm64、dSYM 同梱、`get-task-allow=false` / `beta-reports-active=true`。
- 埋め込み entitlements に `appattest-environment` が含まれないことを確認（＝ production 環境で App Attest が動作）。

**Modified Files**:

- `pubspec.yaml`（`version: 1.1.0+33`）

**Status**: ✅ ビルド成功（App Store Connect へのアップロードは未実施）

---

## 🐛 発見された問題

### `flutter run` 実機起動が端末ロックで失敗していた ✅

- **症状**: Xcode build・インストールは成功するが、アプリ起動段階で `Error running application`
- **原因**: 端末ロック中に `devicectl` が起動要求 → `FBSOpenApplicationErrorDomain error 7 (Locked)`
- **対処**: ロック解除状態で実行。検証中は自動ロックを一時「なし」に
- **状態**: 解決（手順化）

### `Release-prod` に App Attest entitlement が未配線だった ✅

- **症状**: prod リリースビルドで App Attest が機能しない
- **原因**: `CODE_SIGN_ENTITLEMENTS` が `Release` コンフィグにのみ設定され、非継承の `Release-prod` / `Profile-prod` では無効
- **対処**: 両コンフィグに配線
- **状態**: 修正完了

### 実機サインインが App Check の App Attest 403 で常に失敗していた ✅

- **症状**: メール／パスワードのサインインが `firebase_auth/internal-error (17999)` で必ず失敗
- **原因**: `appattest-environment = development` 固定のため、Firebase App Check（production の App Attest サーバでのみ検証）が `exchangeAppAttestAttestation` で 403 → placeholder トークン → identitytoolkit 401
- **対処**: entitlement からキーを削除（配布ビルドは production 環境に）。手元検証用に `APP_CHECK_DEBUG` フラグを追加
- **状態**: 修正完了・実機でサインイン成功を確認

### グループ作成失敗時にエラー内容がユーザーへ通知されていなかった ✅

- **症状**: 上限到達などの例外が SnackBar に反映されない／`Exception: ` 接頭辞が露出
- **原因**: ダイアログごとにエラー表示処理がばらついていた
- **対処**: 3 ダイアログを `SnackBarHelper.showError` に統一し、メッセージを整形
- **状態**: 修正完了

### シミュレータのスクリーンショットが App Store Connect にアップロードできなかった ✅

- **症状**: 「画像のサイズが正しくない」でアップロード不可（サイズ 1320×2868 は正しい）
- **原因**: `simctl` の PNG が RGBA。ASC はアルファチャンネル付き画像を拒否するがメッセージが紛らわしい
- **対処**: ImageMagick でアルファ除去する変換手順を整備
- **状態**: 解決

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ `flutter run` 実機起動失敗（端末ロック）の切り分け（完了日: 2026-09-07）
2. ✅ App Attest entitlements の `Release-prod` / `Profile-prod` 配線（完了日: 2026-09-07）
3. ✅ 実機サインイン失敗（App Attest 環境 / App Check 403）の根本原因特定・修正（完了日: 2026-09-07）
4. ✅ グループ作成失敗時のエラー通知改善（完了日: 2026-09-07）
5. ✅ iOS 年払いプランのクライアント／サーバー対応（完了日: 2026-09-07）
6. ✅ App Store スクショのアルファチャンネル問題の解決手順確立（完了日: 2026-09-07）
7. ✅ TestFlight 用 release build 33（IPA）生成（完了日: 2026-09-07）

### 未着手 / 継続 ⏳

1. ⏳ TestFlight build 33 のアップロードと、実機での App Attest（production）サインイン確認（Priority: High）
2. ⏳ Premium 年払いプランの実機購入 E2E（有料App契約有効化後）（Priority: High）
3. ⏳ App Store 用スクリーンショットの残りサイズ撮影・アップロード（Priority: Medium）
4. ⏳ Firebase App Check の Authentication enforce 状態の最終確認（App Attest 本番動作の確認後）（Priority: Medium）

---

## 💡 技術的学習事項

### 「インストールは成功するが起動しない」は `FBSOpenApplicationErrorDomain error 7` を見る

**問題パターン**:

```text
# ❌ ビルドエラーや署名エラーを疑い続ける
Xcode build done → App installed → Error running application
```

**正しいパターン**:

```text
# ✅ devicectl の launch ログを読む
FBSOpenApplicationErrorDomain error 7 / BSErrorCodeDescription = Locked
  → 端末ロック。署名・entitlements は無関係
```

**教訓**: `flutter run` の「Could not run ... Try launching Xcode」は汎用メッセージ。verbose で `devicectl device process launch` の JSON エラーまで見ると、ロック・Developer Mode 未有効・プロファイル不一致などが区別できる。

---

### Firebase App Check + App Attest は production 環境が必須

**問題パターン**:

```text
# ❌ App Attest の entitlement を development のままにする
com.apple.developer.devicecheck.appattest-environment = development
  → exchangeAppAttestAttestation が常に 403 "App attestation failed"
  → Firebase Auth が placeholder トークンを送信 → identitytoolkit 401
```

**正しいパターン**:

```text
# ✅ entitlement のキー自体を指定しない
未指定 → App Store / TestFlight 配布ビルドは自動的に production 環境
       → Firebase の検証が通る
ローカル（development 署名）検証は App Check の Debug プロバイダ + デバッグトークンを使う
```

**教訓**: App Attest の development 環境は Apple の開発用アテストサーバに対して有効なだけで、Firebase App Check のバックエンドは production サーバでしか検証しない。`devicecheckd` のログに `Development environment override set.` が出ていたら環境ミスマッチを疑う。実機直インストールのローカルビルドで enforce 下の確認をするには、`kDebugMode` 相当のフラグで Debug プロバイダに切り替え、出力されたデバッグトークンを Firebase Console に登録する。

---

### `flutter run` はスキームの StoreKit Configuration を適用しない

**教訓**: `.storekit` を Xcode スキームの Run アクションに設定しても、`flutter run` は自前で `simctl launch` するため無視される（Xcode の Product ▸ Run または `xcodebuild test` のみ適用）。有料App契約の承認前に購入 UI のスクショを撮るなら、アプリ側にモック用の `--dart-define` を用意するのが確実。

---

### App Store Connect はアルファチャンネル付き画像を「サイズが不正」と誤表示する

**教訓**: `xcrun simctl io screenshot` の PNG は RGBA。App Store Connect はアルファチャンネルを拒否するが、エラーは「画像のサイズが正しくありません」と表示されるため原因を見誤りやすい。`sips -g hasAlpha` で確認し、`magick ... -alpha remove -alpha off` でフラット化する。ピクセルサイズが規定どおりでも弾かれる場合はアルファを疑う。

---

## 🕐 午後の追記（審査提出準備・スクリーンショット・シミュレータ検証）

※ 午後の作業はコンソール操作・シミュレータ検証が中心で、コード変更はなし。

### A. スクリーンショット撮影環境の構築 ✅

- iPhone 17 Pro Max（6.9型 / 1320×2868）と iPad Pro 13インチ M5（13型 / 2064×2752）のシミュレータを起動し、`--dart-define=IAP_MOCK=true` でアプリを実行。購入パネルがモック価格（¥200/月・¥1,500/年）で表示されることを確認。
- 購入パネルはサインイン必須の画面配下にあるため、シミュレータ機種ごとに発行される App Check デバッグトークンを Firebase Console のデバッグトークンに登録してサインインする運用を確認（実機用トークンとは別。トークンは秘密情報のためコミット・記録しない）。

### B. App Check enforce 解除直後に Firestore が全 `permission-denied` になった件 ✅

- **症状**: Auth / Firestore の App Check を「適用しない」に変更した直後、iPad シミュレータでリスト作成が `[cloud_firestore/permission-denied]` で失敗。プロフィール同期・課金タイプ取得・ニュース取得・グループ取得もすべて同エラー。
- **切り分け**: `firestoreNews`（ルールは `allow read: if true` の無条件公開）の読み取りまで `permission-denied` になっていた → セキュリティルールではなく App Check がリクエストを弾いている。
- **原因**: App Check enforce 解除の反映には最大 15〜20 分かかり、その間クライアントは無効トークンのまま拒否され続ける。加えて当該シミュレータのデバッグトークンが未登録だった。
- **対処**: シミュレータのデバッグトークンを登録し、`flutter run` でホットリスタート（App Check 再初期化）すれば enforce が残っていても通る。enforce 解除で通す場合は反映まで待つ。Firestore の App Check は「アプリ単位」で解除する必要がある（API 単位ではない）。
- **状態**: 切り分け完了・回避手順を確立（設定変更のみ、コード変更なし）

### C. App Store Connect の提出ステータス整理 ✅

- 「審査準備完了（Ready to Submit）」は必須項目が揃っただけで、**まだ提出していない／審査に入っていない**状態であることを確認。「審査へ提出」を押して初めて「審査待ち」→「審査中」へ進む。
- App 内課金（サブスク）の「提出準備完了」も同義。単体では提出できず、アプリのバージョン提出時に同梱する。提出前に TestFlight にアップロードした build をバージョンへ紐付ける必要がある。

---

## 🗓 翌日（2026-09-08）の予定

1. TestFlight build 33 を App Store Connect へアップロードし、実機で App Attest（production）経由のサインインを確認する
2. App Store 用スクリーンショットの残りサイズを撮影し、アルファ除去のうえアップロードする
3. 有料App契約が有効化されたら、Premium 月額／年払いの実機購入・復元を E2E で確認する
4. App Check の Authentication enforce 状態を最終確認する（本番 App Attest の動作確認後）
5. アプリバージョンに build 33 と App 内課金を紐付けて審査へ提出する

---

## 📝 ドキュメント更新

| ドキュメント                                                       | 更新内容                                                                                                              |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `docs/daily_reports/2026-09/daily_report_20260907.md`              | 本日の日報を新規作成（午後にスクリーンショット・App Check 反映遅延・審査提出ステータスの追記）                        |
| `ios/Runner.xcodeproj/project.pbxproj`                             | App Attest entitlements を `Release-prod` / `Profile-prod` に配線                                                     |
| `ios/Runner/RunnerRelease.entitlements`                            | `appattest-environment = development` を削除（配布ビルドを production 環境に）＋経緯コメント                          |
| `lib/main.dart`                                                    | `--dart-define=APP_CHECK_DEBUG=true` で App Check の Debug プロバイダを選択可能に                                     |
| `lib/services/purchase_service.dart`                               | iOS/Android 年額 SKU 分岐、`supportedPremium`、フォールバック価格更新、`--dart-define=IAP_MOCK=true` のダミー商品注入 |
| `lib/widgets/settings/purchase_plan_panel.dart`                    | iOS 向けサブスク注意事項・法的リンクを追加                                                                            |
| `lib/l10n/app_texts*.dart`（5言語）                                | `subscriptionNotesTitle` / `subscriptionNotesBody` を追加                                                             |
| `functions/index.js` / `functions/receipt_verification.js`         | サーバー検証の許可商品 ID に `goshopping_premium_annual`（iOS 年払い）を追加                                          |
| `lib/widgets/group_creation_with_copy_dialog.dart` ほか2ダイアログ | グループ作成失敗時に `SnackBarHelper.showError` で理由を通知                                                          |
| `ios/Runner/GoShop.storekit` / `prod.xcscheme`                     | スクショ／サンドボックス確認用の StoreKit Configuration を追加                                                        |
| `pubspec.yaml`                                                     | TestFlight 用に `version: 1.1.0+33` へ更新                                                                            |
| 指示書・README                                                     | 更新なし（理由: 恒久ルールやアーキテクチャの変更を伴わないため）                                                      |
