import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import '../models/whiteboard.dart';

const _uuid = Uuid();

/// signature パッケージと カスタムモデル の変換ユーティリティ
class DrawingConverter {
  /// SignatureController から DrawingStroke リストを生成
  /// SignatureパッケージのPointType境界でストロークを分割する。
  /// 距離しきい値による分割は、高速描画時に連続ストロークが点状に分断されやすいため使わない。
  static List<DrawingStroke> captureFromSignatureController({
    required SignatureController controller,
    required String authorId,
    required String authorName,
    required Color strokeColor,
    required double strokeWidth,
    double scale = 1.0, // スケーリング係数（デフォルトは等倍）
  }) {
    try {
      final points = controller.points;
      if (points.isEmpty) return [];

      final List<DrawingStroke> strokes = [];
      List<DrawingPoint> currentStrokePoints = [];

      for (final point in points) {
        final drawingPoint = DrawingPoint(
          x: point.offset.dx / scale,
          y: point.offset.dy / scale,
        );

        final hasPreviousPoint = currentStrokePoints.isNotEmpty;
        final isDuplicatePoint = hasPreviousPoint &&
            currentStrokePoints.last.x == drawingPoint.x &&
            currentStrokePoints.last.y == drawingPoint.y;

        if (!isDuplicatePoint) {
          currentStrokePoints.add(drawingPoint);
        }

        // signature は 1ストロークにつき「tap(start) -> move... -> tap(end)」を流す。
        // 先頭tapではなく、2点目以降のtapを終端として扱う。
        if (point.type == PointType.tap && currentStrokePoints.length > 1) {
          strokes.add(DrawingStroke(
            strokeId: _uuid.v4(),
            points: List.from(currentStrokePoints),
            colorValue: strokeColor.value,
            strokeWidth: strokeWidth,
            createdAt: DateTime.now(),
            authorId: authorId,
            authorName: authorName,
          ));
          currentStrokePoints = [];
        }
      }

      // 念のため終端tapを取り逃したケースも拾う
      if (currentStrokePoints.isNotEmpty) {
        strokes.add(DrawingStroke(
          strokeId: _uuid.v4(),
          points: currentStrokePoints,
          colorValue: strokeColor.value,
          strokeWidth: strokeWidth,
          createdAt: DateTime.now(),
          authorId: authorId,
          authorName: authorName,
        ));
      }

      return strokes;
    } catch (e, stackTrace) {
      // 🔥 Windows版クラッシュ対策：詳細なエラーログ
      print('❌ [DRAWING_CONVERTER] captureFromSignatureController エラー: $e');
      print('📍 [DRAWING_CONVERTER] スタックトレース: $stackTrace');
      return []; // 空リストを返して処理継続
    }
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
          PointType.tap,
          1.0, // pressure
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
          1.0, // pressure
        ));
      }
    }

    return allPoints;
  }
}
