import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import '../models/whiteboard.dart';

const _uuid = Uuid();

/// signature パッケージと カスタムモデル の変換ユーティリティ
class DrawingConverter {
  /// SignatureController から DrawingStroke リストを生成
  static List<DrawingStroke> captureFromSignatureController({
    required SignatureController controller,
    required String authorId,
    required String authorName,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    final points = controller.points;
    if (points.isEmpty) return [];

    // signature パッケージは List<Point> 形式
    // 連続した点を1つのストロークとして扱う
    final drawingPoints = points
        .map((p) => DrawingPoint(
              x: p.offset.dx,
              y: p.offset.dy,
            ))
        .toList();

    return [
      DrawingStroke(
        strokeId: _uuid.v4(),
        points: drawingPoints,
        colorValue: strokeColor.value,
        strokeWidth: strokeWidth,
        createdAt: DateTime.now(),
        authorId: authorId,
        authorName: authorName,
      ),
    ];
  }

  /// DrawingStroke リストを SignatureController に復元
  static void restoreToSignatureController({
    required SignatureController controller,
    required List<DrawingStroke> strokes,
  }) {
    // signature パッケージでは、すべてのストロークを1つのポイントリストに結合
    final allPoints = <Point>[];

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        allPoints.add(Point(
          Offset(point.x, point.y),
          PointType.tap, // 連続した線として描画
        ));
      }
    }

    // SignatureControllerを再作成してポイントを設定
    // 注: 既存のコントローラーには直接追加できないため、呼び出し元で対応が必要
  }

  /// DrawingStroke リストから List<Point> を生成（SignatureController用）
  static List<Point> strokesToPoints(List<DrawingStroke> strokes) {
    final allPoints = <Point>[];

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        allPoints.add(Point(
          Offset(point.x, point.y),
          PointType.tap,
        ));
      }
    }

    return allPoints;
  }
}
