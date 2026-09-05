# 開発日報 - 2026年09月05日

## 📅 本日の目標

- [x] Play Console の Integrity API 利用状況を確認する
- [x] Play Console のユーザー・権限設定を確認する
- [x] 管理画面の保存資料を機密情報ポリシーに沿って整理する
- [x] Pixel 9（Wi-Fi 経由 ADB）実機で課金処理をテストし、ログを監視する
- [x] 課金検証エラー（`unauthenticated` / `unavailable`）の根本原因を特定し修正する
- [x] Premium 年払いプラン（`goshopping-premium-annual`）を追加する
- [x] Free プラン限定でのバナー広告表示ルールを是正する
- [x] release build 32（AAB）をビルドする
- [x] 本日の作業を日報にまとめて `sumomo-planning` へ反映する

---

## ✅ 完了した作業

### 1. Integrity API 利用状況の確認 ✅

**Purpose**: Play Console 上で GoShopping の Integrity API 利用状況を確認する。

**Result**:

- 過去30日間のクラシック API リクエスト数が 0 件であることを確認
- 1日の割り当て使用量が 0.0% であることを確認
- 確認時点では Integrity API リクエストの発生実績なし

**Status**: ✅ 確認完了

---

### 2. Play Console ユーザー・権限設定の確認 ✅

**Purpose**: Play Console に登録されているユーザーとサービスアカウントのアクセス設定を確認する。

**Result**:

- Play Console のユーザー一覧が 2 件であることを確認
- サービスアカウントの詳細画面を開き、アカウント権限とアプリ権限の設定項目を確認
- メールアドレス、サービスアカウント名、developer ID などの実値は日報へ記載しない

**Status**: ✅ 画面確認完了

---

### 3. Play Console 保存資料の機密情報対策 ✅

**Purpose**: `docs/troubleshooting/` に保存された管理画面 PDF を、公開リポジトリの機密情報ポリシーに沿って整理する。

**Problem / Root Cause**:

PDF には Play Console の developer ID、app ID、個人メールアドレス、サービスアカウント識別子が含まれていた。未追跡のまま一括追加すると、公開リポジトリへアカウント情報が公開される状態だった。

```gitignore
# ❌ Before: Play Console の PDF が未追跡ファイルとして表示される
```

**Solution**:

管理画面 PDF はローカル調査資料として残し、`docs/troubleshooting/` 配下の PDF を Git 管理対象外にした。

```gitignore
# ✅ After: アカウント情報を含む管理画面 PDF を追跡しない
docs/troubleshooting/*.pdf
```

**Modified Files**:

- `.gitignore`（Play Console 由来のローカル PDF を追跡対象外に追加）
- `docs/daily_reports/2026-09/daily_report_20260905.md`（本日の日報を新規作成）

**Status**: ✅ 整理完了

---

### 4. 実機課金テストと `verifyPurchase` 検証エラーの根本原因特定・修正 ✅

**Purpose**: Wi-Fi 接続した Pixel 9（Play ストア配信版）で Premium 月額の購入・復元をテストし、ログをリアルタイム監視しながら `[firebase_functions/unauthenticated] UNAUTHENTICATED` エラーの原因を切り分ける。

**調査の流れ**:

1. `adb logcat` をフィルタ監視し、購入直後に `verifyPurchaseWithServer` が `unauthenticated` で失敗することを確認
2. Firebase App Check / Play Integrity 側を疑い、証明書 SHA-256・Cloud プロジェクトのリンク状況を確認 → いずれも問題なし（診断用に一時的にローカル署名でサイドロードした際の副作用と判明、コードは元に戻して調査続行）
3. Cloud Logging で該当リクエストを追跡し、**Cloud Run（`verifypurchase`）自体の認証設定が「認証が必要（IAM）」になっており、Firebase の callable 関数が前提とする公開呼び出しがブロックされていた**ことが判明
4. IAM を「パブリック アクセスを許可」に変更後、エラーが `unauthenticated` → `unavailable`（アプリ内メッセージ）に変化し、関数本体まで到達するように改善
5. Cloud Functions の実行ログから実エラーを特定し、以下を順に解消
   - Google Play Android Developer API が GCP プロジェクトで未有効化 → 有効化
   - Cloud Functions 実行用サービスアカウントに Play Console 側のアプリ権限（注文と定期購入の管理・売上データの表示）が未付与 → 付与
   - Firestore 書き込みに必要な IAM ロールが不足 → 付与
6. 上記すべての修正後、実機での購入・復元テストで `サーバー購入検証完了` を確認し、Firestore の課金タイプが `subscribe` に反映されることを確認

**Root Cause**: Cloud Run の認証設定・Google Cloud API 有効化・Play Console 権限・Firestore 用 IAM ロールの4点が、いずれも `verifyPurchase` の初回デプロイ時に正しく構成されていなかった。App Check / Play Integrity 自体には問題がなかった。

**Modified Files**:

- Cloud Run（`verifypurchase`）の認証設定（コンソール操作、コード変更なし）
- Google Cloud API 有効化・Play Console 権限・IAM ロール付与（コンソール操作）

**Status**: ✅ 実機で購入・復元とも成功を確認

---

### 5. Premium 年払いプラン（`goshopping-premium-annual`）の追加 ✅

**Purpose**: Play Console に新規登録した年払いサブスクリプション商品をアプリ・サーバー双方で利用可能にする。

**Result**:

- `PurchaseService` の年額 SKU を実際に登録された商品IDへ更新し、商品取得対象に追加
- `isPremiumYearlyAvailable` / `premiumYearlyPrice` を新設、`buyPremiumYearly()` を月額版と同等のエラーハンドリング・状態通知に統一
- 設定画面（`PurchasePlanPanel`）に「年払いでPremiumを有効化」ボタンを追加（商品取得成功時のみ表示）
- Cloud Functions（`verifyPurchase`）側が月額IDのみを許可していたため、年払いIDも受理するよう修正（未修正のままだと年払い購入がサーバー検証で `invalid-argument` になっていた）

**Modified Files**:

- `lib/services/purchase_service.dart`
- `lib/widgets/settings/purchase_plan_panel.dart`
- `functions/receipt_verification.js`
- `functions/index.js`

**Status**: ✅ 実装完了（実機での年払い購入テストは未実施、翌日以降に確認予定）

---

### 6. Free プラン限定バナー広告ルールの是正・未使用コード整理 ✅

**Purpose**: 「Free プランのみ、ホーム画面とグループ画面にバナー広告を表示する」という仕様に合わせて広告表示ロジックを是正する。

**発見したバグ**:

- ホーム画面のバナー広告ウィジェット（`HomeBannerAdWidget`）が課金ステータスを一切確認せずに広告を読み込んでいたため、**有料ユーザーにもホーム画面で広告が表示される状態**だった
- `PurchaseType.hidesBannerAds` が月額サブスクのみを対象にしており、買い切り旧プランのユーザーはバナー広告が消えない状態だった

**Solution**:

- `hidesBannerAds` を「Free 以外すべて」を対象にするよう修正
- `HomeBannerAdWidget` の読み込み処理に課金ステータスチェックを追加
- 到達不能だった未使用ページ `lib/pages/news_page.dart` と、専用だった `LocalNewsAdWidget`、どこからも参照されていなかったモック広告一式 `lib/widgets/ad_banner_widget.dart` を削除（ユーザー確認のうえ実施）

**Modified Files**:

- `lib/models/purchase_type.dart`
- `lib/services/ad_service.dart`
- 削除: `lib/pages/news_page.dart`, `lib/widgets/ad_banner_widget.dart`

**Status**: ✅ 修正完了

---

### 7. release build 32（AAB）のビルド ✅

**Purpose**: `pubspec.yaml` のビルド番号を 32 に手動更新後、Play Console 提出用の release AAB を生成する。

**Result**:

- `flutter build appbundle --release --flavor prod` を実行し、`build/app/outputs/bundle/prodRelease/app-prod-release.aab`（約77.2MB）を生成
- Gradle / AGP のバージョン更新を促す警告が出力されたが、ビルドへの影響なし（対応は別途検討）

**Status**: ✅ ビルド成功（Play Console へのアップロードは未実施）

---

## 🐛 発見された問題

### 管理画面 PDF に公開不可の識別情報が含まれていた ✅

- **症状**: Play Console の保存 PDF 3件が未追跡ファイルとして表示された
- **原因**: 管理画面の URL、ユーザー一覧、権限詳細にアカウント・プロジェクト識別情報が含まれていた
- **対処**: PDF をコミット対象から除外し、識別子を伏せた確認結果のみ日報へ記録した
- **状態**: 修正完了

### `verifyPurchase` が実機で常に `unauthenticated`/`unavailable` になっていた ✅

- **症状**: Pixel 9（Play ストア配信版）で購入・復元を行うと、必ず課金検証に失敗する
- **原因**: ①Cloud Run の認証設定が「認証が必要」になっており callable 関数への公開呼び出しがブロック、②Google Play Android Developer API が未有効化、③Cloud Functions 実行用サービスアカウントに Play Console 側の権限が未付与、④Firestore 書き込みに必要な IAM ロールが不足、の4点が重なっていた
- **対処**: 4点をすべて是正し、実機で購入・復元の成功を確認
- **状態**: 修正完了

### ホーム画面のバナー広告が課金ステータスを確認していなかった ✅

- **症状**: `HomeBannerAdWidget` が課金状態を見ずに広告を読み込んでおり、有料ユーザーにもホーム画面で広告が表示され得る状態だった。買い切り旧プランではバナー広告が非表示にならない状態でもあった
- **原因**: 広告ウィジェット側にステータスチェックが実装されていなかった／`hidesBannerAds` が月額サブスクのみを対象にしていた
- **対処**: 広告ウィジェットに課金ステータスチェックを追加し、`hidesBannerAds` を Free 以外すべてに拡張
- **状態**: 修正完了

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Play Store 署名エラーの原因特定と build 31 生成（完了日: 2026-09-03）
2. ✅ Play Console 管理画面 PDF の機密情報対策（完了日: 2026-09-05）
3. ✅ Play Store テストトラック配布版での Premium 月額 購入・復元 E2E（完了日: 2026-09-05）
4. ✅ `verifyPurchase` の `unauthenticated`/`unavailable` エラーの根本原因特定・修正（完了日: 2026-09-05）
5. ✅ Free プラン限定バナー広告ルールの是正（完了日: 2026-09-05）
6. ✅ release build 32（AAB）生成（完了日: 2026-09-05）

### 対応中 🔄

1. 🔄 `firebase_auth_mocks` 非互換によるユニットテスト Auth モックの再整備（Priority: Medium）

### 未着手 ⏳

1. ⏳ Google Play RTDN / App Store Server Notifications による失効同期（Priority: High）
2. ⏳ Premium 年払いプランの実機購入 E2E（Priority: High）

### 翌日継続 ⏳

- ⏳ release build 32 の Play Console アップロード・テストトラック配布状況確認
- ⏳ Premium 年払いプランの実機購入・復元テスト
- ⏳ Auth モックの代替手段を決定してユニットテストを復旧

---

## 💡 技術的学習事項

### 管理コンソールの画面保存は、そのまま技術資料としてコミットしない

**問題パターン**:

```text
# ❌ 管理画面を PDF 保存し、そのまま公開リポジトリへ追加する
管理画面 URL + developer ID + app ID + メールアドレス
```

**正しいパターン**:

```text
# ✅ 原本はローカル管理し、確認結果だけを識別子なしで文書化する
確認項目 + 結果 + 確認日時
```

**教訓**: 管理コンソールの PDF やスクリーンショットには、画面本文だけでなく URL にも識別子が含まれる。公開ドキュメントには必要な確認結果だけを転記する。

---

### `enforceAppCheck: true` の callable Function でも Cloud Run 側の認証設定は別途確認が必要

**問題パターン**:

```text
# ❌ App Check / Firebase Auth 側だけを疑い続ける
コードは正しい enforceAppCheck 設定なのに unauthenticated が直る気配がない
```

**正しいパターン**:

```text
# ✅ レイテンシと resource.type を手がかりにレイヤーを切り分ける
latency: 0s + resource.type: cloud_run_revision → まだ関数コードに到達していない
              → Cloud Run 自体の「認証が必要 / パブリックアクセス」設定を確認する
```

**教訓**: Firebase Functions（第2世代）は内部的に Cloud Run 上で動作するため、コード側の App Check / Auth 設定が正しくても、Cloud Run 自身の IAM 認証設定・API 有効化・実行サービスアカウントの外部API権限が別レイヤーとして存在する。エラーが一瞬で返る（レイテンシがほぼ0）場合は、まだ関数コードに到達していない可能性を疑う。

---

## 🗓 翌日（2026-09-06）の予定

1. release build 32 を Play Console テストトラックへアップロードし、配布状況を確認する
2. Premium 年払いプラン（`goshopping-premium-annual`）の購入・復元フローを実機で E2E 確認する
3. Free プランでのバナー広告表示（ホーム画面・グループ画面）を実機で目視確認する
4. Auth モックの代替手段を決定してユニットテストを復旧する

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `.gitignore` | アカウント・プロジェクト識別情報を含む `docs/troubleshooting/*.pdf` を追跡対象外に追加 |
| `docs/daily_reports/2026-09/daily_report_20260905.md` | 本日の日報を新規作成・実機課金テスト以降の作業を追記 |
| `lib/models/purchase_type.dart` | `hidesBannerAds` を Free 以外すべてに拡張 |
| `lib/services/ad_service.dart` | `HomeBannerAdWidget` に課金ステータスチェックを追加、未使用の `LocalNewsAdWidget` を削除 |
| `lib/services/purchase_service.dart` | 年払いSKU・価格取得・購入フローを追加 |
| `lib/widgets/settings/purchase_plan_panel.dart` | 年払い購入ボタンを追加 |
| `functions/index.js` / `functions/receipt_verification.js` | 年払い商品IDをサーバー検証で許可 |
| （削除）`lib/pages/news_page.dart` / `lib/widgets/ad_banner_widget.dart` | 到達不能・未参照の未使用コードを整理 |
| 指示書・README | 更新なし（理由: 機能仕様・アーキテクチャ変更を伴う恒久ルールの追加はないため） |
