import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

final invitationServiceProvider = Provider<InvitationService>((ref) {
  return InvitationService();
});

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> inviteUserToGroup({
    required String groupId,
    required String groupName,
    required String inviteeEmail,
    required String inviterName,
  }) async {
    final inviteCode = generateInviteCode();
    
    await _firestore.collection('invitations').doc(inviteCode).set({
      'groupId': groupId,
      'groupName': groupName,
      'inviteeEmail': inviteeEmail,
      'inviterName': inviterName,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    await _sendInvitationEmail(inviteeEmail, groupName, inviterName, inviteCode);
    return inviteCode;
  }

  Future<List<String>> inviteMultipleUsers({
    required String groupId,
    required String groupName,
    required List<String> inviteeEmails,
    required String inviterName,
    Function(int)? onProgress,
  }) async {
    final List<String> inviteCodes = [];
    
    for (int i = 0; i < inviteeEmails.length; i++) {
      try {
        final inviteCode = await inviteUserToGroup(
          groupId: groupId,
          groupName: groupName,
          inviteeEmail: inviteeEmails[i],
          inviterName: inviterName,
        );
        inviteCodes.add(inviteCode);
        onProgress?.call(i + 1);
        
        if (i < inviteeEmails.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print(' への招待に失敗: ');
        onProgress?.call(i + 1);
      }
    }
    
    return inviteCodes;
  }

  Future<void> _sendInvitationEmail(String email, String group, String inviter, String code) async {
    try {
      await _firestore.collection('mail').add({
        'to': email,
        'message': {
          'subject': ' さんから「」グループへのご招待',
          'text': ' さんから招待が届いています。招待コード: ',
        },
      });
    } catch (e) {
      final uri = Uri(scheme: 'mailto', path: email);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<Map<String, dynamic>?> getInvitationByCode(String inviteCode) async {
    try {
      final doc = await _firestore.collection('invitations').doc(inviteCode).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('招待情報取得エラー: ');
      return null;
    }
  }

  Future<bool> acceptInvitation(String inviteCode) async {
    try {
      final invitation = await getInvitationByCode(inviteCode);
      if (invitation == null) {
        throw Exception('無効な招待コードです');
      }

      await _firestore.collection('invitations').doc(inviteCode).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('招待承諾エラー: ');
      return false;
    }
  }
}
