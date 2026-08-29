# 開発日報 - 2026年08月26日

## 📅 本日の目標

- [x] 昨日の日報と課金・UIモードの現状を確認する
- [x] FreeユーザーでもMultiモードを選択できるようにする
- [x] サブスク課金実装のコードレビューと不整合箇所の修正を実施する
- [x] 変更箇所の静的解析、単体・結合テスト、差分チェックを実施する
- [ ] Android / iOSの実機サンドボックスで月額SKUの購入・復元を確認する
- [ ] 購入レシートのサーバー検証と失効・解約同期を設計する

---

## ✅ 完了した作業

### 1. FreeユーザーのMultiモード選択を許可 ✅

**Purpose**: Freeプランでも、シングルモードとマルチモードを自由に選択できるようにする。

**Background**: 昨日、Free / Premiumのグループ数・メンバー数制限とPremium月額購入導線を実装した。その際、設定画面のSingle → Multi切り替えにPremium購入ゲートが残っており、FreeユーザーはMultiモードを選択できない状態だった。

**Problem / Root Cause**:

```dart
// ❌ Freeの場合は購入フローへ進み、Multiモードを保存しない
final isPremium = ref.read(isPremiumActiveProvider);
if (!isPremium) {
  await purchaseService.buyPremiumMonthly();
  return;
}
```

**Solution**:

```dart
// ✅ Free / Premiumに関係なくMultiモードを保存する
await _saveMode(ref, AppUIMode.multi);
```

- `single → multi` のPremium判定、アップグレード確認ダイアログ、購入開始処理を削除
- Freeユーザーでも設定画面のスイッチからMultiモードへ切り替え可能に変更
- Freeプランのグループ数上限（最大3グループ）とメンバー数上限（1グループ最大10人）は、既存のグループ作成・メンバー追加処理で引き続き適用
- `multi → single` の切り替え時に行うFree制限（グループ数3以下・各10人以下）の確認は維持

---

### 2. サブスク課金実装のコードレビューと不整合箇所の修正 ✅

**Purpose**: 課金コード全体の現状確認およびレビューで検出された不整合（モード切替時の課金リセット、レガシー表示名、古い初期化ログ）を解消する。

**Problem / Root Cause**:

1. **モード切替時の課金破壊**:
   `app_ui_mode_switcher_panel.dart` の `Multi → Single` 切替時に `subscriptionProvider.notifier.resetToFree()` が呼ばれ、UIモードを変更しただけでPremium課金状態が無料プランへ初期化されていた。
2. **プラン表示名のレガシー残り**:
   `lib/models/purchase_type.dart` の `PurchaseType.subscribe.displayName` が旧プラン表記（`サブスク（¥100/2ヶ月）`）のままだった。
3. **起動ログの不整合**:
   `lib/widgets/app_initialize_widget.dart` に「課金機能無効化のためGoogle Play購入リストアをスキップ」という古いコメントとログが残っていた。

**Solution**:

1. **`resetToFree()` 呼び出しの削除**:
   `app_ui_mode_switcher_panel.dart` から `resetToFree()` および不要な `subscription_provider.dart` インポートを削除し、UIモードと課金状態を完全に独立化。
2. **`displayName` の更新**:
   `PurchaseType.subscribe` を `'Premiumプラン（月額）'`、`PurchaseType.purchase` を `'買い切り（旧プラン）'` へ更新。
3. **初期化ログ・コメントの更新**:
   起動時の課金管理は `purchaseSyncProvider`（Firestoreリアルタイム同期）および設定画面の手動復元で管理する旨の適切なログ・コメントへ更新。

**検証結果**:

| 検証 | 結果 |
| --- | --- |
| `flutter analyze lib/widgets/settings/app_ui_mode_switcher_panel.dart lib/models/purchase_type.dart lib/widgets/app_initialize_widget.dart` | 成功、問題なし（No issues found!） |
| `flutter test` | 全383件テスト成功（All tests passed!） |
| `git diff --check` | 成功 |

**Modified Files**:

- `lib/widgets/settings/app_ui_mode_switcher_panel.dart` - Free向けPremiumゲート削除、Multi→Single時の `resetToFree()` 削除
- `lib/models/purchase_type.dart` - `displayName` の表記を現行プランに更新
- `lib/widgets/app_initialize_widget.dart` - 課金初期化ログ・コメントを更新
- `instructions/50_user_and_settings.md` - Single → MultiをFree / Premium共通利用へ更新

**Status**: ✅ 完了・検証済み

---

## 🐛 発見された問題

### FreeユーザーがMultiモードを選択できない問題 ✅

- **症状**: Freeプランで設定画面のMultiモードを選択すると、Premium購入フローへ進み、モードが切り替わらない
- **原因**: `app_ui_mode_switcher_panel.dart` のSingle → Multi処理が `isPremiumActiveProvider` でゲートされていた
- **対処**: Premium判定と購入フローを削除し、Free / Premium共通で `_saveMode(ref, AppUIMode.multi)` を実行するよう変更
- **状態**: ✅ 修正完了

### Multi → Single 切り替え時に課金状態がリセットされる問題 ✅

- **症状**: MultiモードからSingleモードに切り替えると、購入済みのPremiumプランがローカルでFreeにリセットされる
- **原因**: `app_ui_mode_switcher_panel.dart` の `_onToggle` に `resetToFree()` の呼び出しが残っていた
- **対処**: `resetToFree()` の呼び出しおよびサブスクキャンセル関連処理を削除
- **状態**: ✅ 修正完了

### ストアレシートのサーバー検証未実装 ⚠️

- **症状**: 現在は端末の購入ストリームを起点にPremium状態をFirestoreへ保存している
- **原因**: Google Play / App Storeのレシートを検証するサーバー側処理が未実装
- **対処**: 本番公開前にストアAPIを使った検証、失効、解約状態の同期を実装する
- **状態**: 🔄 対応中

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ FreeユーザーのMultiモード選択不可（2026-08-26）
2. ✅ Multi→Single切り替え時の課金状態リセット不具合（2026-08-26）
3. ✅ Premium購入APIの`buyNonConsumable`互換エラー（2026-08-25）
4. ✅ 鍵世代不一致のconfirmed状態とオフライン鍵回復（2026-08-20）

### 対応中 🔄

1. 🔄 Premium月額のストアサンドボックス購入・復元確認（Priority: High）
2. 🔄 購入レシートのサーバー検証と失効・解約同期（Priority: High）

### 翌日継続 ⏳

- ⏳ Play Console / App Store Connectで月額SKUのテスター設定と実機購入確認
- ⏳ Cloud Functions等でレシート検証、失効、解約状態をFirestoreへ同期する設計

---

## 💡 技術的学習事項

### UIモードの選択権限と利用上限を分離する

**問題パターン**:

```dart
// ❌ モード選択そのものをPremium権限で制限する、またはモード変更で課金を操作する
if (!isPremium) return;
await ref.read(subscriptionProvider.notifier).resetToFree();
```

**正しいパターン**:

```dart
// ✅ モードは自由に選択可能にし、課金状態の変更とモード変更を連動させない
await _saveMode(ref, AppUIMode.multi);
```

**教訓**: 表示モードの選択可否と、Free / Premiumのデータ操作上限・課金状態は独立した責務として扱う。表示形式を切り替えただけで課金権限が影響を受ける副作用を排除した。

---

## 🗓 翌日（2026-08-27）の予定

1. Android / iOSの実機サンドボックスで月額SKUの購入・復元を確認する
2. Cloud Functions等によるレシート検証、失効、解約状態同期の設計を進める
3. Free / Premiumのグループ数・メンバー数・広告表示を実機で確認する

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `instructions/50_user_and_settings.md` | Single → MultiをFree / Premium共通利用へ更新 |
| `docs/daily_reports/2026-08/daily_report_20260826.md` | 本日の変更内容、コードレビュー修正内容、検証結果、継続課題を記録 |
| その他 | 更新なし。今回の変更は既存のユーザー・設定仕様書への反映で完了 |

