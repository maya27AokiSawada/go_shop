import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import 'user_initialization_service.dart';
import '../providers/purchase_group_provider.dart';
import '../models/purchase_group.dart';

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
  syncConfirmation('sync_confirmation'); // 同期確認通知

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
      AppLogger.info('🔔 [NOTIFICATION] 既にリスナー起動中 (UID: ${currentUser.uid})');
      return;
    }

    AppLogger.info('🔔 [NOTIFICATION] リアルタイム通知リスナー起動開始...');
    AppLogger.info('🔔 [NOTIFICATION] ユーザーUID: ${currentUser.uid}');
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
          AppLogger.info('🔔 [NOTIFICATION] 変更タイプ: ${change.type}');
          if (change.type == DocumentChangeType.added) {
            final notification = NotificationData.fromFirestore(change.doc);
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
          // 新メンバー追加通知 - 特定グループのみFirestoreから再取得
          AppLogger.info('👥 [NOTIFICATION] 新メンバー追加通知を受信！');
          final groupId = notification.metadata?['groupId'] as String?;
          AppLogger.info('👥 [NOTIFICATION] グループID: $groupId');
          AppLogger.info(
              '👥 [NOTIFICATION] 新メンバーID: ${notification.metadata?['newMemberId']}');
          AppLogger.info(
              '👥 [NOTIFICATION] 新メンバー名: ${notification.metadata?['newMemberName']}');
          if (groupId != null) {
            AppLogger.info('🔄 [NOTIFICATION] グループ同期開始: $groupId');
            await _syncSpecificGroupFromFirestore(groupId);

            // 受諾者に確認通知を送信
            final acceptorUid =
                notification.metadata?['acceptorUid'] as String?;
            if (acceptorUid != null) {
              AppLogger.info('📤 [NOTIFICATION] 確認通知を送信: $acceptorUid');
              await sendNotification(
                targetUserId: acceptorUid,
                type: NotificationType.syncConfirmation,
                groupId: groupId,
                message: 'グループ同期完了',
                metadata: {'confirmedBy': currentUser.uid},
              );
            }
          } else {
            // groupIdがない場合は全体同期
            final userInitService =
                _ref.read(userInitializationServiceProvider);
            await userInitService.syncFromFirestoreToHive(currentUser);
          }

          // UI更新（全グループと選択中グループの両方を更新）
          _ref.invalidate(allGroupsProvider);
          _ref.invalidate(selectedGroupProvider);
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
      }

      // 通知を既読にする
      await markAsRead(notification.id);
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] 処理エラー: $e');
    }
  }

  /// 特定グループをFirestoreから取得してHiveに同期
  Future<void> _syncSpecificGroupFromFirestore(String groupId) async {
    try {
      AppLogger.info('🔄 [NOTIFICATION] グループ同期開始: $groupId');

      // Firestoreから最新のグループデータを取得
      final groupDoc =
          await _firestore.collection('purchaseGroups').doc(groupId).get();

      if (!groupDoc.exists) {
        AppLogger.warning('⚠️ [NOTIFICATION] グループが存在しません: $groupId');
        return;
      }

      // PurchaseGroupオブジェクトに変換（Timestamp変換）
      final groupData =
          _convertTimestamps(Map<String, dynamic>.from(groupDoc.data()!));

      final group = PurchaseGroup.fromJson(groupData);

      AppLogger.info('🔍 [NOTIFICATION] 同期グループallowedUid: ${group.allowedUid}');

      // Hiveに保存
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      await repository.updateGroup(groupId, group);

      AppLogger.info('✅ [NOTIFICATION] グループ同期完了: ${group.groupName}');
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

      // 自分自身には送信しない
      if (targetUserId == currentUser.uid) {
        AppLogger.info('📭 [NOTIFICATION] 自分自身への送信スキップ');
        return;
      }

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

      await _firestore.collection('notifications').add(notificationData);

      AppLogger.info('📤 [NOTIFICATION] 送信完了: $targetUserId - ${type.value}');
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
          await _firestore.collection('purchaseGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        AppLogger.error('❌ [NOTIFICATION] グループが見つかりません: $groupId');
        return;
      }

      final groupData = groupDoc.data()!;
      final members =
          List<Map<String, dynamic>>.from(groupData['members'] ?? []);

      AppLogger.info(
          '📢 [NOTIFICATION] グループメンバーへ一斉送信: $groupId (${members.length}人)');

      // 各メンバーに通知
      for (var member in members) {
        final memberId = member['memberId'] as String?;
        if (memberId == null) continue;

        // 除外リストチェック
        if (excludeUserIds != null && excludeUserIds.contains(memberId)) {
          continue;
        }

        await sendNotification(
          targetUserId: memberId,
          type: type,
          groupId: groupId,
          message: message,
          metadata: metadata,
        );
      }

      AppLogger.info('✅ [NOTIFICATION] グループへの一斉送信完了');
    } catch (e) {
      AppLogger.error('❌ [NOTIFICATION] グループ送信エラー: $e');
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

  /// Firestore Timestampを再帰的にISO8601文字列に変換
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is Timestamp) {
        // Timestamp → ISO8601文字列
        converted[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        // ネストされたMapを再帰的に変換
        converted[key] = _convertTimestamps(Map<String, dynamic>.from(value));
      } else if (value is List) {
        // Listの要素も変換
        converted[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map) {
            return _convertTimestamps(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    });

    return converted;
  }

  /// リスナーが起動中かどうか
  bool get isListening => _isListening;
}
