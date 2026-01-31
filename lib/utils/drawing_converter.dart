import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import '../models/whiteboard.dart';

const _uuid = Uuid();

/// signature パッケージと カスタムモデル の変換ユーティリティ
class DrawingConverter {
  /// SignatureController から DrawingStroke リストを生成
  /// ペンを離した箇所で自動的に分割
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

      // 点間の距離が大きい場合は別のストロークとして分割
      const double breakThreshold = 30.0; // 30ピクセル以上離れていたら別ストローク

      final List<DrawingStroke> strokes = [];
      List<DrawingPoint> currentStrokePoints = [];

      for (int i = 0; i < points.length; i++) {
        final point = points[i];

        if (currentStrokePoints.isNotEmpty) {
          // 前の点との距離を計算
          final prevPoint = points[i - 1];
          final distance = (point.offset - prevPoint.offset).distance;

          // 距離が大きい場合は別のストロークとして保存
          if (distance > breakThreshold) {
            // 現在のストロークを保存
            if (currentStrokePoints.isNotEmpty) {
              strokes.add(DrawingStroke(
                strokeId: _uuid.v4(),
                points: currentStrokePoints,
                colorValue: strokeColor.value,
                strokeWidth: strokeWidth, // 元のストローク幅（スケーリング前）
                createdAt: DateTime.now(),
                authorId: authorId,
                authorName: authorName,
              ));
            }
            // 新しいストローク開始
            currentStrokePoints = [];
          }
        }

        // 座標をスケーリング前の座標系に変換
        currentStrokePoints.add(DrawingPoint(
          x: point.offset.dx / scale,
          y: point.offset.dy / scale,
        ));
      }

      // 最後のストロークを追加
      if (currentStrokePoints.isNotEmpty) {
        strokes.add(DrawingStroke(
          strokeId: _uuid.v4(),
          points: currentStrokePoints,
          colorValue: strokeColor.value,
          strokeWidth: strokeWidth, // 元のストローク幅（スケーリング前）
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
