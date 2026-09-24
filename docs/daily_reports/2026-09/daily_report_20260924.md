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

## 🗓 次回の予定（引き継ぎ）

1. **App Check / Firestore 断続的 PERMISSION_DENIED の調査**: Firebase Console
   で `gotoshop-572b7` プロジェクトの App Check 強制設定（Cloud Firestore の
   Enforce/Monitor）と、登録済みデバッグトークンの有効期限を確認する。
2. 今回の修正（原因1〜4）が本番相当のシナリオ（複数メンバー・複数回ローテーション）
   でも問題ないか、機会があれば追加の実機 E2E を行う。

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
| `docs/daily_reports/2026-09/daily_report_20260924.md` | **新規**: 本日の日報 |

### 未追跡・本コミット対象外

- `.vscode/settings.json`: エディタ側のフォーマット差分・Java LSP メモリ設定のローカル変更。本日の作業と無関係のため据え置き
- `pubspec.lock`: ローカル環境での依存解決により一部パッケージがダウングレードされた差分。本日の作業と無関係のため据え置き
- `.artifacts/`: 追跡対象外の作業ディレクトリ。本日の作業と無関係のため据え置き
