import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../models/shared_group.dart' hide SyncStatus;
import '../models/shared_group.dart' as models show SyncStatus;
import '../datastore/shared_group_repository.dart';
import '../datastore/hive_shared_group_repository.dart';
import '../datastore/hybrid_purchase_group_repository.dart';
import '../flavors.dart';
import '../helpers/security_validator.dart';
import '../services/access_control_service.dart';
import '../services/user_preferences_service.dart';
import '../services/user_initialization_service.dart';
import '../services/firestore_user_name_service.dart';
import 'auth_provider.dart';
import 'user_specific_hive_provider.dart';
import 'current_list_provider.dart';

// Logger instance

// Repository provider - ハイブリッドリポジトリを使用
final SharedGroupRepositoryProvider = Provider<SharedGroupRepository>((
  ref,
) {
  // � 一時的にdevではHiveのみに戻す（クラッシュ原因調査のため）
  if (F.appFlavor == Flavor.prod) {
    return HybridSharedGroupRepository(ref);
  } else {
    return HiveSharedGroupRepository(ref);
  }
});

// Selected Group Management - 選択されたグループの詳細操作用
class SelectedGroupNotifier extends AsyncNotifier<SharedGroup?> {
  @override
  Future<SharedGroup?> build() async {
    // ✅ 最初に全ての依存性を確定する
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    final repository = ref.read(SharedGroupRepositoryProvider);

    if (selectedGroupId == null || selectedGroupId.isEmpty) return null;

    try {
      AppLogger.info(
        '🔄 [SELECTED GROUP] SelectedGroupNotifier.build() 開始: $selectedGroupId',
      );
      final group = await repository.getGroupById(selectedGroupId);
      final fixedGroup = await _fixLegacyMemberRoles(group, repository);
      AppLogger.info(
          '🔄 [SELECTED GROUP] グループロード完了: ${AppLogger.maskGroup(fixedGroup.groupName, fixedGroup.groupId)}');
      return fixedGroup;
    } catch (e, stackTrace) {
      AppLogger.error('❌ [SELECTED GROUP] ビルドエラー: $e');
      AppLogger.error('❌ [SELECTED GROUP] スタックトレース: $stackTrace');
      return null;
    }
  }

  /// Fix legacy member roles and ensure proper group structure
  Future<SharedGroup> _fixLegacyMemberRoles(
      SharedGroup group, SharedGroupRepository repository) async {
    final originalMembers = group.members ?? [];
    bool needsUpdate = false;

    // Get current Firebase user ID for owner validation (本番環境のみ)
    User? currentUser;
    try {
      if (F.appFlavor == Flavor.prod) {
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

    Log.info(
        '🔧 [LEGACY FIX] currentUserId: ${AppLogger.maskUserId(currentUserId)}');
    Log.info('🔧 [LEGACY FIX] hasCurrentUser in group: $hasCurrentUser');

    // 現在のユーザーがメンバーリストにいない場合は、オーナーのmemberIdを更新
    if (!hasCurrentUser && currentUserId.isNotEmpty) {
      // オーナーメンバーを見つけて、そのmemberIdを現在のユーザーIDに変更
      final List<SharedGroupMember> updatedMembers = [];
      bool ownerUpdated = false;

      for (final member in originalMembers) {
        if (member.role == SharedGroupRole.owner && !ownerUpdated) {
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
    SharedGroupMember? owner;
    final List<SharedGroupMember> nonOwners = [];

    // First pass: separate owners and non-owners
    for (final member in originalMembers) {
      if (member.role == SharedGroupRole.owner) {
        if (owner == null) {
          owner = member; // Keep the first owner
        } else {
          // Convert additional owners to members
          nonOwners.add(member.copyWith(role: SharedGroupRole.member));
          needsUpdate = true;
        }
      } else {
        // Convert any legacy roles (parent, child) to member
        if (member.role != SharedGroupRole.member) {
          nonOwners.add(member.copyWith(role: SharedGroupRole.member));
          needsUpdate = true;
        } else {
          nonOwners.add(member);
        }
      }
    }

    // If no owner found, make the first member an owner
    if (owner == null && nonOwners.isNotEmpty) {
      final firstMember = nonOwners.removeAt(0);
      owner = firstMember.copyWith(role: SharedGroupRole.owner);
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

  Future<void> saveGroup(SharedGroup group) async {
    Log.info('💾 [SAVE GROUP] グループ保存開始: ${group.groupName}');
    final repository = ref.read(SharedGroupRepositoryProvider);

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
    final repository = ref.read(SharedGroupRepositoryProvider);

    try {
      final group = await repository.getGroupById(groupId);
      final fixedGroup = await _fixLegacyMemberRoles(group, repository);

      // アクセス日時を更新
      final accessedGroup = fixedGroup.markAsAccessed();
      await repository.updateGroup(groupId, accessedGroup);

      state = AsyncData(accessedGroup);

      // Update selected group ID
      ref.read(selectedGroupIdProvider.notifier).selectGroup(groupId);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateGroup(SharedGroup group) async {
    await saveGroup(group);
  }

  /// Add a new member to the current group
  Future<void> addMember(SharedGroupMember newMember) async {
    Log.info('👥 [ADD MEMBER] メンバー追加開始: ${newMember.name}');
    final currentGroup = state.value;
    if (currentGroup == null) {
      Log.error('❌ [ADD MEMBER] currentGroupがnullです');
      return;
    }

    final repository = ref.read(SharedGroupRepositoryProvider);

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

      // メンバープールも更新（allGroupsProviderはリアクティブ更新されるため手動invalidateは不要）
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

    final repository = ref.read(SharedGroupRepositoryProvider);

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

      // メンバープールも更新（allGroupsProviderはリアクティブ更新されるため手動invalidateは不要）
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

    // デフォルトグループは削除不可
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentGroup.groupId == 'default_group' ||
        (currentUser != null && currentGroup.groupId == currentUser.uid)) {
      Log.error('❌ [DELETE GROUP] デフォルトグループは削除できません');
      throw Exception('デフォルトグループ（MyLists）は削除できません');
    }

    final repository = ref.read(SharedGroupRepositoryProvider);

    try {
      // ステップ1: Firestoreで削除フラグを立てる（本番環境のみ）
      final currentUser = FirebaseAuth.instance.currentUser;
      if (F.appFlavor == Flavor.prod && currentUser != null) {
        try {
          final initService = ref.read(userInitializationServiceProvider);
          await initService.markGroupAsDeletedInFirestore(
              currentUser, currentGroup.groupId);
          Log.info(
              '✅ [DELETE GROUP] Firestoreで削除フラグ設定: ${currentGroup.groupId}');
        } catch (e) {
          Log.warning('⚠️ [DELETE GROUP] Firestore削除フラグエラー（続行）: $e');
        }
      }

      // ステップ2: Hiveから削除
      await repository.deleteGroup(currentGroup.groupId);
      Log.info('✅ [DELETE GROUP] Hiveから削除完了: ${currentGroup.groupId}');

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
    final repository = ref.read(SharedGroupRepositoryProvider);

    try {
      final currentGroup = await repository.getGroupById(groupId);

      // 🔒 セキュリティチェック: オーナー権限確認
      User? currentUser;
      try {
        if (F.appFlavor == Flavor.prod) {
          currentUser = FirebaseAuth.instance.currentUser;
        }
      } catch (e) {
        Log.info('🔄 [MEMBER DELETE] Firebase利用不可（開発環境）: $e');
        currentUser = null;
      }
      if (currentUser != null && F.appFlavor == Flavor.prod) {
        SecurityValidator.validateFirestoreRuleCompliance(
          operation: 'write',
          resourceType: 'SharedGroup',
          group: currentGroup,
          currentUid: currentUser.uid,
        );
      }

      // 楽観的更新: 先にUIを更新してからバックグラウンドで保存
      final updatedGroup = currentGroup.copyWith(ownerMessage: message);
      state = AsyncData(updatedGroup);

      // バックグラウンドで保存（allGroupsProviderはリアクティブ更新されるため手動invalidateは不要）
      await repository.updateGroup(groupId, updatedGroup);
    } catch (e) {
      // エラーが発生したら元の状態に戻す
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

// All groups provider
class AllGroupsNotifier extends AsyncNotifier<List<SharedGroup>> {
  @override
  Future<List<SharedGroup>> build() async {
    Log.info('🔄 [ALL GROUPS] AllGroupsNotifier.build() 開始');

    // ✅ 最初に全ての依存性を確定する
    // FutureProvider/StreamProviderは ref.watch() が必須（非同期データ監視）
    // Provider<T>は ref.read() で十分（同期的なサービス）
    final hiveReady = ref.watch(hiveInitializationStatusProvider);
    // 初期化状態も監視（初期化完了時に自動的に再構築される）
    ref.watch(userInitializationStatusProvider);
    final repository = ref.read(SharedGroupRepositoryProvider);
    final accessControl =
        ref.read(accessControlServiceProvider); // ← Provider<T>なので read()

    try {
      // Hiveが初期化されるのを待つ（特にデスクトップでのユーザー固有初期化）
      if (!hiveReady) {
        Log.info('🔄 [ALL GROUPS] Hive初期化待機中...');
        // hiveUserInitializationProvider は FutureProvider なので .future で待機
        await ref.read(hiveUserInitializationProvider.future);
        Log.info('🔄 [ALL GROUPS] Hive初期化完了、続行します');
      }

      Log.info('🔄 [ALL GROUPS] リポジトリ取得完了: ${repository.runtimeType}');

      // ✅ Hive優先アーキテクチャ
      // build()では常にHiveから即座にデータを返す（Firestore同期はbuild()内で実行しない）
      // 理由:
      // 1. build()が頻繁に呼ばれるため、毎回Firestore同期すると無限ループのリスク
      // 2. グループ管理はリアルタイム性が低いため、定期同期で十分
      // 3. UI応答性を優先（Hiveは同期的に即座にデータを返す）
      //
      // Firestore同期のタイミング:
      // - アプリ起動時（main.dartなど）
      // - ユーザーが明示的に同期ボタンを押した時（GroupListWidgetの同期ボタン）
      // - グループ作成/更新/削除時（各mutation内で個別に同期）
      Log.info('🔄 [ALL GROUPS] Hive優先モード: ローカルデータを即座に返す');

      Log.info('🔄 [ALL GROUPS] Hiveから直接取得開始');

      // Hiveから直接データ取得（初期化待機なし）
      final hiveRepo = ref.read(hiveSharedGroupRepositoryProvider);
      final allGroupsRaw = await hiveRepo.getAllGroups();

      Log.info(
          '🔍 [ALL GROUPS] Hive Raw取得: ${allGroupsRaw.length}グループ（削除済み含む）');

      // 削除済みグループをフィルタリング
      var allGroups = allGroupsRaw.where((g) => !g.isDeleted).toList();
      final deletedCount = allGroupsRaw.length - allGroups.length;
      if (deletedCount > 0) {
        Log.info('🗑️ [ALL GROUPS] 削除済みグループを除外: $deletedCount グループ');
      }

      // 🔥 CRITICAL: allowedUidに現在ユーザーが含まれないグループを除外
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser != null) {
        final beforeFilterCount = allGroups.length;
        allGroups = allGroups
            .where((g) => g.allowedUid.contains(currentUser.uid))
            .toList();
        final invalidCount = beforeFilterCount - allGroups.length;
        if (invalidCount > 0) {
          Log.warning(
              '⚠️ [ALL GROUPS] allowedUid不一致グループを除外: $invalidCount グループ');
        }
      }

      Log.info('🔄 [ALL GROUPS] Hive直接取得完了: ${allGroups.length}グループ');

      // 🔒 アクセス制御によるフィルタリング
      final visibilityMode = await accessControl.getGroupVisibilityMode();

      List<SharedGroup> filteredGroups;
      switch (visibilityMode) {
        case GroupVisibilityMode.all:
          filteredGroups = allGroups;
          Log.info('🔄 [ALL GROUPS] 全グループ表示モード');
          break;
        case GroupVisibilityMode.defaultOnly:
          filteredGroups =
              allGroups.where((g) => g.groupId == 'default_group').toList();
          Log.info('🔒 [ALL GROUPS] MyListsのみ表示モード（シークレット/未認証）');
          break;
        case GroupVisibilityMode.readOnly:
          filteredGroups = allGroups;
          Log.info('🔄 [ALL GROUPS] 読み取り専用モード');
          break;
      }

      if (filteredGroups.isNotEmpty) {
        for (final group in filteredGroups) {
          Log.info('🔄 [ALL GROUPS] - ${group.groupName} (${group.groupId})');
        }
      }

      // デフォルトグループの確認（情報ログのみ）
      // ⚠️ 注意: デフォルトグループIDはuser.uidなので固定IDではチェックできない
      if (allGroups.isEmpty) {
        Log.info(
            '🔄 [ALL GROUPS] グループが0個です。UserInitializationServiceでデフォルトグループが作成されます');
      } else {
        Log.info('📊 [ALL GROUPS] グループ数: ${allGroups.length}個');
      }

      return filteredGroups;
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

  /// 新しいグループを作成（Firebase認証必須）
  Future<void> createNewGroup(String groupName) async {
    Log.info('🆕 [CREATE GROUP] createNewGroup: $groupName');

    // 🔒 Firebase認証チェック（本番環境のみ）
    User? currentUser;
    try {
      if (F.appFlavor == Flavor.prod) {
        currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('新しいグループを作成するにはFirebase認証が必要です。サインインしてください。');
        }
        Log.info('🆕 [CREATE GROUP] 認証済みユーザー: ${currentUser.email}');
      } else {
        Log.info('🔧 [CREATE GROUP] DEV環境 - 認証チェックをスキップ');
      }
    } catch (e) {
      if (F.appFlavor == Flavor.prod) {
        Log.error('❌ [CREATE GROUP] 認証エラー: $e');
        rethrow;
      }
      Log.info('🔄 [CREATE GROUP] Firebase利用不可（開発環境）: $e');
      currentUser = null;
    }

    final repository = ref.read(SharedGroupRepositoryProvider);
    Log.info('🔍 [CREATE GROUP] Repository type: ${repository.runtimeType}');
    Log.info('🔍 [CREATE GROUP] Flavor: ${F.appFlavor}');
    final currentUserId = currentUser?.uid ?? '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      // ユーザー情報を安全に取得（優先順位: SharedPreferences > Firestore profile > Firebase Auth）
      String userName = 'ゲスト';
      String userEmail = 'guest@local.app';

      if (currentUser != null) {
        // サインイン済みユーザーの場合
        userEmail = currentUser.email ?? 'unknown@local.app';

        // 1. SharedPreferencesから取得を試みる
        try {
          final storedName = await UserPreferencesService.getUserName();
          if (storedName != null && storedName.isNotEmpty) {
            userName = storedName;
            Log.info(
                '✅ [CREATE GROUP] SharedPreferencesからユーザー名取得: ${AppLogger.maskName(userName)}');
          }
        } catch (e) {
          Log.warning('⚠️ [CREATE GROUP] SharedPreferences取得エラー: $e');
        }

        // 2. Firestore /users/{uid} から取得を試みる
        if (userName == 'ゲスト') {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data();
              final firestoreName = userData?['displayName'];
              if (firestoreName != null && firestoreName.isNotEmpty) {
                userName = firestoreName;
                Log.info('✅ [CREATE GROUP] Firestoreからユーザー名取得: $userName');
              }
            }
          } catch (e) {
            Log.warning('⚠️ [CREATE GROUP] Firestore取得エラー: $e');
          }
        }

        // 3. Firebase Auth displayNameから取得を試みる
        if (userName == 'ゲスト') {
          userName = currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'ユーザー';
          Log.info(
              '✅ [CREATE GROUP] Firebase Auth displayNameから取得: ${AppLogger.maskName(userName)}');
        }

        Log.info(
            '🆕 [CREATE GROUP] サインイン済みユーザー: ${AppLogger.maskName(userName)} (${AppLogger.maskName(userEmail)})');
      } else {
        // 未サインインユーザーの場合
        // SharedPreferencesから直接取得（UserPreferencesService使用）
        try {
          final storedName = await UserPreferencesService.getUserName();
          final storedEmail = await UserPreferencesService.getUserEmail();
          userName =
              (storedName?.isNotEmpty ?? false) ? storedName! : 'ゲスト$timestamp';
          userEmail = (storedEmail?.isNotEmpty ?? false)
              ? storedEmail!
              : 'guest_$timestamp@local.app';
        } catch (e) {
          Log.warning('⚠️ [CREATE GROUP] ユーザー設定取得エラー、デフォルト値を使用: $e');
          userName = 'ゲスト$timestamp';
          userEmail = 'guest_$timestamp@local.app';
        }
        Log.info(
            '🆕 [CREATE GROUP] 未サインインユーザー: ${AppLogger.maskName(userName)} (${AppLogger.maskName(userEmail)})');
      }

      // オーナーメンバーを作成
      final ownerMember = SharedGroupMember.create(
        memberId:
            currentUserId.isNotEmpty ? currentUserId : 'local_user_$timestamp',
        name: userName,
        contact: userEmail,
        role: SharedGroupRole.owner,
        isSignedIn: currentUser != null,
      );

      // グループを作成
      final newGroup = await repository.createGroup(
        timestamp.toString(), // 一意のグループID
        groupName,
        ownerMember,
      );

      Log.info('✅ [CREATE GROUP] グループ作成完了: ${newGroup.groupName}');

      // Hive→Firestoreへの同期（本番環境のみ）
      // 🔥 CRITICAL FIX: Firestore同期を再有効化（招待機能に必須）
      if (F.appFlavor == Flavor.prod && currentUser != null) {
        try {
          Log.info('🔄 [CREATE GROUP] Firestoreへグループを同期中...');
          final repository = ref.read(SharedGroupRepositoryProvider);
          await repository.updateGroup(newGroup.groupId, newGroup);
          Log.info('✅ [CREATE GROUP] Firestore同期完了');

          // 🆕 Firestoreプラグインの内部処理が完全に完了するまで追加待機
          // Windowsプラグインのスレッド問題対策
          await Future.delayed(const Duration(milliseconds: 300));
          Log.info('✅ [CREATE GROUP] Firestore内部処理完了待機完了');
        } catch (e) {
          Log.error('❌ [CREATE GROUP] Firestore同期エラー: $e');
          // エラーでも続行（ローカルには保存済み）
        }
      }

      // 作成したグループを選択状態にする
      try {
        // selectedGroupIdProviderを更新
        ref
            .read(selectedGroupIdProvider.notifier)
            .selectGroup(newGroup.groupId);
        Log.info(
            '✅ [CREATE GROUP] selectedGroupIdProvider更新完了: ${newGroup.groupId}');

        // ⚠️ 重要: 新規グループの最終使用リストをクリア
        await ref
            .read(currentListProvider.notifier)
            .clearListForGroup(newGroup.groupId);
        Log.info('✅ [CREATE GROUP] 新規グループの最終使用リストクリア完了: ${newGroup.groupId}');
      } catch (e) {
        Log.warning('⚠️ [CREATE GROUP] グループ選択エラー（続行）: $e');
      }

      // ✅ 楽観的更新: 新しいグループを既存リストに追加
      // repository.getAllGroups()を再度呼ぶのではなく、
      // 既存のstateに新しいグループを追加することで、build()の再トリガーを回避
      try {
        final currentState = state;
        if (currentState is AsyncData<List<SharedGroup>>) {
          final currentGroups = currentState.value;
          final updatedGroups = [...currentGroups, newGroup];
          state = AsyncData(updatedGroups);
          Log.info('✅ [CREATE GROUP] 楽観的更新完了: ${updatedGroups.length}グループ');
        } else {
          Log.warning(
              '⚠️ [CREATE GROUP] stateがAsyncDataではない: ${currentState.runtimeType}');
          ref.invalidateSelf();
        }
      } catch (e) {
        Log.warning('⚠️ [CREATE GROUP] 楽観的更新エラー: $e');
        Log.warning('⚠️ [CREATE GROUP] stateを再構築します');
        // 失敗した場合はbuild()を再実行
        ref.invalidateSelf();
      }

      // ✅ メンバープール更新は不要
      // グループ作成時はオーナー（自分）のみ追加され、既にメンバープールに存在
      // 新規メンバー追加は招待機能でのみ実施されるため
    } catch (e, stackTrace) {
      Log.error('❌ [CREATE GROUP] 予期しないエラー発生: $e');
      Log.error('❌ [CREATE GROUP] スタックトレース: $stackTrace');
      // グループ作成後のエラーは致命的ではないため、ログのみ出力して続行
      // rethrowしない（UI層でのクラッシュを防ぐ）
    }
  }

  /// デフォルトグループを作成（groupId = user.uid）
  /// user_initialization_serviceから呼び出される
  Future<void> createDefaultGroup(User? user) async {
    // ⚠️ CRITICAL: ref.read()を全てメソッド開始時に取得（async処理前）
    final hiveReady = ref.read(hiveInitializationStatusProvider);
    final hiveInitFuture = ref.read(hiveUserInitializationProvider.future);
    final hiveRepository = ref.read(hiveSharedGroupRepositoryProvider);

    try {
      Log.info('🆕 [CREATE DEFAULT] デフォルトグループ作成開始（AllGroupsNotifier）');

      // デフォルトグループIDはユーザーのuidをそのまま使用
      final defaultGroupId = user?.uid ?? 'local_default';
      Log.info(
          '🆔 [CREATE DEFAULT] グループID: ${AppLogger.maskGroupId(defaultGroupId, currentUserId: user?.uid)}');

      // プリファレンスからユーザー名を取得
      String displayName = 'ユーザー';

      // 1. まずFirestore users/{uid}/profile から取得を試みる
      try {
        final firestoreName = await FirestoreUserNameService.getUserName();
        if (firestoreName != null && firestoreName.isNotEmpty) {
          displayName = firestoreName;
          // Preferencesにも反映
          await UserPreferencesService.saveUserName(firestoreName);
          Log.info('✅ [CREATE DEFAULT] Firestoreからユーザー名取得: $displayName');
        }
      } catch (e) {
        Log.warning('⚠️ [CREATE DEFAULT] Firestoreユーザー名取得エラー: $e');
      }

      // 2. Firestoreで取得できなかった場合、Preferencesから取得
      if (displayName == 'ユーザー') {
        final prefsName = await UserPreferencesService.getUserName();
        if (prefsName != null && prefsName.isNotEmpty) {
          displayName = prefsName;
          Log.info('✅ [CREATE DEFAULT] Preferencesからユーザー名取得: $displayName');
        }
      }

      // 3. Preferencesでも取得できなかった場合、Firebase Authから取得
      if (displayName == 'ユーザー') {
        if (user?.displayName?.isNotEmpty == true) {
          displayName = user!.displayName!;
          Log.info('✅ [CREATE DEFAULT] Firebase Authからユーザー名取得: $displayName');
        } else if (user?.email != null) {
          displayName = user!.email!.split('@').first;
          Log.info('✅ [CREATE DEFAULT] メールアドレスからユーザー名生成: $displayName');
        }
      }

      Log.info(
          '👤 [CREATE DEFAULT] 最終決定ユーザー名: ${AppLogger.maskName(displayName)}');

      // メールアドレスをSharedPreferencesに保存
      if (user?.email != null && user!.email!.isNotEmpty) {
        await UserPreferencesService.saveUserEmail(user.email!);
        Log.info('📧 [CREATE DEFAULT] メール保存: ${user.email}');
      }

      // デフォルトグループ作成（createNewGroupのロジックを再利用）
      final defaultGroupName = '$displayNameグループ';
      Log.info('📝 [CREATE DEFAULT] グループ作成: $defaultGroupName');

      // Hive初期化完了を待機
      if (!hiveReady) {
        Log.info('⏳ [CREATE DEFAULT] Hive初期化完了待機中...');
        await hiveInitFuture;
        Log.info('✅ [CREATE DEFAULT] Hive初期化完了');
      }

      // 🔥 CRITICAL: サインイン状態ではFirestoreを優先チェック
      if (user != null && F.appFlavor == Flavor.prod) {
        Log.info('🔥 [CREATE DEFAULT] サインイン状態 - Firestoreから既存グループ確認');

        try {
          // Firestoreから全グループ取得
          final firestore = FirebaseFirestore.instance;
          final groupsSnapshot = await firestore
              .collection('SharedGroups')
              .where('allowedUid', arrayContains: user.uid)
              .get();

          Log.info(
              '📊 [CREATE DEFAULT] Firestoreに${groupsSnapshot.docs.length}グループ存在');

          // デフォルトグループ（groupId = user.uid）が存在するか確認
          final defaultGroupDoc = groupsSnapshot.docs.firstWhere(
            (doc) => doc.id == defaultGroupId,
            orElse: () => throw Exception('デフォルトグループなし'),
          );

          // Firestoreにデフォルトグループが存在する！
          Log.info('✅ [CREATE DEFAULT] Firestoreにデフォルトグループ存在 - Hiveに同期');

          // FirestoreからSharedGroupモデルに変換
          final data = defaultGroupDoc.data();
          final firestoreGroup = SharedGroup(
            groupId: data['groupId'] as String,
            groupName: data['groupName'] as String,
            ownerUid: data['ownerUid'] as String,
            allowedUid: (data['allowedUid'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            members: (data['members'] as List<dynamic>?)?.map((m) {
                  final memberData = m as Map<String, dynamic>;
                  return SharedGroupMember(
                    memberId: memberData['memberId'] as String,
                    name: memberData['name'] as String,
                    contact: memberData['contact'] as String? ?? '',
                    role: _parseRole(memberData['role'] as String?),
                    isSignedIn: memberData['isSignedIn'] as bool? ?? false,
                    isInvited: memberData['isInvited'] as bool? ?? false,
                    isInvitationAccepted:
                        memberData['isInvitationAccepted'] as bool? ?? false,
                  );
                }).toList() ??
                [],
            syncStatus: models.SyncStatus.synced,
            isDeleted: false,
          );

          // Hiveに保存
          await hiveRepository.saveGroup(firestoreGroup);
          Log.info('✅ [CREATE DEFAULT] FirestoreグループをHiveに保存完了');

          // 🔥 CRITICAL: Hiveクリーンアップ - allowedUidに含まれないグループを削除
          await _cleanupInvalidHiveGroupsInternal(user.uid, hiveRepository);

          Log.info('✅ [CREATE DEFAULT] 初期化完了 - 作成不要');
          return;
        } catch (e) {
          Log.info('💡 [CREATE DEFAULT] Firestoreにデフォルトグループなし: $e');
          Log.info('📝 [CREATE DEFAULT] 新規作成を続行');

          // 🔥 CRITICAL: 新規作成前にもHiveクリーンアップ
          await _cleanupInvalidHiveGroupsInternal(user.uid, hiveRepository);
        }
      } else {
        Log.info('🔍 [CREATE DEFAULT] オフラインまたはdev環境 - Hiveのみチェック');
      }

      // ⚠️ 既存グループチェック（Hive）: すでに存在する場合はスキップ
      try {
        final existingGroup = await hiveRepository.getGroupById(defaultGroupId);
        Log.info(
            '✅ [CREATE DEFAULT] デフォルトグループは既に存在します: ${existingGroup.groupName} (ID: $defaultGroupId)');
        Log.info(
            '💡 [CREATE DEFAULT] 既存グループのsyncStatus: ${existingGroup.syncStatus}');

        // 🔥 CRITICAL: Hiveクリーンアップ - allowedUidに含まれないグループを削除
        if (user != null) {
          await _cleanupInvalidHiveGroupsInternal(user.uid, hiveRepository);
        }

        // 🔥 グループ名とメンバー名の更新チェック（ユーザー名が変わった場合に対応）
        final defaultGroupName = '$displayNameグループ';
        final needsGroupNameUpdate =
            existingGroup.groupName != defaultGroupName;

        // オーナーメンバーの名前が現在のユーザー名と一致するかチェック
        SharedGroupMember? ownerMember;
        try {
          ownerMember = existingGroup.members?.firstWhere(
            (m) => m.memberId == defaultGroupId,
          );
        } catch (e) {
          // オーナーメンバーが見つからない場合はnull
          ownerMember = null;
        }
        // 🔥 FIX: ownerMemberが見つかり、名前が異なる場合は更新（空でも更新）
        final needsMemberNameUpdate =
            ownerMember != null && ownerMember.name != displayName;

        if (needsGroupNameUpdate || needsMemberNameUpdate) {
          Log.info('🔄 [CREATE DEFAULT] デフォルトグループ情報を更新');
          if (needsGroupNameUpdate) {
            Log.info(
                '  - グループ名: ${existingGroup.groupName} → $defaultGroupName');
          }
          if (needsMemberNameUpdate) {
            Log.info('  - メンバー名: ${ownerMember.name} → $displayName');
          }

          // メンバーリストの更新
          final updatedMembers = existingGroup.members?.map((m) {
            if (m.memberId == defaultGroupId) {
              return m.copyWith(name: displayName);
            }
            return m;
          }).toList();

          final updatedGroup = existingGroup.copyWith(
            groupName: defaultGroupName,
            members: updatedMembers,
          );

          // Hiveに保存
          await hiveRepository.saveGroup(updatedGroup);

          // Firestoreにも同期（サインイン状態の場合）
          if (user != null && F.appFlavor == Flavor.prod) {
            try {
              final firestore = FirebaseFirestore.instance;
              final updateData = <String, dynamic>{
                'groupName': defaultGroupName,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              // メンバー情報も更新
              if (updatedMembers != null) {
                updateData['members'] = updatedMembers
                    .map((m) => {
                          'memberId': m.memberId,
                          'name': m.name,
                          'contact': m.contact,
                          'role': m.role.toString().split('.').last,
                          'isSignedIn': m.isSignedIn,
                          'isInvited': m.isInvited,
                          'isInvitationAccepted': m.isInvitationAccepted,
                        })
                    .toList();
              }

              await firestore
                  .collection('SharedGroups')
                  .doc(defaultGroupId)
                  .update(updateData);
              Log.info('✅ [CREATE DEFAULT] Firestoreのデフォルトグループ情報も更新完了');
            } catch (e) {
              Log.error('❌ [CREATE DEFAULT] Firestoreグループ情報更新エラー: $e');
            }
          }
        }

        // ⚠️ レガシー'default_group'が残っている場合は削除
        if (defaultGroupId != 'default_group') {
          try {
            await hiveRepository.getGroupById('default_group');
            // レガシーグループが存在する場合は削除
            await hiveRepository.deleteGroup('default_group');
            Log.info('🗑️ [CREATE DEFAULT] レガシーdefault_groupを削除しました');
          } catch (e) {
            // レガシーグループが存在しない場合は何もしない
            Log.info('💡 [CREATE DEFAULT] レガシーdefault_groupは存在しません');
          }
        }

        // 🔥 CHANGED: syncStatus=localの場合、Firestoreに同期
        if (existingGroup.syncStatus == models.SyncStatus.local &&
            user != null &&
            F.appFlavor == Flavor.prod) {
          Log.info('🔄 [CREATE DEFAULT] 既存ローカルグループをFirestoreに同期開始');

          try {
            // syncStatusをsyncedに変更
            final syncedGroup = existingGroup.copyWith(
              syncStatus: models.SyncStatus.synced,
            );
            await hiveRepository.saveGroup(syncedGroup);

            // Firestoreに保存
            final firestore = FirebaseFirestore.instance;
            await firestore.collection('SharedGroups').doc(defaultGroupId).set({
              'groupId': syncedGroup.groupId,
              'groupName': syncedGroup.groupName,
              'ownerName': syncedGroup.ownerName ?? displayName, // 🔥 追加: オーナー名
              'ownerEmail':
                  syncedGroup.ownerEmail ?? user.email, // 🔥 追加: オーナーメール
              'ownerUid': user.uid,
              'allowedUid': [user.uid],
              'members': syncedGroup.members
                      ?.map((m) => {
                            'memberId': m.memberId,
                            'name': m.name,
                            'contact': m.contact,
                            'role': m.role.toString().split('.').last,
                            'isSignedIn': m.isSignedIn,
                            'isInvited': m.isInvited,
                            'isInvitationAccepted': m.isInvitationAccepted,
                          })
                      .toList() ??
                  [],
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            Log.info('✅ [CREATE DEFAULT] 既存グループのFirestore同期完了');
          } catch (e) {
            Log.error('❌ [CREATE DEFAULT] 既存グループの同期エラー: $e');
          }
        }

        // デフォルトグループが既に存在するので作成不要
        Log.info('✅ [CREATE DEFAULT] デフォルトグループは既に存在 - 作成スキップ');
        return;
      } catch (e) {
        // グループが存在しない場合は、全グループをチェック
        Log.info('🔍 [CREATE DEFAULT] 特定IDでは見つからず - 全グループをチェック');

        try {
          final allGroups = await hiveRepository.getAllGroups();
          Log.info('🔍 [CREATE DEFAULT] Hive内グループ数: ${allGroups.length}個');

          // デフォルトグループが既に存在するか確認（他のグループIDで作成済みの可能性）
          final defaultGroupExists = allGroups.any((group) {
            // group.groupIdがdefault_group固定文字列、またはuser.uidと一致
            return group.groupId == 'default_group' ||
                group.groupId == user?.uid;
          });

          if (defaultGroupExists) {
            Log.info('✅ [CREATE DEFAULT] デフォルトグループは別IDで存在 - 作成スキップ');
            return;
          }

          Log.info('📝 [CREATE DEFAULT] デフォルトグループなし - 新規作成を続行');
        } catch (e2) {
          Log.info('⚠️ [CREATE DEFAULT] グループチェックエラー: $e2 - 新規作成を続行');
        }
      }

      // オーナーメンバーを作成（memberIdにFirebase UIDを使用）
      final ownerMember = SharedGroupMember.create(
        memberId: user?.uid, // 🔥 CRITICAL: Firebase UIDを明示的に指定
        name: displayName,
        contact: user?.email ?? '',
        role: SharedGroupRole.owner,
        isSignedIn: user != null,
        isInvited: false,
        isInvitationAccepted: false,
      );

      // グループをHiveに直接作成（groupIdを明示的に指定）
      await hiveRepository.createGroup(
        defaultGroupId, // ★ user.uidを直接使用
        defaultGroupName,
        ownerMember,
      );

      Log.info(
          '✅ [CREATE DEFAULT] グループ作成完了: $defaultGroupName (ID: $defaultGroupId)');

      // 🔥 CHANGED: デフォルトグループもFirestoreに同期する
      // 理由: 複数端末で同じユーザーがログインした場合、デフォルトグループも共有されるべき
      //       groupId = user.uidなので、Firestoreでも衝突しない（ユーザーごとに一意）
      if (user != null && F.appFlavor == Flavor.prod) {
        try {
          final createdGroup =
              await hiveRepository.getGroupById(defaultGroupId);
          // syncStatusをsyncedに変更してFirestoreに同期
          final syncedGroup = createdGroup.copyWith(
            syncStatus: models.SyncStatus.synced,
          );
          await hiveRepository.saveGroup(syncedGroup);

          // Firestoreにも保存
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('SharedGroups').doc(defaultGroupId).set({
            'groupId': syncedGroup.groupId,
            'groupName': syncedGroup.groupName,
            'ownerName': syncedGroup.ownerName ?? displayName, // 🔥 追加: オーナー名
            'ownerEmail':
                syncedGroup.ownerEmail ?? user.email, // 🔥 追加: オーナーメール
            'ownerUid': user.uid,
            'allowedUid': [user.uid],
            'members': syncedGroup.members
                    ?.map((m) => {
                          'memberId': m.memberId,
                          'name': m.name,
                          'contact': m.contact,
                          'role': m.role.toString().split('.').last,
                          'isSignedIn': m.isSignedIn,
                          'isInvited': m.isInvited,
                          'isInvitationAccepted': m.isInvitationAccepted,
                        })
                    .toList() ??
                [],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          Log.info('🌐 [CREATE DEFAULT] デフォルトグループをFirestoreに同期完了');
        } catch (e) {
          Log.error('❌ [CREATE DEFAULT] Firestore同期エラー: $e');
          // エラーでもローカルには作成済みなので続行
        }
      }

      // プロバイダーを更新（UI反映）
      Log.info('🔄 [CREATE DEFAULT] UI更新完了');
    } catch (e, stackTrace) {
      Log.error('❌ [CREATE DEFAULT] デフォルトグループ作成エラー: $e');
      Log.error('❌ [CREATE DEFAULT] スタックトレース: $stackTrace');
      // rethrow; // REMOVED: Allow initialization to continue
    }
  }

  /// 🔥 Hiveから不正なグループを削除（allowedUidに現在ユーザーが含まれないもの）
  /// サインイン成功時に呼び出される
  Future<void> cleanupInvalidHiveGroups() async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) {
      Log.warning('⚠️ [CLEANUP] 認証なし - クリーンアップスキップ');
      return;
    }

    final hiveRepository = ref.read(hiveSharedGroupRepositoryProvider);
    await _cleanupInvalidHiveGroupsInternal(currentUser.uid, hiveRepository);
  }

  /// 🆕 デフォルトグループを手動でFirestoreに同期
  /// 設定画面から呼び出される（syncStatus=localの場合のみ実行）
  Future<bool> syncDefaultGroupToFirestore(User? user) async {
    if (user == null || F.appFlavor != Flavor.prod) {
      Log.warning('⚠️ [SYNC DEFAULT] 認証なしまたは開発環境 - 同期スキップ');
      return false;
    }

    final hiveRepository = ref.read(hiveSharedGroupRepositoryProvider);

    try {
      Log.info('🔄 [SYNC DEFAULT] デフォルトグループFirestore同期開始');

      // デフォルトグループを取得
      final defaultGroupId = user.uid;
      final existingGroup = await hiveRepository.getGroupById(defaultGroupId);

      // 🔥 CHANGED: 常に強制同期（syncStatusに関わらず）
      Log.info(
          '🔄 [SYNC DEFAULT] 既存グループ同期 (syncStatus: ${existingGroup.syncStatus})');

      // 🔧 CRITICAL FIX: Hiveのallowedとmemberをユーザー現在UIDに強制修正
      Log.info(
          '🔧 [SYNC] allowedUid修正前: ${existingGroup.allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()}');

      // オーナーメンバーのmemberIdを修正
      final correctedMembers = existingGroup.members?.map((member) {
            if (member.role == SharedGroupRole.owner &&
                member.memberId != user.uid) {
              Log.info(
                  '🔧 [SYNC] memberId修正: ${member.memberId} → ${user.uid}');
              return member.copyWith(memberId: user.uid);
            }
            return member;
          }).toList() ??
          [];

      // syncStatusをsyncedに変更 + allowedとmemberを修正
      final syncedGroup = existingGroup.copyWith(
        syncStatus: models.SyncStatus.synced,
        allowedUid: [user.uid], // 🔥 CRITICAL: 現在のFirebase UIDに更新
        members: correctedMembers, // memberIdも修正
      );

      Log.info(
          '✅ [SYNC] allowedUid修正後: ${syncedGroup.allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()}');

      // まずHiveに保存（キャッシュを正しい値に更新）
      await hiveRepository.saveGroup(syncedGroup);
      Log.info('✅ [SYNC] Hiveキャッシュ更新完了');

      // Firestoreに保存（allowedUidを現在のユーザーUIDに更新）
      // 🔥 CRITICAL: merge: true を使って既存ドキュメントをマージ更新
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('SharedGroups').doc(defaultGroupId).set(
        {
          'groupId': syncedGroup.groupId,
          'groupName': syncedGroup.groupName,
          'ownerUid': user.uid,
          'allowedUid': [user.uid], // 🔥 修正済みの値を使用
          'members': syncedGroup.members
                  ?.map((m) => {
                        'memberId': m.memberId, // 🔥 修正済みの値を使用
                        'name': m.name,
                        'contact': m.contact,
                        'role': m.role.toString().split('.').last,
                        'isSignedIn': m.isSignedIn,
                        'isInvited': m.isInvited,
                        'isInvitationAccepted': m.isInvitationAccepted,
                      })
                  .toList() ??
              [],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // 🔥 既存ドキュメントとマージ
      );

      Log.info('✅ [SYNC DEFAULT] デフォルトグループFirestore同期完了');

      // プロバイダーを更新してUI反映
      ref.invalidateSelf();

      return true;
    } catch (e) {
      Log.error('❌ [SYNC DEFAULT] 同期エラー: $e');
      return false;
    }
  }
}

// Selected Group Provider - 選択されたグループの詳細操作用
final selectedGroupNotifierProvider =
    AsyncNotifierProvider<SelectedGroupNotifier, SharedGroup?>(
  () => SelectedGroupNotifier(),
);

// Selected Group ID Management - 選択されたグループIDを管理するProvider
class SelectedGroupIdNotifier extends StateNotifier<String?> {
  static const String _selectedGroupIdKey = 'selected_group_id';

  SelectedGroupIdNotifier() : super(null) {
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_selectedGroupIdKey);
      if (savedId != null && savedId.isNotEmpty) {
        state = savedId;
        Log.info('✅ SelectedGroupIdNotifier: 初期値ロード完了: $savedId');
      } else {
        // 未選択状態で開始（グループリスト読み込み後に自動選択される）
        state = null;
        Log.info('ℹ️ SelectedGroupIdNotifier: 未選択状態で開始');
      }
    } catch (e) {
      Log.error('❌ SelectedGroupIdNotifier: 初期値ロードエラー: $e');
      state = null;
    }
  }

  /// SharedPreferencesから保存されたグループIDを取得
  Future<String?> getSavedGroupId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_selectedGroupIdKey);
      Log.info('🔍 SelectedGroupIdNotifier: 保存されたグループID取得: $savedId');
      return savedId;
    } catch (e) {
      Log.error('❌ SelectedGroupIdNotifier: グループID取得エラー: $e');
      return null;
    }
  }

  /// 選択されたグループIDが有効なグループリストに存在するか検証し、無効な場合は最初のグループを設定
  void validateSelection(List<SharedGroup> availableGroups) {
    if (state == null) {
      return; // 未選択状態はvalidateAndRestoreSelectionで処理される
    }

    final isValidSelection =
        availableGroups.any((group) => group.groupId == state);
    if (!isValidSelection) {
      Log.info(
          '⚠️ SelectedGroupIdNotifier: 選択されたグループが見つからないため最初のグループを選択: $state');
      // 利用可能なグループがあれば最初のものを選択
      if (availableGroups.isNotEmpty) {
        state = availableGroups.first.groupId;
        _saveToPreferences(availableGroups.first.groupId);
      } else {
        state = null;
      }
    }
  }

  /// グループリストが更新されたときに、選択状態を検証・復元
  void validateAndRestoreSelection(List<SharedGroup> availableGroups) {
    if (state == null) {
      // 未選択の場合、利用可能なグループがあれば最初のものを選択
      if (availableGroups.isNotEmpty) {
        final groupToSelect = availableGroups.first;
        Log.info(
            '🔄 SelectedGroupIdNotifier: 最初のグループを自動選択: ${groupToSelect.groupName} (${groupToSelect.groupId})');
        state = groupToSelect.groupId;
        // SharedPreferencesにも保存
        _saveToPreferences(groupToSelect.groupId);
      }
    } else {
      // 現在の選択が有効かチェック
      final isValidSelection =
          availableGroups.any((group) => group.groupId == state);
      if (!isValidSelection) {
        Log.info(
            '⚠️ SelectedGroupIdNotifier: 選択されたグループが見つからないため最初のグループを選択: $state');
        // 利用可能なグループがあれば最初のものを選択
        if (availableGroups.isNotEmpty) {
          state = availableGroups.first.groupId;
          _saveToPreferences(availableGroups.first.groupId);
        } else {
          state = null;
        }
      }
    }
  }

  Future<void> _saveToPreferences(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedGroupIdKey, groupId);
      Log.info('✅ SelectedGroupIdNotifier: グループID保存完了: $groupId');
    } catch (e) {
      Log.error('❌ SelectedGroupIdNotifier: グループID保存エラー: $e');
    }
  }

  Future<void> selectGroup(String groupId) async {
    Log.info(
        '📋 [SELECTED_GROUP_ID] グループ選択: ${AppLogger.maskGroupId(groupId)}');
    state = groupId;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedGroupIdKey, groupId);
      Log.info('✅ SelectedGroupIdNotifier: グループID保存完了: $groupId');
    } catch (e) {
      Log.error('❌ SelectedGroupIdNotifier: グループID保存エラー: $e');
    }
  }

  void clearSelection() {
    Log.info('🔄 SelectedGroupIdNotifier: 選択クリア');
    state = null;
  }
}

final selectedGroupIdProvider =
    StateNotifierProvider<SelectedGroupIdNotifier, String?>((ref) {
  final notifier = SelectedGroupIdNotifier();

  // グループリストが変更されたら選択を検証
  ref.listen(allGroupsProvider, (previous, next) {
    next.whenData((groups) {
      notifier.validateAndRestoreSelection(groups);
    });
  });

  return notifier;
});

// Member Pool Management - メンバープール管理用
class MemberPoolNotifier extends AsyncNotifier<SharedGroup> {
  @override
  Future<SharedGroup> build() async {
    final repository = ref.read(SharedGroupRepositoryProvider);

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
    final repository = ref.read(SharedGroupRepositoryProvider);

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
  Future<List<SharedGroupMember>> searchMembers(String query) async {
    Log.info('🔍 [MEMBER POOL] searchMembers() 開始: "$query"');
    final repository = ref.read(SharedGroupRepositoryProvider);

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
  Future<SharedGroupMember?> findMemberByEmail(String email) async {
    Log.info('📧 [MEMBER POOL] findMemberByEmail() 開始: $email');
    final repository = ref.read(SharedGroupRepositoryProvider);

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
    AsyncNotifierProvider<MemberPoolNotifier, SharedGroup>(
  () => MemberPoolNotifier(),
);

final allGroupsProvider =
    AsyncNotifierProvider<AllGroupsNotifier, List<SharedGroup>>(
  () => AllGroupsNotifier(),
);

// 選択されたグループを取得するプロバイダー（後方互換性のために Provider として提供）
final selectedGroupProvider = Provider<AsyncValue<SharedGroup?>>((ref) {
  return ref.watch(selectedGroupNotifierProvider);
});

// =================================================================
// ハイブリッド同期管理
// =================================================================

/// ハイブリッドリポジトリへのアクセス（本番環境のみ）
final hybridRepositoryProvider = Provider<HybridSharedGroupRepository?>((
  ref,
) {
  final repo = ref.read(SharedGroupRepositoryProvider);
  if (repo is HybridSharedGroupRepository) {
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

/// SharedGroupRoleをパース（Firestoreデータ変換用）
SharedGroupRole _parseRole(String? roleString) {
  switch (roleString) {
    case 'owner':
      return SharedGroupRole.owner;
    case 'member':
      return SharedGroupRole.member;
    default:
      return SharedGroupRole.member;
  }
}

/// Hiveから不正なグループを削除（allowedUidに現在ユーザーが含まれないもの）
/// 内部実装（外部からは cleanupInvalidHiveGroups() を使用）
Future<void> _cleanupInvalidHiveGroupsInternal(
  String currentUserId,
  HiveSharedGroupRepository hiveRepository,
) async {
  try {
    Log.info(
        '🧹 [CLEANUP] Hiveクリーンアップ開始 - currentUserId: ${AppLogger.maskUserId(currentUserId)}');

    final allHiveGroups = await hiveRepository.getAllGroups();
    Log.info('🧹 [CLEANUP] Hive内グループ数: ${allHiveGroups.length}');

    int deletedCount = 0;
    for (final group in allHiveGroups) {
      // allowedUidに現在のユーザーが含まれているか確認
      if (!group.allowedUid.contains(currentUserId)) {
        Log.info(
            '🗑️ [CLEANUP] Hiveから削除（Firestoreは保持）: ${AppLogger.maskGroup(group.groupName, group.groupId)} - allowedUid: ${group.allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()}');
        await hiveRepository
            .deleteGroup(group.groupId); // ⚠️ Hiveのみから削除、Firestoreは削除しない
        deletedCount++;
      }
    }

    if (deletedCount > 0) {
      Log.info('✅ [CLEANUP] $deletedCount個の不正グループをHiveから削除（Firestoreは保持）');
    } else {
      Log.info('✅ [CLEANUP] 削除対象なし - Hiveは正常');
    }
  } catch (e) {
    Log.error('❌ [CLEANUP] Hiveクリーンアップエラー: $e');
  }
}
