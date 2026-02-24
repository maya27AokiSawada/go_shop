import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/utils/drawing_converter.dart';
import 'package:goshopping/models/whiteboard.dart';

void main() {
  group('DrawingConverter - strokesToPoints()', () {
    test('空のストロークリストは空のPointリストを返す', () {
      // Arrange
      final strokes = <DrawingStroke>[];

      // Act
      final points = DrawingConverter.strokesToPoints(strokes);

      // Assert
      expect(points, isEmpty);
    });

    test('単一ストロークを正しくPointリストに変換', () {
      // Arrange
      final stroke = DrawingStroke(
        strokeId: 'test-stroke-1',
        points: [
          const DrawingPoint(x: 10.0, y: 20.0),
          const DrawingPoint(x: 30.0, y: 40.0),
          const DrawingPoint(x: 50.0, y: 60.0),
        ],
        colorValue: Colors.black.value,
        strokeWidth: 3.0,
        createdAt: DateTime.now(),
        authorId: 'test-user-1',
        authorName: 'Test User',
      );

      // Act
      final points = DrawingConverter.strokesToPoints([stroke]);

      // Assert
      expect(points.length, 3);
      expect(points[0].offset.dx, 10.0);
      expect(points[0].offset.dy, 20.0);
      expect(points[1].offset.dx, 30.0);
      expect(points[1].offset.dy, 40.0);
      expect(points[2].offset.dx, 50.0);
      expect(points[2].offset.dy, 60.0);
    });

    test('複数ストロークを正しくPointリストに変換（順序維持）', () {
      // Arrange
      final stroke1 = DrawingStroke(
        strokeId: 'test-stroke-1',
        points: [
          const DrawingPoint(x: 10.0, y: 20.0),
          const DrawingPoint(x: 30.0, y: 40.0),
        ],
        colorValue: Colors.black.value,
        strokeWidth: 3.0,
        createdAt: DateTime.now(),
        authorId: 'test-user-1',
        authorName: 'Test User',
      );

      final stroke2 = DrawingStroke(
        strokeId: 'test-stroke-2',
        points: [
          const DrawingPoint(x: 50.0, y: 60.0),
          const DrawingPoint(x: 70.0, y: 80.0),
        ],
        colorValue: Colors.red.value,
        strokeWidth: 5.0,
        createdAt: DateTime.now(),
        authorId: 'test-user-1',
        authorName: 'Test User',
      );

      // Act
      final points = DrawingConverter.strokesToPoints([stroke1, stroke2]);

      // Assert
      expect(points.length, 4);
      // stroke1のポイント
      expect(points[0].offset.dx, 10.0);
      expect(points[0].offset.dy, 20.0);
      expect(points[1].offset.dx, 30.0);
      expect(points[1].offset.dy, 40.0);
      // stroke2のポイント
      expect(points[2].offset.dx, 50.0);
      expect(points[2].offset.dy, 60.0);
      expect(points[3].offset.dx, 70.0);
      expect(points[3].offset.dy, 80.0);
    });

    test('空のポイントを持つストロークは無視される', () {
      // Arrange
      final stroke1 = DrawingStroke(
        strokeId: 'test-stroke-1',
        points: [
          const DrawingPoint(x: 10.0, y: 20.0),
        ],
        colorValue: Colors.black.value,
        strokeWidth: 3.0,
        createdAt: DateTime.now(),
        authorId: 'test-user-1',
        authorName: 'Test User',
      );

      final stroke2 = DrawingStroke(
        strokeId: 'test-stroke-2',
        points: [], // 空のポイント
        colorValue: Colors.red.value,
        strokeWidth: 5.0,
        createdAt: DateTime.now(),
        authorId: 'test-user-1',
        authorName: 'Test User',
      );

      final stroke3 = DrawingStroke(
        strokeId: 'test-stroke-3',
        points: [
          const DrawingPoint(x: 30.0, y: 40.0),
        ],
        colorValue: Colors.blue.value,
        strokeWidth: 4.0,
        createdAt: DateTime.now(),
        authorId: 'test-user-1',
        authorName: 'Test User',
      );

      // Act
      final points =
          DrawingConverter.strokesToPoints([stroke1, stroke2, stroke3]);

      // Assert
      expect(points.length, 2); // stroke2は空なので無視
      expect(points[0].offset.dx, 10.0);
      expect(points[1].offset.dx, 30.0);
    });
  });

  group('DrawingConverter - 座標変換正確性', () {
    test('DrawingPointのtoOffset()拡張メソッドは正確な座標を返す', () {
      // Arrange
      const point = DrawingPoint(x: 123.45, y: 678.90);

      // Act
      final offset = point.toOffset();

      // Assert
      expect(offset.dx, 123.45);
      expect(offset.dy, 678.90);
    });

    test('DrawingPointのtoMap()拡張メソッドは正確なMapを返す', () {
      // Arrange
      const point = DrawingPoint(x: 123.45, y: 678.90);

      // Act
      final map = point.toMap();

      // Assert
      expect(map['x'], 123.45);
      expect(map['y'], 678.90);
    });

    test('DrawingPoint.fromOffset()は正確なDrawingPointを生成', () {
      // Arrange
      const offset = Offset(123.45, 678.90);

      // Act
      final point = DrawingPoint.fromOffset(offset);

      // Assert
      expect(point.x, 123.45);
      expect(point.y, 678.90);
    });

    test('DrawingPoint.fromMap()は正確なDrawingPointを生成', () {
      // Arrange
      final map = {'x': 123.45, 'y': 678.90};

      // Act
      final point = DrawingPoint.fromMap(map);

      // Assert
      expect(point.x, 123.45);
      expect(point.y, 678.90);
    });
  });

  group('DrawingConverter - 浮動小数点精度', () {
    test('極小値の座標も正確に変換される', () {
      // Arrange
      const point = DrawingPoint(x: 0.001, y: 0.002);

      // Act
      final offset = point.toOffset();

      // Assert
      expect(offset.dx, closeTo(0.001, 0.0001));
      expect(offset.dy, closeTo(0.002, 0.0001));
    });

    test('極大値の座標も正確に変換される', () {
      // Arrange
      const point = DrawingPoint(x: 9999.999, y: 8888.888);

      // Act
      final offset = point.toOffset();

      // Assert
      expect(offset.dx, closeTo(9999.999, 0.001));
      expect(offset.dy, closeTo(8888.888, 0.001));
    });

    test('負の座標も正確に変換される', () {
      // Arrange
      const point = DrawingPoint(x: -123.45, y: -678.90);

      // Act
      final offset = point.toOffset();

      // Assert
      expect(offset.dx, -123.45);
      expect(offset.dy, -678.90);
    });
  });

  group('DrawingConverter - DrawingStroke構造検証', () {
    test('DrawingStrokeは必須フィールドをすべて保持する', () {
      // Arrange
      final createdAt = DateTime.now();
      final stroke = DrawingStroke(
        strokeId: 'test-stroke-id',
        points: [
          const DrawingPoint(x: 10.0, y: 20.0),
          const DrawingPoint(x: 30.0, y: 40.0),
        ],
        colorValue: Colors.blue.value,
        strokeWidth: 5.5,
        createdAt: createdAt,
        authorId: 'user-123',
        authorName: 'Test Author',
      );

      // Assert
      expect(stroke.strokeId, 'test-stroke-id');
      expect(stroke.points.length, 2);
      expect(stroke.colorValue, Colors.blue.value);
      expect(stroke.strokeWidth, 5.5);
      expect(stroke.createdAt, createdAt);
      expect(stroke.authorId, 'user-123');
      expect(stroke.authorName, 'Test Author');
    });

    test('DrawingStrokeのデフォルト値（strokeWidth）は3.0', () {
      // Arrange & Act
      final stroke = DrawingStroke(
        strokeId: 'test-stroke-id',
        points: const [DrawingPoint(x: 10.0, y: 20.0)],
        colorValue: Colors.black.value,
        // strokeWidthは省略（デフォルト値使用）
        createdAt: DateTime.now(),
        authorId: 'user-123',
        authorName: 'Test Author',
      );

      // Assert
      expect(stroke.strokeWidth, 3.0);
    });
  });

  group('DrawingConverter - 複数ストローク順序テスト', () {
    test('10本のストロークが正しい順序で変換される', () {
      // Arrange
      final strokes = List.generate(
        10,
        (index) => DrawingStroke(
          strokeId: 'stroke-$index',
          points: [
            DrawingPoint(x: index * 10.0, y: index * 20.0),
            DrawingPoint(x: index * 10.0 + 5, y: index * 20.0 + 10),
          ],
          colorValue: Colors.black.value,
          strokeWidth: 3.0,
          createdAt: DateTime.now(),
          authorId: 'test-user',
          authorName: 'Test User',
        ),
      );

      // Act
      final points = DrawingConverter.strokesToPoints(strokes);

      // Assert
      expect(points.length, 20); // 10ストローク × 2ポイント

      // 最初のストロークの検証
      expect(points[0].offset.dx, 0.0);
      expect(points[0].offset.dy, 0.0);
      expect(points[1].offset.dx, 5.0);
      expect(points[1].offset.dy, 10.0);

      // 最後のストロークの検証
      expect(points[18].offset.dx, 90.0);
      expect(points[18].offset.dy, 180.0);
      expect(points[19].offset.dx, 95.0);
      expect(points[19].offset.dy, 190.0);
    });
  });

  group('DrawingConverter - エッジケース', () {
    test('単一ポイントのストロークも正しく変換される', () {
      // Arrange
      final stroke = DrawingStroke(
        strokeId: 'single-point-stroke',
        points: const [DrawingPoint(x: 100.0, y: 200.0)],
        colorValue: Colors.green.value,
        strokeWidth: 3.0,
        createdAt: DateTime.now(),
        authorId: 'test-user',
        authorName: 'Test User',
      );

      // Act
      final points = DrawingConverter.strokesToPoints([stroke]);

      // Assert
      expect(points.length, 1);
      expect(points[0].offset.dx, 100.0);
      expect(points[0].offset.dy, 200.0);
    });

    test('大量のポイントを持つストロークも正しく変換される', () {
      // Arrange
      final stroke = DrawingStroke(
        strokeId: 'many-points-stroke',
        points: List.generate(
          1000,
          (index) => DrawingPoint(x: index * 1.0, y: index * 2.0),
        ),
        colorValue: Colors.purple.value,
        strokeWidth: 3.0,
        createdAt: DateTime.now(),
        authorId: 'test-user',
        authorName: 'Test User',
      );

      // Act
      final points = DrawingConverter.strokesToPoints([stroke]);

      // Assert
      expect(points.length, 1000);
      expect(points[0].offset.dx, 0.0);
      expect(points[0].offset.dy, 0.0);
      expect(points[999].offset.dx, 999.0);
      expect(points[999].offset.dy, 1998.0);
    });
  });

  group('DrawingConverter - Color値検証', () {
    test('異なる色のストロークが正しく保持される', () {
      // Arrange
      final colors = [
        Colors.black,
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
        Colors.pink,
      ];

      final strokes = colors.map((color) {
        return DrawingStroke(
          strokeId: 'stroke-${color.value}',
          points: const [DrawingPoint(x: 10.0, y: 20.0)],
          colorValue: color.value,
          strokeWidth: 3.0,
          createdAt: DateTime.now(),
          authorId: 'test-user',
          authorName: 'Test User',
        );
      }).toList();

      // Act & Assert
      for (int i = 0; i < strokes.length; i++) {
        expect(strokes[i].colorValue, colors[i].value);
      }
    });
  });

  group('DrawingConverter - 作者情報検証', () {
    test('異なる作者のストロークが正しく区別される', () {
      // Arrange
      final stroke1 = DrawingStroke(
        strokeId: 'stroke-1',
        points: const [DrawingPoint(x: 10.0, y: 20.0)],
        colorValue: Colors.black.value,
        strokeWidth: 3.0,
        createdAt: DateTime.now(),
        authorId: 'user-alice',
        authorName: 'Alice',
      );

      final stroke2 = DrawingStroke(
        strokeId: 'stroke-2',
        points: const [DrawingPoint(x: 30.0, y: 40.0)],
        colorValue: Colors.red.value,
        strokeWidth: 5.0,
        createdAt: DateTime.now(),
        authorId: 'user-bob',
        authorName: 'Bob',
      );

      // Assert
      expect(stroke1.authorId, 'user-alice');
      expect(stroke1.authorName, 'Alice');
      expect(stroke2.authorId, 'user-bob');
      expect(stroke2.authorName, 'Bob');
      expect(stroke1.authorId, isNot(stroke2.authorId));
      expect(stroke1.authorName, isNot(stroke2.authorName));
    });
  });

  group('DrawingConverter - タイムスタンプ検証', () {
    test('DrawingStrokeのcreatedAtは正確に保持される', () {
      // Arrange
      final createdAt = DateTime(2026, 2, 24, 15, 30, 45);
      final stroke = DrawingStroke(
        strokeId: 'timestamp-stroke',
        points: const [DrawingPoint(x: 10.0, y: 20.0)],
        colorValue: Colors.black.value,
        strokeWidth: 3.0,
        createdAt: createdAt,
        authorId: 'test-user',
        authorName: 'Test User',
      );

      // Assert
      expect(stroke.createdAt, createdAt);
      expect(stroke.createdAt.year, 2026);
      expect(stroke.createdAt.month, 2);
      expect(stroke.createdAt.day, 24);
      expect(stroke.createdAt.hour, 15);
      expect(stroke.createdAt.minute, 30);
      expect(stroke.createdAt.second, 45);
    });

    test('複数ストロークのタイムスタンプ順序が保持される', () {
      // Arrange
      final time1 = DateTime(2026, 2, 24, 10, 0, 0);
      final time2 = DateTime(2026, 2, 24, 10, 0, 1);
      final time3 = DateTime(2026, 2, 24, 10, 0, 2);

      final stroke1 = DrawingStroke(
        strokeId: 'stroke-1',
        points: const [DrawingPoint(x: 10.0, y: 20.0)],
        colorValue: Colors.black.value,
        strokeWidth: 3.0,
        createdAt: time1,
        authorId: 'test-user',
        authorName: 'Test User',
      );

      final stroke2 = DrawingStroke(
        strokeId: 'stroke-2',
        points: const [DrawingPoint(x: 30.0, y: 40.0)],
        colorValue: Colors.red.value,
        strokeWidth: 3.0,
        createdAt: time2,
        authorId: 'test-user',
        authorName: 'Test User',
      );

      final stroke3 = DrawingStroke(
        strokeId: 'stroke-3',
        points: const [DrawingPoint(x: 50.0, y: 60.0)],
        colorValue: Colors.blue.value,
        strokeWidth: 3.0,
        createdAt: time3,
        authorId: 'test-user',
        authorName: 'Test User',
      );

      // Assert
      expect(stroke1.createdAt.isBefore(stroke2.createdAt), isTrue);
      expect(stroke2.createdAt.isBefore(stroke3.createdAt), isTrue);
      expect(stroke1.createdAt.isBefore(stroke3.createdAt), isTrue);
    });
  });
}
