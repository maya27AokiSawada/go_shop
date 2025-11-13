import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import 'dart:developer' as developer;

class FirestorePurchaseGroupRepository implements PurchaseGroupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // FirebaseFirestoreインスタンスを直接受け取る
  FirestorePurchaseGroupRepository(this._firestore);

  /// 購入グループコレクション（ルート直下 - QR招待のため）
  CollectionReference get _groupsCollection {
    return _firestore.collection('purchaseGroups');
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
      final user = _auth.currentUser;
      if (user == null) {
        developer.log('❌ [FIRESTORE] User not logged in');
        throw Exception("User not logged in");
      }

      developer.log('🔥 [FIRESTORE] Creating group: $groupName ($groupId)');
      developer.log('🔍 [FIRESTORE] Owner member.memberId: ${member.memberId}');
      developer.log('🔍 [FIRESTORE] Owner member.name: ${member.name}');

      // PurchaseGroup.createファクトリを使用
      final newGroup = PurchaseGroup.create(
        groupId: groupId,
        groupName: groupName,
        members: [member],
      );

      // 新しいアーキテクチャ: ルートの'purchaseGroups'にドキュメントを作成
      final groupDocRef = _groupsCollection.doc(groupId);
      final groupData = {
        ..._groupToFirestore(newGroup),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      developer
          .log('🔥 [FIRESTORE] Group data prepared, writing to Firestore...');
      developer
          .log('🔍 [FIRESTORE] allowedUid in newGroup: ${newGroup.allowedUid}');
      developer.log(
          '🔍 [FIRESTORE] allowedUid in groupData: ${groupData['allowedUid']}');

      try {
        // シンプルなset操作でトランザクションを避ける（crash-proof）
        await groupDocRef.set(groupData);
        developer
            .log('✅ [FIRESTORE] Group write successful: $groupName ($groupId)');
      } catch (writeError) {
        developer
            .log('❌ [FIRESTORE] Write failed, trying transaction: $writeError');

        // setが失敗した場合のみトランザクションを試行
        await _firestore.runTransaction((transaction) async {
          transaction.set(groupDocRef, groupData);
        });
        developer.log(
            '✅ [FIRESTORE] Transaction write successful: $groupName ($groupId)');
      }

      developer.log(
          '🔥 [FIRESTORE] Created group in root collection: $groupName ($groupId)');
      return newGroup;
    } catch (e, st) {
      developer.log('❌ [FIRESTORE] createGroup error: $e');
      developer.log('📄 [FIRESTORE] StackTrace: $st');
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
      developer.log('🔥 [FIRESTORE] Fetching groups for user: $currentUserId');

      // 新しいアーキテクチャ: ルートの'purchaseGroups'をクエリ
      final groupsSnapshot = await _groupsCollection
          .where('allowedUid', arrayContains: currentUserId)
          .get();

      developer.log(
          '🔥 [FIRESTORE] Fetched groups count: ${groupsSnapshot.docs.length}');

      if (groupsSnapshot.docs.isEmpty) {
        developer.log('⚠️ [FIRESTORE] No groups found for this user.');
        return [];
      }

      final userGroups =
          groupsSnapshot.docs.map((doc) => _groupFromFirestore(doc)).toList();

      return userGroups;
    } catch (e, st) {
      developer.log('❌ Firestore getAllGroups error: $e\n$st');
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
      final updateData = _groupToFirestore(group);
      developer.log('🔍 [FIRESTORE UPDATE] groupId: $groupId');
      developer
          .log('🔍 [FIRESTORE UPDATE] group.allowedUid: ${group.allowedUid}');
      developer.log(
          '🔍 [FIRESTORE UPDATE] updateData[allowedUid]: ${updateData['allowedUid']}');

      // set(merge: true)を使用してドキュメントが存在しない場合も対応
      await _groupsCollection.doc(groupId).set({
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      developer
          .log('✅ [FIRESTORE UPDATE] Updated in Firestore: ${group.groupName}');
      return group;
    } catch (e) {
      developer.log('❌ Firestore updateGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    try {
      final user = _auth.currentUser;
      developer
          .log('🔍 [FIRESTORE DELETE] Attempting to delete group: $groupId');
      developer.log(
          '🔍 [FIRESTORE DELETE] User path: users/${user?.uid}/groups/$groupId');

      final doc = await _groupsCollection.doc(groupId).get();
      developer.log('🔍 [FIRESTORE DELETE] Document exists: ${doc.exists}');

      if (!doc.exists) {
        throw Exception('Group not found: $groupId (User: ${user?.uid})');
      }

      final group = _groupFromFirestore(doc);

      // 論理削除: isDeletedフラグを立てる（物理削除はしない）
      await _groupsCollection.doc(groupId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('🔥 [FIRESTORE] Marked group as deleted: $groupId');

      // 削除フラグを立てたグループを返す
      return group.copyWith(isDeleted: true, updatedAt: DateTime.now());
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

      // グループデータを更新（members配列が含まれている）
      await _groupsCollection
          .doc(groupId)
          .update(_groupToFirestore(updatedGroup));

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

      // グループデータを更新（members配列が含まれている）
      await _groupsCollection
          .doc(groupId)
          .update(_groupToFirestore(updatedGroup));

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
      'ownerUid': group.ownerUid,
      'allowedUid': group.allowedUid, // 🔥 CRITICAL: 招待機能に必須
      'members':
          group.members?.map((m) => _memberToFirestore(m)).toList() ?? [],
      'createdAt':
          group.createdAt != null ? Timestamp.fromDate(group.createdAt!) : null,
      'updatedAt':
          group.updatedAt != null ? Timestamp.fromDate(group.updatedAt!) : null,
      'isDeleted': group.isDeleted, // 削除フラグも保存
      // v4: シンプル化されたデータ構造
    };
  }

  Map<String, dynamic> _memberToFirestore(PurchaseGroupMember m) {
    return {
      'memberId': m.memberId,
      'name': m.name,
      'contact': m.contact,
      'role': m.role.name, // enumを文字列として保存
      'invitedAt':
          m.invitedAt != null ? Timestamp.fromDate(m.invitedAt!) : null,
      'acceptedAt':
          m.acceptedAt != null ? Timestamp.fromDate(m.acceptedAt!) : null,
    };
  }

  PurchaseGroup _groupFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final membersList = (data['members'] as List<dynamic>?)
            ?.map((memberData) =>
                _memberFromFirestore(memberData as Map<String, dynamic>))
            .toList() ??
        [];

    return PurchaseGroup(
      groupName: data['groupName'] ?? '',
      groupId: data['groupId'] ?? doc.id,
      ownerUid: data['ownerUid'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      allowedUid:
          List<String>.from(data['allowedUid'] ?? []), // 🔥 CRITICAL: これが抜けていた！
      members: membersList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  PurchaseGroupMember _memberFromFirestore(Map<String, dynamic> data) {
    return PurchaseGroupMember(
      memberId: data['uid'] ?? data['memberId'] ?? '',
      name: data['displayName'] ?? data['name'] ?? '',
      contact: data['contact'] ?? '',
      role: PurchaseGroupRole.values.firstWhere((e) => e.name == data['role'],
          orElse: () => PurchaseGroupRole.member),
      invitedAt: (data['invitedAt'] as Timestamp?)?.toDate() ??
          (data['joinedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate() ??
          (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }
}
