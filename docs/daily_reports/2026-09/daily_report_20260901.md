# 開発日報 - 2026年09月01日

## 📅 本日の目標

- [x] App Checkデバッグトークン登録後のFirestore同期エラーを解消する
- [x] Play購入済み状態がPremium UIへ反映されない経路を調査する
- [x] FreeプランでもSingle / Multiを切り替えられることをSH-54Dで確認する
- [x] SKU未取得時の購入UIを改善する
- [x] Android build 29のprod release AABを生成する
- [ ] Play Storeテストトラック配布版で購入・復元・Firestore反映をE2E確認する

## 📝 今日のTodo

- [ ] build 29 がクローズドテスト配布済みであることをPlay Consoleで確認する
- [ ] SH-54D / Pixel 9 にテストトラック版を入れて、prod package で起動確認する
- [ ] Premium購入フローを実行し、Google Play での支払い完了とFunctions `verifyPurchase` の成功を確認する
- [ ] Firestore への `purchaseType: subscribe` 反映と Premium UI 更新を確認する
- [ ] 購入復元経路を再確認し、既存購入が権限へ反映されるかを検証する
- [ ] 確認結果をログとして残し、必要なら RTDN / App Store Server Notifications の実装方針を整理する

---

## ✅ 完了した作業

### 1. App Check登録反映とFirestore同期復旧 ✅

**Purpose**: SH-54Dで赤く表示されていたAppBar同期アイコンを正常状態へ戻す。

**Background**: Firebase ConsoleへApp Checkデバッグトークンを登録した後も、Firestore同期が失敗していた。

**Problem / Root Cause**:

```text
Failed to exchange debug token
PERMISSION_DENIED: Missing or insufficient permissions.
```

- App Check登録前に取得されたトークン交換結果が実行中アプリに残っていた。
- Firestoreの強制同期失敗によりHybrid Repositoryのオンライン状態がfalseとなり、同期アイコンが赤く表示された。

**Solution**:

- SH-54Dのprodアプリを完全停止して再起動し、App Checkトークンを再交換した。
- prod package、Firebase Android App ID、接続先Firebaseプロジェクトが一致することを確認した。
- trackedコードのコメントに残っていた古いデバッグトークンを削除した。

**検証結果**:

| テスト | 結果 |
|---|---|
| App Check登録後のFirestoreアクセス | 成功 |
| Firestoreからのグループ同期 | 23グループ成功 |
| `flutter analyze lib/main.dart` | 問題なし |

**Modified Files**:

- `lib/main.dart`（デバッグトークン実値をコメントから削除）

**Status**: ✅ 完了・検証済み

---

### 2. 既所有購入の自動復元経路追加 ✅

**Purpose**: Play Storeでは購入済みだがFirestore権限が未反映のケースを、購入復元からFunctions検証へ接続する。

**Problem / Root Cause**:

```dart
// ❌ 購入開始不可時にエラー表示だけで終了
if (!started) {
  _setStatus(
    PurchaseFlowStatus.error,
    message: '購入手続きを開始できませんでした。',
  );
}
```

Play Billingが既所有などの理由で購入フローを開始しなかった場合、購入履歴を照会しないため、既存購入トークンが`verifyPurchase` Callableへ送られなかった。

**Solution**:

```dart
// ✅ 既存購入を復元し、購入ストリームから既存のFunctions検証へ流す
if (!started) {
  Log.warning('購入フローを開始できないため、既存の購入履歴を確認します');
  await restorePurchases();
}
```

**検証結果**:

| テスト | 結果 |
|---|---|
| PurchaseService単体テスト | 8件成功 |
| SH-54Dで購入履歴照会 | API呼び出し成功 |
| SH-54Dで復元購入イベント受信 | 対象なし |

**Modified Files**:

- `lib/services/purchase_service.dart`（購入開始不可時の自動復元）
- `test/services/purchase_service_test.dart`（自動復元の回帰テスト）

**Status**: ✅ クライアント経路修正・テスト済み。Play Store配布版でのE2E確認は継続

---

### 3. FreeプランのMultiモード切替を実機確認 ✅

**Purpose**: Freeプランでも最大3グループまで利用でき、Multiモードへ切り替えられる仕様を保証する。

**Problem / Root Cause**:

- SH-54DでMultiへ切り替えるとPremium購入を要求された。
- 実機で操作されていたのは、現行ソースではなく古いdev APKだった。
- 現行の`AppUIModeSwicherPanel`にはPremiumゲートがなく、Free / Premium共通でMultiへ切り替える実装になっていた。

**Solution**:

- Flutterの増分ビルドキャッシュを消去してdev/prod APKを再生成した。
- SH-54Dの`.dev` packageを現行dev APKで上書きした。
- Free状態でSingleからMultiへ切り替えた。

**検証結果**:

| テスト | 結果 |
|---|---|
| Free: Single → Multi | 成功 |
| 切替時のPremium購入要求 | 発生なし |
| 再起動後のMulti状態保持 | 成功 |

**Modified Files**:

- コード変更なし（現行実装は仕様どおり。旧dev APKの更新で解消）

**Status**: ✅ SH-54D実機検証済み

---

### 4. SKU未取得時の購入UI改善 ✅

**Purpose**: Play Storeから商品情報を取得できないとき、購入ボタンが無反応に見える問題を解消する。

**Problem / Root Cause**:

```text
未登録の商品ID: [goshopping_premium_monthly]
商品取得完了: []
```

- dev packageはprod packageとapplicationIdが異なり、prod SKUを取得できない。
- 従来UIはストア接続可否だけで購入ボタンを有効化したため、SKUがなくても押せてしまった。

**Solution**:

```dart
// ✅ ストア接続とSKU取得の両方を購入可能条件にする
bool get isPremiumMonthlyAvailable =>
    _products.any((product) => product.id == premiumMonthlyProductId);
```

- SKU未取得時は購入ボタンを無効化した。
- ストアアカウントとアプリ配布元の確認メッセージを表示した。
- 購入復元ボタンは利用可能なまま維持した。

**検証結果**:

| テスト | 結果 |
|---|---|
| SKU未取得時の購入ボタン | disabled確認 |
| SKU未取得理由の表示 | SH-54Dで確認 |
| Dart診断 | エラーなし |

**Modified Files**:

- `lib/services/purchase_service.dart`（月額SKU利用可否getter）
- `lib/widgets/settings/purchase_plan_panel.dart`（ボタン制御と案内表示）
- `instructions/50_user_and_settings.md`（課金復元・SKU・flavor別テスト条件）

**Status**: ✅ 完了・実機検証済み

---

### 5. Android build 29 AAB生成 ✅

**Purpose**: Play Storeテスト配布用の最新prod release App Bundleを生成する。

**Solution**:

- `pubspec.yaml`を`1.1.0+29`へ更新した。
- prod flavor、release、`--build-number=29`でAABを生成した。

**検証結果**:

| 項目 | 結果 |
|---|---|
| versionName | `1.1.0` |
| versionCode | `29` |
| AAB | `build/app/outputs/bundle/prodRelease/app-prod-release.aab` |
| サイズ | 79,044,745 bytes |
| 生成日時 | 2026-09-01 10:57:25 |

**Modified Files**:

- `pubspec.yaml`（build number 28 → 29）

**Status**: ✅ 生成完了

---

## 🐛 発見された問題

### App Check登録後も実行中アプリが旧交換結果を保持 ✅

- **症状**: Firestore全体が`PERMISSION_DENIED`となり同期アイコンが赤色
- **原因**: App Check登録前の失敗状態が実行中プロセスに残存
- **対処**: prodアプリを完全停止・再起動してトークン再交換
- **状態**: 修正完了

### dev packageでprod SKUを取得できない ✅

- **症状**: Premium購入ボタンを押してもストア画面が開かない
- **原因**: `.dev` applicationIdにprod商品が紐づいていない
- **対処**: SKU未取得時の購入ボタン無効化と理由表示
- **状態**: UI対応完了。購入E2EはPlay Storeテストトラックのprod packageで実施

### 復元対象購入がPlay Billingから返らない ⚠️

- **症状**: SH-54Dで購入履歴照会は成功するが復元イベントが0件
- **原因**: 現在のストアアカウント、アプリ配布元、SKU購入状態のどれに起因するかは未確定
- **対処**: 購入時と同じGoogleアカウントか確認し、Play Storeテストトラック配布版で再検証する
- **状態**: 調査継続

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ App Checkデバッグトークン反映とFirestore同期復旧（完了日: 2026-09-01）
2. ✅ 既所有時の購入履歴自動復元（完了日: 2026-09-01）
3. ✅ FreeプランのMultiモード切替実機確認（完了日: 2026-09-01）
4. ✅ SKU未取得時の購入UI改善（完了日: 2026-09-01）
5. ✅ Android build 29 AAB生成（完了日: 2026-09-01）

### 対応中 🔄

1. 🔄 Play Storeテストトラック配布版での購入・復元E2E（Priority: High）
2. 🔄 Functions依存のmoderate脆弱性の上流更新監視（Priority: Low）

### 未着手 ⏳

1. ⏳ Google Play RTDN / App Store Server Notificationsによる失効同期（Priority: High）

### 翌日継続 ⏳

- ⏳ build 29をPlay Storeテストトラックへアップロード
- ⏳ 購入時と同じGoogleアカウントでPremium購入・復元を再確認
- ⏳ `verifyPurchase`成功とFirestore `purchaseType: subscribe`反映を確認

---

## 💡 技術的学習事項

### Store購入状態とアプリ権限を分離する

**問題パターン**:

```dart
// ❌ 購入開始失敗を即エラーとして終える
if (!started) {
  showPurchaseError();
}
```

**正しいパターン**:

```dart
// ✅ 既所有の可能性があるため復元し、サーバー検証へ接続する
if (!started) {
  await restorePurchases();
}
```

**教訓**: Play Store上の所有状態だけではアプリ権限を付与しない。購入・復元トークンをFunctionsで検証し、Firestoreを権限の正としてUIへ反映する。

### flavorとストア商品はapplicationId単位で対応する

**問題パターン**:

```text
.dev packageでprod packageの商品IDを取得できる前提でテストする
```

**正しいパターン**:

```text
prod packageをPlay Storeテストトラックからインストールして購入E2Eを行う
```

**教訓**: ストア接続可と商品取得可は別状態としてUIで扱い、SKU未取得時は購入操作を無効化して理由を示す。

---

## 🗓 翌日（2026-09-02）の予定

1. build 29 AABをPlay Storeテストトラックへアップロード
2. SH-54DまたはPixel 9へPlay Store経由でprod版をインストール
3. Premium購入・復元・Functions検証・Firestore反映・UI更新をE2E確認
4. RTDN / App Store Server Notifications実装方針を整理

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `instructions/50_user_and_settings.md` | 購入開始不可時の自動復元、SKU未取得時UI、prod課金E2E条件を追記 |
| `docs/daily_reports/2026-09/daily_report_20260901.md` | 本日の日報を新規作成 |
| その他の指示書・README | 更新なし（アーキテクチャやセットアップ手順の変更なし） |
