# メンバー伝言メッセージ機能 - 詳細設計書

**作成日**: 2025年12月24日
**対象リリース**: v1.1.0
**実装予定**: 2025年12月27日～2026年1月4日（年末年始休暇中）

---

## 📋 目次

1. [機能概要](#機能概要)
2. [ユースケース](#ユースケース)
3. [データモデル設計](#データモデル設計)
4. [Firestore構造設計](#firestore構造設計)
5. [UI設計](#ui設計)
6. [Repository実装設計](#repository実装設計)
7. [Provider設計](#provider設計)
8. [セキュリティルール](#セキュリティルール)
9. [実装手順](#実装手順)
10. [テストケース](#テストケース)
11. [工数見積もり](#工数見積もり)

---

## 機能概要

### 目的

家族間のコミュニケーションを円滑にするため、各メンバーに対して伝言メッセージを残せる機能を実装する。

### 主要機能

- ✅ グループメンバー画面から各メンバーへメッセージ送信
- ✅ 未読メッセージの通知バッジ表示
- ✅ メッセージ履歴の表示（最新10件）
- ✅ メッセージ既読管理
- ✅ リアルタイム同期（Firestore Streams）

### 技術要件

- **データ永続化**: Firestore（メイン） + Hive（キャッシュ）
- **リアルタイム同期**: Firestore `snapshots()`
- **状態管理**: Riverpod (AsyncNotifierProvider)
- **権限管理**: グループメンバーのみ送受信可能

---

## ユースケース

### UC-1: メッセージ送信

**アクター**: グループメンバー
**前提条件**: ユーザーがグループメンバー管理画面を開いている
**メインフロー**:

1. メンバーリストでメッセージアイコンをタップ
2. メッセージダイアログが表示される
3. 過去のメッセージ履歴（最新10件）を確認できる
4. テキストフィールドにメッセージを入力
5. 「送信」ボタンをタップ
6. Firestoreにメッセージが保存される
7. 相手のデバイスにリアルタイムで通知される

**代替フロー**:

- 3a. メッセージがない場合は「まだメッセージはありません」と表示
- 5a. 空のメッセージは送信不可

### UC-2: メッセージ確認

**アクター**: グループメンバー
**前提条件**: 自分宛のメッセージが存在する
**メインフロー**:

1. グループメンバー管理画面を開く
2. 自分の名前のListTileに未読バッジが表示されている
3. メッセージアイコンをタップ
4. メッセージダイアログが開く
5. 未読メッセージを確認
6. ダイアログを開いた時点で既読になる

### UC-3: 未読通知

**アクター**: システム
**トリガー**: 新しいメッセージ受信
**メインフロー**:

1. Firestore Streamが新規メッセージを検知
2. targetMemberIdが現在のユーザーのUIDと一致
3. isRead = false の場合、未読バッジを表示
4. ListTileのsubtitleに最新メッセージプレビューを表示（オプション）

---

## データモデル設計

### MemberMessage モデル

```dart
// lib/models/member_message.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'member_message.freezed.dart';
part 'member_message.g.dart';

@HiveType(typeId: 7)
@freezed
class MemberMessage with _$MemberMessage {
  const factory MemberMessage({
    /// メッセージID（UUID v4）
    @HiveField(0) required String messageId,

    /// グループID
    @HiveField(1) required String groupId,

    /// メッセージを受け取る人のUID
    @HiveField(2) required String targetMemberId,

    /// メッセージを送信した人のUID
    @HiveField(3) required String fromMemberId,

    /// メッセージ送信者の表示名（キャッシュ用）
    @HiveField(4) required String fromMemberName,

    /// メッセージ本文（最大500文字）
    @HiveField(5) required String message,

    /// 作成日時
    @HiveField(6) required DateTime createdAt,

    /// 既読フラグ
    @HiveField(7) @Default(false) bool isRead,

    /// 既読日時（nullの場合は未読）
    @HiveField(8) DateTime? readAt,
  }) = _MemberMessage;

  factory MemberMessage.fromJson(Map<String, dynamic> json) =>
      _$MemberMessageFromJson(json);

  /// 新規メッセージ作成ファクトリ
  factory MemberMessage.create({
    required String groupId,
    required String targetMemberId,
    required String fromMemberId,
    required String fromMemberName,
    required String message,
  }) {
    return MemberMessage(
      messageId: _generateMessageId(),
      groupId: groupId,
      targetMemberId: targetMemberId,
      fromMemberId: fromMemberId,
      fromMemberName: fromMemberName,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
      readAt: null,
    );
  }

  static String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }
}
```

### バリデーションルール

- `message`: 1文字以上、500文字以下
- `targetMemberId`: グループのallowedUidに含まれること
- `fromMemberId`: 現在のユーザーUID
- `groupId`: 存在するグループID

---

## Firestore構造設計

### コレクション構造

```
/SharedGroups/{groupId}/memberMessages/{messageId}
```

**理由**: グループごとにサブコレクション化することで、クエリの効率化とセキュリティルール適用が容易

### ドキュメント構造

```json
{
  "messageId": "msg_1234567890_5678",
  "groupId": "group_abc123",
  "targetMemberId": "uid_target",
  "fromMemberId": "uid_sender",
  "fromMemberName": "すもも",
  "message": "牛乳買ってきてください",
  "createdAt": Timestamp,
  "isRead": false,
  "readAt": null
}
```

### インデックス設計

#### 必須複合インデックス

1. **未読メッセージクエリ用**
   - Collection: `memberMessages`
   - Fields:
     - `targetMemberId` (Ascending)
     - `isRead` (Ascending)
     - `createdAt` (Descending)

2. **メッセージ履歴クエリ用**
   - Collection: `memberMessages`
   - Fields:
     - `targetMemberId` (Ascending)
     - `createdAt` (Descending)

### Firestore Rulesでのセキュリティ

```javascript
// firestore.rules

match /SharedGroups/{groupId}/memberMessages/{messageId} {
  // グループメンバーのみアクセス可能
  function isGroupMember() {
    return request.auth != null && (
      request.auth.uid in get(/databases/$(database)/documents/SharedGroups/$(groupId)).data.allowedUid
    );
  }

  // 自分宛のメッセージ、または自分が送ったメッセージのみ読める
  function canReadMessage() {
    return request.auth != null && (
      resource.data.targetMemberId == request.auth.uid ||
      resource.data.fromMemberId == request.auth.uid
    );
  }

  // メッセージ作成は、fromMemberIdが自分のUID、targetがグループメンバー
  function canCreateMessage() {
    return request.auth != null &&
           request.resource.data.fromMemberId == request.auth.uid &&
           request.resource.data.targetMemberId in get(/databases/$(database)/documents/SharedGroups/$(groupId)).data.allowedUid;
  }

  // 既読更新は、自分宛のメッセージのみ
  function canMarkAsRead() {
    return request.auth != null &&
           resource.data.targetMemberId == request.auth.uid &&
           request.resource.data.keys().hasOnly(['isRead', 'readAt']);
  }

  allow read: if isGroupMember() && canReadMessage();
  allow create: if isGroupMember() && canCreateMessage();
  allow update: if isGroupMember() && canMarkAsRead();
  allow delete: if false; // メッセージ削除は不可（履歴保持のため）
}
```

---

## UI設計

### 1. メンバーリストTile拡張

#### 既存コード修正箇所

`lib/pages/group_member_management_page.dart` - `_buildMemberTile()`

```dart
Widget _buildMemberTile(SharedGroupMember member, SharedGroup group) {
  final isOwner = member.role == SharedGroupRole.owner;
  final roleDisplayName = _getRoleDisplayName(member.role);

  // 🆕 現在のユーザーかチェック
  final currentUser = FirebaseAuth.instance.currentUser;
  final isCurrentUser = currentUser?.uid == member.memberId;

  // 🆕 未読メッセージ数を取得
  final unreadCount = ref.watch(
    unreadMessageCountProvider(member.memberId)
  ).valueOrNull ?? 0;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: isOwner ? Colors.amber.shade100 : Colors.blue.shade100,
        child: Text(
          member.name.isNotEmpty ? member.name[0] : '?',
          style: TextStyle(
            color: isOwner ? Colors.amber.shade700 : Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(member.name),
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '自分',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        roleDisplayName,
        style: TextStyle(
          color: isOwner ? Colors.amber.shade700 : Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🆕 メッセージアイコン（未読バッジ付き）
          _buildMessageButton(member, unreadCount),
          const SizedBox(width: 8),
          // 既存のPopupMenuButton...
          isOwner
              ? const Icon(Icons.star, color: Colors.amber)
              : PopupMenuButton<String>(...),
        ],
      ),
    ),
  );
}

// 🆕 メッセージボタン
Widget _buildMessageButton(SharedGroupMember member, int unreadCount) {
  return Stack(
    children: [
      IconButton(
        icon: const Icon(Icons.message_outlined),
        color: Colors.blue,
        tooltip: '伝言メッセージ',
        onPressed: () => _showMessageDialog(member),
      ),
      if (unreadCount > 0)
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  );
}
```

### 2. メッセージダイアログ

#### 新規ウィジェット

`lib/widgets/member_message_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_group.dart';
import '../models/member_message.dart';
import '../providers/member_message_provider.dart';

class MemberMessageDialog extends ConsumerStatefulWidget {
  final SharedGroup group;
  final SharedGroupMember targetMember;

  const MemberMessageDialog({
    super.key,
    required this.group,
    required this.targetMember,
  });

  @override
  ConsumerState<MemberMessageDialog> createState() =>
      _MemberMessageDialogState();
}

class _MemberMessageDialogState extends ConsumerState<MemberMessageDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // リアルタイムでメッセージ履歴を取得
    final messagesAsync = ref.watch(
      memberMessagesProvider(widget.group.groupId, widget.targetMember.memberId)
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(),
            const Divider(height: 1),

            // メッセージ履歴
            Expanded(
              child: messagesAsync.when(
                data: (messages) => _buildMessageList(messages),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorView(error),
              ),
            ),

            const Divider(height: 1),

            // 入力フィールド
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              widget.targetMember.name.isNotEmpty
                  ? widget.targetMember.name[0]
                  : '?',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.targetMember.name} への伝言',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '最新10件まで表示',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<MemberMessage> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'まだメッセージはありません',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 自動スクロール（新規メッセージ追加時）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(MemberMessage message) {
    final currentUser = ref.read(authStateProvider).value;
    final isMyMessage = message.fromMemberId == currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              child: Text(
                message.fromMemberName.isNotEmpty
                    ? message.fromMemberName[0]
                    : '?',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMyMessage ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMyMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.fromMemberName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDateTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isMyMessage && message.isRead) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLength: 500,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'メッセージを入力...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('メッセージの読み込みに失敗しました'),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(memberMessagesProvider);
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メッセージを入力してください')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref.read(memberMessageNotifierProvider.notifier).sendMessage(
            groupId: widget.group.groupId,
            targetMemberId: widget.targetMember.memberId,
            message: message,
          );

      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メッセージを送信しました'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '昨日 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
```

---

## Repository実装設計

### MemberMessageRepository (Abstract)

`lib/datastore/member_message_repository.dart`

```dart
import '../models/member_message.dart';

abstract class MemberMessageRepository {
  /// メッセージを送信
  Future<void> sendMessage(MemberMessage message);

  /// 特定メンバー宛のメッセージを取得（最新10件）
  Future<List<MemberMessage>> getMessages(String groupId, String targetMemberId);

  /// 特定メンバー宛のメッセージをリアルタイム取得
  Stream<List<MemberMessage>> watchMessages(String groupId, String targetMemberId);

  /// 未読メッセージ数を取得
  Future<int> getUnreadCount(String groupId, String targetMemberId);

  /// 未読メッセージ数をリアルタイム取得
  Stream<int> watchUnreadCount(String groupId, String targetMemberId);

  /// メッセージを既読にする
  Future<void> markAsRead(String groupId, String messageId);

  /// 特定メンバー宛の全メッセージを既読にする
  Future<void> markAllAsRead(String groupId, String targetMemberId);
}
```

### FirestoreMemberMessageRepository

`lib/datastore/firestore_member_message_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer show log;
import '../models/member_message.dart';
import 'member_message_repository.dart';

class FirestoreMemberMessageRepository implements MemberMessageRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreMemberMessageRepository()
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance;

  CollectionReference _collection(String groupId) => _firestore
      .collection('SharedGroups')
      .doc(groupId)
      .collection('memberMessages');

  @override
  Future<void> sendMessage(MemberMessage message) async {
    developer.log('📤 [MESSAGE] メッセージ送信: ${message.messageId}');

    await _collection(message.groupId)
        .doc(message.messageId)
        .set(_messageToFirestore(message));

    developer.log('✅ [MESSAGE] メッセージ送信完了');
  }

  @override
  Future<List<MemberMessage>> getMessages(
      String groupId, String targetMemberId) async {
    developer.log('📥 [MESSAGE] メッセージ取得: $targetMemberId');

    final snapshot = await _collection(groupId)
        .where('targetMemberId', isEqualTo: targetMemberId)
        .orderBy('createdAt', descending: false)
        .limit(10)
        .get();

    final messages = snapshot.docs
        .map((doc) => _messageFromFirestore(doc))
        .toList();

    developer.log('✅ [MESSAGE] ${messages.length}件取得');
    return messages;
  }

  @override
  Stream<List<MemberMessage>> watchMessages(
      String groupId, String targetMemberId) {
    developer.log('👀 [MESSAGE] メッセージ監視開始: $targetMemberId');

    return _collection(groupId)
        .where('targetMemberId', isEqualTo: targetMemberId)
        .orderBy('createdAt', descending: false)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => _messageFromFirestore(doc))
          .toList();
      developer.log('🔄 [MESSAGE] 更新検知: ${messages.length}件');
      return messages;
    });
  }

  @override
  Future<int> getUnreadCount(String groupId, String targetMemberId) async {
    final snapshot = await _collection(groupId)
        .where('targetMemberId', isEqualTo: targetMemberId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Stream<int> watchUnreadCount(String groupId, String targetMemberId) {
    return _collection(groupId)
        .where('targetMemberId', isEqualTo: targetMemberId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAsRead(String groupId, String messageId) async {
    developer.log('✅ [MESSAGE] 既読マーク: $messageId');

    await _collection(groupId).doc(messageId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllAsRead(String groupId, String targetMemberId) async {
    developer.log('✅ [MESSAGE] 全既読マーク: $targetMemberId');

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await _collection(groupId)
        .where('targetMemberId', isEqualTo: targetMemberId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    developer.log('✅ [MESSAGE] ${snapshot.docs.length}件既読');
  }

  // Firestore変換メソッド
  Map<String, dynamic> _messageToFirestore(MemberMessage message) {
    return {
      'messageId': message.messageId,
      'groupId': message.groupId,
      'targetMemberId': message.targetMemberId,
      'fromMemberId': message.fromMemberId,
      'fromMemberName': message.fromMemberName,
      'message': message.message,
      'createdAt': Timestamp.fromDate(message.createdAt),
      'isRead': message.isRead,
      'readAt': message.readAt != null
          ? Timestamp.fromDate(message.readAt!)
          : null,
    };
  }

  MemberMessage _messageFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberMessage(
      messageId: data['messageId'] as String,
      groupId: data['groupId'] as String,
      targetMemberId: data['targetMemberId'] as String,
      fromMemberId: data['fromMemberId'] as String,
      fromMemberName: data['fromMemberName'] as String,
      message: data['message'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
    );
  }
}
```

### HiveMemberMessageRepository (キャッシュ用)

`lib/datastore/hive_member_message_repository.dart`

```dart
import 'package:hive/hive.dart';
import 'dart:developer' as developer show log;
import '../models/member_message.dart';
import 'member_message_repository.dart';

class HiveMemberMessageRepository implements MemberMessageRepository {
  static const String _boxName = 'memberMessages';

  Box<MemberMessage> get _box => Hive.box<MemberMessage>(_boxName);

  @override
  Future<void> sendMessage(MemberMessage message) async {
    developer.log('💾 [HIVE] メッセージ保存: ${message.messageId}');
    await _box.put(message.messageId, message);
  }

  @override
  Future<List<MemberMessage>> getMessages(
      String groupId, String targetMemberId) async {
    developer.log('📖 [HIVE] メッセージ読込: $targetMemberId');

    final allMessages = _box.values.where((msg) =>
        msg.groupId == groupId && msg.targetMemberId == targetMemberId);

    final sortedMessages = allMessages.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return sortedMessages.take(10).toList();
  }

  @override
  Stream<List<MemberMessage>> watchMessages(
      String groupId, String targetMemberId) {
    // Hiveはリアルタイム監視非対応のため、Stream.periodic()で代替
    return Stream.periodic(const Duration(seconds: 5), (_) async {
      return await getMessages(groupId, targetMemberId);
    }).asyncMap((future) => future);
  }

  @override
  Future<int> getUnreadCount(String groupId, String targetMemberId) async {
    final unreadMessages = _box.values.where((msg) =>
        msg.groupId == groupId &&
        msg.targetMemberId == targetMemberId &&
        !msg.isRead);

    return unreadMessages.length;
  }

  @override
  Stream<int> watchUnreadCount(String groupId, String targetMemberId) {
    return Stream.periodic(const Duration(seconds: 5), (_) async {
      return await getUnreadCount(groupId, targetMemberId);
    }).asyncMap((future) => future);
  }

  @override
  Future<void> markAsRead(String groupId, String messageId) async {
    final message = _box.get(messageId);
    if (message != null) {
      final updatedMessage = message.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      await _box.put(messageId, updatedMessage);
    }
  }

  @override
  Future<void> markAllAsRead(String groupId, String targetMemberId) async {
    final unreadMessages = _box.values.where((msg) =>
        msg.groupId == groupId &&
        msg.targetMemberId == targetMemberId &&
        !msg.isRead);

    for (var message in unreadMessages) {
      await markAsRead(groupId, message.messageId);
    }
  }
}
```

### HybridMemberMessageRepository

`lib/datastore/hybrid_member_message_repository.dart`

```dart
import 'dart:developer' as developer show log;
import '../models/member_message.dart';
import '../flavors.dart';
import 'member_message_repository.dart';
import 'firestore_member_message_repository.dart';
import 'hive_member_message_repository.dart';

class HybridMemberMessageRepository implements MemberMessageRepository {
  final FirestoreMemberMessageRepository? _firestoreRepo;
  final HiveMemberMessageRepository _hiveRepo;

  HybridMemberMessageRepository()
      : _firestoreRepo = F.appFlavor == Flavor.prod
            ? FirestoreMemberMessageRepository()
            : null,
        _hiveRepo = HiveMemberMessageRepository();

  @override
  Future<void> sendMessage(MemberMessage message) async {
    if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
      developer.log('🔥 [HYBRID] Firestore優先 - メッセージ送信');
      await _firestoreRepo!.sendMessage(message);
      await _hiveRepo.sendMessage(message); // キャッシュ
    } else {
      developer.log('📝 [HYBRID] Hive送信');
      await _hiveRepo.sendMessage(message);
    }
  }

  @override
  Future<List<MemberMessage>> getMessages(
      String groupId, String targetMemberId) async {
    if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
      try {
        final messages =
            await _firestoreRepo!.getMessages(groupId, targetMemberId);

        // Hiveキャッシュ更新
        for (var message in messages) {
          await _hiveRepo.sendMessage(message);
        }

        return messages;
      } catch (e) {
        developer.log('⚠️ [HYBRID] Firestore失敗、Hiveフォールバック: $e');
        return await _hiveRepo.getMessages(groupId, targetMemberId);
      }
    } else {
      return await _hiveRepo.getMessages(groupId, targetMemberId);
    }
  }

  @override
  Stream<List<MemberMessage>> watchMessages(
      String groupId, String targetMemberId) {
    if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
      developer.log('👀 [HYBRID] Firestore Stream監視');
      return _firestoreRepo!.watchMessages(groupId, targetMemberId).map((messages) {
        // バックグラウンドでHiveキャッシュ更新
        for (var message in messages) {
          _hiveRepo.sendMessage(message);
        }
        return messages;
      });
    } else {
      return _hiveRepo.watchMessages(groupId, targetMemberId);
    }
  }

  @override
  Future<int> getUnreadCount(String groupId, String targetMemberId) async {
    if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
      try {
        return await _firestoreRepo!.getUnreadCount(groupId, targetMemberId);
      } catch (e) {
        return await _hiveRepo.getUnreadCount(groupId, targetMemberId);
      }
    } else {
      return await _hiveRepo.getUnreadCount(groupId, targetMemberId);
    }
  }

  @override
  Stream<int> watchUnreadCount(String groupId, String targetMemberId) {
    if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
      return _firestoreRepo!.watchUnreadCount(groupId, targetMemberId);
    } else {
      return _hiveRepo.watchUnreadCount(groupId, targetMemberId);
    }
  }

  @override
  Future<void> markAsRead(String groupId, String messageId) async {
    if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
      await _firestoreRepo!.markAsRead(groupId, messageId);
      await _hiveRepo.markAsRead(groupId, messageId);
    } else {
      await _hiveRepo.markAsRead(groupId, messageId);
    }
  }

  @override
  Future<void> markAllAsRead(String groupId, String targetMemberId) async {
    if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
      await _firestoreRepo!.markAllAsRead(groupId, targetMemberId);
      await _hiveRepo.markAllAsRead(groupId, targetMemberId);
    } else {
      await _hiveRepo.markAllAsRead(groupId, targetMemberId);
    }
  }
}
```

---

## Provider設計

### RepositoryProvider

`lib/providers/member_message_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/member_message.dart';
import '../datastore/member_message_repository.dart';
import '../datastore/hybrid_member_message_repository.dart';

// Repository Provider
final memberMessageRepositoryProvider =
    Provider<MemberMessageRepository>((ref) {
  return HybridMemberMessageRepository();
});

// メッセージ履歴Provider（リアルタイム）
final memberMessagesProvider = StreamProvider.autoDispose
    .family<List<MemberMessage>, (String, String)>((ref, args) {
  final (groupId, targetMemberId) = args;
  final repository = ref.watch(memberMessageRepositoryProvider);

  return repository.watchMessages(groupId, targetMemberId);
});

// 未読数Provider（リアルタイム）
final unreadMessageCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, targetMemberId) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return Stream.value(0);

  final selectedGroup = ref.watch(selectedGroupProvider).valueOrNull;
  if (selectedGroup == null) return Stream.value(0);

  final repository = ref.watch(memberMessageRepositoryProvider);
  return repository.watchUnreadCount(selectedGroup.groupId, targetMemberId);
});

// メッセージNotifierProvider
final memberMessageNotifierProvider =
    NotifierProvider<MemberMessageNotifier, void>(MemberMessageNotifier.new);

class MemberMessageNotifier extends Notifier<void> {
  @override
  void build() {}

  /// メッセージ送信
  Future<void> sendMessage({
    required String groupId,
    required String targetMemberId,
    required String message,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }

    // 送信者の名前を取得（SharedPreferencesまたはFirestore）
    final fromMemberName = await _getCurrentUserName();

    final newMessage = MemberMessage.create(
      groupId: groupId,
      targetMemberId: targetMemberId,
      fromMemberId: currentUser.uid,
      fromMemberName: fromMemberName,
      message: message,
    );

    final repository = ref.read(memberMessageRepositoryProvider);
    await repository.sendMessage(newMessage);
  }

  /// メッセージを既読にする
  Future<void> markAsRead(String groupId, String messageId) async {
    final repository = ref.read(memberMessageRepositoryProvider);
    await repository.markAsRead(groupId, messageId);
  }

  /// 全メッセージを既読にする
  Future<void> markAllAsRead(String groupId, String targetMemberId) async {
    final repository = ref.read(memberMessageRepositoryProvider);
    await repository.markAllAsRead(groupId, targetMemberId);
  }

  Future<String> _getCurrentUserName() async {
    // SharedPreferencesから取得
    final savedName = await UserPreferencesService.getUserName();
    if (savedName != null && savedName.isNotEmpty) {
      return savedName;
    }

    // Firestoreから取得
    final firestoreName = await FirestoreUserNameService.getUserName();
    if (firestoreName != null && firestoreName.isNotEmpty) {
      return firestoreName;
    }

    // Firebase Authから取得
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser.displayName!;
    }

    // 最終的にメールアドレスの@前を使用
    if (currentUser?.email != null) {
      return currentUser!.email!.split('@')[0];
    }

    return 'ユーザー';
  }
}
```

---

## セキュリティルール

### Firestore Security Rules

`firestore.rules` に追加：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 既存のルール...

    // メンバーメッセージのルール
    match /SharedGroups/{groupId}/memberMessages/{messageId} {
      // グループメンバーかチェック
      function isGroupMember() {
        return request.auth != null && (
          request.auth.uid in get(/databases/$(database)/documents/SharedGroups/$(groupId)).data.allowedUid
        );
      }

      // 自分宛のメッセージ、または自分が送ったメッセージのみ読める
      function canReadMessage() {
        return request.auth != null && (
          resource.data.targetMemberId == request.auth.uid ||
          resource.data.fromMemberId == request.auth.uid
        );
      }

      // メッセージ作成は、fromMemberIdが自分のUID、targetがグループメンバー
      function canCreateMessage() {
        return request.auth != null &&
               request.resource.data.fromMemberId == request.auth.uid &&
               request.resource.data.targetMemberId in get(/databases/$(database)/documents/SharedGroups/$(groupId)).data.allowedUid &&
               request.resource.data.message.size() >= 1 &&
               request.resource.data.message.size() <= 500;
      }

      // 既読更新は、自分宛のメッセージのみ
      function canMarkAsRead() {
        return request.auth != null &&
               resource.data.targetMemberId == request.auth.uid &&
               request.resource.data.keys().hasOnly(['isRead', 'readAt']);
      }

      allow read: if isGroupMember() && canReadMessage();
      allow create: if isGroupMember() && canCreateMessage();
      allow update: if isGroupMember() && canMarkAsRead();
      allow delete: if false; // メッセージ削除は不可（履歴保持のため）
    }
  }
}
```

### デプロイコマンド

```bash
firebase deploy --only firestore:rules
```

---

## 実装手順

### Phase 1: データモデル実装（1時間）

1. ✅ `lib/models/member_message.dart` 作成
2. ✅ Freezed + Hive アノテーション追加
3. ✅ コード生成実行
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. ✅ Hive TypeAdapter登録（main.dart）
   ```dart
   Hive.registerAdapter(MemberMessageAdapter());
   await Hive.openBox<MemberMessage>('memberMessages');
   ```

### Phase 2: Repository実装（2時間）

1. ✅ `member_message_repository.dart` (Abstract)
2. ✅ `firestore_member_message_repository.dart`
3. ✅ `hive_member_message_repository.dart`
4. ✅ `hybrid_member_message_repository.dart`

### Phase 3: Provider実装（1時間）

1. ✅ `member_message_provider.dart` 作成
2. ✅ RepositoryProvider
3. ✅ StreamProviders（メッセージ履歴、未読数）
4. ✅ NotifierProvider（送信、既読処理）

### Phase 4: UI実装（2-3時間）

1. ✅ `member_message_dialog.dart` 作成
2. ✅ `group_member_management_page.dart` 修正
   - メッセージアイコン追加
   - 未読バッジ表示
3. ✅ ダイアログからの送信処理
4. ✅ 既読処理（ダイアログ表示時に自動既読）

### Phase 5: Firestore設定（30分）

1. ✅ firestore.rules 修正
2. ✅ ルールデプロイ
3. ✅ Firestoreインデックス作成（Firebase Console）
   - `targetMemberId` + `isRead` + `createdAt`
   - `targetMemberId` + `createdAt`

### Phase 6: テスト（1時間）

1. ✅ 2デバイスでメッセージ送受信テスト
2. ✅ 未読バッジ表示テスト
3. ✅ 既読処理テスト
4. ✅ リアルタイム同期テスト
5. ✅ エラーハンドリングテスト

---

## テストケース

### 機能テスト

#### TC-1: メッセージ送信

| テスト項目 | 手順 | 期待結果 |
|----------|-----|---------|
| 正常系 | メッセージ入力→送信 | Firestoreに保存、相手デバイスに表示 |
| 異常系（空） | 空文字で送信 | エラーメッセージ表示 |
| 異常系（長文） | 501文字で送信 | エラーメッセージ表示 |

#### TC-2: 未読バッジ

| テスト項目 | 手順 | 期待結果 |
|----------|-----|---------|
| 新規メッセージ | デバイスA→Bへ送信 | デバイスBに未読バッジ表示 |
| 既読後 | メッセージダイアログ開く | バッジ消える |
| 複数未読 | 3件送信 | バッジに「3」表示 |
| 10件以上 | 10件以上送信 | バッジに「9+」表示 |

#### TC-3: リアルタイム同期

| テスト項目 | 手順 | 期待結果 |
|----------|-----|---------|
| 送信中ダイアログ開く | Aから送信、Bでダイアログ開いたまま | Bのダイアログに即座に表示 |
| メンバー画面でバッジ更新 | Aから送信、Bはメンバー画面表示中 | バッジが即座に更新 |

### セキュリティテスト

#### TC-4: 権限チェック

| テスト項目 | 手順 | 期待結果 |
|----------|-----|---------|
| グループ外ユーザー | 他グループのメッセージ読取試行 | PERMISSION_DENIED |
| 他人のメッセージ | 自分以外宛のメッセージ読取試行 | PERMISSION_DENIED |
| 削除試行 | メッセージ削除試行 | PERMISSION_DENIED |

---

## 工数見積もり

| フェーズ | 作業内容 | 見積時間 | 累計 |
|---------|---------|---------|------|
| Phase 1 | データモデル実装 | 1時間 | 1時間 |
| Phase 2 | Repository実装 | 2時間 | 3時間 |
| Phase 3 | Provider実装 | 1時間 | 4時間 |
| Phase 4 | UI実装 | 2.5時間 | 6.5時間 |
| Phase 5 | Firestore設定 | 0.5時間 | 7時間 |
| Phase 6 | テスト | 1時間 | 8時間 |

**合計**: 約8時間（1日）

### スケジュール例

**前提条件**:
- 12/25（水）まで作業所勤務
- 12/27（金）大掃除で実質休暇開始
- 12/28（土）以降が本格実装期間

**Day 1** (12/28土):
- 午前: Phase 1-2（データモデル + Repository）
- 午後: Phase 3-4（Provider + UI）

**Day 2** (12/29日):
- 午前: Phase 5-6（Firestore設定 + テスト）
- 午後: バグフィックス + ドキュメント更新

---

## 今後の拡張案

### 短期（v1.2.0）

- ✅ メッセージ削除機能（送信者のみ）
- ✅ メッセージ編集機能（送信後5分以内）
- ✅ 画像添付機能（Firebase Storage）

### 中期（v2.0.0）

- ✅ グループ全体チャット（全員が見れる掲示板）
- ✅ メンション機能（@username）
- ✅ リアクション機能（👍❤️など）

### 長期（v3.0.0）

- ✅ 音声メッセージ
- ✅ 位置情報共有
- ✅ メッセージ検索機能

---

## 注意事項

### パフォーマンス

- メッセージ取得は最新10件に制限（Firestoreクエリコスト削減）
- StreamProviderは`autoDispose`使用（メモリリーク防止）
- 画像は圧縮してからアップロード（将来実装時）

### セキュリティ

- メッセージ本文にはXSS対策不要（Flutterはネイティブ）
- ただし、表示時に絵文字以外の特殊文字はサニタイズ推奨
- Firestore Rulesで文字数制限（1-500文字）

### UX

- 送信中はローディング表示
- エラー時は具体的なメッセージ表示
- オフライン時はHiveキャッシュで動作継続

---

## 参考資料

- [Firestore Stream Queries](https://firebase.google.com/docs/firestore/query-data/listen)
- [Riverpod StreamProvider](https://riverpod.dev/docs/providers/stream_provider)
- [Hive Database](https://docs.hivedb.dev/)
- Go Shop - copilot-instructions.md

---

**作成者**: GitHub Copilot
**レビュー**: 必要に応じて実装前に確認してください
**最終更新**: 2025年12月24日
