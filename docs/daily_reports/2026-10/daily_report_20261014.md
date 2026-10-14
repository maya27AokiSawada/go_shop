# 開発日報 - 2026年10月14日

## 📅 本日の目標

- [x] 早期ダウンロード特典（`goshopping_onetime_1000`）用の Play ストア商品アイコンを作成する
- [x] 特典コードの引き換えを検証し、1年間の権限を付与・失効させる実装を入れる
- [x] Android のビルド時に出る KGP のメッセージを確認する
- [x] Functions を dev / prod にデプロイし、Play の RTDN（テスト通知）を prod で疎通させる
- [ ] ビルド44を Play ストアコンソールにリリースする
- [ ] Mac で iOS 版を確認し、App Store にリリースする

---

## ✅ 完了した作業

### 1. 早期ダウンロード特典の商品アイコン作成 ✅

**Purpose**: Play Console に登録した1回限りのアイテム「GoShopping2買い切り全画面広告オフ」（`goshopping_onetime_1000`）の商品アイコンを用意する。

**Solution**:

- `play_store_onetime_icon.png`（512×512 PNG）を作成した。
- フィーチャー画像と同じネイビーのグラデーション背景に、チェック入りのすももロゴを置き、右上に特典を表す金色の星バッジを付けた。
- 最初の案は「早期特典」「広告オフ 1年間」の文字を入れていたが、Play Console の「アイコンにテキストを入れない」という指定に合わせ、図形だけで作り直した。

**Status**: ✅ 完了（Play Console へのアップロードは未実施）

---

### 2. 早期ダウンロード特典の付与・失効の実装 ✅

**Purpose**: 特典はアプリ内で販売せず、プロモーションコードの引き換えで付与する。引き換えた購入をサーバーで検証し、説明文どおり「1年間、広告オフ＋グループ数・メンバー数がPremium同等」を有効にする。

**Problem / Root Cause**:

- クライアントは商品IDを受け付けていたが、`verifyPurchase` Callable はサブスクリプションの商品IDしか許可しておらず、検証もサブスクリプション用 API（`subscriptionsv2`）だけだった。
- クライアントはサーバーの応答が `purchaseType: 'subscribe'` でないと失敗扱いにしていた。
- 1回限りのアイテムはストアから失効通知が届かないため、1年の期限を反映する仕組みがなかった。

**Solution**:

- **検証**: `verifyGoogleOneTimePurchase` を追加し、`purchases.products` API で購入状態と購入日時を確認する。期限は引き換え日時の1年後とし、`purchaseVerification.expiresAt` に保存する。
- **付与**: `purchaseType: 'purchase'` として保存する。既存の `purchase` の扱いをそのまま使うため、広告は全て非表示、上限は Premium 同等になる。
- **acknowledge**: 1回限りのアイテム用の `acknowledgeGoogleProductPurchase` を追加し、検証成功後に Functions 側で行う。
- **失効**: スケジュール関数 `expireEarlyDownloadBenefits`（毎日 JST 03:00）を追加し、期限を過ぎたユーザーを `free` に戻す。期限後の復元は `verifyPurchase` が拒否する。
- **クライアント**: サーバー応答の `purchaseType` を商品IDから期待される値と照合するように変更した。反映時のメッセージは「早期ダウンロード特典が有効になりました。」とした。
- **販売なし**: 商品情報の取得対象には入れず、購入ボタンも作っていない。iOS からこの商品IDが届いた場合は拒否する。
- 既存メソッドのシグネチャは変更していない。

**Modified Files**:

- `functions/receipt_verification.js` - 1回限りのアイテムの検証・acknowledge・失効処理を追加
- `functions/index.js` - `verifyPurchase` の振り分けと、スケジュール関数 `expireEarlyDownloadBenefits` を追加
- `functions/play_rtdn.js` - one-time product 通知のコメントを現状に合わせて修正
- `functions/test/receipt_verification.test.js` - 特典の検証・保存・失効のテストを5件追加
- `lib/services/purchase_service.dart` - サーバー応答の照合と特典用メッセージ
- `lib/models/purchase_type.dart` / `lib/providers/subscription_provider.dart` - `purchase` の表示名とコメントを「早期ダウンロード特典」に更新
- `test/services/purchase_service_test.dart` - 特典の復元テストを追加
- `instructions/50_user_and_settings.md` - 早期ダウンロード特典の節を追加

**Test Results**:

- Functions: `npm test` 30件すべて成功
- Flutter: `test/services/purchase_service_test.dart` 14件すべて成功（`fvm` が Windows 機に無く、固定の 3.35.6 ではなくシステムの Flutter 3.47.5 で実行）

**Status**: ✅ 実装完了（実際の Play でのコード引き換えは未確認、Functions は未デプロイ）

---

### 3. Android ビルド時の KGP メッセージの確認 ✅

**Problem / Root Cause**:

- ビルド時に Kotlin Gradle Plugin（KGP）に関するメッセージが出ていた。
- `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` で再現したところ、ビルドは成功し、メッセージはエラーではなく警告だった。
- 警告は2種類。アプリ本体（`android/app/build.gradle.kts`）が `kotlin-android` を適用していること、および `cloud_functions` / `firebase_app_check` / `firebase_auth` / `firebase_core` / `firebase_crashlytics` / `sentry_flutter` が KGP を適用していること。

**Solution**:

- 対応は見送った。`android/gradle.properties` の `android.builtInKotlin=false` で従来方式のまま動いており、プラグイン6つが Built-in Kotlin 未対応のため。

**Status**: ✅ 確認完了（設定変更なし）

---

### 4. Functions の dev / prod デプロイと RTDN の疎通 ✅

**Purpose**: 早期ダウンロード特典の変更（`verifyPurchase`、`expireEarlyDownloadBenefits`）と、Play の RTDN 受信関数 `playRtdnHandler` を dev・prod にデプロイする。

**Problem / Root Cause**:

- `playRtdnHandler` はリトライポリシー付きの新規関数のため、`--force` なしではデプロイが止まった。ソースに無い関数の削除は発生しないことを、先に dev / prod の関数一覧とソースを突き合わせて確認した。
- dev（`gotoshop-572b7`）は Cloud Functions の初回デプロイで、Cloud Build のサービスアカウントの権限不足により7関数すべてのビルドが失敗した。権限を直したあとの再実行で、失敗時に残った `playRtdnHandler`（https 型）が「HTTPS 関数からバックグラウンド関数への変更は不可」で拒否された。
- prod（`goshopping-48db9`）は `playRtdnHandler` だけが `Unexpected error creating Pub/Sub topic` で失敗した。`--debug` で、デプロイ用アカウントに `pubsub.topics.create` の権限が無い（403）ことが原因と分かった。
- トピック `play-rtdn` に `google-play-developer-notifications@system.gserviceaccount.com` を追加しようとしたところ、組織ポリシー `constraints/iam.allowedPolicyMemberDomains`（ドメインで制限された共有）に拒否された。

**Solution**:

- dev: 作りかけの `playRtdnHandler` を削除してから再デプロイし、7関数が作成・更新された。
- prod: トピック `play-rtdn` を作成して再デプロイし、7関数がそろった。`playRtdnHandler` は Pub/Sub トリガー型で作成された。
- 組織ポリシーを、このプロジェクトだけ一時的に緩めて、Play のサービスアカウントを「Pub/Sub パブリッシャー」として追加した。
- Play Console の「収益化の設定」でトピックを `projects/goshopping-48db9/topics/play-rtdn` に設定し、テスト通知を送信した。prod の関数ログで `テスト通知を受信`、`handled: test` を確認した。
- 環境変数をプロジェクト別名ごとに分けた。`functions/.env.dev` と `functions/.env.prod` を追加し、dev の `GOOGLE_PLAY_PACKAGE_NAME` を `net.sumomo_planning.goshopping.dev`、prod を `net.sumomo_planning.goshopping` にした。dev の `ADMIN_RESTORE_SECRET` は prod と別の値にした。`.env.*` は `.gitignore` 対象でコミットしていない。
- `functions/index.js` が `dotenv` で `.env.production` を直接読んでいるため、dev の別名ファイルの値が優先される（dotenv は設定済みの値を上書きしない）。

**Status**: ✅ デプロイ完了。実際の購入・更新・解約の通知は未確認（テスト通知のみ）。dev は新しい `.env.dev` を未反映（次回の dev デプロイで反映される）。

---

## 🔄 継続・確認事項

- **Functions のデプロイ**: dev・prod ともデプロイ済み。特典コードの引き換えは、prod の Play テストトラックで確認する。
- **GCP の権限を元に戻す（要対応）**: 組織ポリシー `iam.allowedPolicyMemberDomains` を、プロジェクト `goshopping-48db9` で一時的に緩めたままになっている。「親のポリシーを継承する」に戻す。追加済みの IAM は戻しても残る。
- **dev の再デプロイ**: `.env.dev` の変更（パッケージ名・`ADMIN_RESTORE_SECRET`）を反映するには、dev を再デプロイする。
- **RTDN の本番通知**: テスト通知のみ確認済み。初回の購入・更新・解約の通知が来たら `firebase functions:log --only playRtdnHandler --project prod` で確認する。
- **実機での引き換え確認**: prod package を Play ストアのテストトラックから入れ、プロモーションコードを引き換えて反映を確認する。
- **アプリを閉じた状態で引き換えた場合**: 設定画面の「購入を復元」を押すまで反映されない。起動時の自動確認は入れていない。
- **広告の範囲**: 商品名は「全画面広告オフ」だが、実装ではバナー広告も非表示になる。全画面広告だけにする場合は変更が必要。
- **サブスクとの併用**: サブスク失効時にいったん `free` に戻り、「購入を復元」で特典が再度有効になる。
- **公開ページ**: `docs/specifications/premium_plan.md` には特典の記載を追加していない。
- **Play ストア**: ビルド44をコンソールにリリースする。商品アイコンをアップロードする。
- **iOS**: Mac で iOS 版を確認してから App Store にリリースする。特典は Android のみで、iOS 側の画面・動作の変更はメッセージ文言の分岐だけ。
- **KGP 移行**: プラグインの Built-in Kotlin 対応版が出てから、アプリ本体とあわせて移行する。

---

## 📝 メモ

- `pubspec.yaml` のバージョンは 1.2.0+44 のまま。`lib/` の変更を含むが、ビルド44としてリリースする方針のためビルド番号は上げていない。
- アイコンの生成には Python の Pillow を使った。生成スクリプトは一時フォルダに置いたままで、リポジトリには含めていない。
- `play_store_feature_graphic.png` の未コミットの変更は今回の作業ではないため、このコミットには含めていない。
