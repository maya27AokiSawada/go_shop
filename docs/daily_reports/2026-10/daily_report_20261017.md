# 開発日報 - 2026年10月17日

## 📅 本日の目標

- [x] App Store 審査の「アプリ内課金がバイナリに存在しない」指摘の原因を調べ、iOS 版の方針を決める
- [x] iOS の課金を Sandbox で試せるようにし、iOS の解約・失効を反映する仕組みを入れる
- [x] グループ画面で暗号文が表示される問題を直す
- [x] 暗号化・復号をリポジトリ層に集約し、Hive を平文にする
- [x] 鍵ローテーションの条件を見直し、メンバーが抜けたら自動でローテーションする
- [x] シングルモードのユーザーにマルチモードを案内する
- [x] ビルド45の AAB を作成する
- [x] AdMob の app-ads.txt を公開サイトに置く
- [ ] ビルド45を Play ストアにリリースする

---

## ✅ 完了した作業

### 1. App Store 審査の指摘への対応方針 ✅

**Purpose**: App Store Connect の審査で、Premium の月額・年額が「バイナリに存在しない」と指摘された原因を調べる。

**Problem / Root Cause**:

- 課金処理（StoreKit・`verifyPurchase`・復元）は実装済みだった。
- 課金開始日（Firestore `appConfig/subscription.salesStartDate`、未設定時は 2027-01-01）より前は、購入ボタンを表示せずプレ公開の案内だけを出していたため、審査担当者から課金の入口が見えなかった。

**Solution**:

- 課金開始（2027年1月）を維持し、年内は Android のみで公開する方針にした。iOS はサブスクと購入ボタンを含むビルドを2027年1月に提出する。
- App Store の審査への返信文（英文）を作成した。
- ニュース（`firestoreNews/current_news` / `current_news_eng`）に「iOS版は2027年1月公開予定」を掲載した（Firebase コンソールで更新済み）。

**Status**: ✅ 完了

---

### 2. iOS 課金の Sandbox テスト用フラグ ✅

**Purpose**: iOS は flavor に関係なく本番 Firebase を参照するため、本番の課金開始日を変えずに Sandbox で購入を試せるようにする。

**Solution**:

- `--dart-define=IAP_SALES_OPEN=true` を付けたビルドだけ、課金開始日前でも購入を受け付けるようにした。リリースビルドには付けない。

**Modified Files**:

- `lib/services/purchase_service.dart`

**Status**: ✅ 完了（Sandbox での購入テストは未実施）

---

### 3. iOS の解約・失効・返金の反映（App Store Server Notifications V2） ✅

**Problem / Root Cause**:

- Android は RTDN で解約・失効を反映しているが、iOS には受け口がなく、一度 `subscribe` になると解約しても Premium のまま残っていた。

**Solution**:

- `appStoreNotifications`（onRequest）を追加した。`signedPayload` を Apple のルート証明書で署名検証し、`purchaseReceipts/{sha256(app_store:originalTransactionId)}` から本人を特定する。
- 期限内は延長、期限切れは `free`、`REFUND` / `REVOKE` は即時 `free`、猶予期間中は `gracePeriodExpiresDate` まで有効とした。別のレシートが権限源のユーザーは `free` にしない。
- 署名不正は 400、一時障害は 500（Apple の再送に委ねる）。

**Modified Files**:

- `functions/apple_notifications.js`（新規）
- `functions/index.js`
- `functions/receipt_verification.js`（`loadAppleRootCertificates` を export）
- `functions/test/apple_notifications.test.js`（新規、14件）

**Test Results**: Functions `npm test` 44件すべて成功

**Status**: ✅ 実装完了（未デプロイ。App Store Connect への URL 登録も未実施）

---

### 4. 暗号化・復号をリポジトリ層に集約し、Hive を平文化 ✅

**Purpose**: グループ画面でアクティブグループを切り替えると、リスト画面を開くまで暗号文が表示されることがあった。画面ごとの鍵解決に頼らない構造にする。

**Problem / Root Cause**:

- Firestore から読むときの鍵の準備は端末の保存済み鍵を読むだけで、鍵が最新か・端末にあるかを確認していなかった。サーバーから鍵を取得する処理は一部の画面からしか呼ばれていなかった。
- Hive の中身は、グループは復号できた分だけ平文、リストのアイテム名は暗号文と平文が混在していた。

**Solution**:

- `GroupKeyExchangeService.ensureFreshGroupKey` を追加し、Firestore から読む直後・書く直前に、ローカル鍵が `activeKeyVersion` と一致するかを確認して、未取得・旧世代なら `keyExchangeEvents` から解決する。グループ共有フィールドは `GroupKeyServiceFieldCipher.primeKey` で行う。
- アイテム名の暗号化・復号を `FirestoreSharedListRepository` の読み書きの境界だけで行い、Hybrid・Hive・UI は平文で扱うようにした。
- 平文・旧鍵のアイテム名は、読み込み時に現行鍵で `items.{itemId}.name` だけを書き戻す（リスト全体は上書きしない）。
- 既存端末の Hive に残った暗号文は `HivePlaintextMigrationService` が起動時に1回だけ平文化する。
- 途中で見つけた不具合も直した。
  - `reencryptSharedItemsForGroup` がアイテム名ではなくグループ鍵そのものを暗号化して書き込み、平文のアイテム名を SharedPreferences に保存していた。
  - 購入状態だけの変更かの判定で暗号文同士を比べており、オーナー以外が他人のアイテムにチェックを付けると権限エラーになっていた。
  - アイテム削除の通知に暗号文が載っていた。
- グループ画面個別の鍵確認（午前に一度入れた修正）は不要になったため外した。

**Modified Files**:

- `lib/services/group_key_exchange_service.dart`
- `lib/datastore/firestore_shared_list_repository.dart`
- `lib/datastore/hybrid_shared_list_repository.dart`
- `lib/datastore/group_field_cipher.dart`
- `lib/datastore/firestore_shared_group_repository.dart`
- `lib/services/firestore_group_sync_service.dart`
- `lib/services/hive_plaintext_migration_service.dart`（新規）
- `lib/widgets/app_initialize_widget.dart`
- `instructions/20_groups_lists_items.md`（暗号化ルールを新設計に更新）

**Status**: ✅ 完了（実機2台で表示を確認）

---

### 5. 鍵ローテーションの条件の見直しと自動ローテーション ✅

**Purpose**: 鍵の再ローテーションに間隔の制限がなかった。メンバーが抜けたときに鍵を変えられるようにする。

**Solution**:

- 時間間隔ではなく「平文・旧鍵のデータを現行鍵へ揃え終えたこと」を条件にした（端末は1世代前の鍵までしか持たないため）。揃えられなければ `GroupKeyRotationBlockedException` で見送る。
- `GroupKeyRotationService` を追加した。ローテーション後はデータを新しい鍵へ揃え、抜けたメンバーの `keyExchangeEvents` を削除する。
- 抜けたメンバー（`keyExchangeEvents` はあるが `allowedUid` にいない）をオーナー端末で検出して自動でローテーションする。オーナーによる削除・退出リクエスト処理ではその場で、自主退出・アカウント削除はオーナーが次にグループへアクセスした時点（5分に1回まで）で行う。
- 削除したメンバーが `allowedUid` に残っている間は回復エンベロープを読めてしまうため、反映を待ってからローテーションする。
- メンバー管理画面の「鍵の再作成」も同じ処理を使う。

**Modified Files**:

- `lib/services/group_key_rotation_service.dart`（新規）
- `lib/services/group_key_access_coordinator.dart`
- `lib/providers/shared_group_provider.dart`
- `lib/services/notification_service.dart`
- `lib/pages/group_member_management_page.dart`

**Status**: ✅ 完了

---

### 6. ローテーション直後に画面遷移なしで復号されない問題 ✅

**Problem / Root Cause**:

- 鍵の確認結果を60秒使い回している間にローテーション後のデータを受け取ると、新しい鍵を取りに行かず暗号文のまま表示されていた。画面遷移で読み直すと直っていた。

**Solution**:

- 復号に失敗したら確認結果を無効化（`markGroupKeyStale`）し、鍵を取り直して同じ読み込みの中で復号し直す。リストは `FirestoreSharedListRepository`、グループは `retryDecryptWithFreshKey`（リアルタイム監視・一覧取得・1件取得・`decryptGroupPrimed`）で行う。

**Status**: ✅ 完了（実機で確認）

---

### 7. シングルモードでマルチモードを案内 ✅

**Solution**:

- シングルモードでグループ画面を開いた最初の3回、「グループとリストを複数使いたい場合は、設定から『マルチ』モードに切り替えてください」を5秒間スナックバーで表示し、「設定を開く」で設定タブへ移動する。
- タブを移った後にボタンを押すと、破棄済みの画面の `ref` を使ってエラーになっていたため、表示時に notifier を取得しておくようにした。
- 文言は日・英・葡・中の4言語。

**Modified Files**:

- `lib/pages/shared_group_page.dart`
- `lib/l10n/app_texts*.dart`

**Status**: ✅ 完了（Aiwa で3回表示・設定への移動を確認）

---

### 8. テスト環境の修正 ✅

**Problem / Root Cause**:

- Firebase Auth 更新後のモック不一致と、`firebase_auth_mocks` のコメントアウトで、鍵交換サービスのテストが一切実行されていなかった。

**Solution**:

- dev 依存の `firebase_auth_mocks` を有効化し、`test/services/invitation_key_exchange_test.mocks.dart` を再生成した。
- 修正前の誤った動作（平文を SharedPreferences に保存）を期待していたテストを1件書き換えた。
- 鍵の最新化・旧鍵での復号・Firestore 境界の暗号化・Hive 移行・ローテーション・再復号のテストを追加した。

**Test Results**: Flutter 415件成功・3件失敗（`test/auth/` の3ファイル。以前から古いモックのまま）

**Status**: ✅ 完了（`test/auth/` のモック再生成は未対応）

---

### 9. 実機確認とビルド45の AAB 作成 ✅

**Solution**:

- SH 54D（上書き）と Aiwa TAB1011（署名が異なるためアンインストールしてから新規インストール）に prod の確認用ビルドを入れた。
- adb で直接入れたリリースビルドは Play Integrity を通らず App Check に拒否されたため、`--dart-define=APP_CHECK_DEBUG=true` で作り直し、両端末のデバッグトークンを Firebase コンソールに登録した。
- ストア用の AAB を `flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod` で作成した（`app-prod-release.aab` 77.4MB、`1.2.0+45`）。確認用フラグは付けていない。

**Status**: ✅ 完了（Play Console へのアップロードは未実施）

---

### 10. AdMob の app-ads.txt ✅

**Purpose**: AdMob と Play ストアのリンク後、app-ads.txt の設定を求められた。

**Solution**:

- Play ストアのデベロッパー ウェブサイトが `sumomo-planning.net` のため、Django アプリのリポジトリ（`sumomo-planning.net`）に `/app-ads.txt` を追加し、`main` にプッシュした（`faa1e53`）。内容は `google.com, pub-7163325066755382, DIRECT, f08c47fec0942fa0`。

**Status**: ✅ プッシュ済み（さくら VPS への手動デプロイと AdMob での確認は未実施）

---

## 🔄 継続・確認事項

- **Play ストア**: ビルド45の AAB をアップロードしてリリースする。
- **確認用ビルド**: 2台に入っている `APP_CHECK_DEBUG` 付きのビルドは、ストア版で上書きできない場合がある。その場合はアンインストールしてから入れ直す。
- **app-ads.txt**: さくら VPS で `sudo sh deploy/update-vps.sh` を実行し、`https://sumomo-planning.net/app-ads.txt` を確認してから、AdMob で確認を実行する。
- **Functions**: `appStoreNotifications` を prod にデプロイし、App Store Connect の「App Store Server Notifications」（本番・Sandbox とも Version 2）に URL を登録する。本番通知の検証には `.env.production` に `APPLE_APP_ID` が必要。
- **iOS（2027年1月提出）**: Sandbox で購入・復元・解約→失効を確認し、サブスク2つとビルドを一緒に提出する。審査メモに購入画面への手順を書く。
- **鍵ローテーション**: オーナーによるメンバー削除後、削除されたメンバーが読めなくなること、残ったメンバーの表示が崩れないことを実機で確認する。
- **テスト**: `test/auth/` の3ファイルのモック（`*.mocks.dart`）を再生成する。

---

## 📝 メモ

- `pubspec.yaml` のバージョンは 1.2.0+45。ビルド45は未リリースのため、午後のマルチモード案内もビルド番号を上げずに45に含めた。
- `build_runner` の `--build-filter` 指定でも、他の自動生成ファイル（`lib/models/*.freezed.dart` など）が削除・変更された。直後に `git checkout` で戻した。モック再生成時は差分を必ず確認する。
- Flutter のテストはシステムの Flutter で実行した（`fvm` が Windows 機に無いため）。
