import 'package:flutter_test/flutter_test.dart';
import 'package:go_shop/models/purchase_group.dart';
import 'package:go_shop/models/purchase_group_v4.dart';
import 'package:go_shop/services/data_migration_v3_v4.dart';

void main() {
  group('DataMigrationV3ToV4', () {
    test('メンバーのマイグレーション（v3→v4）', () {
      // v3メンバーの作成
      final v3Member = PurchaseGroupMember(
        uid: 'user123',
        displayName: 'テストユーザー',
        role: PurchaseGroupRole.member,
        joinedAt: DateTime(2025, 11, 1),
      );

      // v4へマイグレーション
      final v4Member = DataMigrationV3ToV4.migrateMember(v3Member);

      // 検証
      expect(v4Member.uid, 'user123');
      expect(v4Member.displayName, 'テストユーザー');
      expect(v4Member.role, PurchaseGroupRoleV4.member);
      expect(v4Member.joinedAt, DateTime(2025, 11, 1));
    });

    test('グループのマイグレーション（v3→v4）', () {
      // v3グループの作成
      final v3Group = PurchaseGroup.create(
        groupName: 'テストグループ',
        ownerUid: 'owner123',
        ownerDisplayName: 'オーナー',
        groupId: 'group123',
      );

      // メンバー追加
      final v3GroupWithMembers = v3Group.addMember(
        PurchaseGroupMember.create(
          uid: 'member456',
          displayName: 'メンバー1',
        ),
      );

      // v4へマイグレーション
      final v4Group = DataMigrationV3ToV4.migrateGroup(v3GroupWithMembers);

      // 検証
      expect(v4Group.groupId, 'group123');
      expect(v4Group.groupName, 'テストグループ');
      expect(v4Group.ownerUid, 'owner123');
      expect(v4Group.members.length, 2); // オーナー + メンバー1
      expect(v4Group.members[0].uid, 'owner123');
      expect(v4Group.members[1].uid, 'member456');
    });

    test('逆マイグレーション（v4→v3）', () {
      // v4グループの作成
      final v4Group = PurchaseGroupV4.create(
        groupName: 'テストグループ',
        ownerUid: 'owner789',
        ownerDisplayName: 'オーナー',
        groupId: 'group789',
      );

      // v3へ逆マイグレーション
      final v3Group = DataMigrationV3ToV4.reverseMigrateGroup(v4Group);

      // 検証
      expect(v3Group.groupId, 'group789');
      expect(v3Group.groupName, 'テストグループ');
      expect(v3Group.ownerUid, 'owner789');
      expect(v3Group.members.length, 1); // オーナーのみ
    });

    test('ロールの変換', () {
      final roles = [
        PurchaseGroupRole.owner,
        PurchaseGroupRole.member,
        PurchaseGroupRole.manager,
      ];

      for (final v3Role in roles) {
        final v3Member = PurchaseGroupMember(
          uid: 'test',
          displayName: 'Test',
          role: v3Role,
        );

        final v4Member = DataMigrationV3ToV4.migrateMember(v3Member);
        final backToV3 = DataMigrationV3ToV4.reverseMigrateMember(v4Member);

        // ロールが正しく変換されているか
        expect(backToV3.role, v3Role);
      }
    });
  });
}
