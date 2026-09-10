# 開発日報 - 2026年09月10日

## 📅 本日の目標

- [x] ビルド番号を上げて署名済みリリース AAB をビルドし、クローズドテストへ回す（build 35 → 修正込みの build 36）
- [x] 実機 2 台（SH-54D / Pixel 9）に build 35 を導入してテストを実施する
- [~] グループメンバー暗号化の実機復号バグ（9/9 中断分）を特定し修正する（原因特定・A+B 実装・build 36 ビルド完了。実機での修正版 E2E 確認は次回）
- [ ] `play-rtdn` トピック作成 + `playRtdnHandler` デプロイ（未着手）

---

## ✅ 完了した作業

### 1. ビルド番号アップ + リリース AAB ビルド ✅

**内容**:

- `pubspec.yaml` の `version` を `1.1.0+34` → `1.1.0+35`（versionCode = 35）
- `flutter build appbundle --release --flavor prod` で署名済み AAB を生成
  - `build/app/outputs/bundle/prodRelease/app-prod-release.aab`（77.8MB）
- 最初 `--flavor prod` を付けずに実行して `dev` フレーバーの `processDevReleaseGoogleServices` が
  `No matching client found for package name 'net.sumomo_planning.goshopping.dev'` で失敗 →
  `--flavor prod` を付けて成功（本アプリは `prod` / `dev` の 2 フレーバー構成）

**Status**: ✅ AAB 生成完了。Play Console へのアップロードはユーザー作業

---

### 2. 実機 2 台への build 35 導入 ✅（App Check の制約を確認）

**環境**:

| 端末 | 接続 | OS |
|---|---|---|
| SH-54D | USB | Android 16 (API 36) |
| Pixel 9 | Wi-Fi (adb-tls) | Android 17 (API 37) |

**経緯**:

1. AAB は直接インストールできないため、同じ upload キーストア署名の
   `flutter build apk --release --flavor prod` を両端末へ導入しようとしたが、
   既存インストールが別署名（従来の debug ビルド）で `INSTALL_FAILED_UPDATE_INCOMPATIBLE`
2. 両端末をアンインストール → リリース APK をクリーンインストール（versionCode=35 確認）
3. **サインイン失敗**。logcat に
   `[firebase_auth/unknown] Firebase App Check token is invalid.` /
   `App Check 初期化完了 (debugProvider: false)` →
   adb 直接インストール（Play 配布でない）の release APK は **Play Integrity プロバイダの
   App Check 検証を通らず**、enforce 下の Auth / Firestore が全拒否される
4. 方針変更: `--dart-define=APP_CHECK_DEBUG=true`（`lib/main.dart:199`）で Debug プロバイダに
   する案も検討したが、**「クローズドテストに出す build そのもの」を検証する** ため、
   AAB を Play Console の内部／クローズドテストにアップロードし、**Play 経由でインストール**する方式にした
5. Play 配布の build 35（`installerPackageName=com.android.vending`）を両端末へ導入 →
   Play Integrity + Play App Signing が効いてサインイン成功

**学び**: ローカル署名の release APK を実機で App Check enforce 下テストする場合は
`--dart-define=APP_CHECK_DEBUG=true` + Firebase Console にデバッグトークン登録が必要。
「配布物そのもの」を試すなら内部テストトラック経由が確実（反映は数分）。

---

### 3. グループメンバー暗号化の実機復号バグを特定 ✅

**症状（9/9 から継続・再現）**: build 35（Play 配布）で、非オーナーのメンバー端末（Pixel 9 /
グループ「弥富の家」`652b2_1786001089692`）のメンバー管理画面で、`members[].name` /
`contact` が暗号エンベロープ（Base64）のまま表示される。買い物アイテム名は正常復号。

**採取した `🔎 [GF_*]` トレースのタイムライン（Pixel 9）**:

| 時刻 | イベント |
|---|---|
| 15:20:52 | `GF_DEC FAIL err=FormatException: recipient secret does not match` / `GF_SECRET keyLen=0` — グループ同期が走るが**鍵未解決**、空鍵で secret 導出 → 復号失敗 |
| 15:21:00〜03 / 15:21:21 | `💾 SharedGroup保存完了: 弥富の家` — Firestore→Hive 同期が**暗号文のまま Hive に保存** |
| 15:22:09.7 | `✅ [KEY_EXCHANGE] 鍵復号成功: 652b2` — **共有リストを開いた契機**で初めて鍵が永続化される |
| 15:22:10.6 | `GF_DEC OK -> "けいこ" / "kazaguruma0828@gmail.com"` — 鍵ありで復号成立。ただし共有リスト読み取り経路であって、グループの Hive 書き戻しではない |
| 以降 | `弥富の家` の Hive 保存は再発生せず → Hive は暗号文のまま → メンバー管理画面は凍った暗号文を表示し続ける |

**確定した原因（2 つの複合）**:

1. **鍵解決のタイミングが遅い**: メンバー端末のグループ鍵は
   `shared_list_page._ensureGroupKeyForCurrentGroup`（共有リスト初回オープン／stream 開始）
   でしか解決・永続化されない。アプリ起動時の Firestore→Hive グループ同期
   （`sync_service` / `user_initialization_service`）はそれより前に走るため、
   `decryptGroupPrimed` の `primeKey`（= `getPersistedGroupKey`）が空を返す。
2. **`SharedGroups` は書き込み経路でしか復号せず、Hive 読み取り経路は Hive を無条件信頼**:
   鍵前に同期が走ると `_dec` が復号失敗して**生の暗号文を返し**、それが平文扱いで Hive 保存。
   その後鍵が来ても再同期・再復号されない。メンバー管理画面は `allGroupsProvider`
   （Hive・平文前提）を読むため暗号文がそのまま出る。
   Phase 2 設計メモの「メンバー管理画面は個別の鍵解決不要」という前提が崩れていた。

アイテム名が平気なのは `hybrid_shared_list_repository._decryptListForRead` が
**毎回の読み取りで**鍵を取り直して復号しており、かつリストを開く頃には鍵解決済みだから。

補足: `decryptGroupField` のキーレスフォールバックは、鍵欠落時は try も catch も
`group-field-v1:$groupId:`（空鍵）で同一 secret を導出するため**無意味**だった。

---

### 4. 修正 A + B を実装 ✅

**B（主）— 同期前に鍵を prime する**:

| ファイル | 変更 |
|---|---|
| `lib/services/group_key_exchange_service.dart` | `groupDocHasEncryptedFields(Map)`（Firestore ドキュメントに暗号化フィールドが含まれるか判定）と `primeMemberGroupKeysForSync({groupIds, memberUid, budget})`（使用可能鍵が無いグループだけ `resolveGroupKeyForMember` を並列度 4・各 4s タイムアウト・全体 12s バジェットで解決）を追加 |
| `lib/services/sync_service.dart` | `syncAllGroupsFromFirestore` の復号ループ前に `_primeEncryptedGroupKeys(docs, uid)` を呼ぶ |
| `lib/services/user_initialization_service.dart` | `syncFromFirestoreToHive` の download ループ前に同等の prime を実行 |

これで、暗号化フィールドを持つグループは**初回同期の時点で鍵を解決**してから復号 → Hive に平文で保存される。
平文のみのグループには鍵解決を走らせない（無駄な `keyExchangeEvents` 参照を回避）。

**A（副・自己修復）— Hive 読み取り経路でも復号 + 鍵到達時に再構築**:

| ファイル | 変更 |
|---|---|
| `lib/datastore/shared_group_firestore_codec.dart` | `groupHasEncryptedFields(SharedGroup)` と `decryptGroupsPrimedLazy(List)`（暗号文を含むグループだけ prime + 復号、他は素通し）を追加 |
| `lib/providers/shared_group_provider.dart` | `AllGroupsNotifier.build()` で Hive 由来グループを `decryptGroupsPrimedLazy` に通してから返す。既に Hive に焼き込まれた暗号文も、鍵がある状態で再 build されれば平文へ戻る（冪等） |
| `lib/pages/shared_list_page.dart` | メンバー分岐で `resolveGroupKeyForMember` が走った後に `_refreshGroupsAfterKeyResolved()`（= `ref.invalidate(allGroupsProvider)`）を呼び、遅れて鍵が来たケースを自己修復 |
| `lib/services/notification_service.dart` | `_resolveGroupKeyForCurrentUser` の鍵解決成功時に `allGroupsProvider` / `selectedGroupProvider` を invalidate |

**併せて実施 — `🔎` 調査用トレースログの撤去**:

| ファイル | 撤去したもの |
|---|---|
| `lib/datastore/group_field_cipher.dart` | `🔎 [GF_PRIME]` / `🔎 [GF_CFG]`（`debugPrint`）、未使用になった `foundation.dart` import |
| `lib/datastore/shared_group_firestore_codec.dart` | `🔎 [GF_DEC]`（cipher=null / passthrough / OK / FAIL）、未使用 import |
| `lib/services/group_key_exchange_service.dart` | `🔎 [GF_SECRET]` / `🔎 [GF_ENC]`（`print`）|

`🔎 [GF_ENC]` の `activeGroupKey.substring(0, 6)` は短い鍵で `RangeError` を投げ、
`group_key_exchange_field_test.dart` の 2 ケースを壊していた（ロジック変更なしのはずが副作用）。撤去で解消。

**Verified**:

- `flutter analyze lib/` — 変更 8 ファイルに新規の警告・エラーなし（既存の info / 無関係ファイルの warning のみ）
- `flutter test test/datastore/ test/providers/ test/services/group_key_exchange_field_test.dart` — **165 件緑**
- 既存の失敗 `test/services/group_key_exchange_service_test.dart`（`firebase_auth_mocks` が pubspec でコメントアウト）は本作業と無関係の先行破損

---

### 5. 修正込みの build 36 をビルド ✅

- `pubspec.yaml` を `1.1.0+35` → `1.1.0+36`
- `flutter build appbundle --release --flavor prod` →
  `build/app/outputs/bundle/prodRelease/app-prod-release.aab`（77.9MB / versionCode 36）
- 内容: 作業 4 の A+B 修正を含む。Play Console の内部／クローズドテストへ再アップして
  実機 2 台を Play 経由で更新 → E2E 確認へ

**Status**: ✅ AAB 生成完了。アップロードと実機 E2E は次回

---

## 🗓 翌日（2026-09-11）の予定

1. **build 36 を Play 内部／クローズドテストにアップ → 実機 2 台で E2E 確認**:
   再インストール直後のメンバー端末で、リストを一度も開かずにメンバー管理画面を開いて
   `name` / `contact` が平文で出ること。オーナー端末（`iwk***`）でも確認
2. グループメンバー暗号化 **Phase 4**（既存平文データの再暗号化パス）+ **Phase 5**（バリデーションの
   重複チェックを復号済み members で）
3. `play-rtdn` トピック作成 + IAM 付与 + `playRtdnHandler` デプロイ、Play Console の請求サービス設定
4. Sandbox / 内部テストで「解約 → 失効」が `users/{uid}.purchaseType=free` に反映されることを実機確認
5. iOS の App Store Server Notifications V2 対応の設計
6. 特商法表記の仮置き値（電話受付時間・提供時期・英語表記）の確定
7. `decryptGroupField` のキーレスフォールバック（鍵欠落時に無意味）の整理

---

## 📝 変更ファイル一覧

### `pubspec.yaml`

| 変更 |
|---|
| `version: 1.1.0+34` → `1.1.0+35`（build 35 = クローズドテスト）→ `1.1.0+36`（build 36 = A+B 修正込み） |

### グループメンバー暗号化 実機復号バグ修正（A + B）

| ファイル | 更新内容 |
|---|---|
| `lib/services/group_key_exchange_service.dart` | `groupDocHasEncryptedFields` / `primeMemberGroupKeysForSync` 追加、`🔎 [GF_SECRET]` / `🔎 [GF_ENC]` 撤去 |
| `lib/services/sync_service.dart` | `_primeEncryptedGroupKeys` を追加し同期ループ前に呼ぶ、`group_key_exchange_service` import |
| `lib/services/user_initialization_service.dart` | download ループ前にグループ鍵 prime、`group_key_exchange_service` import |
| `lib/providers/shared_group_provider.dart` | `AllGroupsNotifier.build()` で `decryptGroupsPrimedLazy` を通す、codec import |
| `lib/pages/shared_list_page.dart` | `_refreshGroupsAfterKeyResolved()`（鍵解決後に `allGroupsProvider` invalidate）を追加・メンバー分岐から呼ぶ |
| `lib/services/notification_service.dart` | 鍵解決成功時に `allGroupsProvider` / `selectedGroupProvider` invalidate |
| `lib/datastore/shared_group_firestore_codec.dart` | `groupHasEncryptedFields` / `decryptGroupsPrimedLazy` 追加、`🔎 [GF_DEC]` と未使用 import 撤去 |
| `lib/datastore/group_field_cipher.dart` | `🔎 [GF_PRIME]` / `🔎 [GF_CFG]` と未使用 import 撤去 |

### 未追跡・本作業対象外

- `pubspec.lock`: transitive 版数差分のみ（9/9 から継続・据え置き）
- `docs/specifications/tokushoho.md`: 9/9 以前からの未コミット差分
