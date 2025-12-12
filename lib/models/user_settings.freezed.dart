// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  @HiveField(0)
  String get userName => throw _privateConstructorUsedError;
  @HiveField(1)
  String get lastUsedGroupId =>
      throw _privateConstructorUsedError; // 空文字列で初期化、グループリストから自動選択
  @HiveField(2)
  String get lastUsedSharedListId => throw _privateConstructorUsedError;
  @HiveField(3)
  String get userId => throw _privateConstructorUsedError;
  @HiveField(4)
  String get userEmail => throw _privateConstructorUsedError; // メールアドレスフィールドを追加
  @HiveField(5)
  int get appMode => throw _privateConstructorUsedError; // 0=shopping, 1=todo
  @HiveField(6)
  bool get enableListNotifications => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
          UserSettings value, $Res Function(UserSettings) then) =
      _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call(
      {@HiveField(0) String userName,
      @HiveField(1) String lastUsedGroupId,
      @HiveField(2) String lastUsedSharedListId,
      @HiveField(3) String userId,
      @HiveField(4) String userEmail,
      @HiveField(5) int appMode,
      @HiveField(6) bool enableListNotifications});
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userName = null,
    Object? lastUsedGroupId = null,
    Object? lastUsedSharedListId = null,
    Object? userId = null,
    Object? userEmail = null,
    Object? appMode = null,
    Object? enableListNotifications = null,
  }) {
    return _then(_value.copyWith(
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsedGroupId: null == lastUsedGroupId
          ? _value.lastUsedGroupId
          : lastUsedGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsedSharedListId: null == lastUsedSharedListId
          ? _value.lastUsedSharedListId
          : lastUsedSharedListId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userEmail: null == userEmail
          ? _value.userEmail
          : userEmail // ignore: cast_nullable_to_non_nullable
              as String,
      appMode: null == appMode
          ? _value.appMode
          : appMode // ignore: cast_nullable_to_non_nullable
              as int,
      enableListNotifications: null == enableListNotifications
          ? _value.enableListNotifications
          : enableListNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
          _$UserSettingsImpl value, $Res Function(_$UserSettingsImpl) then) =
      __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String userName,
      @HiveField(1) String lastUsedGroupId,
      @HiveField(2) String lastUsedSharedListId,
      @HiveField(3) String userId,
      @HiveField(4) String userEmail,
      @HiveField(5) int appMode,
      @HiveField(6) bool enableListNotifications});
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
      _$UserSettingsImpl _value, $Res Function(_$UserSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userName = null,
    Object? lastUsedGroupId = null,
    Object? lastUsedSharedListId = null,
    Object? userId = null,
    Object? userEmail = null,
    Object? appMode = null,
    Object? enableListNotifications = null,
  }) {
    return _then(_$UserSettingsImpl(
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsedGroupId: null == lastUsedGroupId
          ? _value.lastUsedGroupId
          : lastUsedGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsedSharedListId: null == lastUsedSharedListId
          ? _value.lastUsedSharedListId
          : lastUsedSharedListId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userEmail: null == userEmail
          ? _value.userEmail
          : userEmail // ignore: cast_nullable_to_non_nullable
              as String,
      appMode: null == appMode
          ? _value.appMode
          : appMode // ignore: cast_nullable_to_non_nullable
              as int,
      enableListNotifications: null == enableListNotifications
          ? _value.enableListNotifications
          : enableListNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl(
      {@HiveField(0) this.userName = '',
      @HiveField(1) this.lastUsedGroupId = '',
      @HiveField(2) this.lastUsedSharedListId = '',
      @HiveField(3) this.userId = '',
      @HiveField(4) this.userEmail = '',
      @HiveField(5) this.appMode = 0,
      @HiveField(6) this.enableListNotifications = true});

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  @override
  @JsonKey()
  @HiveField(0)
  final String userName;
  @override
  @JsonKey()
  @HiveField(1)
  final String lastUsedGroupId;
// 空文字列で初期化、グループリストから自動選択
  @override
  @JsonKey()
  @HiveField(2)
  final String lastUsedSharedListId;
  @override
  @JsonKey()
  @HiveField(3)
  final String userId;
  @override
  @JsonKey()
  @HiveField(4)
  final String userEmail;
// メールアドレスフィールドを追加
  @override
  @JsonKey()
  @HiveField(5)
  final int appMode;
// 0=shopping, 1=todo
  @override
  @JsonKey()
  @HiveField(6)
  final bool enableListNotifications;

  @override
  String toString() {
    return 'UserSettings(userName: $userName, lastUsedGroupId: $lastUsedGroupId, lastUsedSharedListId: $lastUsedSharedListId, userId: $userId, userEmail: $userEmail, appMode: $appMode, enableListNotifications: $enableListNotifications)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.lastUsedGroupId, lastUsedGroupId) ||
                other.lastUsedGroupId == lastUsedGroupId) &&
            (identical(other.lastUsedSharedListId, lastUsedSharedListId) ||
                other.lastUsedSharedListId == lastUsedSharedListId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail) &&
            (identical(other.appMode, appMode) || other.appMode == appMode) &&
            (identical(
                    other.enableListNotifications, enableListNotifications) ||
                other.enableListNotifications == enableListNotifications));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userName,
      lastUsedGroupId,
      lastUsedSharedListId,
      userId,
      userEmail,
      appMode,
      enableListNotifications);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(
      this,
    );
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings(
      {@HiveField(0) final String userName,
      @HiveField(1) final String lastUsedGroupId,
      @HiveField(2) final String lastUsedSharedListId,
      @HiveField(3) final String userId,
      @HiveField(4) final String userEmail,
      @HiveField(5) final int appMode,
      @HiveField(6) final bool enableListNotifications}) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override
  @HiveField(0)
  String get userName;
  @override
  @HiveField(1)
  String get lastUsedGroupId;
  @override // 空文字列で初期化、グループリストから自動選択
  @HiveField(2)
  String get lastUsedSharedListId;
  @override
  @HiveField(3)
  String get userId;
  @override
  @HiveField(4)
  String get userEmail;
  @override // メールアドレスフィールドを追加
  @HiveField(5)
  int get appMode;
  @override // 0=shopping, 1=todo
  @HiveField(6)
  bool get enableListNotifications;
  @override
  @JsonKey(ignore: true)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
