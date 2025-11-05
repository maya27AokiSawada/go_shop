// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_group_v4.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PurchaseGroupMemberV4 _$PurchaseGroupMemberV4FromJson(
    Map<String, dynamic> json) {
  return _PurchaseGroupMemberV4.fromJson(json);
}

/// @nodoc
mixin _$PurchaseGroupMemberV4 {
  @HiveField(0)
  String get uid => throw _privateConstructorUsedError; // Firebase UID
  @HiveField(1)
  String get displayName => throw _privateConstructorUsedError; // 表示名
  @HiveField(2)
  PurchaseGroupRoleV4 get role => throw _privateConstructorUsedError; // 権限
  @HiveField(3)
  DateTime? get joinedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseGroupMemberV4CopyWith<PurchaseGroupMemberV4> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseGroupMemberV4CopyWith<$Res> {
  factory $PurchaseGroupMemberV4CopyWith(PurchaseGroupMemberV4 value,
          $Res Function(PurchaseGroupMemberV4) then) =
      _$PurchaseGroupMemberV4CopyWithImpl<$Res, PurchaseGroupMemberV4>;
  @useResult
  $Res call(
      {@HiveField(0) String uid,
      @HiveField(1) String displayName,
      @HiveField(2) PurchaseGroupRoleV4 role,
      @HiveField(3) DateTime? joinedAt});
}

/// @nodoc
class _$PurchaseGroupMemberV4CopyWithImpl<$Res,
        $Val extends PurchaseGroupMemberV4>
    implements $PurchaseGroupMemberV4CopyWith<$Res> {
  _$PurchaseGroupMemberV4CopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = null,
    Object? role = null,
    Object? joinedAt = freezed,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as PurchaseGroupRoleV4,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseGroupMemberV4ImplCopyWith<$Res>
    implements $PurchaseGroupMemberV4CopyWith<$Res> {
  factory _$$PurchaseGroupMemberV4ImplCopyWith(
          _$PurchaseGroupMemberV4Impl value,
          $Res Function(_$PurchaseGroupMemberV4Impl) then) =
      __$$PurchaseGroupMemberV4ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String uid,
      @HiveField(1) String displayName,
      @HiveField(2) PurchaseGroupRoleV4 role,
      @HiveField(3) DateTime? joinedAt});
}

/// @nodoc
class __$$PurchaseGroupMemberV4ImplCopyWithImpl<$Res>
    extends _$PurchaseGroupMemberV4CopyWithImpl<$Res,
        _$PurchaseGroupMemberV4Impl>
    implements _$$PurchaseGroupMemberV4ImplCopyWith<$Res> {
  __$$PurchaseGroupMemberV4ImplCopyWithImpl(_$PurchaseGroupMemberV4Impl _value,
      $Res Function(_$PurchaseGroupMemberV4Impl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = null,
    Object? role = null,
    Object? joinedAt = freezed,
  }) {
    return _then(_$PurchaseGroupMemberV4Impl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as PurchaseGroupRoleV4,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseGroupMemberV4Impl implements _PurchaseGroupMemberV4 {
  const _$PurchaseGroupMemberV4Impl(
      {@HiveField(0) required this.uid,
      @HiveField(1) required this.displayName,
      @HiveField(2) required this.role,
      @HiveField(3) this.joinedAt});

  factory _$PurchaseGroupMemberV4Impl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseGroupMemberV4ImplFromJson(json);

  @override
  @HiveField(0)
  final String uid;
// Firebase UID
  @override
  @HiveField(1)
  final String displayName;
// 表示名
  @override
  @HiveField(2)
  final PurchaseGroupRoleV4 role;
// 権限
  @override
  @HiveField(3)
  final DateTime? joinedAt;

  @override
  String toString() {
    return 'PurchaseGroupMemberV4(uid: $uid, displayName: $displayName, role: $role, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseGroupMemberV4Impl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, uid, displayName, role, joinedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseGroupMemberV4ImplCopyWith<_$PurchaseGroupMemberV4Impl>
      get copyWith => __$$PurchaseGroupMemberV4ImplCopyWithImpl<
          _$PurchaseGroupMemberV4Impl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseGroupMemberV4ImplToJson(
      this,
    );
  }
}

abstract class _PurchaseGroupMemberV4 implements PurchaseGroupMemberV4 {
  const factory _PurchaseGroupMemberV4(
      {@HiveField(0) required final String uid,
      @HiveField(1) required final String displayName,
      @HiveField(2) required final PurchaseGroupRoleV4 role,
      @HiveField(3) final DateTime? joinedAt}) = _$PurchaseGroupMemberV4Impl;

  factory _PurchaseGroupMemberV4.fromJson(Map<String, dynamic> json) =
      _$PurchaseGroupMemberV4Impl.fromJson;

  @override
  @HiveField(0)
  String get uid;
  @override // Firebase UID
  @HiveField(1)
  String get displayName;
  @override // 表示名
  @HiveField(2)
  PurchaseGroupRoleV4 get role;
  @override // 権限
  @HiveField(3)
  DateTime? get joinedAt;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseGroupMemberV4ImplCopyWith<_$PurchaseGroupMemberV4Impl>
      get copyWith => throw _privateConstructorUsedError;
}

PurchaseGroupV4 _$PurchaseGroupV4FromJson(Map<String, dynamic> json) {
  return _PurchaseGroupV4.fromJson(json);
}

/// @nodoc
mixin _$PurchaseGroupV4 {
  @HiveField(0)
  String get groupId => throw _privateConstructorUsedError;
  @HiveField(1)
  String get groupName => throw _privateConstructorUsedError;
  @HiveField(2)
  String get ownerUid => throw _privateConstructorUsedError;
  @HiveField(3)
  List<PurchaseGroupMemberV4> get members => throw _privateConstructorUsedError;
  @HiveField(4)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(5)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseGroupV4CopyWith<PurchaseGroupV4> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseGroupV4CopyWith<$Res> {
  factory $PurchaseGroupV4CopyWith(
          PurchaseGroupV4 value, $Res Function(PurchaseGroupV4) then) =
      _$PurchaseGroupV4CopyWithImpl<$Res, PurchaseGroupV4>;
  @useResult
  $Res call(
      {@HiveField(0) String groupId,
      @HiveField(1) String groupName,
      @HiveField(2) String ownerUid,
      @HiveField(3) List<PurchaseGroupMemberV4> members,
      @HiveField(4) DateTime? createdAt,
      @HiveField(5) DateTime? updatedAt});
}

/// @nodoc
class _$PurchaseGroupV4CopyWithImpl<$Res, $Val extends PurchaseGroupV4>
    implements $PurchaseGroupV4CopyWith<$Res> {
  _$PurchaseGroupV4CopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? groupName = null,
    Object? ownerUid = null,
    Object? members = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      ownerUid: null == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<PurchaseGroupMemberV4>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseGroupV4ImplCopyWith<$Res>
    implements $PurchaseGroupV4CopyWith<$Res> {
  factory _$$PurchaseGroupV4ImplCopyWith(_$PurchaseGroupV4Impl value,
          $Res Function(_$PurchaseGroupV4Impl) then) =
      __$$PurchaseGroupV4ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String groupId,
      @HiveField(1) String groupName,
      @HiveField(2) String ownerUid,
      @HiveField(3) List<PurchaseGroupMemberV4> members,
      @HiveField(4) DateTime? createdAt,
      @HiveField(5) DateTime? updatedAt});
}

/// @nodoc
class __$$PurchaseGroupV4ImplCopyWithImpl<$Res>
    extends _$PurchaseGroupV4CopyWithImpl<$Res, _$PurchaseGroupV4Impl>
    implements _$$PurchaseGroupV4ImplCopyWith<$Res> {
  __$$PurchaseGroupV4ImplCopyWithImpl(
      _$PurchaseGroupV4Impl _value, $Res Function(_$PurchaseGroupV4Impl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? groupName = null,
    Object? ownerUid = null,
    Object? members = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$PurchaseGroupV4Impl(
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      ownerUid: null == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<PurchaseGroupMemberV4>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseGroupV4Impl extends _PurchaseGroupV4 {
  const _$PurchaseGroupV4Impl(
      {@HiveField(0) required this.groupId,
      @HiveField(1) required this.groupName,
      @HiveField(2) required this.ownerUid,
      @HiveField(3) final List<PurchaseGroupMemberV4> members = const [],
      @HiveField(4) this.createdAt,
      @HiveField(5) this.updatedAt})
      : _members = members,
        super._();

  factory _$PurchaseGroupV4Impl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseGroupV4ImplFromJson(json);

  @override
  @HiveField(0)
  final String groupId;
  @override
  @HiveField(1)
  final String groupName;
  @override
  @HiveField(2)
  final String ownerUid;
  final List<PurchaseGroupMemberV4> _members;
  @override
  @JsonKey()
  @HiveField(3)
  List<PurchaseGroupMemberV4> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  @HiveField(4)
  final DateTime? createdAt;
  @override
  @HiveField(5)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PurchaseGroupV4(groupId: $groupId, groupName: $groupName, ownerUid: $ownerUid, members: $members, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseGroupV4Impl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.ownerUid, ownerUid) ||
                other.ownerUid == ownerUid) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, groupId, groupName, ownerUid,
      const DeepCollectionEquality().hash(_members), createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseGroupV4ImplCopyWith<_$PurchaseGroupV4Impl> get copyWith =>
      __$$PurchaseGroupV4ImplCopyWithImpl<_$PurchaseGroupV4Impl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseGroupV4ImplToJson(
      this,
    );
  }
}

abstract class _PurchaseGroupV4 extends PurchaseGroupV4 {
  const factory _PurchaseGroupV4(
      {@HiveField(0) required final String groupId,
      @HiveField(1) required final String groupName,
      @HiveField(2) required final String ownerUid,
      @HiveField(3) final List<PurchaseGroupMemberV4> members,
      @HiveField(4) final DateTime? createdAt,
      @HiveField(5) final DateTime? updatedAt}) = _$PurchaseGroupV4Impl;
  const _PurchaseGroupV4._() : super._();

  factory _PurchaseGroupV4.fromJson(Map<String, dynamic> json) =
      _$PurchaseGroupV4Impl.fromJson;

  @override
  @HiveField(0)
  String get groupId;
  @override
  @HiveField(1)
  String get groupName;
  @override
  @HiveField(2)
  String get ownerUid;
  @override
  @HiveField(3)
  List<PurchaseGroupMemberV4> get members;
  @override
  @HiveField(4)
  DateTime? get createdAt;
  @override
  @HiveField(5)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseGroupV4ImplCopyWith<_$PurchaseGroupV4Impl> get copyWith =>
      throw _privateConstructorUsedError;
}
