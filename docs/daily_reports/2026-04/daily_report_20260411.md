# 開発日報 - 2026年04月11日

## 📅 本日の目標

- [x] アプリ内課金システムを設計・実装する
- [x] Firestore `/users` コレクションに `purchaseType` フィールドを追加
- [x] 課金ステータスに応じた広告制御を実装
- [x] 設定画面に課金プランパネルを追加

---

## ✅ 完了した作業

### 1. アプリ内課金システム実装 ✅

**Purpose**: 有料ユーザーが広告を非表示にできるサブスク（¥100/2ヶ月）と買い切り（¥1,000）を実装する

**Background**:

- 既存の `AdService` では全ユーザーに広告を表示していた
- 既存の `subscription_provider.dart` は Hive ローカルのみ管理で、Google Play 課金と未連携だった
- Firestore `/users/{uid}` に `purchaseType` フィールドを新設し、クラウド同期された課金状態管理を実現

**Solution**:

① **`PurchaseType` enum**（新規）

```dart
// ✅ lib/models/purchase_type.dart
enum PurchaseType { free, subscribe, purchase }

extension PurchaseTypeExt on PurchaseType {
  bool get hidesInterstitialAds =>  // subscribe, purchase
      this == PurchaseType.subscribe || this == PurchaseType.purchase;
  bool get hidesBannerAds => this == PurchaseType.subscribe;
}
```

② **`FirestoreUserNameService` 拡張**（既存ファイル変更）

```dart
// ✅ 追加メソッド
static Future<PurchaseType> getPurchaseType()   // 取得
static Future<void> savePurchaseType(type)       // 保存
static Stream<PurchaseType> watchPurchaseType()  // リアルタイム監視
```

③ **`PurchaseService`**（新規）

```dart
// ✅ lib/services/purchase_service.dart
// Google Play IAP処理: 購入・復元・ストリーム監視
class PurchaseService {
  Future<void> buySubscription()      // goshopping_subscribe_2month
  Future<void> buyOneTimePurchase()   // goshopping_onetime_1000
  Future<void> restorePurchases()
}
```

④ **Riverpod プロバイダー**（新規）

```dart
// ✅ lib/providers/purchase_type_provider.dart
final purchaseTypeProvider = StreamProvider<PurchaseType>(...);
final purchaseServiceProvider = Provider<PurchaseService>(...);
```

⑤ **`AdService` 課金チェック追加**（既存ファイル変更）

```dart
// ❌ Before: インストール猶予チェックのみ
Future<bool> shouldShowSignInAd() async {
  // インストール90日チェックから開始
  ...
}

// ✅ After: 課金チェックを最初に行う
Future<bool> shouldShowSignInAd() async {
  final purchaseType = await FirestoreUserNameService.getPurchaseType();
  if (purchaseType.hidesInterstitialAds) return false;  // ← 追加
  // その後インストール90日チェック
  ...
}

// ✅ 追加: バナー広告スキップ判定
Future<bool> shouldShowBannerAd() async {
  final purchaseType = await FirestoreUserNameService.getPurchaseType();
  return !purchaseType.hidesBannerAds;
}
```

⑥ **`PurchasePlanPanel`**（新規）

設定ページに配置する課金UIパネル。以下を含む：

- 現在のプランバッジ表示
- サブスク・買い切り・無料の3プランを比較するテーブル
- 購入ボタン（現在のプランに応じて非表示）
- 購入を復元するボタン

⑦ **`SettingsPage` 更新**（既存ファイル変更）

`AppModeSwitcherPanel` の直下に `PurchasePlanPanel` を追加。

**Modified Files**:

- `pubspec.yaml` — `in_app_purchase: ^3.2.0` 追加
- `lib/models/purchase_type.dart` — 新規作成
- `lib/services/purchase_service.dart` — 新規作成
- `lib/providers/purchase_type_provider.dart` — 新規作成
- `lib/services/firestore_user_name_service.dart` — 課金タイプのCRUD/Stream追加
- `lib/services/ad_service.dart` — 課金チェックと `shouldShowBannerAd()` 追加
- `lib/widgets/settings/purchase_plan_panel.dart` — 新規作成
- `lib/pages/settings_page.dart` — `PurchasePlanPanel` 追加
- `docs/specifications/privacy_policy.md` — アプリ内課金ポリシー追記

**Commit**: `29722ce`
**Status**: ✅ 完了・コンパイルエラーなし

---

## 🐛 発見された問題

### セキュリティ考慮事項 ⚠️（未対応）

- **症状**: クライアントから `purchaseType: 'subscribe'` を Firestore に任意書き込みできる（レシート検証なし）
- **原因**: 現実装では Google Play の購入イベント（`PurchaseStatus.purchased`）を信頼している
- **対処**: 将来的に Cloud Functions でGoogle Play レシートサーバーサイド検証を実装推奨
- **状態**: 未対応（PoC段階として許容。本番前に対応が必要）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ DeviceIdService アウトレンジアクセス修正（2026-04-10）
2. ✅ CI keystoreセットアップ・prod releaseビルド（2026-04-10）
3. ✅ SH-54D prod release サインイン失敗（APIキー不一致修正）（2026-04-10）
4. ✅ Pixel 9 dev debug サインイン失敗（APIキー不一致修正）（2026-04-10）
5. ✅ インタースティシャル広告 90日猶予期間実装（2026-04-10）
6. ✅ アプリ内課金システム実装（2026-04-11）

### 対応中 🔄

なし

### 翌日継続 ⏳

- ⏳ Google Play Console に課金商品を登録する（`goshopping_subscribe_2month`, `goshopping_onetime_1000`）
- ⏳ Cloud Functions でレシート検証を実装（課金偽装防止）
- ⏳ 実機での課金フロー E2E テスト（Internal Testing トラック）

---

## 💡 技術的学習事項

### in_app_purchase パッケージのフロー

**購入完了後の必須処理**:

```dart
// ✅ Android: pendingCompletePurchase が true の場合は必ず completePurchase() を呼ぶ
// 呼ばないと Google Play が払い戻し扱いにする
if (purchase.pendingCompletePurchase) {
  await _iap.completePurchase(purchase);
}
```

**教訓**: `PurchaseStatus.purchased` + `PurchaseStatus.restored` の両方を処理すること。`restored` を忘れると再インストール後に課金が復活しない。

### Firestore ユーザードキュメントの `purchaseType` フィールド設計

- フィールドが存在しない場合は `free` として扱う（後方互換性）
- `PurchaseTypeExt.fromFirestoreValue(null)` → `PurchaseType.free` を返す設計

```dart
static PurchaseType fromFirestoreValue(String? value) {
  switch (value) {
    case 'subscribe': return PurchaseType.subscribe;
    case 'purchase':  return PurchaseType.purchase;
    default:          return PurchaseType.free;  // null・不明値はfreeにフォールバック
  }
}
```

---

## 🗓 翌日（2026-04-12）の予定

1. Google Play Console に課金商品を登録（優先度: High）
2. Internal Testing トラックで課金フロー確認（優先度: High）
3. Cloud Functions レシート検証の調査・設計（優先度: Medium）

---

## 📝 ドキュメント更新

| ドキュメント                            | 更新内容                                                                                 |
| --------------------------------------- | ---------------------------------------------------------------------------------------- |
| `instructions/50_user_and_settings.md`  | §8「アプリ内課金」セクション追加、設定ウィジェット一覧に `purchase_plan_panel.dart` 追加 |
| `docs/specifications/privacy_policy.md` | アプリ内課金ポリシー追記（JP・EN）                                                       |
