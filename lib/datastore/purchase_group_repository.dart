// lib/datastore/repository/purchase_group_repository.dart
import '../models/purchase_group.dart';

abstract class PurchaseGroupRepository {
// firestore対応するまでgroupIdはdefaultGroupで固定
  Future<PurchaseGroup> addMember(String groupId, PurchaseGroupMember member);
  Future<PurchaseGroup> removeMember(String groupId, PurchaseGroupMember member);
  Future<List<PurchaseGroup>> getAllGroups();
  Future<PurchaseGroup> createGroup(String groupId, String groupName, PurchaseGroupMember member);
  Future<PurchaseGroup> deleteGroup(String groupId);
// setMemberIdはユーザーがログインした際に確定したuidを仮のuuidから置き換えるために使用
//　purchaseGroup全体のcontactもしくは仮uuidが一致するメンバーを更新
// defaultGroupのみの当面は実装しない。
// ToDo　firestore対応時に実装　
  Future<PurchaseGroup> setMemberId(String oldId, String newId, String? contact);
  Future<PurchaseGroup> getGroupById(String groupId);
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group);
  
  // メンバープール関連
  Future<PurchaseGroup> getOrCreateMemberPool();
  Future<void> syncMemberPool();
  Future<List<PurchaseGroupMember>> searchMembersInPool(String query);
  Future<PurchaseGroupMember?> findMemberByEmail(String email);
}
