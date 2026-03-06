# 開発日報 - 2026年03月06日

## 📅 本日の目標

- [x] 最終実機テスト セクション3-4 テスト結果分析・バグ修正（6件）
- [x] 改修確認テスト用チェックリスト作成
- [x] 改修確認テスト Fix 1〜5 実機テスト実施
- [x] Fix 8: 再インストール時グループ同期遅延の根本修正
- [x] Hive Schema Version 3 最低バージョン設定
- [ ] 最終実機テスト セクション5-12 実施

---

## ✅ 完了した作業

### 1. セクション3-4 テスト結果分析・7件の問題検出 ✅

**Purpose**: 最終実機総合テスト チェックリストのセクション3（グループ管理 22項目）とセクション4（買い物リスト 18項目）のテスト結果を分析

**Background**: ユーザーがSH-54D実機でセクション3-4のテストを実施し、結果をチェックリストに記録

**検出された問題**:

| #   | 優先度 | 問題                                                   | セクション |
| --- | ------ | ------------------------------------------------------ | ---------- |
| 1   | P0     | FAB RenderFlexオーバーフロー                           | 3.1        |
| 2   | P1     | コピー付き作成でメンバーがコピーされない               | 3.3        |
| 3   | P1     | コピー付き作成で自分に通知が来ない                     | 3.3        |
| 4   | P1     | メンバーのグループ退出機能が動作しない                 | 3.4        |
| 5   | P2     | 再インストール後に認証切れでネットワーク障害バナー表示 | 3.1        |
| 6   | P2     | 招待残り回数がデバイスUIに非表示                       | 4.3        |
| 7   | Info   | 二重送信防止が速すぎて目視確認困難                     | 4.2        |

**Status**: ✅ 分析完了

---

### 2. P0: FAB RenderFlexオーバーフロー修正 ✅

**Purpose**: グループタブのFABボタン展開時にRenderFlexオーバーフローが発生する問題を修正

**Root Cause**: `Column` の `mainAxisSize` がデフォルト（`MainAxisSize.max`）のため、利用可能な全縦スペースを占有

**Solution**:

```dart
// ❌ Before: Columnが全縦スペースを占有
Column(
  children: [
    FloatingActionButton(...),  // QRスキャン
    FloatingActionButton(...),  // グループ作成
  ],
)

// ✅ After: 子要素のサイズに縮小
Column(
  mainAxisSize: MainAxisSize.min,  // 追加
  children: [
    FloatingActionButton(...),
    FloatingActionButton(...),
  ],
)
```

**Modified Files**:

- `lib/pages/shared_group_page.dart` — `mainAxisSize: MainAxisSize.min` 追加

**Status**: ✅ 完了

---

### 3. P1 #1: コピー付き作成でメンバーがコピーされない修正 ✅

**Purpose**: 既存グループからコピー付き作成時にメンバーが新グループにコピーされない問題を修正

**Root Cause**: `_createGroup()` と `_addMembersToNewGroup()` のasyncメソッド内で `ref.watch()` を使用。`ref.watch()` はbuildコンテキスト外（async処理内）では使用できない。

**Solution**:

```dart
// ❌ Before: asyncメソッド内でref.watch()
Future<void> _createGroup() async {
  final repository = ref.watch(SharedGroupRepositoryProvider);
  // ...
}

// ✅ After: asyncメソッド内ではref.read()
Future<void> _createGroup() async {
  final repository = ref.read(SharedGroupRepositoryProvider);
  // ...
}
```

**Modified Files**:

- `lib/widgets/group_creation_with_copy_dialog.dart` — `ref.watch()` → `ref.read()` を2箇所で変更

**Status**: ✅ 完了

---

### 4. P1 #2: コピー付き作成で自分に通知が来ない修正 ✅

**Purpose**: コピー付きグループ作成時に作成者自身への通知が送信されない問題を修正

**Root Cause**: `_updateMemberSelection()` が現在のユーザーを `_selectedMembers` から除外する設計。通知送信の `_sendMemberNotifications()` は `_selectedMembers` のみに送信するため、自分自身には通知が届かない。

**Solution**:

```dart
// ✅ _sendMemberNotifications() の後に自分への通知を追加
await _sendMemberNotifications(groupId, groupName, context, ref);

// 🔥 自分自身にも通知を送信（他デバイス同期用）
final currentUser = ref.read(authStateProvider).value;
if (currentUser != null) {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.sendGroupCreatedNotification(
    groupId: groupId,
    groupName: groupName,
    creatorName: currentUser.displayName ?? 'ユーザー',
  );
}
```

**Modified Files**:

- `lib/widgets/group_creation_with_copy_dialog.dart` — 自分自身への通知送信ブロック追加

**Status**: ✅ 完了

---

### 5. P1 #3: メンバーのグループ退出機能が動作しない修正 ✅

**Purpose**: メンバーがグループから退出しようとすると「オーナーでないため削除できません」と表示される問題を修正

**Root Cause**: `_showGroupOptions()` にオーナーでない場合の早期returnがあり、退出ダイアログ表示前に処理が終了

**Solution**:

```dart
// ❌ Before: 非オーナーの場合早期returnで退出ダイアログに到達しない
static void _showGroupOptions(BuildContext context, WidgetRef ref, SharedGroup group) {
  final isOwner = ...;
  if (!isOwner) {
    ScaffoldMessenger.of(context).showSnackBar(...);
    return;  // ← ここで処理終了
  }
  _showDeleteConfirmationDialog(...);
}

// ✅ After: 早期returnを削除、オーナー/メンバーの判定はダイアログ内で実施
static void _showGroupOptions(BuildContext context, WidgetRef ref, SharedGroup group) {
  _showDeleteConfirmationDialog(context, ref, group);
  // _showDeleteConfirmationDialog内でオーナー判定して
  // オーナー → 削除ダイアログ、メンバー → 退出ダイアログ を表示
}
```

**Modified Files**:

- `lib/widgets/group_list_widget.dart` — 早期return削除、未使用変数削除

**Status**: ✅ 完了

---

### 6. P2 #1: 再インストール後に認証切れでネットワーク障害バナー表示修正 ✅

**Purpose**: アプリ再インストール後、認証トークン切れにより `permission-denied` エラーが発生し、ネットワーク障害として誤判定される問題を修正

**Root Cause**: `checkFirestoreConnection()` の `FirebaseException` ハンドラーが `permission-denied` と実際のネットワークエラーを区別していない

**Solution**:

```dart
// ✅ permission-denied/unauthenticated の場合は公開コレクションでフォールバック確認
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
    // 認証エラー → 公開コレクションで実際のネットワーク状態を確認
    try {
      await _firestore.collection('furestorenews').limit(1).get()
          .timeout(const Duration(seconds: 5));
      return NetworkStatus.online;  // ネットワークは正常、認証だけの問題
    } catch (_) {
      return NetworkStatus.offline;  // 本当にオフライン
    }
  }
  return NetworkStatus.offline;
}
```

**Modified Files**:

- `lib/services/network_monitor_service.dart` — `permission-denied` 判別 + 公開コレクションフォールバック追加

**Status**: ✅ 完了

---

### 7. P2 #2: 招待残り回数がデバイスUIに非表示修正 ✅

**Purpose**: QR招待画面（`GroupInvitationPage`）に招待可能人数が表示されていない問題を修正

**Root Cause**: `GroupInvitationPage` にmaxUses/remainingUses/currentUsesの表示UIが一切存在しない。なお `GroupInvitationDialog`（別画面）には既に表示あり。

**Solution**: QRコード下に「招待可能人数: 5人」の青色チップUIを追加

```dart
// ✅ QRコード表示部の下に追加
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.blue.shade200),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.people_outline, size: 16, color: Colors.blue.shade700),
      const SizedBox(width: 4),
      Text('招待可能人数: $_maxUses人',
        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
    ],
  ),
)
```

**Modified Files**:

- `lib/pages/group_invitation_page.dart` — `_maxUses` state変数追加 + 青色チップUI追加

**Status**: ✅ 完了

---

### 8. 改修確認テスト用チェックリスト作成 ✅

**Purpose**: 上記6件の修正を実機で検証するための専用チェックリスト作成

**内容**: 6件のFix × 各5〜9テスト項目 = 合計37テスト項目

**Modified Files**:

- `docs/daily_reports/2026-03/fix_verification_checklist_20260306.md` — 新規作成

**Status**: ✅ 完了

---

### 9. 改修確認テスト Fix 1〜5 実施 ✅

**Purpose**: 午前中に修正した6件のバグ修正について、実機で改修確認テストを実施

**テスト実施者**: ユーザー（SH-54D / Pixel 9）

**テスト結果**:

| Fix # | 優先度 | 内容                             | 結果   | 判定        |
| ----- | ------ | -------------------------------- | ------ | ----------- |
| 1     | P0     | FAB RenderFlexオーバーフロー     | 5/5    | ✅ 合格     |
| 2     | P1     | コピー付き作成メンバー未コピー   | 5/5    | ✅ 合格     |
| 3     | P1     | コピー付き作成自分に通知なし     | 5/5    | ✅ 合格     |
| 4     | P1     | メンバーグループ退出機能不動作   | 6/9    | ⚠️ 部分合格 |
| 5     | P2     | 再インストール後ネットワーク障害 | 5/8    | ⚠️ 部分合格 |
| 6     | P2     | 招待残り回数非表示               | 未実施 | ⏳          |

**Fix 4 で発見された問題 (※1)**:

- 退出した端末とFirestore上では退出済みとなっているが、他端末では通知が来ていないし、UIからも消えていない
- → 退出通知の他メンバーへの送信処理が未実装の可能性

**Fix 5 で発見された問題 (※2)**:

- 再インストール後にサインインしてもグループが同期されない
- アプリバーの同期アイコンには異常なし（緑色表示）
- グループを新規作成したら一緒に古いグループも現れた
- → **Fix 8 として調査・修正実施**（下記参照）

**Status**: ✅ 5件テスト完了、1件未実施

---

### 10. Fix 8: 再インストール時グループ同期遅延の根本修正 ✅

**Purpose**: 再インストール後にサインインしてもグループが同期されない問題を根本修正

**Background**: Fix 5のテスト中にユーザーが発見。再インストール → サインイン → グループリスト空 → グループ新規作成したら古いグループも同時に出現。

**Root Cause**:

アプリ起動時の初期化フローに問題:

```
アプリ起動（再インストール後）
  ↓
HybridSharedGroupRepository() コンストラクタ
  ↓
_safeAsyncFirestoreInitialization()
  → currentUser == null（Firebase Authセッション未復元）
  → _firestoreRepo = null
  → _isInitialized = true
  ↓
ユーザーがサインイン → currentUser 利用可能に
  ↓
forceSyncFromFirestore() 呼び出し
  → _firestoreRepo == null をチェック
  → 即座にreturn（同期スキップ）❌
  → waitForSafeInitialization() を呼んでいない！
```

Fix 7で `waitForSafeInitialization()` に認証復帰後の再初期化ロジックを追加済みだったが、`forceSyncFromFirestore()` と `syncFromFirestore()` がそれを呼んでいなかった。

**Solution**:

```dart
// ❌ Before: waitForSafeInitialization() を呼ばずに _firestoreRepo == null で即return
Future<void> forceSyncFromFirestore() async {
  if (_firestoreRepo == null) {
    AppLogger.info('🔧 Force sync skipped - Firestore not initialized');
    return;
  }
  // ...
}

// ✅ After: Fix 7の再初期化ロジックを発動させてから判定
Future<void> forceSyncFromFirestore() async {
  // 🔥 FIX 8: サインイン後にFirestore未初期化の場合、Fix 7の再初期化ロジックを発動
  await waitForSafeInitialization();

  if (_firestoreRepo == null) {
    AppLogger.info('🔧 Force sync skipped - Firestore not initialized');
    return;
  }
  // ...
}
```

**Modified Files**:

- `lib/datastore/hybrid_purchase_group_repository.dart`
  - `forceSyncFromFirestore()` — `await waitForSafeInitialization()` 追加
  - `syncFromFirestore()` — `await waitForSafeInitialization()` 追加

**Status**: ✅ 完了・Pixel 9でビルド実行済み

---

### 11. Hive Schema Version 3 最低バージョン設定 ✅

**Purpose**: v1/v2データがFirestore上に存在しないため、Schema Version 3を最低バージョンとして設定

**Background**: ユーザーの指示: 「現在、スキーマはVer.3で現在Ver.1と2のデータはFirestore上に存在しないのでVer.3を最低ヴァージョンとして下さい。当分Hiveスキーマのグレードアップは予定なし」

**Solution**:

```dart
// ❌ Before: Schema Version 2
static const int _currentSchemaVersion = 2;

// ✅ After: Schema Version 3（最低バージョン）
static const int _currentSchemaVersion =
    3; // Version 3: 最低バージョン（v1/v2データはFirestore上に存在しない）
```

**Effect**: 古いSchemaバージョンのデバイスはHiveキャッシュを自動クリア → Firestoreから再同期

**Modified Files**:

- `lib/services/user_specific_hive_service.dart` — `_currentSchemaVersion` を 2 → 3 に変更

**Status**: ✅ 完了

---

## 🐛 発見された問題

### 1. メンバー退出時の他端末通知・UI未反映（Fix 4 テスト中）

**発見日**: 2026-03-06（午後）
**優先度**: P1
**症状**: メンバーがグループ退出を実行した場合、退出した端末とFirestoreでは正常に処理されるが、他のメンバーの端末には通知が送られず、UIにも反映されない
**想定原因**: グループ退出時に他メンバーへの通知送信処理が未実装の可能性
**Status**: ⏳ 翌日以降で調査

### 2. ネットワーク障害バナー自動消去とタイマー間隔の検討（Fix 5 テスト中）

**発見日**: 2026-03-06（午後）
**優先度**: P2
**症状**: 機内モード解除後にバナーが自動で消えない（手動同期で消える）。タイマー10分は長い可能性
**ユーザーの疑問**: 「メッセージに手動で確認することもできると表示するか？それとも10分という再確認タイマーを短くするか？」
**Status**: ⏳ 検討中

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ P0: FAB RenderFlexオーバーフロー（完了日: 2026-03-06 AM）— テスト 5/5 ✅
2. ✅ P1: コピー付き作成メンバー未コピー（完了日: 2026-03-06 AM）— テスト 5/5 ✅
3. ✅ P1: コピー付き作成自分に通知なし（完了日: 2026-03-06 AM）— テスト 5/5 ✅
4. ✅ P1: メンバーグループ退出機能不動作（完了日: 2026-03-06 AM）— テスト 6/9 ⚠️ 部分合格
5. ✅ P2: 再インストール後ネットワーク障害誤判定（完了日: 2026-03-06 AM）— テスト 5/8 ⚠️ 部分合格
6. ✅ P2: 招待残り回数非表示（完了日: 2026-03-06 AM）— テスト未実施
7. ✅ 再インストール時グループ同期遅延（Fix 8）（完了日: 2026-03-06 PM）— テスト待ち
8. ✅ Hive Schema v3 最低バージョン設定（完了日: 2026-03-06 PM）

### 対応中 ⏳

9. ⏳ P1: メンバー退出時の他端末通知・UI未反映（Fix 4テスト中に発見）
10. ⏳ P2: ネットワーク障害バナー自動消去・タイマー間隔検討（Fix 5テスト中に発見）

### 対応不要 ℹ️

11. ℹ️ Info: 二重送信防止が速すぎて目視確認困難（実質合格）

---

## 💡 技術的学習事項

### 1. ref.watch() vs ref.read() の使い分け

```dart
// ❌ asyncメソッド内でref.watch() → ビルドコンテキスト外で使用不可
Future<void> _createGroup() async {
  final repo = ref.watch(someProvider);  // エラー or 無視される
}

// ✅ asyncメソッド内ではref.read()
Future<void> _createGroup() async {
  final repo = ref.read(someProvider);   // 正常動作
}
```

**教訓**: `ref.watch()` はbuild()内/ConsumerWidget.build()内のみ。asyncメソッド、コールバック、onPressed等では必ず `ref.read()` を使用する。

### 2. FirebaseException の種別判定

```dart
// ❌ FirebaseExceptionを一律ネットワークエラーとして処理
} on FirebaseException catch (e) {
  return NetworkStatus.offline;
}

// ✅ エラーコードで認証エラーとネットワークエラーを区別
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
    // 認証エラー → 公開コレクションで実ネットワーク確認
  }
  return NetworkStatus.offline;
}
```

**教訓**: `permission-denied` は認証の問題であり、ネットワークの問題とは限らない。公開コレクションへのアクセスで真のネットワーク状態を確認する。

### 3. Column mainAxisSize のデフォルト動作

```dart
// ❌ デフォルト: MainAxisSize.max → 親の全スペースを占有
Column(children: [...])

// ✅ Column内に浮動要素がある場合はminを指定
Column(mainAxisSize: MainAxisSize.min, children: [...])
```

**教訓**: FABなど画面上に浮く要素をColumnで配置する場合、`MainAxisSize.min` を指定しないとRenderFlexオーバーフローが発生する。

### 4. waitForSafeInitialization() の適用範囲

```dart
// ❌ 初期化済みかどうかだけ確認して即return → 認証復帰後の再初期化がスキップされる
Future<void> forceSyncFromFirestore() async {
  if (_firestoreRepo == null) {
    return;  // Fix 7の再初期化ロジックが発動しない
  }
}

// ✅ まずwaitForSafeInitialization()で再初期化を試行してから判定
Future<void> forceSyncFromFirestore() async {
  await waitForSafeInitialization();  // Fix 7: 認証復帰検出 → Firestore再初期化
  if (_firestoreRepo == null) {
    return;  // 再初期化も失敗した場合のみスキップ
  }
}
```

**教訓**: `_firestoreRepo == null` チェックの前には必ず `waitForSafeInitialization()` を呼ぶ。特にサインイン後のコードパスでは、Firebase Auth起動遅延による初回初期化失敗を補完するため必須。

### 5. Hive Schema Versionの最低バージョン戦略

```dart
// データマイグレーションが不要になったら → 最低バージョンとして設定
static const int _currentSchemaVersion = 3;
// v1/v2のマイグレーションコードは不要 → 古いデバイスはHiveクリア + Firestore再同期
```

**教訓**: Firestore上にv1/v2データが存在しなくなった時点で、スキーマの最低バージョンを引き上げることで、古いマイグレーションコードの負債を排除できる。

---

## 🗓 翌日（2026-03-07）の予定

1. Fix 8 実機テスト（再インストール → サインイン → グループ同期確認）
2. Fix 4 他端末通知問題の調査・修正（メンバー退出通知）
3. Fix 6 テスト実施（招待残り回数表示）
4. ネットワーク障害バナーのタイマー間隔検討
5. 最終実機テスト セクション5-12 実施
6. 午前修正分 + Fix 8 + Schema v3 のコミット・プッシュ
