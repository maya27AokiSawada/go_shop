import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../providers/hive_provider.dart';
import '../flavors.dart';

class HivePurchaseGroupRepository implements PurchaseGroupRepository {
  final Ref ref;
  
  HivePurchaseGroupRepository(this.ref);
  
  Box<PurchaseGroup> get box => ref.read(purchaseGroupBoxProvider);
  
  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    return box.values.toList();
  }

  @override
  Future<PurchaseGroup> getGroup(String groupId) async {
    final group = box.get(groupId);
    if (group != null) {
      return group;
    }
    throw Exception('Group not found');
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    await box.put(groupId, group);
    return group;
  }

  @override
  Future<PurchaseGroup> addMember(String groupId, PurchaseGroupMember member) async {
    final group = box.get(groupId);
    if (group != null) {
      final updatedGroup = group.addMember(member);
      await box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Group not found');
  }

  @override
  Future<PurchaseGroup> removeMember(String groupId, PurchaseGroupMember member) async {
    final group = box.get(groupId);
    if (group != null) {
      final updatedGroup = group.removeMember(member);
      await box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Group not found');
  }

  @override
  Future<PurchaseGroup> updateMembers(String groupId, List<PurchaseGroupMember> members) async {
    final group = box.get(groupId);
    if (group != null) {
      final updatedGroup = group.copyWith(members: members);
      await box.put(groupId, updatedGroup);
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
    await box.put(groupId, newGroup);
    return newGroup;
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    final group = box.get(groupId);
    if (group != null) {
      await box.delete(groupId);
      return group;
    }
    throw Exception('Group not found');
  }

  @override
  Future<PurchaseGroup> setMemberId(String oldId, String newId, String? contact) async {
    const groupId = 'defaultGroup';
    final group = box.get(groupId);
    if (group != null) {
      final updatedMembers = group.members?.map((member) {
        if (member.memberId == oldId || member.contact == contact) {
          return member.copyWith(memberId: newId);
        }
        return member;
      }).toList();
      final updatedGroup = group.copyWith(members: updatedMembers);
      await box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Default group not found');
  }
}

// HivePurchaseGroupRepositoryのプロバイダー
final hivePurchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  return HivePurchaseGroupRepository(ref);
});

// 環境に応じたリポジトリプロバイダー
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    throw UnimplementedError('FirestorePurchaseGroupRepository is not implemented yet');
  } else {
    return ref.read(hivePurchaseGroupRepositoryProvider);
  }
});

// 現在のグループIDプロバイダー
final currentGroupIdProvider = Provider<String>((ref) => 'defaultGroup');
