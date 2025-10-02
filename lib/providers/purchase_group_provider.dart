// lib/providers/purchase_group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../models/purchase_group.dart';
import 'user_settings_provider.dart';
import 'shopping_list_provider.dart';

// 現在選択中のグループIDを管理するStateNotifier
class SelectedGroupIdNotifier extends StateNotifier<String> {
  final Ref _ref;
  
  SelectedGroupIdNotifier(this._ref) : super('defaultGroup') {
    _loadFromSettings();
  }
  
  // 設定から初期値を読み込み
  void _loadFromSettings() {
    final lastUsedGroupId = _ref.read(lastUsedGroupIdProvider);
    if (lastUsedGroupId.isNotEmpty) {
      state = lastUsedGroupId;
    }
  }
  
  Future<void> selectGroup(String groupId) async {
    state = groupId;
    // 設定に保存
    await _ref.read(userSettingsProvider.notifier).updateLastUsedGroupId(groupId);
    
    // 関連プロバイダーを更新
    _ref.read(purchaseGroupProvider.notifier).refreshForSelectedGroup();
  }
}

// 現在選択中のグループIDプロバイダー
final selectedGroupIdProvider = StateNotifierProvider<SelectedGroupIdNotifier, String>((ref) {
  return SelectedGroupIdNotifier(ref);
});

// PurchaseGroupの状態を管理するAsyncNotifierProvider
class PurchaseGroupNotifier extends AsyncNotifier<PurchaseGroup> {
  @override
  Future<PurchaseGroup> build() async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    final selectedGroupId = ref.read(selectedGroupIdProvider);
    return await repository.getGroupById(selectedGroupId);
  }

  // グループを更新
  Future<void> updateGroup(PurchaseGroup group) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final updatedGroup = await repository.updateGroup(group.groupId, group);
      state = AsyncValue.data(updatedGroup);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // メンバーを追加
  Future<void> addMember(PurchaseGroupMember member) async {
    final currentGroup = await future;
    final updatedGroup = currentGroup.addMember(member);
    await updateGroup(updatedGroup);
  }

  // メンバーを削除
  Future<void> removeMember(PurchaseGroupMember member) async {
    final currentGroup = await future;
    final updatedGroup = currentGroup.removeMember(member);
    await updateGroup(updatedGroup);
  }

  // 自分のIDを設定
  Future<void> setMyId(String myId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final updatedGroup = await repository.setMemberId('tempId', myId, null);
      state = AsyncValue.data(updatedGroup);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // グループを作成
  Future<void> createGroup(String groupId, String groupName, PurchaseGroupMember member) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final newGroup = await repository.createGroup(groupId, groupName, member);
      state = AsyncValue.data(newGroup);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // グループを削除
  Future<void> deleteGroup(String groupId) async {
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      await repository.deleteGroup(groupId);
      
      // 現在選択中のグループが削除された場合はデフォルトグループに切り替え
      final selectedGroupId = ref.read(selectedGroupIdProvider);
      if (selectedGroupId == groupId) {
        ref.read(selectedGroupIdProvider.notifier).selectGroup('defaultGroup');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  // 新しいグループを作成
  Future<void> createNewGroup(String groupName) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final shoppingListRepository = ref.read(shoppingListRepositoryProvider);
      final userName = ref.read(userNameFromSettingsProvider);
      final finalUserName = userName.isEmpty ? 'Unknown User' : userName;
      
      // 新しいグループIDを生成
      final newGroupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
      
      // オーナーメンバーを作成
      final ownerMember = PurchaseGroupMember(
        memberId: 'defaultUser',
        name: finalUserName,
        contact: 'default@example.com',
        role: PurchaseGroupRole.owner,
        isSignedIn: true,
      );
      
      // グループを作成
      final newGroup = await repository.createGroup(newGroupId, groupName, ownerMember);
      
      // 対応するショッピングリストを自動作成
      await shoppingListRepository.getOrCreateList(newGroupId, groupName);
      
      // 新しく作成したグループを選択
      await ref.read(selectedGroupIdProvider.notifier).selectGroup(newGroupId);
      
      // allGroupsProviderを更新（Dropdownメニューで表示されるように）
      await ref.read(allGroupsProvider.notifier).refresh();
      
      state = AsyncValue.data(newGroup);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  // グループを切り替え
  Future<void> switchToGroup(String groupId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final group = await repository.getGroupById(groupId);
      state = AsyncValue.data(group);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // 選択されたグループの変更に応じてプロバイダーを更新
  Future<void> refreshForSelectedGroup() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final selectedGroupId = ref.read(selectedGroupIdProvider);
      final group = await repository.getGroupById(selectedGroupId);
      state = AsyncValue.data(group);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // メンバーを更新（カスタム実装）
  Future<void> updateMembers(List<PurchaseGroupMember> members) async {
    state = const AsyncValue.loading();
    try {
      final currentGroup = await future;
      final updatedGroup = currentGroup.copyWith(members: members);
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final result = await repository.updateGroup(updatedGroup.groupId, updatedGroup);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// PurchaseGroupNotifierのプロバイダー
final purchaseGroupProvider = AsyncNotifierProvider<PurchaseGroupNotifier, PurchaseGroup>(
  () => PurchaseGroupNotifier(),
);

// defaultGroupを取得するプロバイダー
final defaultGroupProvider = FutureProvider<PurchaseGroup>((ref) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  return await repository.getGroupById('defaultGroup');
});

// すべてのグループを管理するAsyncNotifierProvider
class AllGroupsNotifier extends AsyncNotifier<List<PurchaseGroup>> {
  @override
  Future<List<PurchaseGroup>> build() async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    return await repository.getAllGroups();
  }

  // グループリストを更新
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final groups = await repository.getAllGroups();
      state = AsyncValue.data(groups);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// すべてのグループを取得するプロバイダー
final allGroupsProvider = AsyncNotifierProvider<AllGroupsNotifier, List<PurchaseGroup>>(() {
  return AllGroupsNotifier();
});
