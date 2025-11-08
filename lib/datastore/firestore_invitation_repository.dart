// lib/datastore/firestore_invitation_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/invitation.dart';
import '../models/purchase_group.dart';
import '../utils/app_logger.dart';
import 'invitation_repository.dart';

/// Firestore実装の招待リポジトリ
class FirestoreInvitationRepository implements InvitationRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  FirestoreInvitationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Invitationsコレクションへの参照
  CollectionReference<Map<String, dynamic>> get _invitationsCollection =>
      _firestore.collection('invitations');

  @override
  Future<Invitation> inviteOthers({
    required String groupId,
    required String groupName,
    required String invitedBy,
    required String inviterName,
    Duration expiry = const Duration(hours: 24),
    int maxUses = 5,
  }) async {
    try {
      // トークン生成
      final token = 'INV_${_uuid.v4()}';
      final now = DateTime.now();
      final expiresAt = now.add(expiry);

      // 招待情報作成
      final invitation = Invitation(
        token: token,
        groupId: groupId,
        groupName: groupName,
        invitedBy: invitedBy,
        inviterName: inviterName,
        createdAt: now,
        expiresAt: expiresAt,
        maxUses: maxUses,
        currentUses: 0,
        usedBy: [],
      );

      // Firestoreに保存
      await _invitationsCollection.doc(token).set(invitation.toFirestore());

      Log.info('✅ [INVITATION] 招待作成成功: $token (グループ: $groupName)');
      return invitation;
    } catch (e) {
      Log.error('❌ [INVITATION] 招待作成エラー: $e');
      rethrow;
    }
  }

  @override
  Future<void> allowAcceptUsers({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // 招待情報取得
      final invitation = await getInvitationByToken(token);
      if (invitation == null) {
        throw Exception('招待が見つかりません');
      }

      // バリデーション
      if (invitation.isExpired) {
        throw Exception('招待の有効期限が切れています');
      }
      if (invitation.isMaxUsesReached) {
        throw Exception('招待の使用回数上限に達しています');
      }
      if (invitation.isUsedBy(userId)) {
        throw Exception('すでにこの招待を使用しています');
      }

      // グループ情報取得
      final groupRef = _firestore
          .collection('users')
          .doc(invitation.invitedBy)
          .collection('groups')
          .doc(invitation.groupId);

      final groupDoc = await groupRef.get();
      if (!groupDoc.exists) {
        throw Exception('グループが見つかりません');
      }

      // 新メンバー情報
      final newMember = {
        'memberId': userId,
        'name': userName,
        'contact': userEmail,
        'role': PurchaseGroupRole.member.name,
        'isSignedIn': true,
        'invitationStatus': InvitationStatus.accepted.name,
      };

      // メンバー追加
      await groupRef.update({
        'members': FieldValue.arrayUnion([newMember]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 自分のFirestoreにもグループ情報をコピー
      final groupData = groupDoc.data()!;
      groupData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('groups')
          .doc(invitation.groupId)
          .set(groupData, SetOptions(merge: true));

      // 招待トークン更新
      await _invitationsCollection.doc(token).update({
        'currentUses': FieldValue.increment(1),
        'usedBy': FieldValue.arrayUnion([userId]),
      });

      Log.info('✅ [INVITATION] ユーザー参加成功: $userName → ${invitation.groupName}');
    } catch (e) {
      Log.error('❌ [INVITATION] ユーザー参加エラー: $e');
      rethrow;
    }
  }

  @override
  Future<void> cleanUpExpiredInvitation() async {
    try {
      final now = Timestamp.now();

      // 期限切れの招待を検索
      final expiredDocs = await _invitationsCollection
          .where('expiresAt', isLessThan: now)
          .get();

      if (expiredDocs.docs.isEmpty) {
        Log.info('💡 [INVITATION] 期限切れ招待なし');
        return;
      }

      // バッチ削除
      final batch = _firestore.batch();
      for (final doc in expiredDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      Log.info('🗑️ [INVITATION] 期限切れ招待削除完了: ${expiredDocs.docs.length}件');
    } catch (e) {
      Log.error('❌ [INVITATION] クリーンアップエラー: $e');
      rethrow;
    }
  }

  @override
  Future<Invitation?> getInvitationByToken(String token) async {
    try {
      final doc = await _invitationsCollection.doc(token).get();

      if (!doc.exists) {
        Log.warning('⚠️ [INVITATION] 招待が見つかりません: $token');
        return null;
      }

      return Invitation.fromFirestore(doc);
    } catch (e) {
      Log.error('❌ [INVITATION] 招待取得エラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<Invitation>> getInvitationsByGroup(String groupId) async {
    try {
      final now = Timestamp.now();

      // 有効期限内の招待のみ取得（Firestoreインデックス使用）
      final querySnapshot = await _invitationsCollection
          .where('groupId', isEqualTo: groupId)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt', descending: true)
          .get();

      final invitations = querySnapshot.docs
          .map((doc) => Invitation.fromFirestore(doc))
          .toList();

      Log.info('📋 [INVITATION] グループ招待取得: $groupId (${invitations.length}件)');
      return invitations;
    } catch (e) {
      Log.error('❌ [INVITATION] グループ招待取得エラー: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelInvitation(String token) async {
    try {
      await _invitationsCollection.doc(token).delete();
      Log.info('🗑️ [INVITATION] 招待取り消し成功: $token');
    } catch (e) {
      Log.error('❌ [INVITATION] 招待取り消しエラー: $e');
      rethrow;
    }
  }
}
