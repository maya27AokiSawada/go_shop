# 開発日報 - 2026年08月25日

## 📅 本日の目標

- [x] 鍵ローテーション機能のヘルプを更新する
- [x] Free / Premiumプランのグループ・メンバー上限と広告表示を実装する
- [x] Premium月額課金を設定画面から有効化できるようにする
- [x] ビルド番号28のAndroid prodリリースAPKを生成する
- [ ] Google Play / App Storeの実機サンドボックスで月額購入・復元を確認する
- [ ] ストアレシートのサーバー検証を実装する

---

## ✅ 完了した作業

### 1. 鍵ローテーションのヘルプ追記 ✅

**Purpose**: オーナーが実行するグループ鍵ローテーションの操作と画面状態を、アプリ内ヘルプで説明する。

**Solution**:

```markdown
### グループ鍵ローテーション
- オーナーのみ鍵ローテーションボタンを表示
- 新しい鍵を全メンバーへ配布
- 配布中は画面をロック表示
```

**Modified Files**:

- `lib/pages/help_page.dart` - 鍵ローテーションの説明を追加

**Commit**: `65a8149`
**Status**: ✅ 完了

---

### 2. Free / Premiumプランの利用制限と広告表示 ✅

**Purpose**: Freeプランの利用上限を、作成・追加・プラン切替の各経路で一貫して適用する。

**Problem / Root Cause**:

```dart
// ❌ グループ作成だけの制限では、メンバー追加やプラン切替時に
// Freeプランの利用上限を一貫して保証できない。
await repository.addMember(groupId, member);
```

**Solution**:

```dart
// ✅ Freeプランでは追加前に1グループ10人上限を確認する。
if (!isPremium && memberCount >= 10) {
  throw Exception('Free プランでは1グループのメンバーは10人までです。');
}
```

- Freeプランを最大3グループ、各グループ最大10人に制限
- 管理画面の直接リポジトリ呼び出しとProvider経由の両方でメンバー上限を検証
- PremiumからFreeへの切替時に、グループ数と全グループのメンバー数を確認して切替を停止
- Freeプランのログイン済みユーザーだけ、グループ一覧の末尾にバナー広告を表示
- アプリ内ヘルプ、ユーザーガイド、関連仕様書を現仕様に更新

**検証結果**:

| 検証 | 結果 |
| --- | --- |
| 変更対象のDart解析 | 新規エラーなし（既存警告のみ） |
| `git diff --check` | 成功 |

**Modified Files**:

- `lib/providers/shared_group_provider.dart`
- `lib/pages/group_member_management_page.dart`
- `lib/widgets/group_list_widget.dart`
- `lib/widgets/settings/app_ui_mode_switcher_panel.dart`
- `lib/pages/help_page.dart`
- `docs/knowledge_base/user_guide.md`
- `docs/specifications/provider_classes_reference.md`
- `docs/specifications/widget_classes_reference.md`

**Commit**: `84dbe27`, `ecff207`
**Status**: ✅ 完了

---

### 3. Premium月額課金の設定画面導線とAndroidリリースビルド ✅

**Purpose**: 登録済みの月額SKU `goshopping_premium_monthly` を使い、設定画面から購入・復元できるようにする。

**Problem / Root Cause**:

```dart
// ❌ 課金処理が無効で、新SKUをsubscribeへ変換していなかった。
static const bool _monetizationEnabled = false;
await _iap.buyNonConsumable(productDetails: product);
```

**Solution**:

```dart
// ✅ 現行in_app_purchase APIで月額SKUを購入する。
await _iap.buyNonConsumable(
  purchaseParam: PurchaseParam(productDetails: product),
);
```

- `PurchaseService` を有効化し、月額SKUだけを商品情報取得の対象に設定
- 購入・復元の成功時に月額SKUを `PurchaseType.subscribe` としてFirestoreへ反映
- `PurchasePlanPanel` を設定画面へ配置し、購入、復元、ストア未接続状態、Premium利用中状態を表示
- 表示価格はストアのローカル価格を優先し、未取得時は日本語で¥200/月、その他でUS$2/monthを表示
- 購入開始直後にMultiモードへ切り替えないようにし、Premium状態の反映後に切替可能とした
- `pubspec.yaml` の依存関係コメントの文字化けを修正
- `flutter build apk --release --flavor prod --dart-define=FLAVOR=prod` を実行し、`app-prod-release.apk`（約81.4MB）を生成

**検証結果**:

| 検証 | 結果 |
| --- | --- |
| `flutter analyze`（課金・設定UIの4ファイル） | 成功、問題なし |
| prodリリースAPKビルド | 成功 |
| APK versionCode | 28 |

**Modified Files**:

- `lib/services/purchase_service.dart`
- `lib/widgets/settings/purchase_plan_panel.dart`
- `lib/pages/settings_page.dart`
- `lib/widgets/settings/app_ui_mode_switcher_panel.dart`
- `pubspec.yaml`

**Commit**: `cfde912`
**Status**: ✅ 完了・ビルド検証済み

---

## 🐛 発見された問題

### in_app_purchase API不整合 ✅

- **症状**: prodリリースビルドで `buyNonConsumable(productDetails: ...)` の名前付き引数が見つからず停止
- **原因**: `in_app_purchase` 3.2系では `PurchaseParam` を `purchaseParam` 引数へ渡すAPIに変更されていた
- **対処**: `PurchaseParam(productDetails: product)` を使用する呼び出しへ変更
- **状態**: ✅ 修正完了。prodリリースAPKビルド成功

### ストアレシートのサーバー検証未実装 ⚠️

- **症状**: 現在は端末の購入ストリームを起点に `purchaseType` をFirestoreへ保存している
- **原因**: Google Play / App Storeのレシートを検証するCloud Functions等が未実装
- **対処**: 本番公開前にストアAPIを使うサーバー側検証と、失効・解約状態の同期を実装する
- **状態**: 🔄 対応中

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ 鍵世代不一致のconfirmed状態とオフライン鍵回復（2026-08-20）
2. ✅ 小型画面でのメンバー一覧テキストオーバーフロー（2026-08-20）
3. ✅ Premium購入APIの`buyNonConsumable`互換エラー（2026-08-25）

### 対応中 🔄

1. 🔄 Premium月額のストアサンドボックス購入・復元確認（Priority: High）
2. 🔄 購入レシートのサーバー検証と失効・解約同期（Priority: High）

### 翌日継続 ⏳

- ⏳ Play Console / App Store Connectで月額SKUのテスター設定と実機購入確認
- ⏳ Firestore Security RulesとCloud Functionsによるレシート検証設計

---

## 💡 技術的学習事項

### In-app Purchaseは購入開始と購入確定を分離する

**問題パターン**:

```dart
// ❌ 購入UIを開いた時点では、購入完了はまだ通知されていない。
await purchaseService.buyPremiumMonthly();
await saveMultiMode();
```

**正しいパターン**:

```dart
// ✅ 購入完了はpurchaseStreamで受け取り、Premium状態を同期する。
await purchaseService.buyPremiumMonthly();
return;
```

**教訓**: `buyNonConsumable()` は購入結果を返さず、確定結果は `purchaseStream` で届く。権限を広げるUI状態は、購入開始ではなく確認済みのPremium状態に基づいて変更する。

---

## 🗓 翌日（2026-08-26）の予定

1. Android / iOSの実機サンドボックスで月額SKUの購入・復元を確認する
2. Cloud Functions等でレシート検証、失効、解約状態をFirestoreへ同期する設計を実装する
3. Free / Premiumのグループ数・メンバー数・広告表示を実機で確認する

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
| --- | --- |
| `instructions/20_groups_lists_items.md` | Free/Premiumのグループ・メンバー上限と、複数経路での検証要件を追加 |
| `instructions/50_user_and_settings.md` | 月額SKU、設定画面の購入・復元導線、Premium同期、サーバー検証の未完了状態を更新 |
| `README.md` | バージョン28、Free/Premium制限、月額購入・復元機能を追記 |
| `docs/daily_reports/2026-08/daily_report_20260825.md` | 本日の実装・検証・継続課題を記録 |
