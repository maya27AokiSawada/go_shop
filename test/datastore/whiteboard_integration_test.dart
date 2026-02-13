/// ホワイトボード統合テスト（マルチユーザー同時編集シナリオ）
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/whiteboard.dart';
import 'package:flutter/material.dart';

void main() {
  group('Whiteboard 統合シナリオ Tests', () {
    test('マルチユーザー同時描画シナリオ', () {
      // Arrange - 3人のユーザーが同時に描画
      final user1Strokes = [
        DrawingStroke(
          strokeId: 'user1-stroke-001',
          points: const [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100)
          ],
          colorValue: Colors.red.value,
          strokeWidth: 3.0,
          createdAt: DateTime.now(),
          authorId: 'user-123',
          authorName: 'User A',
        ),
      ];

      final user2Strokes = [
        DrawingStroke(
          strokeId: 'user2-stroke-001',
          points: const [
            DrawingPoint(x: 200, y: 200),
            DrawingPoint(x: 300, y: 300)
          ],
          colorValue: Colors.blue.value,
          strokeWidth: 4.0,
          createdAt: DateTime.now(),
          authorId: 'user-456',
          authorName: 'User B',
        ),
      ];

      final user3Strokes = [
        DrawingStroke(
          strokeId: 'user3-stroke-001',
          points: const [
            DrawingPoint(x: 400, y: 400),
            DrawingPoint(x: 500, y: 500)
          ],
          colorValue: Colors.green.value,
          strokeWidth: 5.0,
          createdAt: DateTime.now(),
          authorId: 'user-789',
          authorName: 'User C',
        ),
      ];

      // Act - 全ユーザーのストロークをマージ
      final allStrokes = [...user1Strokes, ...user2Strokes, ...user3Strokes];

      final whiteboard = Whiteboard(
        whiteboardId: 'wb-001',
        groupId: 'group-001',
        strokes: allStrokes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(whiteboard.strokes.length, 3);
      expect(whiteboard.strokes[0].authorId, 'user-123');
      expect(whiteboard.strokes[1].authorId, 'user-456');
      expect(whiteboard.strokes[2].authorId, 'user-789');

      // 各ユーザーのストロークが正しく保持されている
      final user1StrokesInWb =
          whiteboard.strokes.where((s) => s.authorId == 'user-123').toList();
      final user2StrokesInWb =
          whiteboard.strokes.where((s) => s.authorId == 'user-456').toList();
      final user3StrokesInWb =
          whiteboard.strokes.where((s) => s.authorId == 'user-789').toList();

      expect(user1StrokesInWb.length, 1);
      expect(user2StrokesInWb.length, 1);
      expect(user3StrokesInWb.length, 1);
    });

    test('ストローク追加時の重複防止ロジック', () {
      // Arrange - 既存のホワイトボード
      final existingStrokes = [
        DrawingStroke(
          strokeId: 'stroke-001',
          points: const [DrawingPoint(x: 0, y: 0)],
          colorValue: Colors.red.value,
          createdAt: DateTime.now(),
          authorId: 'user-123',
          authorName: 'User A',
        ),
        DrawingStroke(
          strokeId: 'stroke-002',
          points: const [DrawingPoint(x: 100, y: 100)],
          colorValue: Colors.blue.value,
          createdAt: DateTime.now(),
          authorId: 'user-456',
          authorName: 'User B',
        ),
      ];

      // 新しく追加するストローク（一部重複）
      final newStrokes = [
        DrawingStroke(
          strokeId: 'stroke-002', // 重複
          points: const [DrawingPoint(x: 200, y: 200)],
          colorValue: Colors.green.value,
          createdAt: DateTime.now(),
          authorId: 'user-789',
          authorName: 'User C',
        ),
        DrawingStroke(
          strokeId: 'stroke-003', // 新規
          points: const [DrawingPoint(x: 300, y: 300)],
          colorValue: Colors.yellow.value,
          createdAt: DateTime.now(),
          authorId: 'user-789',
          authorName: 'User C',
        ),
      ];

      // Act - 重複チェック処理
      final existingStrokeIds = existingStrokes.map((s) => s.strokeId).toSet();
      final uniqueNewStrokes = newStrokes
          .where((stroke) => !existingStrokeIds.contains(stroke.strokeId))
          .toList();

      // Assert
      expect(uniqueNewStrokes.length, 1); // stroke-003のみ
      expect(uniqueNewStrokes.first.strokeId, 'stroke-003');
    });

    test('ストロークマージ後のソート（作成時刻順）', () {
      // Arrange
      final now = DateTime.now();
      final stroke1 = DrawingStroke(
        strokeId: 'stroke-001',
        points: const [DrawingPoint(x: 0, y: 0)],
        colorValue: Colors.red.value,
        createdAt: now.subtract(const Duration(seconds: 3)),
        authorId: 'user-123',
        authorName: 'User A',
      );

      final stroke2 = DrawingStroke(
        strokeId: 'stroke-002',
        points: const [DrawingPoint(x: 100, y: 100)],
        colorValue: Colors.blue.value,
        createdAt: now.subtract(const Duration(seconds: 1)),
        authorId: 'user-456',
        authorName: 'User B',
      );

      final stroke3 = DrawingStroke(
        strokeId: 'stroke-003',
        points: const [DrawingPoint(x: 200, y: 200)],
        colorValue: Colors.green.value,
        createdAt: now.subtract(const Duration(seconds: 2)),
        authorId: 'user-789',
        authorName: 'User C',
      );

      // Act - ソート
      final unsortedStrokes = [stroke2, stroke3, stroke1];
      final sortedStrokes = [...unsortedStrokes]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Assert - 古い順
      expect(sortedStrokes[0].strokeId, 'stroke-001');
      expect(sortedStrokes[1].strokeId, 'stroke-003');
      expect(sortedStrokes[2].strokeId, 'stroke-002');
    });

    test('個人用ホワイトボードのアクセス権限', () {
      // Arrange - User Aの個人用ホワイトボード（isPrivate=false）
      final personalWhiteboard = Whiteboard(
        whiteboardId: 'wb-personal-001',
        groupId: 'group-001',
        ownerId: 'user-123', // User A
        isPrivate: false, // プライベートOFF
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - isPrivate=falseなら他人も編集可能
      // User A: 編集可能
      expect(personalWhiteboard.canEdit('user-123'), true);

      // User B: 編集可能（isPrivate=false）
      expect(personalWhiteboard.canEdit('user-456'), true);

      // User C: 編集可能（isPrivate=false）
      expect(personalWhiteboard.canEdit('user-789'), true);
    });

    test('個人用ホワイトボードのアクセス権限（プライベート）', () {
      // Arrange - User Aの個人用ホワイトボード（isPrivate=true）
      final privatePersonalWhiteboard = Whiteboard(
        whiteboardId: 'wb-personal-002',
        groupId: 'group-001',
        ownerId: 'user-123', // User A
        isPrivate: true, // プライベートON
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - isPrivate=trueならオーナーのみ編集可能
      // User A: 編集可能
      expect(privatePersonalWhiteboard.canEdit('user-123'), true);

      // User B: 編集不可
      expect(privatePersonalWhiteboard.canEdit('user-456'), false);

      // User C: 編集不可
      expect(privatePersonalWhiteboard.canEdit('user-789'), false);
    });

    test('グループ共通ホワイトボードのアクセス権限（非プライベート）', () {
      // Arrange
      final groupWhiteboard = Whiteboard(
        whiteboardId: 'wb-group-001',
        groupId: 'group-001',
        ownerId: null, // グループ共通
        isPrivate: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - 全員編集可能
      expect(groupWhiteboard.canEdit('user-123'), true);
      expect(groupWhiteboard.canEdit('user-456'), true);
      expect(groupWhiteboard.canEdit('user-789'), true);
    });

    test('グループ共通ホワイトボードのアクセス権限（プライベート）', () {
      // Arrange
      final privateGroupWhiteboard = Whiteboard(
        whiteboardId: 'wb-group-002',
        groupId: 'group-001',
        ownerId: null, // グループ共通
        isPrivate: true, // プライベート
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - 全員編集不可
      expect(privateGroupWhiteboard.canEdit('user-123'), false);
      expect(privateGroupWhiteboard.canEdit('user-456'), false);
      expect(privateGroupWhiteboard.canEdit('user-789'), false);
    });

    test('複数ホワイトボード管理（グループ共通+個人用）', () {
      // Arrange
      final groupWhiteboard = Whiteboard(
        whiteboardId: 'wb-group-001',
        groupId: 'group-001',
        ownerId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personalWhiteboards = [
        Whiteboard(
          whiteboardId: 'wb-personal-001',
          groupId: 'group-001',
          ownerId: 'user-123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Whiteboard(
          whiteboardId: 'wb-personal-002',
          groupId: 'group-001',
          ownerId: 'user-456',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final allWhiteboards = [groupWhiteboard, ...personalWhiteboards];

      // Act
      final groupWbs =
          allWhiteboards.where((wb) => wb.isGroupWhiteboard).toList();
      final personalWbs =
          allWhiteboards.where((wb) => wb.isPersonalWhiteboard).toList();

      // Assert
      expect(allWhiteboards.length, 3);
      expect(groupWbs.length, 1);
      expect(personalWbs.length, 2);
    });

    test('ストロークundo/redo実装パターン', () {
      // Arrange
      final history = <List<DrawingStroke>>[];
      var currentStrokes = <DrawingStroke>[];

      // 初期状態を履歴に追加
      history.add(List.from(currentStrokes));

      // Act - 3回描画
      for (var i = 0; i < 3; i++) {
        final newStroke = DrawingStroke(
          strokeId: 'stroke-$i',
          points: [DrawingPoint(x: i * 100.0, y: i * 100.0)],
          colorValue: Colors.black.value,
          createdAt: DateTime.now(),
          authorId: 'user-123',
          authorName: 'User A',
        );
        currentStrokes = [...currentStrokes, newStroke];
        history.add(List.from(currentStrokes));
      }

      // undo 2回
      var historyIndex = history.length - 1;
      historyIndex--; // undo 1回目
      currentStrokes = history[historyIndex];
      expect(currentStrokes.length, 2);

      historyIndex--; // undo 2回目
      currentStrokes = history[historyIndex];
      expect(currentStrokes.length, 1);

      // redo 1回
      historyIndex++;
      currentStrokes = history[historyIndex];
      expect(currentStrokes.length, 2);

      // Assert
      expect(history.length, 4); // 初期 + 3回描画
      expect(currentStrokes.length, 2);
    });

    test('ストローク自動分割ロジック（距離ベース）', () {
      // Arrange - 連続した点
      final points = [
        const DrawingPoint(x: 0, y: 0),
        const DrawingPoint(x: 10, y: 10),
        const DrawingPoint(x: 100, y: 100), // 距離30px以上 → 別ストローク
        const DrawingPoint(x: 110, y: 110),
      ];

      // Act - 距離チェック
      final strokes = <List<DrawingPoint>>[];
      var currentStroke = <DrawingPoint>[];

      for (var i = 0; i < points.length; i++) {
        if (currentStroke.isEmpty) {
          currentStroke.add(points[i]);
        } else {
          final lastPoint = currentStroke.last;
          final distance = ((points[i].x - lastPoint.x).abs() +
                  (points[i].y - lastPoint.y).abs()) /
              2;

          if (distance > 30) {
            // 別ストロークとして保存
            strokes.add(List.from(currentStroke));
            currentStroke = [points[i]];
          } else {
            currentStroke.add(points[i]);
          }
        }
      }

      // 最後のストロークを追加
      if (currentStroke.isNotEmpty) {
        strokes.add(currentStroke);
      }

      // Assert
      expect(strokes.length, 2); // 2つのストロークに分割
      expect(strokes[0].length, 2); // 最初のストローク
      expect(strokes[1].length, 2); // 2番目のストローク
    });

    test('大規模ホワイトボード（100ストローク）のパフォーマンス', () {
      // Arrange
      const strokeCount = 100;
      final stopwatch = Stopwatch()..start();

      final strokes = List.generate(
        strokeCount,
        (i) => DrawingStroke(
          strokeId: 'stroke-$i',
          points:
              List.generate(30, (j) => DrawingPoint(x: j * 10.0, y: i * 5.0)),
          colorValue: Colors.black.value,
          strokeWidth: 3.0,
          createdAt: DateTime.now(),
          authorId: 'user-${i % 3}',
          authorName: 'User ${i % 3}',
        ),
      );

      // Act - ホワイトボード作成
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-large-001',
        groupId: 'group-001',
        strokes: strokes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ストロークIdのSet作成（重複チェックシミュレーション）
      final strokeIds = whiteboard.strokes.map((s) => s.strokeId).toSet();

      stopwatch.stop();

      // Assert
      expect(whiteboard.strokes.length, strokeCount);
      expect(strokeIds.length, strokeCount); // 重複なし
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100ms以内
    });

    test('ホワイトボード履歴管理（最大50履歴）', () {
      // Arrange
      final history = <List<DrawingStroke>>[];
      const maxHistory = 50;
      var currentStrokes = <DrawingStroke>[];

      // Act - 60回描画（上限を超える）
      for (var i = 0; i < 60; i++) {
        final newStroke = DrawingStroke(
          strokeId: 'stroke-$i',
          points: [DrawingPoint(x: i * 10.0, y: i * 10.0)],
          colorValue: Colors.black.value,
          createdAt: DateTime.now(),
          authorId: 'user-123',
          authorName: 'User A',
        );
        currentStrokes = [...currentStrokes, newStroke];

        // 履歴追加（上限管理）
        history.add(List.from(currentStrokes));
        if (history.length > maxHistory) {
          history.removeAt(0); // 古い履歴を削除
        }
      }

      // Assert
      expect(history.length, maxHistory); // 上限50
      expect(history.last.length, 60); // 最新の状態には60ストローク
    });

    test('ホワイトボードスナップショット保存（createdAt基準）', () {
      // Arrange
      final now = DateTime.now();
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-001',
        groupId: 'group-001',
        strokes: [
          DrawingStroke(
            strokeId: 'stroke-001',
            points: const [DrawingPoint(x: 0, y: 0)],
            colorValue: Colors.red.value,
            createdAt: now.subtract(const Duration(days: 1)),
            authorId: 'user-123',
            authorName: 'User A',
          ),
          DrawingStroke(
            strokeId: 'stroke-002',
            points: const [DrawingPoint(x: 100, y: 100)],
            colorValue: Colors.blue.value,
            createdAt: now,
            authorId: 'user-456',
            authorName: 'User B',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
      );

      // Act - 1日前のスナップショットを再現
      final snapshotDate = now.subtract(const Duration(hours: 12));
      final snapshotStrokes = whiteboard.strokes
          .where((s) => s.createdAt.isBefore(snapshotDate))
          .toList();

      // Assert
      expect(snapshotStrokes.length, 1); // stroke-001のみ
      expect(snapshotStrokes.first.strokeId, 'stroke-001');
    });
  });

  group('Whiteboard 競合解決 Tests', () {
    test('同時編集競合（ストロークID基準マージ）', () {
      // Arrange - 2つのデバイスで同時編集
      final device1Strokes = [
        DrawingStroke(
          strokeId: 'device1-stroke-001',
          points: const [DrawingPoint(x: 0, y: 0)],
          colorValue: Colors.red.value,
          createdAt: DateTime.now(),
          authorId: 'user-123',
          authorName: 'User A',
        ),
      ];

      final device2Strokes = [
        DrawingStroke(
          strokeId: 'device2-stroke-001',
          points: const [DrawingPoint(x: 100, y: 100)],
          colorValue: Colors.blue.value,
          createdAt: DateTime.now(),
          authorId: 'user-456',
          authorName: 'User B',
        ),
      ];

      // Act - 両デバイスのストロークをマージ
      final mergedStrokes = [...device1Strokes, ...device2Strokes];
      final strokeIds = mergedStrokes.map((s) => s.strokeId).toSet();

      // Assert
      expect(mergedStrokes.length, 2);
      expect(strokeIds.length, 2); // 異なるstrokeId → 競合なし
    });

    test('LWW（Last-Write-Wins）ベース競合解決', () {
      // Arrange - 同じstrokeIdで異なるデータ
      final now = DateTime.now();
      final stroke1 = DrawingStroke(
        strokeId: 'stroke-001',
        points: const [DrawingPoint(x: 0, y: 0)],
        colorValue: Colors.red.value,
        createdAt: now.subtract(const Duration(seconds: 1)),
        authorId: 'user-123',
        authorName: 'User A',
      );

      final stroke2 = DrawingStroke(
        strokeId: 'stroke-001', // 同じID
        points: const [DrawingPoint(x: 100, y: 100)],
        colorValue: Colors.blue.value,
        createdAt: now, // より新しい
        authorId: 'user-456',
        authorName: 'User B',
      );

      // Act - LWW: 新しい方を採用
      final winner =
          stroke1.createdAt.isAfter(stroke2.createdAt) ? stroke1 : stroke2;

      // Assert
      expect(winner.strokeId, 'stroke-001');
      expect(winner.colorValue, Colors.blue.value); // stroke2が勝つ
      expect(winner.authorId, 'user-456');
    });
  });
}
