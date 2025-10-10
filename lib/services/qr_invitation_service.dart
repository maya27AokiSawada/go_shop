import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

// QRコード招待サービスプロバイダー
final qrInvitationServiceProvider = Provider<QRInvitationService>((ref) {
  return QRInvitationService();
});

class QRInvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// QRコード用の招待データを作成
  /// 招待元のUID、ShoppingListID、PurchaseGroupIDを含む
  Future<Map<String, dynamic>> createQRInvitationData({
    required String shoppingListId,
    required String purchaseGroupId,
    String? customMessage,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーが認証されていません');
    }

    // 招待データを作成
    final invitationData = {
      'inviterUid': currentUser.uid,
      'inviterEmail': currentUser.email ?? '',
      'shoppingListId': shoppingListId,
      'purchaseGroupId': purchaseGroupId,
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
          decoded['shoppingListId'] != null &&
          decoded['purchaseGroupId'] != null) {
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
            child: Center(
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
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != acceptorUid) {
        throw Exception('ユーザー認証が無効です');
      }

      final inviterUid = invitationData['inviterUid'] as String;
      final shoppingListId = invitationData['shoppingListId'] as String;
      final purchaseGroupId = invitationData['purchaseGroupId'] as String;

      // 自分自身への招待を防ぐ
      if (inviterUid == acceptorUid) {
        throw Exception('自分自身を招待することはできません');
      }

      // Firestoreに招待受諾記録を保存
      await _firestore.collection('invitation_acceptances').add({
        'inviterUid': inviterUid,
        'acceptorUid': acceptorUid,
        'acceptorEmail': currentUser.email ?? '',
        'shoppingListId': shoppingListId,
        'purchaseGroupId': purchaseGroupId,
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