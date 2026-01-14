import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_structure_config.freezed.dart';
part 'group_structure_config.g.dart';

/// 組織構造設定ファイルのデータモデル
@freezed
class GroupStructureConfig with _$GroupStructureConfig {
  const factory GroupStructureConfig({
    required OrganizationConfig organization,
    InheritanceRules? inheritanceRules,
  }) = _GroupStructureConfig;

  factory GroupStructureConfig.fromJson(Map<String, dynamic> json) =>
      _$GroupStructureConfigFromJson(json);
}

/// 組織設定
@freezed
class OrganizationConfig with _$OrganizationConfig {
  const factory OrganizationConfig({
    required String name,
    required List<GroupConfig> groups,
  }) = _OrganizationConfig;

  factory OrganizationConfig.fromJson(Map<String, dynamic> json) =>
      _$OrganizationConfigFromJson(json);
}

/// グループ設定
@freezed
class GroupConfig with _$GroupConfig {
  const factory GroupConfig({
    required String id,
    required String name,
    String? parent,
    required List<MemberConfig> members,
    @Default(0x03) int defaultPermission, // READ | DONE
    @Default([]) List<ListConfig> lists,
  }) = _GroupConfig;

  factory GroupConfig.fromJson(Map<String, dynamic> json) =>
      _$GroupConfigFromJson(json);
}

/// メンバー設定
@freezed
class MemberConfig with _$MemberConfig {
  const factory MemberConfig({
    required String uid,
    required String name,
    @Default(0x03) int permission, // デフォルトはVIEWER
  }) = _MemberConfig;

  factory MemberConfig.fromJson(Map<String, dynamic> json) =>
      _$MemberConfigFromJson(json);
}

/// リスト設定
@freezed
class ListConfig with _$ListConfig {
  const factory ListConfig({
    required String name,
    @Default([]) List<ItemConfig> items,
  }) = _ListConfig;

  factory ListConfig.fromJson(Map<String, dynamic> json) =>
      _$ListConfigFromJson(json);
}

/// アイテム設定
@freezed
class ItemConfig with _$ItemConfig {
  const factory ItemConfig({
    required String name,
    @Default(1) int quantity,
    String? note,
  }) = _ItemConfig;

  factory ItemConfig.fromJson(Map<String, dynamic> json) =>
      _$ItemConfigFromJson(json);
}

/// 継承ルール設定
@freezed
class InheritanceRules with _$InheritanceRules {
  const factory InheritanceRules({
    @Default('read_only')
    String parentToChild, // read_only, full_access, no_access
    @Default('no_access') String childToParent,
    @Default('no_access') String sibling,
  }) = _InheritanceRules;

  factory InheritanceRules.fromJson(Map<String, dynamic> json) =>
      _$InheritanceRulesFromJson(json);
}
