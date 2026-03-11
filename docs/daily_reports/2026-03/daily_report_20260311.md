# 開発日報 - 2026年03月11日

## 📅 本日の目標

- [x] 実機テスト結果を整理し、未解決項目を優先度付きで明確化する
- [x] グループ名変更の同期不具合をオンライン・オフライン両方で改善する
- [x] 再インストール後に Firestore 復元されない問題の調査を開始し、初手の対策を実装する

---

## ✅ 完了した作業

### 1. 実機テストチェックリスト整理と結果の明文化 ✅

**Purpose**: 本日の実機確認結果を、翌日以降の再テストと優先度判断に使える形へ整理する。

**Background**: ユーザーが [docs/daily_reports/2026-03/tomorrow_device_test_checklist_20260311.md](c:/FlutterProject/go_shop/docs/daily_reports/2026-03/tomorrow_device_test_checklist_20260311.md) に実機結果を書き込んでおり、成功項目と未解決項目が混在していた。

**Problem / Root Cause**:

チェックの記法と所見の粒度が揃っておらず、どこまで確認済みか、何が未解決かが追いにくい状態だった。

```text
❌ Before
- [✅] / [ ] が混在
- 結果と課題が同一行に混在
- 失敗理由が末尾メモに分散
```

**Solution**:

チェック記法を `- [x] / - [ ]` に統一し、各項目を `結果 / 課題 / 改善案 / 補足` に分解して読みやすくした。未解決事項も末尾に明示した。

```text
✅ After
- [x] 手順完了
結果: OK / 失敗 の判定を追記
課題: 未解決症状を明記
改善案: 次の修正方針を明記
```

**検証結果**:

| 確認項目                      | 結果 |
| ----------------------------- | ---- |
| 成功 / 失敗チェックの記法統一 | PASS |
| 実機所見の文章整理            | PASS |
| 主な未解決事項の抽出          | PASS |

**Modified Files**:

- `docs/daily_reports/2026-03/tomorrow_device_test_checklist_20260311.md` - 実機テスト結果を整理し、FAIL 判定と未解決事項を明記

**Status**: ✅ 完了

---

### 2. グループ名変更の即時同期を通知ベースで修正 ✅

**Purpose**: グループ名変更が他端末へ即時反映されない問題を解消する。

**Background**: 実機テストで、リスト名変更は反映される一方、グループ名変更は他端末へ即時反映されていなかった。

**Problem / Root Cause**:

グループ更新後に、他端末へ Firestore→Hive 再同期を促す通知が送られていなかった。

```dart
// ❌ Before: グループ名変更後に通知を送らない
await repository.updateGroup(group.groupId, updatedGroup);
```

**Solution**:

グループ名変更専用の通知送信経路を追加し、既存の `groupUpdated` 通知受信時の再同期処理を活用できるようにした。

```dart
// ✅ After: グループ名変更通知を送信
await sendNotificationToGroup(
  groupId: groupId,
  type: NotificationType.groupUpdated,
  message: '$renamerName が「$oldName」を「$newName」に変更しました',
  metadata: {
    'oldGroupName': oldName,
    'newGroupName': newName,
    'renamerName': renamerName,
  },
);
```

**検証結果**:

| テスト                                 | 結果 |
| -------------------------------------- | ---- |
| 両端末オンライン時のグループ名変更反映 | PASS |
| 既存通知フローとの整合性               | PASS |

**Modified Files**:

- `lib/services/notification_service.dart` - `sendGroupRenamedNotification()` を追加
- `lib/pages/group_member_management_page.dart` - グループ名変更の UI 更新経路を調整

**Status**: ✅ 完了・実機確認済み

---

### 3. オフライン時グループ名変更の回復同期を実装 ✅

**Purpose**: オフライン中のグループ名変更がオンライン復帰後に Firestore と他端末へ反映されるようにする。

**Background**: オンライン時は即時反映に改善したが、オフライン変更は Hive のみで止まり、復帰後の Firestore 反映と通知送信が実装されていなかった。

**Problem / Root Cause**:

`HybridSharedGroupRepository` の同期キューに `update` 処理が未実装で、オフライン更新が replay されていなかった。

```dart
// ❌ Before
switch (operation.type) {
  case 'create':
    ...
    break;
  // TODO: update, delete操作も実装
}
```

**Solution**:

`update` 操作を同期キューへ積み、グループ名変更時は rename metadata も保持して、オンライン復帰時に Firestore 更新と通知送信をまとめて実行するようにした。さらに、ローカル UI ではテキストボックスと表示名を即時更新するようにした。

```dart
// ✅ After: update を同期キューに追加
_syncQueue.add(
  _SyncOperation(
    type: 'update',
    groupId: groupId,
    data: {
      'group': group,
      'renameNotification': {
        'oldName': previousGroup.groupName,
        'newName': group.groupName,
        'renamerName': renamerName,
      },
    },
    timestamp: DateTime.now(),
  ),
);

// ✅ After: 復帰後に Firestore 更新 + rename 通知送信
case 'update':
  final group = operation.data['group'] as SharedGroup;
  await _firestoreRepo!.updateGroup(operation.groupId, group);
```

**検証結果**:

| テスト                                                    | 結果     |
| --------------------------------------------------------- | -------- |
| オフラインでグループ名変更 → オンライン復帰後に他端末反映 | PASS     |
| オフラインで変更した名前が Firestore に最終反映           | PASS     |
| テキストボックスのローカル即時反映                        | PASS     |
| AppBar タイトルのオフライン即時反映                       | 部分改善 |

**補足**:

- グループ名入力欄はオフライン中でも即時反映されるようになった
- グループ詳細画面の AppBar タイトルはオンライン復帰後に追従するケースがあり、低優先の表示遅延として残った

**Modified Files**:

- `lib/datastore/hybrid_shared_group_repository.dart` - `update` 同期キューと rename 通知 replay を実装
- `lib/pages/group_member_management_page.dart` - ローカル表示名と `TextEditingController` を状態管理化

**Status**: ✅ 完了・実機確認済み

---

### 4. 再インストール後の Firestore 未復元レースを調査し、初手の対策を実装 ✅

**Purpose**: 再インストール後にサインインしても既存グループが即時復元されず、新規グループ作成を契機に旧グループが現れる問題の根本に着手する。

**Background**: 実機テストで、同一ユーザーでも別ユーザーでも、再インストール直後のサインイン時に `0件` 扱いされることが確認された。

**Problem / Root Cause**:

調査の結果、原因は 2 系統あった。

1. `HybridSharedGroupRepository` が起動直後に未認証だと `_firestoreRepo == null` のまま初期化完了扱いになり、その後サインインしても Firestore 再初期化が保証されない。
2. `AppInitializeWidget` / `HomePage` が、通知ゼロかつ空 Hive の状態で早すぎる `0 groups` 判定をしていた。

```dart
// ❌ Before: 認証なしで初期化完了扱いになり、その後の再回復が弱い
if (currentUser == null) {
  _firestoreRepo = null;
  _isInitialized = true;
  return;
}

// ❌ Before: 通知がなければ同期スキップ
if (hasGroupNotifications) {
  ref.invalidate(forceSyncProvider);
  await ref.read(forceSyncProvider.future);
}
```

**Solution**:

認証済みユーザー向けの Firestore 再初期化ヘルパーを追加し、`waitForSafeInitialization()`, `forceSyncFromFirestore()`, `syncFromFirestore()` の共通前段で回復を試みるようにした。さらに、認証済みかつローカル空の cold start では通知がなくても Firestore 復元を実行し、サインイン直後の `0件` 判定時にも 1 回再同期してから最終判断するようにした。

```dart
// ✅ After: 認証済みなら Firestore 再初期化を保証
Future<void> _ensureFirestoreReadyForAuthenticatedUser() async {
  if (!_shouldRecoverFirestoreForAuthenticatedUser()) {
    return;
  }
  await _safeAsyncFirestoreInitialization();
}

// ✅ After: 通知ゼロでも empty local なら復元する
final needsColdStartRestore = groupBox.isEmpty;
if (hasGroupNotifications || needsColdStartRestore) {
  ref.invalidate(forceSyncProvider);
  await ref.read(forceSyncProvider.future);
  await ref.read(allGroupsProvider.notifier).cleanupInvalidHiveGroups();
  await ref.read(allGroupsProvider.notifier).refresh();
}

// ✅ After: サインイン後に 0 件なら再同期してから最終判定
if (allGroups.isEmpty) {
  ref.invalidate(forceSyncProvider);
  await ref.read(forceSyncProvider.future);
  await ref.read(allGroupsProvider.notifier).refresh();
  allGroups = await ref.read(allGroupsProvider.future);
}
```

**検証結果**:

| 確認項目                              | 結果 |
| ------------------------------------- | ---- |
| 変更 3 ファイルの静的エラー確認       | PASS |
| 認証済み Firestore 再初期化経路の実装 | PASS |
| cold start 復元トリガー追加           | PASS |
| 実機での再インストール復元再テスト    | PASS |

**Modified Files**:

- `lib/datastore/hybrid_shared_group_repository.dart` - 認証済み Firestore 再初期化ヘルパーを追加
- `lib/widgets/app_initialize_widget.dart` - 通知ゼロでも空ローカル時は Firestore 復元を実行する分岐を追加
- `lib/pages/home_page.dart` - サインイン後の `0件` 判定前に再同期確認を追加

**Status**: ✅ 実装完了・実機再検証済み

---

## 🐛 発見された問題

### 再インストール後に Firestore グループが即時復元されない ✅

- **症状**: 再インストール後サインインしても既存グループが出ず、新規グループ作成を契機に旧グループが現れる
- **原因**: 認証復帰後の Firestore repo 回復不足と、空 Hive を早期に `0件` と判定するレース
- **対処**: Firestore 再初期化ヘルパーと empty local 復元トリガーを追加
- **状態**: 実機確認で解消を確認

### オフライン時アイテム追加ダイアログが閉じず UI がリトライに巻き込まれる ⚠️

- **症状**: オフライン中にアイテム追加ダイアログを開くと閉じず、リトライ待ちのような挙動になる
- **原因**: UI 層が Firestore 側の結果待ちに引っ張られ、Hive 側だけで完了扱いになっていない可能性が高い
- **対処**: 未着手。UI を早めに閉じ、再送はリポジトリ層へ委譲する方針が有力
- **状態**: 未修正

### グループ詳細 AppBar タイトルのオフライン反映が遅い ⚠️

- **症状**: オフラインでグループ名変更すると入力欄は即時更新されるが、AppBar タイトルはオンライン復帰後に追従するケースがある
- **原因**: 画面の表示状態と provider 反映の同期タイミング差
- **対処**: 入力欄の即時反映までは対応済み
- **状態**: 低優先で保留

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ グループ名変更が他端末へ即時反映されない問題を修正（完了日: 2026-03-11）
2. ✅ オフライン時のグループ名変更がオンライン復帰後に反映されない問題を修正（完了日: 2026-03-11）
3. ✅ 実機テストチェックリストを整理し、未解決項目を明文化（完了日: 2026-03-11）
4. ✅ 再インストール後の Firestore グループ未復元レースを修正し、実機で復元成功を確認（完了日: 2026-03-11）

### 未着手 ⏳

1. ⏳ オフライン時アイテム追加ダイアログのハング改善（Priority: High）
2. ⏳ グループ詳細 AppBar タイトルのオフライン即時反映（Priority: Low）

### 翌日継続 ⏳

- ⏳ オフライン時アイテム追加ダイアログの UI 切り離し方針を決める

---

## 💡 技術的学習事項

### 「認証復帰後の Firestore 再初期化」は `_isInitialized` だけでは判断できない

**問題パターン**:

```dart
// ❌ 認証なしで初期化完了扱いにした後、以後の待機処理が即 return する
if (currentUser == null) {
  _firestoreRepo = null;
  _isInitialized = true;
  return;
}

Future<void> waitForSafeInitialization() async {
  if (_isInitialized) {
    return;
  }
}
```

**正しいパターン**:

```dart
// ✅ 認証済みかつ _firestoreRepo == null なら回復処理を必ず通す
Future<void> waitForSafeInitialization() async {
  if (_isInitialized) {
    await _ensureFirestoreReadyForAuthenticatedUser();
    return;
  }
}
```

**教訓**: ハイブリッド初期化では「初期化完了」と「認証後に Firestore を使える状態」は別物。`_isInitialized` だけで early return すると、起動時の認証未復元を引きずる。

---

### 空 Hive を見た直後に `0件` と断定してはいけない

**問題パターン**:

```dart
// ❌ Firestore 復元前の空 Hive を最終結果として扱う
final allGroups = await ref.read(allGroupsProvider.future);
if (allGroups.isEmpty) {
  // 初期セットアップへ遷移
}
```

**正しいパターン**:

```dart
// ✅ 認証済みかつ空ローカルなら一度 Firestore 復元を通してから判定
if (allGroups.isEmpty) {
  ref.invalidate(forceSyncProvider);
  await ref.read(forceSyncProvider.future);
  await ref.read(allGroupsProvider.notifier).refresh();
  allGroups = await ref.read(allGroupsProvider.future);
}
```

**教訓**: 再インストール直後の空ローカル状態は「本当に 0 件」ではなく「まだ source of truth に到達していない」可能性が高い。判定前に復元シーケンスを必ず挟むべき。

---

## 🗓 翌日（2026-03-12）の予定

1. オフライン時アイテム追加ダイアログを UI 側で早期終了できるよう設計する
2. 必要ならグループ詳細 AppBar タイトルのオフライン即時更新を追加する
