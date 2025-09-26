// lib/providers/purchase_group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_group.dart';
import '../flavors.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';

// PurchaseGroupRepositoryのプロバイダー
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  // 例: flavorや設定値で切り替え
  if (F.appFlavor == Flavor.prod) {
    // return FirestorePurchaseGroupRepository(ref);
    throw UnimplementedError('FirestorePurchaseGroupRepository is not implemented yet');
  } else {
    return HivePurchaseGroupRepository(ref);  
  }
});

// PurchaseGroupBoxのプロバイダー
final purchaseGroupBoxProvider = FutureProvider<Box<PurchaseGroup>>((ref) async {
  final box = await Hive.openBox<PurchaseGroup>('purchaseGroups');
  return box;
});

// 特定のgroupIdを持つグループを取得するプロバイダー
final purchaseGroupByIdProvider = FutureProvider.family<PurchaseGroup?, String>((ref, groupId) async {
  final box = await ref.watch(purchaseGroupBoxProvider.future);
  return box.get(groupId);
});

// すべてのグループを取得するプロバイダー
final allPurchaseGroupsProvider = FutureProvider<List<PurchaseGroup>>((ref) async {
  final box = await ref.watch(purchaseGroupBoxProvider.future);
  return box.values.toList();
});

// 条件で絞り込むプロバイダー（グループ名で検索）
final purchaseGroupsByNameProvider = FutureProvider.family<List<PurchaseGroup>, String>((ref, namePattern) async {
  final box = await ref.watch(purchaseGroupBoxProvider.future);
  return box.values
      .where((group) => group.groupName.contains(namePattern))
      .toList();
});

// 現在のグループを管理するProvider
final currentGroupIdProvider = Provider<String>((ref) => 'currentGroup');

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

// すべてのグループを取得するプロバイダー
final allGroupsProvider = FutureProvider<List<PurchaseGroup>>((ref) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  return await repository.getAllGroups();
});