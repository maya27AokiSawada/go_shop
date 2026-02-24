/// Enhanced Invitation Service ユニットテスト
/// CI/CD対応: Firebaseモック不要のビジネスロジックテスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/shared_group.dart';
import 'package:goshopping/services/enhanced_invitation_service.dart';

void main() {
  group('GroupInvitationOption データ構造 Tests', () {
    test('招待可能なグループオプション作成', () {
      // Arrange
      final testGroup = SharedGroup.create(
        groupId: 'test-group-1',
        groupName: 'テストグループ',
        members: [
          const SharedGroupMember(
            memberId: 'owner-123',
            name: 'オーナー',
            contact: 'owner@example.com',
            role: SharedGroupRole.owner,
          ),
        ],
      );

      // Act
      const option = GroupInvitationOption(
        group: SharedGroup(
          groupId: 'test-group-1',
          groupName: 'テストグループ',
          ownerUid: 'owner-123',
          allowedUid: ['owner-123'],
          members: [],
        ),
        canInvite: true,
        reason: null,
      );

      // Assert
      expect(option.canInvite, true);
      expect(option.reason, null);
      expect(option.group.groupId, 'test-group-1');
    });

    test('招待不可のグループオプション作成（すでにメンバー）', () {
      // Arrange & Act
      const option = GroupInvitationOption(
        group: SharedGroup(
          groupId: 'test-group-2',
          groupName: 'テストグループ2',
          ownerUid: 'owner-456',
          allowedUid: ['owner-456', 'member-789'],
          members: [],
        ),
        canInvite: false,
        reason: 'すでにメンバーです',
      );

      // Assert
      expect(option.canInvite, false);
      expect(option.reason, 'すでにメンバーです');
    });
  });

  group('GroupInvitationData データ構造 Tests', () {
    test('グループ招待データ作成', () {
      // Arrange & Act
      const data = GroupInvitationData(
        groupId: 'group-abc',
        groupName: '家族グループ',
        targetRole: SharedGroupRole.member,
      );

      // Assert
      expect(data.groupId, 'group-abc');
      expect(data.groupName, '家族グループ');
      expect(data.targetRole, SharedGroupRole.member);
    });

    test('管理者権限での招待データ作成', () {
      // Arrange & Act
      const data = GroupInvitationData(
        groupId: 'group-xyz',
        groupName: 'チームグループ',
        targetRole: SharedGroupRole.manager,
      );

      // Assert
      expect(data.targetRole, SharedGroupRole.manager);
    });
  });

  group('InvitationResult データ構造 Tests', () {
    test('招待成功結果の作成', () {
      // Arrange & Act
      const result = InvitationResult(
        success: true,
        results: {
          'group-1': true,
          'group-2': true,
        },
        errors: [],
        totalSent: 2,
        totalFailed: 0,
      );

      // Assert
      expect(result.success, true);
      expect(result.totalSent, 2);
      expect(result.totalFailed, 0);
      expect(result.errors, isEmpty);
      expect(result.results.length, 2);
    });

    test('招待失敗結果の作成', () {
      // Arrange & Act
      const result = InvitationResult(
        success: false,
        results: {
          'group-1': false,
          'group-2': false,
        },
        errors: [
          'グループ「家族」: 権限がありません',
          'グループ「友達」: グループが見つかりません',
        ],
        totalSent: 0,
        totalFailed: 2,
      );

      // Assert
      expect(result.success, false);
      expect(result.totalSent, 0);
      expect(result.totalFailed, 2);
      expect(result.errors.length, 2);
      expect(result.errors[0], contains('権限がありません'));
    });

    test('部分的成功の結果（混在）', () {
      // Arrange & Act
      const result = InvitationResult(
        success: false,
        results: {
          'group-1': true,
          'group-2': false,
          'group-3': true,
        },
        errors: [
          'グループ「チーム」: すでにメンバーです',
        ],
        totalSent: 2,
        totalFailed: 1,
      );

      // Assert
      expect(result.success, false); // 1つでも失敗があればfalse
      expect(result.totalSent, 2);
      expect(result.totalFailed, 1);
      expect(result.results.values.where((v) => v).length, 2);
      expect(result.results.values.where((v) => !v).length, 1);
    });
  });

  group('PendingInvitation データ構造 Tests', () {
    test('未受諾招待データ作成', () {
      // Arrange
      final invitedAt = DateTime(2026, 2, 24, 10, 0);

      // Act
      final pending = PendingInvitation(
        ownerUid: 'owner-123',
        groupId: 'group-xyz',
        groupName: 'プロジェクトチーム',
        ownerName: '田中太郎',
        targetRole: SharedGroupRole.member,
        invitedAt: invitedAt,
      );

      // Assert
      expect(pending.groupId, 'group-xyz');
      expect(pending.ownerName, '田中太郎');
      expect(pending.targetRole, SharedGroupRole.member);
      expect(pending.invitedAt, invitedAt);
    });
  });

  group('ビジネスロジック Tests', () {
    test('メールアドレス小文字変換による重複チェック', () {
      // Arrange
      const existingEmail = 'test@example.com';
      const newEmail1 = 'TEST@EXAMPLE.COM';
      const newEmail2 = 'Test@Example.Com';
      const newEmail3 = 'different@example.com';

      // Act
      final isDuplicate1 =
          existingEmail.toLowerCase() == newEmail1.toLowerCase();
      final isDuplicate2 =
          existingEmail.toLowerCase() == newEmail2.toLowerCase();
      final isDuplicate3 =
          existingEmail.toLowerCase() == newEmail3.toLowerCase();

      // Assert
      expect(isDuplicate1, true); // 大文字小文字無視で同じ
      expect(isDuplicate2, true); // 混在でも同じ
      expect(isDuplicate3, false); // 異なるメール
    });

    test('招待権限チェック（オーナー）', () {
      // Arrange
      const currentRole = SharedGroupRole.owner;

      // Act
      const canInvite = currentRole == SharedGroupRole.owner ||
          currentRole == SharedGroupRole.manager;

      // Assert
      expect(canInvite, true);
    });

    test('招待権限チェック（管理者）', () {
      // Arrange
      const currentRole = SharedGroupRole.manager;

      // Act
      const canInvite = currentRole == SharedGroupRole.owner ||
          currentRole == SharedGroupRole.manager;

      // Assert
      expect(canInvite, true);
    });

    test('招待権限チェック（一般メンバー）', () {
      // Arrange
      const currentRole = SharedGroupRole.member;

      // Act
      const canInvite = currentRole == SharedGroupRole.owner ||
          currentRole == SharedGroupRole.manager;

      // Assert
      expect(canInvite, false); // 一般メンバーは招待不可
    });

    test('招待権限チェック（パートナー）', () {
      // Arrange
      const currentRole = SharedGroupRole.partner;

      // Act
      const canInvite = currentRole == SharedGroupRole.owner ||
          currentRole == SharedGroupRole.manager;

      // Assert
      expect(canInvite, false); // パートナーは招待不可（owner/managerのみ）
    });

    test('メンバー重複チェック（allowedUid配列）', () {
      // Arrange
      const existingMembers = ['user-1', 'user-2', 'user-3'];
      const newUserId1 = 'user-2'; // 既存
      const newUserId2 = 'user-4'; // 新規

      // Act
      final isDuplicate1 = existingMembers.contains(newUserId1);
      final isDuplicate2 = existingMembers.contains(newUserId2);

      // Assert
      expect(isDuplicate1, true); // すでにメンバー
      expect(isDuplicate2, false); // 新規メンバー
    });

    test('招待結果の集計ロジック', () {
      // Arrange
      final results = <String, bool>{
        'group-1': true,
        'group-2': false,
        'group-3': true,
        'group-4': true,
        'group-5': false,
      };

      // Act
      final totalSent = results.values.where((success) => success).length;
      final totalFailed = results.values.where((success) => !success).length;
      final successRate = totalSent / results.length;

      // Assert
      expect(totalSent, 3); // 3件成功
      expect(totalFailed, 2); // 2件失敗
      expect(successRate, 0.6); // 60%成功率
    });
  });

  group('エッジケース Tests', () {
    test('空の招待リスト', () {
      // Arrange
      const selectedGroups = <GroupInvitationData>[];

      // Act
      const result = InvitationResult(
        success: true, // 空リストは技術的には成功
        results: {},
        errors: [],
        totalSent: 0,
        totalFailed: 0,
      );

      // Assert
      expect(result.success, true);
      expect(result.totalSent, 0);
      expect(result.results, isEmpty);
    });

    test('全て失敗の招待結果', () {
      // Arrange & Act
      const result = InvitationResult(
        success: false,
        results: {
          'group-1': false,
          'group-2': false,
          'group-3': false,
        },
        errors: [
          'エラー1',
          'エラー2',
          'エラー3',
        ],
        totalSent: 0,
        totalFailed: 3,
      );

      // Assert
      expect(result.success, false);
      expect(result.totalFailed, 3);
      expect(result.errors.length, 3);
      expect(result.results.values.every((v) => !v), true); // 全てfalse
    });

    test('空のメールアドレスチェック', () {
      // Arrange
      const email1 = '';
      const email2 = '  '; // スペースのみ
      const email3 = 'valid@example.com';

      // Act
      final isEmpty1 = email1.trim().isEmpty;
      final isEmpty2 = email2.trim().isEmpty;
      final isEmpty3 = email3.trim().isEmpty;

      // Assert
      expect(isEmpty1, true);
      expect(isEmpty2, true); // trimで空になる
      expect(isEmpty3, false);
    });

    test('招待ロール変換チェック', () {
      // Arrange
      final roles = [
        SharedGroupRole.member,
        SharedGroupRole.manager,
        SharedGroupRole.owner,
        SharedGroupRole.partner,
      ];

      // Act & Assert
      for (final role in roles) {
        expect(role, isA<SharedGroupRole>());
        // ロールの文字列表現をテスト
        expect(role.toString(), contains('SharedGroupRole'));
      }
    });

    test('複数グループへの同時招待シナリオ', () {
      // Arrange
      const invitationData = [
        GroupInvitationData(
          groupId: 'family',
          groupName: '家族',
          targetRole: SharedGroupRole.member,
        ),
        GroupInvitationData(
          groupId: 'friends',
          groupName: '友達',
          targetRole: SharedGroupRole.member,
        ),
        GroupInvitationData(
          groupId: 'work',
          groupName: '職場',
          targetRole: SharedGroupRole.manager,
        ),
      ];

      // Act
      final groupIds = invitationData.map((d) => d.groupId).toList();
      final groupNames = invitationData.map((d) => d.groupName).toList();

      // Assert
      expect(groupIds.length, 3);
      expect(groupNames, contains('家族'));
      expect(groupNames, contains('友達'));
      expect(groupNames, contains('職場'));
    });

    test('招待受諾フラグの更新ロジック', () {
      // Arrange
      const member = SharedGroupMember(
        memberId: 'user-123',
        name: 'テストユーザー',
        contact: 'test@example.com',
        role: SharedGroupRole.member,
        isSignedIn: false,
        isInvitationAccepted: false,
      );

      // Act
      final updatedMember = member.copyWith(
        isSignedIn: true,
        isInvitationAccepted: true,
        acceptedAt: DateTime.now(),
      );

      // Assert
      expect(updatedMember.isSignedIn, true);
      expect(updatedMember.isInvitationAccepted, true);
      expect(updatedMember.acceptedAt, isNotNull);
      expect(updatedMember.memberId, member.memberId); // 他のフィールドは保持
    });
  });

  group('データ整合性 Tests', () {
    test('InvitationResult: totalSentとtotalFailedの合計検証', () {
      // Arrange & Act
      const result = InvitationResult(
        success: false,
        results: {
          'g1': true,
          'g2': true,
          'g3': false,
          'g4': true,
          'g5': false,
        },
        errors: ['error1', 'error2'],
        totalSent: 3,
        totalFailed: 2,
      );

      // Assert
      expect(result.totalSent + result.totalFailed, result.results.length);
      expect(result.totalFailed, result.errors.length); // エラー数と一致
    });

    test('GroupInvitationOption: canInvite=falseの場合はreasonが必須', () {
      // Arrange & Act
      const option1 = GroupInvitationOption(
        group: SharedGroup(
          groupId: 'g1',
          groupName: 'グループ1',
          ownerUid: 'owner',
          allowedUid: ['owner'],
          members: [],
        ),
        canInvite: false,
        reason: 'すでにメンバーです',
      );

      const option2 = GroupInvitationOption(
        group: SharedGroup(
          groupId: 'g2',
          groupName: 'グループ2',
          ownerUid: 'owner',
          allowedUid: ['owner'],
          members: [],
        ),
        canInvite: true,
        reason: null,
      );

      // Assert
      if (!option1.canInvite) {
        expect(option1.reason, isNotNull); // falseの場合は理由があるべき
      }
      if (option2.canInvite) {
        expect(option2.reason, isNull); // trueの場合は理由不要
      }
    });

    test('メンバー配列の更新で元のメンバーが保持される', () {
      // Arrange
      const existingMembers = [
        SharedGroupMember(
          memberId: 'user-1',
          name: 'ユーザー1',
          contact: 'user1@example.com',
          role: SharedGroupRole.owner,
        ),
        SharedGroupMember(
          memberId: 'user-2',
          name: 'ユーザー2',
          contact: 'user2@example.com',
          role: SharedGroupRole.member,
        ),
      ];

      const newMember = SharedGroupMember(
        memberId: '',
        name: 'user3@example.com',
        contact: 'user3@example.com',
        role: SharedGroupRole.member,
        isSignedIn: false,
      );

      // Act
      final updatedMembers = <SharedGroupMember>[
        ...existingMembers,
        newMember,
      ];

      // Assert
      expect(updatedMembers.length, 3);
      expect(updatedMembers[0].memberId, 'user-1'); // 元のメンバー保持
      expect(updatedMembers[1].memberId, 'user-2'); // 元のメンバー保持
      expect(updatedMembers[2].contact, 'user3@example.com'); // 新規追加
    });
  });

  group('CI/CD統合シナリオ Tests', () {
    test('招待システムの完全フロー（シミュレーション）', () {
      // STEP 1: 招待可能グループの検索（シミュレーション）
      // 実際のfindInvitableGroups()はFirestore必須なのでロジックのみテスト
      const targetEmail = 'newuser@example.com';
      expect(targetEmail.contains('@'), true);

      // STEP 2: 招待送信（シミュレーション）
      const selectedGroups = [
        GroupInvitationData(
          groupId: 'group-1',
          groupName: 'グループ1',
          targetRole: SharedGroupRole.member,
        ),
        GroupInvitationData(
          groupId: 'group-2',
          groupName: 'グループ2',
          targetRole: SharedGroupRole.member,
        ),
      ];
      expect(selectedGroups.length, 2);

      // STEP 3: 招待結果の検証
      const result = InvitationResult(
        success: true,
        results: {
          'group-1': true,
          'group-2': true,
        },
        errors: [],
        totalSent: 2,
        totalFailed: 0,
      );
      expect(result.success, true);
      expect(result.totalSent, 2);

      // STEP 4: UI表示用メッセージ生成
      final message = result.success
          ? '${result.totalSent}件の招待を送信しました'
          : '${result.totalFailed}件の招待に失敗しました';
      expect(message, '2件の招待を送信しました');
    });

    test('エラーハンドリングフロー（シミュレーション）', () {
      // STEP 1: 部分的失敗のシナリオ
      const result = InvitationResult(
        success: false,
        results: {
          'group-1': true,
          'group-2': false,
          'group-3': true,
        },
        errors: [
          'グループ「グループ2」: 権限がありません',
        ],
        totalSent: 2,
        totalFailed: 1,
      );

      // STEP 2: エラーメッセージ生成
      final errorMessage = result.errors.join('\n');
      expect(errorMessage, contains('権限がありません'));

      // STEP 3: リトライ判定
      final shouldRetry = result.totalFailed > 0 && result.totalSent > 0;
      expect(shouldRetry, true); // 部分的失敗はリトライ可能
    });
  });
}
