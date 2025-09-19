import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import 'package:hive/hive.dart';



class HivePurchaseGroupRepository implements PurchaseGroupRepository {
  final Ref ref;

  HivePurchaseGroupRepository(this.ref);

  @override
  Future<PurchaseGroup> initializeGroup() async {
    final box = await Hive.openBox<PurchaseGroup>('purchaseGroups');
    return box.get('currentGroup') ?? 
      PurchaseGroup(groupID: '0', groupName: 'Default Group', 
      members: [PurchaseGroupMember(
        name: 'あなた',
        contact: '',
        role: PurchaseGroupRole.leader
      )]);
  }

  @override
  Future<PurchaseGroup> addMember(PurchaseGroupMember member) async {
    final box = await Hive.openBox<PurchaseGroup>('purchaseGroups');
    final currentGroup = box.get('currentGroup');
    if (currentGroup != null && !currentGroup.members.contains(member)) {
      final updatedMembers = [...currentGroup.members, member];
      final updatedGroup = currentGroup.copyWith(members: updatedMembers);
      await box.put('currentGroup', updatedGroup);
      return updatedGroup;
    }
    return currentGroup!;
  }

  @override
  Future<PurchaseGroup> removeMember(PurchaseGroupMember member) async {
    final box = await Hive.openBox<PurchaseGroup>('purchaseGroups');
    final currentGroup = box.get('currentGroup');
    if (currentGroup != null && currentGroup.members.contains(member)) {
      final updatedMembers = currentGroup.members.where((m) => m != member).toList();
      final updatedGroup = currentGroup.copyWith(members: updatedMembers);
      await box.put('currentGroup', updatedGroup);
      return updatedGroup;
    }
    return currentGroup!;
  }
  @override
  Future<PurchaseGroup> setMemberId(PurchaseGroupMember member, String newId) async {
    final box = await Hive.openBox<PurchaseGroup>('purchaseGroups');
    final currentGroup = box.get('currentGroup');
    if (currentGroup != null) {
      final updatedMembers = currentGroup.members.map((m) {
        if (m == member) {
          return m.copyWith(memberID: newId);
        }
        return m;
      }).toList();
      final updatedGroup = currentGroup.copyWith(members: updatedMembers);
      await box.put('currentGroup', updatedGroup);
      return updatedGroup;
    }
    return currentGroup!;
  }
}