import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../models/shopping_list.dart';
import '../models/user_settings.dart';
import '../providers/user_settings_provider.dart';
import 'notification_service.dart';

/// リスト変更通知のバッチサービスプロバイダー
final listNotificationBatchServiceProvider =
    Provider<ListNotificationBatchService>((ref) {
  return ListNotificationBatchService(ref);
});

/// リスト変更のタイプ
enum ListChangeType {
  itemAdded,
  itemRemoved,
  itemPurchased,
}

/// バッチ通知用の変更情報
class _ListChange {
  final String listId;
  final String groupId;
  final ListChangeType type;
  final String itemName;
  final String userName;
  final DateTime timestamp;

  _ListChange({
    required this.listId,
    required this.groupId,
    required this.type,
    required this.itemName,
    required this.userName,
    required this.timestamp,
  });
}

/// リスト変更通知のバッチサービス
///
/// 5分間隔でまとめて通知を送信:
/// - アイテム追加
/// - アイテム削除
/// - 購入完了
class ListNotificationBatchService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // バッチキュー
  final List<_ListChange> _changeQueue = [];
  Timer? _batchTimer;
  bool _isProcessing = false;

  // 5分間隔
  static const Duration _batchInterval = Duration(minutes: 5);

  ListNotificationBatchService(this._ref);

  /// サービス開始（タイマー起動）
  void start() {
    if (_batchTimer != null) {
      AppLogger.info('🔔 [LIST_NOTIFY] 既にバッチタイマー起動中');
      return;
    }

    _batchTimer = Timer.periodic(_batchInterval, (_) => _processBatch());
    AppLogger.info('🔔 [LIST_NOTIFY] バッチ通知タイマー起動（5分間隔）');
  }

  /// サービス停止
  void stop() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _changeQueue.clear();
    AppLogger.info('🔕 [LIST_NOTIFY] バッチ通知タイマー停止');
  }

  /// アイテム追加を記録
  Future<void> recordItemAdded({
    required String listId,
    required String groupId,
    required String itemName,
  }) async {
    await _recordChange(
      listId: listId,
      groupId: groupId,
      type: ListChangeType.itemAdded,
      itemName: itemName,
    );
  }

  /// アイテム削除を記録
  Future<void> recordItemRemoved({
    required String listId,
    required String groupId,
    required String itemName,
  }) async {
    await _recordChange(
      listId: listId,
      groupId: groupId,
      type: ListChangeType.itemRemoved,
      itemName: itemName,
    );
  }

  /// 購入完了を記録
  Future<void> recordItemPurchased({
    required String listId,
    required String groupId,
    required String itemName,
  }) async {
    await _recordChange(
      listId: listId,
      groupId: groupId,
      type: ListChangeType.itemPurchased,
      itemName: itemName,
    );
  }

  /// 変更を記録（内部メソッド）
  Future<void> _recordChange({
    required String listId,
    required String groupId,
    required ListChangeType type,
    required String itemName,
  }) async {
    try {
      // ユーザー設定を確認（通知OFF時はスキップ）
      final userSettings = await _ref.read(userSettingsProvider.future);
      if (!userSettings.enableListNotifications) {
        AppLogger.info('🔕 [LIST_NOTIFY] 通知OFF - 記録スキップ');
        return;
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.warning('⚠️ [LIST_NOTIFY] 認証なし - 記録スキップ');
        return;
      }

      final userName = currentUser.displayName ?? currentUser.email ?? 'ユーザー';

      _changeQueue.add(_ListChange(
        listId: listId,
        groupId: groupId,
        type: type,
        itemName: itemName,
        userName: userName,
        timestamp: DateTime.now(),
      ));

      AppLogger.info(
          '📝 [LIST_NOTIFY] 変更記録: ${type.name} - $itemName (キュー: ${_changeQueue.length}件)');
    } catch (e) {
      AppLogger.error('❌ [LIST_NOTIFY] 変更記録エラー: $e');
    }
  }

  /// バッチ処理（5分ごとに実行）
  Future<void> _processBatch() async {
    if (_isProcessing || _changeQueue.isEmpty) {
      return;
    }

    _isProcessing = true;
    AppLogger.info('🔄 [LIST_NOTIFY] バッチ処理開始: ${_changeQueue.length}件の変更');

    try {
      // グループごとに変更をまとめる
      final Map<String, List<_ListChange>> changesByGroup = {};
      for (final change in _changeQueue) {
        changesByGroup.putIfAbsent(change.groupId, () => []).add(change);
      }

      // グループごとに通知を送信
      for (final entry in changesByGroup.entries) {
        final groupId = entry.key;
        final changes = entry.value;

        await _sendGroupNotification(groupId, changes);
      }

      // キューをクリア
      _changeQueue.clear();
      AppLogger.info('✅ [LIST_NOTIFY] バッチ処理完了');
    } catch (e) {
      AppLogger.error('❌ [LIST_NOTIFY] バッチ処理エラー: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// グループメンバーに通知を送信
  Future<void> _sendGroupNotification(
      String groupId, List<_ListChange> changes) async {
    try {
      // グループ情報を取得してメンバーのUIDリストを取得
      final groupDoc =
          await _firestore.collection('purchaseGroups').doc(groupId).get();

      if (!groupDoc.exists) {
        AppLogger.warning('⚠️ [LIST_NOTIFY] グループが見つかりません: $groupId');
        return;
      }

      final groupData = groupDoc.data()!;
      final allowedUids = List<String>.from(groupData['allowedUid'] ?? []);
      final currentUser = _auth.currentUser;

      // 変更内容をまとめる
      final addedItems = changes
          .where((c) => c.type == ListChangeType.itemAdded)
          .map((c) => c.itemName)
          .toList();
      final removedItems = changes
          .where((c) => c.type == ListChangeType.itemRemoved)
          .map((c) => c.itemName)
          .toList();
      final purchasedItems = changes
          .where((c) => c.type == ListChangeType.itemPurchased)
          .map((c) => c.itemName)
          .toList();

      // メッセージ作成
      final List<String> messageParts = [];
      if (addedItems.isNotEmpty) {
        messageParts.add('${addedItems.length}件追加');
      }
      if (removedItems.isNotEmpty) {
        messageParts.add('${removedItems.length}件削除');
      }
      if (purchasedItems.isNotEmpty) {
        messageParts.add('${purchasedItems.length}件購入完了');
      }

      final message = messageParts.join('、');

      // 自分以外のメンバーに通知を送信
      final notificationService = _ref.read(notificationServiceProvider);
      for (final uid in allowedUids) {
        if (uid == currentUser?.uid) continue; // 自分には送らない

        // 通知タイプを決定（最も重要な変更を優先）
        NotificationType notificationType;
        if (addedItems.isNotEmpty) {
          notificationType = NotificationType.itemAdded;
        } else if (purchasedItems.isNotEmpty) {
          notificationType = NotificationType.itemPurchased;
        } else {
          notificationType = NotificationType.itemRemoved;
        }

        await notificationService.sendNotification(
          targetUserId: uid,
          type: notificationType,
          groupId: groupId,
          message: 'リストが更新されました: $message',
          metadata: {
            'added': addedItems,
            'removed': removedItems,
            'purchased': purchasedItems,
            'userName': changes.first.userName,
          },
        );

        AppLogger.info('📤 [LIST_NOTIFY] 通知送信: $uid へ "$message"');
      }
    } catch (e) {
      AppLogger.error('❌ [LIST_NOTIFY] 通知送信エラー: $e');
    }
  }

  /// 即座に通知を送信（緊急時用）
  Future<void> flushNow() async {
    if (_changeQueue.isEmpty) return;

    AppLogger.info('⚡ [LIST_NOTIFY] 即座通知: ${_changeQueue.length}件');
    await _processBatch();
  }
}
