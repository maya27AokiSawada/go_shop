import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../providers/hive_provider.dart';

class HivePurchaseGroupRepository implements PurchaseGroupRepository {
  // Riverpod Refを使用してBoxにアクセス
  final Ref _ref;

  // コンストラクタでRefを受け取る
  HivePurchaseGroupRepository(this._ref);

  // Boxへのアクセスをプロバイダ経由で取得
  Box<PurchaseGroup> get _box => _ref.read(purchaseGroupBoxProvider);

  // CRUDメソッド
  Future<void> saveGroup(PurchaseGroup group) async {
    await _box.put(group.groupId, group);
  }

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    return _box.values.toList();
  }

  @override
  Future<PurchaseGroup> getGroupById(String groupId) async {
    final group =  _box.get(groupId);
    if (group != null) {
      return group;
    }
    throw Exception('Group not found');
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    await _box.put(groupId, group);
    return group;
  }

  @override
  Future<PurchaseGroup> addMember(String groupId, PurchaseGroupMember member) async {
    final group = _box.get(groupId);
    if (group != null) {
      final updatedGroup = group.addMember(member);
      await _box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Group not found');
  }

  @override
  Future<PurchaseGroup> removeMember(String groupId, PurchaseGroupMember member) async {
    final group = _box.get(groupId);
    if (group != null) {
      final updatedGroup = group.removeMember(member);
      await _box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Group not found');
  }

  @override
  Future<PurchaseGroup> createGroup(String groupId, String groupName, PurchaseGroupMember member) async {
    final newGroup = PurchaseGroup(
      groupId: groupId,
      groupName: groupName,
      members: [member],
    );
    await _box.put(groupId, newGroup);
    return newGroup;
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    final group = _box.get(groupId);
    if (group != null) {
      await _box.delete(groupId);
      return group;
    }
    throw Exception('Group not found');
  }

  @override
  Future<PurchaseGroup> setMemberId(String oldId, String newId, String? contact) async {
    const groupId = 'defaultGroup';
    final group = _box.get(groupId);
    if (group != null) {
      final updatedMembers = group.members?.map((member) {
        if (member.memberId == oldId || member.contact == contact) {
          return member.copyWith(memberId: newId);
        }
        return member;
      }).toList();
      final updatedGroup = group.copyWith(members: updatedMembers);
      await _box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Default group not found');
  }

  Future<PurchaseGroup> updateMembers(String groupId, List<PurchaseGroupMember> members) async {
    final group = _box.get(groupId);
    if (group != null) {
      final updatedGroup = group.copyWith(members: members);
      await _box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Group not found');
  }

  Future<PurchaseGroup> getGroup(String groupId) async {
    return await getGroupById(groupId);
  }
}

// HivePurchaseGroupRepositoryのプロバイダー
final hivePurchaseGroupRepositoryProvider = Provider<HivePurchaseGroupRepository>((ref) {
  return HivePurchaseGroupRepository(ref);
});

// 抽象インターフェース用のプロバイダー
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  return ref.read(hivePurchaseGroupRepositoryProvider);
});

// 現在のグループIDプロバイダー（デフォルトグループ用）
final currentGroupIdProvider = Provider<String>((ref) => 'defaultGroup');

// デフォルトグループ保存用のプロバイダー
final saveDefaultGroupProvider = FutureProvider.family<void, PurchaseGroup>((ref, group) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  await repository.updateGroup(group.groupId, group);
});
