# 開発日報 - 2026年03月09日

## 📅 本日の目標

- [x] ユーザー切替時に前ユーザーのグループが残る問題の根本原因を調査する
- [x] ユーザー切替処理を単一路線化してローカル状態の整理を実装する
- [x] Windows で再発した「0件表示後に旧グループ再出現」問題を過去ログベースで再修正する
- [x] ネットワーク回復時の Hive-only データ再送経路を確認し、最低限の復旧同期を実装する
- [ ] オフライン削除整合性のためのモデル層拡張方針を確定する

---

## ✅ 完了した作業

### 1. ユーザー切替処理の完全整理版を実装 ✅

**Purpose**: サインアウト後に別ユーザーでサインインした際、前ユーザーのグループ・選択状態・最終使用リスト情報が残る問題を根本から整理する。

**Background**: 既存実装では、サインイン画面、Auth provider、初期化ウィジェットがそれぞれ別々にユーザー切替を扱っており、Hive クリア、Windows の user-specific Hive 切替、SharedPreferences の削除、Provider の無効化が分散していた。

**Problem / Root Cause**:

ユーザー切替処理が複数箇所に分散し、永続化された選択状態が前ユーザーのまま残っていた。

```dart
// ❌ 切替処理が複数箇所に分散
await ref.read(authProvider).signIn(email, password);
await ref.read(forceSyncProvider.future);
ref.invalidate(allGroupsProvider);

// 別の場所でも UID 差分チェックと Hive クリアを実施
// selected_group_id / current_list_id / group_list_map の削除も不統一
```

**Solution**:

`UserIdChangeHelper.ensureUserContextReady()` に切替処理を集約し、ログイン後のユーザーコンテキスト準備を単一路線化した。

```dart
// ✅ サインイン後の切替処理を helper に集約
await UserIdChangeHelper.ensureUserContextReady(
  ref: ref,
  context: context,
  user: currentUser,
  mounted: mounted,
);

// ✅ サインアウト前クリーンアップも helper に集約
await UserIdChangeHelper.performSignOutCleanup(ref: ref);
```

さらに、永続化された選択状態の削除も統一した。

```dart
// ✅ グループ選択とリスト選択を永続化状態ごと削除
await ref.read(selectedGroupIdProvider.notifier).clearSelectionAndPersistence();
await ref.read(currentListProvider.notifier).clearSelectionAndPersistence();
```

**検証結果**:

| 確認項目                             | 結果 |
| ------------------------------------ | ---- |
| 変更ファイルの静的エラー確認         | PASS |
| ユーザー切替チェックリスト作成       | PASS |
| 前ユーザー選択状態の削除ロジック実装 | PASS |

**Modified Files**:

- `lib/helpers/user_id_change_helper.dart` - ユーザー切替処理の集約、サインアウト前クリーンアップ、Firestore優先復元
- `lib/pages/home_page.dart` - サインイン/サインアウト処理を helper 経由に統一
- `lib/providers/auth_provider.dart` - サインイン後のユーザーコンテキスト準備を helper 化
- `lib/widgets/app_initialize_widget.dart` - 初期化時の UID 監視処理を helper ベースに整理
- `lib/services/user_preferences_service.dart` - `clearUserSwitchState()` を追加
- `lib/providers/current_list_provider.dart` - リスト選択の永続化削除を追加
- `lib/providers/purchase_group_provider.dart` - グループ選択の永続化削除を追加
- `docs/daily_reports/2026-03/user_switch_verification_checklist_20260309.md` - 検証チェックリスト新規作成

**Status**: ✅ 実装完了・静的確認済み

---

### 2. Windows 再発バグの過去ログ調査と再修正 ✅

**Purpose**: Windows で「A → B → A」の連続切替後にグループ数 0 件となり、新規グループ作成を契機に旧グループが再出現する回帰を再修正する。

**Background**: この現象は過去に直していたため、過去ログと Copilot 指示書を調べて、当時の設計意図を再確認した。

**Problem / Root Cause**:

Windows では `initializeForUser()` 直後の空 Hive 状態をそのまま真実の情報源として扱うと、Firestore からの復元前に「グループ0件」と誤判定してしまう。

```dart
// ❌ Wrong: 切替直後の空 Hive をそのまま採用
await hiveService.initializeForUser(newUid);
ref.invalidate(allGroupsProvider);
final groups = await ref.read(allGroupsProvider.future); // []
```

**Solution**:

サインイン後に Firestore を source of truth として再同期し、Hive cleanup と provider refresh を明示的に実行する流れへ戻した。

```dart
// ✅ Correct: Firestore優先で復元
ref.invalidate(forceSyncProvider);
await ref.read(forceSyncProvider.future);
await ref.read(allGroupsProvider.notifier).cleanupInvalidHiveGroups();
await ref.read(allGroupsProvider.notifier).refresh();
```

また、この回帰を今後繰り返さないように anti-pattern を追記した。

**検証結果**:

| 確認項目                                       | 結果 |
| ---------------------------------------------- | ---- |
| 過去ログ・既存指示書の調査                     | PASS |
| `forceSyncProvider` の命令的再実行パターン修正 | PASS |
| Copilot 指示書への anti-pattern 追記           | PASS |

**Modified Files**:

- `.github/copilot-instructions.md` - Windows user switch の anti-pattern と `forceSyncProvider` の invalidate ルール追加
- `lib/helpers/user_id_change_helper.dart` - Firestore優先復元処理の再整理
- `lib/pages/home_page.dart` - サインイン後の provider 再構築順を調整
- `lib/widgets/group_list_widget.dart` - 手動同期時に `forceSyncProvider` を invalidate してから実行
- `lib/widgets/group_selector_widget.dart` - 同上
- `lib/widgets/app_initialize_widget.dart` - 同上

**Status**: ✅ 実装完了・静的確認済み

---

### 3. ネットワーク回復時の Hive-only データ再送同期を追加 ✅

**Purpose**: ネットワーク障害中に Hive のみに残ったデータが、接続回復後に自動で Firestore に押し戻されるようにする。

**Background**: 調査の結果、グループ側には一部救済経路があったが、SharedList/SharedItem 側はメモリ上の再試行キューに依存しており、接続回復イベントと直接つながっていなかった。

**Problem / Root Cause**:

ネットワーク監視はオンライン復帰を通知するだけで、復帰後の再送同期までは実行していなかった。

```dart
// ❌ オンライン復帰は検知するが、再送同期は呼ばれない
final isOnline = await networkMonitor.manualRetry();
if (isOnline) {
  // バナーを閉じるだけ
}
```

**Solution**:

`HomeScreen` に offline → online 復帰リスナーを追加し、復帰時に Group と List の再送同期を一度だけ実行するようにした。

```dart
// ✅ ネットワーク復帰時に回復同期を実行
if (status == NetworkStatus.online && _hasSeenOffline) {
  _hasSeenOffline = false;
  _runRecoverySync();
}
```

SharedList 側の双方向同期本体も実装した。

```dart
// ✅ Hiveにある全リストを Firestore に再送
final localLists = _hiveRepo.getAllLists();
for (final list in localLists) {
  await _firestoreRepo!.updateSharedList(list);
}
```

**検証結果**:

| 確認項目                                              | 結果 |
| ----------------------------------------------------- | ---- |
| `HomeScreen` 追加ロジックの静的エラー                 | PASS |
| `HybridSharedListRepository` 追加ロジックの静的エラー | PASS |
| グループ/リスト再送同期経路の接続                     | PASS |

**Modified Files**:

- `lib/screens/home_screen.dart` - オフライン復帰監視と回復同期トリガーを追加
- `lib/datastore/hybrid_shared_list_repository.dart` - `forceSyncBidirectional()` 実装、`syncOnNetworkRecovery()` 追加

**Status**: ✅ 実装完了・静的確認済み

---

## 🐛 発見された問題

### オフライン削除整合性の弱さ ⚠️

- **症状**: Hive にしか存在しない削除操作を接続回復後に厳密に再現する仕組みが弱い
- **原因**: `SharedItem` には論理削除があるが、`SharedList` 自体には削除トゥームストーンや `syncStatus` がない
- **対処**: 今日は方針整理まで実施。モデル変更は明日検討
- **状態**: 調査完了・未着手

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ ユーザー切替時に前ユーザーのグループが残る問題の整理と修正（完了日: 2026-03-09）
2. ✅ Windows の 0件表示→旧グループ再出現回帰の再修正（完了日: 2026-03-09）
3. ✅ `forceSyncProvider` の命令的再実行 anti-pattern 修正（完了日: 2026-03-09）
4. ✅ ネットワーク回復時の Group/List 再送同期追加（完了日: 2026-03-09）

### 対応中 🔄

1. 🔄 オフライン削除整合性の設計整理（Priority: High）

### 翌日継続 ⏳

- ⏳ `SharedList` モデルに `isDeleted` / `deletedAt` / `syncStatus` 相当が必要か最終判断
- ⏳ 実機でオフライン → 復帰シナリオを通し確認
- ⏳ ユーザー切替チェックリストの未消化項目を実施

---

## 💡 技術的学習事項

### `FutureProvider` を命令的トリガーとして使うなら毎回 invalidate が必要

**問題パターン**:

```dart
// ❌ 前回の完了済み Future を再利用する可能性がある
await ref.read(forceSyncProvider.future);
```

**正しいパターン**:

```dart
// ✅ 明示的な再同期は invalidate してから await する
ref.invalidate(forceSyncProvider);
await ref.read(forceSyncProvider.future);
```

**教訓**: `FutureProvider` は状態を保持するため、命令的な再同期トリガーとして使う場合は「毎回再実行させる」意図をコードで明示しないと、ユーザー切替や回復同期で古い結果を掴む。

---

### Windows の user-specific Hive 切替直後の空状態は真実の情報源ではない

**問題パターン**:

```dart
// ❌ Hive切替直後の空状態を採用してしまう
await hiveService.initializeForUser(newUid);
final groups = await ref.read(allGroupsProvider.future); // []
```

**正しいパターン**:

```dart
// ✅ Firestore復元を先に実行する
await hiveService.initializeForUser(newUid);
ref.invalidate(forceSyncProvider);
await ref.read(forceSyncProvider.future);
await ref.read(allGroupsProvider.notifier).cleanupInvalidHiveGroups();
await ref.read(allGroupsProvider.notifier).refresh();
```

**教訓**: Windows では Hive フォルダ切替の瞬間に空状態が見えることがある。サインイン直後は必ず Firestore を source of truth として復元してから UI 判定する。

---

## 🗓 翌日（2026-03-10）の予定

1. オフライン削除整合性のために `SharedList` モデル変更が必要か最終判断する
2. ネットワーク切断 → Hive保存 → 接続回復 → Firestore反映の実機確認を行う
3. ユーザー切替チェックリストの未完了項目を Windows / Android で埋める
4. 必要ならトゥームストーン設計まで実装する
