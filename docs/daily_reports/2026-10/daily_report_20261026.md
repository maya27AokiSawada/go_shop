# 開発日報 - 2026年10月26日

## 📅 本日の目標

- [x] プレオープン期間に作成したアカウントへの特典を実装する
- [x] ビルド `1.2.0+46` を作成し、Play ストアの内部テストにリリースする

---

## ✅ 完了した作業

### 1. プレオープン特典（課金開始の1か月後まで Premium 相当） ✅

**Purpose**: 課金開始（2027年1月予定）より前にアカウントを作成したユーザーに、課金開始日の1か月後まで Premium と同じ機能（広告非表示、グループ数・メンバー数の上限拡大）を無料で提供する。

**Solution**:

- `PreOpenBenefitService`（`lib/services/pre_open_benefit_service.dart`）を追加した。アカウント作成日時（Firebase Auth の `metadata.creationTime`）と課金開始日（Firestore の `appConfig/subscription.salesStartDate`、取得失敗時は既定値）で判定する。クライアントから書き換えられない値だけを使う。
- Firestore の `purchaseType` は変更しない（課金・家族特典の Functions の処理と干渉させないため）。
- `SubscriptionSalesConfig` に期間（`preOpenBenefitMonths = 1`）、終了日時の計算（翌月に同じ日がなければ月末日）、判定を追加した。
- `preOpenBenefitProvider` を追加した。終了日時に再評価する（最大1日ごとのタイマー）。
- `isPremiumActiveProvider` を「課金・無料体験の Premium」または「特典中」にした。Riverpod 外の広告判定（`AdService` のインタースティシャル・バナー）と、広告同意によるマルチモードの禁止も特典中は対象外にした。
- `groupLimitStatusProvider` は特典の読み込み中は超過扱いにしない。
- 設定画面の `PurchasePlanPanel` に「プレオープン特典を利用中」と終了日を表示する。特典終了前に加入できるよう、特典中も購入ボタンは表示する。
- 公開ページ `docs/specifications/premium_plan.md`（日・英）と `instructions/50_user_and_settings.md` に特典の説明を追記した。
- 課金開始日の取得処理を `PurchaseService` から `PreOpenBenefitService` に移した。

**Modified Files**:

- `lib/services/pre_open_benefit_service.dart`（新規）、`lib/providers/pre_open_benefit_provider.dart`（新規）
- `lib/config/subscription_sales_config.dart`、`lib/providers/subscription_provider.dart`、`lib/providers/group_limit_provider.dart`、`lib/providers/ad_consent_provider.dart`
- `lib/services/ad_service.dart`、`lib/services/purchase_service.dart`、`lib/widgets/settings/purchase_plan_panel.dart`
- `lib/l10n/app_texts.dart`、`app_texts_ja.dart`、`app_texts_en.dart`、`app_texts_pt.dart`、`app_texts_zh_hans.dart`
- `test/config/subscription_sales_config_test.dart`（新規）
- `docs/specifications/premium_plan.md`、`instructions/50_user_and_settings.md`

**Commit**: `7d35ddae`

**Status**: ✅ 実装済み（実機確認は未実施）

---

### 2. ビルド46を Play ストアの内部テストにリリース ✅

- `1.2.0+46` のリリース AAB を作成した（コミット `7d35ddae` 時点。10/24 のグループ上限超過の制限、dev のグループ作成の修正、プレオープン特典を含む）。
- Play Console の内部テストにリリースした。

**Note**: versionCode 46 はアップロード済みのため、今後 `lib/` などコードを変更して push するときは `+47` に上げるかを判断する。

---

## 🔄 継続・確認事項

- 内部テスト版で、設定画面に「プレオープン特典を利用中」と終了日が出ること、広告が出ないこと、Premium の上限でグループを作成できることを確認する。
- 10/24 の継続事項（グループ数の上限超過時の制限、dev のグループ作成の修正）の実機確認も、内部テスト版とあわせて行う。
