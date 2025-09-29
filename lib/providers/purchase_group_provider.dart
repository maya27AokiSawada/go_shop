// lib/providers/purchase_group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../models/purchase_group.dart';

// PurchaseGroupの状態を管理するAsyncNotifierProvider
class PurchaseGroupNotifier extends AsyncNotifier<PurchaseGroup> {
  @override
  Future<PurchaseGroup> build() async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    final currentGroupId = ref.read(currentGroupIdProvider);
    return await repository.getGroupById(currentGroupId);
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
      // デフォルトグループを読み込み
      await build();
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

// すべてのグループを取得するプロバイダー
final allGroupsProvider = FutureProvider<List<PurchaseGroup>>((ref) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  return await repository.getAllGroups();
});