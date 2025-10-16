import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../datastore/hybrid_purchase_group_repository.dart';
import '../flavors.dart';
import '../helper/security_validator.dart';
import 'user_settings_provider.dart';
import 'auth_provider.dart';

// Repository provider - ハイブリッドリポジトリを使用
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    // 本番環境ではハイブリッド（Hive + Firestore）を使用
    return HybridPurchaseGroupRepository(ref);
  } else {
    // 開発環境ではHiveのみ
    return HivePurchaseGroupRepository(ref);
  }
});

// PurchaseGroup state notifier - selected group に基づいて動作
class PurchaseGroupNotifier extends AsyncNotifier<PurchaseGroup> {
  @override
  Future<PurchaseGroup> build() async {
    print('🔄 [PROVIDER BUILD] PurchaseGroupNotifier.build() 開始');
    final repository = ref.read(purchaseGroupRepositoryProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    print('🔄 [PROVIDER BUILD] selectedGroupId: $selectedGroupId');
    
    try {
      // 指定されたグループIDのグループを取得
      print('🔄 [PROVIDER BUILD] getAllGroups() 呼び出し開始');
      final groups = await repository.getAllGroups();
      print('🔄 [PROVIDER BUILD] getAllGroups() 完了: ${groups.length}件');
      PurchaseGroup? targetGroup;
      
      if (groups.isNotEmpty) {
        // 選択されたグループIDのグループを探す
        targetGroup = groups.where((group) => group.groupId == selectedGroupId).firstOrNull;
        print('🔄 [PROVIDER BUILD] targetGroup found: ${targetGroup?.groupName}');
        
        // 見つからない場合はデフォルトグループまたは最初のグループを使用
        targetGroup ??= groups.first;
        print('🔄 [PROVIDER BUILD] 最終 targetGroup: ${targetGroup.groupName}');
        
        print('🔄 [PROVIDER BUILD] _fixLegacyMemberRoles() 呼び出し開始');
        final result = await _fixLegacyMemberRoles(targetGroup);
        print('🔄 [PROVIDER BUILD] _fixLegacyMemberRoles() 完了');
        return result;
      } else {
        print('🔄 [PROVIDER BUILD] グループが存在しないため、デフォルトグループを作成');
        // グループが存在しない場合はデフォルトグループを作成
        // userSettingsProviderから直接データを取得（Asyncの場合は待機）
        final userSettingsAsync = await ref.read(userSettingsProvider.future);
        print('🔄 [PROVIDER BUILD] userSettings: $userSettingsAsync');
        final userName = userSettingsAsync.userName;
        final userEmail = userSettingsAsync.userEmail;
        print('🔄 [PROVIDER BUILD] userName: $userName, userEmail: $userEmail');
        
        // 現在のユーザーIDを取得
        final authService = ref.read(authProvider);
        final currentUser = authService.currentUser;
        final currentUserId = currentUser?.uid ?? '';
        print('🔄 [PROVIDER BUILD] currentUserId: $currentUserId');
        
        final ownerMember = PurchaseGroupMember.create(
          memberId: currentUserId,  // 現在のユーザーIDを明示的に設定
          name: userName,
          contact: userEmail,
          role: PurchaseGroupRole.owner,
          isSignedIn: true,
        );
        print('🔄 [PROVIDER BUILD] createGroup() 呼び出し開始');
        final defaultGroup = await repository.createGroup('defaultGroup', 'デフォルトグループ', ownerMember);
        print('🔄 [PROVIDER BUILD] createGroup() 完了');
        return defaultGroup;
      }
    } catch (e, stackTrace) {
      print('❌ [PROVIDER BUILD] エラー発生: $e');
      print('❌ [PROVIDER BUILD] スタックトレース: $stackTrace');
      throw Exception('Failed to load purchase groups: $e');
    }
  }

  Future<PurchaseGroup> _fixLegacyMemberRoles(PurchaseGroup group) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    if (group.members == null || group.members!.isEmpty) {
      return group;
    }
    
    // 現在のFirebaseユーザーIDを取得
    final authService = ref.read(authProvider);
    final currentUser = authService.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    
    bool needsUpdate = false;
    final originalMembers = group.members!;
    
    // 現在のユーザーが既存のメンバーに含まれているかチェック
    final hasCurrentUser = originalMembers.any((member) => member.memberId == currentUserId);
    
    print('🔧 [LEGACY FIX] currentUserId: $currentUserId');
    print('🔧 [LEGACY FIX] hasCurrentUser in group: $hasCurrentUser');
    
    // 現在のユーザーがメンバーリストにいない場合は、オーナーのmemberIdを更新
    if (!hasCurrentUser && currentUserId.isNotEmpty) {
      // オーナーメンバーを見つけて、そのmemberIdを現在のユーザーIDに変更
      final List<PurchaseGroupMember> updatedMembers = [];
      bool ownerUpdated = false;
      
      for (final member in originalMembers) {
        if (member.role == PurchaseGroupRole.owner && !ownerUpdated) {
          // オーナーのmemberIdを現在のFirebaseユーザーIDに更新
          final updatedOwner = member.copyWith(memberId: currentUserId);
          updatedMembers.add(updatedOwner);
          ownerUpdated = true;
          needsUpdate = true;
          print('🔧 [LEGACY FIX] Updated owner memberId from ${member.memberId} to $currentUserId');
        } else {
          updatedMembers.add(member);
        }
      }
      
      if (needsUpdate) {
        final updatedGroup = group.copyWith(members: updatedMembers);
        await repository.updateGroup(updatedGroup.groupId, updatedGroup);
        print('🔧 [LEGACY FIX] Group updated with corrected member IDs');
        return updatedGroup;
      }
    }
    
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
    print('💾 [SAVE GROUP] グループ保存開始: ${group.groupName}');
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      // 楽観的更新: 先にUIを更新
      state = AsyncData(group);
      print('💾 [SAVE GROUP] 楽観的更新完了');
      
      // バックグラウンドでデータベースに保存
      await repository.updateGroup(group.groupId, group);
      print('💾 [SAVE GROUP] データベース保存完了');
    } catch (e, stackTrace) {
      print('❌ [SAVE GROUP] エラー発生: $e');
      state = AsyncError(e, stackTrace);
      rethrow;
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
    print('👥 [ADD MEMBER] メンバー追加開始: ${newMember.name}');
    final currentGroup = state.value;
    if (currentGroup == null) {
      print('❌ [ADD MEMBER] currentGroupがnullです');
      return;
    }

    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      print('👥 [ADD MEMBER] 現在のメンバー数: ${currentGroup.members?.length ?? 0}');
      
      // 楽観的更新: 先にUIを更新
      final optimisticGroup = currentGroup.addMember(newMember);
      state = AsyncData(optimisticGroup);
      print('👥 [ADD MEMBER] 楽観的更新完了。新メンバー数: ${optimisticGroup.members?.length ?? 0}');
      
      // バックグラウンドでデータベースに保存
      await repository.addMember(currentGroup.groupId, newMember);
      print('👥 [ADD MEMBER] データベース保存完了');
      
      // 念のため最新データを取得（同期エラー防止）
      final updatedGroup = await repository.getGroupById(currentGroup.groupId);
      state = AsyncData(updatedGroup);
      print('👥 [ADD MEMBER] 最終更新完了');
    } catch (e, stackTrace) {
      print('❌ [ADD MEMBER] エラー発生: $e');
      print('❌ [ADD MEMBER] スタックトレース: $stackTrace');
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }

  /// Create a new group
  Future<void> createNewGroup(String groupName) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      print('🆕 グループ作成開始: $groupName');
      
      // 作成前の全グループ数を確認
      final beforeGroups = await repository.getAllGroups();
      print('📊 作成前のグループ数: ${beforeGroups.length}');
      for (var g in beforeGroups) {
        print('  - ${g.groupName} (${g.groupId})');
      }
      
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
      
      print('✅ グループ作成完了: ${newGroup.groupName} (${newGroup.groupId})');
      
      // 作成後の全グループ数を確認
      final afterGroups = await repository.getAllGroups();
      print('📊 作成後のグループ数: ${afterGroups.length}');
      for (var g in afterGroups) {
        print('  - ${g.groupName} (${g.groupId})');
      }
      
      // 新しいグループを選択状態に設定
      ref.read(selectedGroupIdProvider.notifier).selectGroup(newGroup.groupId);
      print('🎯 選択グループIDを設定: ${newGroup.groupId}');
      
      state = AsyncData(newGroup);
      
      // Refresh the all groups list so dropdown updates
      print('🔄 allGroupsProviderを更新開始');
      ref.invalidate(allGroupsProvider);
      await ref.read(allGroupsProvider.future);
      print('🔄 allGroupsProviderの更新完了');
      
      // 確認のため最新の状態を取得
      final updatedAllGroups = ref.read(allGroupsProvider);
      updatedAllGroups.when(
        data: (groups) {
          print('📋 更新後のallGroupsProvider: ${groups.length}グループ');
          for (var g in groups) {
            print('  - ${g.groupName} (${g.groupId})');
          }
        },
        loading: () => print('⏳ allGroupsProviderロード中'),
        error: (e, _) => print('❌ allGroupsProviderエラー: $e'),
      );
      
    } catch (e) {
      print('❌ グループ作成エラー: $e');
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

  /// Update owner message for the current group
  Future<void> updateOwnerMessage(String groupId, String message) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    
    try {
      final currentGroup = await repository.getGroupById(groupId);
      
      // 🔒 セキュリティチェック: オーナー権限確認
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && F.appFlavor == Flavor.prod) {
        SecurityValidator.validateFirestoreRuleCompliance(
          operation: 'write',
          resourceType: 'purchaseGroup',
          group: currentGroup,
          currentUid: currentUser.uid,
        );
      }
      
      // 楽観的更新: 先にUIを更新してからバックグラウンドで保存
      final updatedGroup = currentGroup.copyWith(ownerMessage: message);
      state = AsyncData(updatedGroup);
      
      // バックグラウンドで保存
      await repository.updateGroup(groupId, updatedGroup);
    } catch (e) {
      // エラーが発生したら元の状態に戻す
      state = AsyncError(e, StackTrace.current);
      rethrow;
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
    print('🔄 [ALL GROUPS] AllGroupsNotifier.build() 開始');
    final repository = ref.read(purchaseGroupRepositoryProvider);
    print('🔄 [ALL GROUPS] リポジトリ取得完了: ${repository.runtimeType}');
    
    try {
      print('🔄 [ALL GROUPS] getAllGroups() 呼び出し開始');
      final groups = await repository.getAllGroups();
      print('🔄 [ALL GROUPS] getAllGroups() 完了: ${groups.length}グループ');
      for (final group in groups) {
        print('🔄 [ALL GROUPS] - ${group.groupName} (${group.groupId})');
      }
      return groups;
    } catch (e, stackTrace) {
      print('❌ [ALL GROUPS] エラー発生: $e');
      print('❌ [ALL GROUPS] スタックトレース: $stackTrace');
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

// =================================================================
// ハイブリッド同期管理
// =================================================================

/// ハイブリッドリポジトリへのアクセス（本番環境のみ）
final hybridRepositoryProvider = Provider<HybridPurchaseGroupRepository?>((ref) {
  final repo = ref.read(purchaseGroupRepositoryProvider);
  if (repo is HybridPurchaseGroupRepository) {
    return repo;
  }
  return null;
});

/// 手動同期トリガー
final forceSyncProvider = FutureProvider<void>((ref) async {
  final hybridRepo = ref.read(hybridRepositoryProvider);
  if (hybridRepo != null) {
    await hybridRepo.forceSyncFromFirestore();
    // 同期後にAllGroupsProviderを更新
    ref.invalidate(allGroupsProvider);
  }
});

/// 同期状態プロバイダー
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final hybridRepo = ref.read(hybridRepositoryProvider);
  if (hybridRepo == null) {
    return SyncStatus.localOnly;
  }
  
  if (!hybridRepo.isOnline) {
    return SyncStatus.offline;
  }
  
  if (hybridRepo.isSyncing) {
    return SyncStatus.syncing;
  }
  
  return SyncStatus.synced;
});

/// 同期状態enum
enum SyncStatus {
  localOnly,  // ローカルのみ（dev環境）
  offline,    // オフライン
  syncing,    // 同期中
  synced,     // 同期済み
}
