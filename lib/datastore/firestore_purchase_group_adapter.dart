// lib/datastore/firestore_purchase_group_adapter.dart
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../helpers/validation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// FirestoreをHive互換インターフェースで使用するためのアダプター
class FirestorePurchaseGroupAdapter implements PurchaseGroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirestorePurchaseGroupAdapter();

  CollectionReference get _groupsCollection =>
      _firestore.collection('purchaseGroups');

  @override
  Future<PurchaseGroup> addMember(
      String groupId, PurchaseGroupMember member) async {
    try {
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found: $groupId');
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final currentMembers = _parseMembers(groupData['members'] ?? []);

      // ValidationServiceを使った重複チェック
      if (member.contact != null) {
        final emailValidation = ValidationService.validateMemberEmail(
            member.contact!, currentMembers);
        if (emailValidation.hasError) {
          throw Exception(emailValidation.errorMessage);
        }
      }

      final nameValidation = ValidationService.validateMemberName(
          member.displayName, currentMembers);
      if (nameValidation.hasError) {
        throw Exception(nameValidation.errorMessage);
      }

      final updatedMembers = [...currentMembers, member];
      await _groupsCollection.doc(groupId).update({
        'members': updatedMembers.map((m) => _memberToMap(m)).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('➕ Firestore: メンバー追加: ${member.displayName} to $groupId');
      final group = _mapToGroup(groupData);
      return group.copyWith(members: updatedMembers);
    } catch (e) {
      developer.log('❌ Firestore: メンバー追加エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> removeMember(
      String groupId, PurchaseGroupMember member) async {
    try {
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found: $groupId');
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final currentMembers = _parseMembers(groupData['members'] ?? []);

      final updatedMembers =
          currentMembers.where((m) => m.uid != member.uid).toList();

      await _groupsCollection.doc(groupId).update({
        'members': updatedMembers.map((m) => _memberToMap(m)).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer
          .log('🚫 Firestore: メンバー削除: ${member.displayName} from $groupId');
      return _mapToGroup(groupData).copyWith(members: updatedMembers);
    } catch (e) {
      developer.log('❌ Firestore: メンバー削除エラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        // 認証されていない場合はデフォルトグループを作成
        return [await _createDefaultGroup()];
      }

      // ユーザーが参加しているグループを取得
      final querySnapshot = await _groupsCollection
          .where('memberEmails', arrayContains: currentUser.email)
          .get();

      final groups = querySnapshot.docs.map((doc) => _docToGroup(doc)).toList();

      if (groups.isEmpty) {
        // グループがない場合はデフォルトグループを作成
        groups.add(await _createDefaultGroup());
      }

      developer.log('📋 Firestore: グループ取得: ${groups.length}個');
      return groups;
    } catch (e) {
      developer.log('❌ Firestore: グループ取得エラー: $e');
      // エラー時はデフォルトグループを返す
      return [await _createDefaultGroup()];
    }
  }

  @override
  Future<PurchaseGroup> createGroup(
      String groupId, String groupName, PurchaseGroupMember member) async {
    try {
      final currentUser = _auth.currentUser;

      // グループ名の重複チェック
      final allGroups = await getAllGroups();
      final validation =
          ValidationService.validateGroupName(groupName, allGroups);
      if (validation.hasError) {
        throw Exception(validation.errorMessage);
      }

      final newGroup = PurchaseGroup(
        groupId: groupId,
        groupName: groupName,
        ownerUid: currentUser?.uid ?? member.uid,
        members: [member],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _groupsCollection.doc(groupId).set({
        'groupName': groupName,
        'ownerUid': newGroup.ownerUid,
        'ownerName': newGroup.ownerName,
        'ownerEmail': newGroup.ownerEmail,
        'members': [_memberToMap(member)],
        'memberEmails': [member.contact],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('🆕 Firestore: グループ作成: $groupName ($groupId)');
      return newGroup;
    } catch (e) {
      developer.log('❌ Firestore: グループ作成エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    try {
      await _groupsCollection.doc(groupId).delete();
      developer.log('🗑️ Firestore: グループ削除: $groupId');

      // 削除したグループを返す（削除されたことを示すため）
      return PurchaseGroup(
        groupId: groupId,
        groupName: 'Deleted Group',
        ownerUid: '',
        members: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      developer.log('❌ Firestore: グループ削除エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> setMemberId(
      String oldId, String newId, String? contact) async {
    // TODO: Firestore実装
    throw UnimplementedError('setMemberId not implemented for Firestore yet');
  }

  @override
  Future<PurchaseGroup> getGroupById(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (doc.exists) {
        return _docToGroup(doc);
      }
      throw Exception('Group not found: $groupId');
    } catch (e) {
      developer.log('❌ Firestore: グループ取得エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'groupName': group.groupName,
        'ownerUid': group.ownerUid,
        'members': group.members.map((m) => _memberToMap(m)).toList(),
        'memberEmails': group.members
            .map((m) => m.contact)
            .where((c) => c != null)
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('🔄 Firestore: グループ更新: $groupId');
      return group;
    } catch (e) {
      developer.log('❌ Firestore: グループ更新エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> getOrCreateMemberPool() async {
    // TODO: Firestore対応
    return PurchaseGroup(
      groupId: 'memberPool',
      groupName: 'Member Pool',
      ownerUid: '',
      members: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> syncMemberPool() async {
    // TODO: Firestore対応
    developer.log('📝 Firestore: Member pool sync (not implemented)');
  }

  @override
  Future<List<PurchaseGroupMember>> searchMembersInPool(String query) async {
    // TODO: Firestore対応
    return [];
  }

  @override
  Future<PurchaseGroupMember?> findMemberByEmail(String email) async {
    // TODO: Firestore対応
    return null;
  }

  // ヘルパーメソッド
  Future<PurchaseGroup> _createDefaultGroup() async {
    final currentUser = _auth.currentUser;
    const groupId = 'default_group';

    final defaultMember = PurchaseGroupMember(
      uid: currentUser?.uid ?? 'defaultUser',
      displayName: currentUser?.displayName ?? 'ユーザー',
      contact: currentUser?.email,
      role: PurchaseGroupRole.owner,
      joinedAt: DateTime.now(),
    );

    return PurchaseGroup(
      groupId: groupId,
      groupName: 'あなたのグループ',
      ownerUid: currentUser?.uid ?? 'defaultUser',
      members: [defaultMember],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  PurchaseGroup _docToGroup(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _mapToGroup(data).copyWith(groupId: doc.id);
  }

  PurchaseGroup _mapToGroup(Map<String, dynamic> data) {
    return PurchaseGroup(
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      members: _parseMembers(data['members'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  List<PurchaseGroupMember> _parseMembers(List<dynamic> membersData) {
    return membersData.map((memberData) {
      if (memberData is Map<String, dynamic>) {
        return PurchaseGroupMember(
          uid: memberData['uid'] ?? memberData['memberId'] ?? '',
          displayName: memberData['displayName'] ?? memberData['name'] ?? '',
          contact: memberData['contact'],
          role: _parseRole(memberData['role']),
          joinedAt: memberData['joinedAt'] != null
              ? (memberData['joinedAt'] as Timestamp).toDate()
              : null,
        );
      }
      return PurchaseGroupMember.create(
        uid: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Unknown',
        role: PurchaseGroupRole.member,
      );
    }).toList();
  }

  Map<String, dynamic> _memberToMap(PurchaseGroupMember member) {
    final map = <String, dynamic>{
      'uid': member.uid,
      'displayName': member.displayName,
      'role': member.role.name,
    };
    if (member.contact != null) {
      map['contact'] = member.contact!;
    }
    if (member.joinedAt != null) {
      map['joinedAt'] = Timestamp.fromDate(member.joinedAt!);
    }
    return map;
  }

  PurchaseGroupRole _parseRole(dynamic roleData) {
    if (roleData is String) {
      switch (roleData.toLowerCase()) {
        case 'owner':
          return PurchaseGroupRole.owner;
        case 'member':
        default:
          return PurchaseGroupRole.member;
      }
    }
    return PurchaseGroupRole.member;
  }
}
