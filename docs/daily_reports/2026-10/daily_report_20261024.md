# 開発日報 - 2026年10月24日

## 📅 本日の目標

- [x] dev でプレミアムを有効にしてもグループが3個までしか作れない原因を調べる
- [x] 家族特典の解除後にグループ数が上限を超えたときの扱いを決めて実装する

---

## ✅ 完了した作業（午前）

### 1. dev の課金状態の切替が反映されない件 ✅

**Problem / Root Cause**:

- dev で「Premium にする」を押してもグループが3個までしか作れなかった。
- `setDevPurchaseType` などの Callable は、コード側で `enforceAppCheck: true` を指定している。コンソールで App Check の適用をオフにしても Functions には効かないため、デバッグトークン未登録の端末では Callable が拒否され、`purchaseType` が `free` のままになる。

**Solution**: コード変更なし。端末のデバッグトークンを dev の App Check に登録する（10/21 の日報のメモと同じ）。

---

### 2. dev でグループを作成できない不具合 ✅

**Problem / Root Cause**:

- 上限内でもグループが作成されなかった。
- `AllGroupsNotifier.createNewGroup()` は dev フレーバーのとき認証チェックを飛ばし、`currentUser` を `null` のまま進めていた。そのためオーナーの `memberId` が `local_user_<timestamp>` になり、`ownerUid` / `allowedUid` も同じ値になる。
- Firestore ルールは `ownerUid == request.auth.uid` を要求するため書き込みが拒否され、`HybridSharedGroupRepository` が Hive だけに保存する。Firestore と同期した時点で Hive だけのグループが消え、作成されないように見えていた。

**Solution**: dev でも `FirebaseAuth.instance.currentUser` を取得し、サインイン済みならその uid でオーナーを作るようにした。未サインイン時にチェックを飛ばす動きは残した。

**Modified Files**: `lib/providers/shared_group_provider.dart`

**Status**: ✅ 修正済み（実機確認は未実施）

---

### 3. 家族特典の解除後にグループ数が上限を超えたときの制限 ✅

**Purpose**: 家族特典の受諾・発行者による解除はユーザーが実機で確認済み。ただ、解除されて Free に戻っても4個目以降のグループがそのまま使えてしまっていた。

**Solution**:

- `groupLimitStatusProvider`（`lib/providers/group_limit_provider.dart`）を追加した。`allGroupsProvider` のグループ数がプラン上限（Free 3 / Premium 20）を超えているかを返す。グループ一覧の読み込み中は超過扱いにしない。
- `GroupLimitWarningBanner`（`lib/widgets/group_limit_warning_banner.dart`）を追加した。超過中だけ、上限・現在の数・削除が必要な数を表示する。ホーム画面（「グループ画面を開く」ボタン付き）とグループ画面に表示する。
- `HomeScreen` で、超過中はリストタブを押してもスナックバーを出して移動しないようにした。リスト画面を開いたまま超過になった場合も、リストの代わりに警告を表示する。
- 文言4個（`groupLimitExceededTitle` など）を日・英・葡・中に追加した。
- 参加しているだけのグループも数に含める（作成時の上限チェックと同じ）。警告文で「参加しているグループは退出できます」と案内している。
- ルールを `instructions/20_groups_lists_items.md` の 1.1 に追記した。

**Modified Files**:

- `lib/providers/group_limit_provider.dart`（新規）、`lib/widgets/group_limit_warning_banner.dart`（新規）
- `lib/screens/home_screen.dart`、`lib/pages/home_page.dart`、`lib/pages/shared_group_page.dart`
- `lib/l10n/app_texts.dart`、`app_texts_ja.dart`、`app_texts_en.dart`、`app_texts_pt.dart`、`app_texts_zh_hans.dart`
- `instructions/20_groups_lists_items.md`

**Status**: ✅ 実装済み（`flutter analyze` でエラー・警告なし、`test/screens/home_screen_test.dart` 成功。実機確認は未実施）

---

## 🔄 継続・確認事項

- dev でグループを作成し、ログに `❌ [FIRESTORE] createGroup error` / `Hiveフォールバック` が出ないことを確認する。失敗していた間の `local_user_...` オーナーのグループが Hive に残っていれば削除する。
- 家族特典を解除して4個以上になったとき、ホーム・グループ画面に警告が出てリストタブが開けないこと、3個まで削除すると解除されることを実機で確認する。
- 参加しているだけのグループを上限の数に含める方針でよいか決める。
