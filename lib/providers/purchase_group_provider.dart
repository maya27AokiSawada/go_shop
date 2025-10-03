import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../flavors.dart';

// Repository provider
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    throw UnimplementedError('FirestorePurchaseGroupRepository is not implemented yet');
  } else {
    return HivePurchaseGroupRepository(ref);
  }
});

// PurchaseGroup state notifier
class PurchaseGroupNotifier extends AsyncNotifier<PurchaseGroup> {
  @override
  Future<PurchaseGroup> build() async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      final groups = await repository.getAllGroups();
      if (groups.isNotEmpty) {
        final defaultGroup = groups.first;
        return await _fixLegacyMemberRoles(defaultGroup);
      } else {
        // Create default group using the repository
        final ownerMember = PurchaseGroupMember.create(
          name: 'デフォルトユーザー',
          contact: 'default@example.com',
          role: PurchaseGroupRole.owner,
          isSignedIn: true,
        );
        final defaultGroup = await repository.createGroup('defaultGroup', 'デフォルトグループ', ownerMember);
        return defaultGroup;
      }
    } catch (e) {
      throw Exception('Failed to load purchase groups: $e');
    }
  }

  Future<PurchaseGroup> _fixLegacyMemberRoles(PurchaseGroup group) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    bool needsUpdate = false;
    final fixedMembers = group.members?.map((member) {
      PurchaseGroupRole fixedRole = member.role;
      
      if (member == group.members?.first) {
        if (member.role != PurchaseGroupRole.owner) {
          fixedRole = PurchaseGroupRole.owner;
          needsUpdate = true;
        }
      } else {
        if (member.role != PurchaseGroupRole.member && member.role != PurchaseGroupRole.owner) {
          fixedRole = PurchaseGroupRole.member;
          needsUpdate = true;
        }
      }
      
      return member.copyWith(role: fixedRole);
    }).toList();

    if (needsUpdate && fixedMembers != null) {
      final updatedGroup = group.copyWith(members: fixedMembers);
      await repository.updateGroup(group.groupId, updatedGroup);
      return updatedGroup;
    }
    
    return group;
  }

  Future<void> saveGroup(PurchaseGroup group) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      await repository.updateGroup(group.groupId, group);
      state = AsyncData(group);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final purchaseGroupProvider = AsyncNotifierProvider<PurchaseGroupNotifier, PurchaseGroup>(
  () => PurchaseGroupNotifier(),
);
