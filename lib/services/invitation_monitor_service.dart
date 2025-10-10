// lib/services/invitation_monitor_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accepted_invitation.dart';
import '../services/accepted_invitation_service.dart';
import '../providers/purchase_group_provider.dart';
import '../datastore/purchase_group_repository.dart';

/// 招待監視サービスプロバイダー
final invitationMonitorServiceProvider = Provider<InvitationMonitorService>((ref) {
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
    final acceptedInvitationService = _ref.read(acceptedInvitationServiceProvider);
    
    _subscription = acceptedInvitationService
        .watchUnprocessedInvitations()
        .listen(_processNewInvitations);
        
    print('👁️ 招待受諾監視を開始しました');
  }

  /// 監視を停止
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    print('🛑 招待受諾監視を停止しました');
  }

  /// 新しい受諾を処理
  Future<void> _processNewInvitations(List<FirestoreAcceptedInvitation> invitations) async {
    if (invitations.isEmpty) return;

    print('📥 新しい招待受諾: ${invitations.length}件');

    for (final invitation in invitations) {
      try {
        await _processAcceptedInvitation(invitation);
      } catch (e) {
        print('❌ 招待処理エラー (${invitation.acceptorUid}): $e');
      }
    }
  }

  /// 個別の受諾招待を処理
  Future<void> _processAcceptedInvitation(FirestoreAcceptedInvitation invitation) async {
    print('🔄 招待処理中: ${invitation.acceptorName} (${invitation.acceptorUid})');

    try {
      // 1. PurchaseGroupのallowedUidsに追加
      await _updatePurchaseGroupAllowedUids(
        groupId: invitation.purchaseGroupId,
        newUid: invitation.acceptorUid,
      );

      // 2. ShoppingListのallowedUidsに追加
      await _updateShoppingListAllowedUids(
        listId: invitation.shoppingListId,
        newUid: invitation.acceptorUid,
      );

      // 3. 処理済みマーク
      final acceptedInvitationService = _ref.read(acceptedInvitationServiceProvider);
      await acceptedInvitationService.markAsProcessed(
        acceptorUid: invitation.acceptorUid,
        notes: 'allowedUidsに追加完了',
      );

      print('✅ 招待処理完了: ${invitation.acceptorName}');

    } catch (e) {
      print('❌ 招待処理失敗: ${invitation.acceptorName} - $e');
      rethrow;
    }
  }

  /// PurchaseGroupのallowedUidsを更新
  Future<void> _updatePurchaseGroupAllowedUids({
    required String groupId,
    required String newUid,
  }) async {
    try {
      // Firestoreの PurchaseGroup ドキュメントを直接更新
      await _firestore.collection('purchaseGroups').doc(groupId).update({
        'allowedUids': FieldValue.arrayUnion([newUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ PurchaseGroup allowedUids更新: $groupId + $newUid');
    } catch (e) {
      print('❌ PurchaseGroup更新エラー: $e');
      rethrow;
    }
  }

  /// ShoppingListのallowedUidsを更新
  Future<void> _updateShoppingListAllowedUids({
    required String listId,
    required String newUid,
  }) async {
    try {
      // Firestoreの ShoppingList ドキュメントを直接更新
      await _firestore.collection('shoppingLists').doc(listId).update({
        'allowedUids': FieldValue.arrayUnion([newUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ ShoppingList allowedUids更新: $listId + $newUid');
    } catch (e) {
      print('❌ ShoppingList更新エラー: $e');
      rethrow;
    }
  }

  /// 手動で未処理招待をすべて処理
  Future<void> processAllPendingInvitations() async {
    final acceptedInvitationService = _ref.read(acceptedInvitationServiceProvider);
    
    try {
      final pendingInvitations = await acceptedInvitationService.getUnprocessedInvitations();
      
      if (pendingInvitations.isEmpty) {
        print('📋 未処理の招待はありません');
        return;
      }

      print('🔄 未処理招待を手動処理: ${pendingInvitations.length}件');
      
      for (final invitation in pendingInvitations) {
        await _processAcceptedInvitation(invitation);
      }
      
      print('✅ 全未処理招待の処理完了');
      
    } catch (e) {
      print('❌ 手動処理エラー: $e');
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
      // PurchaseGroupから削除
      await _firestore.collection('purchaseGroups').doc(groupId).update({
        'allowedUids': FieldValue.arrayRemove([revokeUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ShoppingListから削除
      await _firestore.collection('shoppingLists').doc(listId).update({
        'allowedUids': FieldValue.arrayRemove([revokeUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ ユーザー権限削除完了: $revokeUid');
    } catch (e) {
      print('❌ 権限削除エラー: $e');
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
      print('❌ 統計取得エラー: $e');
      return {};
    }
  }

  /// リソースクリーンアップ
  void dispose() {
    stopMonitoring();
  }
}