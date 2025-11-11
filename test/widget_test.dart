// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_shop/models/purchase_group.dart';

void main() {
  group('Go Shop Data Structure Tests', () {
    test('InvitationStatus enum has correct values', () {
      expect(InvitationStatus.values.length, 4);
      expect(InvitationStatus.values, contains(InvitationStatus.self));
      expect(InvitationStatus.values, contains(InvitationStatus.pending));
      expect(InvitationStatus.values, contains(InvitationStatus.accepted));
      expect(InvitationStatus.values, contains(InvitationStatus.deleted));
    });

    test('PurchaseGroupMember can be created with new fields', () {
      final member = PurchaseGroupMember(
        memberId: 'test-id',
        name: 'Test User',
        contact: 'test@example.com',
        role: PurchaseGroupRole.member,
        invitationStatus: InvitationStatus.pending,
        securityKey: 'test-security-key',
        invitedAt: DateTime.now(),
      );

      expect(member.memberId, 'test-id');
      expect(member.name, 'Test User');
      expect(member.contact, 'test@example.com');
      expect(member.role, PurchaseGroupRole.member);
      expect(member.invitationStatus, InvitationStatus.pending);
      expect(member.securityKey, 'test-security-key');
      expect(member.invitedAt, isNotNull);
    });

    test('PurchaseGroupMember maintains backward compatibility', () {
      const member = PurchaseGroupMember(
        memberId: 'test-id',
        name: 'Test User',
        contact: 'test@example.com',
        role: PurchaseGroupRole.member,
        invitationStatus: InvitationStatus.accepted,
      );

      // Test the new status system
      expect(member.invitationStatus, InvitationStatus.accepted);
      expect(member.isAccepted, true);
      expect(member.isPending, false);
      expect(member.isDeleted, false);
      expect(member.isSelf, false);
    });

    test('InvitationStatus helper methods work correctly', () {
      const pendingMember = PurchaseGroupMember(
        memberId: 'pending-id',
        name: 'Pending User',
        contact: 'pending@example.com',
        role: PurchaseGroupRole.member,
        invitationStatus: InvitationStatus.pending,
      );

      const selfMember = PurchaseGroupMember(
        memberId: 'self-id',
        name: 'Self User',
        contact: 'self@example.com',
        role: PurchaseGroupRole.owner,
        invitationStatus: InvitationStatus.self,
      );

      expect(pendingMember.isPending, true);
      expect(pendingMember.isAccepted, false);
      expect(pendingMember.isDeleted, false);
      expect(pendingMember.isSelf, false);

      expect(selfMember.isPending, false);
      expect(selfMember.isAccepted, false);
      expect(selfMember.isDeleted, false);
      expect(selfMember.isSelf, true);
    });

    test('PurchaseGroup can be created with security features', () {
      const member = PurchaseGroupMember(
        memberId: 'owner-id',
        name: 'Owner',
        contact: 'owner@example.com',
        role: PurchaseGroupRole.owner,
        invitationStatus: InvitationStatus.self,
      );

      const group = PurchaseGroup(
        groupName: 'Test Group',
        groupId: 'test-group-123',
        ownerName: 'Owner Name',
        ownerEmail: 'owner@example.com',
        ownerUid: 'owner-uid',
        members: [member],
      );

      expect(group.groupName, 'Test Group');
      expect(group.groupId, 'test-group-123');
      expect(group.members!.length, 1);
      expect(group.members!.first.invitationStatus, InvitationStatus.self);
    });
  });
}
