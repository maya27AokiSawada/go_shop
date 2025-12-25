import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../utils/firestore_helper.dart'; // Firestore操作ヘルパー
import 'user_initialization_service.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/hive_provider.dart'; // Hive Box プロバイダー
import '../models/shared_group.dart';
import '../datastore/firestore_purchase_group_repository.dart'; // Repository型チェック用

/// 通知サービスプロバイダー
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// 通知タイプ
enum NotificationType {
  groupMemberAdded('group_member_added'),
  groupUpdated('group_updated'),
  invitationAccepted('invitation_accepted'),
  groupDeleted('group_deleted'),
  syncConfirmation('sync_confirmation'), // 同期確認通知

  // リスト関連通知（即時送信）
  listCreated('list_created'), // リスト作成
  listDeleted('list_deleted'), // リスト削除
  listRenamed('list_renamed'), // リスト名変更

  // アイテム関連通知（5分間隔でバッチ送信）
  itemAdded('item_added'), // アイテム追加
  itemRemoved('item_removed'), // アイテム削除
  itemPurchased('item_purchased'); // 購入完了

  const NotificationType(this.value);
  final String value;

  static NotificationType? fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.groupUpdated,
    );
  }
}

/// 通知データモデル
class NotificationData {
  final String id;
  final String userId;
  final NotificationType type;
  final String groupId;
  final String message;
  final DateTime timestamp;
  final bool read;
  final Map<String, dynamic>? metadata;

  NotificationData({
    required this.id,
    required this.userId,
    required this.type,
    required this.groupId,
    required this.message,
    required this.timestamp,
    required this.read,
    this.metadata,
  });

  factory NotificationData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationData(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.fromString(data['type'] ?? '') ??
          NotificationType.groupUpdated,
      groupId: data['groupId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// リアルタイム通知サービス
class NotificationService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isListening = false;

  NotificationService(this._ref);

  /// 通知リスナーを開始
  void startListening() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      AppLogger.info('🔕 [NOTIFICATION] 認証なし - 通知リスナー起動スキップ');
      return;
    }

    if (_isListening) {
      AppLogger.info(
          '🔔 [NOTIFICATION] 既にリスナー起動中 (UID: ${AppLogger.maskUserId(currentUser.uid)})');
      return;
    }

    AppLogger.info('🔔 [NOTIFICATION] ========== リアルタイム通知リスナー起動開始 ==========');
    AppLogger.info(
        '🔔 [NOTIFICATION] ユーザーUID: ${AppLogger.maskUserId(currentUser.uid)}');
    AppLogger.info(
        '🔔 [NOTIFICATION] ユーザー名: ${currentUser.displayName ?? "未設定"}');
    AppLogger.info('🔔 [NOTIFICATION] メール: ${currentUser.email}');

    // リスナー起動時刻を記録（この時刻以降の通知のみ処理）
    final listenerStartTime = DateTime.now();
    AppLogger.info('🔔 [NOTIFICATION] リスナー起動時刻: $listenerStartTime');
    AppLogger.info(
        '🔔 [NOTIFICATION] クエリ条件: userId == ${currentUser.uid}, read == false');

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        AppLogger.info(
            '🔔 [NOTIFICATION] スナップショット受信: ${snapshot.docChanges.length}件の変更');
        for (var change in snapshot.docChanges) {
          AppLogger.info(
              '🔔 [NOTIFICATION] 変更タイプ: ${change.type}, docId: ${change.doc.id}');
          if (change.type == DocumentChangeType.added) {
            final notification = NotificationData.fromFirestore(change.doc);

            // リスナー起動前の既存通知はスキップ（既読化しない）
            if (notification.timestamp.isBefore(listenerStartTime)) {
              AppLogger.info(
                  '⏭️ [NOTIFICATION] 既存通知をスキップ: ${notification.id} (${notification.timestamp})');
              continue;
            }

            AppLogger.info(
                '🔔 [NOTIFICATION] 新規通知検出: type=${notification.type}, groupId=${notification.groupId}');
            _handleNotification(notification);
          }
        }
      },
      onError: (error) {
        AppLogger.error('❌ [NOTIFICATION] リスナーエラー: $error');
        AppLogger.error('❌ [NOTIFICATION] エラー詳細: ${error.toString()}');
      },
    );

    _isListening = true;
    AppLogger.info('✅ [NOTIFICATION] リスナー起動完了！待機中...');
    AppLogger.info('🔔 [NOTIFICATION] ========== リスナー設定完了 ==========');
  }

  /// 通知リスナーを停止
  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _isListening = false;
    AppLogger.info('🔕 [NOTIFICATION] リスナー停止');
  }

  /// 通知を処理
  Future<void> _handleNotification(NotificationData notification) async {
    try {
      AppLogger.info(
          '📬 [NOTIFICATION] 受信: ${notification.type.value} - ${notification.message}');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.error('❌ [NOTIFICATION] 認証なし - 処理スキップ');
        return;
      }

      // 通知タイプによって処理を分岐
      switch (notification.type) {
        case NotificationType.groupMemberAdded:
          // 新メンバー追加通知 - 招待元が受諾者をグループに追加
          AppLogger.info('👥 [NOTIFICATION] 新メンバー追加通知を受信！');
          final groupId = notification.groupId; // ← トップレベルから取得
          final acceptorUid = notification.metadata?['acceptorUid'] as String?;
          final acceptorName =
              notification.metadata?['acceptorName'] as String? ?? 'ユーザー';

          AppLogger.info(
              '👥 [NOTIFICATION] グループID: ${AppLogger.maskGroupId(groupId)}');
          AppLogger.info('👥 [NOTIFICATION] 受諾者UID: $acceptorUid');
          AppLogger.info('👥 [NOTIFICATION] 受諾者名: $acceptorName');

          if (groupId.isNotEmpty && acceptorUid != null) {
            // 受諾者をグループに追加（招待元として実行）
            await _addMemberToGroup(groupId, acceptorUid, acceptorName);

            // UI更新（全グループプロバイダーを即座に更新）
            _ref.invalidate(allGroupsProvider);

            // 現在選択中のグループIDを確認
            final selectedGroupId = _ref.read(selectedGroupIdProvider);
            if (selectedGroupId == groupId) {
              // 対象グループが現在選択中の場合、selectedGroupProviderも更新
              _ref.invalidate(selectedGroupProvider);
              AppLogger.info(
                  '✅ [NOTIFICATION] 選択中グループも更新: ${AppLogger.maskGroupId(groupId)}');
            }

            // 受諾者に確認通知を送信
            AppLogger.info('📤 [NOTIFICATION] 確認通知を送信: $acceptorUid');
            await sendNotification(
              targetUserId: acceptorUid,
              type: NotificationType.syncConfirmation,
              groupId: groupId,
              message: 'グループへの参加が承認されました',
              metadata: {
                'confirmedBy': currentUser.uid,
                'groupName': notification.metadata?['groupName']
              },
            );
          } else {
            // groupIdがない場合は全体同期
            final userInitService =
                _ref.read(userInitializationServiceProvider);
            await userInitService.syncFromFirestoreToHive(currentUser);

            // UI更新
            _ref.invalidate(allGroupsProvider);
            _ref.invalidate(selectedGroupProvider);
          }

          AppLogger.info('✅ [NOTIFICATION] 同期完了 - UI更新');
          break;

        case NotificationType.invitationAccepted:
        case NotificationType.groupUpdated:
          // Firestore→Hive同期
          AppLogger.info('🔄 [NOTIFICATION] Firestore→Hive同期開始');
          final userInitService = _ref.read(userInitializationServiceProvider);
          await userInitService.syncFromFirestoreToHive(currentUser);

          // UI更新（全グループと選択中グループの両方を更新）
          _ref.invalidate(allGroupsProvider);
          _ref.invalidate(selectedGroupProvider);
          AppLogger.info('✅ [NOTIFICATION] 同期完了 - UI更新');
          break;

        case NotificationType.syncConfirmation:
          // 同期確認通知 - 念のため同期実行（二重保険）
          AppLogger.info('✅ [NOTIFICATION] 同期確認受信 - 念のため同期実行');
          final userInitService = _ref.read(userInitializationServiceProvider);
          await userInitService.syncFromFirestoreToHive(currentUser);
          _ref.invalidate(allGroupsProvider);
          AppLogger.info('✅ [NOTIFICATION] 確認通知による同期完了');
          break;

        case NotificationType.groupDeleted:
          // グループ削除通知
          AppLogger.info('🗑️ [NOTIFICATION] グループ削除通知');
          _ref.invalidate(allGroupsProvider);
          break;

        case NotificationType.itemAdded:
        case NotificationType.itemRemoved:
        case NotificationType.itemPurchased:
          // リスト変更通知 - リストプロバイダーを更新
          AppLogger.info(
              '📝 [NOTIFICATION] リスト変更通知: ${notification.type.value}');
          // TODO: SharedListProviderの無効化処理を追加
          // _ref.invalidate(sharedListProvider);
          AppLogger.info('✅ [NOTIFICATION] リスト変更通知処理完了');
          break;

        case NotificationType.listCreated:
          // リスト作成通知
          AppLogger.info('📝 [NOTIFICATION] リスト作成通知受信');
          _ref.invalidate(allGroupsProvider);
          AppLogger.info('✅ [NOTIFICATION] リスト作成通知処理完了');
          break;

        case NotificationType.listDeleted:
          // リスト削除通知
          AppLogger.info('🗑️ [NOTIFICATION] リスト削除通知受信');
          _ref.invalidate(allGroupsProvider);
          AppLogger.info('✅ [NOTIFICATION] リスト削除通知処理完了');
          break;

        case NotificationType.listRenamed:
          // リスト名変更通知
          AppLogger.info('✏️ [NOTIFICATION] リスト名変更通知受信');
          _ref.invalidate(allGroupsProvider);
          AppLogger.info('✅ [NOTIFICATION] リスト名変更通知処理完了');
          break;
      }

      // 通知を既読にする
      await markAsRead(notification.id);
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] 処理エラー: $e');
    }
  }

  /// 受諾者をグループに追加（招待元として実行）
  Future<void> _addMemberToGroup(
      String groupId, String acceptorUid, String acceptorName) async {
    try {
      AppLogger.info(
          '📤 [OWNER] グループ更新開始: ${AppLogger.maskGroupId(groupId)} に ${AppLogger.maskName(acceptorName)} を追加');

      // acceptorNameが空の場合、Firestoreプロファイルから取得
      String finalAcceptorName = acceptorName;
      if (acceptorName.isEmpty || acceptorName == 'ユーザー') {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(acceptorUid)
              .get();

          if (userDoc.exists) {
            final firestoreName = userDoc.data()?['displayName'] as String?;
            if (firestoreName?.isNotEmpty == true) {
              finalAcceptorName = firestoreName!;
              AppLogger.info('📤 [OWNER] Firestoreから名前取得: $finalAcceptorName');
            }
          }
        } catch (e) {
          AppLogger.error('📤 [OWNER] Firestore取得エラー: $e');
        }
      }

      // 現在のグループ情報を取得
      final repository = _ref.read(SharedGroupRepositoryProvider);
      final currentGroup = await repository.getGroupById(groupId);

      // allowedUidに追加
      final updatedAllowedUid = List<String>.from(currentGroup.allowedUid);
      if (!updatedAllowedUid.contains(acceptorUid)) {
        updatedAllowedUid.add(acceptorUid);
      }

      // メンバーリストに追加
      final updatedMembers =
          List<SharedGroupMember>.from(currentGroup.members ?? []);
      if (!updatedMembers.any((m) => m.memberId == acceptorUid)) {
        updatedMembers.add(
          SharedGroupMember(
            memberId: acceptorUid,
            name: finalAcceptorName,
            contact: '',
            role: SharedGroupRole.member,
            isSignedIn: true,
            invitationStatus: InvitationStatus.accepted,
            acceptedAt: DateTime.now(),
          ),
        );
      }

      // Firestoreに更新
      await FirebaseFirestore.instance
          .collection('SharedGroups')
          .doc(groupId)
          .update({
        'allowedUid': updatedAllowedUid,
        'members': updatedMembers
            .map((m) => {
                  'memberId': m.memberId,
                  'name': m.name,
                  'contact': m.contact,
                  'role': m.role.name,
                  'isSignedIn': m.isSignedIn,
                  'invitationStatus': m.invitationStatus.name,
                  'acceptedAt': m.acceptedAt?.toIso8601String(),
                })
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ [OWNER] Firestore更新完了: $acceptorUid を追加');

      // Hiveにも更新
      final updatedGroup = currentGroup.copyWith(
        allowedUid: updatedAllowedUid,
        members: updatedMembers,
      );
      await repository.updateGroup(groupId, updatedGroup);

      AppLogger.info('✅ [OWNER] Hive更新完了: グループ更新完了');
    } catch (e) {
      AppLogger.error('❌ [OWNER] グループ更新エラー: $e');
      rethrow;
    }
  }

  /// 特定グループをFirestoreから取得してHiveに同期
  Future<void> _syncSpecificGroupFromFirestore(String groupId) async {
    try {
      AppLogger.info(
          '🔄 [NOTIFICATION] グループ同期開始: ${AppLogger.maskGroupId(groupId)}');

      // 🔥 共通ユーティリティでFirestoreから取得
      final group = await FirestoreHelper.fetchGroup(groupId);

      if (group == null) {
        AppLogger.warning(
            '⚠️ [NOTIFICATION] グループが存在しません: ${AppLogger.maskGroupId(groupId)}');
        return;
      }

      AppLogger.info('🔍 [NOTIFICATION] 同期グループallowedUid: ${group.allowedUid}');

      // 🔥 CRITICAL FIX: Hiveにのみ保存（Firestoreへの逆書き込みを防ぐ）
      final repository = _ref.read(SharedGroupRepositoryProvider);

      // FirestoreRepositoryの場合は、Hive Boxに直接書き込む
      if (repository is FirestoreSharedGroupRepository) {
        final SharedGroupBox = _ref.read(SharedGroupBoxProvider);
        await SharedGroupBox.put(groupId, group);
        AppLogger.info(
            '✅ [NOTIFICATION] HiveのみにGroup保存（Firestore書き戻し回避）: ${group.groupName}');
      } else {
        // HiveRepositoryの場合は通常のupdateを使用
        await repository.updateGroup(groupId, group);
        AppLogger.info(
            '✅ [NOTIFICATION] グループ同期完了: ${AppLogger.maskGroup(group.groupName, group.groupId)}');
      }
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] グループ同期エラー: $e');
    }
  }

  /// 通知を送信
  Future<void> sendNotification({
    required String targetUserId,
    required NotificationType type,
    required String groupId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.error('❌ [NOTIFICATION] 認証なし - 送信スキップ');
        return;
      }

      // 🔥 複数デバイス対応: 同じユーザーでも別デバイスに通知を送信する
      // （マルチデバイスUXのため、自分自身への送信制限を削除）

      final notificationData = {
        'userId': targetUserId,
        'type': type.value,
        'groupId': groupId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? currentUser.email ?? 'Unknown',
      };

      if (metadata != null) {
        notificationData['metadata'] = metadata;
      }

      AppLogger.info(
          '🔔 [NOTIFICATION] Firestoreドキュメント作成: type=${type.value}, target=${AppLogger.maskUserId(targetUserId)}');
      await _firestore.collection('notifications').add(notificationData);

      AppLogger.info(
          '📤 [NOTIFICATION] 送信完了: ${AppLogger.maskUserId(targetUserId)} - ${type.value}');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] 送信エラー: $e');
    }
  }

  /// グループの全メンバーに通知を送信
  Future<void> sendNotificationToGroup({
    required String groupId,
    required NotificationType type,
    required String message,
    List<String>? excludeUserIds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // グループ情報を取得
      final groupDoc =
          await _firestore.collection('SharedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        AppLogger.error(
            '❌ [NOTIFICATION] グループが見つかりません: ${AppLogger.maskGroupId(groupId)}');
        return;
      }

      final groupData = groupDoc.data()!;
      final members =
          List<Map<String, dynamic>>.from(groupData['members'] ?? []);

      AppLogger.info(
          '📢 [NOTIFICATION] グループメンバーへ一斉送信: ${AppLogger.maskGroupId(groupId)} (${members.length}人)');
      AppLogger.info('📢 [NOTIFICATION] 送信タイプ: ${type.value}');
      AppLogger.info('📢 [NOTIFICATION] メッセージ: $message');

      int sentCount = 0;
      // 各メンバーに通知
      for (var member in members) {
        final memberId = member['memberId'] as String?;
        if (memberId == null) continue;

        // 除外リストチェック
        if (excludeUserIds != null && excludeUserIds.contains(memberId)) {
          AppLogger.info(
              '⏭️ [NOTIFICATION] スキップ（除外リスト）: ${AppLogger.maskUserId(memberId)}');
          continue;
        }

        AppLogger.info(
            '📤 [NOTIFICATION] 送信中 [${sentCount + 1}/${members.length}]: ${AppLogger.maskUserId(memberId)}');

        await sendNotification(
          targetUserId: memberId,
          type: type,
          groupId: groupId,
          message: message,
          metadata: metadata,
        );
        sentCount++;
      }

      AppLogger.info('✅ [NOTIFICATION] グループへの一斉送信完了: $sentCount件送信');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] グループ送信エラー: $e');
    }
  }

  /// リスト作成通知を送信
  Future<void> sendListCreatedNotification({
    required String groupId,
    required String listId,
    required String listName,
    required String creatorName,
  }) async {
    try {
      AppLogger.info('📝 [NOTIFICATION] リスト作成通知送信: $listName');

      await sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.listCreated,
        message: '$creatorName が「$listName」を作成しました',
        metadata: {
          'listId': listId,
          'listName': listName,
          'creatorName': creatorName,
        },
      );

      AppLogger.info('✅ [NOTIFICATION] リスト作成通知送信完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] リスト作成通知エラー: $e');
    }
  }

  /// リスト削除通知を送信
  Future<void> sendListDeletedNotification({
    required String groupId,
    required String listId,
    required String listName,
    required String deleterName,
  }) async {
    try {
      AppLogger.info('🗑️ [NOTIFICATION] リスト削除通知送信: $listName');

      await sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.listDeleted,
        message: '$deleterName が「$listName」を削除しました',
        metadata: {
          'listId': listId,
          'listName': listName,
          'deleterName': deleterName,
        },
      );

      AppLogger.info('✅ [NOTIFICATION] リスト削除通知送信完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] リスト削除通知エラー: $e');
    }
  }

  /// リスト名変更通知を送信
  Future<void> sendListRenamedNotification({
    required String groupId,
    required String listId,
    required String oldName,
    required String newName,
    required String renamerName,
  }) async {
    try {
      AppLogger.info('✏️ [NOTIFICATION] リスト名変更通知送信: $oldName → $newName');

      await sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.listRenamed,
        message: '$renamerName が「$oldName」を「$newName」に変更しました',
        metadata: {
          'listId': listId,
          'oldName': oldName,
          'newName': newName,
          'renamerName': renamerName,
        },
      );

      AppLogger.info('✅ [NOTIFICATION] リスト名変更通知送信完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] リスト名変更通知エラー: $e');
    }
  }

  /// グループ削除通知を送信
  Future<void> sendGroupDeletedNotification({
    required String groupId,
    required String groupName,
    required String deleterName,
  }) async {
    try {
      AppLogger.info('🗑️ [NOTIFICATION] グループ削除通知送信: $groupName');

      await sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.groupDeleted,
        message: '$deleterName が「$groupName」を削除しました',
        metadata: {
          'groupName': groupName,
          'deleterName': deleterName,
        },
      );

      AppLogger.info('✅ [NOTIFICATION] グループ削除通知送信完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] グループ削除通知エラー: $e');
    }
  }

  /// アイテム追加通知を送信
  Future<void> sendItemAddedNotification({
    required String groupId,
    required String listId,
    required String listName,
    required String itemName,
    required String adderName,
  }) async {
    try {
      AppLogger.info('➕ [NOTIFICATION] アイテム追加通知送信: $itemName');

      await sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.itemAdded,
        message: '$adderName が「$listName」に「$itemName」を追加しました',
        metadata: {
          'listId': listId,
          'listName': listName,
          'itemName': itemName,
          'adderName': adderName,
        },
      );

      AppLogger.info('✅ [NOTIFICATION] アイテム追加通知送信完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] アイテム追加通知エラー: $e');
    }
  }

  /// アイテム削除通知を送信
  Future<void> sendItemRemovedNotification({
    required String groupId,
    required String listId,
    required String listName,
    required String itemName,
    required String removerName,
  }) async {
    try {
      AppLogger.info('➖ [NOTIFICATION] アイテム削除通知送信: $itemName');

      await sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.itemRemoved,
        message: '$removerName が「$listName」から「$itemName」を削除しました',
        metadata: {
          'listId': listId,
          'listName': listName,
          'itemName': itemName,
          'removerName': removerName,
        },
      );

      AppLogger.info('✅ [NOTIFICATION] アイテム削除通知送信完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] アイテム削除通知エラー: $e');
    }
  }

  /// アイテム購入通知を送信
  Future<void> sendItemPurchasedNotification({
    required String groupId,
    required String listId,
    required String listName,
    required String itemName,
    required String purchaserName,
  }) async {
    try {
      AppLogger.info('✅ [NOTIFICATION] アイテム購入通知送信: $itemName');

      await sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.itemPurchased,
        message: '$purchaserName が「$listName」の「$itemName」を購入しました',
        metadata: {
          'listId': listId,
          'listName': listName,
          'itemName': itemName,
          'purchaserName': purchaserName,
        },
      );

      AppLogger.info('✅ [NOTIFICATION] アイテム購入通知送信完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] アイテム購入通知エラー: $e');
    }
  }

  /// 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('✅ [NOTIFICATION] 既読: $notificationId');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] 既読エラー: $e');
    }
  }

  /// 確認通知を待機（最大10秒）
  Future<bool> waitForSyncConfirmation({
    required String groupId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.error('❌ [NOTIFICATION] 認証なし - 確認待機スキップ');
        return false;
      }

      AppLogger.info('⏳ [NOTIFICATION] 確認通知待機中... (最大${timeout.inSeconds}秒)');

      final completer = Completer<bool>();
      StreamSubscription<QuerySnapshot>? subscription;

      // タイムアウトタイマー
      final timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          AppLogger.warning('⚠️ [NOTIFICATION] 確認通知タイムアウト');
          subscription?.cancel();
          completer.complete(false);
        }
      });

      // 確認通知を待機
      subscription = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: NotificationType.syncConfirmation.value)
          .where('groupId', isEqualTo: groupId)
          .where('read', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docChanges.isNotEmpty && !completer.isCompleted) {
          AppLogger.info('✅ [NOTIFICATION] 確認通知受信！');
          timer.cancel();
          subscription?.cancel();

          // 確認通知を既読にする
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              markAsRead(change.doc.id);
            }
          }

          completer.complete(true);
        }
      });

      final result = await completer.future;
      return result;
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] 確認待機エラー: $e');
      return false;
    }
  }

  /// 古い通知をクリーンアップ（7日以上前の既読通知を削除）
  Future<void> cleanupOldNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: true)
          .where('timestamp', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.info(
          '🧹 [NOTIFICATION] 古い通知を削除: ${oldNotifications.docs.length}件');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] クリーンアップエラー: $e');
    }
  }

  /// リスナーが起動中かどうか
  bool get isListening => _isListening;
}
