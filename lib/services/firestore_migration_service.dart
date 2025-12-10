import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shared_group.dart';
import '../utils/app_logger.dart';

/// Firestoreデータマイグレーションサービス
///
/// 旧構造: /users/{uid}/groups/{groupId}
/// 新構造: /SharedGroups/{groupId} + /userMemberships/{userId}/groups/{groupId}
class FirestoreDataMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Version 2 → Version 3 マイグレーション実行
  Future<void> migrateToVersion3() async {
    AppLogger.info('🔄 [MIGRATION] Firestore構造マイグレーション開始 (v2 → v3)');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      AppLogger.info('ℹ️ [MIGRATION] ユーザー未認証のためマイグレーションスキップ');
      return;
    }

    try {
      await _migrateUserGroupsToNewStructure(currentUser.uid);
      AppLogger.info('✅ [MIGRATION] Firestore構造マイグレーション完了');
    } catch (e) {
      AppLogger.error('❌ [MIGRATION] マイグレーションエラー: $e');
      rethrow;
    }
  }

  /// ユーザーのグループを旧構造から新構造に移行
  Future<void> _migrateUserGroupsToNewStructure(String userId) async {
    AppLogger.info(
        '🔄 [MIGRATION] ユーザー ${AppLogger.maskUserId(userId)} のグループマイグレーション開始');

    // 1. 旧構造からグループデータを取得
    final oldGroupsRef =
        _firestore.collection('users').doc(userId).collection('groups');

    final oldGroupsSnapshot = await oldGroupsRef.get();

    if (oldGroupsSnapshot.docs.isEmpty) {
      AppLogger.info('ℹ️ [MIGRATION] 旧構造にグループが見つかりませんでした');
      return;
    }

    AppLogger.info(
        '📋 [MIGRATION] 発見された旧グループ数: ${oldGroupsSnapshot.docs.length}');

    // 2. バッチ処理で新構造にデータを移行
    final batch = _firestore.batch();
    int migratedCount = 0;

    for (final doc in oldGroupsSnapshot.docs) {
      try {
        final groupData = doc.data();
        final groupId = doc.id;

        AppLogger.info('🔄 [MIGRATION] グループマイグレーション: $groupId');

        // 旧データから新構造のSharedGroupを復元
        final group = _convertOldGroupData(groupData, groupId);

        // 新構造: /SharedGroups/{groupId} にグループデータを保存
        final newGroupRef = _firestore.collection('SharedGroups').doc(groupId);
        batch.set(newGroupRef, _groupToFirestore(group));

        // 新構造: 全メンバーのメンバーシップを作成
        for (final member in group.members ?? <SharedGroupMember>[]) {
          final membershipRef = _firestore
              .collection('userMemberships')
              .doc(member.memberId)
              .collection('groups')
              .doc(groupId);

          batch.set(membershipRef, {
            'role': member.role.toString().split('.').last,
            'joinedAt': FieldValue.serverTimestamp(),
            'groupName': group.groupName,
            'migratedAt': FieldValue.serverTimestamp(),
          });
        }

        migratedCount++;
      } catch (e) {
        AppLogger.error('❌ [MIGRATION] グループ ${doc.id} のマイグレーションエラー: $e');
      }
    }

    // 3. バッチコミット
    if (migratedCount > 0) {
      await batch.commit();
      AppLogger.info('✅ [MIGRATION] バッチコミット完了: $migratedCount グループ');

      // 4. 成功したら旧データを削除（オプション）
      await _cleanupOldStructureData(userId, oldGroupsSnapshot.docs);
    }
  }

  /// 旧構造のデータをSharedGroupに変換
  SharedGroup _convertOldGroupData(Map<String, dynamic> data, String groupId) {
    try {
      // 旧データから必要な情報を抽出
      final groupName = data['groupName'] as String? ?? 'Unnamed Group';
      final ownerUid = data['ownerUid'] as String? ?? '';
      final ownerName = data['ownerName'] as String? ?? '';
      final ownerEmail = data['ownerEmail'] as String? ?? '';
      // メンバーデータを変換
      final membersList = data['members'] as List<dynamic>? ?? [];
      final members = membersList.map((memberData) {
        final memberMap = memberData as Map<String, dynamic>;
        return SharedGroupMember(
          memberId: memberMap['memberId'] as String? ?? '',
          name: memberMap['name'] as String? ?? '',
          contact: memberMap['contact'] as String? ?? '',
          role: _parseRole(memberMap['role']),
          invitationStatus:
              _parseInvitationStatus(memberMap['invitationStatus']),
        );
      }).toList();

      return SharedGroup(
        groupId: groupId,
        groupName: groupName,
        ownerUid: ownerUid,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        members: members,
      );
    } catch (e) {
      AppLogger.error('❌ [MIGRATION] 旧データ変換エラー: $e');
      rethrow;
    }
  }

  /// 旧構造データの削除（クリーンアップ）
  Future<void> _cleanupOldStructureData(
      String userId, List<QueryDocumentSnapshot> oldDocs) async {
    try {
      AppLogger.info('🧹 [MIGRATION] 旧構造データのクリーンアップ開始');

      final batch = _firestore.batch();

      for (final doc in oldDocs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.info('✅ [MIGRATION] 旧構造データのクリーンアップ完了');
    } catch (e) {
      AppLogger.error('❌ [MIGRATION] クリーンアップエラー: $e');
      // クリーンアップエラーは致命的ではないので続行
    }
  }

  /// 役割の文字列をenumに変換
  SharedGroupRole _parseRole(dynamic roleData) {
    if (roleData == null) return SharedGroupRole.member;

    final roleString = roleData.toString();
    switch (roleString) {
      case 'owner':
      case 'SharedGroupRole.owner':
        return SharedGroupRole.owner;
      case 'manager':
      case 'SharedGroupRole.manager':
        return SharedGroupRole.manager;
      case 'partner':
      case 'SharedGroupRole.partner':
        return SharedGroupRole.partner;
      default:
        return SharedGroupRole.member;
    }
  }

  /// 招待ステータスの文字列をenumに変換
  InvitationStatus _parseInvitationStatus(dynamic statusData) {
    if (statusData == null) return InvitationStatus.accepted; // 既存メンバーは承諾済み

    final statusString = statusData.toString();
    switch (statusString) {
      case 'pending':
      case 'InvitationStatus.pending':
        return InvitationStatus.pending;
      case 'deleted':
      case 'InvitationStatus.deleted':
        return InvitationStatus.deleted;
      case 'self':
      case 'InvitationStatus.self':
        return InvitationStatus.self;
      default:
        return InvitationStatus.accepted;
    }
  }

  /// SharedGroupをFirestoreデータに変換
  Map<String, dynamic> _groupToFirestore(SharedGroup group) {
    return {
      'groupId': group.groupId,
      'groupName': group.groupName,
      'ownerUid': group.ownerUid,
      'ownerName': group.ownerName,
      'ownerEmail': group.ownerEmail,
      'members': group.members
              ?.map((member) => {
                    'memberId': member.memberId,
                    'name': member.name,
                    'contact': member.contact,
                    'role': member.role.toString().split('.').last,
                    'invitationStatus':
                        member.invitationStatus.toString().split('.').last,
                  })
              .toList() ??
          [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'migratedAt': FieldValue.serverTimestamp(), // マイグレーション日時
    };
  }
}
