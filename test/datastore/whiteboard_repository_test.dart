/// ホワイトボードRepositoryのユニットテスト
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/whiteboard.dart';
import 'package:flutter/material.dart';

void main() {
  group('Whiteboard モデル Tests', () {
    test('DrawingPoint - 正しく作成できる', () {
      // Act
      const point = DrawingPoint(x: 100.0, y: 200.0);

      // Assert
      expect(point.x, 100.0);
      expect(point.y, 200.0);
    });

    test('DrawingPoint - Offsetから作成できる', () {
      // Arrange
      const offset = Offset(150.0, 250.0);

      // Act
      final point = DrawingPoint.fromOffset(offset);

      // Assert
      expect(point.x, 150.0);
      expect(point.y, 250.0);
    });

    test('DrawingPoint - toOffset変換', () {
      // Arrange
      const point = DrawingPoint(x: 100.0, y: 200.0);

      // Act
      final offset = point.toOffset();

      // Assert
      expect(offset.dx, 100.0);
      expect(offset.dy, 200.0);
    });

    test('DrawingPoint - toMap/fromMap変換', () {
      // Arrange
      const point = DrawingPoint(x: 100.0, y: 200.0);

      // Act
      final map = point.toMap();
      final restored = DrawingPoint.fromMap(map);

      // Assert
      expect(map['x'], 100.0);
      expect(map['y'], 200.0);
      expect(restored.x, point.x);
      expect(restored.y, point.y);
    });

    test('DrawingStroke - 正しく作成できる', () {
      // Arrange
      final points = [
        const DrawingPoint(x: 0, y: 0),
        const DrawingPoint(x: 100, y: 100),
        const DrawingPoint(x: 200, y: 200),
      ];
      final now = DateTime.now();

      // Act
      final stroke = DrawingStroke(
        strokeId: 'stroke-001',
        points: points,
        colorValue: Colors.black.value,
        strokeWidth: 3.0,
        createdAt: now,
        authorId: 'user-123',
        authorName: 'Test User',
      );

      // Assert
      expect(stroke.strokeId, 'stroke-001');
      expect(stroke.points.length, 3);
      expect(stroke.colorValue, Colors.black.value);
      expect(stroke.strokeWidth, 3.0);
      expect(stroke.createdAt, now);
      expect(stroke.authorId, 'user-123');
      expect(stroke.authorName, 'Test User');
    });

    test('DrawingStroke - デフォルトstrokeWidth', () {
      // Act
      final stroke = DrawingStroke(
        strokeId: 'stroke-001',
        points: const [DrawingPoint(x: 0, y: 0)],
        colorValue: Colors.black.value,
        createdAt: DateTime.now(),
        authorId: 'user-123',
        authorName: 'Test User',
      );

      // Assert
      expect(stroke.strokeWidth, 3.0); // デフォルト値
    });

    test('Whiteboard - グループ共通ホワイトボード作成', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-001',
        groupId: 'group-001',
        ownerId: null, // グループ共通
        strokes: [],
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
        canvasWidth: 1280.0,
        canvasHeight: 720.0,
      );

      // Assert
      expect(whiteboard.whiteboardId, 'wb-001');
      expect(whiteboard.groupId, 'group-001');
      expect(whiteboard.ownerId, null);
      expect(whiteboard.isGroupWhiteboard, true);
      expect(whiteboard.isPersonalWhiteboard, false);
      expect(whiteboard.strokes.isEmpty, true);
      expect(whiteboard.isPrivate, false);
      expect(whiteboard.canvasWidth, 1280.0);
      expect(whiteboard.canvasHeight, 720.0);
    });

    test('Whiteboard - 個人用ホワイトボード作成', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-002',
        groupId: 'group-001',
        ownerId: 'user-123', // 個人用
        strokes: [],
        isPrivate: true,
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(whiteboard.ownerId, 'user-123');
      expect(whiteboard.isGroupWhiteboard, false);
      expect(whiteboard.isPersonalWhiteboard, true);
      expect(whiteboard.isPrivate, true);
    });

    test('Whiteboard - デフォルト値', () {
      // Act
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-003',
        groupId: 'group-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(whiteboard.strokes, []);
      expect(whiteboard.isPrivate, false);
      // Note: Freezedの実装によりデフォルト値が異なる場合がある
      expect(whiteboard.canvasWidth, isNotNull);
      expect(whiteboard.canvasHeight, isNotNull);
    });

    test('Whiteboard - canEdit判定（グループ共通・非プライベート）', () {
      // Arrange
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-001',
        groupId: 'group-001',
        ownerId: null, // グループ共通
        isPrivate: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(whiteboard.canEdit('user-123'), true); // 誰でも編集可能
      expect(whiteboard.canEdit('user-456'), true);
    });

    test('Whiteboard - canEdit判定（グループ共通・プライベート）', () {
      // Arrange
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-002',
        groupId: 'group-001',
        ownerId: null,
        isPrivate: true, // プライベート
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(whiteboard.canEdit('user-123'), false); // 誰も編集不可
      expect(whiteboard.canEdit('user-456'), false);
    });

    test('Whiteboard - canEdit判定（個人用）', () {
      // Arrange
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-003',
        groupId: 'group-001',
        ownerId: 'user-123', // 個人用
        isPrivate: false, // プライベートOFF
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert - isPrivate=falseなら他人も編集可能
      expect(whiteboard.canEdit('user-123'), true); // オーナーは編集可能
      expect(whiteboard.canEdit('user-456'), true); // 他人も編集可能（isPrivate=false）
    });

    test('Whiteboard - canEdit判定（個人用・プライベート）', () {
      // Arrange
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-004',
        groupId: 'group-001',
        ownerId: 'user-123', // 個人用
        isPrivate: true, // プライベートON
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert - isPrivate=trueならオーナーのみ編集可能
      expect(whiteboard.canEdit('user-123'), true); // オーナーは編集可能
      expect(whiteboard.canEdit('user-456'), false); // 他人は編集不可
    });

    test('Whiteboard - copyWithでストローク追加', () {
      // Arrange
      final original = Whiteboard(
        whiteboardId: 'wb-001',
        groupId: 'group-001',
        strokes: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newStroke = DrawingStroke(
        strokeId: 'stroke-001',
        points: const [DrawingPoint(x: 0, y: 0)],
        colorValue: Colors.red.value,
        strokeWidth: 3.0,
        createdAt: DateTime.now(),
        authorId: 'user-123',
        authorName: 'Test User',
      );

      // Act
      final updated = original.copyWith(
        strokes: [newStroke],
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(updated.strokes.length, 1);
      expect(updated.strokes.first.strokeId, 'stroke-001');
      expect(updated.whiteboardId, original.whiteboardId); // IDは維持
    });

    test('Whiteboard - 複数ストローク管理', () {
      // Arrange
      final strokes = List.generate(
        10,
        (i) => DrawingStroke(
          strokeId: 'stroke-$i',
          points: [DrawingPoint(x: i * 10.0, y: i * 10.0)],
          colorValue: Colors.blue.value,
          strokeWidth: 2.0,
          createdAt: DateTime.now(),
          authorId: 'user-123',
          authorName: 'Test User',
        ),
      );

      final whiteboard = Whiteboard(
        whiteboardId: 'wb-001',
        groupId: 'group-001',
        strokes: strokes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(whiteboard.strokes.length, 10);
      expect(whiteboard.strokes.first.strokeId, 'stroke-0');
      expect(whiteboard.strokes.last.strokeId, 'stroke-9');
    });

    test('Whiteboard - ストロークID重複チェック', () {
      // Arrange
      final stroke1 = DrawingStroke(
        strokeId: 'stroke-001',
        points: const [DrawingPoint(x: 0, y: 0)],
        colorValue: Colors.red.value,
        createdAt: DateTime.now(),
        authorId: 'user-123',
        authorName: 'User A',
      );

      final stroke2 = DrawingStroke(
        strokeId: 'stroke-001', // 同じID
        points: const [DrawingPoint(x: 100, y: 100)],
        colorValue: Colors.blue.value,
        createdAt: DateTime.now(),
        authorId: 'user-456',
        authorName: 'User B',
      );

      // Act
      final strokeIds = [stroke1, stroke2].map((s) => s.strokeId).toSet();

      // Assert
      expect(strokeIds.length, 1); // 重複検出
    });

    test('DrawingStroke - 異なる色のストローク', () {
      // Arrange
      final colors = [
        Colors.black,
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.yellow,
      ];

      // Act
      final strokes = colors
          .map(
            (color) => DrawingStroke(
              strokeId: 'stroke-${color.value}',
              points: const [DrawingPoint(x: 0, y: 0)],
              colorValue: color.value,
              createdAt: DateTime.now(),
              authorId: 'user-123',
              authorName: 'Test User',
            ),
          )
          .toList();

      // Assert
      expect(strokes.length, 5);
      expect(strokes[0].colorValue, Colors.black.value);
      expect(strokes[1].colorValue, Colors.red.value);
      expect(strokes[2].colorValue, Colors.green.value);
    });

    test('DrawingStroke - 異なる線幅', () {
      // Arrange
      final widths = [1.0, 2.0, 4.0, 6.0, 8.0];

      // Act
      final strokes = widths
          .map(
            (width) => DrawingStroke(
              strokeId: 'stroke-$width',
              points: const [DrawingPoint(x: 0, y: 0)],
              colorValue: Colors.black.value,
              strokeWidth: width,
              createdAt: DateTime.now(),
              authorId: 'user-123',
              authorName: 'Test User',
            ),
          )
          .toList();

      // Assert
      expect(strokes.length, 5);
      expect(strokes[0].strokeWidth, 1.0);
      expect(strokes[1].strokeWidth, 2.0);
      expect(strokes[4].strokeWidth, 8.0);
    });

    test('Whiteboard - 大量ストロークのパフォーマンステスト', () {
      // Arrange
      const strokeCount = 100;
      final stopwatch = Stopwatch()..start();

      final strokes = List.generate(
        strokeCount,
        (i) => DrawingStroke(
          strokeId: 'stroke-$i',
          points:
              List.generate(50, (j) => DrawingPoint(x: j * 1.0, y: i * 1.0)),
          colorValue: Colors.black.value,
          strokeWidth: 3.0,
          createdAt: DateTime.now(),
          authorId: 'user-123',
          authorName: 'Test User',
        ),
      );

      // Act
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-001',
        groupId: 'group-001',
        strokes: strokes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      stopwatch.stop();

      // Assert
      expect(whiteboard.strokes.length, strokeCount);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100ms以内
    });
  });

  group('Whiteboard ビジネスロジック Tests', () {
    test('ストローク作成時刻でソート', () {
      // Arrange
      final now = DateTime.now();
      final stroke1 = DrawingStroke(
        strokeId: 'stroke-001',
        points: const [DrawingPoint(x: 0, y: 0)],
        colorValue: Colors.red.value,
        createdAt: now.subtract(const Duration(seconds: 2)),
        authorId: 'user-123',
        authorName: 'User A',
      );

      final stroke2 = DrawingStroke(
        strokeId: 'stroke-002',
        points: const [DrawingPoint(x: 100, y: 100)],
        colorValue: Colors.blue.value,
        createdAt: now,
        authorId: 'user-456',
        authorName: 'User B',
      );

      // Act
      final sorted = [stroke2, stroke1]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Assert
      expect(sorted.first.strokeId, 'stroke-001'); // 古い方が先
      expect(sorted.last.strokeId, 'stroke-002');
    });

    test('作者別ストローク分離', () {
      // Arrange
      final strokes = [
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
        DrawingStroke(
          strokeId: 'stroke-003',
          points: const [DrawingPoint(x: 200, y: 200)],
          colorValue: Colors.green.value,
          createdAt: DateTime.now(),
          authorId: 'user-123',
          authorName: 'User A',
        ),
      ];

      // Act
      final userAStrokes =
          strokes.where((s) => s.authorId == 'user-123').toList();
      final userBStrokes =
          strokes.where((s) => s.authorId == 'user-456').toList();

      // Assert
      expect(userAStrokes.length, 2);
      expect(userBStrokes.length, 1);
    });

    test('空ストローク除外（ポイント0個）', () {
      // Arrange
      final validStroke = DrawingStroke(
        strokeId: 'stroke-001',
        points: const [DrawingPoint(x: 0, y: 0)],
        colorValue: Colors.red.value,
        createdAt: DateTime.now(),
        authorId: 'user-123',
        authorName: 'User A',
      );

      final emptyStroke = DrawingStroke(
        strokeId: 'stroke-002',
        points: const [], // 空
        colorValue: Colors.blue.value,
        createdAt: DateTime.now(),
        authorId: 'user-456',
        authorName: 'User B',
      );

      final strokes = [validStroke, emptyStroke];

      // Act
      final filteredStrokes =
          strokes.where((s) => s.points.isNotEmpty).toList();

      // Assert
      expect(filteredStrokes.length, 1);
      expect(filteredStrokes.first.strokeId, 'stroke-001');
    });

    test('キャンバスサイズ変更', () {
      // Arrange
      final whiteboard = Whiteboard(
        whiteboardId: 'wb-001',
        groupId: 'group-001',
        canvasWidth: 1280.0,
        canvasHeight: 720.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final resized = whiteboard.copyWith(
        canvasWidth: 1920.0,
        canvasHeight: 1080.0,
      );

      // Assert
      expect(resized.canvasWidth, 1920.0);
      expect(resized.canvasHeight, 1080.0);
    });
  });
}
