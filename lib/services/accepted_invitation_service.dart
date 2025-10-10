// lib/services/accepted_invitation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accepted_invitation.dart';

/// 受諾招待サービスプロバイダー
final acceptedInvitationServiceProvider = Provider<AcceptedInvitationService>((ref) {
  return AcceptedInvitationService();
});

/// 招待受諾管理サービス
/// 受諾者が招待元のacceptedInvitationsコレクションに書き込む
class AcceptedInvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 招待受諾を招待元のコレクションに記録
  /// 誰でも認証済みユーザーなら書き込み可能
  Future<void> recordAcceptedInvitation({
    required String inviterUid,
    required String purchaseGroupId,
    required String shoppingListId,
    required String inviteRole,
    String? notes,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーが認証されていません');
    }

    final acceptorUid = currentUser.uid;
    final acceptorEmail = currentUser.email ?? '';
    final acceptorName = currentUser.displayName ?? acceptorEmail;

    // 📝 重要: 招待元のacceptedInvitationsコレクションに書き込み
    // パス: /users/{inviterUid}/acceptedInvitations/{acceptorUid}
    final acceptedInvitation = FirestoreAcceptedInvitation(
      id: acceptorUid,
      acceptorUid: acceptorUid,
      acceptorEmail: acceptorEmail,
      acceptorName: acceptorName,
      purchaseGroupId: purchaseGroupId,
      shoppingListId: shoppingListId,
      inviteRole: inviteRole,
      acceptedAt: DateTime.now(),
      isProcessed: false,
      notes: notes,
    );

    try {
      await _firestore
          .collection('users')
          .doc(inviterUid)
          .collection('acceptedInvitations')
          .doc(acceptorUid)
          .set(acceptedInvitation.toFirestore());

      print('✅ 招待受諾を記録: $inviterUid → $acceptorUid');
    } catch (e) {
      print('❌ 招待受諾記録エラー: $e');
      rethrow;
    }
  }

  /// 招待元：自分に対する受諾リストを取得
  /// 自分のacceptedInvitationsコレクションから未処理のものを取得
  Future<List<FirestoreAcceptedInvitation>> getUnprocessedInvitations() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーが認証されていません');
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('acceptedInvitations')
          .where('isProcessed', isEqualTo: false)
          .orderBy('acceptedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FirestoreAcceptedInvitation.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ 未処理招待取得エラー: $e');
      return [];
    }
  }

  /// 招待元：受諾された招待を処理済みにマーク
  Future<void> markAsProcessed({
    required String acceptorUid,
    String? notes,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーが認証されていません');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('acceptedInvitations')
          .doc(acceptorUid)
          .update({
        'isProcessed': true,
        'processedAt': FieldValue.serverTimestamp(),
        if (notes != null) 'notes': notes,
      });

      print('✅ 招待処理完了: $acceptorUid');
    } catch (e) {
      print('❌ 招待処理エラー: $e');
      rethrow;
    }
  }

  /// 招待元：受諾リストをリアルタイム監視
  /// UI更新のためのStream
  Stream<List<FirestoreAcceptedInvitation>> watchUnprocessedInvitations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('acceptedInvitations')
        .where('isProcessed', isEqualTo: false)
        .orderBy('acceptedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirestoreAcceptedInvitation.fromFirestore(doc))
            .toList());
  }

  /// 特定の受諾招待を削除（クリーンアップ用）
  Future<void> deleteAcceptedInvitation({
    required String acceptorUid,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーが認証されていません');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('acceptedInvitations')
          .doc(acceptorUid)
          .delete();

      print('✅ 受諾招待削除: $acceptorUid');
    } catch (e) {
      print('❌ 受諾招待削除エラー: $e');
      rethrow;
    }
  }
}