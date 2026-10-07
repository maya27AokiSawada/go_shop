# 開発日報 - 2026年10月7日

## 📅 本日の目標

- [x] リリース目標バージョンを指示書に定義する
- [x] プレ公開期間中のPremium新規購入をブロックする
- [x] 課金開始日をFirestoreから読み出せるようにする
- [x] SH-54Dとエミュレーターへデプロイして確認する
- [x] リリース用AAB（1.2.0+43）をビルドする
- [x] Firestore Rulesを本番・開発の両プロジェクトへデプロイする
- [ ] Firestoreに課金開始日ドキュメントを作成する

---

## ✅ 完了した作業

### 1. リリース目標バージョンの指示書化 ✅

**Purpose**: エージェントが `sumomo-planning` へプッシュするとき、目標バージョンとの食い違いやバージョン更新漏れに気づけるようにする。

**実施内容**:

- `AGENTS.md` に「リリース目標バージョン」の節を追加（ストア公開目標は `1.2.0`）
- `sumomo-planning` へのプッシュ前に `pubspec.yaml` の `version` と目標バージョンを照合し、コード変更があるのに未更新なら質問するルールを定義
- ビルド番号は `1.2.0+1` ではなく `1.2.0+43` とした。`+N` はAndroidの `versionCode` になり、Google Playは過去より小さい値を受け付けないため、バージョン本体が上がってもリセットせず通番で増やす
- クローズドテスト用ビルド（+43）の作成後、次の開発ビルド用に `1.2.0+44` へカウントアップ

**Modified Files**:

- `AGENTS.md`
- `pubspec.yaml`

**Status**: ✅ 完了

---

### 2. プレ公開期間中のPremium新規購入ブロック ✅

**Purpose**: サブスク受付は2027年1月開始とし、それまではプレ公開中である旨を表示して新規購入を受け付けない。

**実施内容**:

- `PurchaseService.buyPremiumMonthly()` / `buyPremiumYearly()` は、課金開始日より前はストア購入UIを開かずに案内メッセージを返す
- 設定ページの `PurchasePlanPanel` は、未加入ユーザーに購入ボタンの代わりに「プレ公開中」「課金はyyyy年M月開始予定です。」の案内を表示する
- iOS向けの自動更新の注意書きは、購入ボタンがない間は非表示
- 既存の課金ユーザーはそのまま。「購入を復元」と購入ストリームで届いた取引の検証は止めていない
- 案内文言を日本語・英語・ポルトガル語・中国語の4言語に追加

**Modified Files**:

- `lib/config/subscription_sales_config.dart`（新規）
- `lib/services/purchase_service.dart`
- `lib/widgets/settings/purchase_plan_panel.dart`
- `lib/l10n/app_texts.dart` / `app_texts_ja.dart` / `app_texts_en.dart` / `app_texts_pt.dart` / `app_texts_zh_hans.dart`

**Status**: ✅ 完了

---

### 3. 課金開始日のFirestore読み出し ✅

**Purpose**: 課金開始日をアプリ更新なしで変更できるようにする。

**仕様**:

| 項目 | 値 |
|---|---|
| ドキュメントパス | `appConfig/subscription` |
| フィールド名 | `salesStartDate` |
| 型 | timestamp |

- `PurchaseService.refreshSalesStartDate()` が読み出しを行い、`PurchasePlanPanel` の初期化時に呼び出す
- ドキュメント・フィールドが未設定、または取得に失敗した場合は既定値の2027年1月1日（端末のローカル時刻）を使う
- 案内の年月は課金開始日から生成する。日付が可変になったため、固定の「2026年中は」という言い回しは使わない
- `firestore.rules` に `appConfig` の読み取りルールを追加（認証済みユーザーのみ読み取り可、書き込みはFirebase Console / Admin SDKのみ）

**Modified Files**:

- `lib/config/subscription_sales_config.dart`
- `lib/services/purchase_service.dart`
- `firestore.rules`
- `instructions/50_user_and_settings.md`

**検証結果**:

- `flutter test test/services/purchase_service_test.dart test/config/subscription_sales_config_test.dart`: 16件すべて成功
- `flutter analyze`（変更ファイル）: 新規の警告なし
- 実際のFirestoreドキュメントからの読み出しは未確認（ドキュメント未作成のため）

**Status**: ✅ 実装完了。ドキュメント作成は未実施。

---

### 4. 実機・エミュレーターへのデプロイとリリースビルド ✅

**実施内容**:

- `flutter build apk --debug --flavor prod --dart-define=FLAVOR=prod`: 成功
- エミュレーター `emulator-5554`（Android 17 / API 37）: `adb install -r` で上書きインストール成功
- SH-54D（Android 16 / API 36）: Playストア版 `1.1.0+42` と署名が一致せず `INSTALL_FAILED_UPDATE_INCOMPATIBLE` で失敗。Playストア版をアンインストールしてから入れ直した
- ユーザー確認で `1.2.0+43` に問題なし
- `flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod`: 成功（`app-prod-release.aab` 77.4MB、`1.2.0+43`）

**Status**: ✅ 完了。AABはクローズドテストへのリリース用。

---

### 5. Firestore Rulesのデプロイ ✅

**実施内容**:

- 本番 `goshopping-48db9`: 本番に `verifyPurchase` がデプロイ済みであることを確認したうえで、ユーザーがデプロイを実施（エージェントからの本番デプロイは権限設定でブロックされた）
- 開発 `gotoshop-572b7`: `firebase deploy --only firestore:rules --project dev` でデプロイ成功

**Status**: ✅ 完了

---

## 🐛 発見された問題

### 開発プロジェクトにverifyPurchaseが未デプロイ ⚠️

- **症状**: 開発側のFunctionsはメール送信の拡張機能のみで、`verifyPurchase` がない。Rulesだけが先行した状態
- **影響**: devフレーバーで購入や復元を試してもPremiumは有効にならない。課金パネルの表示と課金開始日の読み出しは確認できる
- **対処**: 開発側にはFunctionsを入れない方針とした。このマシンに `functions/.env` がなく、devパッケージがPlay Consoleに未登録なら検証も通らないため
- **状態**: 対応しない（課金の実動作確認は本番プロジェクトとPlayのテストトラックで行う）

### 本番Functionsにplay RTDNハンドラが見当たらない ⚠️

- **症状**: 本番のFunctions一覧に、現在のコードにある `playRtdnHandler` がない
- **影響**: 解約・返金などのGoogle Play通知による自動反映に関わる可能性がある
- **状態**: 未調査

### 上限エラー文言・ヘルプの案内がプレ公開と不整合 ⚠️

- **症状**: グループ数・メンバー数の上限エラーに「Premium にアップグレードしてください」という文言があり、ヘルプページにもPremiumプランの説明がある。プレ公開中は購入できない
- **状態**: 未対応

---

## 💡 技術的学習事項

### Google PlayのversionCodeは通番

```text
pubspec.yaml の version: x.y.z+N の N = Android versionCode
```

Google Playは過去にアップロードしたものより小さい `versionCode` を受け付けない。バージョン本体を上げてもビルド番号はリセットできない。バージョンごとにリセットできるのはApp Store側だけ。

### Playストア版とローカルビルドの署名不一致

Playストアからインストールしたアプリは、ローカルのデバッグAPKで上書きできない（`INSTALL_FAILED_UPDATE_INCOMPATIBLE`）。入れ替えるにはアンインストールが必要で、端末内のローカルデータは消える。

---

## 🗓 次回の予定

1. Firebase Consoleで本番・開発それぞれに `appConfig/subscription`（`salesStartDate`）を作成し、アプリでの読み出しを確認する
2. `1.2.0+43` のAABをPlay Consoleのクローズドテストへリリースする
3. 本番Functionsの `playRtdnHandler` の有無を確認する
4. 上限エラー文言とヘルプページのPremium案内をプレ公開に合わせるか判断する

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `AGENTS.md` | リリース目標バージョンと `sumomo-planning` プッシュ時のルールを追加、目標を `1.2.0+44` に更新 |
| `instructions/50_user_and_settings.md` | プレ公開期間の新規受付ブロックと課金開始日のFirestore管理を追記 |
| `docs/daily_reports/2026-10/daily_report_20261007.md` | 本日の作業・検証結果・未解決課題を記録 |
