// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_structure_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroupStructureConfigImpl _$$GroupStructureConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$GroupStructureConfigImpl(
      organization: OrganizationConfig.fromJson(
          json['organization'] as Map<String, dynamic>),
      inheritanceRules: json['inheritanceRules'] == null
          ? null
          : InheritanceRules.fromJson(
              json['inheritanceRules'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$GroupStructureConfigImplToJson(
        _$GroupStructureConfigImpl instance) =>
    <String, dynamic>{
      'organization': instance.organization,
      'inheritanceRules': instance.inheritanceRules,
    };

_$OrganizationConfigImpl _$$OrganizationConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$OrganizationConfigImpl(
      name: json['name'] as String,
      groups: (json['groups'] as List<dynamic>)
          .map((e) => GroupConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$OrganizationConfigImplToJson(
        _$OrganizationConfigImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'groups': instance.groups,
    };

_$GroupConfigImpl _$$GroupConfigImplFromJson(Map<String, dynamic> json) =>
    _$GroupConfigImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parent: json['parent'] as String?,
      members: (json['members'] as List<dynamic>)
          .map((e) => MemberConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultPermission: (json['defaultPermission'] as num?)?.toInt() ?? 0x03,
      lists: (json['lists'] as List<dynamic>?)
              ?.map((e) => ListConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$GroupConfigImplToJson(_$GroupConfigImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parent': instance.parent,
      'members': instance.members,
      'defaultPermission': instance.defaultPermission,
      'lists': instance.lists,
    };

_$MemberConfigImpl _$$MemberConfigImplFromJson(Map<String, dynamic> json) =>
    _$MemberConfigImpl(
      uid: json['uid'] as String,
      name: json['name'] as String,
      permission: (json['permission'] as num?)?.toInt() ?? 0x03,
    );

Map<String, dynamic> _$$MemberConfigImplToJson(_$MemberConfigImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'permission': instance.permission,
    };

_$ListConfigImpl _$$ListConfigImplFromJson(Map<String, dynamic> json) =>
    _$ListConfigImpl(
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ItemConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ListConfigImplToJson(_$ListConfigImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'items': instance.items,
    };

_$ItemConfigImpl _$$ItemConfigImplFromJson(Map<String, dynamic> json) =>
    _$ItemConfigImpl(
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$ItemConfigImplToJson(_$ItemConfigImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'note': instance.note,
    };

_$InheritanceRulesImpl _$$InheritanceRulesImplFromJson(
        Map<String, dynamic> json) =>
    _$InheritanceRulesImpl(
      parentToChild: json['parentToChild'] as String? ?? 'read_only',
      childToParent: json['childToParent'] as String? ?? 'no_access',
      sibling: json['sibling'] as String? ?? 'no_access',
    );

Map<String, dynamic> _$$InheritanceRulesImplToJson(
        _$InheritanceRulesImpl instance) =>
    <String, dynamic>{
      'parentToChild': instance.parentToChild,
      'childToParent': instance.childToParent,
      'sibling': instance.sibling,
    };
