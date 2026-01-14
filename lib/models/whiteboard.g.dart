// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whiteboard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrawingStrokeAdapter extends TypeAdapter<DrawingStroke> {
  @override
  final int typeId = 12;

  @override
  DrawingStroke read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawingStroke(
      strokeId: fields[0] as String,
      points: (fields[1] as List).cast<DrawingPoint>(),
      colorValue: fields[2] as int,
      strokeWidth: fields[3] as double,
      createdAt: fields[4] as DateTime,
      authorId: fields[5] as String,
      authorName: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DrawingStroke obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.strokeId)
      ..writeByte(1)
      ..write(obj.points)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.strokeWidth)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.authorId)
      ..writeByte(6)
      ..write(obj.authorName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingStrokeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DrawingPointAdapter extends TypeAdapter<DrawingPoint> {
  @override
  final int typeId = 13;

  @override
  DrawingPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawingPoint(
      x: fields[0] as double,
      y: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DrawingPoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WhiteboardAdapter extends TypeAdapter<Whiteboard> {
  @override
  final int typeId = 14;

  @override
  Whiteboard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Whiteboard(
      whiteboardId: fields[0] as String,
      groupId: fields[1] as String,
      ownerId: fields[2] as String?,
      strokes: (fields[3] as List).cast<DrawingStroke>(),
      isPrivate: fields[4] as bool,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      canvasWidth: fields[7] as double,
      canvasHeight: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Whiteboard obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.whiteboardId)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.ownerId)
      ..writeByte(3)
      ..write(obj.strokes)
      ..writeByte(4)
      ..write(obj.isPrivate)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.canvasWidth)
      ..writeByte(8)
      ..write(obj.canvasHeight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhiteboardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DrawingStrokeImpl _$$DrawingStrokeImplFromJson(Map<String, dynamic> json) =>
    _$DrawingStrokeImpl(
      strokeId: json['strokeId'] as String,
      points: (json['points'] as List<dynamic>)
          .map((e) => DrawingPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      colorValue: (json['colorValue'] as num).toInt(),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
    );

Map<String, dynamic> _$$DrawingStrokeImplToJson(_$DrawingStrokeImpl instance) =>
    <String, dynamic>{
      'strokeId': instance.strokeId,
      'points': instance.points,
      'colorValue': instance.colorValue,
      'strokeWidth': instance.strokeWidth,
      'createdAt': instance.createdAt.toIso8601String(),
      'authorId': instance.authorId,
      'authorName': instance.authorName,
    };

_$DrawingPointImpl _$$DrawingPointImplFromJson(Map<String, dynamic> json) =>
    _$DrawingPointImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$$DrawingPointImplToJson(_$DrawingPointImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

_$WhiteboardImpl _$$WhiteboardImplFromJson(Map<String, dynamic> json) =>
    _$WhiteboardImpl(
      whiteboardId: json['whiteboardId'] as String,
      groupId: json['groupId'] as String,
      ownerId: json['ownerId'] as String?,
      strokes: (json['strokes'] as List<dynamic>?)
              ?.map((e) => DrawingStroke.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isPrivate: json['isPrivate'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      canvasWidth: (json['canvasWidth'] as num?)?.toDouble() ?? 800.0,
      canvasHeight: (json['canvasHeight'] as num?)?.toDouble() ?? 600.0,
    );

Map<String, dynamic> _$$WhiteboardImplToJson(_$WhiteboardImpl instance) =>
    <String, dynamic>{
      'whiteboardId': instance.whiteboardId,
      'groupId': instance.groupId,
      'ownerId': instance.ownerId,
      'strokes': instance.strokes,
      'isPrivate': instance.isPrivate,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'canvasWidth': instance.canvasWidth,
      'canvasHeight': instance.canvasHeight,
    };
