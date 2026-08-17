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

### v3.1 読み取りレース対策（必須）

QR生成直後は、`SharedGroups/{groupId}/invitations/{invitationId}` が
別端末から即時に見えないことがある（Firestore の反映タイミング差）。

このため、受諾側の詳細取得は「1回で `exists == false` なら即失敗」ではなく、
短時間リトライを行うこと。

- 推奨: 最大 8 回、250ms からの段階的バックオフ
- `unavailable` / `deadline-exceeded` / `aborted` / `internal` / 読み取りタイムアウトは再試行対象
- 最終試行後も未取得の場合のみ「無効なQRコード」扱いにする

```dart
for (var attempt = 1; attempt <= 8; attempt++) {
  final doc = await invitationRef.get().timeout(const Duration(seconds: 4));
  if (doc.exists) return doc.data();
  await Future.delayed(_backoff(attempt));
}
return null;
```

### 旧招待データへの後方互換

旧形式の招待データでは `inviterUid` が欠落していることがあるため、
受諾処理では以下の優先順位で招待元 UID を解決すること。

1. `inviterUid`
2. `invitedBy`
3. `groupOwnerUid`
4. `SharedGroups/{groupId}.ownerUid` へのフォールバック

`inviterUid` が空のままでは受諾処理が失敗するため、
古い招待データでも安全に扱えるようにすること。

### Firestore `/invitations/{invitationId}` のスキーマ

```text
maxUses: 5         // 最大招待回数
currentUses: 0     // 利用済み回数
usedBy: []         // 受諾済み UID
status: 'pending'  // pending | accepted | expired
expiresAt: ...     // 作成から 24 時間
```

### 鍵交換イベント（`keyExchangeEvents`）の権限要件

受諾側が復号するには、次のドキュメント読み取りが必須。

- `SharedGroups/{groupId}/keyExchangeEvents/{memberUid}`

Firestore Security Rules で最低限以下を許可すること。

- `read`: グループオーナー、または `memberUid` 本人
- `create`: グループオーナー
- `update`: グループオーナー、または `memberUid` 本人（`status=confirmed` 更新）
- `delete`: グループオーナー

このルールが無い場合、受諾端末で `permission-denied` が発生し、
`resolveGroupKeyForMember()` が失敗して復号不能になる。

### 鍵交換の責務分離とオーナー限定（必須）

鍵の生成・配布・ローテーションは、グループオーナーのみが発火する。
参加者は既存鍵の取得と復号だけを行い、書き込み（鍵生成・配布・更新）は行わない。

- オーナー発火: `handleAcceptedInvitation()` / `ensureGroupKeyForOwner()` / `rotateGroupKey()`
- 参加者発火: `resolveGroupKeyForMember()` / `hasUsableGroupKey()` / `waitForUsableGroupKey()`
- 共有権限フィールド: `allowedUid` を正とする。`allowedUids` は旧名・レガシー名として扱い、新規保存は禁止
- `keyExchangeEvents/{memberUid}` の作成・更新は基本的にオーナーが行う
- メンバー側の責務は「暗号化された鍵を読む」「ローカルへ保存する」「復号する」だけに限定する

#### 正しいフロー

```text
1. 受諾者が招待承認
2. オーナーが SharedGroup / SharedList の allowedUid を更新
3. オーナーが keyExchangeEvents/{memberUid} を作成
4. オーナーが新しいグループ鍵を生成し、各メンバーへ配布
5. 受諾者が resolveGroupKeyForMember() で復号し、ローカル保存
```

#### 禁止事項

- 参加者端末側から `ensureGroupKeyForOwner()` / `rotateGroupKey()` を直接呼ばない
- `allowedUids` を新規に追加・更新しない
- `keyExchangeEvents` の作成をメンバー側で代行しない
- `activeKeyVersion` の更新をメンバー側で行わない

#### 実装上の注意

- オーナー判定は `currentUser.uid == group.ownerUid` で厳密に確認する
- 既存鍵がある場合でも、再配布時には `forceRefresh` / `rotateGroupKey` の経路を明示してオーナーの管理フローに戻す
- Firestore Rules とアプリ実装の両方で `allowedUid` を標準に揃える

### 使用回数の更新はアトミックに

```dart
await _firestore.collection('invitations').doc(invitationId).update({
  'currentUses': FieldValue.increment(1),
  'usedBy': FieldValue.arrayUnion([acceptorUid]),
  'lastUsedAt': FieldValue.serverTimestamp(),
});
```

### 既に参加済みの場合はダイアログを出さずスキャン画面を閉じる

- `accept_invitation_widget.dart` の「すでにグループメンバー」分岐を含む**すべての分岐**（正常・スキップ・エラー）で必ず `_controller.stop()` を呼んでから `Navigator.pop()` すること
- `stop()` なしで `pop()` するとカメラプレビューが残留しブラックアウトになる

```dart
// ✅ 正しいパターン（全分岐共通）
final navigator = Navigator.of(context);
final messenger = ScaffoldMessenger.maybeOf(context);
try { await _controller.stop(); } catch (e) { Log.warning(...); }
navigator.pop();
messenger?.showSnackBar(...);
```

---

## 2. 通知

### 通知リスナーに必要な Firestore インデックス

`userId(ASC)` + `read(ASC)` + `timestamp(DESC)` の複合インデックスが必要。
`firestore.indexes.json` にデプロイ済みであることを確認すること。

### 通知作成時のセキュリティ要件

通知の作成時は、次の条件を Firestore Security Rules でも守ること。

- `request.auth != null` であること
- `senderId` が `request.auth.uid` と一致すること
- `targetUserId` が空文字でないこと
- `type` が許可済みリストに含まれること
- `groupId` が空文字でないこと
- `read` は `false` であること
- `senderName` が文字列であること

特に `group_member_added` は、招待ドキュメントとの整合性を確認し、
`invitationId` / `acceptorUid` / `currentUses < maxUses` なども検証すること。

### 通知受信時の処理

| 通知タイプ                    | 処理                                                                                     |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| `groupMemberAdded`            | Firestore→Hive 同期 + `allGroupsProvider` invalidate                                     |
| `invitationAccepted`          | 同上                                                                                     |
| `groupUpdated`                | 同上                                                                                     |
| `syncConfirmation`            | `groupId` で Firestore から直接グループ取得 → Hive 保存 + `allGroupsProvider` invalidate |
| `groupDeleted`                | Hive からグループ削除 + 選択グループをクリア                                             |
| `listCreated` / `listDeleted` | リスト Provider invalidate                                                               |

**`groupMemberAdded` のハンドラーを忘れると 3人目以降のメンバーが他端末に反映されない。**

### syncConfirmation ハンドラーの注意点

`syncConfirmation` 受信時は **`syncFromFirestoreToHive()` のみに依存してはいけない**。
このメソッドは Dev 環境で早期リターンする実装になっており、Dev では Hive 同期が実行されない。

```dart
// ❌ NG — Dev環境ではスキップされる
await userInitService.syncFromFirestoreToHive(currentUser);

// ✅ 正しい — groupId で直接 Firestore から取得して Hive に保存する
final syncGroupId = notification.groupId;
if (syncGroupId.isNotEmpty) {
  final repository = _ref.read(SharedGroupRepositoryProvider);
  final group = await repository.getGroupById(syncGroupId);
  final hiveRepository = _ref.read(hiveSharedGroupRepositoryProvider);
  await hiveRepository.saveGroup(group);
}
// 念のため既存パスも実行（prod向け二重保険）
await userInitService.syncFromFirestoreToHive(currentUser);
_ref.invalidate(allGroupsProvider);
```

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

### `acceptQRInvitation` の例外ハンドリング

`acceptQRInvitation` は内部例外を **rethrow** する設計になっている。
呼び出し元は必ず `ErrorHandler.handleAsync` でラップすること（現行 2 箇所ともラップ済み）。

```dart
// ✅ acceptQRInvitation の catch ブロック（サービス層）
} catch (e, stackTrace) {
  Log.error('QR招待受諾エラー: $e');
  await ErrorLogService.logOperationError('QR招待受諾', '$e', stackTrace);
  rethrow;  // 呼び出し元の ErrorHandler に伝播させて SnackBar に表示
}
```

- `return false` にすると呼び出し元がエラー原因を知れず、デバッグが困難になる ❌
- 呼び出し元が `ErrorHandler.handleAsync` を使っていれば `rethrow` は安全 ✅

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
