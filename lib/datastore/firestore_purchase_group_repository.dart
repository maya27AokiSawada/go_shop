import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import 'dart:developer' as developer;

class FirestorePurchaseGroupRepository implements PurchaseGroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// 購入グループコレクション（全体で一意）
  CollectionReference get _groupsCollection =>
      _firestore.collection('purchaseGroups');

  /// ショッピングリストコレクション（全体で一意）
  CollectionReference get _shoppingListsCollection =>
      _firestore.collection('shoppingLists');

  /// ユーザーメンバーシップコレクション
  CollectionReference _getUserMembershipsCollection(String userId) {
    return _firestore
        .collection('userMemberships')
        .doc(userId)
        .collection('groups');
  }

  /// 現在のユーザーのメンバーシップコレクション
  CollectionReference get _currentUserMemberships {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    return _getUserMembershipsCollection(currentUser.uid);
  }

  /// ショッピングリストID生成（groupId + UUID）
  String generateShoppingListId(String groupId) {
    final uuid = _uuid.v4().replaceAll('-', '').substring(0, 12);
    return '${groupId}_$uuid';
  }

  /// リストIDからグループIDを抽出
  String getGroupIdFromListId(String listId) {
    return listId.split('_')[0];
  }

  @override
  Future<PurchaseGroup> createGroup(
      String groupId, String groupName, PurchaseGroupMember member) async {
    try {
      final newGroup = PurchaseGroup.create(
        groupId: groupId,
        groupName: groupName,
        ownerName: member.name,
        ownerEmail: member.contact,
        ownerUid: member.memberId,
        members: [member],
      );

      // Firestoreトランザクションで一括処理
      await _firestore.runTransaction((transaction) async {
        // 1. グループデータを作成
        transaction.set(
            _groupsCollection.doc(groupId), _groupToFirestore(newGroup));

        // 2. オーナーのメンバーシップを作成
        final membershipRef =
            _getUserMembershipsCollection(member.memberId).doc(groupId);
        transaction.set(membershipRef, {
          'role': 'owner',
          'joinedAt': FieldValue.serverTimestamp(),
          'groupName': groupName, // キャッシュ用
        });
      });

      developer.log(
          '🔥 [FIRESTORE] Created group and membership: $groupName ($groupId)');
      return newGroup;
    } catch (e) {
      developer.log('❌ Firestore createGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        developer.log('❌ User not authenticated');
        return [];
      }

      final currentUserId = currentUser.uid;
      final currentUserEmail = currentUser.email ?? '';

      developer.log(
          '🔥 [FIRESTORE] Fetching groups for user: $currentUserId ($currentUserEmail)');

      // 1. ユーザーのメンバーシップからグループIDリストを取得
      final membershipsSnapshot =
          await _getUserMembershipsCollection(currentUserId).get();
      final groupIds = membershipsSnapshot.docs.map((doc) => doc.id).toList();

      developer.log(
          '🔥 [FIRESTORE] Found memberships for ${groupIds.length} groups: $groupIds');

      if (groupIds.isEmpty) {
        developer.log('🔥 [FIRESTORE] No group memberships found');
        return [];
      }

      // 2. グループIDsでグループデータを一括取得
      final List<PurchaseGroup> allGroups = [];

      // Firestoreの'in'クエリは最大10件までなので、バッチ処理
      for (int i = 0; i < groupIds.length; i += 10) {
        final batch = groupIds.skip(i).take(10).toList();
        final groupsSnapshot = await _groupsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final batchGroups =
            groupsSnapshot.docs.map((doc) => _groupFromFirestore(doc)).toList();

        allGroups.addAll(batchGroups);
      }

      // デバッグ: 各グループの詳細をログ出力
      for (final group in allGroups) {
        developer.log(
            '🔥 [FIRESTORE] - ${group.groupName} (${group.groupId}) Owner: ${group.ownerUid}');
      }

      developer.log('🔥 [FIRESTORE] Total fetched groups: ${allGroups.length}');
      return allGroups;
    } catch (e) {
      developer.log('❌ Firestore getAllGroups error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> getGroupById(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) {
        throw Exception('Group not found: $groupId');
      }

      return _groupFromFirestore(doc);
    } catch (e) {
      developer.log('❌ Firestore getGroupById error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    try {
      await _groupsCollection.doc(groupId).update({
        ..._groupToFirestore(group),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('🔥 Updated in Firestore: ${group.groupName}');
      return group;
    } catch (e) {
      developer.log('❌ Firestore updateGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) {
        throw Exception('Group not found: $groupId');
      }

      final group = _groupFromFirestore(doc);

      // Firestoreトランザクションで一括処理
      await _firestore.runTransaction((transaction) async {
        // 1. グループデータを削除
        transaction.delete(_groupsCollection.doc(groupId));

        // 2. 全メンバーのメンバーシップを削除
        for (final member in group.members ?? <PurchaseGroupMember>[]) {
          final membershipRef =
              _getUserMembershipsCollection(member.memberId).doc(groupId);
          transaction.delete(membershipRef);
        }
      });

      developer
          .log('🔥 [FIRESTORE] Deleted group and all memberships: $groupId');
      return group;
    } catch (e) {
      developer.log('❌ Firestore deleteGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> addMember(
      String groupId, PurchaseGroupMember member) async {
    try {
      final group = await getGroupById(groupId);
      final updatedGroup = group.addMember(member);

      // Firestoreトランザクションで一括処理
      await _firestore.runTransaction((transaction) async {
        // 1. グループデータを更新
        transaction.update(
            _groupsCollection.doc(groupId), _groupToFirestore(updatedGroup));

        // 2. 新メンバーのメンバーシップを作成
        final membershipRef =
            _getUserMembershipsCollection(member.memberId).doc(groupId);
        transaction.set(membershipRef, {
          'role': member.role.toString().split('.').last,
          'joinedAt': FieldValue.serverTimestamp(),
          'groupName': group.groupName, // キャッシュ用
        });
      });

      developer.log(
          '🔥 [FIRESTORE] Added member and created membership: ${member.name} to $groupId');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ Firestore addMember error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> removeMember(
      String groupId, PurchaseGroupMember member) async {
    try {
      final group = await getGroupById(groupId);
      final updatedGroup = group.removeMember(member);

      // Firestoreトランザクションで一括処理
      await _firestore.runTransaction((transaction) async {
        // 1. グループデータを更新
        transaction.update(
            _groupsCollection.doc(groupId), _groupToFirestore(updatedGroup));

        // 2. メンバーのメンバーシップを削除
        final membershipRef =
            _getUserMembershipsCollection(member.memberId).doc(groupId);
        transaction.delete(membershipRef);
      });

      developer.log(
          '🔥 [FIRESTORE] Removed member and deleted membership: ${member.name} from $groupId');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ Firestore removeMember error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> setMemberId(
      String oldId, String newId, String? contact) async {
    try {
      // TODO: Firestore実装 - 複数グループでのUID更新
      throw UnimplementedError('setMemberId not implemented for Firestore yet');
    } catch (e) {
      developer.log('❌ Firestore setMemberId error: $e');
      rethrow;
    }
  }

  // 🔒 メンバープール関連（個人情報保護のため Firestore では実装しない）
  @override
  Future<PurchaseGroup> getOrCreateMemberPool() async {
    throw UnimplementedError(
        '🔒 Member pool is local-only for privacy protection');
  }

  @override
  Future<void> syncMemberPool() async {
    // 🔒 個人情報保護: メンバープールはFirestoreに同期しない
  }

  @override
  Future<List<PurchaseGroupMember>> searchMembersInPool(String query) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return [];
  }

  @override
  Future<PurchaseGroupMember?> findMemberByEmail(String email) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return null;
  }

  // =================================================================
  // Firestore変換ヘルパー
  // =================================================================

  Map<String, dynamic> _groupToFirestore(PurchaseGroup group) {
    return {
      'groupName': group.groupName,
      'groupId': group.groupId,
      'ownerName': group.ownerName,
      'ownerEmail': group.ownerEmail,
      'ownerUid': group.ownerUid,
      'members': group.members
          ?.map((m) => {
                'memberId': m.memberId,
                'name': m.name,
                'contact': m.contact,
                'role': m.role.index,
                'isSignedIn': m.isSignedIn,
                'isInvited': m.isInvited,
                'isInvitationAccepted': m.isInvitationAccepted,
                'invitedAt': m.invitedAt?.millisecondsSinceEpoch,
                'acceptedAt': m.acceptedAt?.millisecondsSinceEpoch,
              })
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  PurchaseGroup _groupFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final membersList = (data['members'] as List<dynamic>?)
        ?.map((memberData) => PurchaseGroupMember(
              memberId: memberData['memberId'] ?? '',
              name: memberData['name'] ?? '',
              contact: memberData['contact'] ?? '',
              role: PurchaseGroupRole.values[memberData['role'] ?? 0],
              isSignedIn: memberData['isSignedIn'] ?? false,
              isInvited: memberData['isInvited'] ?? false,
              isInvitationAccepted: memberData['isInvitationAccepted'] ?? false,
              invitedAt: memberData['invitedAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(memberData['invitedAt'])
                  : null,
              acceptedAt: memberData['acceptedAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      memberData['acceptedAt'])
                  : null,
            ))
        .toList();

    return PurchaseGroup(
      groupName: data['groupName'] ?? '',
      groupId: data['groupId'] ?? doc.id,
      ownerName: data['ownerName'],
      ownerEmail: data['ownerEmail'],
      ownerUid: data['ownerUid'],
      members: membersList,
    );
  }
}
