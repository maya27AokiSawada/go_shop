import 'dart:convert';

// Logger instance

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/app_logger.dart';
import 'invitation_security_service.dart';
import 'user_initialization_service.dart';
import 'notification_service.dart';
import '../providers/purchase_group_provider.dart';
import '../models/purchase_group.dart';

// QRコード招待サービスプロバイダー
final qrInvitationServiceProvider = Provider<QRInvitationService>((ref) {
  return QRInvitationService(ref);
});

class QRInvitationService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  QRInvitationService(this._ref);

  InvitationSecurityService get _securityService =>
      _ref.read(invitationSecurityServiceProvider);

  /// セキュアなQRコード用の招待データを作成
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

    // セキュリティキーを生成
    final securityKey = _securityService.generateSecurityKey();
    final invitationId = _securityService.generateInvitationId(purchaseGroupId);

    // セキュアな招待トークンを生成
    final invitationToken = _securityService.generateInvitationToken(
      groupId: purchaseGroupId,
      invitationType: invitationType,
      securityKey: securityKey,
      inviterUid: currentUser.uid,
    );

    // 招待データを作成
    final invitationData = {
      'invitationId': invitationId,
      'inviterUid': currentUser.uid,
      'inviterEmail': currentUser.email ?? '',
      'inviterDisplayName':
          currentUser.displayName ?? currentUser.email ?? 'ユーザー',
      'shoppingListId': shoppingListId,
      'purchaseGroupId': purchaseGroupId,
      'groupName': groupName,
      'groupOwnerUid': groupOwnerUid,
      'invitationType': invitationType,
      'inviteRole': 'member',
      'message': customMessage ?? 'Go Shopグループへの招待です',
      'securityKey': securityKey,
      'invitationToken': invitationToken,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt':
          DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      'type': 'secure_qr_invitation',
      'version': '3.0', // セキュリティ強化版
    };

    // Firestoreのinvitationsコレクションに保存
    await _firestore.collection('invitations').doc(invitationId).set({
      ...invitationData,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(hours: 24)),
      'status': 'pending', // pending, accepted, expired
    });

    Log.info('🔐 招待データをFirestoreに保存: $invitationId');

    return invitationData;
  }

  /// QRコードデータをJSONエンコード
  String encodeQRData(Map<String, dynamic> invitationData) {
    return jsonEncode(invitationData);
  }

  /// QRコードデータをJSONデコード（セキュリティ検証付き）
  Map<String, dynamic>? decodeQRData(String qrData) {
    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;

      // バージョンチェック
      final version = decoded['version'] as String?;
      if (version == '3.0') {
        return _validateSecureInvitation(decoded);
      } else {
        return _validateLegacyInvitation(decoded);
      }
    } catch (e) {
      Log.error('QRコードデコードエラー: $e');
      return null;
    }
  }

  /// セキュア招待（v3.0）の検証
  Map<String, dynamic>? _validateSecureInvitation(
      Map<String, dynamic> decoded) {
    // 必須フィールドのチェック
    if (decoded['type'] != 'secure_qr_invitation' ||
        decoded['invitationId'] == null ||
        decoded['inviterUid'] == null ||
        decoded['purchaseGroupId'] == null ||
        decoded['securityKey'] == null ||
        decoded['invitationToken'] == null ||
        decoded['expiresAt'] == null) {
      Log.info('セキュア招待データの必須フィールドが不足');
      return null;
    }

    // 有効期限チェック
    final expiresAt = DateTime.parse(decoded['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      Log.info('招待コードが期限切れです');
      return null;
    }

    // 招待トークンの検証
    final token = decoded['invitationToken'] as String;
    final tokenData = _securityService.parseInvitationToken(token);
    if (tokenData == null) {
      Log.info('無効な招待トークン');
      return null;
    }

    // トークンの整合性チェック
    if (tokenData.groupId != decoded['purchaseGroupId'] ||
        tokenData.securityKey != decoded['securityKey'] ||
        _securityService.isTokenExpired(tokenData.timestamp)) {
      Log.info('招待トークンの整合性チェック失敗');
      return null;
    }

    return decoded;
  }

  /// レガシー招待（v2.0以前）の検証
  Map<String, dynamic>? _validateLegacyInvitation(
      Map<String, dynamic> decoded) {
    if (decoded['type'] == 'qr_invitation' &&
        decoded['inviterUid'] != null &&
        decoded['inviterDisplayName'] != null &&
        decoded['shoppingListId'] != null &&
        decoded['purchaseGroupId'] != null &&
        decoded['groupName'] != null &&
        decoded['groupOwnerUid'] != null &&
        decoded['inviteRole'] != null) {
      final role = decoded['inviteRole'] as String;
      if (role != 'member' && role != 'manager') {
        Log.warning('警告: 予期しない招待ロール: $role, memberとして扱います');
        decoded['inviteRole'] = 'member';
      }
      return decoded;
    }
    return null;
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
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        embeddedImage: null,
        embeddedImageStyle: null,
        errorStateBuilder: (cxt, err) {
          return Container(
            child: const Center(
              child: Text('QRコードの生成に失敗しました'),
            ),
          );
        },
      ),
    );
  }

  /// 招待を受諾する処理（セキュリティ検証付き）
  Future<bool> acceptQRInvitation({
    required Map<String, dynamic> invitationData,
    required String acceptorUid,
    required WidgetRef ref,
    String? providedSecurityKey, // セキュリティキー（必要な場合）
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != acceptorUid) {
        throw Exception('ユーザー認証が無効です');
      }

      // セキュリティ検証
      if (!await _validateInvitationSecurity(
          invitationData, providedSecurityKey)) {
        throw Exception('招待のセキュリティ検証に失敗しました');
      }

      final inviterUid = invitationData['inviterUid'] as String;

      // 自分自身への招待を防ぐ
      if (inviterUid == acceptorUid) {
        throw Exception('自分自身を招待することはできません');
      }

      // 招待タイプを取得
      final invitationType =
          invitationData['invitationType'] as String? ?? 'individual';

      Log.info('💡 セキュア招待受諾: タイプ=$invitationType');

      // 招待タイプによって処理を分岐
      if (invitationType == 'friend') {
        await _processFriendInvitation(inviterUid, acceptorUid);
      } else {
        await _processIndividualInvitation(invitationData, acceptorUid);
      }

      // 招待受諾の記録
      await _recordInvitationAcceptance(invitationData, acceptorUid);

      // Firestoreのinvitationsコレクションのステータスを更新
      final invitationId = invitationData['invitationId'] as String?;
      if (invitationId != null) {
        await _firestore.collection('invitations').doc(invitationId).update({
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'acceptorUid': acceptorUid,
        });
        Log.info('✅ 招待ステータスを更新: $invitationId → accepted');
      }

      // Firestore書き込みの伝播を待つ（重要！）
      Log.info('⏳ Firestore伝播待機中...');
      await Future.delayed(const Duration(seconds: 2));

      // Firestore→Hive同期を実行
      Log.info('🔄 招待受諾後のFirestore→Hive同期を開始');
      final userInitService = ref.read(userInitializationServiceProvider);
      await userInitService.syncFromFirestoreToHive(currentUser);

      // AllGroupsProviderを再読み込み
      ref.invalidate(allGroupsProvider);
      Log.info('✅ 招待受諾後の同期完了');

      return true;
    } catch (e) {
      Log.error('QR招待受諾エラー: $e');
      return false;
    }
  }

  /// 招待のセキュリティを検証（Firestoreから取得）
  Future<bool> _validateInvitationSecurity(
      Map<String, dynamic> invitationData, String? providedKey) async {
    final version = invitationData['version'] as String?;

    // v3.0（セキュア版）の場合
    if (version == '3.0') {
      final invitationId = invitationData['invitationId'] as String?;
      if (invitationId == null) {
        Log.info('❌ 招待IDが不足');
        return false;
      }

      // Firestoreから実際の招待データを取得
      final invitationDoc =
          await _firestore.collection('invitations').doc(invitationId).get();

      if (!invitationDoc.exists) {
        Log.info('❌ 招待が見つかりません: $invitationId');
        return false;
      }

      final storedData = invitationDoc.data()!;
      final storedSecurityKey = storedData['securityKey'] as String?;
      final status = storedData['status'] as String?;
      final expiresAt = storedData['expiresAt'] as Timestamp?;

      // ステータスチェック
      if (status != 'pending') {
        Log.info('❌ 招待は既に使用済みまたは無効です: $status');
        return false;
      }

      // 有効期限チェック
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        Log.info('❌ 招待の有効期限が切れています');
        return false;
      }

      // セキュリティキー検証
      if (storedSecurityKey == null || providedKey == null) {
        Log.info('❌ セキュリティキーが不足');
        return false;
      }

      if (!_securityService.validateSecurityKey(
          providedKey, storedSecurityKey)) {
        Log.info('❌ セキュリティキーが無効');
        return false;
      }

      Log.info('✅ セキュリティ検証成功');
    }

    return true;
  }

  /// 招待受諾を記録
  Future<void> _recordInvitationAcceptance(
      Map<String, dynamic> invitationData, String acceptorUid) async {
    final invitationId = invitationData['invitationId'] as String?;
    if (invitationId != null) {
      await _firestore.collection('invitation_logs').doc(invitationId).set({
        'invitationId': invitationId,
        'acceptorUid': acceptorUid,
        'acceptedAt': FieldValue.serverTimestamp(),
        'groupId': invitationData['purchaseGroupId'],
        'invitationType': invitationData['invitationType'],
      });
    }
  }

  /// フレンド招待を処理 - 招待者の全グループへのアクセスを許可
  Future<void> _processFriendInvitation(
      String inviterUid, String acceptorUid) async {
    try {
      Log.info('🤝 フレンド招待を処理中...');

      // フレンドリストに追加
      await _firestore
          .collection('users')
          .doc(inviterUid)
          .collection('friends')
          .doc(acceptorUid)
          .set({
        'uid': acceptorUid,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': 'invitation',
      });

      await _firestore
          .collection('users')
          .doc(acceptorUid)
          .collection('friends')
          .doc(inviterUid)
          .set({
        'uid': inviterUid,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': 'invitation_acceptance',
      });

      // 招待者がオーナーのグループを取得
      final ownerGroupsQuery = await _firestore
          .collection('purchaseGroups')
          .where('ownerUid', isEqualTo: inviterUid)
          .get();

      // 各グループに友達として追加
      for (final doc in ownerGroupsQuery.docs) {
        final groupData = doc.data();
        final allowedUids = List<String>.from(groupData['allowedUids'] ?? []);
        final members =
            List<Map<String, dynamic>>.from(groupData['members'] ?? []);

        // allowedUidsに追加
        if (!allowedUids.contains(acceptorUid)) {
          allowedUids.add(acceptorUid);
          Log.info('✅ allowedUidsに追加: $acceptorUid → ${doc.id}');
        }

        // membersリストにも追加
        final memberExists = members.any((m) => m['memberId'] == acceptorUid);
        if (!memberExists) {
          // ユーザー情報を取得
          final acceptorUser = _auth.currentUser;
          final userName = acceptorUser?.displayName ?? 'Unknown User';

          // 新しいメンバーを追加
          final newMember = {
            'memberId': acceptorUid,
            'name': userName,
            'role': 'member', // デフォルトは一般メンバー
            'joinedAt': FieldValue.serverTimestamp(),
          };
          members.add(newMember);
          Log.info('✅ membersリストに追加: $userName ($acceptorUid) → ${doc.id}');
        }

        // Firestoreを更新
        await doc.reference.update({
          'allowedUids': allowedUids,
          'members': members,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        Log.info('✅ フレンドとして ${doc.id} グループに追加: $acceptorUid');
      }

      Log.info('✅ フレンド招待処理完了');
    } catch (e) {
      Log.error('❌ フレンド招待処理エラー: $e');
      rethrow;
    }
  }

  /// 個別招待を処理 - 特定のグループのみ
  Future<void> _processIndividualInvitation(
      Map<String, dynamic> invitationData, String acceptorUid) async {
    try {
      Log.info('👤 個別招待を処理中...');

      final groupId = invitationData['purchaseGroupId'] as String;
      final groupName = invitationData['groupName'] as String;

      Log.info('🔍 [QR_INVITATION] グループID: $groupId');
      Log.info('🔍 [QR_INVITATION] グループ名: $groupName');

      // リポジトリ経由でグループを取得
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      final group = await repository.getGroupById(groupId);
      Log.info('🔍 [QR_INVITATION] 既存グループ取得: ${group.groupName}');

      final allowedUid = List<String>.from(group.allowedUid);
      final members = List<PurchaseGroupMember>.from(group.members ?? []);

      // allowedUidに追加
      if (!allowedUid.contains(acceptorUid)) {
        allowedUid.add(acceptorUid);
        Log.info('✅ allowedUidに追加: $acceptorUid');
      }

      // membersリストにも追加
      final memberExists = members.any((m) => m.memberId == acceptorUid);
      if (!memberExists) {
        // ユーザー情報を取得
        final acceptorUser = _auth.currentUser;
        final userName = acceptorUser?.displayName ?? 'Unknown User';
        final userEmail = acceptorUser?.email ?? '';

        // 新しいメンバーを追加
        final newMember = PurchaseGroupMember(
          memberId: acceptorUid,
          name: userName,
          contact: userEmail,
          role: PurchaseGroupRole.member, // デフォルトは一般メンバー
          isSignedIn: true,
          invitationStatus: InvitationStatus.accepted,
          acceptedAt: DateTime.now(),
        );
        members.add(newMember);
        Log.info('✅ membersリストに追加: $userName ($acceptorUid)');
      }

      // グループを更新（リポジトリ経由）
      final updatedGroup = group.copyWith(
        allowedUid: allowedUid,
        members: members,
        updatedAt: DateTime.now(),
      );
      await repository.updateGroup(groupId, updatedGroup);

      Log.info('✅ 個別招待でグループに追加: $acceptorUid → $groupId');

      // グループの全メンバーに通知を送信（参加者本人は除く）
      final notificationService = _ref.read(notificationServiceProvider);
      final acceptorUser = _auth.currentUser;
      final userName =
          acceptorUser?.displayName ?? acceptorUser?.email ?? 'ユーザー';

      await notificationService.sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.groupMemberAdded,
        message: '$userName さんがグループに参加しました',
        excludeUserIds: [acceptorUid], // 参加者本人には送らない
        metadata: {
          'groupId': groupId, // 招待元がこのグループを再同期するため
          'newMemberId': acceptorUid,
          'newMemberName': userName,
        },
      );

      Log.info('✅ 個別招待処理完了 + 通知送信完了');
    } catch (e) {
      Log.error('❌ 個別招待処理エラー: $e');
      rethrow;
    }
  }
}
