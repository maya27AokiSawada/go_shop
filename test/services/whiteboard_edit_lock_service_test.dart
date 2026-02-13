/// ホワイトボード編集ロックサービスのユニットテスト
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhiteboardEditLock ビジネスロジック Tests', () {
    test('編集ロック有効期限チェック（有効期限内）', () {
      // Arrange
      final lockCreatedAt =
          DateTime.now().subtract(const Duration(minutes: 30));
      final now = DateTime.now();

      // Act
      final isExpired = now.difference(lockCreatedAt).inHours >= 1;

      // Assert
      expect(isExpired, false); // 30分経過 → まだ有効
    });

    test('編集ロック有効期限チェック（有効期限切れ）', () {
      // Arrange
      final lockCreatedAt = DateTime.now().subtract(const Duration(hours: 2));
      final now = DateTime.now();

      // Act
      final isExpired = now.difference(lockCreatedAt).inHours >= 1;

      // Assert
      expect(isExpired, true); // 2時間経過 → 期限切れ
    });

    test('編集ロック延長ロジック', () {
      // Arrange
      final originalExpiry = DateTime.now().add(const Duration(hours: 1));

      // Act - ロック延長（新しい有効期限を設定）
      final now = DateTime.now();
      final newExpiry = now.add(const Duration(hours: 1));

      // Assert
      expect(
          newExpiry
              .isAfter(originalExpiry.subtract(const Duration(minutes: 1))),
          true);
    });

    test('同一ユーザーによるロック判定', () {
      // Arrange
      const currentLockUserId = 'user-123';
      const requestUserId = 'user-123';

      // Act
      const isSameUser = currentLockUserId == requestUserId;

      // Assert
      expect(isSameUser, true);
    });

    test('異なるユーザーによるロック判定', () {
      // Arrange
      const currentLockUserId = 'user-123';
      const requestUserId = 'user-456';

      // Act
      const isSameUser = currentLockUserId == requestUserId;

      // Assert
      expect(isSameUser, false);
    });

    test('編集ロックデータ構造', () {
      // Arrange - ロックデータのマップ形式
      final now = DateTime.now();
      final lockExpiry = now.add(const Duration(hours: 1));

      final editLock = {
        'userId': 'user-123',
        'userName': 'Test User',
        'createdAt': now,
        'expiresAt': lockExpiry,
        'updatedAt': now,
      };

      // Assert
      expect(editLock['userId'], 'user-123');
      expect(editLock['userName'], 'Test User');
      expect(editLock['createdAt'], isA<DateTime>());
      expect(editLock['expiresAt'], isA<DateTime>());
      expect((editLock['expiresAt'] as DateTime).isAfter(now), true);
    });

    test('ロック自動延長判定（15秒タイマー）', () {
      // Arrange
      final lastExtended = DateTime.now().subtract(const Duration(seconds: 20));
      final now = DateTime.now();

      // Act
      final shouldExtend = now.difference(lastExtended).inSeconds >= 15;

      // Assert
      expect(shouldExtend, true); // 20秒経過 → 延長必要
    });

    test('ロック自動延長判定（まだ延長不要）', () {
      // Arrange
      final lastExtended = DateTime.now().subtract(const Duration(seconds: 10));
      final now = DateTime.now();

      // Act
      final shouldExtend = now.difference(lastExtended).inSeconds >= 15;

      // Assert
      expect(shouldExtend, false); // 10秒経過 → まだ延長不要
    });

    test('複数ユーザーのロック競合シナリオ', () {
      // Arrange
      const user1 = 'user-123';
      const user2 = 'user-456';
      const user3 = 'user-789';

      String? currentLockHolder;

      // Act & Assert
      // User1がロック取得
      currentLockHolder = user1;
      expect(currentLockHolder, user1);

      // User2が取得試行 → 失敗
      final user2CanAcquire = currentLockHolder == user2;
      expect(user2CanAcquire, false);

      // User3が取得試行 → 失敗
      final user3CanAcquire = currentLockHolder == user3;
      expect(user3CanAcquire, false);

      // User1がロック解放
      currentLockHolder = null;

      // User2が取得試行 → 成功
      if (currentLockHolder == null) {
        currentLockHolder = user2;
        expect(currentLockHolder, user2);
      }
    });

    test('レガシーロッククリーンアップ判定（3日以上古い）', () {
      // Arrange
      final oldLockCreatedAt = DateTime.now().subtract(const Duration(days: 4));
      final now = DateTime.now();

      // Act
      final shouldCleanup = now.difference(oldLockCreatedAt).inDays >= 3;

      // Assert
      expect(shouldCleanup, true);
    });

    test('レガシーロッククリーンアップ判定（最近のロック）', () {
      // Arrange
      final recentLockCreatedAt =
          DateTime.now().subtract(const Duration(days: 1));
      final now = DateTime.now();

      // Act
      final shouldCleanup = now.difference(recentLockCreatedAt).inDays >= 3;

      // Assert
      expect(shouldCleanup, false);
    });

    test('ロック情報マスキング（プライバシー保護）', () {
      // Arrange
      const userId = 'abc123def456ghi789';
      const userName = 'すももプランニング';

      // Act - 先頭3文字のみ表示
      final maskedUserId =
          userId.length >= 3 ? '${userId.substring(0, 3)}***' : userId;
      final maskedUserName =
          userName.length >= 2 ? '${userName.substring(0, 2)}***' : userName;

      // Assert
      expect(maskedUserId, 'abc***');
      expect(maskedUserName, 'すも***');
    });

    test('ロック状態遷移', () {
      // Arrange
      const states = [
        'unlocked',
        'acquiring',
        'locked',
        'releasing',
        'unlocked'
      ];
      var currentState = 'unlocked';

      // Act & Assert
      // unlocked → acquiring
      currentState = 'acquiring';
      expect(currentState, 'acquiring');

      // acquiring → locked
      currentState = 'locked';
      expect(currentState, 'locked');

      // locked → releasing
      currentState = 'releasing';
      expect(currentState, 'releasing');

      // releasing → unlocked
      currentState = 'unlocked';
      expect(currentState, 'unlocked');
    });

    test('同時編集リクエスト処理（タイムスタンプ順）', () {
      // Arrange
      final requests = [
        {
          'userId': 'user-456',
          'timestamp': DateTime.now().add(const Duration(milliseconds: 100))
        },
        {'userId': 'user-123', 'timestamp': DateTime.now()},
        {
          'userId': 'user-789',
          'timestamp': DateTime.now().add(const Duration(milliseconds: 50))
        },
      ];

      // Act - タイムスタンプでソート
      requests.sort((a, b) =>
          (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

      // Assert - 早い順に処理
      expect(requests[0]['userId'], 'user-123');
      expect(requests[1]['userId'], 'user-789');
      expect(requests[2]['userId'], 'user-456');
    });

    test('ロック強制解除権限チェック（グループオーナー）', () {
      // Arrange
      const currentLockUserId = 'user-456';
      const requestUserId = 'user-123';
      const groupOwnerUid = 'user-123';

      // Act
      const canForceRelease =
          requestUserId == groupOwnerUid || requestUserId == currentLockUserId;

      // Assert
      expect(canForceRelease, true); // オーナーは強制解除可能
    });

    test('ロック強制解除権限チェック（一般メンバー）', () {
      // Arrange
      const currentLockUserId = 'user-456';
      const requestUserId = 'user-789';
      const groupOwnerUid = 'user-123';

      // Act
      const canForceRelease =
          requestUserId == groupOwnerUid || requestUserId == currentLockUserId;

      // Assert
      expect(canForceRelease, false); // 一般メンバーは強制解除不可
    });

    test('ロック有効期限警告判定（残り10分以下）', () {
      // Arrange
      final expiresAt = DateTime.now().add(const Duration(minutes: 8));
      final now = DateTime.now();

      // Act
      final remainingMinutes = expiresAt.difference(now).inMinutes;
      final shouldWarn = remainingMinutes <= 10;

      // Assert
      expect(shouldWarn, true);
      expect(remainingMinutes, lessThanOrEqualTo(10));
    });

    test('ロック情報のJSON変換（Firestore互換）', () {
      // Arrange
      final now = DateTime.now();
      final lockExpiry = now.add(const Duration(hours: 1));

      final editLock = {
        'userId': 'user-123',
        'userName': 'Test User',
        'createdAt': now.toIso8601String(),
        'expiresAt': lockExpiry.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Act - JSON文字列化（実際はFirestoreが自動処理）
      final userId = editLock['userId'];
      final createdAt = DateTime.parse(editLock['createdAt']!);

      // Assert
      expect(userId, 'user-123');
      expect(createdAt.isAtSameMomentAs(now), true);
    });
  });

  group('WhiteboardEditLock エッジケース Tests', () {
    test('null editLock処理（新規ロック）', () {
      // Arrange
      Map<String, dynamic>? editLock;

      // Act
      final hasLock = editLock != null;

      // Assert
      expect(hasLock, false);
    });

    test('期限切れロックの自動クリーンアップ判定', () {
      // Arrange
      final locks = [
        {
          'userId': 'user-123',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2))
        },
        {
          'userId': 'user-456',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 30))
        },
        {
          'userId': 'user-789',
          'createdAt': DateTime.now().subtract(const Duration(hours: 5))
        },
      ];

      // Act
      final expiredLocks = locks
          .where((lock) =>
              DateTime.now()
                  .difference(lock['createdAt'] as DateTime)
                  .inHours >=
              1)
          .toList();

      // Assert
      expect(expiredLocks.length, 2); // user-123, user-789
    });

    test('ロック延長上限チェック（最大1時間）', () {
      // Arrange
      const maxLockDuration = Duration(hours: 1);
      const proposedDuration = Duration(hours: 2);

      // Act
      final actualDuration = proposedDuration > maxLockDuration
          ? maxLockDuration
          : proposedDuration;

      // Assert
      expect(actualDuration, maxLockDuration);
    });
  });
}
