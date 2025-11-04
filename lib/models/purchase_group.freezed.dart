// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PurchaseGroupMember _$PurchaseGroupMemberFromJson(Map<String, dynamic> json) {
  return _PurchaseGroupMember.fromJson(json);
}

/// @nodoc
mixin _$PurchaseGroupMember {
  @HiveField(0)
  String get uid => throw _privateConstructorUsedError; // Firebase UID
  @HiveField(1)
  String get displayName => throw _privateConstructorUsedError; // 表示名
  @HiveField(2)
  PurchaseGroupRole get role => throw _privateConstructorUsedError; // 権限
  @HiveField(3)
  DateTime? get joinedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseGroupMemberCopyWith<PurchaseGroupMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseGroupMemberCopyWith<$Res> {
  factory $PurchaseGroupMemberCopyWith(
          PurchaseGroupMember value, $Res Function(PurchaseGroupMember) then) =
      _$PurchaseGroupMemberCopyWithImpl<$Res, PurchaseGroupMember>;
  @useResult
  $Res call(
      {@HiveField(0) String uid,
      @HiveField(1) String displayName,
      @HiveField(2) PurchaseGroupRole role,
      @HiveField(3) DateTime? joinedAt});
}

/// @nodoc
class _$PurchaseGroupMemberCopyWithImpl<$Res, $Val extends PurchaseGroupMember>
    implements $PurchaseGroupMemberCopyWith<$Res> {
  _$PurchaseGroupMemberCopyWithImpl(this._value, this._then);

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
              as PurchaseGroupRole,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseGroupMemberImplCopyWith<$Res>
    implements $PurchaseGroupMemberCopyWith<$Res> {
  factory _$$PurchaseGroupMemberImplCopyWith(_$PurchaseGroupMemberImpl value,
          $Res Function(_$PurchaseGroupMemberImpl) then) =
      __$$PurchaseGroupMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String uid,
      @HiveField(1) String displayName,
      @HiveField(2) PurchaseGroupRole role,
      @HiveField(3) DateTime? joinedAt});
}

/// @nodoc
class __$$PurchaseGroupMemberImplCopyWithImpl<$Res>
    extends _$PurchaseGroupMemberCopyWithImpl<$Res, _$PurchaseGroupMemberImpl>
    implements _$$PurchaseGroupMemberImplCopyWith<$Res> {
  __$$PurchaseGroupMemberImplCopyWithImpl(_$PurchaseGroupMemberImpl _value,
      $Res Function(_$PurchaseGroupMemberImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = null,
    Object? role = null,
    Object? joinedAt = freezed,
  }) {
    return _then(_$PurchaseGroupMemberImpl(
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
              as PurchaseGroupRole,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseGroupMemberImpl implements _PurchaseGroupMember {
  const _$PurchaseGroupMemberImpl(
      {@HiveField(0) required this.uid,
      @HiveField(1) required this.displayName,
      @HiveField(2) required this.role,
      @HiveField(3) this.joinedAt});

  factory _$PurchaseGroupMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseGroupMemberImplFromJson(json);

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
  final PurchaseGroupRole role;
// 権限
  @override
  @HiveField(3)
  final DateTime? joinedAt;

  @override
  String toString() {
    return 'PurchaseGroupMember(uid: $uid, displayName: $displayName, role: $role, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseGroupMemberImpl &&
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
  _$$PurchaseGroupMemberImplCopyWith<_$PurchaseGroupMemberImpl> get copyWith =>
      __$$PurchaseGroupMemberImplCopyWithImpl<_$PurchaseGroupMemberImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseGroupMemberImplToJson(
      this,
    );
  }
}

abstract class _PurchaseGroupMember implements PurchaseGroupMember {
  const factory _PurchaseGroupMember(
      {@HiveField(0) required final String uid,
      @HiveField(1) required final String displayName,
      @HiveField(2) required final PurchaseGroupRole role,
      @HiveField(3) final DateTime? joinedAt}) = _$PurchaseGroupMemberImpl;

  factory _PurchaseGroupMember.fromJson(Map<String, dynamic> json) =
      _$PurchaseGroupMemberImpl.fromJson;

  @override
  @HiveField(0)
  String get uid;
  @override // Firebase UID
  @HiveField(1)
  String get displayName;
  @override // 表示名
  @HiveField(2)
  PurchaseGroupRole get role;
  @override // 権限
  @HiveField(3)
  DateTime? get joinedAt;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseGroupMemberImplCopyWith<_$PurchaseGroupMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LegacyPurchaseGroupMember _$LegacyPurchaseGroupMemberFromJson(
    Map<String, dynamic> json) {
  return _LegacyPurchaseGroupMember.fromJson(json);
}

/// @nodoc
mixin _$LegacyPurchaseGroupMember {
  @HiveField(0)
  String get memberId => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  String get contact => throw _privateConstructorUsedError;
  @HiveField(3)
  PurchaseGroupRole get role => throw _privateConstructorUsedError;
  @HiveField(4)
  bool get isSignedIn => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LegacyPurchaseGroupMemberCopyWith<LegacyPurchaseGroupMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LegacyPurchaseGroupMemberCopyWith<$Res> {
  factory $LegacyPurchaseGroupMemberCopyWith(LegacyPurchaseGroupMember value,
          $Res Function(LegacyPurchaseGroupMember) then) =
      _$LegacyPurchaseGroupMemberCopyWithImpl<$Res, LegacyPurchaseGroupMember>;
  @useResult
  $Res call(
      {@HiveField(0) String memberId,
      @HiveField(1) String name,
      @HiveField(2) String contact,
      @HiveField(3) PurchaseGroupRole role,
      @HiveField(4) bool isSignedIn});
}

/// @nodoc
class _$LegacyPurchaseGroupMemberCopyWithImpl<$Res,
        $Val extends LegacyPurchaseGroupMember>
    implements $LegacyPurchaseGroupMemberCopyWith<$Res> {
  _$LegacyPurchaseGroupMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? name = null,
    Object? contact = null,
    Object? role = null,
    Object? isSignedIn = null,
  }) {
    return _then(_value.copyWith(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      contact: null == contact
          ? _value.contact
          : contact // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as PurchaseGroupRole,
      isSignedIn: null == isSignedIn
          ? _value.isSignedIn
          : isSignedIn // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LegacyPurchaseGroupMemberImplCopyWith<$Res>
    implements $LegacyPurchaseGroupMemberCopyWith<$Res> {
  factory _$$LegacyPurchaseGroupMemberImplCopyWith(
          _$LegacyPurchaseGroupMemberImpl value,
          $Res Function(_$LegacyPurchaseGroupMemberImpl) then) =
      __$$LegacyPurchaseGroupMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String memberId,
      @HiveField(1) String name,
      @HiveField(2) String contact,
      @HiveField(3) PurchaseGroupRole role,
      @HiveField(4) bool isSignedIn});
}

/// @nodoc
class __$$LegacyPurchaseGroupMemberImplCopyWithImpl<$Res>
    extends _$LegacyPurchaseGroupMemberCopyWithImpl<$Res,
        _$LegacyPurchaseGroupMemberImpl>
    implements _$$LegacyPurchaseGroupMemberImplCopyWith<$Res> {
  __$$LegacyPurchaseGroupMemberImplCopyWithImpl(
      _$LegacyPurchaseGroupMemberImpl _value,
      $Res Function(_$LegacyPurchaseGroupMemberImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? name = null,
    Object? contact = null,
    Object? role = null,
    Object? isSignedIn = null,
  }) {
    return _then(_$LegacyPurchaseGroupMemberImpl(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      contact: null == contact
          ? _value.contact
          : contact // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as PurchaseGroupRole,
      isSignedIn: null == isSignedIn
          ? _value.isSignedIn
          : isSignedIn // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LegacyPurchaseGroupMemberImpl implements _LegacyPurchaseGroupMember {
  const _$LegacyPurchaseGroupMemberImpl(
      {@HiveField(0) this.memberId = '',
      @HiveField(1) required this.name,
      @HiveField(2) required this.contact,
      @HiveField(3) required this.role,
      @HiveField(4) this.isSignedIn = false});

  factory _$LegacyPurchaseGroupMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$LegacyPurchaseGroupMemberImplFromJson(json);

  @override
  @JsonKey()
  @HiveField(0)
  final String memberId;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String contact;
  @override
  @HiveField(3)
  final PurchaseGroupRole role;
  @override
  @JsonKey()
  @HiveField(4)
  final bool isSignedIn;

  @override
  String toString() {
    return 'LegacyPurchaseGroupMember(memberId: $memberId, name: $name, contact: $contact, role: $role, isSignedIn: $isSignedIn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegacyPurchaseGroupMemberImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.contact, contact) || other.contact == contact) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isSignedIn, isSignedIn) ||
                other.isSignedIn == isSignedIn));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, memberId, name, contact, role, isSignedIn);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LegacyPurchaseGroupMemberImplCopyWith<_$LegacyPurchaseGroupMemberImpl>
      get copyWith => __$$LegacyPurchaseGroupMemberImplCopyWithImpl<
          _$LegacyPurchaseGroupMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LegacyPurchaseGroupMemberImplToJson(
      this,
    );
  }
}

abstract class _LegacyPurchaseGroupMember implements LegacyPurchaseGroupMember {
  const factory _LegacyPurchaseGroupMember(
      {@HiveField(0) final String memberId,
      @HiveField(1) required final String name,
      @HiveField(2) required final String contact,
      @HiveField(3) required final PurchaseGroupRole role,
      @HiveField(4) final bool isSignedIn}) = _$LegacyPurchaseGroupMemberImpl;

  factory _LegacyPurchaseGroupMember.fromJson(Map<String, dynamic> json) =
      _$LegacyPurchaseGroupMemberImpl.fromJson;

  @override
  @HiveField(0)
  String get memberId;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  String get contact;
  @override
  @HiveField(3)
  PurchaseGroupRole get role;
  @override
  @HiveField(4)
  bool get isSignedIn;
  @override
  @JsonKey(ignore: true)
  _$$LegacyPurchaseGroupMemberImplCopyWith<_$LegacyPurchaseGroupMemberImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PurchaseGroup _$PurchaseGroupFromJson(Map<String, dynamic> json) {
  return _PurchaseGroup.fromJson(json);
}

/// @nodoc
mixin _$PurchaseGroup {
  @HiveField(0)
  String get groupId => throw _privateConstructorUsedError;
  @HiveField(1)
  String get groupName => throw _privateConstructorUsedError;
  @HiveField(2)
  String get ownerUid => throw _privateConstructorUsedError;
  @HiveField(3)
  List<PurchaseGroupMember> get members => throw _privateConstructorUsedError;
  @HiveField(4)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(5)
  DateTime? get updatedAt => throw _privateConstructorUsedError; // シークレットモード機能
  @HiveField(6)
  bool get isSecret => throw _privateConstructorUsedError;
  @HiveField(7)
  List<String> get allowedUid => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseGroupCopyWith<PurchaseGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseGroupCopyWith<$Res> {
  factory $PurchaseGroupCopyWith(
          PurchaseGroup value, $Res Function(PurchaseGroup) then) =
      _$PurchaseGroupCopyWithImpl<$Res, PurchaseGroup>;
  @useResult
  $Res call(
      {@HiveField(0) String groupId,
      @HiveField(1) String groupName,
      @HiveField(2) String ownerUid,
      @HiveField(3) List<PurchaseGroupMember> members,
      @HiveField(4) DateTime? createdAt,
      @HiveField(5) DateTime? updatedAt,
      @HiveField(6) bool isSecret,
      @HiveField(7) List<String> allowedUid});
}

/// @nodoc
class _$PurchaseGroupCopyWithImpl<$Res, $Val extends PurchaseGroup>
    implements $PurchaseGroupCopyWith<$Res> {
  _$PurchaseGroupCopyWithImpl(this._value, this._then);

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
    Object? isSecret = null,
    Object? allowedUid = null,
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
              as List<PurchaseGroupMember>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSecret: null == isSecret
          ? _value.isSecret
          : isSecret // ignore: cast_nullable_to_non_nullable
              as bool,
      allowedUid: null == allowedUid
          ? _value.allowedUid
          : allowedUid // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseGroupImplCopyWith<$Res>
    implements $PurchaseGroupCopyWith<$Res> {
  factory _$$PurchaseGroupImplCopyWith(
          _$PurchaseGroupImpl value, $Res Function(_$PurchaseGroupImpl) then) =
      __$$PurchaseGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String groupId,
      @HiveField(1) String groupName,
      @HiveField(2) String ownerUid,
      @HiveField(3) List<PurchaseGroupMember> members,
      @HiveField(4) DateTime? createdAt,
      @HiveField(5) DateTime? updatedAt,
      @HiveField(6) bool isSecret,
      @HiveField(7) List<String> allowedUid});
}

/// @nodoc
class __$$PurchaseGroupImplCopyWithImpl<$Res>
    extends _$PurchaseGroupCopyWithImpl<$Res, _$PurchaseGroupImpl>
    implements _$$PurchaseGroupImplCopyWith<$Res> {
  __$$PurchaseGroupImplCopyWithImpl(
      _$PurchaseGroupImpl _value, $Res Function(_$PurchaseGroupImpl) _then)
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
    Object? isSecret = null,
    Object? allowedUid = null,
  }) {
    return _then(_$PurchaseGroupImpl(
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
              as List<PurchaseGroupMember>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSecret: null == isSecret
          ? _value.isSecret
          : isSecret // ignore: cast_nullable_to_non_nullable
              as bool,
      allowedUid: null == allowedUid
          ? _value._allowedUid
          : allowedUid // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseGroupImpl extends _PurchaseGroup {
  const _$PurchaseGroupImpl(
      {@HiveField(0) required this.groupId,
      @HiveField(1) required this.groupName,
      @HiveField(2) required this.ownerUid,
      @HiveField(3) final List<PurchaseGroupMember> members = const [],
      @HiveField(4) this.createdAt,
      @HiveField(5) this.updatedAt,
      @HiveField(6) this.isSecret = false,
      @HiveField(7) final List<String> allowedUid = const []})
      : _members = members,
        _allowedUid = allowedUid,
        super._();

  factory _$PurchaseGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseGroupImplFromJson(json);

  @override
  @HiveField(0)
  final String groupId;
  @override
  @HiveField(1)
  final String groupName;
  @override
  @HiveField(2)
  final String ownerUid;
  final List<PurchaseGroupMember> _members;
  @override
  @JsonKey()
  @HiveField(3)
  List<PurchaseGroupMember> get members {
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
// シークレットモード機能
  @override
  @JsonKey()
  @HiveField(6)
  final bool isSecret;
  final List<String> _allowedUid;
  @override
  @JsonKey()
  @HiveField(7)
  List<String> get allowedUid {
    if (_allowedUid is EqualUnmodifiableListView) return _allowedUid;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedUid);
  }

  @override
  String toString() {
    return 'PurchaseGroup(groupId: $groupId, groupName: $groupName, ownerUid: $ownerUid, members: $members, createdAt: $createdAt, updatedAt: $updatedAt, isSecret: $isSecret, allowedUid: $allowedUid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseGroupImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.ownerUid, ownerUid) ||
                other.ownerUid == ownerUid) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isSecret, isSecret) ||
                other.isSecret == isSecret) &&
            const DeepCollectionEquality()
                .equals(other._allowedUid, _allowedUid));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      groupId,
      groupName,
      ownerUid,
      const DeepCollectionEquality().hash(_members),
      createdAt,
      updatedAt,
      isSecret,
      const DeepCollectionEquality().hash(_allowedUid));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseGroupImplCopyWith<_$PurchaseGroupImpl> get copyWith =>
      __$$PurchaseGroupImplCopyWithImpl<_$PurchaseGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseGroupImplToJson(
      this,
    );
  }
}

abstract class _PurchaseGroup extends PurchaseGroup {
  const factory _PurchaseGroup(
      {@HiveField(0) required final String groupId,
      @HiveField(1) required final String groupName,
      @HiveField(2) required final String ownerUid,
      @HiveField(3) final List<PurchaseGroupMember> members,
      @HiveField(4) final DateTime? createdAt,
      @HiveField(5) final DateTime? updatedAt,
      @HiveField(6) final bool isSecret,
      @HiveField(7) final List<String> allowedUid}) = _$PurchaseGroupImpl;
  const _PurchaseGroup._() : super._();

  factory _PurchaseGroup.fromJson(Map<String, dynamic> json) =
      _$PurchaseGroupImpl.fromJson;

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
  List<PurchaseGroupMember> get members;
  @override
  @HiveField(4)
  DateTime? get createdAt;
  @override
  @HiveField(5)
  DateTime? get updatedAt;
  @override // シークレットモード機能
  @HiveField(6)
  bool get isSecret;
  @override
  @HiveField(7)
  List<String> get allowedUid;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseGroupImplCopyWith<_$PurchaseGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
