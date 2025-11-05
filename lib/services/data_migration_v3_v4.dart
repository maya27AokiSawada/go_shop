import 'package:go_shop/models/purchase_group.dart';
import 'package:go_shop/models/purchase_group_v4.dart';

/// データマイグレーションv3→v4
/// 冗長なメンバー情報をシンプルな構造に変換
class DataMigrationV3ToV4 {
  /// PurchaseGroupMember (v3) → PurchaseGroupMemberV4 (v4)
  static PurchaseGroupMemberV4 migrateMember(PurchaseGroupMember v3Member) {
    return PurchaseGroupMemberV4(
      uid: v3Member.uid,
      displayName: v3Member.displayName,
      role: _migrateRole(v3Member.role),
      joinedAt: v3Member.joinedAt ?? DateTime.now(),
    );
  }

  /// PurchaseGroup (v3) → PurchaseGroupV4 (v4)
  static PurchaseGroupV4 migrateGroup(PurchaseGroup v3Group) {
    final v4Members = v3Group.members.map(migrateMember).toList();

    return PurchaseGroupV4(
      groupId: v3Group.groupId,
      groupName: v3Group.groupName,
      ownerUid: v3Group.ownerUid,
      members: v4Members,
      createdAt: v3Group.createdAt ?? DateTime.now(),
      updatedAt: v3Group.updatedAt ?? DateTime.now(),
    );
  }

  /// 複数グループを一括変換
  static List<PurchaseGroupV4> migrateGroups(List<PurchaseGroup> v3Groups) {
    return v3Groups.map(migrateGroup).toList();
  }

  /// Role enumの変換
  static PurchaseGroupRoleV4 _migrateRole(PurchaseGroupRole v3Role) {
    switch (v3Role) {
      case PurchaseGroupRole.owner:
        return PurchaseGroupRoleV4.owner;
      case PurchaseGroupRole.member:
        return PurchaseGroupRoleV4.member;
      case PurchaseGroupRole.manager:
        return PurchaseGroupRoleV4.manager;
    }
  }

  /// 逆変換: v4 → v3 (後方互換性用)
  static PurchaseGroupMember reverseMigrateMember(
      PurchaseGroupMemberV4 v4Member) {
    return PurchaseGroupMember(
      uid: v4Member.uid,
      displayName: v4Member.displayName,
      role: _reverseMigrateRole(v4Member.role),
      joinedAt: v4Member.joinedAt,
    );
  }

  static PurchaseGroup reverseMigrateGroup(PurchaseGroupV4 v4Group) {
    final v3Members = v4Group.members.map(reverseMigrateMember).toList();

    return PurchaseGroup(
      groupId: v4Group.groupId,
      groupName: v4Group.groupName,
      ownerUid: v4Group.ownerUid,
      members: v3Members,
      createdAt: v4Group.createdAt,
      updatedAt: v4Group.updatedAt,
    );
  }

  static PurchaseGroupRole _reverseMigrateRole(PurchaseGroupRoleV4 v4Role) {
    switch (v4Role) {
      case PurchaseGroupRoleV4.owner:
        return PurchaseGroupRole.owner;
      case PurchaseGroupRoleV4.member:
        return PurchaseGroupRole.member;
      case PurchaseGroupRoleV4.manager:
        return PurchaseGroupRole.manager;
    }
  }
}
