// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SharedGroupMember _$SharedGroupMemberFromJson(Map<String, dynamic> json) {
  return _SharedGroupMember.fromJson(json);
}

/// @nodoc
mixin _$SharedGroupMember {
  @HiveField(0)
  String get memberId => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  String get contact => throw _privateConstructorUsedError; // email または phone
  @HiveField(3)
  SharedGroupRole get role => throw _privateConstructorUsedError;
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

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SharedGroupMemberCopyWith<SharedGroupMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SharedGroupMemberCopyWith<$Res> {
  factory $SharedGroupMemberCopyWith(
          SharedGroupMember value, $Res Function(SharedGroupMember) then) =
      _$SharedGroupMemberCopyWithImpl<$Res, SharedGroupMember>;
  @useResult
  $Res call(
      {@HiveField(0) String memberId,
      @HiveField(1) String name,
      @HiveField(2) String contact,
      @HiveField(3) SharedGroupRole role,
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
class _$SharedGroupMemberCopyWithImpl<$Res, $Val extends SharedGroupMember>
    implements $SharedGroupMemberCopyWith<$Res> {
  _$SharedGroupMemberCopyWithImpl(this._value, this._then);

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
              as SharedGroupRole,
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
abstract class _$$SharedGroupMemberImplCopyWith<$Res>
    implements $SharedGroupMemberCopyWith<$Res> {
  factory _$$SharedGroupMemberImplCopyWith(_$SharedGroupMemberImpl value,
          $Res Function(_$SharedGroupMemberImpl) then) =
      __$$SharedGroupMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String memberId,
      @HiveField(1) String name,
      @HiveField(2) String contact,
      @HiveField(3) SharedGroupRole role,
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
class __$$SharedGroupMemberImplCopyWithImpl<$Res>
    extends _$SharedGroupMemberCopyWithImpl<$Res, _$SharedGroupMemberImpl>
    implements _$$SharedGroupMemberImplCopyWith<$Res> {
  __$$SharedGroupMemberImplCopyWithImpl(_$SharedGroupMemberImpl _value,
      $Res Function(_$SharedGroupMemberImpl) _then)
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
    return _then(_$SharedGroupMemberImpl(
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
              as SharedGroupRole,
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
@JsonSerializable()
class _$SharedGroupMemberImpl implements _SharedGroupMember {
  const _$SharedGroupMemberImpl(
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

  factory _$SharedGroupMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$SharedGroupMemberImplFromJson(json);

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
  final SharedGroupRole role;
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
    return 'SharedGroupMember(memberId: $memberId, name: $name, contact: $contact, role: $role, isSignedIn: $isSignedIn, invitationStatus: $invitationStatus, securityKey: $securityKey, invitedAt: $invitedAt, acceptedAt: $acceptedAt, isInvited: $isInvited, isInvitationAccepted: $isInvitationAccepted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SharedGroupMemberImpl &&
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

  @JsonKey(ignore: true)
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
  _$$SharedGroupMemberImplCopyWith<_$SharedGroupMemberImpl> get copyWith =>
      __$$SharedGroupMemberImplCopyWithImpl<_$SharedGroupMemberImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SharedGroupMemberImplToJson(
      this,
    );
  }
}

abstract class _SharedGroupMember implements SharedGroupMember {
  const factory _SharedGroupMember(
      {@HiveField(0) final String memberId,
      @HiveField(1) required final String name,
      @HiveField(2) required final String contact,
      @HiveField(3) required final SharedGroupRole role,
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
      final bool isInvitationAccepted}) = _$SharedGroupMemberImpl;

  factory _SharedGroupMember.fromJson(Map<String, dynamic> json) =
      _$SharedGroupMemberImpl.fromJson;

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
  SharedGroupRole get role;
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
  _$$SharedGroupMemberImplCopyWith<_$SharedGroupMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SharedGroup _$SharedGroupFromJson(Map<String, dynamic> json) {
  return _SharedGroup.fromJson(json);
}

/// @nodoc
mixin _$SharedGroup {
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
  List<SharedGroupMember>? get members => throw _privateConstructorUsedError;
  @HiveField(6)
  String? get ownerMessage =>
      throw _privateConstructorUsedError; // @HiveField(7) @Default([]) List<String> sharedListIds, // サブコレクション化のため不要に
  @HiveField(11)
  List<String> get allowedUid => throw _privateConstructorUsedError;
  @HiveField(12)
  bool get isSecret =>
      throw _privateConstructorUsedError; // acceptedUid: [{uid: securityKey}] のような構造を想定
  @HiveField(13)
  List<Map<String, String>> get acceptedUid =>
      throw _privateConstructorUsedError; // 削除フラグと最終アクセス日時
  @HiveField(14)
  bool get isDeleted => throw _privateConstructorUsedError;
  @HiveField(15)
  DateTime? get lastAccessedAt => throw _privateConstructorUsedError;
  @HiveField(16)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(17)
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @HiveField(18)
  SyncStatus get syncStatus => throw _privateConstructorUsedError;
  @HiveField(19)
  GroupType get groupType => throw _privateConstructorUsedError; // グループタイプ追加
// 🆕 階層構造管理（HiveField 20-21）
  @HiveField(20)
  String? get parentGroupId => throw _privateConstructorUsedError; // 親グループID
  @HiveField(21)
  List<String> get childGroupIds =>
      throw _privateConstructorUsedError; // 子グループIDリスト
// 🆕 権限管理（HiveField 22-24）
  @HiveField(22)
  Map<String, int> get memberPermissions =>
      throw _privateConstructorUsedError; // userId → permission bits
  @HiveField(23)
  int get defaultPermission =>
      throw _privateConstructorUsedError; // デフォルト権限（READ | DONE）
  @HiveField(24)
  bool get inheritParentLists => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SharedGroupCopyWith<SharedGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SharedGroupCopyWith<$Res> {
  factory $SharedGroupCopyWith(
          SharedGroup value, $Res Function(SharedGroup) then) =
      _$SharedGroupCopyWithImpl<$Res, SharedGroup>;
  @useResult
  $Res call(
      {@HiveField(0) String groupName,
      @HiveField(1) String groupId,
      @HiveField(2) String? ownerName,
      @HiveField(3) String? ownerEmail,
      @HiveField(4) String? ownerUid,
      @HiveField(5) List<SharedGroupMember>? members,
      @HiveField(6) String? ownerMessage,
      @HiveField(11) List<String> allowedUid,
      @HiveField(12) bool isSecret,
      @HiveField(13) List<Map<String, String>> acceptedUid,
      @HiveField(14) bool isDeleted,
      @HiveField(15) DateTime? lastAccessedAt,
      @HiveField(16) DateTime? createdAt,
      @HiveField(17) DateTime? updatedAt,
      @HiveField(18) SyncStatus syncStatus,
      @HiveField(19) GroupType groupType,
      @HiveField(20) String? parentGroupId,
      @HiveField(21) List<String> childGroupIds,
      @HiveField(22) Map<String, int> memberPermissions,
      @HiveField(23) int defaultPermission,
      @HiveField(24) bool inheritParentLists});
}

/// @nodoc
class _$SharedGroupCopyWithImpl<$Res, $Val extends SharedGroup>
    implements $SharedGroupCopyWith<$Res> {
  _$SharedGroupCopyWithImpl(this._value, this._then);

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
    Object? allowedUid = null,
    Object? isSecret = null,
    Object? acceptedUid = null,
    Object? isDeleted = null,
    Object? lastAccessedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? syncStatus = null,
    Object? groupType = null,
    Object? parentGroupId = freezed,
    Object? childGroupIds = null,
    Object? memberPermissions = null,
    Object? defaultPermission = null,
    Object? inheritParentLists = null,
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
              as List<SharedGroupMember>?,
      ownerMessage: freezed == ownerMessage
          ? _value.ownerMessage
          : ownerMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      allowedUid: null == allowedUid
          ? _value.allowedUid
          : allowedUid // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isSecret: null == isSecret
          ? _value.isSecret
          : isSecret // ignore: cast_nullable_to_non_nullable
              as bool,
      acceptedUid: null == acceptedUid
          ? _value.acceptedUid
          : acceptedUid // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      lastAccessedAt: freezed == lastAccessedAt
          ? _value.lastAccessedAt
          : lastAccessedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      groupType: null == groupType
          ? _value.groupType
          : groupType // ignore: cast_nullable_to_non_nullable
              as GroupType,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      childGroupIds: null == childGroupIds
          ? _value.childGroupIds
          : childGroupIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      memberPermissions: null == memberPermissions
          ? _value.memberPermissions
          : memberPermissions // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      defaultPermission: null == defaultPermission
          ? _value.defaultPermission
          : defaultPermission // ignore: cast_nullable_to_non_nullable
              as int,
      inheritParentLists: null == inheritParentLists
          ? _value.inheritParentLists
          : inheritParentLists // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SharedGroupImplCopyWith<$Res>
    implements $SharedGroupCopyWith<$Res> {
  factory _$$SharedGroupImplCopyWith(
          _$SharedGroupImpl value, $Res Function(_$SharedGroupImpl) then) =
      __$$SharedGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String groupName,
      @HiveField(1) String groupId,
      @HiveField(2) String? ownerName,
      @HiveField(3) String? ownerEmail,
      @HiveField(4) String? ownerUid,
      @HiveField(5) List<SharedGroupMember>? members,
      @HiveField(6) String? ownerMessage,
      @HiveField(11) List<String> allowedUid,
      @HiveField(12) bool isSecret,
      @HiveField(13) List<Map<String, String>> acceptedUid,
      @HiveField(14) bool isDeleted,
      @HiveField(15) DateTime? lastAccessedAt,
      @HiveField(16) DateTime? createdAt,
      @HiveField(17) DateTime? updatedAt,
      @HiveField(18) SyncStatus syncStatus,
      @HiveField(19) GroupType groupType,
      @HiveField(20) String? parentGroupId,
      @HiveField(21) List<String> childGroupIds,
      @HiveField(22) Map<String, int> memberPermissions,
      @HiveField(23) int defaultPermission,
      @HiveField(24) bool inheritParentLists});
}

/// @nodoc
class __$$SharedGroupImplCopyWithImpl<$Res>
    extends _$SharedGroupCopyWithImpl<$Res, _$SharedGroupImpl>
    implements _$$SharedGroupImplCopyWith<$Res> {
  __$$SharedGroupImplCopyWithImpl(
      _$SharedGroupImpl _value, $Res Function(_$SharedGroupImpl) _then)
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
    Object? allowedUid = null,
    Object? isSecret = null,
    Object? acceptedUid = null,
    Object? isDeleted = null,
    Object? lastAccessedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? syncStatus = null,
    Object? groupType = null,
    Object? parentGroupId = freezed,
    Object? childGroupIds = null,
    Object? memberPermissions = null,
    Object? defaultPermission = null,
    Object? inheritParentLists = null,
  }) {
    return _then(_$SharedGroupImpl(
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
              as List<SharedGroupMember>?,
      ownerMessage: freezed == ownerMessage
          ? _value.ownerMessage
          : ownerMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      allowedUid: null == allowedUid
          ? _value._allowedUid
          : allowedUid // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isSecret: null == isSecret
          ? _value.isSecret
          : isSecret // ignore: cast_nullable_to_non_nullable
              as bool,
      acceptedUid: null == acceptedUid
          ? _value._acceptedUid
          : acceptedUid // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      lastAccessedAt: freezed == lastAccessedAt
          ? _value.lastAccessedAt
          : lastAccessedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      groupType: null == groupType
          ? _value.groupType
          : groupType // ignore: cast_nullable_to_non_nullable
              as GroupType,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      childGroupIds: null == childGroupIds
          ? _value._childGroupIds
          : childGroupIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      memberPermissions: null == memberPermissions
          ? _value._memberPermissions
          : memberPermissions // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      defaultPermission: null == defaultPermission
          ? _value.defaultPermission
          : defaultPermission // ignore: cast_nullable_to_non_nullable
              as int,
      inheritParentLists: null == inheritParentLists
          ? _value.inheritParentLists
          : inheritParentLists // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SharedGroupImpl extends _SharedGroup {
  const _$SharedGroupImpl(
      {@HiveField(0) required this.groupName,
      @HiveField(1) required this.groupId,
      @HiveField(2) this.ownerName,
      @HiveField(3) this.ownerEmail,
      @HiveField(4) this.ownerUid,
      @HiveField(5) final List<SharedGroupMember>? members,
      @HiveField(6) this.ownerMessage,
      @HiveField(11) final List<String> allowedUid = const [],
      @HiveField(12) this.isSecret = false,
      @HiveField(13) final List<Map<String, String>> acceptedUid = const [],
      @HiveField(14) this.isDeleted = false,
      @HiveField(15) this.lastAccessedAt,
      @HiveField(16) this.createdAt,
      @HiveField(17) this.updatedAt,
      @HiveField(18) this.syncStatus = SyncStatus.synced,
      @HiveField(19) this.groupType = GroupType.shopping,
      @HiveField(20) this.parentGroupId,
      @HiveField(21) final List<String> childGroupIds = const [],
      @HiveField(22) final Map<String, int> memberPermissions = const {},
      @HiveField(23) this.defaultPermission = 0x03,
      @HiveField(24) this.inheritParentLists = true})
      : _members = members,
        _allowedUid = allowedUid,
        _acceptedUid = acceptedUid,
        _childGroupIds = childGroupIds,
        _memberPermissions = memberPermissions,
        super._();

  factory _$SharedGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$SharedGroupImplFromJson(json);

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
  final List<SharedGroupMember>? _members;
  @override
  @HiveField(5)
  List<SharedGroupMember>? get members {
    final value = _members;
    if (value == null) return null;
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @HiveField(6)
  final String? ownerMessage;
// @HiveField(7) @Default([]) List<String> sharedListIds, // サブコレクション化のため不要に
  final List<String> _allowedUid;
// @HiveField(7) @Default([]) List<String> sharedListIds, // サブコレクション化のため不要に
  @override
  @JsonKey()
  @HiveField(11)
  List<String> get allowedUid {
    if (_allowedUid is EqualUnmodifiableListView) return _allowedUid;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedUid);
  }

  @override
  @JsonKey()
  @HiveField(12)
  final bool isSecret;
// acceptedUid: [{uid: securityKey}] のような構造を想定
  final List<Map<String, String>> _acceptedUid;
// acceptedUid: [{uid: securityKey}] のような構造を想定
  @override
  @JsonKey()
  @HiveField(13)
  List<Map<String, String>> get acceptedUid {
    if (_acceptedUid is EqualUnmodifiableListView) return _acceptedUid;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_acceptedUid);
  }

// 削除フラグと最終アクセス日時
  @override
  @JsonKey()
  @HiveField(14)
  final bool isDeleted;
  @override
  @HiveField(15)
  final DateTime? lastAccessedAt;
  @override
  @HiveField(16)
  final DateTime? createdAt;
  @override
  @HiveField(17)
  final DateTime? updatedAt;
  @override
  @JsonKey()
  @HiveField(18)
  final SyncStatus syncStatus;
  @override
  @JsonKey()
  @HiveField(19)
  final GroupType groupType;
// グループタイプ追加
// 🆕 階層構造管理（HiveField 20-21）
  @override
  @HiveField(20)
  final String? parentGroupId;
// 親グループID
  final List<String> _childGroupIds;
// 親グループID
  @override
  @JsonKey()
  @HiveField(21)
  List<String> get childGroupIds {
    if (_childGroupIds is EqualUnmodifiableListView) return _childGroupIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_childGroupIds);
  }

// 子グループIDリスト
// 🆕 権限管理（HiveField 22-24）
  final Map<String, int> _memberPermissions;
// 子グループIDリスト
// 🆕 権限管理（HiveField 22-24）
  @override
  @JsonKey()
  @HiveField(22)
  Map<String, int> get memberPermissions {
    if (_memberPermissions is EqualUnmodifiableMapView)
      return _memberPermissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_memberPermissions);
  }

// userId → permission bits
  @override
  @JsonKey()
  @HiveField(23)
  final int defaultPermission;
// デフォルト権限（READ | DONE）
  @override
  @JsonKey()
  @HiveField(24)
  final bool inheritParentLists;

  @override
  String toString() {
    return 'SharedGroup(groupName: $groupName, groupId: $groupId, ownerName: $ownerName, ownerEmail: $ownerEmail, ownerUid: $ownerUid, members: $members, ownerMessage: $ownerMessage, allowedUid: $allowedUid, isSecret: $isSecret, acceptedUid: $acceptedUid, isDeleted: $isDeleted, lastAccessedAt: $lastAccessedAt, createdAt: $createdAt, updatedAt: $updatedAt, syncStatus: $syncStatus, groupType: $groupType, parentGroupId: $parentGroupId, childGroupIds: $childGroupIds, memberPermissions: $memberPermissions, defaultPermission: $defaultPermission, inheritParentLists: $inheritParentLists)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SharedGroupImpl &&
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
                .equals(other._allowedUid, _allowedUid) &&
            (identical(other.isSecret, isSecret) ||
                other.isSecret == isSecret) &&
            const DeepCollectionEquality()
                .equals(other._acceptedUid, _acceptedUid) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.lastAccessedAt, lastAccessedAt) ||
                other.lastAccessedAt == lastAccessedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.groupType, groupType) ||
                other.groupType == groupType) &&
            (identical(other.parentGroupId, parentGroupId) ||
                other.parentGroupId == parentGroupId) &&
            const DeepCollectionEquality()
                .equals(other._childGroupIds, _childGroupIds) &&
            const DeepCollectionEquality()
                .equals(other._memberPermissions, _memberPermissions) &&
            (identical(other.defaultPermission, defaultPermission) ||
                other.defaultPermission == defaultPermission) &&
            (identical(other.inheritParentLists, inheritParentLists) ||
                other.inheritParentLists == inheritParentLists));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        groupName,
        groupId,
        ownerName,
        ownerEmail,
        ownerUid,
        const DeepCollectionEquality().hash(_members),
        ownerMessage,
        const DeepCollectionEquality().hash(_allowedUid),
        isSecret,
        const DeepCollectionEquality().hash(_acceptedUid),
        isDeleted,
        lastAccessedAt,
        createdAt,
        updatedAt,
        syncStatus,
        groupType,
        parentGroupId,
        const DeepCollectionEquality().hash(_childGroupIds),
        const DeepCollectionEquality().hash(_memberPermissions),
        defaultPermission,
        inheritParentLists
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SharedGroupImplCopyWith<_$SharedGroupImpl> get copyWith =>
      __$$SharedGroupImplCopyWithImpl<_$SharedGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SharedGroupImplToJson(
      this,
    );
  }
}

abstract class _SharedGroup extends SharedGroup {
  const factory _SharedGroup(
      {@HiveField(0) required final String groupName,
      @HiveField(1) required final String groupId,
      @HiveField(2) final String? ownerName,
      @HiveField(3) final String? ownerEmail,
      @HiveField(4) final String? ownerUid,
      @HiveField(5) final List<SharedGroupMember>? members,
      @HiveField(6) final String? ownerMessage,
      @HiveField(11) final List<String> allowedUid,
      @HiveField(12) final bool isSecret,
      @HiveField(13) final List<Map<String, String>> acceptedUid,
      @HiveField(14) final bool isDeleted,
      @HiveField(15) final DateTime? lastAccessedAt,
      @HiveField(16) final DateTime? createdAt,
      @HiveField(17) final DateTime? updatedAt,
      @HiveField(18) final SyncStatus syncStatus,
      @HiveField(19) final GroupType groupType,
      @HiveField(20) final String? parentGroupId,
      @HiveField(21) final List<String> childGroupIds,
      @HiveField(22) final Map<String, int> memberPermissions,
      @HiveField(23) final int defaultPermission,
      @HiveField(24) final bool inheritParentLists}) = _$SharedGroupImpl;
  const _SharedGroup._() : super._();

  factory _SharedGroup.fromJson(Map<String, dynamic> json) =
      _$SharedGroupImpl.fromJson;

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
  List<SharedGroupMember>? get members;
  @override
  @HiveField(6)
  String? get ownerMessage;
  @override // @HiveField(7) @Default([]) List<String> sharedListIds, // サブコレクション化のため不要に
  @HiveField(11)
  List<String> get allowedUid;
  @override
  @HiveField(12)
  bool get isSecret;
  @override // acceptedUid: [{uid: securityKey}] のような構造を想定
  @HiveField(13)
  List<Map<String, String>> get acceptedUid;
  @override // 削除フラグと最終アクセス日時
  @HiveField(14)
  bool get isDeleted;
  @override
  @HiveField(15)
  DateTime? get lastAccessedAt;
  @override
  @HiveField(16)
  DateTime? get createdAt;
  @override
  @HiveField(17)
  DateTime? get updatedAt;
  @override
  @HiveField(18)
  SyncStatus get syncStatus;
  @override
  @HiveField(19)
  GroupType get groupType;
  @override // グループタイプ追加
// 🆕 階層構造管理（HiveField 20-21）
  @HiveField(20)
  String? get parentGroupId;
  @override // 親グループID
  @HiveField(21)
  List<String> get childGroupIds;
  @override // 子グループIDリスト
// 🆕 権限管理（HiveField 22-24）
  @HiveField(22)
  Map<String, int> get memberPermissions;
  @override // userId → permission bits
  @HiveField(23)
  int get defaultPermission;
  @override // デフォルト権限（READ | DONE）
  @HiveField(24)
  bool get inheritParentLists;
  @override
  @JsonKey(ignore: true)
  _$$SharedGroupImplCopyWith<_$SharedGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
