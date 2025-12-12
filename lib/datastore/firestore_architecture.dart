// lib/datastore/firestore_architecture.dart
/// Firestore Collection Architecture for Go Shop
///
/// Owner UID Collection Structure:
///
/// /users/{ownerUid}/SharedGroups/{groupId} - Purchase Group Document
/// /users/{ownerUid}/sharedLists/{listId} - Shopping List Document
///
/// Each Purchase Group contains:
/// - Basic group info (name, creation date, etc.)
/// - Members list with roles
/// - AcceptedUids list (users who accepted invitations)
/// - SharedListIds array (references to shopping lists)
///
/// Invitation Flow:
/// 1. Owner/Manager creates invitation for specific group
/// 2. If multiple groups have same email, show selection UI
/// 3. Invited user adds their UID to AcceptedUids list
/// 4. User sync happens only on invitation acceptance
///
/// Role-based Permissions:
/// - Owner: Full access, can invite others
/// - Manager: Can invite others, manage group
/// - Member: View and edit lists only
///
/// Group Management:
/// - Different roles require separate groups
/// - Provide UI to copy existing members when creating new group
/// - Multiple invitation selection for same email addresses

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_group.dart';

class FirestoreCollections {
  static const String users = 'users';
  static const String SharedGroups = 'SharedGroups';
  static const String sharedLists = 'sharedLists';

  /// Get user's purchase groups collection reference
  static CollectionReference<Map<String, dynamic>> getUserSharedGroups(
      String ownerUid) {
    return FirebaseFirestore.instance
        .collection(users)
        .doc(ownerUid)
        .collection(SharedGroups);
  }

  /// Get user's shopping lists collection reference
  static CollectionReference<Map<String, dynamic>> getUserSharedLists(
      String ownerUid) {
    return FirebaseFirestore.instance
        .collection(users)
        .doc(ownerUid)
        .collection(sharedLists);
  }

  /// Get specific purchase group document reference
  static DocumentReference<Map<String, dynamic>> getSharedGroupDoc(
      String ownerUid, String groupId) {
    return getUserSharedGroups(ownerUid).doc(groupId);
  }

  /// Get specific shopping list document reference
  static DocumentReference<Map<String, dynamic>> getSharedListDoc(
      String ownerUid, String listId) {
    return getUserSharedLists(ownerUid).doc(listId);
  }
}

/// Extended Purchase Group for Firestore with invitation management
class FirestoreSharedGroup {
  final SharedGroup baseGroup;
  final List<String> acceptedUids;
  final List<String> pendingInvitations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreSharedGroup({
    required this.baseGroup,
    this.acceptedUids = const [],
    this.pendingInvitations = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Convenience getters to access base group properties
  String get groupName => baseGroup.groupName;
  String get groupId => baseGroup.groupId;
  String? get ownerName => baseGroup.ownerName;
  String? get ownerEmail => baseGroup.ownerEmail;
  String? get ownerUid => baseGroup.ownerUid;
  List<SharedGroupMember>? get members => baseGroup.members;
  // sharedListIds はサブコレクションに移行したため削除

  /// Create from base SharedGroup
  factory FirestoreSharedGroup.fromSharedGroup(
    SharedGroup group, {
    List<String> acceptedUids = const [],
    List<String> pendingInvitations = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return FirestoreSharedGroup(
      baseGroup: group,
      acceptedUids: acceptedUids,
      pendingInvitations: pendingInvitations,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestoreData() {
    return {
      'groupName': groupName,
      'groupId': groupId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerUid': ownerUid,
      'members': members
              ?.map((m) => {
                    'memberId': m.memberId,
                    'name': m.name,
                    'contact': m.contact,
                    'role': m.role.name,
                    'isSignedIn': m.isSignedIn,
                  })
              .toList() ??
          [],
      // 'sharedListIds': sharedListIds, // サブコレクションに移行したため削除
      'acceptedUids': acceptedUids,
      'pendingInvitations': pendingInvitations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Firestore document data
  factory FirestoreSharedGroup.fromFirestoreData(Map<String, dynamic> data) {
    final baseGroup = SharedGroup(
      groupName: data['groupName'] ?? '',
      groupId: data['groupId'] ?? '',
      ownerName: data['ownerName'],
      ownerEmail: data['ownerEmail'],
      ownerUid: data['ownerUid'],
      members: (data['members'] as List<dynamic>?)
          ?.map((m) => SharedGroupMember(
                memberId: m['memberId'] ?? '',
                name: m['name'] ?? '',
                contact: m['contact'] ?? '',
                role: SharedGroupRole.values.firstWhere(
                  (r) => r.name == m['role'],
                  orElse: () => SharedGroupRole.member,
                ),
                isSignedIn: m['isSignedIn'] ?? false,
              ))
          .toList(),
      // sharedListIds はサブコレクションに移行したため削除
    );

    return FirestoreSharedGroup(
      baseGroup: baseGroup,
      acceptedUids: List<String>.from(data['acceptedUids'] ?? []),
      pendingInvitations: List<String>.from(data['pendingInvitations'] ?? []),
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Check if user can invite others (Owner or Manager only)
  bool canInviteUsers(String userId) {
    final member = members?.firstWhere(
      (m) => m.memberId == userId,
      orElse: () => const SharedGroupMember(
          memberId: '', name: '', contact: '', role: SharedGroupRole.member),
    );

    return member?.role == SharedGroupRole.owner ||
        member?.role == SharedGroupRole.manager;
  }

  /// Add accepted UID to the list
  FirestoreSharedGroup acceptInvitation(String uid) {
    if (acceptedUids.contains(uid)) return this;

    return FirestoreSharedGroup(
      baseGroup: baseGroup,
      acceptedUids: [...acceptedUids, uid],
      pendingInvitations:
          pendingInvitations.where((email) => email != uid).toList(),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to base SharedGroup
  SharedGroup toSharedGroup() {
    return SharedGroup(
      groupName: groupName,
      groupId: groupId,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerUid: ownerUid,
      members: members,
      // sharedListIds はサブコレクションに移行したため削除
    );
  }
}

/// Invitation data structure
class GroupInvitation {
  final String groupId;
  final String groupName;
  final String ownerName;
  final String ownerEmail;
  final String invitedEmail;
  final SharedGroupRole targetRole;
  final DateTime createdAt;

  const GroupInvitation({
    required this.groupId,
    required this.groupName,
    required this.ownerName,
    required this.ownerEmail,
    required this.invitedEmail,
    required this.targetRole,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'invitedEmail': invitedEmail,
      'targetRole': targetRole.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupInvitation.fromMap(Map<String, dynamic> map) {
    return GroupInvitation(
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      invitedEmail: map['invitedEmail'] ?? '',
      targetRole: SharedGroupRole.values.firstWhere(
        (r) => r.name == map['targetRole'],
        orElse: () => SharedGroupRole.member,
      ),
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
