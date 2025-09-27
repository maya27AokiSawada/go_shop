// lib/providers/purchase_group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/purchase_group.dart';
import '../flavors.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';

@riverpod
class AllGroups extends _$AllGroups {
  @override
  Future<List<PurchaseGroup>> build() async {
    
    return await repository.getAllGroups();
  }
}

// PurchaseGroupの状態を管理するAsyncNotifierProvider
final purchaseGroupProvider = AsyncNotifierProvider<PurchaseGroupNotifier, PurchaseGroup>(
  () => PurchaseGroupNotifier(),
);

class PurchaseGroupNotifier extends AsyncNotifier<PurchaseGroup> {
  @override
  Future<PurchaseGroup> build() async {
    final repository = ref.read(purchaseGroupRepositoryProvider);
    final currentGroupId = ref.read(currentGroupIdProvider);
    return await repository.getGroup(currentGroupId);
  }

  // グループを更新
  Future<void> updateGroup(PurchaseGroup group) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final updatedGroup = await repository.updateGroup(group);
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
      final updatedGroup = await repository.setMyId(myId);
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

  // メンバーを更新
  Future<void> updateMembers(List<PurchaseGroupMember> members) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final updatedGroup = await repository.updateMembers(members);
      state = AsyncValue.data(updatedGroup);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// defaultGroupを取得するプロバイダー
final defaultGroupProvider = FutureProvider<PurchaseGroup>((ref) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  return await repository.getGroup('defaultGroup');
});

// すべてのグループを取得するプロバイダー
final allGroupsProvider = FutureProvider<List<PurchaseGroup>>((ref) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  return await repository.getAllGroups();
});