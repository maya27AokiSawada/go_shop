import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../services/accepted_invitation_service.dart';

// QRコード招待サービスプロバイダー
final qrInvitationServiceProvider = Provider<QRInvitationService>((ref) {
  return QRInvitationService();
});

class QRInvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// QRコード用の招待データを作成
  /// 招待元のUID、ShoppingListID、PurchaseGroupIDを含む（常にメンバーロールで招待）
  Future<Map<String, dynamic>> createQRInvitationData({
    required String shoppingListId,
    required String purchaseGroupId,
    required String groupName,
    required String groupOwnerUid,
    String? customMessage,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーが認証されていません');
    }

    // 招待データを作成（常にメンバーロールで招待）
    final invitationData = {
      'inviterUid': currentUser.uid,
      'inviterEmail': currentUser.email ?? '',
      'inviterDisplayName': currentUser.displayName ?? currentUser.email ?? 'ユーザー', // 招待者表示名追加
      'shoppingListId': shoppingListId,
      'purchaseGroupId': purchaseGroupId,
      'groupName': groupName, // 🆕 グループ名を追加
      'groupOwnerUid': groupOwnerUid, // 🆕 グループオーナーUIDを追加
      'inviteRole': 'member', // 常にメンバーロールで招待
      'message': customMessage ?? 'Go Shopグループへの招待です',
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'qr_invitation',
      'version': '1.0',
    };

    return invitationData;
  }

  /// QRコードデータをJSONエンコード
  String encodeQRData(Map<String, dynamic> invitationData) {
    return jsonEncode(invitationData);
  }

  /// QRコードデータをJSONデコード
  Map<String, dynamic>? decodeQRData(String qrData) {
    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;
      
      // 基本的な検証
      if (decoded['type'] == 'qr_invitation' && 
          decoded['inviterUid'] != null &&
          decoded['inviterDisplayName'] != null &&
          decoded['shoppingListId'] != null &&
          decoded['purchaseGroupId'] != null &&
          decoded['groupName'] != null && // 🆕 グループ名の検証
          decoded['groupOwnerUid'] != null && // 🆕 オーナーUIDの検証
          decoded['inviteRole'] != null) {
        // inviteRoleがmemberであることを確認（レガシー対応でmanager、ownerもチェック）
        final role = decoded['inviteRole'] as String;
        if (role != 'member' && role != 'manager') {
          print('警告: 予期しない招待ロール: $role, memberとして扱います');
          decoded['inviteRole'] = 'member'; // 強制的にmemberに変更
        }
        return decoded;
      }
      return null;
    } catch (e) {
      print('QRコードデコードエラー: $e');
      return null;
    }
  }

  /// QRコードウィジェットを生成
  Widget generateQRWidget(String qrData, {double size = 200.0}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: size,
        gapless: false,
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        errorStateBuilder: (cxt, err) {
          return Container(
            child: const Center(
              child: Text(
                'QRコード生成エラー',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 招待を受諾する処理
  Future<bool> acceptQRInvitation({
    required Map<String, dynamic> invitationData,
    required String acceptorUid,
    required WidgetRef ref, // Riverpod ref for repository access
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != acceptorUid) {
        throw Exception('ユーザー認証が無効です');
      }

      final inviterUid = invitationData['inviterUid'] as String;
      final shoppingListId = invitationData['shoppingListId'] as String;
      final purchaseGroupId = invitationData['purchaseGroupId'] as String;
      final inviteRoleStr = invitationData['inviteRole'] as String;

      // 自分自身への招待を防ぐ
      if (inviterUid == acceptorUid) {
        throw Exception('自分自身を招待することはできません');
      }

      // ロール文字列をPurchaseGroupRoleに変換（常にmemberとして扱う）
      PurchaseGroupRole inviteRole = PurchaseGroupRole.member;
      
      // レガシー招待データとの互換性チェック
      if (inviteRoleStr == 'owner') {
        throw Exception('オーナー権限での招待は受諾できません');
      }
      
      // 他のロールでも安全のため全てmemberとして扱う
      print('💡 招待ロール: $inviteRoleStr → member として受諾');

      // PurchaseGroupRepositoryを取得
      final repository = ref.read(purchaseGroupRepositoryProvider);
      
      // 招待データからグループ情報を取得（グループ名、オーナーUID、オーナー名）
      final groupName = invitationData['groupName'] as String? ?? 'グループ';
      final groupOwnerUid = invitationData['groupOwnerUid'] as String? ?? inviterUid;
      final ownerDisplayName = invitationData['inviterDisplayName'] as String? ?? 
                               (invitationData['inviterEmail'] as String? ?? 'オーナー');
      
      print('📋 招待情報: groupName=$groupName, groupOwnerUid=$groupOwnerUid, ownerName=$ownerDisplayName');
      
      // 招待された側用の新しいグループを作成
      // 「〇〇さんの」プレフィックスを付けたグループ名（オーナー名を使用）
      final sharedGroupName = '$ownerDisplayNameさんの$groupName';
      final newGroupId = '${purchaseGroupId}_shared_$acceptorUid';
      
      // 招待された側のメンバー情報
      final acceptorMember = PurchaseGroupMember.create(
        memberId: currentUser.uid, // 🔒 Firebase Auth UIDを確実に設定
        name: currentUser.displayName ?? currentUser.email ?? 'ユーザー',
        contact: currentUser.email ?? '',
        role: inviteRole, // 招待時に指定されたロール（owner以外）
        isSignedIn: true, // Firebase Auth済み
        isInvited: true,
        isInvitationAccepted: true,
        invitedAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      );
      
      // 🆕 新アーキテクチャ: 招待元のacceptedInvitationsに書き込み
      final acceptedInvitationService = ref.read(acceptedInvitationServiceProvider);
      await acceptedInvitationService.recordAcceptedInvitation(
        inviterUid: inviterUid,
        purchaseGroupId: purchaseGroupId,
        shoppingListId: shoppingListId,
        inviteRole: inviteRole.name,
        notes: '$sharedGroupNameへの招待を受諾',
      );
      
      // 🆕 招待元のFirestoreグループにメンバー情報を記録
      // 注: 招待を受諾した側は、招待元のローカルグループにアクセスできないため、
      // acceptedInvitationsコレクションを使用して招待元に通知します
      // 招待元は定期的にacceptedInvitationsを確認し、自分のグループにメンバーを追加します
      try {
        print('✅ 招待受諾情報を記録しました。招待元が同期時にメンバーを追加します。');
      } catch (e) {
        print('⚠️ 招待受諾情報の記録エラー: $e');
      }
      
      // 招待された側用の共有グループを作成(ローカル用)
      try {
        await repository.createGroup(newGroupId, sharedGroupName, acceptorMember);
        print('✅ 共有グループ「$sharedGroupName」を作成しました');
        print('✅ 招待受諾を招待元($inviterUid)に通知しました');
        
        // プロバイダーを更新してUIに反映
        ref.invalidate(purchaseGroupProvider);
        ref.invalidate(allGroupsProvider);
      } catch (e) {
        print('⚠️ 共有グループ作成エラー: $e');
        // 既に存在する場合はスキップ
      }

      // Firestoreに招待受諾記録を保存
      await _firestore.collection('invitation_acceptances').add({
        'inviterUid': inviterUid,
        'acceptorUid': acceptorUid,
        'acceptorEmail': currentUser.email ?? '',
        'shoppingListId': shoppingListId,
        'purchaseGroupId': purchaseGroupId,
        'inviteRole': inviteRoleStr,
        'acceptedAt': FieldValue.serverTimestamp(),
        'type': 'qr_invitation_accepted',
        'originalInvitation': invitationData,
      });

      // 招待者に通知を送信（オプション）
      await _sendAcceptanceNotification(
        inviterUid: inviterUid,
        acceptorEmail: currentUser.email ?? '',
        shoppingListId: shoppingListId,
        purchaseGroupId: purchaseGroupId,
      );

      return true;
    } catch (e) {
      print('QR招待受諾エラー: $e');
      return false;
    }
  }

  /// 招待受諾通知を送信
  Future<void> _sendAcceptanceNotification({
    required String inviterUid,
    required String acceptorEmail,
    required String shoppingListId,
    required String purchaseGroupId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientUid': inviterUid,
        'type': 'invitation_accepted',
        'message': '$acceptorEmail さんがあなたの招待を受諾しました',
        'shoppingListId': shoppingListId,
        'purchaseGroupId': purchaseGroupId,
        'acceptorEmail': acceptorEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('招待受諾通知送信エラー: $e');
      // 通知送信失敗は非致命的なので、エラーを投げない
    }
  }

  /// 招待受諾記録を取得
  Future<List<Map<String, dynamic>>> getAcceptedInvitations(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('invitation_acceptances')
          .where('inviterUid', isEqualTo: uid)
          .orderBy('acceptedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('招待受諾記録取得エラー: $e');
      return [];
    }
  }

  /// 通知を取得
  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('通知取得エラー: $e');
      return [];
    }
  }

  /// 通知を既読にする
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('通知既読エラー: $e');
    }
  }
}