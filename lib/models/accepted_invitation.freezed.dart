// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accepted_invitation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AcceptedInvitation _$AcceptedInvitationFromJson(Map<String, dynamic> json) {
  return _AcceptedInvitation.fromJson(json);
}

/// @nodoc
mixin _$AcceptedInvitation {
  @HiveField(0)
  String get acceptorUid => throw _privateConstructorUsedError; // 受諾者のUID
  @HiveField(1)
  String get acceptorEmail => throw _privateConstructorUsedError; // 受諾者のメール
  @HiveField(2)
  String get acceptorName => throw _privateConstructorUsedError; // 受諾者の表示名
  @HiveField(3)
  String get SharedGroupId =>
      throw _privateConstructorUsedError; // 対象SharedGroupのID
  @HiveField(4)
  String get shoppingListId =>
      throw _privateConstructorUsedError; // 対象ShoppingListのID
  @HiveField(5)
  String get inviteRole =>
      throw _privateConstructorUsedError; // 招待時のロール（member/manager）
  @HiveField(6)
  DateTime get acceptedAt => throw _privateConstructorUsedError; // 受諾日時
  @HiveField(7)
  bool get isProcessed => throw _privateConstructorUsedError; // 招待元が処理済みかフラグ
  @HiveField(8)
  DateTime? get processedAt => throw _privateConstructorUsedError; // 処理済み日時
  @HiveField(9)
  String? get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AcceptedInvitationCopyWith<AcceptedInvitation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AcceptedInvitationCopyWith<$Res> {
  factory $AcceptedInvitationCopyWith(
          AcceptedInvitation value, $Res Function(AcceptedInvitation) then) =
      _$AcceptedInvitationCopyWithImpl<$Res, AcceptedInvitation>;
  @useResult
  $Res call(
      {@HiveField(0) String acceptorUid,
      @HiveField(1) String acceptorEmail,
      @HiveField(2) String acceptorName,
      @HiveField(3) String SharedGroupId,
      @HiveField(4) String shoppingListId,
      @HiveField(5) String inviteRole,
      @HiveField(6) DateTime acceptedAt,
      @HiveField(7) bool isProcessed,
      @HiveField(8) DateTime? processedAt,
      @HiveField(9) String? notes});
}

/// @nodoc
class _$AcceptedInvitationCopyWithImpl<$Res, $Val extends AcceptedInvitation>
    implements $AcceptedInvitationCopyWith<$Res> {
  _$AcceptedInvitationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? acceptorUid = null,
    Object? acceptorEmail = null,
    Object? acceptorName = null,
    Object? SharedGroupId = null,
    Object? shoppingListId = null,
    Object? inviteRole = null,
    Object? acceptedAt = null,
    Object? isProcessed = null,
    Object? processedAt = freezed,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      acceptorUid: null == acceptorUid
          ? _value.acceptorUid
          : acceptorUid // ignore: cast_nullable_to_non_nullable
              as String,
      acceptorEmail: null == acceptorEmail
          ? _value.acceptorEmail
          : acceptorEmail // ignore: cast_nullable_to_non_nullable
              as String,
      acceptorName: null == acceptorName
          ? _value.acceptorName
          : acceptorName // ignore: cast_nullable_to_non_nullable
              as String,
      SharedGroupId: null == SharedGroupId
          ? _value.SharedGroupId
          : SharedGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      shoppingListId: null == shoppingListId
          ? _value.shoppingListId
          : shoppingListId // ignore: cast_nullable_to_non_nullable
              as String,
      inviteRole: null == inviteRole
          ? _value.inviteRole
          : inviteRole // ignore: cast_nullable_to_non_nullable
              as String,
      acceptedAt: null == acceptedAt
          ? _value.acceptedAt
          : acceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isProcessed: null == isProcessed
          ? _value.isProcessed
          : isProcessed // ignore: cast_nullable_to_non_nullable
              as bool,
      processedAt: freezed == processedAt
          ? _value.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AcceptedInvitationImplCopyWith<$Res>
    implements $AcceptedInvitationCopyWith<$Res> {
  factory _$$AcceptedInvitationImplCopyWith(_$AcceptedInvitationImpl value,
          $Res Function(_$AcceptedInvitationImpl) then) =
      __$$AcceptedInvitationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String acceptorUid,
      @HiveField(1) String acceptorEmail,
      @HiveField(2) String acceptorName,
      @HiveField(3) String SharedGroupId,
      @HiveField(4) String shoppingListId,
      @HiveField(5) String inviteRole,
      @HiveField(6) DateTime acceptedAt,
      @HiveField(7) bool isProcessed,
      @HiveField(8) DateTime? processedAt,
      @HiveField(9) String? notes});
}

/// @nodoc
class __$$AcceptedInvitationImplCopyWithImpl<$Res>
    extends _$AcceptedInvitationCopyWithImpl<$Res, _$AcceptedInvitationImpl>
    implements _$$AcceptedInvitationImplCopyWith<$Res> {
  __$$AcceptedInvitationImplCopyWithImpl(_$AcceptedInvitationImpl _value,
      $Res Function(_$AcceptedInvitationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? acceptorUid = null,
    Object? acceptorEmail = null,
    Object? acceptorName = null,
    Object? SharedGroupId = null,
    Object? shoppingListId = null,
    Object? inviteRole = null,
    Object? acceptedAt = null,
    Object? isProcessed = null,
    Object? processedAt = freezed,
    Object? notes = freezed,
  }) {
    return _then(_$AcceptedInvitationImpl(
      acceptorUid: null == acceptorUid
          ? _value.acceptorUid
          : acceptorUid // ignore: cast_nullable_to_non_nullable
              as String,
      acceptorEmail: null == acceptorEmail
          ? _value.acceptorEmail
          : acceptorEmail // ignore: cast_nullable_to_non_nullable
              as String,
      acceptorName: null == acceptorName
          ? _value.acceptorName
          : acceptorName // ignore: cast_nullable_to_non_nullable
              as String,
      SharedGroupId: null == SharedGroupId
          ? _value.SharedGroupId
          : SharedGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      shoppingListId: null == shoppingListId
          ? _value.shoppingListId
          : shoppingListId // ignore: cast_nullable_to_non_nullable
              as String,
      inviteRole: null == inviteRole
          ? _value.inviteRole
          : inviteRole // ignore: cast_nullable_to_non_nullable
              as String,
      acceptedAt: null == acceptedAt
          ? _value.acceptedAt
          : acceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isProcessed: null == isProcessed
          ? _value.isProcessed
          : isProcessed // ignore: cast_nullable_to_non_nullable
              as bool,
      processedAt: freezed == processedAt
          ? _value.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AcceptedInvitationImpl implements _AcceptedInvitation {
  const _$AcceptedInvitationImpl(
      {@HiveField(0) required this.acceptorUid,
      @HiveField(1) required this.acceptorEmail,
      @HiveField(2) required this.acceptorName,
      @HiveField(3) required this.SharedGroupId,
      @HiveField(4) required this.shoppingListId,
      @HiveField(5) required this.inviteRole,
      @HiveField(6) required this.acceptedAt,
      @HiveField(7) this.isProcessed = false,
      @HiveField(8) this.processedAt,
      @HiveField(9) this.notes});

  factory _$AcceptedInvitationImpl.fromJson(Map<String, dynamic> json) =>
      _$$AcceptedInvitationImplFromJson(json);

  @override
  @HiveField(0)
  final String acceptorUid;
// 受諾者のUID
  @override
  @HiveField(1)
  final String acceptorEmail;
// 受諾者のメール
  @override
  @HiveField(2)
  final String acceptorName;
// 受諾者の表示名
  @override
  @HiveField(3)
  final String SharedGroupId;
// 対象SharedGroupのID
  @override
  @HiveField(4)
  final String shoppingListId;
// 対象ShoppingListのID
  @override
  @HiveField(5)
  final String inviteRole;
// 招待時のロール（member/manager）
  @override
  @HiveField(6)
  final DateTime acceptedAt;
// 受諾日時
  @override
  @JsonKey()
  @HiveField(7)
  final bool isProcessed;
// 招待元が処理済みかフラグ
  @override
  @HiveField(8)
  final DateTime? processedAt;
// 処理済み日時
  @override
  @HiveField(9)
  final String? notes;

  @override
  String toString() {
    return 'AcceptedInvitation(acceptorUid: $acceptorUid, acceptorEmail: $acceptorEmail, acceptorName: $acceptorName, SharedGroupId: $SharedGroupId, shoppingListId: $shoppingListId, inviteRole: $inviteRole, acceptedAt: $acceptedAt, isProcessed: $isProcessed, processedAt: $processedAt, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AcceptedInvitationImpl &&
            (identical(other.acceptorUid, acceptorUid) ||
                other.acceptorUid == acceptorUid) &&
            (identical(other.acceptorEmail, acceptorEmail) ||
                other.acceptorEmail == acceptorEmail) &&
            (identical(other.acceptorName, acceptorName) ||
                other.acceptorName == acceptorName) &&
            (identical(other.SharedGroupId, SharedGroupId) ||
                other.SharedGroupId == SharedGroupId) &&
            (identical(other.shoppingListId, shoppingListId) ||
                other.shoppingListId == shoppingListId) &&
            (identical(other.inviteRole, inviteRole) ||
                other.inviteRole == inviteRole) &&
            (identical(other.acceptedAt, acceptedAt) ||
                other.acceptedAt == acceptedAt) &&
            (identical(other.isProcessed, isProcessed) ||
                other.isProcessed == isProcessed) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      acceptorUid,
      acceptorEmail,
      acceptorName,
      SharedGroupId,
      shoppingListId,
      inviteRole,
      acceptedAt,
      isProcessed,
      processedAt,
      notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AcceptedInvitationImplCopyWith<_$AcceptedInvitationImpl> get copyWith =>
      __$$AcceptedInvitationImplCopyWithImpl<_$AcceptedInvitationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AcceptedInvitationImplToJson(
      this,
    );
  }
}

abstract class _AcceptedInvitation implements AcceptedInvitation {
  const factory _AcceptedInvitation(
      {@HiveField(0) required final String acceptorUid,
      @HiveField(1) required final String acceptorEmail,
      @HiveField(2) required final String acceptorName,
      @HiveField(3) required final String SharedGroupId,
      @HiveField(4) required final String shoppingListId,
      @HiveField(5) required final String inviteRole,
      @HiveField(6) required final DateTime acceptedAt,
      @HiveField(7) final bool isProcessed,
      @HiveField(8) final DateTime? processedAt,
      @HiveField(9) final String? notes}) = _$AcceptedInvitationImpl;

  factory _AcceptedInvitation.fromJson(Map<String, dynamic> json) =
      _$AcceptedInvitationImpl.fromJson;

  @override
  @HiveField(0)
  String get acceptorUid;
  @override // 受諾者のUID
  @HiveField(1)
  String get acceptorEmail;
  @override // 受諾者のメール
  @HiveField(2)
  String get acceptorName;
  @override // 受諾者の表示名
  @HiveField(3)
  String get SharedGroupId;
  @override // 対象SharedGroupのID
  @HiveField(4)
  String get shoppingListId;
  @override // 対象ShoppingListのID
  @HiveField(5)
  String get inviteRole;
  @override // 招待時のロール（member/manager）
  @HiveField(6)
  DateTime get acceptedAt;
  @override // 受諾日時
  @HiveField(7)
  bool get isProcessed;
  @override // 招待元が処理済みかフラグ
  @HiveField(8)
  DateTime? get processedAt;
  @override // 処理済み日時
  @HiveField(9)
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$AcceptedInvitationImplCopyWith<_$AcceptedInvitationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
