# 開発日報 - 2026年10月19日

## 📅 本日の目標

- [x] AdMob の「欧州の規制」対応として、広告の同意フローと同意の取り消し入口（プライバシー設定）を実装する
- [x] SH 54D の UMP テストデバイスIDを取得し、dev で EEA 向けの同意フローを確認できるようにする
- [x] iOS 版で課金パネルを既定で非表示にし、ビルドオプションで表示できるようにする
- [x] ビルド番号を 46 に上げる
- [x] 米国の州規制（CCPA 等）への対応状況を確認し、dev で確認する地域を切り替えられるようにする
- [x] 広告同意がないユーザーのマルチモード切り替えを禁止し、注意を表示する
- [x] 広告同意の状況を Firestore の `users/{uid}` に保存する
- [x] Premium ユーザーの家族特典クーポンを実装する
- [x] 家族特典の Functions と Security Rules をデプロイする（prod・dev）
- [x] SH 54D の dev で同期アイコンが赤のままになる問題を解消する
- [x] 広告同意がないのにホーム画面にバナーが出る問題を修正する
- [x] アプリ内ニュースのコレクション名の綴り違いを直す（prod・dev）
- [ ] AdMob コンソールで GDPR メッセージを公開する
- [ ] SH 54D で同意ダイアログと取り消し入口の動作を確認する

---

## ✅ 完了した作業

### 1. AdMob の広告同意（UMP）と取り消し入口 ✅

**Purpose**: AdMob から、欧州の規制に従って広告を配信するには同意の取り消しリンクを用意するよう求められた。

**Problem / Root Cause**:

- `AdService.initialize()` は `MobileAds.instance.initialize()` を呼ぶだけで、同意を確認する仕組み（UMP）がなかった。そのため取り消し入口だけでなく、最初の同意ダイアログもなかった。

**Solution**:

- `AdService.initialize()` で、まず UMP の同意情報を更新し、必要なら同意フォームを表示するようにした。`canRequestAds()` が `true` のときだけ SDK を初期化し、インタースティシャルを読み込む（メソッドのシグネチャは変更なし）。
- `shouldShowBannerAd()` は同意の確認が終わるのを待ち、`canRequestAds()` が `false` ならバナーを出さない。
- 設定画面に `AdPrivacyOptionsPanel`（「広告のプライバシー設定」）を追加した。`getPrivacyOptionsRequirementStatus()` が `required` のときだけ表示し、`ConsentForm.showPrivacyOptionsForm()` で同意の変更・取り消しができる。EEA・英国・スイス以外では表示されない。
- 文言を日・英・葡・中の4言語に追加した。
- dev では `.env` の `ADMOB_UMP_DEBUG_EEA=true` と `ADMOB_UMP_TEST_DEVICE_IDS` で、日本から EEA 向けの同意フローを確認できるようにした。

**Modified Files**:

- `lib/services/ad_service.dart`
- `lib/widgets/settings/ad_privacy_options_panel.dart`（新規）
- `lib/pages/settings_page.dart`
- `lib/l10n/app_texts.dart`、`app_texts_ja.dart`、`app_texts_en.dart`、`app_texts_pt.dart`、`app_texts_zh_hans.dart`
- `instructions/50_user_and_settings.md`

**Status**: ✅ 実装完了（AdMob コンソールでのメッセージ公開と実機確認は未実施）

---

### 2. SH 54D の UMP テストデバイスID ✅

**Solution**:

- dev 版を SH 54D で起動し、logcat の `addTestDeviceHashedId` から ID を取得した: `D2E2C1DE1E3945DAB1D40EE530842094`
- ローカルの `.env`（git 管理外）に `ADMOB_UMP_DEBUG_EEA=true` と上記 ID を追記した。

**Status**: ✅ 完了

---

### 3. iOS 版の課金パネルを既定で非表示 ✅

**Purpose**: 10/17 に決めた方針（iOS の課金は2027年1月に提出）に合わせて、それまでの iOS ビルドでは課金パネルを出さない。

**Solution**:

- `PurchasePlanPanel.isAvailable` を追加し、iOS では `false` を返すようにした。設定画面はこれが `true` のときだけパネルを表示する。
- iOS で表示させるビルドオプション:
  - `--dart-define=IOS_PURCHASE_PANEL=true`: 2027年1月の提出ビルド用
  - `--dart-define=IAP_SALES_OPEN=true`: Sandbox テスト用（課金開始日前でも購入を受け付ける。リリースビルドには付けない）
- Android は変更なし。購入ストリームの購読（`PurchaseService.initialize()`）は iOS でも従来どおり行う。

**Modified Files**:

- `lib/widgets/settings/purchase_plan_panel.dart`
- `lib/pages/settings_page.dart`
- `instructions/50_user_and_settings.md`

**Status**: ✅ 完了（iOS 実機での表示確認は未実施）

---

### 4. ビルド番号 46 ✅

- `pubspec.yaml` を `1.2.0+46` に、`AGENTS.md` のビルド目標バージョンも `1.2.0+46` に更新した。

**Test Results**: `flutter test` 415件成功、3件失敗（`test/auth/` の3ファイル。モックの再生成が必要な既知の問題で、今回の変更とは無関係）

---

### 5. 米国の州規制への対応確認と dev の確認地域の切り替え ✅

**Purpose**: 米国州規制（CCPA 等）でのデータ利用同意にも対応しているか確認する。

**Solution**:

- 米国州規制は起動時の同意ではなく、ユーザーが自分でオプトアウトできる入口が必要。これは項目1の「広告のプライバシー設定」が兼ねる（AdMob コンソールで「米国の州規制」メッセージを公開すると対象州で表示される）。`google_mobile_ads` 9.0.0 は Android の UMP 4.0.0 を含み対応済み。
- dev の確認地域を `.env` の `ADMOB_UMP_DEBUG_GEOGRAPHY=eea` / `us` / `other` で切り替えられるようにした（旧設定 `ADMOB_UMP_DEBUG_EEA=true` は `eea` と同じ扱い）。ローカルの `.env` は `eea` に変更済み。

**Modified Files**:

- `lib/services/ad_service.dart`
- `instructions/50_user_and_settings.md`

**Status**: ✅ 完了（AdMob コンソールでのメッセージ公開と実機確認は未実施）

---

### 6. 広告同意がないユーザーのマルチモード切り替えを禁止 ✅

**Purpose**: 広告を表示できない無料ユーザーには、マルチモードを使わせない。

**Solution**:

- 対象は UMP の `canRequestAds()` が `false` の無料ユーザー（同意フォームを未回答のまま閉じた、エラーなど）。同意を拒否した EEA ユーザーや米国州でオプトアウトしたユーザーは制限付き広告が配信されるため対象外とした（GDPR の「自由な同意」との関係もあり、拒否まで対象にするのは見送り）。課金ユーザーは広告が出ないため対象外。
- `multiModeBlockedByAdConsentProvider` を追加した。管理モード切替パネルは、シングルモードかつ対象のときスイッチを無効にし、注意文と「広告への同意を行う」ボタンを表示する。ボタンは `AdService.requestConsentAgain()` で同意フォームを再表示する。
- マルチ → シングルの切り替えは同意に関係なく可能。
- 文言を4言語に追加した。

**Modified Files**:

- `lib/providers/ad_consent_provider.dart`（新規）
- `lib/services/ad_service.dart`
- `lib/widgets/settings/app_ui_mode_switcher_panel.dart`
- `lib/widgets/settings/ad_privacy_options_panel.dart`
- `lib/l10n/app_texts*.dart`
- `instructions/50_user_and_settings.md`

**Status**: ✅ 実装完了（実機確認は未実施。リリース前のためビルド46に含める）

---

### 7. 課金ユーザーの案内と、広告同意の状況の Firestore 保存 ✅

**Solution**:

- 管理モード切替パネルの注意文に「Premiumプランに加入してもマルチモードを利用できる」旨を追加した。課金パネルを表示できる環境（`PurchasePlanPanel.isAvailable`）でのみこの文言にし、課金パネル非表示中の iOS では従来の文言のままにした。4言語に追加。
- 同意状況を `users/{uid}.adConsent`（`consentStatus` / `canRequestAds` / `privacyOptionsRequired` / `platform` / `updatedAt`）に保存するようにした。起動時の同意確認後、同意フォームの再表示後、プライバシー設定フォームの後、サインイン・ユーザー切替時に保存する。前回から変化がなければ書き込まない。
- ユーザードキュメントが未作成のときは `update()` が `not-found` になるため保存をスキップする（新規作成時の `appUIMode: 0` などの初期値を飛ばさないため）。Security Rules は自分のドキュメントの更新を許可済みのため変更不要。

**Modified Files**:

- `lib/services/ad_service.dart`
- `lib/services/firestore_user_name_service.dart`
- `lib/widgets/app_initialize_widget.dart`
- `lib/widgets/settings/app_ui_mode_switcher_panel.dart`
- `lib/l10n/app_texts*.dart`
- `instructions/50_user_and_settings.md`

**Status**: ✅ 実装完了（実機での保存確認は未実施）

---

### 8. EEA・米国以外でのデータ提供同意（検討メモ） 📝

- 当面は実装しない。将来、利用データを他社や自社の他アプリ（木之本すもも企画）に提供する場合は、UMP（広告パートナー向け）とは別に、アプリ独自の同意ダイアログを全地域で表示できる。
- 日本の個人情報保護法では、個人データの第三者提供に原則本人の同意が必要。同意の文言の版・日時・結果を `users/{uid}` に保存し、プライバシーポリシーと Google Play のデータセーフティも更新する。
- iOS では、他社のアプリやデータと結び付けて使う場合は ATT（App Tracking Transparency）の許可も必要になる。

---

### 9. 家族特典クーポン ✅

**Purpose**: Premium の課金ユーザーにクーポンを発行し、入力した家族5人までが Premium と同じ機能を使えるようにする。

**決めた仕様**:

- 対象は月額・年額 Premium（`subscribe`）のみ。早期ダウンロード特典は対象外。
- 家族は広告非表示も含めて Premium 同等（`purchaseType: family`）。
- 家族の範囲は「発行者が参加しているグループのどれかに参加していること」で、入力時のみ確認する。後でグループを抜けても、発行者の Premium が有効な間は特典が続く。
- 同時に5人まで。発行者は家族を解除して枠を空けられる。
- 特典を受けている家族の `users/{uid}.familyBenefit.sponsorUid` に発行者の uid を保存する（表示用に `sponsorDisplayName` も保存）。
- iOS は App Store ガイドライン 3.1.1（アプリ内課金以外での機能解放）への配慮から、課金パネルと同じく既定で非表示（`IOS_PURCHASE_PANEL=true` で表示）。

**Solution**:

- 不正を防ぐため、発行・入力・解除は Functions の Callable で行い、5人の上限とグループ参加の確認はサーバー側でトランザクション内に行う。
- 発行者の Premium が切れたら家族を `free` に、再開したら `family` に戻す処理は、`users/{uid}` の Firestore トリガー1か所にまとめた（購入検証・RTDN・App Store 通知・早期特典の失効など、どこで `purchaseType` が変わっても反映される）。
- アカウント削除時は、発行者なら家族の特典とクーポンを、家族なら発行者側の枠を片付ける。
- `familyCoupon` / `familyBenefit` を Security Rules の保護対象に追加した。
- クライアントに `PurchaseType.family` を追加した（広告非表示、Hive の猶予は月額と同じ35日）。設定画面に `FamilyCouponPanel` を追加し、Premium ならクーポンと家族一覧（解除ボタン付き）、家族特典中なら発行者名、無料なら入力欄を表示する。文言は4言語。

**Modified Files**:

- `functions/family_coupon.js`（新規）、`functions/index.js`、`functions/test/family_coupon.test.js`（新規、19件）
- `firestore.rules`
- `lib/models/purchase_type.dart`、`lib/providers/purchase_sync_provider.dart`、`lib/providers/subscription_provider.dart`
- `lib/services/family_coupon_service.dart`（新規）、`lib/providers/family_coupon_provider.dart`（新規）
- `lib/widgets/settings/family_coupon_panel.dart`（新規）、`lib/pages/settings_page.dart`
- `lib/l10n/app_texts*.dart`、`test/services/family_coupon_service_test.dart`（新規、5件）
- `instructions/50_user_and_settings.md`

**Test Results**: Functions `npm test` 63件すべて成功。`flutter test` 420件成功、3件失敗（`test/auth/` の既知のモック再生成待ち）

**Status**: ✅ 実装・デプロイ完了（prod `goshopping-48db9` は Claude が、dev `gotoshop-572b7` は手動でデプロイ。いずれも Firestore と同じ `asia-northeast1`。実機確認は未実施）

---

### 10. SH 54D の dev 確認で見つかった問題 ✅

- **同期アイコンが赤のまま**: dev プロジェクトで Cloud Firestore の App Check 適用が有効になっており、SH 54D のデバッグトークン（アプリのデータ消去で再生成）が未登録だったため、Firestore がすべて `permission-denied` になっていた。dev の Firestore の App Check 適用をオフにして解消（ユーザー対応）。
- **広告同意がないのにホーム画面にバナーが出る**: ホーム画面のバナーは `AdService.initialize()` より先に作られるため、同意確認の開始前に前回起動時の同意状態で判定していた。`_canRequestAds()` で同意確認が未開始なら開始して完了を待つように修正した（`lib/services/ad_service.dart`）。
- UMP の同意情報の更新が `Error making request.` で失敗している（GDPR メッセージ未公開、または AdMob アプリと dev パッケージ名の組み合わせが原因の可能性。未確認）。

---

### 11. アプリ内ニュースのコレクション名の綴り違い ✅

**Problem / Root Cause**:

- アプリ（`FirestoreNewsService`）と Security Rules は `firestoreNews` を参照しているが、prod・dev とも Firestore 上のコレクション名が `furestorenews`（綴り違い）になっていた。ルールでも許可されていない名前のため、ニュースがアプリに表示されていなかった（10/17 掲載の「iOS版は2027年1月公開予定」も未表示だった）。

**Solution**:

- Firebase コンソールで `firestoreNews` コレクションを作り、`current_news` / `current_news_eng` を作り直した（ユーザー対応）。アプリでニュースが表示されることを確認済み。

**Status**: ✅ 完了

**参考（dev にコレクションが少ない理由）**: Firestore のコレクションはドキュメントができて初めて表示される。dev に無い `appConfig`（課金開始日、未設定時は既定値）、`testingStatus`（広告テスト用、未設定時はオフ）、`purchaseReceipts`（購入検証で作成）は、無くても動作に影響しない。

---

## 🔄 継続・確認事項

- **AdMob コンソール**: 「プライバシーとメッセージ」→「欧州の規制」で GDPR メッセージを作成・公開する。公開しないと同意ダイアログも取り消し入口も表示されない。
- **実機確認（SH 54D）**: dev を再起動して同意ダイアログが出ること、設定画面に「広告のプライバシー設定」が出てフォームを開けることを確認する。最初のダイアログをもう一度試すときはアプリのデータを消去する。
- **iOS（2027年1月提出）**: 提出ビルドは `--dart-define=IOS_PURCHASE_PANEL=true` を付けて作成する。
- **Play ストア**: ビルド46の AAB を作成してリリースする（ビルド45は未リリース）。
- **家族特典の実機確認**: Premium のアカウントでクーポン発行 → 同じグループの別アカウントで入力 → 広告が消え上限が上がること、発行者の解除で戻ること。
- **UMP のエラー**: dev で同意情報の更新が `Error making request.` になる原因を調べる（GDPR メッセージの公開後に再確認。解消しなければ AdMob アプリと dev パッケージ名の対応を確認）。
- **ホーム画面のバナー**: 同意なしの状態で、ホーム画面にもバナーが出ないことを SH 54D で確認する。
- **紛らわしいログ**: 同意がなく SDK を初期化しなかった場合も、`app_initialize_widget.dart` が「✅ AdMob SDK 初期化完了」と出力する。必要なら修正する。
- **App Check（dev）**: dev の Cloud Firestore の App Check 適用はオフにした。再びオンにする場合は、SH 54D の新しいデバッグトークンを登録する。9/24 登録の古い SH 54D 用トークンは不要なら削除する。
- **Firestore の不要なコレクション**: 綴り違いの `furestorenews`（prod・dev）と、prod の大文字の `Notifications`（現在のコードでは未使用）の中身を確認し、不要なら削除する。
- **テスト**: `test/auth/` の3ファイルのモック（`*.mocks.dart`）を再生成する。

---

## 📝 メモ

- UMP のテストデバイスIDは、端末の Android ID（Android 8 以降はアプリの署名ごとに異なる）から作られるため、adb で取れる値からは計算できない。アプリを一度起動して logcat から取得する。
- 同意を取り消しても `canRequestAds()` は `true` のままで、広告は同意内容（TCF 文字列）に従って制限付きで配信される。
- App Check のデバッグトークンはアプリのデータを消去すると作り直される。Firestore の App Check 適用が有効なプロジェクトでは、未登録のトークンだと Firestore がすべて `permission-denied` になり、ログイン中でも同期アイコンが赤（オフライン扱い）になる。
- VS Code のデバッグ起動が途中で切れると、dev アプリが Dart の起動前の黒い画面のまま止まることがある。デバッグを停止し、アプリを強制終了してから起動し直す。
- `dart format` をディレクトリ単位でかけると、関係のないファイルまで整形される。ファイルを指定して実行する。
