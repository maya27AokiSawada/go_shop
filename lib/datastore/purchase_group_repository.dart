// lib/datastore/repository/purchase_group_repository.dart
import '../models/purchase_group.dart';

abstract class PurchaseGroupRepository {
  Future<PurchaseGroup> initializeGroup();
  Future<PurchaseGroup> addMember(PurchaseGroupMember member);
  Future<PurchaseGroup> removeMember(PurchaseGroupMember member);
  Future<PurchaseGroup> setMemberId(PurchaseGroupMember member, String newId);
}
