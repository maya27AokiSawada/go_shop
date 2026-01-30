# 3番目メンバー招待同期バグ修正

**修正日**: 2026-01-30
**対象ブランチ**: future
**重要度**: 🔥 **CRITICAL**

---

## バグ概要

### 症状

- すもも（招待元）がまや（3番目メンバー）を招待
- しんや（既存メンバー）の端末で新メンバーが表示されない
- Firebase Consoleでは`allowedUid`と`members`が正しく更新されている
- しんやの端末で共有リストが消える

### 再現条件

1. グループに2人のメンバーがいる状態（すもも＋しんや）
2. すももが3人目のメンバー（まや）をQR招待
3. まやが招待を受諾
4. すももの端末ではまやが表示される
5. ❌ しんやの端末ではまやが表示されない

---

## 根本原因

### 問題1: `groupMemberAdded` 通知が処理されていない

`lib/services/notification_service.dart` の `_handleNotification` メソッドで、`groupMemberAdded` の case が欠落していた。

**Before**:

```dart
case NotificationType.invitationAccepted:
case NotificationType.groupUpdated:
  // Firestore→Hive同期
  await userInitService.syncFromFirestoreToHive(currentUser);
  _ref.invalidate(allGroupsProvider);
  break;

// ❌ groupMemberAdded のケースがない
```

**After**:

```dart
case NotificationType.invitationAccepted:
case NotificationType.groupUpdated:
case NotificationType.groupMemberAdded:  // 🔥 追加
  // Firestore→Hive同期
  await userInitService.syncFromFirestoreToHive(currentUser);
  _ref.invalidate(allGroupsProvider);
  break;
```

### 問題2: 既存メンバーへの通知送信が欠落

`_addGroupMember` メソッドで、新メンバー追加後に既存メンバー全員に通知を送信していなかった。

**Before**:

```dart
// Firestoreに更新
await FirebaseFirestore.instance
    .collection('SharedGroups')
    .doc(groupId)
    .update({...});

// Hiveにも更新
await repository.updateGroup(groupId, updatedGroup);

// ❌ 既存メンバーへの通知送信なし
```

**After**:

```dart
// Firestoreに更新
await FirebaseFirestore.instance
    .collection('SharedGroups')
    .doc(groupId)
    .update({...});

// Hiveにも更新
await repository.updateGroup(groupId, updatedGroup);

// 🔥 既存メンバー全員に通知を送信
final existingMemberIds = currentGroup.allowedUid
    .where((uid) => uid != acceptorUid) // 新メンバーを除外
    .toList();

for (final memberId in existingMemberIds) {
  await sendNotification(
    targetUserId: memberId,
    groupId: groupId,
    type: NotificationType.groupMemberAdded,
    message: '$finalAcceptorName さんが「$groupName」に参加しました',
    metadata: {...},
  );
}
```

---

## 修正内容

### 1. `groupMemberAdded` 通知ハンドラー追加

**ファイル**: `lib/services/notification_service.dart`
**行数**: Lines 280-295

```dart
case NotificationType.invitationAccepted:
case NotificationType.groupUpdated:
case NotificationType.groupMemberAdded:  // 🔥 新規追加：3番目メンバー招待対応
  // Firestore→Hive同期
  AppLogger.info('🔄 [NOTIFICATION] Firestore→Hive同期開始');
  final userInitService = _ref.read(userInitializationServiceProvider);
  await userInitService.syncFromFirestoreToHive(currentUser);

  // UI更新（全グループと選択中グループの両方を更新）
  _ref.invalidate(allGroupsProvider);
  _ref.invalidate(selectedGroupProvider);
  AppLogger.info('✅ [NOTIFICATION] 同期完了 - UI更新');
  break;
```

### 2. 既存メンバーへの通知送信追加

**ファイル**: `lib/services/notification_service.dart`
**行数**: Lines 490-520（`_addGroupMember` メソッド末尾）

```dart
// 🔥 CRITICAL FIX: 既存メンバー全員に通知を送信
AppLogger.info('📤 [OWNER] 既存メンバーへの通知送信開始');
final existingMemberIds = currentGroup.allowedUid
    .where((uid) => uid != acceptorUid) // 新メンバーを除外
    .toList();

for (final memberId in existingMemberIds) {
  try {
    await sendNotification(
      targetUserId: memberId,
      groupId: groupId,
      type: NotificationType.groupMemberAdded,
      message: '$finalAcceptorName さんが「$groupName」に参加しました',
      metadata: {
        'groupName': groupName,
        'newMemberUid': acceptorUid,
        'newMemberName': finalAcceptorName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    AppLogger.info(
        '✅ [OWNER] 既存メンバーに通知送信: ${AppLogger.maskUserId(memberId)}');
  } catch (e) {
    AppLogger.error(
        '❌ [OWNER] メンバー通知送信エラー (${AppLogger.maskUserId(memberId)}): $e');
  }
}

AppLogger.info('✅ [OWNER] 全既存メンバーへの通知送信完了');
```

---

## 期待される動作フロー（修正後）

### ケース: すもも→まや招待（既存メンバー：しんや）

1. **まや**（受諾者） → QRコード受諾
   - `groupMemberAdded` 通知を **すもも** に送信

2. **すもも**（招待元） → 通知受信
   - `_handleNotification` で `groupMemberAdded` を処理
   - `syncFromFirestoreToHive` 実行
   - `_addGroupMember` 実行
     - ✅ Firestoreの `allowedUid` に `まやUID` 追加
     - ✅ Firestoreの `members` に `まやメンバー情報` 追加
     - ✅ Hive更新
     - 🔥 **既存メンバー（しんや）に `groupMemberAdded` 通知送信**

3. **しんや**（既存メンバー） → 🔥 **通知受信**
   - `_handleNotification` で `groupMemberAdded` を処理
   - `syncFromFirestoreToHive` 実行
   - Firestoreから最新グループ情報を取得（まや含む）
   - Hiveに同期
   - `allGroupsProvider` 無効化 → UI更新
   - ✅ **まやがメンバーリストに表示される**

4. **まや**（受諾者） → `invitationAccepted` 通知を受信
   - `syncFromFirestoreToHive` 実行
   - ✅ グループメンバーとして表示される

---

## テスト手順

### 準備

1. すもも、しんやの2人でグループを作成
2. 各デバイスでグループメンバーが2人表示されることを確認

### 実行

1. すもも端末で新規QRコードを生成
2. まや端末でQRコードをスキャン
3. すもも端末で招待承認

### 期待結果

- ✅ すもも端末：まやがメンバーリストに表示される
- ✅ しんや端末：まやがメンバーリストに表示される（修正前は❌）
- ✅ まや端末：グループメンバーとして表示される
- ✅ 全員の端末で共有リストが正常に表示される

---

## 関連ファイル

- `lib/services/notification_service.dart` - 通知処理メインファイル
- `lib/services/qr_invitation_service.dart` - QR招待処理
- `lib/services/user_initialization_service.dart` - Firestore→Hive同期
- `lib/providers/purchase_group_provider.dart` - グループプロバイダー

---

## リスク評価

### 影響範囲

- **既存機能への影響**: なし（通知ハンドラーの追加のみ）
- **パフォーマンス**: 既存メンバー数に応じた通知送信回数増加
  - 例：10人のグループに1人追加 → 9通の通知送信
  - Firebase Cloud Messaging無料枠内で十分対応可能

### 想定される副作用

- ❌ なし（既存の通知システムを拡張するのみ）

---

## 次のステップ

1. ✅ コード修正完了
2. ⏳ コミット＆プッシュ
3. ⏳ Android実機でテスト
4. ⏳ 3人以上のグループで動作確認
5. ⏳ 通知ログで同期タイミング確認

---

**修正者**: GitHub Copilot (AI Agent)
**レビュー待ち**: maya27aokisawada
