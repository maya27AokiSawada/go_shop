import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../datastore/hybrid_purchase_group_repository.dart';
import '../flavors.dart';
import '../helper/security_validator.dart';
import 'user_settings_provider.dart';
import 'auth_provider.dart';

// Logger instance

// Repository provider - ハイブリッドリポジトリを使用
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((
  ref,
) {
  if (F.appFlavor == Flavor.prod) {
    // 本番環境ではハイブリッド（Hive + Firestore）を使用
    return HybridPurchaseGroupRepository(ref);
  } else {
    // 開発環境ではHiveのみ
    return HivePurchaseGroupRepository(ref);
  }
});

// Selected Group Management - 選択されたグループの詳細操作用
class SelectedGroupNotifier extends AsyncNotifier<PurchaseGroup?> {
  @override
  Future<PurchaseGroup?> build() async {
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    if (selectedGroupId.isEmpty) return null;

    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      AppLogger.info(
        '🔄 [SELECTED GROUP] SelectedGroupNotifier.build() 開始: $selectedGroupId',
      );
      final group = await repository.getGroupById(selectedGroupId);
      final fixedGroup = await _fixLegacyMemberRoles(group);
      AppLogger.info('🔄 [SELECTED GROUP] グループロード完了: ${fixedGroup.groupName}');
      return fixedGroup;
    } catch (e, stackTrace) {
      AppLogger.error('❌ [SELECTED GROUP] ビルドエラー: $e');
      AppLogger.error('❌ [SELECTED GROUP] スタックトレース: $stackTrace');
      return null;
    }
  }

  /// Fix legacy member roles and ensure proper group structure
  Future<PurchaseGroup> _fixLegacyMemberRoles(PurchaseGroup group) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    final originalMembers = group.members ?? [];
    bool needsUpdate = false;

    // Get current Firebase user ID for owner validation
    User? currentUser;
    try {
      if (F.appFlavor != Flavor.dev) {
        currentUser = FirebaseAuth.instance.currentUser;
      }
    } catch (e) {
      Log.info('🔄 [SELECTED GROUP] Firebase利用不可（開発環境）: $e');
      currentUser = null;
    }
    final currentUserId = currentUser?.uid ?? '';

    // 現在のユーザーが既存のメンバーに含まれているかチェック
    final hasCurrentUser = originalMembers.any(
      (member) => member.memberId == currentUserId,
    );

    Log.info('🔧 [LEGACY FIX] currentUserId: $currentUserId');
    Log.info('🔧 [LEGACY FIX] hasCurrentUser in group: $hasCurrentUser');

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
          Log.info(
            '🔧 [LEGACY FIX] Updated owner memberId from ${member.memberId} to $currentUserId',
          );
        } else {
          updatedMembers.add(member);
        }
      }

      if (needsUpdate) {
        final updatedGroup = group.copyWith(members: updatedMembers);
        await repository.updateGroup(updatedGroup.groupId, updatedGroup);
        Log.info('🔧 [LEGACY FIX] Group updated with corrected member IDs');
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
    Log.info('💾 [SAVE GROUP] グループ保存開始: ${group.groupName}');
    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      // 楽観的更新: 先にUIを更新
      state = AsyncData(group);
      Log.info('💾 [SAVE GROUP] 楽観的更新完了');

      // バックグラウンドでデータベースに保存
      await repository.updateGroup(group.groupId, group);
      Log.info('💾 [SAVE GROUP] データベース保存完了');
    } catch (e, stackTrace) {
      Log.error('❌ [SAVE GROUP] エラー発生: $e');
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
    Log.info('👥 [ADD MEMBER] メンバー追加開始: ${newMember.name}');
    final currentGroup = state.value;
    if (currentGroup == null) {
      Log.error('❌ [ADD MEMBER] currentGroupがnullです');
      return;
    }

    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      Log.info(
        '👥 [ADD MEMBER] 現在のメンバー数: ${currentGroup.members?.length ?? 0}',
      );

      // 楽観的更新: 先にUIを更新
      final optimisticGroup = currentGroup.addMember(newMember);
      state = AsyncData(optimisticGroup);
      Log.info(
        '👥 [ADD MEMBER] 楽観的更新完了。新メンバー数: ${optimisticGroup.members?.length ?? 0}',
      );

      // バックグラウンドでデータベースに保存
      await repository.addMember(currentGroup.groupId, newMember);
      Log.info('👥 [ADD MEMBER] データベース保存完了');

      // 念のため最新データを取得（同期エラー防止）
      final updatedGroup = await repository.getGroupById(currentGroup.groupId);
      state = AsyncData(updatedGroup);
      Log.info('👥 [ADD MEMBER] 最終更新完了');

      // allGroupsProviderも更新
      ref.invalidate(allGroupsProvider);

      // メンバープールも更新
      ref.read(memberPoolProvider.notifier).syncPool();
    } catch (e, stackTrace) {
      Log.error('❌ [ADD MEMBER] エラー発生: $e');
      Log.error('❌ [ADD MEMBER] スタックトレース: $stackTrace');
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }

  /// Delete a member from the current group
  Future<void> deleteMember(String memberId) async {
    Log.info('👥 [DELETE MEMBER] メンバー削除開始: $memberId');
    final currentGroup = state.value;
    if (currentGroup == null) {
      Log.error('❌ [DELETE MEMBER] currentGroupがnullです');
      return;
    }

    // 削除するメンバーを見つける
    final memberToDelete =
        currentGroup.members?.where((m) => m.memberId == memberId).firstOrNull;
    if (memberToDelete == null) {
      Log.error('❌ [DELETE MEMBER] 指定されたmemberIdのメンバーが見つかりません: $memberId');
      return;
    }

    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      Log.info(
        '👥 [DELETE MEMBER] 現在のメンバー数: ${currentGroup.members?.length ?? 0}',
      );

      // 楽観的更新: 先にUIを更新
      final optimisticGroup = currentGroup.removeMember(memberToDelete);
      state = AsyncData(optimisticGroup);
      Log.info(
        '👥 [DELETE MEMBER] 楽観的更新完了。新メンバー数: ${optimisticGroup.members?.length ?? 0}',
      );

      // バックグラウンドでデータベースから削除
      await repository.removeMember(currentGroup.groupId, memberToDelete);
      Log.info('👥 [DELETE MEMBER] データベース削除完了');

      // 念のため最新データを取得（同期エラー防止）
      final updatedGroup = await repository.getGroupById(currentGroup.groupId);
      state = AsyncData(updatedGroup);
      Log.info('👥 [DELETE MEMBER] 最終更新完了');

      // allGroupsProviderも更新
      ref.invalidate(allGroupsProvider);

      // メンバープールも更新
      ref.read(memberPoolProvider.notifier).syncPool();
    } catch (e, stackTrace) {
      Log.error('❌ [DELETE MEMBER] エラー発生: $e');
      Log.error('❌ [DELETE MEMBER] スタックトレース: $stackTrace');
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }

  /// Delete the current group
  Future<void> deleteCurrentGroup() async {
    final currentGroup = state.value;
    if (currentGroup == null) {
      Log.error('❌ [DELETE GROUP] currentGroupがnullです');
      return;
    }

    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      await repository.deleteGroup(currentGroup.groupId);

      // グループ削除後は全グループリストを更新
      await ref.read(allGroupsProvider.notifier).refresh();

      // 他のグループがあれば最初のグループを選択、なければデフォルト作成
      final groups = await repository.getAllGroups();
      if (groups.isNotEmpty) {
        ref
            .read(selectedGroupIdProvider.notifier)
            .selectGroup(groups.first.groupId);
      } else {
        // デフォルトグループを作成
        await ref.read(allGroupsProvider.notifier).createNewGroup('デフォルトグループ');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update owner message for the current group
  Future<void> updateOwnerMessage(String groupId, String message) async {
    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      final currentGroup = await repository.getGroupById(groupId);

      // 🔒 セキュリティチェック: オーナー権限確認
      User? currentUser;
      try {
        if (F.appFlavor != Flavor.dev) {
          currentUser = FirebaseAuth.instance.currentUser;
        }
      } catch (e) {
        Log.info('🔄 [MEMBER DELETE] Firebase利用不可（開発環境）: $e');
        currentUser = null;
      }
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

      // allGroupsProviderも更新
      ref.invalidate(allGroupsProvider);
    } catch (e) {
      // エラーが発生したら元の状態に戻す
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

// Group selection management
class SelectedGroupIdNotifier extends StateNotifier<String> {
  SelectedGroupIdNotifier() : super('default_group');

  void selectGroup(String groupId) {
    state = groupId;
  }
}

// All groups provider
class AllGroupsNotifier extends AsyncNotifier<List<PurchaseGroup>> {
  @override
  Future<List<PurchaseGroup>> build() async {
    Log.info('🔄 [ALL GROUPS] AllGroupsNotifier.build() 開始');

    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      Log.info('🔄 [ALL GROUPS] リポジトリ取得完了: ${repository.runtimeType}');

      // Auth状態を安全に読み取り（エラーでも続行）
      try {
        final authStateAsync = ref.read(authStateProvider);
        authStateAsync.whenOrNull(
          data: (user) {
            if (user != null) {
              Log.info('🔄 [ALL GROUPS] サインイン状態でグループ取得: ${user.email}');
              // サインイン済みの場合はFirestore同期をバックグラウンドで実行
              if (repository is HybridPurchaseGroupRepository) {
                // 非同期でFirestore同期を実行（buildをブロックしない）
                repository.syncFromFirestore().catchError((e) {
                  Log.warning('⚠️ [ALL GROUPS] バックグラウンド同期エラー: $e');
                });
              }
            } else {
              Log.info('🔄 [ALL GROUPS] 未サインイン状態でグループ取得');
            }
          },
          loading: () {
            Log.info('🔄 [ALL GROUPS] Auth状態確認中...');
          },
          error: (error, stack) {
            Log.warning('⚠️ [ALL GROUPS] Auth状態エラー: $error');
          },
        );
      } catch (authError) {
        Log.warning('⚠️ [ALL GROUPS] Auth状態読み取りエラー（続行します）: $authError');
      }

      Log.info('🔄 [ALL GROUPS] getAllGroups() 呼び出し開始');
      final groups = await repository.getAllGroups();
      Log.info('🔄 [ALL GROUPS] getAllGroups() 完了: ${groups.length}グループ');

      if (groups.isNotEmpty) {
        for (final group in groups) {
          Log.info('🔄 [ALL GROUPS] - ${group.groupName} (${group.groupId})');
        }
      }

      // デフォルトグループが存在しない場合、即座に作成（空の場合のみ）
      if (groups.isEmpty) {
        Log.info('🔄 [ALL GROUPS] グループが空のため、デフォルトグループを作成します');
        try {
          await _ensureDefaultGroupExists();
          // 作成後に再度グループを取得
          final updatedGroups = await repository.getAllGroups();
          Log.info('🔄 [ALL GROUPS] デフォルトグループ作成後: ${updatedGroups.length}グループ');
          return updatedGroups;
        } catch (defaultGroupError) {
          Log.error('❌ [ALL GROUPS] デフォルトグループ作成エラー: $defaultGroupError');
          // デフォルトグループ作成に失敗した場合は空リストを返す
          Log.warning('⚠️ [ALL GROUPS] グループが存在せず、デフォルト作成も失敗しました');
          return [];
        }
      }

      return groups;
    } catch (e, stackTrace) {
      Log.error('❌ [ALL GROUPS] エラー発生: $e');
      Log.error('❌ [ALL GROUPS] スタックトレース: $stackTrace');
      // エラーが発生した場合でも空リストを返す（アプリクラッシュを防ぐ）
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// デフォルトグループの存在を確保
  Future<void> _ensureDefaultGroupExists() async {
    try {
      Log.info('🔄 [DEFAULT GROUP] デフォルトグループ作成開始');
      final repository = ref.read(purchaseGroupRepositoryProvider);

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 開発環境では常にローカルユーザーとして処理
      User? currentUser;
      try {
        if (F.appFlavor != Flavor.dev) {
          currentUser = FirebaseAuth.instance.currentUser;
        }
      } catch (e) {
        Log.info('🔄 [DEFAULT GROUP] Firebase利用不可（開発環境）: $e');
        currentUser = null;
      }

      final currentUserId = currentUser?.uid ?? 'local_user_$timestamp';

      String userName = 'ゲスト';
      String userEmail = 'guest@local.app';

      if (currentUser != null) {
        // サインイン済みユーザーの場合
        userName = currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'ユーザー';
        userEmail = currentUser.email ?? 'unknown@local.app';
        Log.info('🔄 [DEFAULT GROUP] サインイン済みユーザー: $userName ($userEmail)');
      } else {
        // 未サインインユーザーの場合（開発環境含む）
        userName = 'ゲスト$timestamp';
        userEmail = 'guest_${timestamp}@local.app';
        Log.info('🔄 [DEFAULT GROUP] 未サインインユーザー: $userName ($userEmail)');
      }

      // デフォルトグループのオーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        memberId: currentUserId,
        name: userName,
        contact: userEmail,
        role: PurchaseGroupRole.owner,
        isSignedIn: currentUser != null,
      );

      // デフォルトグループを作成
      await repository.createGroup('default_group', 'My Lists', ownerMember);

      Log.info('✅ [DEFAULT GROUP] デフォルトグループ作成完了: $userName');
    } catch (e, stackTrace) {
      Log.error('❌ [DEFAULT GROUP] デフォルトグループ作成エラー: $e');
      Log.error('❌ [DEFAULT GROUP] スタックトレース: $stackTrace');
      throw Exception('Failed to create default group: $e');
    }
  }

  /// 新しいグループを作成
  Future<void> createNewGroup(String groupName) async {
    Log.info('🆕 [CREATE GROUP] createNewGroup: $groupName');
    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      // 現在のFirebaseユーザー情報を安全に取得
      User? currentUser;
      try {
        if (F.appFlavor != Flavor.dev) {
          currentUser = FirebaseAuth.instance.currentUser;
        }
      } catch (e) {
        Log.info('🔄 [CREATE GROUP] Firebase利用不可（開発環境）: $e');
        currentUser = null;
      }
      final currentUserId = currentUser?.uid ?? '';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // ユーザー情報を安全に取得
      String userName = 'ゲスト';
      String userEmail = 'guest@local.app';

      if (currentUser != null) {
        // サインイン済みユーザーの場合
        userName = currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'ユーザー';
        userEmail = currentUser.email ?? 'unknown@local.app';
        Log.info('🆕 [CREATE GROUP] サインイン済みユーザー: $userName ($userEmail)');
      } else {
        // 未サインインユーザーの場合
        // UserSettingsからの取得を試行（エラーが発生しても続行）
        try {
          final userSettingsAsync = ref.read(userSettingsProvider);
          final userSettings = userSettingsAsync.value;
          if (userSettings != null) {
            userName = userSettings.userName.isNotEmpty
                ? userSettings.userName
                : 'ゲスト$timestamp';
            userEmail = userSettings.userEmail.isNotEmpty
                ? userSettings.userEmail
                : 'guest_${timestamp}@local.app';
          } else {
            userName = 'ゲスト$timestamp';
            userEmail = 'guest_${timestamp}@local.app';
          }
        } catch (e) {
          Log.warning('⚠️ [CREATE GROUP] UserSettings取得エラー、デフォルト値を使用: $e');
          userName = 'ゲスト$timestamp';
          userEmail = 'guest_${timestamp}@local.app';
        }
        Log.info('🆕 [CREATE GROUP] 未サインインユーザー: $userName ($userEmail)');
      }

      // オーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        memberId:
            currentUserId.isNotEmpty ? currentUserId : 'local_user_$timestamp',
        name: userName,
        contact: userEmail,
        role: PurchaseGroupRole.owner,
        isSignedIn: currentUser != null,
      );

      // グループを作成
      final newGroup = await repository.createGroup(
        timestamp.toString(), // 一意のグループID
        groupName,
        ownerMember,
      );

      Log.info('✅ [CREATE GROUP] グループ作成完了: ${newGroup.groupName}');

      // 作成したグループを選択状態にする
      ref.read(selectedGroupIdProvider.notifier).selectGroup(newGroup.groupId);

      // 楽観的更新：直接stateを更新（refreshは使わない）
      try {
        final currentGroups = await repository.getAllGroups();
        state = AsyncData(currentGroups);
        Log.info('✅ [CREATE GROUP] 楽観的更新完了: ${currentGroups.length}グループ');
      } catch (e) {
        Log.warning('⚠️ [CREATE GROUP] 楽観的更新エラー: $e');
      }

      // メンバープールも更新（新しいオーナーが追加されるため）
      try {
        await ref.read(memberPoolProvider.notifier).syncPool();
        Log.info('✅ [CREATE GROUP] メンバープール更新完了');
      } catch (e) {
        Log.warning('⚠️ [CREATE GROUP] メンバープール更新エラー: $e');
      }
    } catch (e, stackTrace) {
      Log.error('❌ [CREATE GROUP] エラー発生: $e');
      Log.error('❌ [CREATE GROUP] スタックトレース: $stackTrace');
      throw Exception('Failed to create group: $e');
    }
  }
}

// Selected Group Provider - 選択されたグループの詳細操作用
final selectedGroupNotifierProvider =
    AsyncNotifierProvider<SelectedGroupNotifier, PurchaseGroup?>(
  () => SelectedGroupNotifier(),
);

final selectedGroupIdProvider =
    StateNotifierProvider<SelectedGroupIdNotifier, String>(
  (ref) => SelectedGroupIdNotifier(),
);

// Member Pool Management - メンバープール管理用
class MemberPoolNotifier extends AsyncNotifier<PurchaseGroup> {
  @override
  Future<PurchaseGroup> build() async {
    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      Log.info('🔄 [MEMBER POOL] MemberPoolNotifier.build() 開始');
      final memberPool = await repository.getOrCreateMemberPool();
      Log.info(
        '🔄 [MEMBER POOL] メンバープール取得完了: ${memberPool.members?.length ?? 0}メンバー',
      );
      return memberPool;
    } catch (e, stackTrace) {
      Log.error('❌ [MEMBER POOL] ビルドエラー: $e');
      Log.error('❌ [MEMBER POOL] スタックトレース: $stackTrace');
      throw Exception('Failed to load member pool: $e');
    }
  }

  /// メンバープールを最新の状態に同期
  Future<void> syncPool() async {
    Log.info('🔄 [MEMBER POOL] syncPool() 開始');
    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      // プールを同期
      await repository.syncMemberPool();

      // 最新のプール状態を取得
      final updatedPool = await repository.getOrCreateMemberPool();
      state = AsyncData(updatedPool);

      Log.info(
        '✅ [MEMBER POOL] プール同期完了: ${updatedPool.members?.length ?? 0}メンバー',
      );
    } catch (e, stackTrace) {
      Log.error('❌ [MEMBER POOL] 同期エラー: $e');
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }

  /// メンバープール内でメンバーを検索
  Future<List<PurchaseGroupMember>> searchMembers(String query) async {
    Log.info('🔍 [MEMBER POOL] searchMembers() 開始: "$query"');
    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      final members = await repository.searchMembersInPool(query);
      Log.info('🔍 [MEMBER POOL] 検索完了: ${members.length}件');
      return members;
    } catch (e) {
      Log.error('❌ [MEMBER POOL] 検索エラー: $e');
      rethrow;
    }
  }

  /// メールアドレスでメンバーを検索
  Future<PurchaseGroupMember?> findMemberByEmail(String email) async {
    Log.info('📧 [MEMBER POOL] findMemberByEmail() 開始: $email');
    final repository = ref.read(purchaseGroupRepositoryProvider);

    try {
      final member = await repository.findMemberByEmail(email);
      Log.info(
        '📧 [MEMBER POOL] メール検索完了: ${member != null ? 'found' : 'not found'}',
      );
      return member;
    } catch (e) {
      Log.error('❌ [MEMBER POOL] メール検索エラー: $e');
      rethrow;
    }
  }

  /// プールを手動で更新（グループメンバー変更後など）
  Future<void> refreshPool() async {
    Log.info('🔄 [MEMBER POOL] refreshPool() 開始');

    try {
      await syncPool();
      Log.info('✅ [MEMBER POOL] プール更新完了');
    } catch (e) {
      Log.error('❌ [MEMBER POOL] プール更新エラー: $e');
      rethrow;
    }
  }
}

final memberPoolProvider =
    AsyncNotifierProvider<MemberPoolNotifier, PurchaseGroup>(
  () => MemberPoolNotifier(),
);

final allGroupsProvider =
    AsyncNotifierProvider<AllGroupsNotifier, List<PurchaseGroup>>(
  () => AllGroupsNotifier(),
);

// 選択されたグループを取得するプロバイダー（後方互換性のために Provider として提供）
final selectedGroupProvider = Provider<AsyncValue<PurchaseGroup?>>((ref) {
  return ref.watch(selectedGroupNotifierProvider);
});

// =================================================================
// ハイブリッド同期管理
// =================================================================

/// ハイブリッドリポジトリへのアクセス（本番環境のみ）
final hybridRepositoryProvider = Provider<HybridPurchaseGroupRepository?>((
  ref,
) {
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
  localOnly, // ローカルのみ（dev環境）
  offline, // オフライン
  syncing, // 同期中
  synced, // 同期済み
}
