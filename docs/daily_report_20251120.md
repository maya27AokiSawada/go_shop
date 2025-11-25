# Daily Report - 2025年11月20日

## 本日の作業概要
QR招待受諾時のPermission-Denied問題の解決として、Plan B（受諾者は通知のみ送信、招待元がすべて更新）を完全実装し、実機テストを実施。通知送信は成功したが、Windows側で通知を受信できない問題を調査。

---

## 実施した作業

### 1. Plan B実装の完成
**背景**: 受諾者がFirestore/Hiveを直接更新するとPermission-Deniedが発生するため、受諾者は通知のみ送信し、招待元がすべての更新を実行する方式に変更。

#### 1.1 受諾処理の簡略化
**ファイル**: `lib/services/qr_invitation_service.dart` (line 273-299)

**変更内容**:
- 削除した処理:
  - `_createPlaceholderGroup()` - Hiveプレースホルダー作成
  - `_processIndividualInvitation()` - グループ更新
  - `_recordInvitationAcceptance()` - 招待記録
- 残存処理:
  - 招待元への通知送信のみ

**実装コード**:
```dart
// 招待元のオーナーに通知を送信
await notificationService.sendNotification(
  targetUserId: inviterUid,
  groupId: groupId,
  type: NotificationType.groupMemberAdded,
  message: '$userName さんが「$groupName」への参加を希望しています',
  metadata: {
    'groupName': groupName,
    'acceptorUid': acceptorUid,
    'acceptorName': userName,
    'invitationId': invitationData['invitationId'],
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

#### 1.2 招待元側のグループ更新処理
**ファイル**: `lib/services/notification_service.dart`

**追加メソッド**: `_addMemberToGroup()` (line 242-315)

**処理内容**:
1. 現在のグループ情報を取得
2. `allowedUid`リストに受諾者UIDを追加
3. `members`リストに受諾者を追加
4. Firestoreを更新
5. Hiveを更新
6. 受諾者に確認通知を送信

**実装コード**:
```dart
Future<void> _addMemberToGroup(String groupId, String? acceptorUid, String acceptorName) async {
  // グループ取得
  final currentGroup = await repository.getGroupById(groupId);

  // allowedUid追加
  final updatedAllowedUid = List<String>.from(currentGroup.allowedUid ?? []);
  if (!updatedAllowedUid.contains(acceptorUid)) {
    updatedAllowedUid.add(acceptorUid!);
  }

  // members追加
  final updatedMembers = List<SharedGroupMember>.from(currentGroup.members ?? []);
  final newMember = SharedGroupMember(
    memberId: acceptorUid!,
    name: acceptorName,
    role: SharedGroupRole.member,
    // ...
  );
  updatedMembers.add(newMember);

  // Firestore更新
  await FirebaseFirestore.instance.collection('SharedGroups').doc(groupId).update({
    'allowedUid': updatedAllowedUid,
    'members': updatedMembers.map((m) => m.toJson()).toList(),
  });

  // Hive更新
  await repository.updateGroup(groupId, updatedGroup);
}
```

**通知受信時の処理** (line 155-186):
```dart
case NotificationType.groupMemberAdded:
  final acceptorUid = notification.metadata?['acceptorUid'] as String?;
  final acceptorName = notification.metadata?['acceptorName'] as String? ?? 'ユーザー';

  await _addMemberToGroup(groupId, acceptorUid, acceptorName);

  // 確認通知送信
  await sendNotification(
    targetUserId: acceptorUid,
    type: NotificationType.syncConfirmation,
    groupId: groupId,
    message: 'グループへの参加が承認されました',
  );
```

#### 1.3 UI更新
**ファイル**: `lib/widgets/accept_invitation_widget.dart` (line 210-228)

**変更内容**: 成功メッセージを「招待元の確認待ち」に変更

```dart
SnackBar(
  content: Column(
    children: [
      Text('✅ 招待を受諾しました'),
      Text('招待元（$groupName）の確認をお待ちください'),
    ],
  ),
  backgroundColor: Colors.orange,
);
```

#### 1.4 Permission-Denied対策
**ファイル**: `lib/services/user_initialization_service.dart`

**変更箇所**:
- Line 608-612: 同期削除時にHive専用リポジトリ使用
- Line 627-631: 同上

**理由**: Firestoreセキュリティルールでowner-only updateのため、受諾者がFirestore削除を試みるとPermission-Deniedが発生する。

### 2. 詳細ログの追加
**ファイル**: `lib/services/notification_service.dart` (line 87-133)

**追加内容**:
- リスナー起動時の詳細情報:
  - ユーザーUID
  - ユーザー名
  - メールアドレス
  - クエリ条件（`userId == `, `read == false`）
- スナップショット受信時のログ
- 通知検出時のログ

---

## 実機テスト結果

### テスト環境
- **招待元**: Windows (mayaでログイン)
- **受諾者**: Android (すももでログイン)

### テストフロー
1. Windows(maya)で招待QRコード作成
2. Android(すもも)でQRスキャン・受諾
3. 通知送信完了（Androidログで確認）
4. Windows側で通知受信確認

### 結果
✅ **Android側**: 通知送信成功
- ログ: `📤 [NOTIFICATION] 送信完了: VqNEozvTyXXw55Q46mNiGNMNngw2 - group_member_added`

❌ **Windows側**: 通知受信失敗
- リスナー起動は確認: `🔔 [NOTIFICATION] スナップショット受信: 0件の変更`
- 通知は検出されず

---

## 発見された問題

### 問題1: 通知が`read = true`になっている
**詳細**:
- Firestoreコンソールで確認された通知の`read`フィールドが`true`
- 通知リスナーは`read == false`でフィルタリング（line 109）
- そのため、Windows側で検出されない

**通知データ**:
```
type: "added" (group_member_added)
userId: "VqNEozvTyXXw55Q46mNiGNMNngw2" (mayaUID)
groupId: "1763614447615"
acceptorUid: "K35DAuQUktfhSr4XWFoAtBNL32E3" (すももUID)
read: true ← ここが問題
timestamp: 15:05頃
```

**考えられる原因**:
1. 通知作成直後に何らかの処理で自動的に既読化
2. リスナー起動前に通知が作成され、既に処理済み
3. 古い通知を確認している

**コードでは`read: false`で作成**:
```dart
// lib/services/notification_service.dart line 378
final notificationData = {
  'userId': targetUserId,
  'type': type.value,
  'groupId': groupId,
  'message': message,
  'timestamp': FieldValue.serverTimestamp(),
  'read': false,  // ← 明示的にfalse設定
  // ...
};
```

### 問題2: ログ出力とログイン状態の不一致
**ユーザー報告**:
- Windows側は**mayaでログイン中**
- ユーザー名: maya
- メールアドレス: fatima.sumomo@gmail.com

**ログ出力**:
- すべて**すもも（K35DAuQUktfhSr4XWFoAtBNL32E3）**として記録
- メールアドレス: fatima.yatomi@outlook.com

**考えられる原因**:
1. ログ出力のタイミング問題（UID変更処理中の古いログ）
2. SharedPreferencesとFirebaseAuthの不一致
3. ログ出力バグ

---

## 未解決の課題

### 1. 通知が`read = true`になる原因の特定
**対策案**:
- 新しいテストで通知作成の瞬間をリアルタイムで確認
- Firestoreコンソールで新規通知ドキュメントの`read`フィールドを即座に確認
- Windows側のログも同時に確認

### 2. ログイン状態の真実の確認
**対策案**:
- UIにFirebase AuthのUIDを直接表示
- サインアウト→再サインインで状態クリア
- Firebase Authの現在のユーザー情報を直接ログ出力

### 3. リスナーのクエリ条件見直し
**現状のクエリ**:
```dart
.where('userId', isEqualTo: currentUser.uid)
.where('read', isEqualTo: false)
```

**検討事項**:
- `read`条件を外して全通知を受信するか？
- または、通知受信後に既読化するタイミングを調整するか？

---

## 技術的知見

### 1. Firestore Permission対策
受諾者がFirestoreを直接更新しようとすると、owner-only updateルールでPermission-Deniedが発生する。解決策として：
- 受諾者: 通知のみ送信（権限不要）
- 招待元: 通知を受信して、自身の権限でFirestore/Hive更新

### 2. 通知ベースの非同期処理
リアルタイム通知を使うことで：
- セキュリティルールを維持したまま
- 非同期でグループメンバー追加が可能
- UI更新もリアルタイムで反映

### 3. クエリ条件の重要性
Firestoreリスナーのクエリ条件が厳密すぎると、通知を見逃す可能性がある。特に`read`フィールドの扱いには注意が必要。

---

## 明日の予定

1. **通知受信問題の完全解決**
   - 新しいテストでリアルタイム確認
   - `read = true`になる原因の特定
   - 必要に応じてクエリ条件を調整

2. **ログイン状態の検証**
   - Firebase AuthのUID直接表示
   - ログ出力の正確性確認

3. **エンドツーエンドテストの実施**
   - 招待作成→スキャン→通知受信→グループ更新→同期確認
   - すべての流れが正常に動作することを確認

4. **ドキュメント更新**
   - 通知システムの仕様書作成
   - トラブルシューティングガイド作成

---

## 作業時間
- 実装・デバッグ: 約4時間
- 実機テスト・調査: 約2時間
- ドキュメント作成: 約30分

## 備考
- Plan B実装は完了し、Android側の通知送信までは正常動作
- Windows側の通知受信問題が残っているが、原因は特定済み（`read = true`問題）
- 次回テストで最終確認予定
