// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invitation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Invitation _$InvitationFromJson(Map<String, dynamic> json) {
  return _Invitation.fromJson(json);
}

/// @nodoc
mixin _$Invitation {
  /// 招待トークン (UUID v4形式: "INV_abc123-def456-...")
  String get token => throw _privateConstructorUsedError;

  /// 招待先グループID
  String get groupId => throw _privateConstructorUsedError;

  /// 招待先グループ名
  String get groupName => throw _privateConstructorUsedError;

  /// 招待元ユーザーUID
  String get invitedBy => throw _privateConstructorUsedError;

  /// 招待元ユーザー名
  String get inviterName => throw _privateConstructorUsedError;

  /// 作成日時
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 有効期限
  DateTime get expiresAt => throw _privateConstructorUsedError;

  /// 最大使用回数
  int get maxUses => throw _privateConstructorUsedError;

  /// 現在の使用回数
  int get currentUses => throw _privateConstructorUsedError;

  /// 使用済みユーザーUIDリスト
  List<String> get usedBy => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InvitationCopyWith<Invitation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvitationCopyWith<$Res> {
  factory $InvitationCopyWith(
          Invitation value, $Res Function(Invitation) then) =
      _$InvitationCopyWithImpl<$Res, Invitation>;
  @useResult
  $Res call(
      {String token,
      String groupId,
      String groupName,
      String invitedBy,
      String inviterName,
      DateTime createdAt,
      DateTime expiresAt,
      int maxUses,
      int currentUses,
      List<String> usedBy});
}

/// @nodoc
class _$InvitationCopyWithImpl<$Res, $Val extends Invitation>
    implements $InvitationCopyWith<$Res> {
  _$InvitationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? groupId = null,
    Object? groupName = null,
    Object? invitedBy = null,
    Object? inviterName = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? maxUses = null,
    Object? currentUses = null,
    Object? usedBy = null,
  }) {
    return _then(_value.copyWith(
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      invitedBy: null == invitedBy
          ? _value.invitedBy
          : invitedBy // ignore: cast_nullable_to_non_nullable
              as String,
      inviterName: null == inviterName
          ? _value.inviterName
          : inviterName // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maxUses: null == maxUses
          ? _value.maxUses
          : maxUses // ignore: cast_nullable_to_non_nullable
              as int,
      currentUses: null == currentUses
          ? _value.currentUses
          : currentUses // ignore: cast_nullable_to_non_nullable
              as int,
      usedBy: null == usedBy
          ? _value.usedBy
          : usedBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvitationImplCopyWith<$Res>
    implements $InvitationCopyWith<$Res> {
  factory _$$InvitationImplCopyWith(
          _$InvitationImpl value, $Res Function(_$InvitationImpl) then) =
      __$$InvitationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String token,
      String groupId,
      String groupName,
      String invitedBy,
      String inviterName,
      DateTime createdAt,
      DateTime expiresAt,
      int maxUses,
      int currentUses,
      List<String> usedBy});
}

/// @nodoc
class __$$InvitationImplCopyWithImpl<$Res>
    extends _$InvitationCopyWithImpl<$Res, _$InvitationImpl>
    implements _$$InvitationImplCopyWith<$Res> {
  __$$InvitationImplCopyWithImpl(
      _$InvitationImpl _value, $Res Function(_$InvitationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? groupId = null,
    Object? groupName = null,
    Object? invitedBy = null,
    Object? inviterName = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? maxUses = null,
    Object? currentUses = null,
    Object? usedBy = null,
  }) {
    return _then(_$InvitationImpl(
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      invitedBy: null == invitedBy
          ? _value.invitedBy
          : invitedBy // ignore: cast_nullable_to_non_nullable
              as String,
      inviterName: null == inviterName
          ? _value.inviterName
          : inviterName // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maxUses: null == maxUses
          ? _value.maxUses
          : maxUses // ignore: cast_nullable_to_non_nullable
              as int,
      currentUses: null == currentUses
          ? _value.currentUses
          : currentUses // ignore: cast_nullable_to_non_nullable
              as int,
      usedBy: null == usedBy
          ? _value._usedBy
          : usedBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvitationImpl extends _Invitation {
  const _$InvitationImpl(
      {required this.token,
      required this.groupId,
      required this.groupName,
      required this.invitedBy,
      required this.inviterName,
      required this.createdAt,
      required this.expiresAt,
      this.maxUses = 5,
      this.currentUses = 0,
      final List<String> usedBy = const []})
      : _usedBy = usedBy,
        super._();

  factory _$InvitationImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvitationImplFromJson(json);

  /// 招待トークン (UUID v4形式: "INV_abc123-def456-...")
  @override
  final String token;

  /// 招待先グループID
  @override
  final String groupId;

  /// 招待先グループ名
  @override
  final String groupName;

  /// 招待元ユーザーUID
  @override
  final String invitedBy;

  /// 招待元ユーザー名
  @override
  final String inviterName;

  /// 作成日時
  @override
  final DateTime createdAt;

  /// 有効期限
  @override
  final DateTime expiresAt;

  /// 最大使用回数
  @override
  @JsonKey()
  final int maxUses;

  /// 現在の使用回数
  @override
  @JsonKey()
  final int currentUses;

  /// 使用済みユーザーUIDリスト
  final List<String> _usedBy;

  /// 使用済みユーザーUIDリスト
  @override
  @JsonKey()
  List<String> get usedBy {
    if (_usedBy is EqualUnmodifiableListView) return _usedBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_usedBy);
  }

  @override
  String toString() {
    return 'Invitation(token: $token, groupId: $groupId, groupName: $groupName, invitedBy: $invitedBy, inviterName: $inviterName, createdAt: $createdAt, expiresAt: $expiresAt, maxUses: $maxUses, currentUses: $currentUses, usedBy: $usedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvitationImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.invitedBy, invitedBy) ||
                other.invitedBy == invitedBy) &&
            (identical(other.inviterName, inviterName) ||
                other.inviterName == inviterName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.maxUses, maxUses) || other.maxUses == maxUses) &&
            (identical(other.currentUses, currentUses) ||
                other.currentUses == currentUses) &&
            const DeepCollectionEquality().equals(other._usedBy, _usedBy));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      token,
      groupId,
      groupName,
      invitedBy,
      inviterName,
      createdAt,
      expiresAt,
      maxUses,
      currentUses,
      const DeepCollectionEquality().hash(_usedBy));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InvitationImplCopyWith<_$InvitationImpl> get copyWith =>
      __$$InvitationImplCopyWithImpl<_$InvitationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvitationImplToJson(
      this,
    );
  }
}

abstract class _Invitation extends Invitation {
  const factory _Invitation(
      {required final String token,
      required final String groupId,
      required final String groupName,
      required final String invitedBy,
      required final String inviterName,
      required final DateTime createdAt,
      required final DateTime expiresAt,
      final int maxUses,
      final int currentUses,
      final List<String> usedBy}) = _$InvitationImpl;
  const _Invitation._() : super._();

  factory _Invitation.fromJson(Map<String, dynamic> json) =
      _$InvitationImpl.fromJson;

  @override

  /// 招待トークン (UUID v4形式: "INV_abc123-def456-...")
  String get token;
  @override

  /// 招待先グループID
  String get groupId;
  @override

  /// 招待先グループ名
  String get groupName;
  @override

  /// 招待元ユーザーUID
  String get invitedBy;
  @override

  /// 招待元ユーザー名
  String get inviterName;
  @override

  /// 作成日時
  DateTime get createdAt;
  @override

  /// 有効期限
  DateTime get expiresAt;
  @override

  /// 最大使用回数
  int get maxUses;
  @override

  /// 現在の使用回数
  int get currentUses;
  @override

  /// 使用済みユーザーUIDリスト
  List<String> get usedBy;
  @override
  @JsonKey(ignore: true)
  _$$InvitationImplCopyWith<_$InvitationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InvitationQRData _$InvitationQRDataFromJson(Map<String, dynamic> json) {
  return _InvitationQRData.fromJson(json);
}

/// @nodoc
mixin _$InvitationQRData {
  /// データタイプ識別子
  String get type => throw _privateConstructorUsedError;

  /// バージョン
  String get version => throw _privateConstructorUsedError;

  /// 招待トークン
  String get token => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InvitationQRDataCopyWith<InvitationQRData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvitationQRDataCopyWith<$Res> {
  factory $InvitationQRDataCopyWith(
          InvitationQRData value, $Res Function(InvitationQRData) then) =
      _$InvitationQRDataCopyWithImpl<$Res, InvitationQRData>;
  @useResult
  $Res call({String type, String version, String token});
}

/// @nodoc
class _$InvitationQRDataCopyWithImpl<$Res, $Val extends InvitationQRData>
    implements $InvitationQRDataCopyWith<$Res> {
  _$InvitationQRDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? version = null,
    Object? token = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvitationQRDataImplCopyWith<$Res>
    implements $InvitationQRDataCopyWith<$Res> {
  factory _$$InvitationQRDataImplCopyWith(_$InvitationQRDataImpl value,
          $Res Function(_$InvitationQRDataImpl) then) =
      __$$InvitationQRDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, String version, String token});
}

/// @nodoc
class __$$InvitationQRDataImplCopyWithImpl<$Res>
    extends _$InvitationQRDataCopyWithImpl<$Res, _$InvitationQRDataImpl>
    implements _$$InvitationQRDataImplCopyWith<$Res> {
  __$$InvitationQRDataImplCopyWithImpl(_$InvitationQRDataImpl _value,
      $Res Function(_$InvitationQRDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? version = null,
    Object? token = null,
  }) {
    return _then(_$InvitationQRDataImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvitationQRDataImpl implements _InvitationQRData {
  const _$InvitationQRDataImpl(
      {this.type = 'go_shop_invitation',
      this.version = '1.0',
      required this.token});

  factory _$InvitationQRDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvitationQRDataImplFromJson(json);

  /// データタイプ識別子
  @override
  @JsonKey()
  final String type;

  /// バージョン
  @override
  @JsonKey()
  final String version;

  /// 招待トークン
  @override
  final String token;

  @override
  String toString() {
    return 'InvitationQRData(type: $type, version: $version, token: $token)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvitationQRDataImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.token, token) || other.token == token));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, type, version, token);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InvitationQRDataImplCopyWith<_$InvitationQRDataImpl> get copyWith =>
      __$$InvitationQRDataImplCopyWithImpl<_$InvitationQRDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvitationQRDataImplToJson(
      this,
    );
  }
}

abstract class _InvitationQRData implements InvitationQRData {
  const factory _InvitationQRData(
      {final String type,
      final String version,
      required final String token}) = _$InvitationQRDataImpl;

  factory _InvitationQRData.fromJson(Map<String, dynamic> json) =
      _$InvitationQRDataImpl.fromJson;

  @override

  /// データタイプ識別子
  String get type;
  @override

  /// バージョン
  String get version;
  @override

  /// 招待トークン
  String get token;
  @override
  @JsonKey(ignore: true)
  _$$InvitationQRDataImplCopyWith<_$InvitationQRDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
