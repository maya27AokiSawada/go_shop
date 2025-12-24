import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';

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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('通知履歴'),
        ),
        body: const Center(
          child: Text('サインインが必要です'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知履歴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '既読通知を削除',
            onPressed: () => _clearReadNotifications(currentUser.uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots(),
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
                      const Text(
                        'Firestoreインデックスが必要です',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Firebase Consoleで複合インデックスを作成してください',
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
              child: Text('エラーが発生しました: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '通知はありません',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.message,
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
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '未読',
                  style: TextStyle(
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
                tooltip: '既読にする',
                onPressed: () => _markAsRead(notification.id),
              )
            : null,
        onTap: !isRead ? () => _markAsRead(notification.id) : null,
      ),
    );
  }

  /// 時間差を人間が読める形式に変換
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}週間前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}ヶ月前';
    } else {
      return '${(difference.inDays / 365).floor()}年前';
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
          SnackBar(content: Text('エラーが発生しました: $e')),
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
            const SnackBar(content: Text('既読通知はありません')),
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
            content: Text('${readNotifications.docs.length}件の既読通知を削除しました'),
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
            const SnackBar(
              content: Text('Firestoreインデックスが必要です。Firebase Consoleで作成してください'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }
}
