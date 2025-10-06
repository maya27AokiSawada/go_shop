import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../flavors.dart';
import 'user_settings_provider.dart';

// Repository provider
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    throw UnimplementedError('FirestorePurchaseGroupRepository is not implemented yet');
  } else {
    return HivePurchaseGroupRepository(ref);
  }
});

// PurchaseGroup state notifier - selected group に基づいて動作
class PurchaseGroupNotifier extends AsyncNotifier<PurchaseGroup> {
  @override
  Future<PurchaseGroup> build() async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    
    try {
      // 指定されたグループIDのグループを取得
      final groups = await repository.getAllGroups();
      PurchaseGroup? targetGroup;
      
      if (groups.isNotEmpty) {
        // 選択されたグループIDのグループを探す
        targetGroup = groups.where((group) => group.groupId == selectedGroupId).firstOrNull;
        
        // 見つからない場合はデフォルトグループまたは最初のグループを使用
        targetGroup ??= groups.first;
        
        return await _fixLegacyMemberRoles(targetGroup);
      } else {
        // グループが存在しない場合はデフォルトグループを作成
        final userSettings = ref.read(userSettingsProvider).value;
        final userName = userSettings?.userName ?? 'デフォルトユーザー';
        final userEmail = userSettings?.userEmail ?? 'default@example.com';
        
        final ownerMember = PurchaseGroupMember.create(
          name: userName,
          contact: userEmail,
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
    
    if (group.members == null || group.members!.isEmpty) {
      return group;
    }
    
    bool needsUpdate = false;
    final originalMembers = group.members!;
    
    // Find the first owner or the first member to be the owner
    PurchaseGroupMember? owner;
    final List<PurchaseGroupMember> nonOwners = [];
    
    // First pass: separate owners and non-owners
    for (final member in originalMembers) {
      if (member.role == PurchaseGroupRole.owner) {
        if (owner == null) {
          owner = member; // Keep the first owner
        } else {
          // Convert additional owners to members
          nonOwners.add(member.copyWith(role: PurchaseGroupRole.member));
          needsUpdate = true;
        }
      } else {
        // Convert any legacy roles (parent, child) to member
        if (member.role != PurchaseGroupRole.member) {
          nonOwners.add(member.copyWith(role: PurchaseGroupRole.member));
          needsUpdate = true;
        } else {
          nonOwners.add(member);
        }
      }
    }
    
    // If no owner found, make the first member an owner
    if (owner == null && nonOwners.isNotEmpty) {
      final firstMember = nonOwners.removeAt(0);
      owner = firstMember.copyWith(role: PurchaseGroupRole.owner);
      needsUpdate = true;
    }
    
    if (needsUpdate && owner != null) {
      final fixedMembers = [owner, ...nonOwners];
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

  /// Load specific group by ID
  Future<void> loadGroup(String groupId) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      final group = await repository.getGroupById(groupId);
      final fixedGroup = await _fixLegacyMemberRoles(group);
      state = AsyncData(fixedGroup);
      
      // Update selected group ID
      ref.read(selectedGroupIdProvider.notifier).selectGroup(groupId);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
  Future<void> updateGroup(PurchaseGroup group) async {
    await saveGroup(group);
  }

  /// Add a new member to the current group
  Future<void> addMember(PurchaseGroupMember newMember) async {
    final currentGroup = state.value;
    if (currentGroup == null) return;

    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      await repository.addMember(currentGroup.groupId, newMember);
      // Reload the group to get updated data
      final updatedGroup = await repository.getGroupById(currentGroup.groupId);
      state = AsyncData(updatedGroup);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Create a new group
  Future<void> createNewGroup(String groupName) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      // UserSettingsから現在のユーザー情報を取得
      final userSettings = await ref.read(userSettingsProvider.future);
      
      // ユーザー情報が存在する場合はそれを使用、そうでなければデフォルト
      final userName = (userSettings.userName.isNotEmpty) ? userSettings.userName : 'デフォルトユーザー';
      final userEmail = (userSettings.userEmail.isNotEmpty) ? userSettings.userEmail : 'default@example.com';
      
      final ownerMember = PurchaseGroupMember.create(
        name: userName,
        contact: userEmail,
        role: PurchaseGroupRole.owner,
        isSignedIn: true,
      );
      
      final newGroup = await repository.createGroup(
        'group_${DateTime.now().millisecondsSinceEpoch}',
        groupName,
        ownerMember,
      );
      
      state = AsyncData(newGroup);
      
      // Refresh the all groups list so dropdown updates
      ref.read(allGroupsProvider.notifier).refresh();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Delete a group
  Future<void> deleteGroup(String groupId) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      await repository.deleteGroup(groupId);
      // After deletion, try to load another group or create default
      final groups = await repository.getAllGroups();
      if (groups.isNotEmpty) {
        state = AsyncData(groups.first);
      } else {
        // Create default group if no groups exist
        final userSettings = await ref.read(userSettingsProvider.future);
        final userName = (userSettings.userName.isNotEmpty) ? userSettings.userName : 'デフォルトユーザー';
        final userEmail = (userSettings.userEmail.isNotEmpty) ? userSettings.userEmail : 'default@example.com';
        
        final ownerMember = PurchaseGroupMember.create(
          name: userName,
          contact: userEmail,
          role: PurchaseGroupRole.owner,
          isSignedIn: true,
        );
        final defaultGroup = await repository.createGroup('defaultGroup', 'デフォルトグループ', ownerMember);
        state = AsyncData(defaultGroup);
      }
      
      // Refresh the all groups list so dropdown updates
      ref.read(allGroupsProvider.notifier).refresh();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

// Group selection management
class SelectedGroupIdNotifier extends StateNotifier<String> {
  SelectedGroupIdNotifier() : super('defaultGroup');

  void selectGroup(String groupId) {
    state = groupId;
  }
}

// All groups provider
class AllGroupsNotifier extends AsyncNotifier<List<PurchaseGroup>> {
  @override
  Future<List<PurchaseGroup>> build() async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      return await repository.getAllGroups();
    } catch (e) {
      throw Exception('Failed to load all groups: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

// Providers
final purchaseGroupProvider = AsyncNotifierProvider<PurchaseGroupNotifier, PurchaseGroup>(
  () => PurchaseGroupNotifier(),
);

final selectedGroupIdProvider = StateNotifierProvider<SelectedGroupIdNotifier, String>(
  (ref) => SelectedGroupIdNotifier(),
);

final allGroupsProvider = AsyncNotifierProvider<AllGroupsNotifier, List<PurchaseGroup>>(
  () => AllGroupsNotifier(),
);

// 選択されたグループIDに基づいて特定のグループを取得するプロバイダー
final selectedGroupProvider = Provider<AsyncValue<PurchaseGroup?>>((ref) {
  final selectedGroupId = ref.watch(selectedGroupIdProvider);
  final allGroupsAsync = ref.watch(allGroupsProvider);
  
  return allGroupsAsync.when(
    data: (groups) {
      // 隠しグループ（メンバープール）を除外
      final visibleGroups = groups.where((group) => group.groupId != '__member_pool__').toList();
      final selectedGroup = visibleGroups.where((group) => group.groupId == selectedGroupId).firstOrNull;
      return AsyncValue.data(selectedGroup);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
