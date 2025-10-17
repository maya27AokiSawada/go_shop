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

/// @nodoc
mixin _$PurchaseGroupMember {
  @HiveField(0)
  String get memberId => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  String get contact => throw _privateConstructorUsedError; // email または phone
  @HiveField(3)
  PurchaseGroupRole get role => throw _privateConstructorUsedError;
  @HiveField(4)
  bool get isSignedIn => throw _privateConstructorUsedError; // 新しい招待管理フィールド
  @HiveField(9)
  InvitationStatus get invitationStatus => throw _privateConstructorUsedError;
  @HiveField(10)
  String? get securityKey => throw _privateConstructorUsedError; // 招待時のセキュリティキー
  @HiveField(7)
  DateTime? get invitedAt => throw _privateConstructorUsedError; // 招待日時
  @HiveField(8)
  DateTime? get acceptedAt => throw _privateConstructorUsedError; // 受諾日時
// 既存のフィールドは後方互換性のため残す（非推奨）
  @HiveField(5)
  @Deprecated('Use invitationStatus instead')
  bool get isInvited => throw _privateConstructorUsedError;
  @HiveField(6)
  @Deprecated('Use invitationStatus instead')
  bool get isInvitationAccepted => throw _privateConstructorUsedError;

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
      {@HiveField(0) String memberId,
      @HiveField(1) String name,
      @HiveField(2) String contact,
      @HiveField(3) PurchaseGroupRole role,
      @HiveField(4) bool isSignedIn,
      @HiveField(9) InvitationStatus invitationStatus,
      @HiveField(10) String? securityKey,
      @HiveField(7) DateTime? invitedAt,
      @HiveField(8) DateTime? acceptedAt,
      @HiveField(5) @Deprecated('Use invitationStatus instead') bool isInvited,
      @HiveField(6)
      @Deprecated('Use invitationStatus instead')
      bool isInvitationAccepted});
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
    Object? memberId = null,
    Object? name = null,
    Object? contact = null,
    Object? role = null,
    Object? isSignedIn = null,
    Object? invitationStatus = null,
    Object? securityKey = freezed,
    Object? invitedAt = freezed,
    Object? acceptedAt = freezed,
    Object? isInvited = null,
    Object? isInvitationAccepted = null,
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
      invitationStatus: null == invitationStatus
          ? _value.invitationStatus
          : invitationStatus // ignore: cast_nullable_to_non_nullable
              as InvitationStatus,
      securityKey: freezed == securityKey
          ? _value.securityKey
          : securityKey // ignore: cast_nullable_to_non_nullable
              as String?,
      invitedAt: freezed == invitedAt
          ? _value.invitedAt
          : invitedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      acceptedAt: freezed == acceptedAt
          ? _value.acceptedAt
          : acceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isInvited: null == isInvited
          ? _value.isInvited
          : isInvited // ignore: cast_nullable_to_non_nullable
              as bool,
      isInvitationAccepted: null == isInvitationAccepted
          ? _value.isInvitationAccepted
          : isInvitationAccepted // ignore: cast_nullable_to_non_nullable
              as bool,
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
      {@HiveField(0) String memberId,
      @HiveField(1) String name,
      @HiveField(2) String contact,
      @HiveField(3) PurchaseGroupRole role,
      @HiveField(4) bool isSignedIn,
      @HiveField(9) InvitationStatus invitationStatus,
      @HiveField(10) String? securityKey,
      @HiveField(7) DateTime? invitedAt,
      @HiveField(8) DateTime? acceptedAt,
      @HiveField(5) @Deprecated('Use invitationStatus instead') bool isInvited,
      @HiveField(6)
      @Deprecated('Use invitationStatus instead')
      bool isInvitationAccepted});
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
    Object? memberId = null,
    Object? name = null,
    Object? contact = null,
    Object? role = null,
    Object? isSignedIn = null,
    Object? invitationStatus = null,
    Object? securityKey = freezed,
    Object? invitedAt = freezed,
    Object? acceptedAt = freezed,
    Object? isInvited = null,
    Object? isInvitationAccepted = null,
  }) {
    return _then(_$PurchaseGroupMemberImpl(
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
      invitationStatus: null == invitationStatus
          ? _value.invitationStatus
          : invitationStatus // ignore: cast_nullable_to_non_nullable
              as InvitationStatus,
      securityKey: freezed == securityKey
          ? _value.securityKey
          : securityKey // ignore: cast_nullable_to_non_nullable
              as String?,
      invitedAt: freezed == invitedAt
          ? _value.invitedAt
          : invitedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      acceptedAt: freezed == acceptedAt
          ? _value.acceptedAt
          : acceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isInvited: null == isInvited
          ? _value.isInvited
          : isInvited // ignore: cast_nullable_to_non_nullable
              as bool,
      isInvitationAccepted: null == isInvitationAccepted
          ? _value.isInvitationAccepted
          : isInvitationAccepted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PurchaseGroupMemberImpl implements _PurchaseGroupMember {
  const _$PurchaseGroupMemberImpl(
      {@HiveField(0) this.memberId = '',
      @HiveField(1) required this.name,
      @HiveField(2) required this.contact,
      @HiveField(3) required this.role,
      @HiveField(4) this.isSignedIn = false,
      @HiveField(9) this.invitationStatus = InvitationStatus.self,
      @HiveField(10) this.securityKey,
      @HiveField(7) this.invitedAt,
      @HiveField(8) this.acceptedAt,
      @HiveField(5)
      @Deprecated('Use invitationStatus instead')
      this.isInvited = false,
      @HiveField(6)
      @Deprecated('Use invitationStatus instead')
      this.isInvitationAccepted = false});

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
// email または phone
  @override
  @HiveField(3)
  final PurchaseGroupRole role;
  @override
  @JsonKey()
  @HiveField(4)
  final bool isSignedIn;
// 新しい招待管理フィールド
  @override
  @JsonKey()
  @HiveField(9)
  final InvitationStatus invitationStatus;
  @override
  @HiveField(10)
  final String? securityKey;
// 招待時のセキュリティキー
  @override
  @HiveField(7)
  final DateTime? invitedAt;
// 招待日時
  @override
  @HiveField(8)
  final DateTime? acceptedAt;
// 受諾日時
// 既存のフィールドは後方互換性のため残す（非推奨）
  @override
  @JsonKey()
  @HiveField(5)
  @Deprecated('Use invitationStatus instead')
  final bool isInvited;
  @override
  @JsonKey()
  @HiveField(6)
  @Deprecated('Use invitationStatus instead')
  final bool isInvitationAccepted;

  @override
  String toString() {
    return 'PurchaseGroupMember(memberId: $memberId, name: $name, contact: $contact, role: $role, isSignedIn: $isSignedIn, invitationStatus: $invitationStatus, securityKey: $securityKey, invitedAt: $invitedAt, acceptedAt: $acceptedAt, isInvited: $isInvited, isInvitationAccepted: $isInvitationAccepted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseGroupMemberImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.contact, contact) || other.contact == contact) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isSignedIn, isSignedIn) ||
                other.isSignedIn == isSignedIn) &&
            (identical(other.invitationStatus, invitationStatus) ||
                other.invitationStatus == invitationStatus) &&
            (identical(other.securityKey, securityKey) ||
                other.securityKey == securityKey) &&
            (identical(other.invitedAt, invitedAt) ||
                other.invitedAt == invitedAt) &&
            (identical(other.acceptedAt, acceptedAt) ||
                other.acceptedAt == acceptedAt) &&
            (identical(other.isInvited, isInvited) ||
                other.isInvited == isInvited) &&
            (identical(other.isInvitationAccepted, isInvitationAccepted) ||
                other.isInvitationAccepted == isInvitationAccepted));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      memberId,
      name,
      contact,
      role,
      isSignedIn,
      invitationStatus,
      securityKey,
      invitedAt,
      acceptedAt,
      isInvited,
      isInvitationAccepted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseGroupMemberImplCopyWith<_$PurchaseGroupMemberImpl> get copyWith =>
      __$$PurchaseGroupMemberImplCopyWithImpl<_$PurchaseGroupMemberImpl>(
          this, _$identity);
}

abstract class _PurchaseGroupMember implements PurchaseGroupMember {
  const factory _PurchaseGroupMember(
      {@HiveField(0) final String memberId,
      @HiveField(1) required final String name,
      @HiveField(2) required final String contact,
      @HiveField(3) required final PurchaseGroupRole role,
      @HiveField(4) final bool isSignedIn,
      @HiveField(9) final InvitationStatus invitationStatus,
      @HiveField(10) final String? securityKey,
      @HiveField(7) final DateTime? invitedAt,
      @HiveField(8) final DateTime? acceptedAt,
      @HiveField(5)
      @Deprecated('Use invitationStatus instead')
      final bool isInvited,
      @HiveField(6)
      @Deprecated('Use invitationStatus instead')
      final bool isInvitationAccepted}) = _$PurchaseGroupMemberImpl;

  @override
  @HiveField(0)
  String get memberId;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  String get contact;
  @override // email または phone
  @HiveField(3)
  PurchaseGroupRole get role;
  @override
  @HiveField(4)
  bool get isSignedIn;
  @override // 新しい招待管理フィールド
  @HiveField(9)
  InvitationStatus get invitationStatus;
  @override
  @HiveField(10)
  String? get securityKey;
  @override // 招待時のセキュリティキー
  @HiveField(7)
  DateTime? get invitedAt;
  @override // 招待日時
  @HiveField(8)
  DateTime? get acceptedAt;
  @override // 受諾日時
// 既存のフィールドは後方互換性のため残す（非推奨）
  @HiveField(5)
  @Deprecated('Use invitationStatus instead')
  bool get isInvited;
  @override
  @HiveField(6)
  @Deprecated('Use invitationStatus instead')
  bool get isInvitationAccepted;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseGroupMemberImplCopyWith<_$PurchaseGroupMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PurchaseGroup {
  @HiveField(0)
  String get groupName => throw _privateConstructorUsedError;
  @HiveField(1)
  String get groupId => throw _privateConstructorUsedError;
  @HiveField(2)
  String? get ownerName => throw _privateConstructorUsedError;
  @HiveField(3)
  String? get ownerEmail => throw _privateConstructorUsedError;
  @HiveField(4)
  String? get ownerUid => throw _privateConstructorUsedError;
  @HiveField(5)
  List<PurchaseGroupMember>? get members => throw _privateConstructorUsedError;
  @HiveField(6)
  String? get ownerMessage =>
      throw _privateConstructorUsedError; // オーナーからメンバーへのメッセージ
  @HiveField(7)
  List<String>? get shoppingListIds => throw _privateConstructorUsedError;

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
      {@HiveField(0) String groupName,
      @HiveField(1) String groupId,
      @HiveField(2) String? ownerName,
      @HiveField(3) String? ownerEmail,
      @HiveField(4) String? ownerUid,
      @HiveField(5) List<PurchaseGroupMember>? members,
      @HiveField(6) String? ownerMessage,
      @HiveField(7) List<String>? shoppingListIds});
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
    Object? groupName = null,
    Object? groupId = null,
    Object? ownerName = freezed,
    Object? ownerEmail = freezed,
    Object? ownerUid = freezed,
    Object? members = freezed,
    Object? ownerMessage = freezed,
    Object? shoppingListIds = freezed,
  }) {
    return _then(_value.copyWith(
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerEmail: freezed == ownerEmail
          ? _value.ownerEmail
          : ownerEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerUid: freezed == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      members: freezed == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<PurchaseGroupMember>?,
      ownerMessage: freezed == ownerMessage
          ? _value.ownerMessage
          : ownerMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      shoppingListIds: freezed == shoppingListIds
          ? _value.shoppingListIds
          : shoppingListIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
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
      {@HiveField(0) String groupName,
      @HiveField(1) String groupId,
      @HiveField(2) String? ownerName,
      @HiveField(3) String? ownerEmail,
      @HiveField(4) String? ownerUid,
      @HiveField(5) List<PurchaseGroupMember>? members,
      @HiveField(6) String? ownerMessage,
      @HiveField(7) List<String>? shoppingListIds});
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
    Object? groupName = null,
    Object? groupId = null,
    Object? ownerName = freezed,
    Object? ownerEmail = freezed,
    Object? ownerUid = freezed,
    Object? members = freezed,
    Object? ownerMessage = freezed,
    Object? shoppingListIds = freezed,
  }) {
    return _then(_$PurchaseGroupImpl(
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerEmail: freezed == ownerEmail
          ? _value.ownerEmail
          : ownerEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerUid: freezed == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      members: freezed == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<PurchaseGroupMember>?,
      ownerMessage: freezed == ownerMessage
          ? _value.ownerMessage
          : ownerMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      shoppingListIds: freezed == shoppingListIds
          ? _value._shoppingListIds
          : shoppingListIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc

class _$PurchaseGroupImpl implements _PurchaseGroup {
  const _$PurchaseGroupImpl(
      {@HiveField(0) required this.groupName,
      @HiveField(1) required this.groupId,
      @HiveField(2) this.ownerName,
      @HiveField(3) this.ownerEmail,
      @HiveField(4) this.ownerUid,
      @HiveField(5) final List<PurchaseGroupMember>? members,
      @HiveField(6) this.ownerMessage,
      @HiveField(7) final List<String>? shoppingListIds})
      : _members = members,
        _shoppingListIds = shoppingListIds;

  @override
  @HiveField(0)
  final String groupName;
  @override
  @HiveField(1)
  final String groupId;
  @override
  @HiveField(2)
  final String? ownerName;
  @override
  @HiveField(3)
  final String? ownerEmail;
  @override
  @HiveField(4)
  final String? ownerUid;
  final List<PurchaseGroupMember>? _members;
  @override
  @HiveField(5)
  List<PurchaseGroupMember>? get members {
    final value = _members;
    if (value == null) return null;
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @HiveField(6)
  final String? ownerMessage;
// オーナーからメンバーへのメッセージ
  final List<String>? _shoppingListIds;
// オーナーからメンバーへのメッセージ
  @override
  @HiveField(7)
  List<String>? get shoppingListIds {
    final value = _shoppingListIds;
    if (value == null) return null;
    if (_shoppingListIds is EqualUnmodifiableListView) return _shoppingListIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'PurchaseGroup(groupName: $groupName, groupId: $groupId, ownerName: $ownerName, ownerEmail: $ownerEmail, ownerUid: $ownerUid, members: $members, ownerMessage: $ownerMessage, shoppingListIds: $shoppingListIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseGroupImpl &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.ownerName, ownerName) ||
                other.ownerName == ownerName) &&
            (identical(other.ownerEmail, ownerEmail) ||
                other.ownerEmail == ownerEmail) &&
            (identical(other.ownerUid, ownerUid) ||
                other.ownerUid == ownerUid) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.ownerMessage, ownerMessage) ||
                other.ownerMessage == ownerMessage) &&
            const DeepCollectionEquality()
                .equals(other._shoppingListIds, _shoppingListIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      groupName,
      groupId,
      ownerName,
      ownerEmail,
      ownerUid,
      const DeepCollectionEquality().hash(_members),
      ownerMessage,
      const DeepCollectionEquality().hash(_shoppingListIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseGroupImplCopyWith<_$PurchaseGroupImpl> get copyWith =>
      __$$PurchaseGroupImplCopyWithImpl<_$PurchaseGroupImpl>(this, _$identity);
}

abstract class _PurchaseGroup implements PurchaseGroup {
  const factory _PurchaseGroup(
      {@HiveField(0) required final String groupName,
      @HiveField(1) required final String groupId,
      @HiveField(2) final String? ownerName,
      @HiveField(3) final String? ownerEmail,
      @HiveField(4) final String? ownerUid,
      @HiveField(5) final List<PurchaseGroupMember>? members,
      @HiveField(6) final String? ownerMessage,
      @HiveField(7) final List<String>? shoppingListIds}) = _$PurchaseGroupImpl;

  @override
  @HiveField(0)
  String get groupName;
  @override
  @HiveField(1)
  String get groupId;
  @override
  @HiveField(2)
  String? get ownerName;
  @override
  @HiveField(3)
  String? get ownerEmail;
  @override
  @HiveField(4)
  String? get ownerUid;
  @override
  @HiveField(5)
  List<PurchaseGroupMember>? get members;
  @override
  @HiveField(6)
  String? get ownerMessage;
  @override // オーナーからメンバーへのメッセージ
  @HiveField(7)
  List<String>? get shoppingListIds;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseGroupImplCopyWith<_$PurchaseGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
