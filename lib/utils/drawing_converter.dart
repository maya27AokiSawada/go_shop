import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:uuid/uuid.dart';
import '../models/whiteboard.dart';

const _uuid = Uuid();

/// flutter_drawing_board の JSON と カスタムモデル の変換ユーティリティ
class DrawingConverter {
  /// flutter_drawing_board の DrawConfig JSON から DrawingStroke に変換
  static DrawingStroke jsonToStroke({
    required Map<String, dynamic> json,
    required String authorId,
    required String authorName,
  }) {
    final type = json['type'] as String?;
    final paint = json['paint'] as Map<String, dynamic>?;
    final points = json['data'] as List<dynamic>?;

    // 色情報取得（デフォルト: 黒）
    int colorValue = Colors.black.value;
    if (paint != null && paint.containsKey('color')) {
      colorValue = paint['color'] as int;
    }

    // 線幅取得（デフォルト: 3.0）
    double strokeWidth = 3.0;
    if (paint != null && paint.containsKey('strokeWidth')) {
      strokeWidth = (paint['strokeWidth'] as num).toDouble();
    }

    // 座標データ変換
    final drawingPoints = <DrawingPoint>[];
    if (points != null) {
      for (final point in points) {
        if (point is Map<String, dynamic>) {
          final dx = (point['dx'] as num?)?.toDouble() ?? 0.0;
          final dy = (point['dy'] as num?)?.toDouble() ?? 0.0;
          drawingPoints.add(DrawingPoint(x: dx, y: dy));
        }
      }
    }

    return DrawingStroke(
      strokeId: _uuid.v4(),
      points: drawingPoints,
      colorValue: colorValue,
      strokeWidth: strokeWidth,
      createdAt: DateTime.now(),
      authorId: authorId,
      authorName: authorName,
    );
  }

  /// DrawingStroke から flutter_drawing_board の DrawConfig JSON に変換
  static Map<String, dynamic> strokeToJson(DrawingStroke stroke) {
    return {
      'type': 'StraightLine', // flutter_drawing_board のデフォルトタイプ
      'paint': {
        'blendMode': 3, // BlendMode.srcOver
        'color': stroke.colorValue,
        'filterQuality': 3, // FilterQuality.low
        'invertColors': false,
        'isAntiAlias': true,
        'strokeCap': 1, // StrokeCap.round
        'strokeJoin': 1, // StrokeJoin.round
        'strokeWidth': stroke.strokeWidth,
        'style': 1, // PaintingStyle.stroke
      },
      'data': stroke.points
          .map((p) => {
                'dx': p.x,
                'dy': p.y,
              })
          .toList(),
    };
  }

  /// 複数ストロークを一括変換 (DrawingStroke → JSON List)
  static List<Map<String, dynamic>> strokesToJsonList(
    List<DrawingStroke> strokes,
  ) {
    return strokes.map((s) => strokeToJson(s)).toList();
  }

  /// 複数ストロークを一括変換 (JSON List → DrawingStroke)
  static List<DrawingStroke> jsonListToStrokes({
    required List<Map<String, dynamic>> jsonList,
    required String authorId,
    required String authorName,
  }) {
    return jsonList
        .map((json) => jsonToStroke(
              json: json,
              authorId: authorId,
              authorName: authorName,
            ))
        .toList();
  }

  /// DrawingController から現在の描画データを DrawingStroke リストに変換
  static List<DrawingStroke> captureFromController({
    required DrawingController controller,
    required String authorId,
    required String authorName,
  }) {
    final jsonList = controller.getJsonList();
    return jsonListToStrokes(
      jsonList: jsonList,
      authorId: authorId,
      authorName: authorName,
    );
  }

  /// DrawingStroke リストを DrawingController に復元
  static void restoreToController({
    required DrawingController controller,
    required List<DrawingStroke> strokes,
  }) {
    final jsonList = strokesToJsonList(strokes);
    // flutter_drawing_board 1.0.1+1 doesn't support setJsonList
    // Manual restoration is required
    controller.clear();
    // TODO: Implement manual stroke-by-stroke restoration if needed
  }
}
