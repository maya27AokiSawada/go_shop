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
    required String groupName,
    required String groupOwnerUid,
    required String invitationType, // 'individual' または 'friend'
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
      'inviterDisplayName': currentUser.displayName ?? currentUser.email ?? 'ユーザー',
      'shoppingListId': shoppingListId,
      'purchaseGroupId': purchaseGroupId,
      'groupName': groupName,
      'groupOwnerUid': groupOwnerUid,
      'invitationType': invitationType, // 'individual' または 'friend'
      'inviteRole': 'member',
      'message': customMessage ?? 'Go Shopグループへの招待です',
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'qr_invitation',
      'version': '2.0', // バージョンアップ
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
      
      // 自分自身への招待を防ぐ
      if (inviterUid == acceptorUid) {
        throw Exception('自分自身を招待することはできません');
      }

      // 招待タイプを取得（デフォルトは個別招待）
      final invitationType = invitationData['invitationType'] as String? ?? 'individual';
      
      print('💡 招待タイプ: $invitationType');

      // 招待タイプによって処理を分岐
      if (invitationType == 'friend') {
        await _processFriendInvitation(inviterUid, acceptorUid);
      } else {
        await _processIndividualInvitation(invitationData, acceptorUid);
      }

      return true;
    } catch (e) {
      print('QR招待受諾エラー: $e');
      return false;
    }
  }

  /// フレンド招待を処理 - 招待者の全グループへのアクセスを許可
  Future<void> _processFriendInvitation(String inviterUid, String acceptorUid) async {
    try {
      print('🤝 フレンド招待を処理中...');
      
      // 1. フレンドリストに追加
      await _firestore.collection('users').doc(inviterUid).collection('friends').doc(acceptorUid).set({
        'uid': acceptorUid,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': 'invitation',
      });
      
      await _firestore.collection('users').doc(acceptorUid).collection('friends').doc(inviterUid).set({
        'uid': inviterUid,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': 'invitation_acceptance',
      });
      
      // 2. 招待者のプールユーザー管理グループ（隠しグループ）にフレンドとして追加
      await _addToPoolUsersGroup(inviterUid, acceptorUid, 'friend');
      
      // 3. 招待者の全グループ・リストにアクセス権限を付与
      final inviterGroups = await _firestore
          .collection('purchaseGroups')
          .where('ownerId', isEqualTo: inviterUid)
          .get();
          
      for (final doc in inviterGroups.docs) {
        // グループのallowedUidsに追加
        await doc.reference.update({
          'allowedUids': FieldValue.arrayUnion([acceptorUid])
        });
        
        // 関連するショッピングリストも更新
        final lists = await _firestore
            .collection('shoppingLists')
            .where('purchaseGroupId', isEqualTo: doc.id)
            .get();
            
        for (final listDoc in lists.docs) {
          await listDoc.reference.update({
            'allowedUids': FieldValue.arrayUnion([acceptorUid])
          });
        }
      }
      
      print('✅ フレンド招待処理完了');
    } catch (e) {
      print('❌ フレンド招待処理エラー: $e');
      throw e;
    }
  }
  
  /// 個別招待を処理 - 特定のグループのみへのアクセスを許可
  Future<void> _processIndividualInvitation(Map<String, dynamic> invitationData, String acceptorUid) async {
    try {
      print('👤 個別招待を処理中...');
      
      final purchaseGroupId = invitationData['purchaseGroupId'] as String;
      final shoppingListId = invitationData['shoppingListId'] as String?;
      final inviterUid = invitationData['inviterUid'] as String;
      
      // 1. 招待者のプールユーザー管理グループ（隠しグループ）にメンバーとして追加
      await _addToPoolUsersGroup(inviterUid, acceptorUid, 'member');
      
      // 2. 指定されたグループのallowedUidsに追加
      await _firestore.collection('purchaseGroups').doc(purchaseGroupId).update({
        'allowedUids': FieldValue.arrayUnion([acceptorUid])
      });
      
      // 3. 指定されたショッピングリストがある場合は、それにもアクセス権限を付与
      if (shoppingListId != null) {
        await _firestore.collection('shoppingLists').doc(shoppingListId).update({
          'allowedUids': FieldValue.arrayUnion([acceptorUid])
        });
      }
      
      print('✅ 個別招待処理完了');
    } catch (e) {
      print('❌ 個別招待処理エラー: $e');
      throw e;
    }
  }
  
  /// プールユーザー管理グループ（隠しグループ）にメンバーを追加
  Future<void> _addToPoolUsersGroup(String inviterUid, String acceptorUid, String roleType) async {
    try {
      // 招待者のプールユーザー管理グループを検索
      // グループ名の規則: "_pool_users_{inviterUid}" または類似のパターン
      final poolGroupQuery = await _firestore
          .collection('purchaseGroups')
          .where('ownerId', isEqualTo: inviterUid)
          .where('groupName', isGreaterThanOrEqualTo: '_pool_')
          .where('groupName', isLessThan: '_pool_\uf8ff')
          .get();
      
      String poolGroupId;
      
      if (poolGroupQuery.docs.isEmpty) {
        // プールユーザー管理グループが存在しない場合は作成
        poolGroupId = 'pool_users_$inviterUid';
        await _firestore.collection('purchaseGroups').doc(poolGroupId).set({
          'groupId': poolGroupId,
          'groupName': '_pool_users_$inviterUid',
          'ownerId': inviterUid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isHidden': true, // 隠しグループフラグ
          'members': [],
          'allowedUids': [inviterUid],
        });
        print('📦 プールユーザー管理グループを作成: $poolGroupId');
      } else {
        poolGroupId = poolGroupQuery.docs.first.id;
        print('📦 既存のプールユーザー管理グループを使用: $poolGroupId');
      }
      
      // ユーザー情報を取得
      final acceptorUser = await _auth.currentUser;
      final acceptorEmail = acceptorUser?.email ?? '';
      final acceptorName = acceptorUser?.displayName ?? acceptorEmail;
      
      // ロールを決定（friend招待 -> friend, 個別招待 -> member）
      final role = roleType == 'friend' ? 'friend' : 'member';
      
      // プールユーザー管理グループにメンバーを追加
      await _firestore.collection('purchaseGroups').doc(poolGroupId).update({
        'members': FieldValue.arrayUnion([{
          'memberId': acceptorUid,
          'name': acceptorName,
          'contact': acceptorEmail,
          'role': role,
          'isSignedIn': true,
          'isInvited': true,
          'isInvitationAccepted': true,
          'invitedAt': FieldValue.serverTimestamp(),
          'acceptedAt': FieldValue.serverTimestamp(),
        }]),
        'allowedUids': FieldValue.arrayUnion([acceptorUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ プールユーザー管理グループにメンバー追加完了: $acceptorUid as $role');
    } catch (e) {
      print('❌ プールユーザー管理グループ追加エラー: $e');
      // 非致命的エラーとして処理し、招待処理自体は継続
    }
  }
}