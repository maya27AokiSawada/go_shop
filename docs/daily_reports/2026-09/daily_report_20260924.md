# 開発日報 - 2026年09月24日

## 📅 本日の目標

- [x] `android/app` 配下に配置された dev/prod 用 `google-services.json` の整合性を確認する
- [x] 「鍵ローテーション後にリスト画面を開かないとグループメンバーの復号ができない」不具合を修正する
- [x] Android エミュレーター・実機（SH-54D）で修正内容を検証する
- [x] 本日の作業を日報にまとめて `sumomo-planning` へコミット・プッシュする

---

## ✅ 完了した作業

### 1. Android `google-services.json` の配置確認・dev flavor package_name 不一致の修正 ✅

**Purpose**: `android/app`、`android/app/src/dev`、`android/app/src/prod` に配置された
`google-services.json` が、`build.gradle.kts` の flavor 設定と整合しているかを確認する。

**発見**: `android/app/build.gradle.kts` の dev flavor `applicationId` は
`net.sumomo_planning.goshopping.dev`（ドット区切り）だが、既存の
`android/app/src/dev/google-services.json` の `package_name` は
`net.sumomo_planning.goshopping_dev`（アンダースコア区切り）で不一致。
過去にも同じ不整合が発生・修正されていた
（[daily_report_20260819.md](../2026-08/daily_report_20260819.md)）が、再発していた。
`flutter build --flavor dev` 実行時に
`No matching client found for package name 'net.sumomo_planning.goshopping.dev'`
で失敗する状態だった。

**対応**: ユーザー判断で「Firebase Console 側を `goshopping.dev` に合わせて再登録」を選択。
Firebase Console の dev プロジェクト（`gotoshop-572b7`）で
`net.sumomo_planning.goshopping.dev` の Android アプリを登録し直し、
再ダウンロードした `google-services.json` を `android/app/src/dev/` に配置。
併せて [SETUP.md](../../../SETUP.md) 内の誤記（dev flavor の package_name を
`net.sumomo_planning.go_shop.dev` としていた記述）を `goshopping.dev` に修正。

**Status**: ✅ 完了。prod flavor・共通の `android/app/google-services.json` は元々整合していたため変更なし。

---

### 2. グループメンバー復号バグ（鍵ローテーション後、リスト画面を開くまで復号不可）の調査・修正 ✅

**Purpose**: 鍵ローテーション後、グループメンバー管理画面を単独で開いても
`members[].name` 等が復号されず、買い物リスト画面を一度開くまで直らない不具合を修正する。

**原因1: 鍵解決トリガーがリスト画面にしかなかった**

新しい鍵の解決・配布処理（`resolveGroupKeyForMember` / `ensureGroupKeyForOwner`）は
[`shared_list_page.dart`](../../../lib/pages/shared_list_page.dart) の
`_ensureGroupKeyForCurrentGroup` にしか実装されておらず、買い物リスト画面を開いた
ときにしか実行されなかった。グループメンバー管理画面は `allGroupsProvider`
（Hiveキャッシュ＋既存ローカル鍵での遅延復号のみ）を見るだけで、新しい鍵を
取りに行く処理を一切トリガーしていなかった。

**対応**: [`group_key_access_coordinator.dart`](../../../lib/services/group_key_access_coordinator.dart)
を新規作成し、`_ensureGroupKeyForCurrentGroup` の鍵解決ロジックを `ensureGroupKeyAvailable()`
として切り出し。[`shared_list_page.dart`](../../../lib/pages/shared_list_page.dart) はこれを
呼ぶ薄いラッパーに変更（挙動は同一）。
[`group_member_management_page.dart`](../../../lib/pages/group_member_management_page.dart) の
`initState()` でも同じ関数を呼ぶよう追加し、メンバー管理画面を単独で開いても鍵解決が走るようにした。

**原因2: `rotateGroupKey` のローカル鍵永続化タイミングが早すぎた（実機テストで発見）**

実機（Android エミュレーター + SH-54D、USB接続）で鍵ローテーションを実行して検証した際、
Firebase App Check のデバッグトークン未登録により1回目のローテーションが
Firestore 書き込み時に `PERMISSION_DENIED` で失敗。デバッグトークンを登録して
2回目を実行したところ成功したが、**オーナー端末だけメンバー詳細画面を開くまで
復号できない**という新たな症状が発生。

調査の結果、[`group_key_exchange_service.dart`](../../../lib/services/group_key_exchange_service.dart)
の `rotateGroupKey()` が、Firestore への配布が**何も成功していない時点**で
`_persistGroupKeyLocally()` を呼び新鍵をローカル `current` に即保存しており、
このとき直前の `current` は自動的に `previous`（1世代前の鍵）へ退避される仕様だった。
1回目の失敗で「幻の鍵」が `current` に保存された状態のまま2回目を実行すると、
2回目が新たに生成した「本物の鍵」を `_persistGroupKeyLocally` する際、
**直前に入っていた「幻の鍵」が `previous` として上書き保存され、本来の旧鍵
（Firestore上の旧暗号文を実際に復号できる鍵）が失われる**ことが判明。

**対応**: `_persistGroupKeyLocally()` の呼び出しを、Firestore への全書き込み
（`keyExchangeEvents` 配布・`activeKeyVersion` 更新）が成功した**後**に移動。
失敗時にローカル状態を一切汚染しないようにした。

**原因3（本命）: 新規グループ作成時に previous key が永久に汚染される**

原因2の修正後、**新規に作成したグループ**でも同じ「グループフィールド移行スキップ
（旧鍵で復号失敗）」の警告が大量に（1バーストで500件超）繰り返し出ることを実機で確認。
これは既存の壊れたテストグループ特有の問題ではなく、**新規グループ作成の度に必ず
発生する恒久的なバグ**と判明。

`ensureGroupKeyForOwner()` の新規グループ作成分岐（`shouldCreate` 側）が、
実際に配布される鍵とは別に**使い捨ての鍵**を先に生成してローカル保存し、
直後に呼ぶ `rotateGroupKey()` が本物の鍵を生成・永続化する際、
「現在の鍵を previous へ退避する」ロジックにより**一度も Firestore への暗号化に
使われていない使い捨て鍵が `previous key` として永久に居座る**ことが原因だった。
`reencryptGroupFieldsIfKeyChanged`（グループ読み込みのたびに実行）はこの
使い捨て鍵で復号を試みては必ず失敗し、警告を出し続ける（`previous != current` の
不一致が絶対に解消しないため、通常のローテーションのような自然収束もしない）。

**対応**: 使い捨て鍵の生成・事前永続化を削除し、`rotateGroupKey()` に鍵の生成・配布・
永続化を一任するよう変更。新規グループでは `previous key` が最初から空になり、
`reencryptGroupFieldsIfKeyChanged` は即座に no-op で返る。

**原因4（軽微、効率改善）**: `reencryptGroupFieldsIfKeyChanged` の `migrateField` が、
既に `currentKey` で復号できる（＝移行済みの）フィールドに対しても毎回無条件で
`previousKey` での復号を試みて失敗・警告していた。`currentKey` での復号を先に
試すよう変更し、無駄な失敗の試行と警告ログを削減。

**テスト**: [`group_key_exchange_field_rotation_test.dart`](../../../test/services/group_key_exchange_field_rotation_test.dart)
に以下を追加（既存3件と合わせ計6件、全件パス）:

- `migrateField` の current key 優先チェックにより、移行済みグループでは
  Firestore への書き戻しが発生しないこと
- `rotateGroupKey` が失敗→再試行のシナリオで、本来の旧鍵（previous key）を
  破壊しないこと
- `ensureGroupKeyForOwner` が新規グループの初回鍵作成時に previous key を
  汚染しないこと（原因3の修正）。**この回帰テストは実際に修正前のコードへ戻すと
  失敗することを確認済み**（`previous key` に使い捨て鍵が入ってしまう）

**実機検証**: Android エミュレーター（オーナー役）+ SH-54D（USB接続、メンバー役）で
新規グループを作成し鍵ローテーションを実行。修正後は KEY_EXCHANGE 関連のログが
完全にクリーン（鍵作成→配布→メンバーへの鍵保存→オーナー側の鍵復号成功まで、
警告・エラーなし）であることを確認。

**Status**: ✅ 実装・テスト・実機検証完了。

---

### 3. 実機検証中に判明した別問題（未解決・保留）🔄

実機テスト中、Firebase App Check のデバッグトークン未登録による Firestore
`PERMISSION_DENIED`（鍵ローテーション・通知送信・グループ一覧取得など）に複数回遭遇し、
都度 Firebase Console でトークンを登録して解消した。

ただし、既に登録済みのトークンでも `keyRecoveryEnvelopes` 書き込みや
`notifications` 書き込み、`sharedLists` の realtime listen が断続的に
`PERMISSION_DENIED` になる事象が残っており、単純なトークン未登録では説明が
つかない。App Check の実際の検証トークン（デバッグトークンとは別に、Firebase
側が発行する短命の attestation トークン）の期限切れ・再発行失敗、または
Firestore の Enforce 設定に起因する可能性がある。クライアント側のログだけでは
確定できないため、Firebase Console（App Check → APIs → Cloud Firestore の
Enforce 状態、登録済みデバッグトークンの有効期限）の確認をユーザーに依頼した。

**Status**: 🔄 保留（ユーザー判断で午後以降に対応）。今回のグループメンバー復号
バグとは別の問題として切り分け済み。

---

### 4. 午後の実機検証で発覚した3つの独立したバグの調査・修正 ✅

午前中に保留とした「App Check 強制設定下での断続的 PERMISSION_DENIED」を
実機（Android エミュレーター + SH-54D）で継続調査した結果、App Check とは
別に**3つの独立したバグ**が重なって発生していたことが判明した。

**原因A: `main_dev.dart` / `main_prod.dart` に App Check 初期化が存在しない**

`FirebaseAppCheck.instance.activate()` は [`lib/main.dart`](../../../lib/main.dart)
にしか実装されておらず、`-t lib/main_dev.dart` / `-t lib/main_prod.dart` で
起動したセッションでは App Check が一度も初期化されず、無検証トークンで
Firestore にリクエストし続けていた。Firebase Console の App Check 使用状況が
「77%検証済み / 23%未検証」だったのは、起動時の entry point 次第で
App Check が有効化されたりされなかったりしていたため。

**対応**: [`lib/main_dev.dart`](../../../lib/main_dev.dart) と
[`lib/main_prod.dart`](../../../lib/main_prod.dart) に `main.dart` と同一の
App Check 初期化ブロックを追加。

**原因B: `group_member_added` 通知が3箇所で設計上絶対に通らないルールに違反**

Firestore の `isValidGroupMemberAddedCreate()` ルールは `group_member_added`
タイプの通知を「招待受諾者が招待元へ送る」用途専用に設計しており、
`metadata.acceptorUid` / `metadata.invitationId` が実在の招待ドキュメントと
整合することを必須にしている。一方、以下3箇所は同じタイプを
「メンバー変更を知らせる」汎用通知として誤用しており、必須メタデータを
満たせないため**常に** `PERMISSION_DENIED` になっていた:

- [`group_creation_with_copy_dialog.dart`](../../../lib/widgets/group_creation_with_copy_dialog.dart):
  グループ作成者への自己通知（2箇所）
- [`notification_service.dart`](../../../lib/services/notification_service.dart):
  既存メンバーへの新メンバー参加通知、受諾者への承認通知

**対応**: 上記3箇所（実際には同一パターンの4呼び出し）のタイプを
`NotificationType.groupUpdated`（送信者がグループメンバーであることのみを
要求する緩いルール）に変更。正規の「受諾者→招待元」通知
（[`qr_invitation_service.dart`](../../../lib/services/qr_invitation_service.dart)）
は変更なし。

**原因C: 本番 Firestore ルールに `keyRecoveryEnvelopes` のブロックが丸ごと欠落**

鍵ローテーション（`rotateGroupKey`）が `SharedGroups/{groupId}/keyRecoveryEnvelopes/`
への書き込みで必ず失敗する問題を診断ログで追跡した結果、
`server.ownerUid` / `currentUid` が完全一致しているにもかかわらず拒否される
ことが判明。ユーザーが Firebase Console のルールを直接確認したところ、
ローカルの [`firestore.rules`](../../../firestore.rules) にある
`keyRecoveryEnvelopes` の `match` ブロックが本番に一度もデプロイされて
いなかった（ルールが無いパスはデフォルト拒否）。ついでに `users/{userId}`
の課金フィールド保護（`hasProtectedPurchaseFields` 等）も本番未反映だった
ことが判明。

**対応**: ユーザーが Firebase Console のルールエディタでローカル
`firestore.rules` の内容を貼り付けて公開。デプロイ後、鍵ローテーションが
`keyRecoveryEnvelope 書き込み成功` → `keyExchangeEvents 書き込み成功` →
`activeKeyVersion 更新成功` まで完走することを診断ログで確認。

**副次確認事項**:
- `group_member_management_page.dart` / `shared_list_page.dart` の
  `members[].name` 復号は `allGroupsProvider` のリアルタイムリスナー
  （`FirestoreGroupSyncService.watchUserGroups()`）駆動で自動的に
  再試行される設計であることをコードで確認。テストで短時間に4回連続
  ローテーションした際は鍵の世代が飛び複数回の再試行を要したが、
  通常運用（単発ローテーション）およびメンバー端末を完全終了→再起動
  した状態からの単発ローテーションでは、いずれも自動復号を実機で確認済み。
- [`qr_invitation_service.dart:752-769`](../../../lib/services/qr_invitation_service.dart#L752-L769)
  の招待受諾直後の自己検証クエリが、宛先が自分ではない通知を読もうとして
  `PERMISSION_DENIED` になる非致命的な既知の問題を発見（try/catchで
  警告ログのみ、処理は継続するため実害なし）。今回は未修正・情報共有のみ。

**Status**: ✅ 実装・実機検証・本番ルールデプロイ完了。

---

### 5. ビルド 1.1.0+39 のリリースビルド作成 ✅

上記修正を反映し、`pubspec.yaml` のビルド番号を 38 → 39 に更新。
`prod` flavor で Android App Bundle と iOS IPA をビルドし、クローズド
テスト配信用の成果物を作成した。

- Android AAB: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`（80.4MB）
- iOS IPA: `build/ios/ipa/go_shop.ipa`（44.3MB、自動署名・Team 9A34XAPY8W）

アップロード（Play Console / App Store Connect）はユーザーが別途実施。

**Status**: ✅ ビルド完了。

---

## 🗓 次回の予定（引き継ぎ）

1. `qr_invitation_service.dart` の招待受諾直後の自己検証クエリ
   （非自分宛て通知への read）を見直す（優先度低、非致命的）。
2. 短時間の連続ローテーションで鍵世代が飛んだ場合の収束を早める改善
   （`keyRecoveryEnvelopes` の複数世代チェーン走査など）を検討する
   （優先度低、通常運用では発生しにくい）。
3. クローズドテストでの実配信後のフィードバック確認。

---

## 📝 ドキュメント / 変更ファイル一覧

| ファイル | 更新内容 |
|---|---|
| `SETUP.md` | dev flavor の package_name 誤記（`go_shop.dev` → `goshopping.dev`）を修正 |
| `android/app/src/dev/google-services.json` | **Git管理対象外**（gitignore）。package_name を `goshopping.dev` に一致する内容へ再配置 |
| `lib/services/group_key_access_coordinator.dart` | **新規**: `SharedListPage` にあった鍵解決ロジックを `ensureGroupKeyAvailable()` として切り出し |
| `lib/pages/shared_list_page.dart` | `_ensureGroupKeyForCurrentGroup` を `ensureGroupKeyAvailable()` 呼び出しの薄いラッパーに変更 |
| `lib/pages/group_member_management_page.dart` | `initState()` で `ensureGroupKeyAvailable()` を呼び、画面単独表示時にも鍵解決を実行するよう追加 |
| `lib/services/group_key_exchange_service.dart` | `rotateGroupKey`: ローカル鍵永続化を Firestore 書き込み成功後に移動（失敗→再試行時の previous key 汚染を防止）。`ensureGroupKeyForOwner`: 新規グループ作成時の使い捨て鍵生成・事前永続化を削除（previous key 永久汚染バグの修正）。`reencryptGroupFieldsIfKeyChanged`: `migrateField` で current key を先に試すよう変更（無駄な失敗試行・警告ログを削減） |
| `test/services/group_key_exchange_field_rotation_test.dart` | 上記3点の回帰テストを追加（計6件） |
| `lib/main_dev.dart` | App Check 初期化ブロックを追加（`main.dart` と同内容） |
| `lib/main_prod.dart` | App Check 初期化ブロックを追加（`main.dart` と同内容） |
| `lib/widgets/group_creation_with_copy_dialog.dart` | 自己通知の `NotificationType` を `groupMemberAdded` → `groupUpdated` に変更（3箇所） |
| `lib/services/notification_service.dart` | 既存メンバー通知・受諾承認通知の `NotificationType` を `groupMemberAdded` → `groupUpdated` に変更（2箇所） |
| `firestore.rules` | **本番デプロイのみ**（ローカルファイルは変更なし）。`keyRecoveryEnvelopes` ブロック等、未デプロイだった内容を Firebase Console から公開 |
| `pubspec.yaml` | ビルド番号を `38` → `39` に更新 |
| `docs/daily_reports/2026-09/daily_report_20260924.md` | 本日の日報（午前・午後の作業を追記） |

### 未追跡・本コミット対象外

- `.vscode/settings.json`: エディタ側のフォーマット差分・Java LSP メモリ設定のローカル変更。本日の作業と無関係のため据え置き
- `pubspec.lock`: ローカル環境での依存解決により一部パッケージがダウングレードされた差分。本日の作業と無関係のため据え置き
- `.artifacts/`: 追跡対象外の作業ディレクトリ。本日の作業と無関係のため据え置き
