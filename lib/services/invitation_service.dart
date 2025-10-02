// lib/services/invitation_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_group.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 招待リンクを生成してメール送信
  Future<String> inviteUserToGroup({
    required String groupId,
    required String inviteeEmail,
    required PurchaseGroupRole role,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // 招待情報をFirestoreに保存
    final invitationData = {
      'groupId': groupId,
      'inviterUid': currentUser.uid,
      'inviterEmail': currentUser.email,
      'inviteeEmail': inviteeEmail,
      'role': role.name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(days: 7)), // 7日間有効
    };

    final docRef = await _firestore.collection('invitations').add(invitationData);
    
    // Dynamic Linkを生成
    final invitationLink = await _generateDynamicLink(
      invitationId: docRef.id,
      groupId: groupId,
    );

    // メール送信（実装は省略）
    await _sendInvitationEmail(inviteeEmail, invitationLink);
    
    return invitationLink;
  }

  Future<String> _generateDynamicLink({
    required String invitationId,
    required String groupId,
  }) async {
    // Firebase Dynamic Links実装
    // または単純なディープリンク
    return 'https://goshop.app/invite?id=$invitationId&group=$groupId';
  }

  Future<void> _sendInvitationEmail(String email, String link) async {
    // Cloud Functions経由でメール送信
    // または外部メールサービス利用
  }

  // 招待を受諾
  Future<void> acceptInvitation(String invitationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final invitationDoc = await _firestore
        .collection('invitations')
        .doc(invitationId)
        .get();

    if (!invitationDoc.exists) {
      throw Exception('Invitation not found');
    }

    final invitationData = invitationDoc.data()!;
    
    // 招待されたメールアドレスとログインユーザーのメールが一致するかチェック
    if (invitationData['inviteeEmail'] != currentUser.email) {
      throw Exception('Email mismatch');
    }

    // PurchaseGroupにメンバーを追加
    await _addMemberToGroup(
      groupId: invitationData['groupId'],
      uid: currentUser.uid,
      email: currentUser.email!,
      role: _parseRole(invitationData['role']),
    );

    // 招待ステータスを更新
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'acceptedBy': currentUser.uid,
    });
  }

  Future<void> _addMemberToGroup({
    required String groupId,
    required String uid,
    required String email,
    required PurchaseGroupRole role,
  }) async {
    // Firestore上のPurchaseGroupを更新
    final groupDoc = _firestore.collection('purchaseGroups').doc(groupId);
    
    final newMember = {
      'memberId': uid,
      'name': email.split('@')[0], // 仮の名前
      'contact': email,
      'role': role.name,
      'isSignedIn': true,
      'joinedAt': FieldValue.serverTimestamp(),
    };

    await groupDoc.update({
      'members': FieldValue.arrayUnion([newMember])
    });
  }

  PurchaseGroupRole _parseRole(String roleString) {
    switch (roleString) {
      case 'owner':
        return PurchaseGroupRole.owner;
      case 'parent':
        return PurchaseGroupRole.parent;
      case 'child':
        return PurchaseGroupRole.child;
      default:
        return PurchaseGroupRole.child;
    }
  }
}