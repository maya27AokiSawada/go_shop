import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'user_initialization_service.dart';
import '../providers/shared_group_provider.dart'; // selectedGroupIdProvider, SharedGroupRepositoryProvider
import '../providers/current_list_provider.dart'; // currentListProvider
import '../datastore/hive_shared_group_repository.dart'; // hiveSharedGroupRepositoryProvider
import '../datastore/firestore_shared_group_repository.dart';
import '../models/shared_group.dart';

/// 通知サービスプロバイダー
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// 通知タイプ
enum NotificationType {
  groupMemberAdded('group_member_added'),
  groupUpdated('group_updated'),
  groupLeaveRequested('group_leave_requested'),
  groupLeft('group_left'),
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
  itemPurchased('item_purchased'), // 購入完了

  // ホワイトボード関連通知（即時送信）
  whiteboardUpdated('whiteboard_updated'); // ホワイトボード更新

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
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isListening = false;

  /// コンストラクタ
  ///
  /// [firestore] と [auth] はテスト用の依存性注入に使用。
  /// 省略時は本番環境のインスタンスを使用（後方互換性維持）。
  NotificationService(
    this._ref, {
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
        AppLogger.info('🔔 [NOTIFICATION] 現在のドキュメント数: ${snapshot.docs.length}');

        for (var change in snapshot.docChanges) {
          AppLogger.info(
              '🔔 [NOTIFICATION] 変更タイプ: ${change.type}, docId: ${change.doc.id}');

          // 🔥 FIX: ドキュメントの詳細情報をログ出力
          final data = change.doc.data();
          AppLogger.info('🔔 [NOTIFICATION] 通知データ詳細:');
          AppLogger.info('   - type: ${data?['type']}');
          AppLogger.info(
              '   - userId: ${AppLogger.maskUserId(data?['userId'])}');
          AppLogger.info(
              '   - groupId: ${AppLogger.maskGroupId(data?['groupId'])}');
          AppLogger.info('   - read: ${data?['read']}');
          AppLogger.info('   - metadata: ${data?['metadata']}');

          if (change.type == DocumentChangeType.added) {
            final notification = NotificationData.fromFirestore(change.doc);

            // 🔥 CRITICAL FIX: リスナー起動前の既存通知も処理する（招待受諾漏れ防止）
            // リスナー起動前の通知は、アプリが閉じていた間に届いた重要な通知
            // （招待受諾、メンバー追加など）のため、必ず処理する必要がある
            if (notification.timestamp.isBefore(listenerStartTime)) {
              AppLogger.info(
                  '📬 [NOTIFICATION] リスナー起動前の通知を処理: ${notification.id} (${notification.timestamp})');
              AppLogger.info(
                  '   → type=${notification.type.value}, groupId=${notification.groupId}');
            }

            AppLogger.info(
                '🔔 [NOTIFICATION] 通知検出: type=${notification.type}, groupId=${notification.groupId}');
            AppLogger.info('🔔 [NOTIFICATION] _handleNotification()を呼び出します...');
            _handleNotification(notification);
            AppLogger.info('✅ [NOTIFICATION] _handleNotification()完了');
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

  /// グループ関連の未読通知があるかチェック
  ///
  /// アプリ起動時にFirestore同期が必要か判断するために使用
  /// 最後に同期した時刻以降にグループ関連の通知がある場合にtrueを返す
  ///
  /// 🔥 重要: readフィールドではなくtimestampを使用
  /// 理由: 通知はFirestoreで全端末共有されるため、
  ///       一度既読になると他端末では検出できなくなる
  Future<bool> hasUnreadGroupNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      AppLogger.info('🔕 [NOTIFICATION] 認証なし - 未読通知チェックスキップ');
      return false;
    }

    try {
      AppLogger.info('🔍 [NOTIFICATION] 最終同期時刻以降のグループ通知チェック開始...');

      // 最終同期時刻を取得（なければ24時間前）
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt('last_firestore_sync_time') ??
          (DateTime.now()
              .subtract(const Duration(hours: 24))
              .millisecondsSinceEpoch);
      final lastSyncTime = Timestamp.fromMillisecondsSinceEpoch(lastSyncMs);

      AppLogger.info(
          '📅 [NOTIFICATION] 最終同期: ${DateTime.fromMillisecondsSinceEpoch(lastSyncMs)}');

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('timestamp', isGreaterThan: lastSyncTime) // ← 時刻ベース
          .get()
          .timeout(const Duration(seconds: 5));

      AppLogger.info('📬 [NOTIFICATION] 最終同期以降の通知総数: ${snapshot.docs.length}');

      // グループ関連の通知タイプ
      final groupTypes = [
        'group_member_added', // グループ作成またはメンバー追加
        'group_updated', // グループ更新
        'group_deleted', // グループ削除
        'invitation_accepted', // 招待受諾
      ];

      int groupNotificationCount = 0;
      for (final doc in snapshot.docs) {
        final type = doc.data()['type'] as String?;
        if (type != null && groupTypes.contains(type)) {
          groupNotificationCount++;
          final message = doc.data()['message'] as String? ?? '';
          final timestamp = doc.data()['timestamp'] as Timestamp?;
          AppLogger.info('  - $type ($timestamp): $message');
        }
      }

      AppLogger.info('📊 [NOTIFICATION] グループ関連通知: $groupNotificationCount件');
      return groupNotificationCount > 0;
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] 通知チェックエラー: $e');
      return false; // エラー時は安全側に倒す（同期しない）
    }
  }

  /// 最終同期時刻を更新
  /// forceSyncProvider完了後に呼び出す
  Future<void> updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('last_firestore_sync_time', now);
      AppLogger.info(
          '⏰ [NOTIFICATION] 最終同期時刻を更新: ${DateTime.fromMillisecondsSinceEpoch(now)}');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] 最終同期時刻更新エラー: $e');
    }
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
        case NotificationType.groupLeaveRequested:
          AppLogger.info('🚪 [NOTIFICATION] グループ退出リクエスト受信');
          await _handleGroupLeaveRequested(notification, currentUser);
          break;

        case NotificationType.groupLeft:
          AppLogger.info('🚪 [NOTIFICATION] グループ退出確定通知受信');
          await _handleGroupLeft(notification);
          break;

        case NotificationType.groupMemberAdded:
          // 🔥 FIX: 詳細なデバッグログを追加
          AppLogger.info('========== groupMemberAdded 通知処理開始 ==========');
          AppLogger.info(
              '   - groupId: ${AppLogger.maskGroupId(notification.groupId)}');
          AppLogger.info('   - metadata: ${notification.metadata}');
          AppLogger.info(
              '   - metadata.acceptorUid: ${notification.metadata?['acceptorUid']}');

          // 🔥 CRITICAL FIX: 自分が受諾者の場合と招待元の場合を区別
          final acceptorUid = notification.metadata?['acceptorUid'] as String?;

          // metadataにacceptorUidがあり、かつ自分が受諾者でない場合は招待元として処理
          if (acceptorUid != null && currentUser.uid != acceptorUid) {
            // 招待元: 新メンバー追加処理
            AppLogger.info('========================================');
            AppLogger.info('👥 [NOTIFICATION] 招待元として新メンバー追加通知を受信！');
            AppLogger.info('========================================');

            final groupId = notification.groupId;
            final acceptorName =
                notification.metadata?['acceptorName'] as String? ?? 'ユーザー';

            AppLogger.info(
                '   - acceptorUid: ${AppLogger.maskUserId(acceptorUid)}');
            AppLogger.info(
                '   - acceptorName: ${AppLogger.maskName(acceptorName)}');

            if (groupId.isNotEmpty) {
              AppLogger.info('👥 [NOTIFICATION] _addMemberToGroup()を呼び出します...');
              await _addMemberToGroup(groupId, acceptorUid, acceptorName);
              AppLogger.info('✅ [NOTIFICATION] _addMemberToGroup()完了');

              final invitationId =
                  notification.metadata?['invitationId'] as String?;
              if (invitationId != null) {
                AppLogger.info('📝 [NOTIFICATION] 招待使用回数更新: $invitationId');
                await _updateInvitationUsage(
                    groupId: groupId,
                    invitationId: invitationId,
                    acceptorUid: acceptorUid);
                AppLogger.info('✅ [NOTIFICATION] 招待使用回数更新完了');
              }

              AppLogger.info('📤 [NOTIFICATION] 受諾者に確認通知を送信...');
              await sendNotification(
                  targetUserId: acceptorUid,
                  type: NotificationType.syncConfirmation,
                  groupId: groupId,
                  message: 'グループへの参加が承認されました',
                  metadata: {
                    'confirmedBy': currentUser.uid,
                    'groupName': notification.metadata?['groupName']
                  });
              AppLogger.info('✅ [NOTIFICATION] 受諾者への確認通知送信完了');
            } else {
              AppLogger.error(
                  '❌ [NOTIFICATION] groupIdまたはacceptorUidが無効: groupId=$groupId, acceptorUid=$acceptorUid');
            }
          } else {
            // 既存メンバー: 同期処理
            AppLogger.info('👥 [NOTIFICATION] 既存メンバーとして同期通知を受信！');
            AppLogger.info(
                '   - groupId: ${AppLogger.maskGroupId(notification.groupId)}');
            AppLogger.info('� [NOTIFICATION] Firestore→Hive同期開始...');
            final userInitService =
                _ref.read(userInitializationServiceProvider);
            await userInitService.syncFromFirestoreToHive(currentUser);
            AppLogger.info('✅ [NOTIFICATION] Firestore→Hive同期完了');
          }
          // UI更新
          AppLogger.info('🔄 [NOTIFICATION] プロバイダー無効化開始...');
          _ref.invalidate(allGroupsProvider);
          _ref.invalidate(selectedGroupProvider);
          AppLogger.info('✅ [NOTIFICATION] プロバイダー無効化完了');
          AppLogger.info('========== groupMemberAdded 通知処理完了 ==========');
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
          // グループ削除通知 - メンバー側でローカル削除
          AppLogger.info('🗑️ [NOTIFICATION] グループ削除通知受信');
          final deletedGroupId = notification.groupId;
          final groupName =
              notification.metadata?['groupName'] as String? ?? 'グループ';

          AppLogger.info(
              '🗑️ [NOTIFICATION] 削除対象グループ: ${AppLogger.maskGroup(groupName, deletedGroupId)}');

          try {
            // Hiveからグループを削除
            final hiveRepository = _ref.read(hiveSharedGroupRepositoryProvider);
            await hiveRepository.deleteGroup(deletedGroupId);
            AppLogger.info(
                '✅ [NOTIFICATION] Hiveからグループ削除完了: ${AppLogger.maskGroupId(deletedGroupId)}');

            // 選択中のグループが削除された場合は別のグループを選択
            final selectedGroupId = _ref.read(selectedGroupIdProvider);
            if (selectedGroupId == deletedGroupId) {
              AppLogger.info('⚠️ [NOTIFICATION] 選択中グループが削除されました - 別のグループを選択');

              // 他のグループがあるか確認
              final allGroups = await hiveRepository.getAllGroups();
              if (allGroups.isNotEmpty) {
                // 最初のグループを選択
                _ref
                    .read(selectedGroupIdProvider.notifier)
                    .selectGroup(allGroups.first.groupId);
                AppLogger.info(
                    '✅ [NOTIFICATION] 別のグループに切替: ${AppLogger.maskGroup(allGroups.first.groupName, allGroups.first.groupId)}');
              } else {
                // 🔥 REMOVED: デフォルトグループ機能廃止
                AppLogger.info('📝 [NOTIFICATION] グループが0個→初回セットアップ画面表示');
              }
            }

            // UI更新
            _ref.invalidate(allGroupsProvider);
            _ref.invalidate(selectedGroupProvider);
            AppLogger.info('✅ [NOTIFICATION] グループ削除通知処理完了');
          } catch (e) {
            AppLogger.error('❌ [NOTIFICATION] グループ削除処理エラー: $e');
          }
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

          // 削除されたリストのIDを取得
          final deletedListId = notification.metadata?['listId'] as String?;
          AppLogger.info('🗑️ [NOTIFICATION] 削除されたリストID: $deletedListId');

          // 削除されたリストが現在選択中の場合、currentListProviderをクリア
          if (deletedListId != null) {
            final currentList = _ref.read(currentListProvider);
            if (currentList?.listId == deletedListId) {
              AppLogger.info('🗑️ [NOTIFICATION] 選択中のリストが削除されたため、クリア実行');
              await _ref.read(currentListProvider.notifier).clearListForGroup(
                    notification.groupId,
                  );
            }
          }

          // グループのリスト一覧を更新
          _ref.invalidate(allGroupsProvider);
          AppLogger.info('✅ [NOTIFICATION] リスト削除通知処理完了');
          break;

        case NotificationType.listRenamed:
          // リスト名変更通知
          AppLogger.info('✏️ [NOTIFICATION] リスト名変更通知受信');
          _ref.invalidate(allGroupsProvider);
          AppLogger.info('✅ [NOTIFICATION] リスト名変更通知処理完了');
          break;

        case NotificationType.whiteboardUpdated:
          // ホワイトボード更新通知
          await _handleWhiteboardUpdated(notification);
          break;
      }

      // 通知を既読にする
      await markAsRead(notification.id);
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] 処理エラー: $e');
    }
  }

  Future<void> _handleGroupLeaveRequested(
      NotificationData notification, User currentUser) async {
    final requesterUid = notification.metadata?['requesterUid'] as String?;
    final requesterName =
        notification.metadata?['requesterName'] as String? ?? 'ユーザー';

    if (requesterUid == null || requesterUid.isEmpty) {
      AppLogger.error('❌ [GROUP_LEAVE_REQUEST] requesterUid がありません');
      return;
    }

    final firestoreRepo = FirestoreSharedGroupRepository(_firestore);
    final currentGroup = await firestoreRepo.getGroupById(notification.groupId);

    if (currentGroup.ownerUid != currentUser.uid) {
      AppLogger.info('ℹ️ [GROUP_LEAVE_REQUEST] オーナー端末ではないため処理スキップ');
      return;
    }

    final existingMember = currentGroup.members
        ?.where((member) => member.memberId == requesterUid)
        .toList();
    final memberToRemove = (existingMember != null && existingMember.isNotEmpty)
        ? existingMember.first
        : SharedGroupMember(
            memberId: requesterUid,
            name: requesterName,
            contact: '',
            role: SharedGroupRole.member,
            isSignedIn: true,
            invitationStatus: InvitationStatus.accepted,
          );

    final updatedGroup = currentGroup.removeMember(memberToRemove);

    await firestoreRepo.updateGroup(currentGroup.groupId, updatedGroup);

    final hiveRepository = _ref.read(hiveSharedGroupRepositoryProvider);
    await hiveRepository.updateGroup(updatedGroup.groupId, updatedGroup);

    _ref.invalidate(allGroupsProvider);
    _ref.invalidate(selectedGroupProvider);

    await sendNotification(
      targetUserId: requesterUid,
      type: NotificationType.groupLeft,
      groupId: updatedGroup.groupId,
      message: '「${updatedGroup.groupName}」から退出しました',
      metadata: {
        'groupName': updatedGroup.groupName,
        'requesterUid': requesterUid,
        'requesterName': requesterName,
      },
    );

    await sendNotificationToGroup(
      groupId: updatedGroup.groupId,
      type: NotificationType.groupUpdated,
      message: '$requesterName が「${updatedGroup.groupName}」から退出しました',
      metadata: {
        'groupName': updatedGroup.groupName,
        'leftUserUid': requesterUid,
        'leftUserName': requesterName,
      },
    );

    AppLogger.info('✅ [GROUP_LEAVE_REQUEST] 退出処理完了: ${updatedGroup.groupId}');
  }

  Future<void> _handleGroupLeft(NotificationData notification) async {
    final hiveRepository = _ref.read(hiveSharedGroupRepositoryProvider);
    await hiveRepository.deleteGroup(notification.groupId);

    final selectedGroupId = _ref.read(selectedGroupIdProvider);
    if (selectedGroupId == notification.groupId) {
      _ref.read(selectedGroupIdProvider.notifier).clearSelection();
      await _ref.read(currentListProvider.notifier).clearListForGroup(
            notification.groupId,
          );
    }

    _ref.invalidate(allGroupsProvider);
    _ref.invalidate(selectedGroupProvider);

    AppLogger.info('✅ [GROUP_LEFT] Hiveから退出済みグループを削除: ${notification.groupId}');
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

      // 🔥 FIX: メンバー追加の伝播確認（三人目招待時のpermission-denied対策）
      try {
        final verifyGroup = await repository.getGroupById(groupId);
        if (verifyGroup.allowedUid.contains(acceptorUid)) {
          AppLogger.info('✅ [OWNER] メンバー追加の伝播確認成功');
        } else {
          throw Exception('メンバーがまだallowedUidに含まれていません');
        }
      } catch (verifyError) {
        AppLogger.warning('⚠️ [OWNER] メンバー追加の伝播確認失敗、リトライします: $verifyError');
        await Future.delayed(const Duration(milliseconds: 100));
        final verifyGroup = await repository.getGroupById(groupId);
        if (!verifyGroup.allowedUid.contains(acceptorUid)) {
          AppLogger.error('❌ [OWNER] メンバー追加の伝播確認リトライ失敗');
          throw Exception('メンバー追加の伝播確認に失敗しました');
        }
        AppLogger.info('✅ [OWNER] メンバー追加の伝播確認リトライ成功');
      }

      // Hiveにも更新
      final updatedGroup = currentGroup.copyWith(
        allowedUid: updatedAllowedUid,
        members: updatedMembers,
      );
      await repository.updateGroup(groupId, updatedGroup);

      AppLogger.info('✅ [OWNER] Hive更新完了: グループ更新完了');

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
            message: '$finalAcceptorName さんが「${currentGroup.groupName}」に参加しました',
            metadata: {
              'groupName': currentGroup.groupName,
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

      // 🔥 CRITICAL FIX: 受諾者自身にも承認通知を送信
      AppLogger.info('📤 [OWNER] 受諾者への承認通知送信開始');
      try {
        await sendNotification(
          targetUserId: acceptorUid,
          groupId: groupId,
          type: NotificationType.groupMemberAdded,
          message: '「${currentGroup.groupName}」への参加が承認されました',
          metadata: {
            'groupName': currentGroup.groupName,
            'acceptorUid': acceptorUid,
            'acceptorName': finalAcceptorName,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        AppLogger.info(
            '✅ [OWNER] 受諾者への承認通知送信完了: ${AppLogger.maskUserId(acceptorUid)}');
      } catch (e) {
        AppLogger.error('❌ [OWNER] 受諾者への承認通知送信エラー: $e');
      }
    } catch (e) {
      AppLogger.error('❌ [OWNER] グループ更新エラー: $e');
      rethrow;
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

      AppLogger.info('========================================');
      AppLogger.info('🔔 [NOTIFICATION] 送信処理開始');
      AppLogger.info('   - type: ${type.value}');
      AppLogger.info(
          '   - targetUserId: ${AppLogger.maskUserId(targetUserId)}');
      AppLogger.info('   - groupId: ${AppLogger.maskGroupId(groupId)}');
      AppLogger.info('   - message: $message');
      AppLogger.info('   - metadata: $metadata');
      AppLogger.info('========================================');

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

      AppLogger.info('🔔 [NOTIFICATION] Firestoreドキュメント作成開始: notifications/');
      AppLogger.info('   - notificationData: $notificationData');

      final docRef =
          await _firestore.collection('notifications').add(notificationData);

      AppLogger.info('✅ [NOTIFICATION] Firestore保存成功: docId=${docRef.id}');
      AppLogger.info(
          '📤 [NOTIFICATION] 送信完了: ${AppLogger.maskUserId(targetUserId)} - ${type.value}');
    } catch (e, stackTrace) {
      AppLogger.error('❌ [NOTIFICATION] 送信エラー: $e');
      AppLogger.error('❌ [NOTIFICATION] スタックトレース: $stackTrace');
      rethrow;
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

  /// 招待使用回数を更新（招待元として実行）
  Future<void> _updateInvitationUsage({
    required String groupId,
    required String invitationId,
    required String acceptorUid,
  }) async {
    try {
      AppLogger.info(
          '📊 [INVITATION] 招待使用回数を更新: invitationId=$invitationId, acceptorUid=${AppLogger.maskUserId(acceptorUid)}');

      // SharedGroups/{groupId}/invitations/{invitationId}サブコレクション
      final invitationRef = _firestore
          .collection('SharedGroups')
          .doc(groupId)
          .collection('invitations')
          .doc(invitationId);

      // 現在の使用回数を確認してステータスを決定
      final invitationDoc = await invitationRef.get();
      final currentUses = (invitationDoc.data()?['currentUses'] as int?) ?? 0;
      final maxUses = (invitationDoc.data()?['maxUses'] as int?) ?? 5;
      final newCurrentUses = currentUses + 1;

      // ステータスの決定: maxUsesに達したら'used'、それ以外は'accepted'
      final newStatus = newCurrentUses >= maxUses ? 'used' : 'accepted';

      AppLogger.info(
          '📊 [INVITATION] 使用回数: $currentUses → $newCurrentUses / $maxUses (status: $newStatus)');

      // Atomic update: currentUsesをインクリメント、usedBy配列に追加
      await invitationRef.update({
        'currentUses': FieldValue.increment(1),
        'usedBy': FieldValue.arrayUnion([acceptorUid]),
        'lastUsedAt': FieldValue.serverTimestamp(),
        'status': newStatus,
      });

      AppLogger.info('✅ [INVITATION] 招待使用回数の更新完了');
    } catch (e) {
      AppLogger.error('❌ [INVITATION] 招待使用回数の更新エラー: $e');
      // エラーが発生してもメイン処理は継続（カウント更新は副次的な処理）
    }
  }

  /// ホワイトボード更新通知を処理
  Future<void> _handleWhiteboardUpdated(NotificationData notification) async {
    try {
      AppLogger.info('🎨 [NOTIFICATION] ホワイトボード更新通知受信');

      final whiteboardId = notification.metadata?['whiteboardId'] as String?;
      final editorName =
          notification.metadata?['editorName'] as String? ?? 'ユーザー';
      final isGroupWhiteboard =
          notification.metadata?['isGroupWhiteboard'] as bool? ?? false;

      AppLogger.info('🎨 [NOTIFICATION] whiteboardId: $whiteboardId');
      AppLogger.info(
          '🎨 [NOTIFICATION] editorName: ${AppLogger.maskName(editorName)}');
      AppLogger.info('🎨 [NOTIFICATION] isGroupWhiteboard: $isGroupWhiteboard');

      // ホワイトボードプロバイダーを無効化して再取得
      if (isGroupWhiteboard) {
        // グループ共通ホワイトボードの場合
        final groupId = notification.groupId;
        AppLogger.info(
            '🎨 [NOTIFICATION] グループ共通ホワイトボードを更新: ${AppLogger.maskGroupId(groupId)}');
        // groupWhiteboardProviderを無効化（次回アクセス時に再取得）
        // 注: Provider invalidateはwhiteboard_provider.dartで実装されている想定
      } else {
        // 個人用ホワイトボードの場合
        final ownerId = notification.metadata?['ownerId'] as String?;
        AppLogger.info(
            '🎨 [NOTIFICATION] 個人用ホワイトボードを更新: ${AppLogger.maskUserId(ownerId)}');
        // personalWhiteboardProviderを無効化
      }

      AppLogger.info('✅ [NOTIFICATION] ホワイトボード更新通知処理完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] ホワイトボード更新処理エラー: $e');
    }
  }

  /// ホワイトボード更新通知を送信
  Future<void> sendWhiteboardUpdateNotification({
    required String groupId,
    required String whiteboardId,
    required bool isGroupWhiteboard,
    String? ownerId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.error('❌ [WHITEBOARD] ユーザー未認証 - 通知送信スキップ');
        return;
      }

      final editorName = currentUser.displayName ?? 'ユーザー';

      AppLogger.info('📤 [WHITEBOARD] ホワイトボード更新通知を送信開始');
      AppLogger.info(
          '📤 [WHITEBOARD] groupId: ${AppLogger.maskGroupId(groupId)}');
      AppLogger.info('📤 [WHITEBOARD] whiteboardId: $whiteboardId');
      AppLogger.info('📤 [WHITEBOARD] isGroupWhiteboard: $isGroupWhiteboard');
      AppLogger.info(
          '📤 [WHITEBOARD] editorName: ${AppLogger.maskName(editorName)}');

      // グループメンバーを取得
      final groupDoc =
          await _firestore.collection('SharedGroups').doc(groupId).get();

      if (!groupDoc.exists) {
        AppLogger.error(
            '❌ [WHITEBOARD] グループが存在しません: ${AppLogger.maskGroupId(groupId)}');
        return;
      }

      final groupData = groupDoc.data()!;
      final allowedUid = List<String>.from(groupData['allowedUid'] ?? []);
      final groupName = groupData['name'] as String? ?? 'グループ';

      AppLogger.info('📤 [WHITEBOARD] グループメンバー数: ${allowedUid.length}');

      // 自分以外の全メンバーに通知を送信
      final batch = _firestore.batch();
      int notificationCount = 0;

      for (final memberId in allowedUid) {
        if (memberId == currentUser.uid) {
          continue; // 自分には送信しない
        }

        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': memberId,
          'type': NotificationType.whiteboardUpdated.value,
          'groupId': groupId,
          'message': isGroupWhiteboard
              ? '${AppLogger.maskName(editorName)}さんがグループホワイトボードを更新しました'
              : '${AppLogger.maskName(editorName)}さんがホワイトボードを更新しました',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'metadata': {
            'whiteboardId': whiteboardId,
            'editorUid': currentUser.uid,
            'editorName': editorName,
            'groupName': groupName,
            'isGroupWhiteboard': isGroupWhiteboard,
            if (ownerId != null) 'ownerId': ownerId,
          },
        });

        notificationCount++;
      }

      if (notificationCount > 0) {
        await batch.commit();
        AppLogger.info('✅ [WHITEBOARD] ホワイトボード更新通知送信完了: $notificationCount件');
      } else {
        AppLogger.info('ℹ️ [WHITEBOARD] 送信対象メンバーなし（自分のみ）');
      }
    } catch (e) {
      AppLogger.error('❌ [WHITEBOARD] ホワイトボード更新通知送信エラー: $e');
    }
  }

  /// リスナーが起動中かどうか
  bool get isListening => _isListening;
}
