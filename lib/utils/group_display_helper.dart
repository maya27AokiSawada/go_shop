import '../models/shared_group.dart';

class GroupDisplayHelper {
  const GroupDisplayHelper._();

  static String ownerLabel(SharedGroup group) {
    final trimmedOwnerName = group.ownerName?.trim();
    if (trimmedOwnerName != null && trimmedOwnerName.isNotEmpty) {
      return trimmedOwnerName;
    }

    final ownerUid = group.ownerUid;
    if (ownerUid != null && ownerUid.isNotEmpty) {
      final ownerMember = group.members?.firstWhere(
        (member) => member.memberId == ownerUid,
        orElse: () => const SharedGroupMember(
          memberId: '',
          name: '',
          contact: '',
          role: SharedGroupRole.member,
        ),
      );

      final ownerMemberName = ownerMember?.name.trim();
      if (ownerMemberName != null && ownerMemberName.isNotEmpty) {
        return ownerMemberName;
      }
    }

    return 'オーナー不明';
  }

  static bool hasNameCollision(
      SharedGroup targetGroup, List<SharedGroup> allGroups) {
    final normalizedTarget = targetGroup.groupName.trim().toLowerCase();
    if (normalizedTarget.isEmpty) {
      return false;
    }

    return allGroups.where((group) {
      if (group.groupId == targetGroup.groupId) {
        return false;
      }

      return group.groupName.trim().toLowerCase() == normalizedTarget;
    }).isNotEmpty;
  }

  static String displayName(
      SharedGroup targetGroup, List<SharedGroup> allGroups) {
    if (!hasNameCollision(targetGroup, allGroups)) {
      return targetGroup.groupName;
    }

    return '${ownerLabel(targetGroup)}さんの${targetGroup.groupName}';
  }
}
