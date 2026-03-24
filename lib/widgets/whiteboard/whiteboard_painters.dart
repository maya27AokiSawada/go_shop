import 'package:flutter/material.dart';
import '../../models/whiteboard.dart';

/// 保存済みストロークを描画するCustomPainter
class DrawingStrokePainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  DrawingStrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // ストロークの各点を線で結ぶ
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(
          Offset(p1.x, p1.y),
          Offset(p2.x, p2.y),
          paint,
        );
      }

      // 単一点の場合は点を描画
      if (stroke.points.length == 1) {
        final p = stroke.points[0];
        canvas.drawCircle(
          Offset(p.x, p.y),
          stroke.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingStrokePainter oldDelegate) {
    return strokes != oldDelegate.strokes;
  }
}

/// グリッド線を描画するCustomPainter
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color color;

  GridPainter({
    required this.gridSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 縦線
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 横線
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return gridSize != oldDelegate.gridSize || color != oldDelegate.color;
  }
}
