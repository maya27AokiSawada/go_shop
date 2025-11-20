// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InvitationImpl _$$InvitationImplFromJson(Map<String, dynamic> json) =>
    _$InvitationImpl(
      token: json['token'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      invitedBy: json['invitedBy'] as String,
      inviterName: json['inviterName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 5,
      currentUses: (json['currentUses'] as num?)?.toInt() ?? 0,
      usedBy: (json['usedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      securityKey: json['securityKey'] as String?,
    );

Map<String, dynamic> _$$InvitationImplToJson(_$InvitationImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'groupId': instance.groupId,
      'groupName': instance.groupName,
      'invitedBy': instance.invitedBy,
      'inviterName': instance.inviterName,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'maxUses': instance.maxUses,
      'currentUses': instance.currentUses,
      'usedBy': instance.usedBy,
      'securityKey': instance.securityKey,
    };

_$InvitationQRDataImpl _$$InvitationQRDataImplFromJson(
        Map<String, dynamic> json) =>
    _$InvitationQRDataImpl(
      type: json['type'] as String? ?? 'go_shop_invitation',
      version: json['version'] as String? ?? '1.0',
      token: json['token'] as String,
    );

Map<String, dynamic> _$$InvitationQRDataImplToJson(
        _$InvitationQRDataImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'version': instance.version,
      'token': instance.token,
    };
