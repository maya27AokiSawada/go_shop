# 開発日報 - 2026年11月21日

## 📅 本日の目標

- [x] Flutter SDK を最新にする
- [x] ビルド目標を `1.2.0+49` に上げる
- [x] iOS のサブスク（課金パネル）を解放する
- [x] iPhone 17e（prod フレーバー）で Sandbox 購入・復元を確認する
- [ ] 解約・失効が反映されることを確認する（通知の受信待ち）

---

## ✅ 完了した作業

### 1. Flutter SDK 3.50.1 とビルド `1.2.0+49` ✅

- Flutter SDK を 3.50.0 から 3.50.1（2026-11-18 リリース、stable 最新）に更新した。
- `pubspec.lock` と Windows の生成ファイルの更新を反映した。
- `pubspec.yaml` と `AGENTS.md` のビルド目標を `1.2.0+49` にした。

### 2. iOS の課金パネルを解放 ✅

- `PurchasePlanPanel.isAvailable` を常に `true` にした。`IOS_PURCHASE_PANEL` は廃止した。
- 家族特典クーポンパネルも、課金パネルと同じ条件で表示される。
- 課金開始日（2027年1月）前の購入は、従来どおり `isSalesOpen` で受け付けない。Sandbox の購入テストだけ `--dart-define=IAP_SALES_OPEN=true` で受け付ける。

### 3. Sandbox の購入・復元を確認 ✅

**Problem**: 購入後に「購入状態を反映できませんでした」と表示された。

**Cause**:

- Cloud Functions の `verifyPurchase` が App Check で拒否されていた（ログ: `app: INVALID`、`auth: VALID`）。
- prod の iOS アプリは、App Check のプロバイダが未登録だった。App Attest だけでは、起動時の `exchangeDeviceCheckToken` が `App not registered` で失敗していた。
- デバッグトークンを古い iOS アプリ側に登録していたことも、切り分けを難しくした。

**Fix**: Firebase コンソールで DeviceCheck の鍵（.p8）を登録した。

**Result**:

- 購入、復元ともにサーバー検証が通り、Premium になった（`Purchase verified: platform=app_store, product=goshopping2_premium_monthly`）。
- Firestore の購入履歴を削除してから復元しても、Premium が戻り、Firestore に記録された。
- dev フレーバーは、Bundle ID（`net.sumomo_planning.go_shop.dev`）が商品の登録先と違うため、課金テストはできない。prod フレーバーで行う。

**Note**:

- 起動時に、古い Sandbox 取引（`goshopping_premium_annual`）が再送され、「未対応の商品IDです」のエラーが毎回記録される。その商品 ID は App Store にもうないため、放置する。製品版には影響しない。
- `flutter run` でインストールしたデバッグビルドは、ホーム画面のアイコンから起動できない（iOS 14 以降の仕様）。

### 4. App Store Server Notifications の受け口を公開 ✅

**Problem**: `appStoreNotifications` が prod に未デプロイだった。デプロイ後も、Cloud Run が認証ヘッダーのない Apple の通知を拒否していた（`The request was not authenticated`）。

**Fix**:

- `appStoreNotifications` を prod にデプロイした。
- `invoker: "public"` を `functions/index.js` に追加した。署名（`signedPayload`）はコード内で Apple のルート証明書により検証しているので、公開しても偽の通知は拒否される。
- `firebase deploy` では IAM の設定に失敗したため、Cloud Run のコンソールから「未認証の呼び出しを許可」を手動で設定した。
- 関数の URL を、App Store Connect の App Store Server Notifications（本番・Sandbox ともに V2）に登録した。

---

## 📝 残った課題・メモ

- 通知の受信と、失効が `free` に反映されることは、まだ確認していない。
  - サーバー側のログ（`appStoreNotifications`）で、`SUBSCRIBED` や `EXPIRED` などの受信を確認する。
  - Sandbox のサブスクは、月額が5分周期で、更新は最大6回まで。
  - Sandbox のテスターの管理（設定アプリの「Sandbox Apple Account」）は、iPhone 17e でエラーになり開けなかった。
  - 必要なら、App Store Connect の Sandbox テスターから「購入履歴を消去」を使う。
- 年額プランの購入は、まだ確認していない。
- Firebase コンソールに登録した App Check のデバッグトークンを、テスト後に削除する（古いアプリ側の登録も含む）。
- `flutter run` が iOS プロジェクトを Swift Package Manager に自動で移行した（`ios/Podfile.lock`、`project.pbxproj`、`swiftpm/Package.resolved`）。意図した変更ではなく、今回のコミットには含めていない。取り扱いを決める。
- 提出ビルドに `IAP_SALES_OPEN` を付けない。
