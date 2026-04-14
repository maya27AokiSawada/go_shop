// lib/services/invitation_monitor_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../models/accepted_invitation.dart';
import '../models/shared_list.dart';
import '../services/accepted_invitation_service.dart';
import '../providers/shared_list_provider.dart';

/// 招待監視サービスプロバイダー
final invitationMonitorServiceProvider =
    Provider<InvitationMonitorService>((ref) {
  return InvitationMonitorService(ref);
});

/// 招待元が受諾を監視して権限同期を行うサービス
class InvitationMonitorService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<List<FirestoreAcceptedInvitation>>? _subscription;

  InvitationMonitorService(this._ref);

  /// リアルタイム監視を開始
  void startMonitoring() {
    final acceptedInvitationService =
        _ref.read(acceptedInvitationServiceProvider);

    _subscription =
        acceptedInvitationService.watchUnprocessedInvitations().listen(
      _processNewInvitations,
      onError: (Object e, StackTrace s) {
        Log.error('❌ 招待受諾監視エラー: $e');
      },
      cancelOnError: false,
    );

    Log.info('👁️ 招待受諾監視を開始しました');
  }

  /// 監視を停止
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    Log.info('🛑 招待受諾監視を停止しました');
  }

  /// 新しい受諾を処理
  Future<void> _processNewInvitations(
      List<FirestoreAcceptedInvitation> invitations) async {
    if (invitations.isEmpty) return;

    Log.info('📥 新しい招待受諾: ${invitations.length}件');

    for (final invitation in invitations) {
      try {
        await _processAcceptedInvitation(invitation);
      } catch (e) {
        Log.error('❌ 招待処理エラー (${invitation.acceptorUid}): $e');
      }
    }
  }

  /// 個別の受諾招待を処理
  Future<void> _processAcceptedInvitation(
      FirestoreAcceptedInvitation invitation) async {
    Log.info(
        '🔄 招待処理中: ${invitation.acceptorName} (${invitation.acceptorUid})');

    try {
      // 1. SharedGroupのallowedUidsに追加
      await _updateSharedGroupAllowedUids(
        groupId: invitation.SharedGroupId,
        newUid: invitation.acceptorUid,
      );

      // 2. SharedListのallowedUidsに追加
      await _updateSharedListAllowedUids(
        listId: invitation.sharedListId,
        newUid: invitation.acceptorUid,
      );

      // 3. グループに属する既存のショッピングリストをダウンロード
      await _downloadExistingSharedLists(
        groupId: invitation.SharedGroupId,
        acceptorUid: invitation.acceptorUid,
      );

      // 4. 処理済みマーク
      final acceptedInvitationService =
          _ref.read(acceptedInvitationServiceProvider);
      await acceptedInvitationService.markAsProcessed(
        acceptorUid: invitation.acceptorUid,
        notes: 'allowedUids追加 & リストダウンロード完了',
      );

      Log.info('✅ 招待処理完了: ${invitation.acceptorName}');
    } catch (e) {
      Log.error('❌ 招待処理失敗: ${invitation.acceptorName} - $e');
      rethrow;
    }
  }

  /// SharedGroupのallowedUidsを更新
  Future<void> _updateSharedGroupAllowedUids({
    required String groupId,
    required String newUid,
  }) async {
    try {
      // Firestoreの SharedGroup ドキュメントを直接更新
      await _firestore.collection('SharedGroups').doc(groupId).update({
        'allowedUids': FieldValue.arrayUnion([newUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Log.info(
          '✅ SharedGroup allowedUids更新: $groupId + ${AppLogger.maskUserId(newUid)}');
    } catch (e) {
      Log.error('❌ SharedGroup更新エラー: $e');
      rethrow;
    }
  }

  /// SharedListのallowedUidsを更新
  Future<void> _updateSharedListAllowedUids({
    required String listId,
    required String newUid,
  }) async {
    try {
      // Firestoreの SharedList ドキュメントを直接更新
      await _firestore.collection('sharedLists').doc(listId).update({
        'allowedUids': FieldValue.arrayUnion([newUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Log.info(
          '✅ SharedList allowedUids更新: $listId + ${AppLogger.maskUserId(newUid)}');
    } catch (e) {
      Log.error('❌ SharedList更新エラー: $e');
      rethrow;
    }
  }

  /// 手動で未処理招待をすべて処理
  Future<void> processAllPendingInvitations() async {
    final acceptedInvitationService =
        _ref.read(acceptedInvitationServiceProvider);

    try {
      final pendingInvitations =
          await acceptedInvitationService.getUnprocessedInvitations();

      if (pendingInvitations.isEmpty) {
        Log.info('📋 未処理の招待はありません');
        return;
      }

      Log.info('🔄 未処理招待を手動処理: ${pendingInvitations.length}件');

      for (final invitation in pendingInvitations) {
        await _processAcceptedInvitation(invitation);
      }

      Log.info('✅ 全未処理招待の処理完了');
    } catch (e) {
      Log.error('❌ 手動処理エラー: $e');
      rethrow;
    }
  }

  /// 特定のユーザーの権限を削除（退出時）
  Future<void> revokeUserAccess({
    required String groupId,
    required String listId,
    required String revokeUid,
  }) async {
    try {
      // SharedGroupから削除
      await _firestore.collection('SharedGroups').doc(groupId).update({
        'allowedUids': FieldValue.arrayRemove([revokeUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // SharedListから削除
      await _firestore.collection('sharedLists').doc(listId).update({
        'allowedUids': FieldValue.arrayRemove([revokeUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Log.info('✅ ユーザー権限削除完了: $revokeUid');
    } catch (e) {
      Log.error('❌ 権限削除エラー: $e');
      rethrow;
    }
  }

  /// 招待統計情報を取得
  Future<Map<String, int>> getInvitationStats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    try {
      final allInvitations = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('acceptedInvitations')
          .get();

      final processed = allInvitations.docs
          .where((doc) => doc.data()['isProcessed'] == true)
          .length;
      final pending = allInvitations.docs.length - processed;

      return {
        'total': allInvitations.docs.length,
        'processed': processed,
        'pending': pending,
      };
    } catch (e) {
      Log.error('❌ 統計取得エラー: $e');
      return {};
    }
  }

  /// グループに属する既存のショッピングリストをFirestoreからダウンロードしてHiveに保存
  Future<void> _downloadExistingSharedLists({
    required String groupId,
    required String acceptorUid,
  }) async {
    try {
      Log.info('📥 [DOWNLOAD LISTS] グループ($groupId)の既存リスト取得開始...');

      // 1. Firestoreからグループに属する全リストを取得
      final listsSnapshot = await _firestore
          .collectionGroup('sharedLists')
          .where('groupId', isEqualTo: groupId)
          .get();

      if (listsSnapshot.docs.isEmpty) {
        Log.info('ℹ️ [DOWNLOAD LISTS] グループにリストが存在しません');
        return;
      }

      Log.info('📋 [DOWNLOAD LISTS] ${listsSnapshot.docs.length}件のリストを発見');

      // 2. Hiveのショッピングリストボックスを取得
      final sharedListBox = _ref.read(sharedListBoxProvider);

      // 3. 各リストをHiveに保存
      int savedCount = 0;
      for (final doc in listsSnapshot.docs) {
        try {
          final data = doc.data();
          final list = _sharedListFromFirestore(doc.id, data);

          // Hiveに保存（既存データは上書き）
          await sharedListBox.put(list.listId, list);
          savedCount++;

          Log.info(
              '✅ [DOWNLOAD LISTS] リスト保存: ${list.listName} (ID: ${list.listId})');
        } catch (e) {
          Log.error('❌ [DOWNLOAD LISTS] リスト保存エラー (${doc.id}): $e');
        }
      }

      Log.info(
          '✅ [DOWNLOAD LISTS] $savedCount/${listsSnapshot.docs.length}件のリストをローカル保存完了');
    } catch (e) {
      Log.error('❌ [DOWNLOAD LISTS] リストダウンロードエラー: $e');
      // エラーが発生しても招待処理自体は継続（リストは後から同期可能）
    }
  }

  /// FirestoreドキュメントからSharedListモデルに変換
  SharedList _sharedListFromFirestore(String docId, Map<String, dynamic> data) {
    final items = (data['items'] as List?)
            ?.map((item) => _sharedItemFromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return SharedList(
      listId: docId,
      ownerUid: data['ownerUid'] ?? '',
      groupId: data['groupId'] ?? '',
      groupName: data['listName'] ?? data['groupName'] ?? '',
      listName: data['listName'] ?? '',
      description: data['description'] ?? '',
      items: {for (var item in items) item.itemId: item},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// MapからSharedItemに変換
  SharedItem _sharedItemFromMap(Map<String, dynamic> data) {
    return SharedItem(
      itemId: data['itemId'] ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      memberId: data['memberId'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 1,
      registeredDate: (data['registeredDate'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
      isPurchased: data['isPurchased'] ?? false,
      shoppingInterval: data['shoppingInterval'] ?? 0,
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
    );
  }

  /// リソースクリーンアップ
  void dispose() {
    stopMonitoring();
  }
}
