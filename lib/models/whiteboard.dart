import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'whiteboard.freezed.dart';
part 'whiteboard.g.dart';

/// 手書きストローク（1本の線）
@HiveType(typeId: 15)
@freezed
class DrawingStroke with _$DrawingStroke {
  const factory DrawingStroke({
    @HiveField(0) required String strokeId,
    @HiveField(1) required List<DrawingPoint> points,
    @HiveField(2) required int colorValue, // Color.value
    @HiveField(3) @Default(3.0) double strokeWidth,
    @HiveField(4) required DateTime createdAt,
    @HiveField(5) required String authorId,
    @HiveField(6) required String authorName,
  }) = _DrawingStroke;

  factory DrawingStroke.fromJson(Map<String, dynamic> json) =>
      _$DrawingStrokeFromJson(json);

  factory DrawingStroke.fromFirestore(Map<String, dynamic> data) {
    return DrawingStroke(
      strokeId: data['strokeId'] as String,
      points: (data['points'] as List<dynamic>)
          .map((p) => DrawingPoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      colorValue: data['colorValue'] as int,
      strokeWidth: (data['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
    );
  }
}

/// 描画ポイント（座標）
@HiveType(typeId: 16)
@freezed
class DrawingPoint with _$DrawingPoint {
  const factory DrawingPoint({
    @HiveField(0) required double x,
    @HiveField(1) required double y,
  }) = _DrawingPoint;

  factory DrawingPoint.fromJson(Map<String, dynamic> json) =>
      _$DrawingPointFromJson(json);

  factory DrawingPoint.fromMap(Map<String, dynamic> map) {
    return DrawingPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }

  factory DrawingPoint.fromOffset(Offset offset) {
    return DrawingPoint(x: offset.dx, y: offset.dy);
  }
}

extension DrawingPointExtension on DrawingPoint {
  Offset toOffset() => Offset(x, y);
  Map<String, dynamic> toMap() => {'x': x, 'y': y};
}

/// ホワイトボード
@HiveType(typeId: 17)
@freezed
class Whiteboard with _$Whiteboard {
  const Whiteboard._();

  const factory Whiteboard({
    @HiveField(0) required String whiteboardId,
    @HiveField(1) required String groupId,
    @HiveField(2) String? ownerId, // null = グループ共通、値あり = 個人用
    @HiveField(3) @Default([]) List<DrawingStroke> strokes,
    @HiveField(4) @Default(false) bool isPrivate, // 自分以外編集不可
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) required DateTime updatedAt,
    @HiveField(7) @Default(800.0) double canvasWidth,
    @HiveField(8) @Default(600.0) double canvasHeight,
  }) = _Whiteboard;

  factory Whiteboard.fromJson(Map<String, dynamic> json) =>
      _$WhiteboardFromJson(json);

  factory Whiteboard.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return Whiteboard(
      whiteboardId: documentId,
      groupId: data['groupId'] as String,
      ownerId: data['ownerId'] as String?,
      strokes: (data['strokes'] as List<dynamic>?)
              ?.map(
                  (s) => DrawingStroke.fromFirestore(s as Map<String, dynamic>))
              .toList() ??
          [],
      isPrivate: data['isPrivate'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      canvasWidth: (data['canvasWidth'] as num?)?.toDouble() ?? 800.0,
      canvasHeight: (data['canvasHeight'] as num?)?.toDouble() ?? 600.0,
    );
  }

  /// グループ共通ホワイトボードか？
  bool get isGroupWhiteboard => ownerId == null;

  /// 個人用ホワイトボードか？
  bool get isPersonalWhiteboard => ownerId != null;

  /// ユーザーが編集可能か判定
  bool canEdit(String userId) {
    // グループ共通 & プライベートOFF → 誰でも編集可能
    if (isGroupWhiteboard && !isPrivate) return true;

    // 個人用 & オーナー本人 → 編集可能
    if (isPersonalWhiteboard && ownerId == userId) return true;

    // 個人用 & プライベートOFF & 他人 → 編集可能
    if (isPersonalWhiteboard && !isPrivate) return true;

    // 上記以外 → 編集不可
    return false;
  }

  /// Firestoreへの保存用Map
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'ownerId': ownerId,
      'strokes': strokes
          .map((s) => {
                'strokeId': s.strokeId,
                'points': s.points.map((p) => p.toMap()).toList(),
                'colorValue': s.colorValue,
                'strokeWidth': s.strokeWidth,
                'createdAt': Timestamp.fromDate(s.createdAt),
                'authorId': s.authorId,
                'authorName': s.authorName,
              })
          .toList(),
      'isPrivate': isPrivate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
    };
  }
}
