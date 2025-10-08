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
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get groupId => throw _privateConstructorUsedError;
  @HiveField(2)
  String get inviteCode => throw _privateConstructorUsedError;
  @HiveField(3)
  String get inviterUid => throw _privateConstructorUsedError;
  @HiveField(4)
  String get inviteeEmail => throw _privateConstructorUsedError;
  @HiveField(5)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(6)
  DateTime get expiresAt => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get isAccepted => throw _privateConstructorUsedError;
  @HiveField(8)
  String? get acceptedByUid => throw _privateConstructorUsedError;
  @HiveField(9)
  DateTime? get acceptedAt => throw _privateConstructorUsedError;

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
      {@HiveField(0) String id,
      @HiveField(1) String groupId,
      @HiveField(2) String inviteCode,
      @HiveField(3) String inviterUid,
      @HiveField(4) String inviteeEmail,
      @HiveField(5) DateTime createdAt,
      @HiveField(6) DateTime expiresAt,
      @HiveField(7) bool isAccepted,
      @HiveField(8) String? acceptedByUid,
      @HiveField(9) DateTime? acceptedAt});
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
    Object? id = null,
    Object? groupId = null,
    Object? inviteCode = null,
    Object? inviterUid = null,
    Object? inviteeEmail = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? isAccepted = null,
    Object? acceptedByUid = freezed,
    Object? acceptedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      inviteCode: null == inviteCode
          ? _value.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String,
      inviterUid: null == inviterUid
          ? _value.inviterUid
          : inviterUid // ignore: cast_nullable_to_non_nullable
              as String,
      inviteeEmail: null == inviteeEmail
          ? _value.inviteeEmail
          : inviteeEmail // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAccepted: null == isAccepted
          ? _value.isAccepted
          : isAccepted // ignore: cast_nullable_to_non_nullable
              as bool,
      acceptedByUid: freezed == acceptedByUid
          ? _value.acceptedByUid
          : acceptedByUid // ignore: cast_nullable_to_non_nullable
              as String?,
      acceptedAt: freezed == acceptedAt
          ? _value.acceptedAt
          : acceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
      {@HiveField(0) String id,
      @HiveField(1) String groupId,
      @HiveField(2) String inviteCode,
      @HiveField(3) String inviterUid,
      @HiveField(4) String inviteeEmail,
      @HiveField(5) DateTime createdAt,
      @HiveField(6) DateTime expiresAt,
      @HiveField(7) bool isAccepted,
      @HiveField(8) String? acceptedByUid,
      @HiveField(9) DateTime? acceptedAt});
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
    Object? id = null,
    Object? groupId = null,
    Object? inviteCode = null,
    Object? inviterUid = null,
    Object? inviteeEmail = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? isAccepted = null,
    Object? acceptedByUid = freezed,
    Object? acceptedAt = freezed,
  }) {
    return _then(_$InvitationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      inviteCode: null == inviteCode
          ? _value.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String,
      inviterUid: null == inviterUid
          ? _value.inviterUid
          : inviterUid // ignore: cast_nullable_to_non_nullable
              as String,
      inviteeEmail: null == inviteeEmail
          ? _value.inviteeEmail
          : inviteeEmail // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAccepted: null == isAccepted
          ? _value.isAccepted
          : isAccepted // ignore: cast_nullable_to_non_nullable
              as bool,
      acceptedByUid: freezed == acceptedByUid
          ? _value.acceptedByUid
          : acceptedByUid // ignore: cast_nullable_to_non_nullable
              as String?,
      acceptedAt: freezed == acceptedAt
          ? _value.acceptedAt
          : acceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvitationImpl implements _Invitation {
  const _$InvitationImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.groupId,
      @HiveField(2) required this.inviteCode,
      @HiveField(3) required this.inviterUid,
      @HiveField(4) required this.inviteeEmail,
      @HiveField(5) required this.createdAt,
      @HiveField(6) required this.expiresAt,
      @HiveField(7) this.isAccepted = false,
      @HiveField(8) this.acceptedByUid,
      @HiveField(9) this.acceptedAt});

  factory _$InvitationImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvitationImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String groupId;
  @override
  @HiveField(2)
  final String inviteCode;
  @override
  @HiveField(3)
  final String inviterUid;
  @override
  @HiveField(4)
  final String inviteeEmail;
  @override
  @HiveField(5)
  final DateTime createdAt;
  @override
  @HiveField(6)
  final DateTime expiresAt;
  @override
  @JsonKey()
  @HiveField(7)
  final bool isAccepted;
  @override
  @HiveField(8)
  final String? acceptedByUid;
  @override
  @HiveField(9)
  final DateTime? acceptedAt;

  @override
  String toString() {
    return 'Invitation(id: $id, groupId: $groupId, inviteCode: $inviteCode, inviterUid: $inviterUid, inviteeEmail: $inviteeEmail, createdAt: $createdAt, expiresAt: $expiresAt, isAccepted: $isAccepted, acceptedByUid: $acceptedByUid, acceptedAt: $acceptedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvitationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.inviterUid, inviterUid) ||
                other.inviterUid == inviterUid) &&
            (identical(other.inviteeEmail, inviteeEmail) ||
                other.inviteeEmail == inviteeEmail) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.isAccepted, isAccepted) ||
                other.isAccepted == isAccepted) &&
            (identical(other.acceptedByUid, acceptedByUid) ||
                other.acceptedByUid == acceptedByUid) &&
            (identical(other.acceptedAt, acceptedAt) ||
                other.acceptedAt == acceptedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      groupId,
      inviteCode,
      inviterUid,
      inviteeEmail,
      createdAt,
      expiresAt,
      isAccepted,
      acceptedByUid,
      acceptedAt);

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

abstract class _Invitation implements Invitation {
  const factory _Invitation(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String groupId,
      @HiveField(2) required final String inviteCode,
      @HiveField(3) required final String inviterUid,
      @HiveField(4) required final String inviteeEmail,
      @HiveField(5) required final DateTime createdAt,
      @HiveField(6) required final DateTime expiresAt,
      @HiveField(7) final bool isAccepted,
      @HiveField(8) final String? acceptedByUid,
      @HiveField(9) final DateTime? acceptedAt}) = _$InvitationImpl;

  factory _Invitation.fromJson(Map<String, dynamic> json) =
      _$InvitationImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get groupId;
  @override
  @HiveField(2)
  String get inviteCode;
  @override
  @HiveField(3)
  String get inviterUid;
  @override
  @HiveField(4)
  String get inviteeEmail;
  @override
  @HiveField(5)
  DateTime get createdAt;
  @override
  @HiveField(6)
  DateTime get expiresAt;
  @override
  @HiveField(7)
  bool get isAccepted;
  @override
  @HiveField(8)
  String? get acceptedByUid;
  @override
  @HiveField(9)
  DateTime? get acceptedAt;
  @override
  @JsonKey(ignore: true)
  _$$InvitationImplCopyWith<_$InvitationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CreateInvitationRequest {
  String get groupId => throw _privateConstructorUsedError;
  String get inviteeEmail => throw _privateConstructorUsedError;
  String get inviterUid => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CreateInvitationRequestCopyWith<CreateInvitationRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateInvitationRequestCopyWith<$Res> {
  factory $CreateInvitationRequestCopyWith(CreateInvitationRequest value,
          $Res Function(CreateInvitationRequest) then) =
      _$CreateInvitationRequestCopyWithImpl<$Res, CreateInvitationRequest>;
  @useResult
  $Res call({String groupId, String inviteeEmail, String inviterUid});
}

/// @nodoc
class _$CreateInvitationRequestCopyWithImpl<$Res,
        $Val extends CreateInvitationRequest>
    implements $CreateInvitationRequestCopyWith<$Res> {
  _$CreateInvitationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? inviteeEmail = null,
    Object? inviterUid = null,
  }) {
    return _then(_value.copyWith(
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      inviteeEmail: null == inviteeEmail
          ? _value.inviteeEmail
          : inviteeEmail // ignore: cast_nullable_to_non_nullable
              as String,
      inviterUid: null == inviterUid
          ? _value.inviterUid
          : inviterUid // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CreateInvitationRequestImplCopyWith<$Res>
    implements $CreateInvitationRequestCopyWith<$Res> {
  factory _$$CreateInvitationRequestImplCopyWith(
          _$CreateInvitationRequestImpl value,
          $Res Function(_$CreateInvitationRequestImpl) then) =
      __$$CreateInvitationRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String groupId, String inviteeEmail, String inviterUid});
}

/// @nodoc
class __$$CreateInvitationRequestImplCopyWithImpl<$Res>
    extends _$CreateInvitationRequestCopyWithImpl<$Res,
        _$CreateInvitationRequestImpl>
    implements _$$CreateInvitationRequestImplCopyWith<$Res> {
  __$$CreateInvitationRequestImplCopyWithImpl(
      _$CreateInvitationRequestImpl _value,
      $Res Function(_$CreateInvitationRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? inviteeEmail = null,
    Object? inviterUid = null,
  }) {
    return _then(_$CreateInvitationRequestImpl(
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      inviteeEmail: null == inviteeEmail
          ? _value.inviteeEmail
          : inviteeEmail // ignore: cast_nullable_to_non_nullable
              as String,
      inviterUid: null == inviterUid
          ? _value.inviterUid
          : inviterUid // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$CreateInvitationRequestImpl implements _CreateInvitationRequest {
  const _$CreateInvitationRequestImpl(
      {required this.groupId,
      required this.inviteeEmail,
      required this.inviterUid});

  @override
  final String groupId;
  @override
  final String inviteeEmail;
  @override
  final String inviterUid;

  @override
  String toString() {
    return 'CreateInvitationRequest(groupId: $groupId, inviteeEmail: $inviteeEmail, inviterUid: $inviterUid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateInvitationRequestImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.inviteeEmail, inviteeEmail) ||
                other.inviteeEmail == inviteeEmail) &&
            (identical(other.inviterUid, inviterUid) ||
                other.inviterUid == inviterUid));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, groupId, inviteeEmail, inviterUid);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateInvitationRequestImplCopyWith<_$CreateInvitationRequestImpl>
      get copyWith => __$$CreateInvitationRequestImplCopyWithImpl<
          _$CreateInvitationRequestImpl>(this, _$identity);
}

abstract class _CreateInvitationRequest implements CreateInvitationRequest {
  const factory _CreateInvitationRequest(
      {required final String groupId,
      required final String inviteeEmail,
      required final String inviterUid}) = _$CreateInvitationRequestImpl;

  @override
  String get groupId;
  @override
  String get inviteeEmail;
  @override
  String get inviterUid;
  @override
  @JsonKey(ignore: true)
  _$$CreateInvitationRequestImplCopyWith<_$CreateInvitationRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AcceptInvitationRequest {
  String get inviteCode => throw _privateConstructorUsedError;
  String get accepterUid => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AcceptInvitationRequestCopyWith<AcceptInvitationRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AcceptInvitationRequestCopyWith<$Res> {
  factory $AcceptInvitationRequestCopyWith(AcceptInvitationRequest value,
          $Res Function(AcceptInvitationRequest) then) =
      _$AcceptInvitationRequestCopyWithImpl<$Res, AcceptInvitationRequest>;
  @useResult
  $Res call({String inviteCode, String accepterUid});
}

/// @nodoc
class _$AcceptInvitationRequestCopyWithImpl<$Res,
        $Val extends AcceptInvitationRequest>
    implements $AcceptInvitationRequestCopyWith<$Res> {
  _$AcceptInvitationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inviteCode = null,
    Object? accepterUid = null,
  }) {
    return _then(_value.copyWith(
      inviteCode: null == inviteCode
          ? _value.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String,
      accepterUid: null == accepterUid
          ? _value.accepterUid
          : accepterUid // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AcceptInvitationRequestImplCopyWith<$Res>
    implements $AcceptInvitationRequestCopyWith<$Res> {
  factory _$$AcceptInvitationRequestImplCopyWith(
          _$AcceptInvitationRequestImpl value,
          $Res Function(_$AcceptInvitationRequestImpl) then) =
      __$$AcceptInvitationRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String inviteCode, String accepterUid});
}

/// @nodoc
class __$$AcceptInvitationRequestImplCopyWithImpl<$Res>
    extends _$AcceptInvitationRequestCopyWithImpl<$Res,
        _$AcceptInvitationRequestImpl>
    implements _$$AcceptInvitationRequestImplCopyWith<$Res> {
  __$$AcceptInvitationRequestImplCopyWithImpl(
      _$AcceptInvitationRequestImpl _value,
      $Res Function(_$AcceptInvitationRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inviteCode = null,
    Object? accepterUid = null,
  }) {
    return _then(_$AcceptInvitationRequestImpl(
      inviteCode: null == inviteCode
          ? _value.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String,
      accepterUid: null == accepterUid
          ? _value.accepterUid
          : accepterUid // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$AcceptInvitationRequestImpl implements _AcceptInvitationRequest {
  const _$AcceptInvitationRequestImpl(
      {required this.inviteCode, required this.accepterUid});

  @override
  final String inviteCode;
  @override
  final String accepterUid;

  @override
  String toString() {
    return 'AcceptInvitationRequest(inviteCode: $inviteCode, accepterUid: $accepterUid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AcceptInvitationRequestImpl &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.accepterUid, accepterUid) ||
                other.accepterUid == accepterUid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, inviteCode, accepterUid);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AcceptInvitationRequestImplCopyWith<_$AcceptInvitationRequestImpl>
      get copyWith => __$$AcceptInvitationRequestImplCopyWithImpl<
          _$AcceptInvitationRequestImpl>(this, _$identity);
}

abstract class _AcceptInvitationRequest implements AcceptInvitationRequest {
  const factory _AcceptInvitationRequest(
      {required final String inviteCode,
      required final String accepterUid}) = _$AcceptInvitationRequestImpl;

  @override
  String get inviteCode;
  @override
  String get accepterUid;
  @override
  @JsonKey(ignore: true)
  _$$AcceptInvitationRequestImplCopyWith<_$AcceptInvitationRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}
