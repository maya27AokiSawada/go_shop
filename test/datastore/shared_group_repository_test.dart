// SharedGroup モデルのユニットテスト
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/shared_group.dart';

void main() {
  group('SharedGroup モデル CRUD Tests', () {
    test('SharedGroup - 正しく作成できる', () {
      // Arrange
      const groupId = 'group-001';
      const groupName = 'テストグループ';
      const ownerUid = 'user-123';
      const member = SharedGroupMember(
        memberId: ownerUid,
        name: 'Test User',
        contact: 'test@example.com',
        role: SharedGroupRole.owner,
      );

      // Act
      final group = SharedGroup(
        groupId: groupId,
        groupName: groupName,
        ownerUid: ownerUid,
        allowedUid: [ownerUid],
        members: [member],
        createdAt: DateTime.now(),
      );

      // Assert
      expect(group.groupId, groupId);
      expect(group.groupName, groupName);
      expect(group.ownerUid, ownerUid);
      expect(group.allowedUid.length, 1);
      expect(group.members?.length, 1);
    });

    test('SharedGroup - copyWithで更新できる', () {
      // Arrange
      final original = SharedGroup(
        groupId: 'group-001',
        groupName: 'Original Group',
        ownerUid: 'user-123',
        allowedUid: ['user-123'],
        createdAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(
        groupName: 'Updated Group',
        allowedUid: ['user-123', 'user-456'],
      );

      // Assert
      expect(updated.groupId, original.groupId);
      expect(updated.groupName, 'Updated Group');
      expect(updated.allowedUid.length, 2);
      expect(updated.allowedUid.contains('user-456'), true);
    });

    test('SharedGroupMember - 正しく作成できる', () {
      // Act
      const member = SharedGroupMember(
        memberId: 'user-123',
        name: 'Test User',
        contact: 'test@example.com',
        role: SharedGroupRole.member,
      );

      // Assert
      expect(member.memberId, 'user-123');
      expect(member.name, 'Test User');
      expect(member.contact, 'test@example.com');
      expect(member.role, SharedGroupRole.member);
    });

    test('SharedGroupRole - 正しいroleの種類がある', () {
      // Assert
      expect(SharedGroupRole.values.length, 4);
      expect(SharedGroupRole.values.contains(SharedGroupRole.owner), true);
      expect(SharedGroupRole.values.contains(SharedGroupRole.member), true);
      expect(SharedGroupRole.values.contains(SharedGroupRole.manager), true);
      expect(SharedGroupRole.values.contains(SharedGroupRole.partner), true);
    });

    test('SharedGroup - デフォルトグループ判定', () {
      // Arrange
      const userId = 'user-123';
      final defaultGroup = SharedGroup(
        groupId: userId, // デフォルトグループはgroupId == userId
        groupName: '$userIdグループ',
        ownerUid: userId,
        allowedUid: [userId],
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.local,
      );

      final normalGroup = SharedGroup(
        groupId: 'group-001',
        groupName: '家族グループ',
        ownerUid: userId,
        allowedUid: [userId],
        createdAt: DateTime.now(),
      );

      // Assert
      expect(defaultGroup.groupId == userId, true);
      expect(defaultGroup.syncStatus, SyncStatus.local);
      expect(normalGroup.groupId != userId, true);
    });

    test('SharedGroup - メンバーリスト操作（追加）', () {
      // Arrange
      const member1 = SharedGroupMember(
        memberId: 'user-1',
        name: 'Alice',
        contact: 'alice@example.com',
        role: SharedGroupRole.owner,
      );
      const member2 = SharedGroupMember(
        memberId: 'user-2',
        name: 'Bob',
        contact: 'bob@example.com',
        role: SharedGroupRole.member,
      );
      const member3 = SharedGroupMember(
        memberId: 'user-3',
        name: 'Charlie',
        contact: 'charlie@example.com',
        role: SharedGroupRole.member,
      );

      // Act
      final members = [member1, member2, member3];
      final group = SharedGroup(
        groupId: 'group-001',
        groupName: 'Test Group',
        ownerUid: 'user-1',
        allowedUid: ['user-1', 'user-2', 'user-3'],
        members: members,
        createdAt: DateTime.now(),
      );

      // Assert
      expect(group.members?.length, 3);
      expect(
          group.members?.where((m) => m.role == SharedGroupRole.owner).length,
          1);
      expect(
          group.members?.where((m) => m.role == SharedGroupRole.member).length,
          2);
    });

    test('SharedGroup - メンバーロール検証', () {
      // Arrange
      const owner = SharedGroupMember(
        memberId: 'user-1',
        name: 'Owner',
        contact: 'owner@example.com',
        role: SharedGroupRole.owner,
      );
      const manager = SharedGroupMember(
        memberId: 'user-2',
        name: 'Manager',
        contact: 'manager@example.com',
        role: SharedGroupRole.manager,
      );

      // Act
      final members = [owner, manager];
      final group = SharedGroup(
        groupId: 'group-001',
        groupName: 'Test Group',
        ownerUid: 'user-1',
        allowedUid: ['user-1', 'user-2'],
        members: members,
        createdAt: DateTime.now(),
      );

      // Assert
      for (final member in group.members ?? []) {
        if (member.memberId == 'user-1') {
          expect(member.role, SharedGroupRole.owner);
        } else if (member.memberId == 'user-2') {
          expect(member.role, SharedGroupRole.manager);
        }
      }
    });

    test('SharedGroup - メンバー追加操作', () {
      // Arrange
      final originalGroup = SharedGroup(
        groupId: 'group-001',
        groupName: 'Original Group',
        ownerUid: 'user-1',
        allowedUid: ['user-1'],
        members: const [
          SharedGroupMember(
            memberId: 'user-1',
            name: 'Alice',
            contact: 'alice@example.com',
            role: SharedGroupRole.owner,
          ),
        ],
        createdAt: DateTime.now(),
      );

      const newMember = SharedGroupMember(
        memberId: 'user-2',
        name: 'Bob',
        contact: 'bob@example.com',
        role: SharedGroupRole.member,
      );

      // Act
      final updatedGroup = originalGroup.copyWith(
        allowedUid: [...originalGroup.allowedUid, 'user-2'],
        members: [...?originalGroup.members, newMember],
      );

      // Assert
      expect(updatedGroup.members?.length, 2);
      expect(updatedGroup.allowedUid.length, 2);
      expect(updatedGroup.members?.any((m) => m.memberId == 'user-2'), true);
    });

    test('SharedGroup - メンバー削除操作', () {
      // Arrange
      const memberToRemove = 'user-2';
      final originalGroup = SharedGroup(
        groupId: 'group-001',
        groupName: 'Original Group',
        ownerUid: 'user-1',
        allowedUid: ['user-1', 'user-2', 'user-3'],
        members: const [
          SharedGroupMember(
            memberId: 'user-1',
            name: 'Alice',
            contact: 'alice@example.com',
            role: SharedGroupRole.owner,
          ),
          SharedGroupMember(
            memberId: 'user-2',
            name: 'Bob',
            contact: 'bob@example.com',
            role: SharedGroupRole.member,
          ),
          SharedGroupMember(
            memberId: 'user-3',
            name: 'Charlie',
            contact: 'charlie@example.com',
            role: SharedGroupRole.member,
          ),
        ],
        createdAt: DateTime.now(),
      );

      // Act
      final updatedGroup = originalGroup.copyWith(
        allowedUid: originalGroup.allowedUid
            .where((uid) => uid != memberToRemove)
            .toList(),
        members: originalGroup.members
            ?.where((m) => m.memberId != memberToRemove)
            .toList(),
      );

      // Assert
      expect(updatedGroup.members?.length, 2);
      expect(updatedGroup.allowedUid.length, 2);
      expect(updatedGroup.members?.any((m) => m.memberId == 'user-2'), false);
    });
  });
}
