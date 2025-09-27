import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../flavors.dart';

final String currentGroupId = F.appFlavor
  == Flavor.dev ? 'currentGroup' : 'currentGroup';

// シンプルなFutureProviderでBoxを提供
final purchaseGroupBoxProvider = FutureProvider<Box<PurchaseGroup>>((ref) async {
  return Hive.openBox<PurchaseGroup>('purchaseGroups');
});

class HivePurchaseGroupRepository implements PurchaseGroupRepository {
  final Ref ref;
  final Box<PurchaseGroup> box = Hive.box<PurchaseGroup>('purchaseGroups');
  HivePurchaseGroupRepository(this.ref);

  @override
  Future<PurchaseGroup> createGroup(String groupId,
                                    String groupName,
                                    PurchaseGroupMember member) async {
    final newGroup = PurchaseGroup(
      groupId: groupId,
      groupName: groupName,
      members: [member],
    );
    await box.put(groupId, newGroup);
    return newGroup;
  }

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    return box.values.toList();
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
  Future<PurchaseGroup> setMyId(String myId) async {
    final currentGroup = box.get(currentGroupId);
    if (currentGroup != null) {
      final updatedMembers = currentGroup.members!.map((member) {
        if (member.role == PurchaseGroupRole.leader) {
          return member.copyWith(memberId: myId);
        }
        return member;
      }).toList();
      final updatedGroup = currentGroup.copyWith(members: updatedMembers);
      await box.put(currentGroupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('No current group found');
  }

  @override
  Future<PurchaseGroup> getGroup(String groupId) async {
    final group = box.get(groupId);
    if (group != null) {
      return group;
    }
    // デフォルトグループを作成
    final defaultGroup = PurchaseGroup(
      groupId: groupId,
      groupName: 'Default Group',
      members: [PurchaseGroupMember(
        name: 'あなた',
        contact: '',
        role: PurchaseGroupRole.leader
      )],
    );
    await box.put(groupId, defaultGroup);
    return defaultGroup;
  }

  @override
  Future<PurchaseGroup> updateGroup(PurchaseGroup group) async {
    await box.put(group.groupId, group);
    return group;
  }

  @override
  Future<PurchaseGroup> initializeGroup() async {
    final defaultGroup = PurchaseGroup(
      groupId: currentGroupId,
      groupName: 'Default Group',
      members: [PurchaseGroupMember(
        name: 'あなた',
        contact: '',
        role: PurchaseGroupRole.leader
      )],
    );
    await box.put(currentGroupId, defaultGroup);
    return defaultGroup;
  }

  @override
  Future<PurchaseGroup> addMember(PurchaseGroupMember member) async {
    final currentGroup = box.get(currentGroupId);
    if (currentGroup != null && currentGroup.members != null) {
      final updatedGroup = currentGroup.addMember(member);
      await box.put(currentGroupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('No current group found');
  }

  @override
  Future<PurchaseGroup> removeMember(PurchaseGroupMember member) async {
    final currentGroup = box.get(currentGroupId);
    if (currentGroup != null && currentGroup.members != null) {
      final updatedGroup = currentGroup.removeMember(member);
      await box.put(currentGroupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('No current group found');
  }

  @override
  Future<PurchaseGroup> setMemberId(PurchaseGroupMember member, String newId) async {
    final currentGroup = box.get(currentGroupId);
    if (currentGroup != null && currentGroup.members != null) {
      final updatedMembers = currentGroup.members!.map((m) {
        if (m.name == member.name && m.contact == member.contact) {
          return m.copyWith(memberId: newId);
        }
        return m;
      }).toList();
      final updatedGroup = currentGroup.copyWith(members: updatedMembers);
      await box.put(currentGroupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('No current group found');
  }

  @override
  Future<PurchaseGroup> updateMembers(List<PurchaseGroupMember> members) async {
    final currentGroup = box.get(currentGroupId);
    if (currentGroup != null) {
      final updatedGroup = currentGroup.copyWith(members: members);
      await box.put(currentGroupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('No current group found');
  }
}