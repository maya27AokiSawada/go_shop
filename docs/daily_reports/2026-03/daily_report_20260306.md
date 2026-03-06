# 開発日報 - 2026年03月06日（午前）

## 📅 本日の目標

- [x] 最終実機テスト セクション3-4 テスト結果分析・バグ修正（6件）
- [x] 改修確認テスト用チェックリスト作成
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

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ P0: FAB RenderFlexオーバーフロー（完了日: 2026-03-06）
2. ✅ P1: コピー付き作成メンバー未コピー（完了日: 2026-03-06）
3. ✅ P1: コピー付き作成自分に通知なし（完了日: 2026-03-06）
4. ✅ P1: メンバーグループ退出機能不動作（完了日: 2026-03-06）
5. ✅ P2: 再インストール後ネットワーク障害誤判定（完了日: 2026-03-06）
6. ✅ P2: 招待残り回数非表示（完了日: 2026-03-06）

### 対応不要 ℹ️

7. ℹ️ Info: 二重送信防止が速すぎて目視確認困難（実質合格）

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

---

## 🗓 午後の予定

1. 改修確認テスト実施（37項目）
2. セクション5-12のテスト実施
3. 検出された追加バグの修正
