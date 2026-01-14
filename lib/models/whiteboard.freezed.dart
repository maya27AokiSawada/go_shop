// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whiteboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DrawingStroke _$DrawingStrokeFromJson(Map<String, dynamic> json) {
  return _DrawingStroke.fromJson(json);
}

/// @nodoc
mixin _$DrawingStroke {
  @HiveField(0)
  String get strokeId => throw _privateConstructorUsedError;
  @HiveField(1)
  List<DrawingPoint> get points => throw _privateConstructorUsedError;
  @HiveField(2)
  int get colorValue => throw _privateConstructorUsedError; // Color.value
  @HiveField(3)
  double get strokeWidth => throw _privateConstructorUsedError;
  @HiveField(4)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(5)
  String get authorId => throw _privateConstructorUsedError;
  @HiveField(6)
  String get authorName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DrawingStrokeCopyWith<DrawingStroke> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DrawingStrokeCopyWith<$Res> {
  factory $DrawingStrokeCopyWith(
          DrawingStroke value, $Res Function(DrawingStroke) then) =
      _$DrawingStrokeCopyWithImpl<$Res, DrawingStroke>;
  @useResult
  $Res call(
      {@HiveField(0) String strokeId,
      @HiveField(1) List<DrawingPoint> points,
      @HiveField(2) int colorValue,
      @HiveField(3) double strokeWidth,
      @HiveField(4) DateTime createdAt,
      @HiveField(5) String authorId,
      @HiveField(6) String authorName});
}

/// @nodoc
class _$DrawingStrokeCopyWithImpl<$Res, $Val extends DrawingStroke>
    implements $DrawingStrokeCopyWith<$Res> {
  _$DrawingStrokeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strokeId = null,
    Object? points = null,
    Object? colorValue = null,
    Object? strokeWidth = null,
    Object? createdAt = null,
    Object? authorId = null,
    Object? authorName = null,
  }) {
    return _then(_value.copyWith(
      strokeId: null == strokeId
          ? _value.strokeId
          : strokeId // ignore: cast_nullable_to_non_nullable
              as String,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as List<DrawingPoint>,
      colorValue: null == colorValue
          ? _value.colorValue
          : colorValue // ignore: cast_nullable_to_non_nullable
              as int,
      strokeWidth: null == strokeWidth
          ? _value.strokeWidth
          : strokeWidth // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      authorName: null == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DrawingStrokeImplCopyWith<$Res>
    implements $DrawingStrokeCopyWith<$Res> {
  factory _$$DrawingStrokeImplCopyWith(
          _$DrawingStrokeImpl value, $Res Function(_$DrawingStrokeImpl) then) =
      __$$DrawingStrokeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String strokeId,
      @HiveField(1) List<DrawingPoint> points,
      @HiveField(2) int colorValue,
      @HiveField(3) double strokeWidth,
      @HiveField(4) DateTime createdAt,
      @HiveField(5) String authorId,
      @HiveField(6) String authorName});
}

/// @nodoc
class __$$DrawingStrokeImplCopyWithImpl<$Res>
    extends _$DrawingStrokeCopyWithImpl<$Res, _$DrawingStrokeImpl>
    implements _$$DrawingStrokeImplCopyWith<$Res> {
  __$$DrawingStrokeImplCopyWithImpl(
      _$DrawingStrokeImpl _value, $Res Function(_$DrawingStrokeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strokeId = null,
    Object? points = null,
    Object? colorValue = null,
    Object? strokeWidth = null,
    Object? createdAt = null,
    Object? authorId = null,
    Object? authorName = null,
  }) {
    return _then(_$DrawingStrokeImpl(
      strokeId: null == strokeId
          ? _value.strokeId
          : strokeId // ignore: cast_nullable_to_non_nullable
              as String,
      points: null == points
          ? _value._points
          : points // ignore: cast_nullable_to_non_nullable
              as List<DrawingPoint>,
      colorValue: null == colorValue
          ? _value.colorValue
          : colorValue // ignore: cast_nullable_to_non_nullable
              as int,
      strokeWidth: null == strokeWidth
          ? _value.strokeWidth
          : strokeWidth // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      authorName: null == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DrawingStrokeImpl implements _DrawingStroke {
  const _$DrawingStrokeImpl(
      {@HiveField(0) required this.strokeId,
      @HiveField(1) required final List<DrawingPoint> points,
      @HiveField(2) required this.colorValue,
      @HiveField(3) this.strokeWidth = 3.0,
      @HiveField(4) required this.createdAt,
      @HiveField(5) required this.authorId,
      @HiveField(6) required this.authorName})
      : _points = points;

  factory _$DrawingStrokeImpl.fromJson(Map<String, dynamic> json) =>
      _$$DrawingStrokeImplFromJson(json);

  @override
  @HiveField(0)
  final String strokeId;
  final List<DrawingPoint> _points;
  @override
  @HiveField(1)
  List<DrawingPoint> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  @override
  @HiveField(2)
  final int colorValue;
// Color.value
  @override
  @JsonKey()
  @HiveField(3)
  final double strokeWidth;
  @override
  @HiveField(4)
  final DateTime createdAt;
  @override
  @HiveField(5)
  final String authorId;
  @override
  @HiveField(6)
  final String authorName;

  @override
  String toString() {
    return 'DrawingStroke(strokeId: $strokeId, points: $points, colorValue: $colorValue, strokeWidth: $strokeWidth, createdAt: $createdAt, authorId: $authorId, authorName: $authorName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrawingStrokeImpl &&
            (identical(other.strokeId, strokeId) ||
                other.strokeId == strokeId) &&
            const DeepCollectionEquality().equals(other._points, _points) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue) &&
            (identical(other.strokeWidth, strokeWidth) ||
                other.strokeWidth == strokeWidth) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      strokeId,
      const DeepCollectionEquality().hash(_points),
      colorValue,
      strokeWidth,
      createdAt,
      authorId,
      authorName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DrawingStrokeImplCopyWith<_$DrawingStrokeImpl> get copyWith =>
      __$$DrawingStrokeImplCopyWithImpl<_$DrawingStrokeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DrawingStrokeImplToJson(
      this,
    );
  }
}

abstract class _DrawingStroke implements DrawingStroke {
  const factory _DrawingStroke(
      {@HiveField(0) required final String strokeId,
      @HiveField(1) required final List<DrawingPoint> points,
      @HiveField(2) required final int colorValue,
      @HiveField(3) final double strokeWidth,
      @HiveField(4) required final DateTime createdAt,
      @HiveField(5) required final String authorId,
      @HiveField(6) required final String authorName}) = _$DrawingStrokeImpl;

  factory _DrawingStroke.fromJson(Map<String, dynamic> json) =
      _$DrawingStrokeImpl.fromJson;

  @override
  @HiveField(0)
  String get strokeId;
  @override
  @HiveField(1)
  List<DrawingPoint> get points;
  @override
  @HiveField(2)
  int get colorValue;
  @override // Color.value
  @HiveField(3)
  double get strokeWidth;
  @override
  @HiveField(4)
  DateTime get createdAt;
  @override
  @HiveField(5)
  String get authorId;
  @override
  @HiveField(6)
  String get authorName;
  @override
  @JsonKey(ignore: true)
  _$$DrawingStrokeImplCopyWith<_$DrawingStrokeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DrawingPoint _$DrawingPointFromJson(Map<String, dynamic> json) {
  return _DrawingPoint.fromJson(json);
}

/// @nodoc
mixin _$DrawingPoint {
  @HiveField(0)
  double get x => throw _privateConstructorUsedError;
  @HiveField(1)
  double get y => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DrawingPointCopyWith<DrawingPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DrawingPointCopyWith<$Res> {
  factory $DrawingPointCopyWith(
          DrawingPoint value, $Res Function(DrawingPoint) then) =
      _$DrawingPointCopyWithImpl<$Res, DrawingPoint>;
  @useResult
  $Res call({@HiveField(0) double x, @HiveField(1) double y});
}

/// @nodoc
class _$DrawingPointCopyWithImpl<$Res, $Val extends DrawingPoint>
    implements $DrawingPointCopyWith<$Res> {
  _$DrawingPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DrawingPointImplCopyWith<$Res>
    implements $DrawingPointCopyWith<$Res> {
  factory _$$DrawingPointImplCopyWith(
          _$DrawingPointImpl value, $Res Function(_$DrawingPointImpl) then) =
      __$$DrawingPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@HiveField(0) double x, @HiveField(1) double y});
}

/// @nodoc
class __$$DrawingPointImplCopyWithImpl<$Res>
    extends _$DrawingPointCopyWithImpl<$Res, _$DrawingPointImpl>
    implements _$$DrawingPointImplCopyWith<$Res> {
  __$$DrawingPointImplCopyWithImpl(
      _$DrawingPointImpl _value, $Res Function(_$DrawingPointImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_$DrawingPointImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DrawingPointImpl implements _DrawingPoint {
  const _$DrawingPointImpl(
      {@HiveField(0) required this.x, @HiveField(1) required this.y});

  factory _$DrawingPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$DrawingPointImplFromJson(json);

  @override
  @HiveField(0)
  final double x;
  @override
  @HiveField(1)
  final double y;

  @override
  String toString() {
    return 'DrawingPoint(x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrawingPointImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, x, y);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DrawingPointImplCopyWith<_$DrawingPointImpl> get copyWith =>
      __$$DrawingPointImplCopyWithImpl<_$DrawingPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DrawingPointImplToJson(
      this,
    );
  }
}

abstract class _DrawingPoint implements DrawingPoint {
  const factory _DrawingPoint(
      {@HiveField(0) required final double x,
      @HiveField(1) required final double y}) = _$DrawingPointImpl;

  factory _DrawingPoint.fromJson(Map<String, dynamic> json) =
      _$DrawingPointImpl.fromJson;

  @override
  @HiveField(0)
  double get x;
  @override
  @HiveField(1)
  double get y;
  @override
  @JsonKey(ignore: true)
  _$$DrawingPointImplCopyWith<_$DrawingPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Whiteboard _$WhiteboardFromJson(Map<String, dynamic> json) {
  return _Whiteboard.fromJson(json);
}

/// @nodoc
mixin _$Whiteboard {
  @HiveField(0)
  String get whiteboardId => throw _privateConstructorUsedError;
  @HiveField(1)
  String get groupId => throw _privateConstructorUsedError;
  @HiveField(2)
  String? get ownerId =>
      throw _privateConstructorUsedError; // null = グループ共通、値あり = 個人用
  @HiveField(3)
  List<DrawingStroke> get strokes => throw _privateConstructorUsedError;
  @HiveField(4)
  bool get isPrivate => throw _privateConstructorUsedError; // 自分以外編集不可
  @HiveField(5)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(6)
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @HiveField(7)
  double get canvasWidth => throw _privateConstructorUsedError;
  @HiveField(8)
  double get canvasHeight => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WhiteboardCopyWith<Whiteboard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WhiteboardCopyWith<$Res> {
  factory $WhiteboardCopyWith(
          Whiteboard value, $Res Function(Whiteboard) then) =
      _$WhiteboardCopyWithImpl<$Res, Whiteboard>;
  @useResult
  $Res call(
      {@HiveField(0) String whiteboardId,
      @HiveField(1) String groupId,
      @HiveField(2) String? ownerId,
      @HiveField(3) List<DrawingStroke> strokes,
      @HiveField(4) bool isPrivate,
      @HiveField(5) DateTime createdAt,
      @HiveField(6) DateTime updatedAt,
      @HiveField(7) double canvasWidth,
      @HiveField(8) double canvasHeight});
}

/// @nodoc
class _$WhiteboardCopyWithImpl<$Res, $Val extends Whiteboard>
    implements $WhiteboardCopyWith<$Res> {
  _$WhiteboardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? whiteboardId = null,
    Object? groupId = null,
    Object? ownerId = freezed,
    Object? strokes = null,
    Object? isPrivate = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? canvasWidth = null,
    Object? canvasHeight = null,
  }) {
    return _then(_value.copyWith(
      whiteboardId: null == whiteboardId
          ? _value.whiteboardId
          : whiteboardId // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: freezed == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      strokes: null == strokes
          ? _value.strokes
          : strokes // ignore: cast_nullable_to_non_nullable
              as List<DrawingStroke>,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      canvasWidth: null == canvasWidth
          ? _value.canvasWidth
          : canvasWidth // ignore: cast_nullable_to_non_nullable
              as double,
      canvasHeight: null == canvasHeight
          ? _value.canvasHeight
          : canvasHeight // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WhiteboardImplCopyWith<$Res>
    implements $WhiteboardCopyWith<$Res> {
  factory _$$WhiteboardImplCopyWith(
          _$WhiteboardImpl value, $Res Function(_$WhiteboardImpl) then) =
      __$$WhiteboardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String whiteboardId,
      @HiveField(1) String groupId,
      @HiveField(2) String? ownerId,
      @HiveField(3) List<DrawingStroke> strokes,
      @HiveField(4) bool isPrivate,
      @HiveField(5) DateTime createdAt,
      @HiveField(6) DateTime updatedAt,
      @HiveField(7) double canvasWidth,
      @HiveField(8) double canvasHeight});
}

/// @nodoc
class __$$WhiteboardImplCopyWithImpl<$Res>
    extends _$WhiteboardCopyWithImpl<$Res, _$WhiteboardImpl>
    implements _$$WhiteboardImplCopyWith<$Res> {
  __$$WhiteboardImplCopyWithImpl(
      _$WhiteboardImpl _value, $Res Function(_$WhiteboardImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? whiteboardId = null,
    Object? groupId = null,
    Object? ownerId = freezed,
    Object? strokes = null,
    Object? isPrivate = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? canvasWidth = null,
    Object? canvasHeight = null,
  }) {
    return _then(_$WhiteboardImpl(
      whiteboardId: null == whiteboardId
          ? _value.whiteboardId
          : whiteboardId // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: freezed == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      strokes: null == strokes
          ? _value._strokes
          : strokes // ignore: cast_nullable_to_non_nullable
              as List<DrawingStroke>,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      canvasWidth: null == canvasWidth
          ? _value.canvasWidth
          : canvasWidth // ignore: cast_nullable_to_non_nullable
              as double,
      canvasHeight: null == canvasHeight
          ? _value.canvasHeight
          : canvasHeight // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WhiteboardImpl extends _Whiteboard {
  const _$WhiteboardImpl(
      {@HiveField(0) required this.whiteboardId,
      @HiveField(1) required this.groupId,
      @HiveField(2) this.ownerId,
      @HiveField(3) final List<DrawingStroke> strokes = const [],
      @HiveField(4) this.isPrivate = false,
      @HiveField(5) required this.createdAt,
      @HiveField(6) required this.updatedAt,
      @HiveField(7) this.canvasWidth = 800.0,
      @HiveField(8) this.canvasHeight = 600.0})
      : _strokes = strokes,
        super._();

  factory _$WhiteboardImpl.fromJson(Map<String, dynamic> json) =>
      _$$WhiteboardImplFromJson(json);

  @override
  @HiveField(0)
  final String whiteboardId;
  @override
  @HiveField(1)
  final String groupId;
  @override
  @HiveField(2)
  final String? ownerId;
// null = グループ共通、値あり = 個人用
  final List<DrawingStroke> _strokes;
// null = グループ共通、値あり = 個人用
  @override
  @JsonKey()
  @HiveField(3)
  List<DrawingStroke> get strokes {
    if (_strokes is EqualUnmodifiableListView) return _strokes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_strokes);
  }

  @override
  @JsonKey()
  @HiveField(4)
  final bool isPrivate;
// 自分以外編集不可
  @override
  @HiveField(5)
  final DateTime createdAt;
  @override
  @HiveField(6)
  final DateTime updatedAt;
  @override
  @JsonKey()
  @HiveField(7)
  final double canvasWidth;
  @override
  @JsonKey()
  @HiveField(8)
  final double canvasHeight;

  @override
  String toString() {
    return 'Whiteboard(whiteboardId: $whiteboardId, groupId: $groupId, ownerId: $ownerId, strokes: $strokes, isPrivate: $isPrivate, createdAt: $createdAt, updatedAt: $updatedAt, canvasWidth: $canvasWidth, canvasHeight: $canvasHeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WhiteboardImpl &&
            (identical(other.whiteboardId, whiteboardId) ||
                other.whiteboardId == whiteboardId) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            const DeepCollectionEquality().equals(other._strokes, _strokes) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.canvasWidth, canvasWidth) ||
                other.canvasWidth == canvasWidth) &&
            (identical(other.canvasHeight, canvasHeight) ||
                other.canvasHeight == canvasHeight));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      whiteboardId,
      groupId,
      ownerId,
      const DeepCollectionEquality().hash(_strokes),
      isPrivate,
      createdAt,
      updatedAt,
      canvasWidth,
      canvasHeight);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WhiteboardImplCopyWith<_$WhiteboardImpl> get copyWith =>
      __$$WhiteboardImplCopyWithImpl<_$WhiteboardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WhiteboardImplToJson(
      this,
    );
  }
}

abstract class _Whiteboard extends Whiteboard {
  const factory _Whiteboard(
      {@HiveField(0) required final String whiteboardId,
      @HiveField(1) required final String groupId,
      @HiveField(2) final String? ownerId,
      @HiveField(3) final List<DrawingStroke> strokes,
      @HiveField(4) final bool isPrivate,
      @HiveField(5) required final DateTime createdAt,
      @HiveField(6) required final DateTime updatedAt,
      @HiveField(7) final double canvasWidth,
      @HiveField(8) final double canvasHeight}) = _$WhiteboardImpl;
  const _Whiteboard._() : super._();

  factory _Whiteboard.fromJson(Map<String, dynamic> json) =
      _$WhiteboardImpl.fromJson;

  @override
  @HiveField(0)
  String get whiteboardId;
  @override
  @HiveField(1)
  String get groupId;
  @override
  @HiveField(2)
  String? get ownerId;
  @override // null = グループ共通、値あり = 個人用
  @HiveField(3)
  List<DrawingStroke> get strokes;
  @override
  @HiveField(4)
  bool get isPrivate;
  @override // 自分以外編集不可
  @HiveField(5)
  DateTime get createdAt;
  @override
  @HiveField(6)
  DateTime get updatedAt;
  @override
  @HiveField(7)
  double get canvasWidth;
  @override
  @HiveField(8)
  double get canvasHeight;
  @override
  @JsonKey(ignore: true)
  _$$WhiteboardImplCopyWith<_$WhiteboardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
