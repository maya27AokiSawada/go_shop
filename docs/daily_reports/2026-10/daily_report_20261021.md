# 開発日報 - 2026年10月21日

## 📅 本日の目標

- [x] dev で家族特典クーポンの発行・入力を2台（SH 54D / AIWA タブレット）で確認する
- [x] 発行者が設定画面から家族を解除できることを確認する
- [x] 発行者の Premium のオン・オフに家族の特典が連動することを確認する

---

## ✅ 完了した作業

### 1. dev 用の課金状態の切替（10/20 実装） ✅

**Purpose**: ストアで購入せずに、dev で Premium 前提の機能（家族特典クーポン）を確認する。

**Solution**:

- dev 専用の Callable `setDevPurchaseType`（`functions/dev_tools.js`）を追加した。自分の `purchaseType` を `subscribe` / `free` に切り替える。dev プロジェクト（`gotoshop-572b7`）以外では常に拒否する。App Check 必須。
- dev ビルドの設定画面に「課金状態の切替（開発用）」（`DevPurchaseTypeSwitcher`）を追加した。
- 本番と同じ `purchaseType` を書き換えるため、発行・入力・解除や、Premium が切れたときに家族を `free` に戻すトリガーまで本番と同じ流れで確認できる。
- `setDevPurchaseType` のみ dev にデプロイ済み（家族特典クーポンの関数は 10/19 にデプロイ済み）。

**Modified Files**:

- `functions/dev_tools.js`（新規）、`functions/index.js`、`functions/test/dev_tools.test.js`（新規）
- `lib/widgets/settings/dev_purchase_type_switcher.dart`（新規）、`lib/pages/settings_page.dart`
- `instructions/50_user_and_settings.md`

**Status**: ✅ 完了（Functions のテスト 67 件成功）

---

### 2. dev プロジェクトの Functions が Firestore にアクセスできない問題 ✅

**Problem / Root Cause**:

- `setDevPurchaseType` が Admin SDK の Firestore 読み取りで `PERMISSION_DENIED` になった。
- 2nd gen の Functions の実行サービスアカウント（`895658199748-compute@developer.gserviceaccount.com`）に Firestore のロールが付いていなかった。`scheduledFirestoreBackup` と `expireEarlyDownloadBenefits` も 10/18 から毎日同じエラーで失敗していた。

**Solution**: 同サービスアカウントに「Cloud Datastore ユーザー」と「Cloud Datastore インポート / エクスポート管理者」を付与した（ユーザー対応）。

**Status**: ✅ 完了（`scheduledFirestoreBackup` は Storage バケットへの書き込み権限も必要な可能性あり。次回実行のログで確認）

---

### 3. App Check のデバッグトークン登録 ✅

- SH 54D（`4ce424a0-…`）と AIWA タブレット（`486ef1f7-…`）のトークンを dev の Android アプリに登録した。
- AIWA はトークンがログに出なかったため、`run-as` で `shared_prefs/com.google.firebase.appcheck.debug.store.*.xml` から取得した。

---

### 4. 家族特典クーポンの実機確認 ✅

- SH 54D（まや・Premium）でクーポンの発行、AIWA タブレット（すも）で入力を確認した。
- 発行者のグループに参加していない状態では特典が有効にならないことも確認した。
- 発行者が設定画面から家族を解除できることを確認した。
- 発行者の Premium をオン・オフすると、トリガー（`syncFamilyBenefits`）で家族の特典も連動して有効・無効になることを確認した。

**Status**: ✅ 完了

---

### 5. 広告同意を取り直したあとの `ref` エラー（10/20） ✅

- 同意が取れると注意表示が破棄され、`finally` の `ref.invalidate` で `Cannot use "ref" after the widget was disposed` が発生していた。`await` 前に `ProviderScope` のコンテナを取得して使うように修正（`da05443e`）。

---

### 6. `SubscriptionNotifier` のリスナー例外 ✅

**Problem / Root Cause**:

- 課金状態が変わるたびに Crashlytics へ `Providers are not allowed to modify other providers during their initialization.`（`_debugCurrentlyBuildingElement` の assertion）と `At least listener of the StateNotifier Instance of 'SubscriptionNotifier' threw an exception` が送られていた。
- `purchaseSyncProvider` が `ref.watch(purchaseTypeProvider)` で再ビルドし、その build の中で `SubscriptionNotifier` の状態を書き換えていた。

**Solution**:

- `ref.listen`（`fireImmediately: true`）で変化を受け取り、`Future.microtask` で build の外で反映するようにした。同期の内容は変更なし。
- `test/providers/purchase_sync_provider_test.dart` を追加（修正前は2件とも同じ assertion で失敗することを確認）。

**Modified Files**:

- `lib/providers/purchase_sync_provider.dart`
- `test/providers/purchase_sync_provider_test.dart`（新規）

**Status**: ✅ 完了（SH 54D・AIWA タブレットの新ビルドで Premium のオン・オフを繰り返し、例外が出ないことを確認）

---

### 7. Firestore の監視がエラーで止まったら再接続する ✅

- Firestore の `snapshots()` はエラーが1回起きると終わり、再接続しない。本番も App Check を強制しているため、Play Integrity の判定が一時的に失敗すると課金状態の変化が反映されなくなる。
- エラー時に間隔を空けて購読し直す `retryingSnapshots`（`lib/utils/retrying_snapshots.dart`）を追加し、課金状態（`watchPurchaseType`）と家族特典（`FamilyCouponService.watchStatus`）に適用した。ほかの監視箇所への適用は ToDo に残した。

**Status**: ✅ 完了（ユニットテストのみ。実機での再現方法は未確立）

---

### 8. GCP の組織ポリシーを元に戻す ✅

- `goshopping-48db9` に 10/14 に設定したプロジェクト個別のポリシー（`iam.allowedPolicyMemberDomains` を `allValues: ALLOW`）を `gcloud resource-manager org-policies delete` で削除し、親のポリシーの継承に戻した（ユーザー実行）。
- 実効ポリシーは自組織（`C03gq7hp3`）のみ許可。Pub/Sub トピック `play-rtdn` の Play サービスアカウント（Pub/Sub パブリッシャー）は残っている。
- 新しい `gcloud org-policies` は Organization Policy API が無効のため使えず、旧来の `gcloud resource-manager org-policies` を使った。

**Status**: ✅ 完了

---

## 🔄 継続・確認事項

> 全体の未完了項目は [`docs/todo.md`](../../todo.md) にまとめた。

- **Firestore の監視の再接続**: 実機でエラーからの復帰を確かめる方法が未確立。AIWA で招待の通知を受け取れなかった件は原因未特定。

---

## 🕐 午前のまとめ

- 家族特典クーポンの実機確認（発行・入力・グループ未参加時の拒否・解除・Premium との連動）をすべて完了。
- `SubscriptionNotifier` の例外を修正し、2台の実機で確認。
- Firestore の監視の再接続を課金状態と家族特典に適用。
- GCP の組織ポリシーを元に戻した。
- ToDo を `docs/todo.md` に独立させた。

---

## 🕐 午後の作業

### 9. Firestore の監視の再接続をほかの箇所にも適用 ✅

- `retryingSnapshots` をグループ一覧、招待受諾、通知履歴の画面、ホワイトボード（ストローク・メタデータ・グループ共通・個人用）に適用した。共有リスト（Hive へのフォールバックあり）、ニュース、同期確認の待機、未使用の `watchUserName` は対象外。
- `instructions/00_project_common.md` に Anti-12 を追加し、`instructions/30_whiteboard.md` の 3-1・3-2 を直した（`cancelOnError: false` だけでは Firestore の監視は続かない）。
- 2台でグループ退出の即時反映、ホワイトボードの保存での反映（従来どおり）を確認した。

### 10. dev の Firestore バックアップを止める ✅

- dev ではバックアップは不要と判断。`scheduledFirestoreBackup` を、dev プロジェクトでは何もせず終わるようにした（Cloud Scheduler の一時停止ではなく、デプロイし直しても戻らないようコードで判定）。
- dev にデプロイし、ジョブを手動実行して「dev プロジェクトのため Firestore バックアップをスキップします」のログを確認した。

### 11. `test/auth/` のモックの再生成 ✅

- firebase_auth の更新で `FirebaseAuth.setSettings` に `migrateCurrentUser` などの引数が増え、古いモックがコンパイルエラーになっていた。
- `--build-filter="test/auth/*.mocks.dart"` で再生成した。全テスト 472 件成功。

**注意（build_runner）**:

- `--delete-conflicting-outputs` は `--build-filter` を付けても、対象外の生成済みファイル（`lib/models/*.freezed.dart` / `*.g.dart` など）まで削除する。実行後は `git ls-files --deleted` で消えたファイルを確認し、`git checkout` で戻す。
- Claude Code のサンドボックス内では Dart VM がスタック領域の取得に失敗してクラッシュした。サンドボックス外で実行すると成功した。

---

## 📝 メモ

- App Check のデバッグトークンはアプリのデータごとに作られる。データ消去・再インストールで変わるので、登録し直しが必要。登録前に起動していた場合は、登録後にアプリを再起動する。
- UMP のデバッグ地域が効かなかったのは `.env` のキー名の誤り（`ADMOB_UMP_DEBUG_GEOGRAPHfY`）。正しくは `ADMOB_UMP_DEBUG_GEOGRAPHY`。
- 同意フォームですべて拒否しても `canRequestAds()` は `true` になり、制限付き広告が配信される。マルチモードの利用条件は「何らかの広告を表示できること」で、今の判定のままとした。
