import 'dart:async';
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
import '../services/device_id_service.dart'; // 🆕 デバイスID生成用
// 🔥 REMOVED: import '../services/firestore_user_name_service.dart'; デフォルトグループ機能削除
import '../services/notification_service.dart';
import 'auth_provider.dart';
import 'user_specific_hive_provider.dart';
import 'current_list_provider.dart';

// Logger instance

// Repository provider - ハイブリッドリポジトリを使用
final SharedGroupRepositoryProvider = Provider<SharedGroupRepository>((
  ref,
) {
  // 🔥 devフレーバーもprodフレーバーも同じ機能（Firestore + Hive）を使用
  // 違いはFirebaseプロジェクトのみ（gotoshop-572b7 vs goshopping-48db9）
  return HybridSharedGroupRepository(ref);
});

// Selected Group Management - 選択されたグループの詳細操作用
class SelectedGroupNotifier extends AsyncNotifier<SharedGroup?> {
  // Refフィールド（他のメソッドでプロバイダーアクセスに使用）
  // ⚠️ nullable + null-aware代入でbuild()の複数回呼び出しに対応
  Ref? _ref;

  @override
  Future<SharedGroup?> build() async {
    // Refを保存（deleteCurrentGroup等で使用）
    // ⚠️ 初回のみ代入（複数回build()が呼ばれても安全）
    _ref ??= ref;

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

    // 🔥 REMOVED: デフォルトグループ削除保護を削除（デフォルトグループ機能廃止）

    final repository = ref.read(SharedGroupRepositoryProvider);

    try {
      // 削除前にグループ名を取得（通知用）
      final groupName = currentGroup.groupName;

      // ステップ1: Firestoreで削除フラグを立てる（本番環境のみ）
      final currentUser = FirebaseAuth.instance.currentUser;
      if (F.appFlavor == Flavor.prod && currentUser != null) {
        try {
          final initService = ref.read(userInitializationServiceProvider);
          await initService.markGroupAsDeletedInFirestore(
              currentUser, currentGroup.groupId);
          Log.info(
              '✅ [DELETE GROUP] Firestoreで削除フラグ設定: ${currentGroup.groupId}');

          // グループ削除通知を送信
          try {
            final deleterName = currentUser.displayName ??
                await UserPreferencesService.getUserName() ??
                'ユーザー';

            // 🔥 グループ削除通知を送信
            if (_ref != null) {
              final notificationService =
                  _ref!.read(notificationServiceProvider);
              await notificationService.sendGroupDeletedNotification(
                groupId: currentGroup.groupId,
                groupName: groupName,
                deleterName: deleterName,
              );
              Log.info('✅ [DELETE GROUP] グループ削除通知送信完了');
            } else {
              Log.warning('⚠️ [DELETE GROUP] Ref未初期化のため通知スキップ');
            }
          } catch (e) {
            Log.warning('⚠️ [DELETE GROUP] 通知送信エラー（続行）: $e');
          }
        } catch (e) {
          Log.warning('⚠️ [DELETE GROUP] Firestore削除フラグエラー（続行）: $e');
        }
      }

      // ステップ2: Hiveから削除
      await repository.deleteGroup(currentGroup.groupId);
      Log.info('✅ [DELETE GROUP] Hiveから削除完了: ${currentGroup.groupId}');

      // グループ削除後は全グループリストを更新
      await ref.read(allGroupsProvider.notifier).refresh();

      // 他のグループがあれば最初のグループを選択
      final groups = await repository.getAllGroups();
      if (groups.isNotEmpty) {
        ref
            .read(selectedGroupIdProvider.notifier)
            .selectGroup(groups.first.groupId);
      }
      // グループが0個の場合は初回セットアップ画面が表示される
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
      final currentUser = ref.watch(authStateProvider).value;
      Log.info(
          '🔍 [ALL GROUPS] 現在のユーザー: ${AppLogger.maskUserId(currentUser?.uid)}');

      if (currentUser != null) {
        final beforeFilterCount = allGroups.length;
        Log.info('🔍 [ALL GROUPS] フィルタリング前: $beforeFilterCount グループ');

        // 各グループの詳細をログ出力
        for (final group in allGroups) {
          final hasCurrentUser = group.allowedUid.contains(currentUser.uid);
          Log.info(
              '  📋 [GROUP] ${AppLogger.maskGroup(group.groupName, group.groupId)} - allowedUid: ${group.allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()} - 含む: $hasCurrentUser');
        }

        allGroups = allGroups
            .where((g) => g.allowedUid.contains(currentUser.uid))
            .toList();
        final invalidCount = beforeFilterCount - allGroups.length;
        if (invalidCount > 0) {
          Log.warning(
              '⚠️ [ALL GROUPS] allowedUid不一致グループを除外: $invalidCount グループ');
        }
        Log.info('🔍 [ALL GROUPS] フィルタリング後: ${allGroups.length} グループ');
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

      // 🆕 デバイス固有のgroupID生成（ID衝突防止）
      final groupId = await DeviceIdService.generateGroupId();
      Log.info('🆕 [CREATE GROUP] デバイスプレフィックス付きgroupId生成: $groupId');

      // グループを作成
      final newGroup = await repository.createGroup(
        groupId, // 🆕 デバイスプレフィックス付きID
        groupName,
        ownerMember,
      );

      Log.info('✅ [CREATE GROUP] グループ作成完了: ${newGroup.groupName}');

      // 🔥 CRITICAL: HybridRepositoryのcreateGroup()は既にFirestore同期済み
      // 二重のupdateGroup()呼び出しは不要（削除済み）

      // 🆕 Firestoreプラグインの内部処理が完全に完了するまで追加待機
      // Windowsプラグインのスレッド問題対策
      await Future.delayed(const Duration(milliseconds: 300));
      Log.info('✅ [CREATE GROUP] Firestore内部処理完了待機完了');

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

      // ✅ プロバイダー無効化は呼び出し側で実施
      // ここでinvalidateSelf()を呼ぶと、watchしているウィジェットが再ビルドされ、
      // 呼び出し側のBuildContextが無効になってダイアログが閉じられなくなる
      Log.info('✅ [CREATE GROUP] グループ作成処理完了（プロバイダー無効化は呼び出し側で実施）');

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

  /// 🔥 REMOVED: createDefaultGroup() - デフォルトグループ機能削除
  /// 新規ユーザーは初回セットアップ画面でグループを作成またはQRコード参加を選択

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

/// 同期状態を監視するためのStreamProvider
/// HybridRepositoryのValueNotifierから状態をStreamとして公開
final isSyncingProvider = StreamProvider<bool>((ref) {
  final hybridRepo = ref.watch(hybridRepositoryProvider);
  if (hybridRepo == null) {
    return Stream.value(false);
  }

  // ValueNotifierをStreamに変換
  final notifier = hybridRepo.isSyncingNotifier;

  // StreamControllerを作成
  late final StreamController<bool> controller;
  controller = StreamController<bool>(
    onListen: () {
      // 初期値を送信
      controller.add(notifier.value);

      // ValueNotifierのリスナーを登録
      void listener() {
        if (!controller.isClosed) {
          controller.add(notifier.value);
        }
      }

      notifier.addListener(listener);

      // クリーンアップ
      ref.onDispose(() {
        notifier.removeListener(listener);
        controller.close();
      });
    },
  );

  return controller.stream;
});

/// ValueNotifierベースの同期状態プロバイダー
/// HybridRepositoryのisSyncingNotifierを監視して即座にUI更新
final syncStatusProvider = Provider<SyncStatus>((ref) {
  // allGroupsProviderの状態を監視して同期状態を判定
  final allGroupsAsync = ref.watch(allGroupsProvider);

  // HybridRepositoryを取得
  final hybridRepo = ref.read(hybridRepositoryProvider);

  // 🔥 StreamProviderからisSyncingを取得
  final isSyncingAsync = ref.watch(isSyncingProvider);
  final isSyncing = isSyncingAsync.maybeWhen(
    data: (value) => value,
    orElse: () => false,
  );

  // AsyncValueの状態から同期状態を判定
  return allGroupsAsync.when(
    data: (_) {
      // データ取得完了 - hybridRepoの状態で判定
      if (hybridRepo == null) {
        return SyncStatus.localOnly;
      }

      if (!hybridRepo.isOnline) {
        return SyncStatus.offline;
      }

      // 🔥 StreamProviderから取得したisSyncingを使用
      if (isSyncing) {
        return SyncStatus.syncing;
      }

      return SyncStatus.synced;
    },
    loading: () => SyncStatus.syncing, // ローディング中は同期中とみなす
    error: (_, __) => SyncStatus.offline, // エラー時はオフラインとみなす
  );
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
