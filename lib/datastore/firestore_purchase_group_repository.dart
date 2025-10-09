import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import 'dart:developer' as developer;

class FirestorePurchaseGroupRepository implements PurchaseGroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _groupsCollection => _firestore.collection('purchaseGroups');

  @override
  Future<PurchaseGroup> createGroup(String groupId, String groupName, PurchaseGroupMember member) async {
    try {
      final newGroup = PurchaseGroup.create(
        groupId: groupId,
        groupName: groupName,
        ownerName: member.name,
        ownerEmail: member.contact,
        ownerUid: member.memberId,
        members: [member],
      );

      await _groupsCollection.doc(groupId).set(_groupToFirestore(newGroup));

      developer.log('🔥 Created in Firestore: $groupName');
      return newGroup;
    } catch (e) {
      developer.log('❌ Firestore createGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    try {
      final snapshot = await _groupsCollection.get();
      final groups = snapshot.docs
          .map((doc) => _groupFromFirestore(doc))
          .toList();
      
      developer.log('🔥 Fetched ${groups.length} groups from Firestore');
      return groups;
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
      await _groupsCollection.doc(groupId).delete();
      
      developer.log('🔥 Deleted from Firestore: $groupId');
      return group;
    } catch (e) {
      developer.log('❌ Firestore deleteGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> addMember(String groupId, PurchaseGroupMember member) async {
    try {
      final group = await getGroupById(groupId);
      final updatedGroup = group.addMember(member);
      return await updateGroup(groupId, updatedGroup);
    } catch (e) {
      developer.log('❌ Firestore addMember error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> removeMember(String groupId, PurchaseGroupMember member) async {
    try {
      final group = await getGroupById(groupId);
      final updatedGroup = group.removeMember(member);
      return await updateGroup(groupId, updatedGroup);
    } catch (e) {
      developer.log('❌ Firestore removeMember error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> setMemberId(String oldId, String newId, String? contact) async {
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
    throw UnimplementedError('🔒 Member pool is local-only for privacy protection');
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
      'members': group.members?.map((m) => {
        'memberId': m.memberId,
        'name': m.name,
        'contact': m.contact,
        'role': m.role.index,
        'isSignedIn': m.isSignedIn,
        'isInvited': m.isInvited,
        'isInvitationAccepted': m.isInvitationAccepted,
        'invitedAt': m.invitedAt?.millisecondsSinceEpoch,
        'acceptedAt': m.acceptedAt?.millisecondsSinceEpoch,
      }).toList(),
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
              ? DateTime.fromMillisecondsSinceEpoch(memberData['acceptedAt'])
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