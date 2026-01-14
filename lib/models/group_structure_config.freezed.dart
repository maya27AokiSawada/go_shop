// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_structure_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GroupStructureConfig _$GroupStructureConfigFromJson(Map<String, dynamic> json) {
  return _GroupStructureConfig.fromJson(json);
}

/// @nodoc
mixin _$GroupStructureConfig {
  OrganizationConfig get organization => throw _privateConstructorUsedError;
  InheritanceRules? get inheritanceRules => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupStructureConfigCopyWith<GroupStructureConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupStructureConfigCopyWith<$Res> {
  factory $GroupStructureConfigCopyWith(GroupStructureConfig value,
          $Res Function(GroupStructureConfig) then) =
      _$GroupStructureConfigCopyWithImpl<$Res, GroupStructureConfig>;
  @useResult
  $Res call(
      {OrganizationConfig organization, InheritanceRules? inheritanceRules});

  $OrganizationConfigCopyWith<$Res> get organization;
  $InheritanceRulesCopyWith<$Res>? get inheritanceRules;
}

/// @nodoc
class _$GroupStructureConfigCopyWithImpl<$Res,
        $Val extends GroupStructureConfig>
    implements $GroupStructureConfigCopyWith<$Res> {
  _$GroupStructureConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? organization = null,
    Object? inheritanceRules = freezed,
  }) {
    return _then(_value.copyWith(
      organization: null == organization
          ? _value.organization
          : organization // ignore: cast_nullable_to_non_nullable
              as OrganizationConfig,
      inheritanceRules: freezed == inheritanceRules
          ? _value.inheritanceRules
          : inheritanceRules // ignore: cast_nullable_to_non_nullable
              as InheritanceRules?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $OrganizationConfigCopyWith<$Res> get organization {
    return $OrganizationConfigCopyWith<$Res>(_value.organization, (value) {
      return _then(_value.copyWith(organization: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $InheritanceRulesCopyWith<$Res>? get inheritanceRules {
    if (_value.inheritanceRules == null) {
      return null;
    }

    return $InheritanceRulesCopyWith<$Res>(_value.inheritanceRules!, (value) {
      return _then(_value.copyWith(inheritanceRules: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GroupStructureConfigImplCopyWith<$Res>
    implements $GroupStructureConfigCopyWith<$Res> {
  factory _$$GroupStructureConfigImplCopyWith(_$GroupStructureConfigImpl value,
          $Res Function(_$GroupStructureConfigImpl) then) =
      __$$GroupStructureConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {OrganizationConfig organization, InheritanceRules? inheritanceRules});

  @override
  $OrganizationConfigCopyWith<$Res> get organization;
  @override
  $InheritanceRulesCopyWith<$Res>? get inheritanceRules;
}

/// @nodoc
class __$$GroupStructureConfigImplCopyWithImpl<$Res>
    extends _$GroupStructureConfigCopyWithImpl<$Res, _$GroupStructureConfigImpl>
    implements _$$GroupStructureConfigImplCopyWith<$Res> {
  __$$GroupStructureConfigImplCopyWithImpl(_$GroupStructureConfigImpl _value,
      $Res Function(_$GroupStructureConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? organization = null,
    Object? inheritanceRules = freezed,
  }) {
    return _then(_$GroupStructureConfigImpl(
      organization: null == organization
          ? _value.organization
          : organization // ignore: cast_nullable_to_non_nullable
              as OrganizationConfig,
      inheritanceRules: freezed == inheritanceRules
          ? _value.inheritanceRules
          : inheritanceRules // ignore: cast_nullable_to_non_nullable
              as InheritanceRules?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupStructureConfigImpl implements _GroupStructureConfig {
  const _$GroupStructureConfigImpl(
      {required this.organization, this.inheritanceRules});

  factory _$GroupStructureConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupStructureConfigImplFromJson(json);

  @override
  final OrganizationConfig organization;
  @override
  final InheritanceRules? inheritanceRules;

  @override
  String toString() {
    return 'GroupStructureConfig(organization: $organization, inheritanceRules: $inheritanceRules)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupStructureConfigImpl &&
            (identical(other.organization, organization) ||
                other.organization == organization) &&
            (identical(other.inheritanceRules, inheritanceRules) ||
                other.inheritanceRules == inheritanceRules));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, organization, inheritanceRules);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupStructureConfigImplCopyWith<_$GroupStructureConfigImpl>
      get copyWith =>
          __$$GroupStructureConfigImplCopyWithImpl<_$GroupStructureConfigImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupStructureConfigImplToJson(
      this,
    );
  }
}

abstract class _GroupStructureConfig implements GroupStructureConfig {
  const factory _GroupStructureConfig(
      {required final OrganizationConfig organization,
      final InheritanceRules? inheritanceRules}) = _$GroupStructureConfigImpl;

  factory _GroupStructureConfig.fromJson(Map<String, dynamic> json) =
      _$GroupStructureConfigImpl.fromJson;

  @override
  OrganizationConfig get organization;
  @override
  InheritanceRules? get inheritanceRules;
  @override
  @JsonKey(ignore: true)
  _$$GroupStructureConfigImplCopyWith<_$GroupStructureConfigImpl>
      get copyWith => throw _privateConstructorUsedError;
}

OrganizationConfig _$OrganizationConfigFromJson(Map<String, dynamic> json) {
  return _OrganizationConfig.fromJson(json);
}

/// @nodoc
mixin _$OrganizationConfig {
  String get name => throw _privateConstructorUsedError;
  List<GroupConfig> get groups => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OrganizationConfigCopyWith<OrganizationConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrganizationConfigCopyWith<$Res> {
  factory $OrganizationConfigCopyWith(
          OrganizationConfig value, $Res Function(OrganizationConfig) then) =
      _$OrganizationConfigCopyWithImpl<$Res, OrganizationConfig>;
  @useResult
  $Res call({String name, List<GroupConfig> groups});
}

/// @nodoc
class _$OrganizationConfigCopyWithImpl<$Res, $Val extends OrganizationConfig>
    implements $OrganizationConfigCopyWith<$Res> {
  _$OrganizationConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? groups = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      groups: null == groups
          ? _value.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<GroupConfig>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrganizationConfigImplCopyWith<$Res>
    implements $OrganizationConfigCopyWith<$Res> {
  factory _$$OrganizationConfigImplCopyWith(_$OrganizationConfigImpl value,
          $Res Function(_$OrganizationConfigImpl) then) =
      __$$OrganizationConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, List<GroupConfig> groups});
}

/// @nodoc
class __$$OrganizationConfigImplCopyWithImpl<$Res>
    extends _$OrganizationConfigCopyWithImpl<$Res, _$OrganizationConfigImpl>
    implements _$$OrganizationConfigImplCopyWith<$Res> {
  __$$OrganizationConfigImplCopyWithImpl(_$OrganizationConfigImpl _value,
      $Res Function(_$OrganizationConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? groups = null,
  }) {
    return _then(_$OrganizationConfigImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      groups: null == groups
          ? _value._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<GroupConfig>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrganizationConfigImpl implements _OrganizationConfig {
  const _$OrganizationConfigImpl(
      {required this.name, required final List<GroupConfig> groups})
      : _groups = groups;

  factory _$OrganizationConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrganizationConfigImplFromJson(json);

  @override
  final String name;
  final List<GroupConfig> _groups;
  @override
  List<GroupConfig> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  @override
  String toString() {
    return 'OrganizationConfig(name: $name, groups: $groups)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrganizationConfigImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._groups, _groups));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, const DeepCollectionEquality().hash(_groups));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OrganizationConfigImplCopyWith<_$OrganizationConfigImpl> get copyWith =>
      __$$OrganizationConfigImplCopyWithImpl<_$OrganizationConfigImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrganizationConfigImplToJson(
      this,
    );
  }
}

abstract class _OrganizationConfig implements OrganizationConfig {
  const factory _OrganizationConfig(
      {required final String name,
      required final List<GroupConfig> groups}) = _$OrganizationConfigImpl;

  factory _OrganizationConfig.fromJson(Map<String, dynamic> json) =
      _$OrganizationConfigImpl.fromJson;

  @override
  String get name;
  @override
  List<GroupConfig> get groups;
  @override
  @JsonKey(ignore: true)
  _$$OrganizationConfigImplCopyWith<_$OrganizationConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupConfig _$GroupConfigFromJson(Map<String, dynamic> json) {
  return _GroupConfig.fromJson(json);
}

/// @nodoc
mixin _$GroupConfig {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parent => throw _privateConstructorUsedError;
  List<MemberConfig> get members => throw _privateConstructorUsedError;
  int get defaultPermission =>
      throw _privateConstructorUsedError; // READ | DONE
  List<ListConfig> get lists => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupConfigCopyWith<GroupConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupConfigCopyWith<$Res> {
  factory $GroupConfigCopyWith(
          GroupConfig value, $Res Function(GroupConfig) then) =
      _$GroupConfigCopyWithImpl<$Res, GroupConfig>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? parent,
      List<MemberConfig> members,
      int defaultPermission,
      List<ListConfig> lists});
}

/// @nodoc
class _$GroupConfigCopyWithImpl<$Res, $Val extends GroupConfig>
    implements $GroupConfigCopyWith<$Res> {
  _$GroupConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parent = freezed,
    Object? members = null,
    Object? defaultPermission = null,
    Object? lists = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parent: freezed == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as String?,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<MemberConfig>,
      defaultPermission: null == defaultPermission
          ? _value.defaultPermission
          : defaultPermission // ignore: cast_nullable_to_non_nullable
              as int,
      lists: null == lists
          ? _value.lists
          : lists // ignore: cast_nullable_to_non_nullable
              as List<ListConfig>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupConfigImplCopyWith<$Res>
    implements $GroupConfigCopyWith<$Res> {
  factory _$$GroupConfigImplCopyWith(
          _$GroupConfigImpl value, $Res Function(_$GroupConfigImpl) then) =
      __$$GroupConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? parent,
      List<MemberConfig> members,
      int defaultPermission,
      List<ListConfig> lists});
}

/// @nodoc
class __$$GroupConfigImplCopyWithImpl<$Res>
    extends _$GroupConfigCopyWithImpl<$Res, _$GroupConfigImpl>
    implements _$$GroupConfigImplCopyWith<$Res> {
  __$$GroupConfigImplCopyWithImpl(
      _$GroupConfigImpl _value, $Res Function(_$GroupConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parent = freezed,
    Object? members = null,
    Object? defaultPermission = null,
    Object? lists = null,
  }) {
    return _then(_$GroupConfigImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parent: freezed == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as String?,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<MemberConfig>,
      defaultPermission: null == defaultPermission
          ? _value.defaultPermission
          : defaultPermission // ignore: cast_nullable_to_non_nullable
              as int,
      lists: null == lists
          ? _value._lists
          : lists // ignore: cast_nullable_to_non_nullable
              as List<ListConfig>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupConfigImpl implements _GroupConfig {
  const _$GroupConfigImpl(
      {required this.id,
      required this.name,
      this.parent,
      required final List<MemberConfig> members,
      this.defaultPermission = 0x03,
      final List<ListConfig> lists = const []})
      : _members = members,
        _lists = lists;

  factory _$GroupConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupConfigImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parent;
  final List<MemberConfig> _members;
  @override
  List<MemberConfig> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  @JsonKey()
  final int defaultPermission;
// READ | DONE
  final List<ListConfig> _lists;
// READ | DONE
  @override
  @JsonKey()
  List<ListConfig> get lists {
    if (_lists is EqualUnmodifiableListView) return _lists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lists);
  }

  @override
  String toString() {
    return 'GroupConfig(id: $id, name: $name, parent: $parent, members: $members, defaultPermission: $defaultPermission, lists: $lists)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupConfigImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parent, parent) || other.parent == parent) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.defaultPermission, defaultPermission) ||
                other.defaultPermission == defaultPermission) &&
            const DeepCollectionEquality().equals(other._lists, _lists));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      parent,
      const DeepCollectionEquality().hash(_members),
      defaultPermission,
      const DeepCollectionEquality().hash(_lists));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupConfigImplCopyWith<_$GroupConfigImpl> get copyWith =>
      __$$GroupConfigImplCopyWithImpl<_$GroupConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupConfigImplToJson(
      this,
    );
  }
}

abstract class _GroupConfig implements GroupConfig {
  const factory _GroupConfig(
      {required final String id,
      required final String name,
      final String? parent,
      required final List<MemberConfig> members,
      final int defaultPermission,
      final List<ListConfig> lists}) = _$GroupConfigImpl;

  factory _GroupConfig.fromJson(Map<String, dynamic> json) =
      _$GroupConfigImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parent;
  @override
  List<MemberConfig> get members;
  @override
  int get defaultPermission;
  @override // READ | DONE
  List<ListConfig> get lists;
  @override
  @JsonKey(ignore: true)
  _$$GroupConfigImplCopyWith<_$GroupConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemberConfig _$MemberConfigFromJson(Map<String, dynamic> json) {
  return _MemberConfig.fromJson(json);
}

/// @nodoc
mixin _$MemberConfig {
  String get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get permission => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemberConfigCopyWith<MemberConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemberConfigCopyWith<$Res> {
  factory $MemberConfigCopyWith(
          MemberConfig value, $Res Function(MemberConfig) then) =
      _$MemberConfigCopyWithImpl<$Res, MemberConfig>;
  @useResult
  $Res call({String uid, String name, int permission});
}

/// @nodoc
class _$MemberConfigCopyWithImpl<$Res, $Val extends MemberConfig>
    implements $MemberConfigCopyWith<$Res> {
  _$MemberConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? permission = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      permission: null == permission
          ? _value.permission
          : permission // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemberConfigImplCopyWith<$Res>
    implements $MemberConfigCopyWith<$Res> {
  factory _$$MemberConfigImplCopyWith(
          _$MemberConfigImpl value, $Res Function(_$MemberConfigImpl) then) =
      __$$MemberConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String uid, String name, int permission});
}

/// @nodoc
class __$$MemberConfigImplCopyWithImpl<$Res>
    extends _$MemberConfigCopyWithImpl<$Res, _$MemberConfigImpl>
    implements _$$MemberConfigImplCopyWith<$Res> {
  __$$MemberConfigImplCopyWithImpl(
      _$MemberConfigImpl _value, $Res Function(_$MemberConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? permission = null,
  }) {
    return _then(_$MemberConfigImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      permission: null == permission
          ? _value.permission
          : permission // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemberConfigImpl implements _MemberConfig {
  const _$MemberConfigImpl(
      {required this.uid, required this.name, this.permission = 0x03});

  factory _$MemberConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemberConfigImplFromJson(json);

  @override
  final String uid;
  @override
  final String name;
  @override
  @JsonKey()
  final int permission;

  @override
  String toString() {
    return 'MemberConfig(uid: $uid, name: $name, permission: $permission)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemberConfigImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.permission, permission) ||
                other.permission == permission));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, uid, name, permission);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemberConfigImplCopyWith<_$MemberConfigImpl> get copyWith =>
      __$$MemberConfigImplCopyWithImpl<_$MemberConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemberConfigImplToJson(
      this,
    );
  }
}

abstract class _MemberConfig implements MemberConfig {
  const factory _MemberConfig(
      {required final String uid,
      required final String name,
      final int permission}) = _$MemberConfigImpl;

  factory _MemberConfig.fromJson(Map<String, dynamic> json) =
      _$MemberConfigImpl.fromJson;

  @override
  String get uid;
  @override
  String get name;
  @override
  int get permission;
  @override
  @JsonKey(ignore: true)
  _$$MemberConfigImplCopyWith<_$MemberConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ListConfig _$ListConfigFromJson(Map<String, dynamic> json) {
  return _ListConfig.fromJson(json);
}

/// @nodoc
mixin _$ListConfig {
  String get name => throw _privateConstructorUsedError;
  List<ItemConfig> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ListConfigCopyWith<ListConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ListConfigCopyWith<$Res> {
  factory $ListConfigCopyWith(
          ListConfig value, $Res Function(ListConfig) then) =
      _$ListConfigCopyWithImpl<$Res, ListConfig>;
  @useResult
  $Res call({String name, List<ItemConfig> items});
}

/// @nodoc
class _$ListConfigCopyWithImpl<$Res, $Val extends ListConfig>
    implements $ListConfigCopyWith<$Res> {
  _$ListConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemConfig>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ListConfigImplCopyWith<$Res>
    implements $ListConfigCopyWith<$Res> {
  factory _$$ListConfigImplCopyWith(
          _$ListConfigImpl value, $Res Function(_$ListConfigImpl) then) =
      __$$ListConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, List<ItemConfig> items});
}

/// @nodoc
class __$$ListConfigImplCopyWithImpl<$Res>
    extends _$ListConfigCopyWithImpl<$Res, _$ListConfigImpl>
    implements _$$ListConfigImplCopyWith<$Res> {
  __$$ListConfigImplCopyWithImpl(
      _$ListConfigImpl _value, $Res Function(_$ListConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? items = null,
  }) {
    return _then(_$ListConfigImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemConfig>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ListConfigImpl implements _ListConfig {
  const _$ListConfigImpl(
      {required this.name, final List<ItemConfig> items = const []})
      : _items = items;

  factory _$ListConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ListConfigImplFromJson(json);

  @override
  final String name;
  final List<ItemConfig> _items;
  @override
  @JsonKey()
  List<ItemConfig> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'ListConfig(name: $name, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListConfigImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ListConfigImplCopyWith<_$ListConfigImpl> get copyWith =>
      __$$ListConfigImplCopyWithImpl<_$ListConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ListConfigImplToJson(
      this,
    );
  }
}

abstract class _ListConfig implements ListConfig {
  const factory _ListConfig(
      {required final String name,
      final List<ItemConfig> items}) = _$ListConfigImpl;

  factory _ListConfig.fromJson(Map<String, dynamic> json) =
      _$ListConfigImpl.fromJson;

  @override
  String get name;
  @override
  List<ItemConfig> get items;
  @override
  @JsonKey(ignore: true)
  _$$ListConfigImplCopyWith<_$ListConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemConfig _$ItemConfigFromJson(Map<String, dynamic> json) {
  return _ItemConfig.fromJson(json);
}

/// @nodoc
mixin _$ItemConfig {
  String get name => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemConfigCopyWith<ItemConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemConfigCopyWith<$Res> {
  factory $ItemConfigCopyWith(
          ItemConfig value, $Res Function(ItemConfig) then) =
      _$ItemConfigCopyWithImpl<$Res, ItemConfig>;
  @useResult
  $Res call({String name, int quantity, String? note});
}

/// @nodoc
class _$ItemConfigCopyWithImpl<$Res, $Val extends ItemConfig>
    implements $ItemConfigCopyWith<$Res> {
  _$ItemConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? quantity = null,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemConfigImplCopyWith<$Res>
    implements $ItemConfigCopyWith<$Res> {
  factory _$$ItemConfigImplCopyWith(
          _$ItemConfigImpl value, $Res Function(_$ItemConfigImpl) then) =
      __$$ItemConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int quantity, String? note});
}

/// @nodoc
class __$$ItemConfigImplCopyWithImpl<$Res>
    extends _$ItemConfigCopyWithImpl<$Res, _$ItemConfigImpl>
    implements _$$ItemConfigImplCopyWith<$Res> {
  __$$ItemConfigImplCopyWithImpl(
      _$ItemConfigImpl _value, $Res Function(_$ItemConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? quantity = null,
    Object? note = freezed,
  }) {
    return _then(_$ItemConfigImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemConfigImpl implements _ItemConfig {
  const _$ItemConfigImpl({required this.name, this.quantity = 1, this.note});

  factory _$ItemConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemConfigImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final int quantity;
  @override
  final String? note;

  @override
  String toString() {
    return 'ItemConfig(name: $name, quantity: $quantity, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemConfigImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, quantity, note);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemConfigImplCopyWith<_$ItemConfigImpl> get copyWith =>
      __$$ItemConfigImplCopyWithImpl<_$ItemConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemConfigImplToJson(
      this,
    );
  }
}

abstract class _ItemConfig implements ItemConfig {
  const factory _ItemConfig(
      {required final String name,
      final int quantity,
      final String? note}) = _$ItemConfigImpl;

  factory _ItemConfig.fromJson(Map<String, dynamic> json) =
      _$ItemConfigImpl.fromJson;

  @override
  String get name;
  @override
  int get quantity;
  @override
  String? get note;
  @override
  @JsonKey(ignore: true)
  _$$ItemConfigImplCopyWith<_$ItemConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InheritanceRules _$InheritanceRulesFromJson(Map<String, dynamic> json) {
  return _InheritanceRules.fromJson(json);
}

/// @nodoc
mixin _$InheritanceRules {
  String get parentToChild =>
      throw _privateConstructorUsedError; // read_only, full_access, no_access
  String get childToParent => throw _privateConstructorUsedError;
  String get sibling => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InheritanceRulesCopyWith<InheritanceRules> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InheritanceRulesCopyWith<$Res> {
  factory $InheritanceRulesCopyWith(
          InheritanceRules value, $Res Function(InheritanceRules) then) =
      _$InheritanceRulesCopyWithImpl<$Res, InheritanceRules>;
  @useResult
  $Res call({String parentToChild, String childToParent, String sibling});
}

/// @nodoc
class _$InheritanceRulesCopyWithImpl<$Res, $Val extends InheritanceRules>
    implements $InheritanceRulesCopyWith<$Res> {
  _$InheritanceRulesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parentToChild = null,
    Object? childToParent = null,
    Object? sibling = null,
  }) {
    return _then(_value.copyWith(
      parentToChild: null == parentToChild
          ? _value.parentToChild
          : parentToChild // ignore: cast_nullable_to_non_nullable
              as String,
      childToParent: null == childToParent
          ? _value.childToParent
          : childToParent // ignore: cast_nullable_to_non_nullable
              as String,
      sibling: null == sibling
          ? _value.sibling
          : sibling // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InheritanceRulesImplCopyWith<$Res>
    implements $InheritanceRulesCopyWith<$Res> {
  factory _$$InheritanceRulesImplCopyWith(_$InheritanceRulesImpl value,
          $Res Function(_$InheritanceRulesImpl) then) =
      __$$InheritanceRulesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String parentToChild, String childToParent, String sibling});
}

/// @nodoc
class __$$InheritanceRulesImplCopyWithImpl<$Res>
    extends _$InheritanceRulesCopyWithImpl<$Res, _$InheritanceRulesImpl>
    implements _$$InheritanceRulesImplCopyWith<$Res> {
  __$$InheritanceRulesImplCopyWithImpl(_$InheritanceRulesImpl _value,
      $Res Function(_$InheritanceRulesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parentToChild = null,
    Object? childToParent = null,
    Object? sibling = null,
  }) {
    return _then(_$InheritanceRulesImpl(
      parentToChild: null == parentToChild
          ? _value.parentToChild
          : parentToChild // ignore: cast_nullable_to_non_nullable
              as String,
      childToParent: null == childToParent
          ? _value.childToParent
          : childToParent // ignore: cast_nullable_to_non_nullable
              as String,
      sibling: null == sibling
          ? _value.sibling
          : sibling // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InheritanceRulesImpl implements _InheritanceRules {
  const _$InheritanceRulesImpl(
      {this.parentToChild = 'read_only',
      this.childToParent = 'no_access',
      this.sibling = 'no_access'});

  factory _$InheritanceRulesImpl.fromJson(Map<String, dynamic> json) =>
      _$$InheritanceRulesImplFromJson(json);

  @override
  @JsonKey()
  final String parentToChild;
// read_only, full_access, no_access
  @override
  @JsonKey()
  final String childToParent;
  @override
  @JsonKey()
  final String sibling;

  @override
  String toString() {
    return 'InheritanceRules(parentToChild: $parentToChild, childToParent: $childToParent, sibling: $sibling)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InheritanceRulesImpl &&
            (identical(other.parentToChild, parentToChild) ||
                other.parentToChild == parentToChild) &&
            (identical(other.childToParent, childToParent) ||
                other.childToParent == childToParent) &&
            (identical(other.sibling, sibling) || other.sibling == sibling));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, parentToChild, childToParent, sibling);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InheritanceRulesImplCopyWith<_$InheritanceRulesImpl> get copyWith =>
      __$$InheritanceRulesImplCopyWithImpl<_$InheritanceRulesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InheritanceRulesImplToJson(
      this,
    );
  }
}

abstract class _InheritanceRules implements InheritanceRules {
  const factory _InheritanceRules(
      {final String parentToChild,
      final String childToParent,
      final String sibling}) = _$InheritanceRulesImpl;

  factory _InheritanceRules.fromJson(Map<String, dynamic> json) =
      _$InheritanceRulesImpl.fromJson;

  @override
  String get parentToChild;
  @override // read_only, full_access, no_access
  String get childToParent;
  @override
  String get sibling;
  @override
  @JsonKey(ignore: true)
  _$$InheritanceRulesImplCopyWith<_$InheritanceRulesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
