// lib/services/enhanced_invitation_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../datastore/firestore_architecture.dart';
import '../providers/auth_provider.dart';
import 'dart:developer' as developer;

/// Enhanced invitation service with multi-group selection and role-based permissions
class EnhancedInvitationService {
  final Ref ref;

  EnhancedInvitationService(this.ref);

  /// Find all groups where the given email exists and current user can invite
  Future<List<GroupInvitationOption>> findInvitableGroups(
      String targetEmail) async {
    try {
      final currentUser = ref.read(authProvider).currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final userGroups =
          await FirestoreCollections.getUserPurchaseGroups(currentUser.uid)
              .get();
      final invitableGroups = <GroupInvitationOption>[];

      for (final doc in userGroups.docs) {
        final firestoreGroup =
            FirestorePurchaseGroup.fromFirestoreData(doc.data());

        // Check if current user can invite to this group
        if (firestoreGroup.canInviteUsers(currentUser.uid)) {
          // Check if target email already exists in group
          final existingMember = firestoreGroup.members?.firstWhere(
            (m) => m.contact.toLowerCase() == targetEmail.toLowerCase(),
            orElse: () => const PurchaseGroupMember(
                memberId: '', name: '', contact: '', role: PurchaseGroupRole.member),
          );

          final isAlreadyMember = existingMember?.contact.isNotEmpty == true;

          invitableGroups.add(GroupInvitationOption(
            group: firestoreGroup,
            canInvite: !isAlreadyMember,
            reason: isAlreadyMember ? 'すでにメンバーです' : null,
          ));
        }
      }

      developer.log('📧 招待可能グループ検索: ${invitableGroups.length}個見つかりました');
      return invitableGroups;
    } catch (e) {
      developer.log('❌ 招待可能グループ検索エラー: $e');
      rethrow;
    }
  }

  /// Send invitations to selected groups
  Future<InvitationResult> sendInvitations({
    required String targetEmail,
    required List<GroupInvitationData> selectedGroups,
    String? customMessage,
  }) async {
    try {
      final currentUser = ref.read(authProvider).currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final results = <String, bool>{};
      final errors = <String>[];

      for (final groupData in selectedGroups) {
        try {
          await _sendSingleInvitation(
            ownerUid: currentUser.uid,
            groupId: groupData.groupId,
            targetEmail: targetEmail,
            targetRole: groupData.targetRole,
            customMessage: customMessage,
          );
          results[groupData.groupId] = true;
          developer.log('✅ 招待送信成功: グループ ${groupData.groupId}');
        } catch (e) {
          results[groupData.groupId] = false;
          errors.add('グループ「${groupData.groupName}」: $e');
          developer.log('❌ 招待送信失敗: グループ ${groupData.groupId} - $e');
        }
      }

      return InvitationResult(
        success: errors.isEmpty,
        results: results,
        errors: errors,
        totalSent: results.values.where((success) => success).length,
        totalFailed: results.values.where((success) => !success).length,
      );
    } catch (e) {
      developer.log('❌ 招待送信エラー: $e');
      return InvitationResult(
        success: false,
        results: {},
        errors: [e.toString()],
        totalSent: 0,
        totalFailed: selectedGroups.length,
      );
    }
  }

  /// Send invitation to a single group
  Future<void> _sendSingleInvitation({
    required String ownerUid,
    required String groupId,
    required String targetEmail,
    required PurchaseGroupRole targetRole,
    String? customMessage,
  }) async {
    // Get group document
    final groupDoc =
        await FirestoreCollections.getPurchaseGroupDoc(ownerUid, groupId).get();
    if (!groupDoc.exists) {
      throw Exception('グループが見つかりません');
    }

    final firestoreGroup =
        FirestorePurchaseGroup.fromFirestoreData(groupDoc.data()!);

    // Verify current user can invite
    if (!firestoreGroup.canInviteUsers(ownerUid)) {
      throw Exception('招待権限がありません');
    }

    // Add to pending invitations if not already present
    final updatedPendingInvitations = [...firestoreGroup.pendingInvitations];
    if (!updatedPendingInvitations.contains(targetEmail)) {
      updatedPendingInvitations.add(targetEmail);
    }

    // Create new member entry (will be activated when invitation is accepted)
    final newMember = PurchaseGroupMember.create(
      name: targetEmail, // Will be updated when user accepts
      contact: targetEmail,
      role: targetRole,
      isSignedIn: false,
    );

    final updatedMembers = <PurchaseGroupMember>[
      ...(firestoreGroup.members ?? [])
    ];
    // Remove any existing member with same email and add new one
    updatedMembers.removeWhere(
        (m) => m.contact.toLowerCase() == targetEmail.toLowerCase());
    updatedMembers.add(newMember);

    final baseGroup = PurchaseGroup(
      groupName: firestoreGroup.groupName,
      groupId: firestoreGroup.groupId,
      ownerName: firestoreGroup.ownerName,
      ownerEmail: firestoreGroup.ownerEmail,
      ownerUid: firestoreGroup.ownerUid,
      members: updatedMembers,
      // shoppingListIds はサブコレクションに移行したため削除
    );

    final updatedGroup = FirestorePurchaseGroup(
      baseGroup: baseGroup,
      acceptedUids: firestoreGroup.acceptedUids,
      pendingInvitations: updatedPendingInvitations,
      createdAt: firestoreGroup.createdAt,
      updatedAt: DateTime.now(),
    );

    // Update Firestore
    await groupDoc.reference.update(updatedGroup.toFirestoreData());

    // TODO: Send actual email invitation
    // await _sendEmailInvitation(firestoreGroup, targetEmail, customMessage);

    developer
        .log('📧 招待送信完了: $targetEmail → グループ「${firestoreGroup.groupName}」');
  }

  /// Accept invitation by adding UID to acceptedUids list
  Future<void> acceptInvitation({
    required String ownerUid,
    required String groupId,
    required String userUid,
    String? userName,
  }) async {
    try {
      final groupDoc =
          await FirestoreCollections.getPurchaseGroupDoc(ownerUid, groupId)
              .get();
      if (!groupDoc.exists) {
        throw Exception('グループが見つかりません');
      }

      final firestoreGroup =
          FirestorePurchaseGroup.fromFirestoreData(groupDoc.data()!);

      // Accept invitation
      final updatedGroup = firestoreGroup.acceptInvitation(userUid);

      // Update member info with actual user name if provided
      if (userName != null) {
        final updatedMembers = updatedGroup.members?.map((member) {
          // Find member by UID in acceptedUids or by contact (for pending)
          if (updatedGroup.acceptedUids.contains(userUid)) {
            // Update the member info with actual user data
            return member.copyWith(
              name: userName,
              isSignedIn: true,
              isInvitationAccepted: true,
              acceptedAt: DateTime.now(),
            );
          }
          return member;
        }).toList();

        final finalBaseGroup = PurchaseGroup(
          groupName: updatedGroup.groupName,
          groupId: updatedGroup.groupId,
          ownerName: updatedGroup.ownerName,
          ownerEmail: updatedGroup.ownerEmail,
          ownerUid: updatedGroup.ownerUid,
          members: updatedMembers,
          // shoppingListIds はサブコレクションに移行したため削除
        );

        final finalGroup = FirestorePurchaseGroup(
          baseGroup: finalBaseGroup,
          acceptedUids: updatedGroup.acceptedUids,
          pendingInvitations: updatedGroup.pendingInvitations,
          createdAt: updatedGroup.createdAt,
          updatedAt: DateTime.now(),
        );

        await groupDoc.reference.update(finalGroup.toFirestoreData());
      } else {
        await groupDoc.reference.update(updatedGroup.toFirestoreData());
      }

      developer
          .log('✅ 招待受諾完了: UID $userUid → グループ「${firestoreGroup.groupName}」');
    } catch (e) {
      developer.log('❌ 招待受諾エラー: $e');
      rethrow;
    }
  }

  /// Find pending invitations for a user by email
  Future<List<PendingInvitation>> findPendingInvitations(
      String userEmail) async {
    try {
      final pendingInvitations = <PendingInvitation>[];

      // TODO: Implement global search across all users' groups
      // For now, we'll need to implement a separate invitations collection
      // or search mechanism in Firestore rules

      developer.log('🔍 未受諾招待検索: $userEmail');
      return pendingInvitations;
    } catch (e) {
      developer.log('❌ 未受諾招待検索エラー: $e');
      rethrow;
    }
  }
}

/// Group invitation option for selection UI
class GroupInvitationOption {
  final FirestorePurchaseGroup group;
  final bool canInvite;
  final String? reason;

  const GroupInvitationOption({
    required this.group,
    required this.canInvite,
    this.reason,
  });
}

/// Group invitation data for sending invitations
class GroupInvitationData {
  final String groupId;
  final String groupName;
  final PurchaseGroupRole targetRole;

  const GroupInvitationData({
    required this.groupId,
    required this.groupName,
    required this.targetRole,
  });
}

/// Result of invitation sending operation
class InvitationResult {
  final bool success;
  final Map<String, bool> results;
  final List<String> errors;
  final int totalSent;
  final int totalFailed;

  const InvitationResult({
    required this.success,
    required this.results,
    required this.errors,
    required this.totalSent,
    required this.totalFailed,
  });
}

/// Pending invitation data
class PendingInvitation {
  final String ownerUid;
  final String groupId;
  final String groupName;
  final String ownerName;
  final PurchaseGroupRole targetRole;
  final DateTime invitedAt;

  const PendingInvitation({
    required this.ownerUid,
    required this.groupId,
    required this.groupName,
    required this.ownerName,
    required this.targetRole,
    required this.invitedAt,
  });
}

/// Provider for enhanced invitation service
final enhancedInvitationServiceProvider =
    Provider<EnhancedInvitationService>((ref) {
  return EnhancedInvitationService(ref);
});
