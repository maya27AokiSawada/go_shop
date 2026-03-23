# QR招待・通知指示書

> 共通ルールは `00_project_common.md` を先に読むこと。

---

## 1. QR 招待 v3.1 形式

### QR コードに埋め込むデータは最小限（5フィールド）

```json
{
  "invitationId": "abc123",
  "sharedGroupId": "group_xyz",
  "securityKey": "secure_key",
  "type": "secure_qr_invitation",
  "version": "3.1"
}
```

- フル招待データは `invitationId` で Firestore から取得する
- `securityKey` で Firestore のデータを検証する（改ざん防止）
- v3.0（フル埋込み）との後方互換を維持する

### Firestore `/invitations/{invitationId}` のスキーマ

```text
maxUses: 5         // 最大招待回数
currentUses: 0     // 利用済み回数
usedBy: []         // 受諾済み UID
status: 'pending'  // pending | accepted | expired
expiresAt: ...     // 作成から 24 時間
```

### 使用回数の更新はアトミックに

```dart
await _firestore.collection('invitations').doc(invitationId).update({
  'currentUses': FieldValue.increment(1),
  'usedBy': FieldValue.arrayUnion([acceptorUid]),
  'lastUsedAt': FieldValue.serverTimestamp(),
});
```

### 既に参加済みの場合はダイアログを出さずスキャン画面を閉じる

---

## 2. 通知

### 通知リスナーに必要な Firestore インデックス

`userId(ASC)` + `read(ASC)` + `timestamp(DESC)` の複合インデックスが必要。
`firestore.indexes.json` にデプロイ済みであることを確認すること。

### 通知受信時の処理

| 通知タイプ                    | 処理                                                 |
| ----------------------------- | ---------------------------------------------------- |
| `groupMemberAdded`            | Firestore→Hive 同期 + `allGroupsProvider` invalidate |
| `invitationAccepted`          | 同上                                                 |
| `groupUpdated`                | 同上                                                 |
| `groupDeleted`                | Hive からグループ削除 + 選択グループをクリア         |
| `listCreated` / `listDeleted` | リスト Provider invalidate                           |

**`groupMemberAdded` のハンドラーを忘れると 3人目以降のメンバーが他端末に反映されない。**

### 招待受諾側と招待元側の役割分担

```text
受諾側（acceptor）:
  → sendNotification() で招待元に通知を送る
  → _updateInvitationUsage() は呼ばない（まだメンバーでないので permission-denied）

招待元（owner）:
  → 通知受信後に allowedUid / members を更新
  → _updateInvitationUsage() を呼ぶ（グループオーナーの権限で実行）
  → 既存メンバー全員に groupMemberAdded 通知を送信
```

### Firestore クエリに `Future.any()` タイムアウトを使う

```dart
// ✅ Dart レベルで確実にタイムアウト保証
final snapshot = await Future.any([
  _firestore.collection('notifications')
      .where('userId', isEqualTo: uid)
      .get(),
  Future<QuerySnapshot<Map<String, dynamic>>>.delayed(
    const Duration(seconds: 5),
    () => throw TimeoutException('5秒でタイムアウト'),
  ),
]);
```

---

## 3. 通知履歴

- StreamBuilder で Firestore から 100件以内をリアルタイム表示
- タップで既読マーク（`read: true`）
- 一括削除は**既読のみ**
- 時間差表示（「たった今」「3分前」「2日前」）

---

## 4. 禁止事項

- v3.0 以前の旧招待システムファイルの参照・復元
  - 削除済み: `invitation_repository.dart`、`invitation_provider.dart`、`invitation_management_dialog.dart`
- 受諾側から `_updateInvitationUsage()` を呼ぶ（permission-denied になる）
- `groupMemberAdded` 通知ハンドラーの省略
