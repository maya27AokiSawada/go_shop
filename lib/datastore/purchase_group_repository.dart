// lib/datastore/repository/purchase_group_repository.dart
import '../models/purchase_group.dart';

abstract class PurchaseGroupRepository {
  Future<PurchaseGroup> initializeGroup();
  Future<PurchaseGroup> addMember(PurchaseGroupMember member);
  Future<PurchaseGroup> removeMember(PurchaseGroupMember member);
  Future<PurchaseGroup> setMemberId(PurchaseGroupMember member, String newId);
  Future<PurchaseGroup> updateMembers(List<PurchaseGroupMember> members);
  Future<List<PurchaseGroup>> getAllGroups();
  Future<PurchaseGroup> createGroup(String groupId, String groupName, PurchaseGroupMember member);
  Future<PurchaseGroup> deleteGroup(String groupId);
  Future<PurchaseGroup> setMyId(String myId);
  Future<PurchaseGroup> getGroup(String groupId);
  Future<PurchaseGroup> updateGroup(PurchaseGroup group);
}
