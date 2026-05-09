import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_group_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';
import '../l10n/l10n.dart';

/// 通知履歴画面
class NotificationHistoryPage extends ConsumerStatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  ConsumerState<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState
    extends ConsumerState<NotificationHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ストリームを State に保持することで build() のたびに再生成されないようにする。
  // authStateProvider のリフレッシュ等で build() が再呼び出されても
  // StreamBuilder が waiting にリセットされるのを防ぐ。
  Stream<QuerySnapshot>? _notificationStream;
  String? _streamUserId;

  void _initStreamIfNeeded(String userId) {
    if (_streamUserId == userId && _notificationStream != null) return;
    _streamUserId = userId;
    _notificationStream = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(texts.notificationHistory),
        ),
        body: Center(
          child: Text(texts.signInRequired),
        ),
      );
    }

    _initStreamIfNeeded(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(texts.notificationHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: texts.tooltipDeleteRead,
            onPressed: () => _clearReadNotifications(currentUser.uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            AppLogger.error('通知履歴取得エラー: ${snapshot.error}');

            // インデックスエラーの詳細を表示
            if (snapshot.error.toString().contains('failed-precondition') ||
                snapshot.error.toString().contains('index')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        texts.firestoreIndexRequired,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        texts.firestoreIndexDesc,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'エラー詳細:\n${snapshot.error}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Text('${texts.errorWithDetail}${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    texts.noNotifications,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final notification = NotificationData.fromFirestore(doc);

              return _buildNotificationCard(notification, currentUser.uid);
            },
          );
        },
      ),
    );
  }

  /// 通知カードを構築
  Widget _buildNotificationCard(
      NotificationData notification, String currentUserId) {
    final isRead = notification.read;
    final timeAgo = _formatTimeAgo(notification.timestamp);

    // 通知タイプに応じたアイコンと色
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.listCreated:
        icon = Icons.playlist_add;
        iconColor = Colors.green;
        break;
      case NotificationType.listDeleted:
        icon = Icons.delete;
        iconColor = Colors.red;
        break;
      case NotificationType.listRenamed:
        icon = Icons.edit;
        iconColor = Colors.blue;
        break;
      case NotificationType.groupMemberAdded:
        icon = Icons.person_add;
        iconColor = Colors.purple;
        break;
      case NotificationType.groupDeleted:
        icon = Icons.group_remove;
        iconColor = Colors.red;
        break;
      case NotificationType.itemAdded:
        icon = Icons.add_shopping_cart;
        iconColor = Colors.green;
        break;
      case NotificationType.itemRemoved:
        icon = Icons.remove_shopping_cart;
        iconColor = Colors.orange;
        break;
      case NotificationType.itemPurchased:
        icon = Icons.shopping_bag;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          _buildNotificationMessage(notification),
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  texts.unread,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: !isRead
            ? IconButton(
                icon: const Icon(Icons.check, color: Colors.blue),
                tooltip: texts.tooltipMarkRead,
                onPressed: () => _markAsRead(notification.id),
              )
            : null,
        onTap: !isRead ? () => _markAsRead(notification.id) : null,
      ),
    );
  }

  /// 通知メッセージをメタデータから現地語で再構築
  String _buildNotificationMessage(NotificationData notification) {
    final m = notification.metadata ?? {};
    final name = (m['creatorName'] ??
        m['deleterName'] ??
        m['renamerName'] ??
        m['adderName'] ??
        m['removerName'] ??
        m['purchaserName'] ??
        m['editorName'] ??
        m['newMemberName'] ??
        m['leftUserName'] ??
        m['requesterName'] ??
        '') as String;
    final listName = (m['listName'] ?? '') as String;
    final itemName = (m['itemName'] ?? '') as String;
    final oldName = (m['oldName'] ?? m['oldGroupName'] ?? '') as String;
    final newName = (m['newName'] ?? m['newGroupName'] ?? '') as String;
    String groupName = (m['groupName'] ?? '') as String;
    final acceptorName = (m['acceptorName'] ?? '') as String;

    // groupNameが空の場合、allGroupsProviderからフォールバック
    if (groupName.isEmpty && notification.groupId.isNotEmpty) {
      final groups = ref.read(allGroupsProvider).valueOrNull ?? [];
      final found =
          groups.where((g) => g.groupId == notification.groupId).firstOrNull;
      if (found != null) groupName = found.groupName;
    }

    switch (notification.type) {
      case NotificationType.listCreated:
        return texts.notifListCreated(name, listName);
      case NotificationType.listDeleted:
        return texts.notifListDeleted(name, listName);
      case NotificationType.listRenamed:
        return texts.notifRenamed(name, oldName, newName);
      case NotificationType.groupMemberAdded:
        if (acceptorName.isNotEmpty) {
          return texts.notifMembershipApproved(groupName);
        }
        final joinedName = (m['newMemberName'] ?? name) as String;
        return texts.notifMemberJoined(joinedName, groupName);
      case NotificationType.syncConfirmation:
        return texts.notifMembershipApproved(groupName);
      case NotificationType.groupDeleted:
        return texts.notifGroupDeleted(name, groupName);
      case NotificationType.groupUpdated:
        if (oldName.isNotEmpty && newName.isNotEmpty) {
          return texts.notifRenamed(name, oldName, newName);
        }
        final leftUser = (m['leftUserName'] ?? '') as String;
        if (leftUser.isNotEmpty) {
          return texts.notifMemberLeft(leftUser, groupName);
        }
        return notification.message;
      case NotificationType.groupLeft:
        return texts.notifYouLeft(groupName);
      case NotificationType.itemAdded:
        return texts.notifItemAdded(name, itemName, listName);
      case NotificationType.itemRemoved:
        return texts.notifItemRemoved(name, itemName, listName);
      case NotificationType.itemPurchased:
        return texts.notifItemPurchased(name, itemName, listName);
      case NotificationType.whiteboardUpdated:
        return texts.notifWhiteboardUpdated(name);
      case NotificationType.whiteboardEditStarted:
        return texts.notifWhiteboardEditStarted(name);
      case NotificationType.whiteboardEditEnded:
        return texts.notifWhiteboardEditEnded(name);
      default:
        return notification.message;
    }
  }

  /// 時間差を人間が読める形式に変換
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return texts.justNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${texts.minutesAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${texts.hoursAgo}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${texts.daysAgo}';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}${texts.weeksAgo}';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}${texts.monthsAgo}';
    } else {
      return '${(difference.inDays / 365).floor()}${texts.yearsAgo}';
    }
  }

  /// 通知を既読にする
  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('通知を既読にしました: $notificationId');
    } catch (e) {
      AppLogger.error('通知既読エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${texts.errorWithDetail}$e')),
        );
      }
    }
  }

  /// 既読通知を削除
  Future<void> _clearReadNotifications(String userId) async {
    try {
      AppLogger.info('既読通知削除開始: userId=${AppLogger.maskUserId(userId)}');

      final readNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: true)
          .get();

      if (readNotifications.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(texts.noReadNotifications)),
          );
        }
        return;
      }

      final batch = _firestore.batch();
      for (var doc in readNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      AppLogger.info('既読通知を削除しました: ${readNotifications.docs.length}件');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                texts.deletedReadNotifications(readNotifications.docs.length)),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('既読通知削除エラー: $e');

      // インデックスエラーの場合の特別処理
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${texts.firestoreIndexRequired}. ${texts.firestoreIndexDesc}'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${texts.errorWithDetail}$e')),
        );
      }
    }
  }
}
