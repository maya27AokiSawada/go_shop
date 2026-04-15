// lib/datastore/firestore_shared_group_adapter.dart
import '../models/shared_group.dart';
import '../datastore/shared_group_repository.dart';
import '../helpers/validation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// FirestoreをHive互換インターフェースで使用するためのアダプター
class FirestoreSharedGroupAdapter implements SharedGroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirestoreSharedGroupAdapter();

  CollectionReference get _groupsCollection =>
      _firestore.collection('SharedGroups');

  @override
  Future<SharedGroup> addMember(
      String groupId, SharedGroupMember member) async {
    try {
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found: $groupId');
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final currentMembers = _parseMembers(groupData['members'] ?? []);

      // ValidationServiceを使った重複チェック
      final emailValidation =
          ValidationService.validateMemberEmail(member.contact, currentMembers);
      if (emailValidation.hasError) {
        throw Exception(emailValidation.errorMessage);
      }

      final nameValidation =
          ValidationService.validateMemberName(member.name, currentMembers);
      if (nameValidation.hasError) {
        throw Exception(nameValidation.errorMessage);
      }

      final updatedMembers = [...currentMembers, member];
      await _groupsCollection.doc(groupId).update({
        'members': updatedMembers.map((m) => _memberToMap(m)).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('➕ Firestore: メンバー追加: ${member.name} to $groupId');
      final group = _mapToGroup(groupData);
      return group.copyWith(members: updatedMembers);
    } catch (e) {
      developer.log('❌ Firestore: メンバー追加エラー: $e');
      rethrow;
    }
  }

  @override
  Future<SharedGroup> removeMember(
      String groupId, SharedGroupMember member) async {
    try {
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found: $groupId');
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final currentMembers = _parseMembers(groupData['members'] ?? []);

      final updatedMembers =
          currentMembers.where((m) => m.memberId != member.memberId).toList();

      await _groupsCollection.doc(groupId).update({
        'members': updatedMembers.map((m) => _memberToMap(m)).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('🚫 Firestore: メンバー削除: ${member.name} from $groupId');
      return _mapToGroup(groupData).copyWith(members: updatedMembers);
    } catch (e) {
      developer.log('❌ Firestore: メンバー削除エラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<SharedGroup>> getAllGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        // 🔥 CHANGED: 認証されていない場合は空配列を返す（初回セットアップ画面へ）
        return [];
      }

      // ユーザーが参加しているグループを取得
      final querySnapshot = await _groupsCollection
          .where('memberEmails', arrayContains: currentUser.email)
          .get();

      final groups = querySnapshot.docs.map((doc) => _docToGroup(doc)).toList();

      // 🔥 CHANGED: グループがない場合も空配列を返す（初回セットアップ画面へ）

      developer.log('📋 Firestore: グループ取得: ${groups.length}個');
      return groups;
    } catch (e) {
      developer.log('❌ Firestore: グループ取得エラー: $e');
      // 🔥 CHANGED: エラー時も空配列を返す（初回セットアップ画面へ）
      return [];
    }
  }

  @override
  Future<SharedGroup> createGroup(
      String groupId, String groupName, SharedGroupMember member) async {
    try {
      final currentUser = _auth.currentUser;

      // グループ名の重複チェック
      final allGroups = await getAllGroups();
      final validation =
          ValidationService.validateGroupName(groupName, allGroups);
      if (validation.hasError) {
        throw Exception(validation.errorMessage);
      }

      final newGroup = SharedGroup(
        groupId: groupId,
        groupName: groupName,
        ownerUid: currentUser?.uid ?? member.memberId,
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
  Future<SharedGroup> deleteGroup(String groupId) async {
    try {
      await _groupsCollection.doc(groupId).delete();
      developer.log('🗑️ Firestore: グループ削除: $groupId');

      // 削除したグループを返す（削除されたことを示すため）
      return SharedGroup(
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
  Future<SharedGroup> setMemberId(
      String oldId, String newId, String? contact) async {
    // TODO: Firestore実装
    throw UnimplementedError('setMemberId not implemented for Firestore yet');
  }

  @override
  Future<SharedGroup> getGroupById(String groupId) async {
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
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'groupName': group.groupName,
        'ownerUid': group.ownerUid,
        'members': group.members?.map((m) => _memberToMap(m)).toList() ?? [],
        'memberEmails': group.members?.map((m) => m.contact).toList() ?? [],
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
  Future<SharedGroup> getOrCreateMemberPool() async {
    // TODO: Firestore対応
    return SharedGroup(
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
  Future<List<SharedGroupMember>> searchMembersInPool(String query) async {
    // TODO: Firestore対応
    return [];
  }

  @override
  Future<SharedGroupMember?> findMemberByEmail(String email) async {
    // TODO: Firestore対応
    return null;
  }

  // 🔥 REMOVED: _createDefaultGroup() - デフォルトグループ機能削除

  SharedGroup _docToGroup(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _mapToGroup(data).copyWith(groupId: doc.id);
  }

  SharedGroup _mapToGroup(Map<String, dynamic> data) {
    return SharedGroup(
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      members: _parseMembers(data['members'] ?? []),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// 🔥 FIX: Timestamp/String両対応のDateTime変換
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        developer.log('⚠️ Unknown datetime type: ${value.runtimeType}');
        return DateTime.now();
      }
    } catch (e) {
      developer.log('❌ DateTime parse error: $e, value: $value');
      return DateTime.now();
    }
  }

  List<SharedGroupMember> _parseMembers(List<dynamic> membersData) {
    return membersData.map((memberData) {
      if (memberData is Map<String, dynamic>) {
        return SharedGroupMember(
          memberId: memberData['uid'] ?? memberData['memberId'] ?? '',
          name: memberData['displayName'] ?? memberData['name'] ?? '',
          contact: memberData['contact'] ?? '',
          role: _parseRole(memberData['role']),
          invitedAt:
              _parseDateTime(memberData['invitedAt'] ?? memberData['joinedAt']),
          acceptedAt: _parseDateTimeNullable(
              memberData['acceptedAt'] ?? memberData['joinedAt']),
        );
      }
      return SharedGroupMember(
        memberId: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Unknown',
        contact: '',
        role: SharedGroupRole.member,
        invitedAt: DateTime.now(),
      );
    }).toList();
  }

  /// 🔥 FIX: Nullable DateTime変換
  DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        developer.log('⚠️ Unknown datetime type: ${value.runtimeType}');
        return null;
      }
    } catch (e) {
      developer.log('❌ DateTime parse error: $e, value: $value');
      return null;
    }
  }

  Map<String, dynamic> _memberToMap(SharedGroupMember member) {
    final map = <String, dynamic>{
      'memberId': member.memberId,
      'name': member.name,
      'contact': member.contact,
      'role': member.role.name,
    };
    if (member.invitedAt != null) {
      map['invitedAt'] = Timestamp.fromDate(member.invitedAt!);
    }
    if (member.acceptedAt != null) {
      map['acceptedAt'] = Timestamp.fromDate(member.acceptedAt!);
    }
    return map;
  }

  SharedGroupRole _parseRole(dynamic roleData) {
    if (roleData is String) {
      switch (roleData.toLowerCase()) {
        case 'owner':
          return SharedGroupRole.owner;
        case 'manager':
          return SharedGroupRole.manager;
        case 'member':
        default:
          return SharedGroupRole.member;
      }
    }
    return SharedGroupRole.member;
  }

  @override
  Future<int> cleanupDeletedGroups() async {
    // FirestoreアダプターではHiveのような物理削除は不要
    // 論理削除されたデータは自動的にクエリから除外される
    developer.log(
        '⚠️ [ADAPTER] cleanupDeletedGroups is not implemented (Firestore manages this automatically)');
    return 0;
  }
}
