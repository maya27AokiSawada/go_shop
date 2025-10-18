// lib/providers/enhanced_group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../services/enhanced_invitation_service.dart';

import '../providers/purchase_group_provider.dart';
import 'dart:developer' as developer;

/// Enhanced group management with invitation features
class EnhancedGroupNotifier extends AsyncNotifier<EnhancedGroupState> {
  @override
  Future<EnhancedGroupState> build() async {
    final allGroups = await ref.watch(allGroupsProvider.future);
    final currentGroup = ref.watch(selectedGroupNotifierProvider).value;
    
    return EnhancedGroupState(
      allGroups: allGroups,
      currentGroup: currentGroup,
      isLoading: false,
    );
  }
  
  /// Send invitation with multi-group selection
  Future<InvitationResult?> sendEnhancedInvitation(String targetEmail) async {
    try {
      state = state.whenData((data) => data.copyWith(isLoading: true));
      
      final invitationService = ref.read(enhancedInvitationServiceProvider);
      final availableGroups = await invitationService.findInvitableGroups(targetEmail);
      
      if (availableGroups.isEmpty) {
        throw Exception('招待可能なグループがありません');
      }
      
      // If only one group is available, use it directly
      if (availableGroups.length == 1 && availableGroups.first.canInvite) {
        final group = availableGroups.first.group;
        return await invitationService.sendInvitations(
          targetEmail: targetEmail,
          selectedGroups: [
            GroupInvitationData(
              groupId: group.groupId,
              groupName: group.groupName,
              targetRole: PurchaseGroupRole.member,
            ),
          ],
        );
      }
      
      // Return available groups for UI selection
      state = state.whenData((data) => data.copyWith(
        isLoading: false,
        availableInvitationGroups: availableGroups,
        pendingInvitationEmail: targetEmail,
      ));
      
      return null; // UI should handle multi-group selection
    } catch (e) {
      developer.log('❌ Enhanced invitation error: $e');
      state = state.whenData((data) => data.copyWith(isLoading: false));
      rethrow;
    }
  }
  
  /// Complete multi-group invitation after UI selection
  Future<InvitationResult> completeMultiGroupInvitation(
    String targetEmail,
    List<GroupInvitationData> selectedGroups,
    {String? customMessage}
  ) async {
    try {
      state = state.whenData((data) => data.copyWith(isLoading: true));
      
      final invitationService = ref.read(enhancedInvitationServiceProvider);
      final result = await invitationService.sendInvitations(
        targetEmail: targetEmail,
        selectedGroups: selectedGroups,
        customMessage: customMessage,
      );
      
      // Clear pending invitation state
      state = state.whenData((data) => data.copyWith(
        isLoading: false,
        availableInvitationGroups: [],
        pendingInvitationEmail: null,
      ));
      
      return result;
    } catch (e) {
      state = state.whenData((data) => data.copyWith(isLoading: false));
      rethrow;
    }
  }
  
  /// Accept invitation
  Future<void> acceptInvitation({
    required String ownerUid,
    required String groupId,
    required String userUid,
    String? userName,
  }) async {
    try {
      final invitationService = ref.read(enhancedInvitationServiceProvider);
      await invitationService.acceptInvitation(
        ownerUid: ownerUid,
        groupId: groupId,
        userUid: userUid,
        userName: userName,
      );
      
      // Refresh groups after acceptance
      ref.invalidate(allGroupsProvider);
      ref.invalidate(selectedGroupNotifierProvider);
    } catch (e) {
      developer.log('❌ Invitation acceptance error: $e');
      rethrow;
    }
  }
  
  /// Create new group with optional member copy
  Future<bool> createGroupWithCopy({
    required String groupName,
    PurchaseGroup? sourceGroup,
    List<String>? selectedMemberIds,
    Map<String, PurchaseGroupRole>? memberRoles,
  }) async {
    try {
      state = state.whenData((data) => data.copyWith(isLoading: true));
      
      // Create basic group first
      await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
      
      // Add copied members if specified
      if (sourceGroup?.members != null && 
          selectedMemberIds != null && 
          selectedMemberIds.isNotEmpty) {
        
        await _copySelectedMembers(
          sourceGroup: sourceGroup!,
          selectedMemberIds: selectedMemberIds,
          memberRoles: memberRoles ?? {},
        );
      }
      
      // Refresh state
      await ref.read(allGroupsProvider.notifier).refresh();
      state = state.whenData((data) => data.copyWith(isLoading: false));
      
      return true;
    } catch (e) {
      developer.log('❌ Group creation with copy error: $e');
      state = state.whenData((data) => data.copyWith(isLoading: false));
      rethrow;
    }
  }
  
  Future<void> _copySelectedMembers({
    required PurchaseGroup sourceGroup,
    required List<String> selectedMemberIds,
    required Map<String, PurchaseGroupRole> memberRoles,
  }) async {
    final selectedGroupNotifier = ref.read(selectedGroupNotifierProvider.notifier);
    
    for (final member in sourceGroup.members ?? <PurchaseGroupMember>[]) {
      if (selectedMemberIds.contains(member.memberId) && 
          member.role != PurchaseGroupRole.owner) {
        
        final newRole = memberRoles[member.memberId] ?? member.role;
        
        final newMember = PurchaseGroupMember.create(
          name: member.name,
          contact: member.contact,
          role: newRole,
          isSignedIn: member.isSignedIn,
          isInvited: member.isInvited,
          isInvitationAccepted: member.isInvitationAccepted,
          invitedAt: member.invitedAt,
          acceptedAt: member.acceptedAt,
        );
        
        await selectedGroupNotifier.addMember(newMember);
      }
    }
  }
  
  /// Check if current user can invite others to a group
  bool canInviteToGroup(PurchaseGroup group, String currentUserId) {
    final member = group.members?.firstWhere(
      (m) => m.memberId == currentUserId,
      orElse: () => const PurchaseGroupMember(
        memberId: '', 
        name: '', 
        contact: '', 
        role: PurchaseGroupRole.member,
      ),
    );
    
    return member?.role == PurchaseGroupRole.owner || 
           member?.role == PurchaseGroupRole.manager;
  }
  
  /// Clear pending invitation state
  void clearPendingInvitation() {
    state = state.whenData((data) => data.copyWith(
      availableInvitationGroups: [],
      pendingInvitationEmail: null,
    ));
  }
}

/// Enhanced group state with invitation features
class EnhancedGroupState {
  final List<PurchaseGroup> allGroups;
  final PurchaseGroup? currentGroup;
  final bool isLoading;
  final List<GroupInvitationOption> availableInvitationGroups;
  final String? pendingInvitationEmail;
  
  const EnhancedGroupState({
    required this.allGroups,
    this.currentGroup,
    this.isLoading = false,
    this.availableInvitationGroups = const [],
    this.pendingInvitationEmail,
  });
  
  EnhancedGroupState copyWith({
    List<PurchaseGroup>? allGroups,
    PurchaseGroup? currentGroup,
    bool? isLoading,
    List<GroupInvitationOption>? availableInvitationGroups,
    String? pendingInvitationEmail,
  }) {
    return EnhancedGroupState(
      allGroups: allGroups ?? this.allGroups,
      currentGroup: currentGroup ?? this.currentGroup,
      isLoading: isLoading ?? this.isLoading,
      availableInvitationGroups: availableInvitationGroups ?? this.availableInvitationGroups,
      pendingInvitationEmail: pendingInvitationEmail ?? this.pendingInvitationEmail,
    );
  }
}

/// Enhanced group provider
final enhancedGroupProvider = AsyncNotifierProvider<EnhancedGroupNotifier, EnhancedGroupState>(
  () => EnhancedGroupNotifier(),
);

/// Helper providers for UI state management
final canCurrentUserInviteProvider = Provider<bool>((ref) {
  final groupState = ref.watch(enhancedGroupProvider).value;
  if (groupState?.currentGroup == null) return false;
  
  // TODO: Get current user ID from auth provider
  // For now, assume current user is owner
  return true;
});

final hasPendingInvitationProvider = Provider<bool>((ref) {
  final groupState = ref.watch(enhancedGroupProvider).value;
  return groupState?.availableInvitationGroups.isNotEmpty == true;
});