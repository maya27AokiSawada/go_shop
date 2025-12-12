// lib/datastore/repository/shared_group_repository.dart
import '../models/shared_group.dart';

abstract class SharedGroupRepository {
// firestore対応するまでgroupIdはdefaultGroupで固定
  Future<SharedGroup> addMember(String groupId, SharedGroupMember member);
  Future<SharedGroup> removeMember(
      String groupId, SharedGroupMember member);
  Future<List<SharedGroup>> getAllGroups();
  Future<SharedGroup> createGroup(
      String groupId, String groupName, SharedGroupMember member);
  Future<SharedGroup> deleteGroup(String groupId);
// setMemberIdはユーザーがログインした際に確定したuidを仮のuuidから置き換えるために使用
//　SharedGroup全体のcontactもしくは仮uuidが一致するメンバーを更新
// defaultGroupのみの当面は実装しない。
// ToDo　firestore対応時に実装
  Future<SharedGroup> setMemberId(
      String oldId, String newId, String? contact);
  Future<SharedGroup> getGroupById(String groupId);
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group);

  // メンバープール関連
  Future<SharedGroup> getOrCreateMemberPool();
  Future<void> syncMemberPool();
  Future<List<SharedGroupMember>> searchMembersInPool(String query);
  Future<SharedGroupMember?> findMemberByEmail(String email);

  // データベースクリーンアップ
  Future<int> cleanupDeletedGroups();
}
