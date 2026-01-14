// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SharedGroupMemberAdapter extends TypeAdapter<SharedGroupMember> {
  @override
  final int typeId = 1;

  @override
  SharedGroupMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SharedGroupMember(
      memberId: fields[0] as String,
      name: fields[1] as String,
      contact: fields[2] as String,
      role: fields[3] as SharedGroupRole,
      isSignedIn: fields[4] as bool,
      invitationStatus: fields[9] as InvitationStatus,
      securityKey: fields[10] as String?,
      invitedAt: fields[7] as DateTime?,
      acceptedAt: fields[8] as DateTime?,
      isInvited: fields[5] as bool,
      isInvitationAccepted: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SharedGroupMember obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.memberId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.contact)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.isSignedIn)
      ..writeByte(9)
      ..write(obj.invitationStatus)
      ..writeByte(10)
      ..write(obj.securityKey)
      ..writeByte(7)
      ..write(obj.invitedAt)
      ..writeByte(8)
      ..write(obj.acceptedAt)
      ..writeByte(5)
      ..write(obj.isInvited)
      ..writeByte(6)
      ..write(obj.isInvitationAccepted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedGroupMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SharedGroupAdapter extends TypeAdapter<SharedGroup> {
  @override
  final int typeId = 2;

  @override
  SharedGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SharedGroup(
      groupName: fields[0] as String,
      groupId: fields[1] as String,
      ownerName: fields[2] as String?,
      ownerEmail: fields[3] as String?,
      ownerUid: fields[4] as String?,
      members: (fields[5] as List?)?.cast<SharedGroupMember>(),
      ownerMessage: fields[6] as String?,
      allowedUid: (fields[11] as List).cast<String>(),
      isSecret: fields[12] as bool,
      acceptedUid: (fields[13] as List)
          .map((dynamic e) => (e as Map).cast<String, String>())
          .toList(),
      isDeleted: fields[14] as bool,
      lastAccessedAt: fields[15] as DateTime?,
      createdAt: fields[16] as DateTime?,
      updatedAt: fields[17] as DateTime?,
      syncStatus: fields[18] as SyncStatus,
      groupType: fields[19] as GroupType,
      parentGroupId: fields[20] as String?,
      childGroupIds: (fields[21] as List).cast<String>(),
      memberPermissions: (fields[22] as Map).cast<String, int>(),
      defaultPermission: fields[23] as int,
      inheritParentLists: fields[24] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SharedGroup obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.groupName)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.ownerName)
      ..writeByte(3)
      ..write(obj.ownerEmail)
      ..writeByte(4)
      ..write(obj.ownerUid)
      ..writeByte(5)
      ..write(obj.members)
      ..writeByte(6)
      ..write(obj.ownerMessage)
      ..writeByte(11)
      ..write(obj.allowedUid)
      ..writeByte(12)
      ..write(obj.isSecret)
      ..writeByte(13)
      ..write(obj.acceptedUid)
      ..writeByte(14)
      ..write(obj.isDeleted)
      ..writeByte(15)
      ..write(obj.lastAccessedAt)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.syncStatus)
      ..writeByte(19)
      ..write(obj.groupType)
      ..writeByte(20)
      ..write(obj.parentGroupId)
      ..writeByte(21)
      ..write(obj.childGroupIds)
      ..writeByte(22)
      ..write(obj.memberPermissions)
      ..writeByte(23)
      ..write(obj.defaultPermission)
      ..writeByte(24)
      ..write(obj.inheritParentLists);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SharedGroupRoleAdapter extends TypeAdapter<SharedGroupRole> {
  @override
  final int typeId = 0;

  @override
  SharedGroupRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SharedGroupRole.owner;
      case 1:
        return SharedGroupRole.member;
      case 2:
        return SharedGroupRole.manager;
      case 3:
        return SharedGroupRole.partner;
      default:
        return SharedGroupRole.owner;
    }
  }

  @override
  void write(BinaryWriter writer, SharedGroupRole obj) {
    switch (obj) {
      case SharedGroupRole.owner:
        writer.writeByte(0);
        break;
      case SharedGroupRole.member:
        writer.writeByte(1);
        break;
      case SharedGroupRole.manager:
        writer.writeByte(2);
        break;
      case SharedGroupRole.partner:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedGroupRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvitationStatusAdapter extends TypeAdapter<InvitationStatus> {
  @override
  final int typeId = 8;

  @override
  InvitationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvitationStatus.self;
      case 1:
        return InvitationStatus.pending;
      case 2:
        return InvitationStatus.accepted;
      case 3:
        return InvitationStatus.deleted;
      default:
        return InvitationStatus.self;
    }
  }

  @override
  void write(BinaryWriter writer, InvitationStatus obj) {
    switch (obj) {
      case InvitationStatus.self:
        writer.writeByte(0);
        break;
      case InvitationStatus.pending:
        writer.writeByte(1);
        break;
      case InvitationStatus.accepted:
        writer.writeByte(2);
        break;
      case InvitationStatus.deleted:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvitationTypeAdapter extends TypeAdapter<InvitationType> {
  @override
  final int typeId = 9;

  @override
  InvitationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvitationType.individual;
      case 1:
        return InvitationType.partner;
      default:
        return InvitationType.individual;
    }
  }

  @override
  void write(BinaryWriter writer, InvitationType obj) {
    switch (obj) {
      case InvitationType.individual:
        writer.writeByte(0);
        break;
      case InvitationType.partner:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 10;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.synced;
      case 1:
        return SyncStatus.pending;
      case 2:
        return SyncStatus.local;
      default:
        return SyncStatus.synced;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.synced:
        writer.writeByte(0);
        break;
      case SyncStatus.pending:
        writer.writeByte(1);
        break;
      case SyncStatus.local:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupTypeAdapter extends TypeAdapter<GroupType> {
  @override
  final int typeId = 11;

  @override
  GroupType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GroupType.shopping;
      case 1:
        return GroupType.todo;
      default:
        return GroupType.shopping;
    }
  }

  @override
  void write(BinaryWriter writer, GroupType obj) {
    switch (obj) {
      case GroupType.shopping:
        writer.writeByte(0);
        break;
      case GroupType.todo:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SharedGroupMemberImpl _$$SharedGroupMemberImplFromJson(
        Map<String, dynamic> json) =>
    _$SharedGroupMemberImpl(
      memberId: json['memberId'] as String? ?? '',
      name: json['name'] as String,
      contact: json['contact'] as String,
      role: $enumDecode(_$SharedGroupRoleEnumMap, json['role']),
      isSignedIn: json['isSignedIn'] as bool? ?? false,
      invitationStatus: $enumDecodeNullable(
              _$InvitationStatusEnumMap, json['invitationStatus']) ??
          InvitationStatus.self,
      securityKey: json['securityKey'] as String?,
      invitedAt: json['invitedAt'] == null
          ? null
          : DateTime.parse(json['invitedAt'] as String),
      acceptedAt: json['acceptedAt'] == null
          ? null
          : DateTime.parse(json['acceptedAt'] as String),
      isInvited: json['isInvited'] as bool? ?? false,
      isInvitationAccepted: json['isInvitationAccepted'] as bool? ?? false,
    );

Map<String, dynamic> _$$SharedGroupMemberImplToJson(
        _$SharedGroupMemberImpl instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'name': instance.name,
      'contact': instance.contact,
      'role': _$SharedGroupRoleEnumMap[instance.role]!,
      'isSignedIn': instance.isSignedIn,
      'invitationStatus': _$InvitationStatusEnumMap[instance.invitationStatus]!,
      'securityKey': instance.securityKey,
      'invitedAt': instance.invitedAt?.toIso8601String(),
      'acceptedAt': instance.acceptedAt?.toIso8601String(),
      'isInvited': instance.isInvited,
      'isInvitationAccepted': instance.isInvitationAccepted,
    };

const _$SharedGroupRoleEnumMap = {
  SharedGroupRole.owner: 'owner',
  SharedGroupRole.member: 'member',
  SharedGroupRole.manager: 'manager',
  SharedGroupRole.partner: 'partner',
};

const _$InvitationStatusEnumMap = {
  InvitationStatus.self: 'self',
  InvitationStatus.pending: 'pending',
  InvitationStatus.accepted: 'accepted',
  InvitationStatus.deleted: 'deleted',
};

_$SharedGroupImpl _$$SharedGroupImplFromJson(Map<String, dynamic> json) =>
    _$SharedGroupImpl(
      groupName: json['groupName'] as String,
      groupId: json['groupId'] as String,
      ownerName: json['ownerName'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      ownerUid: json['ownerUid'] as String?,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => SharedGroupMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      ownerMessage: json['ownerMessage'] as String?,
      allowedUid: (json['allowedUid'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isSecret: json['isSecret'] as bool? ?? false,
      acceptedUid: (json['acceptedUid'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          const [],
      isDeleted: json['isDeleted'] as bool? ?? false,
      lastAccessedAt: json['lastAccessedAt'] == null
          ? null
          : DateTime.parse(json['lastAccessedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
              SyncStatus.synced,
      groupType: $enumDecodeNullable(_$GroupTypeEnumMap, json['groupType']) ??
          GroupType.shopping,
      parentGroupId: json['parentGroupId'] as String?,
      childGroupIds: (json['childGroupIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      memberPermissions:
          (json['memberPermissions'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              const {},
      defaultPermission: (json['defaultPermission'] as num?)?.toInt() ?? 0x03,
      inheritParentLists: json['inheritParentLists'] as bool? ?? true,
    );

Map<String, dynamic> _$$SharedGroupImplToJson(_$SharedGroupImpl instance) =>
    <String, dynamic>{
      'groupName': instance.groupName,
      'groupId': instance.groupId,
      'ownerName': instance.ownerName,
      'ownerEmail': instance.ownerEmail,
      'ownerUid': instance.ownerUid,
      'members': instance.members,
      'ownerMessage': instance.ownerMessage,
      'allowedUid': instance.allowedUid,
      'isSecret': instance.isSecret,
      'acceptedUid': instance.acceptedUid,
      'isDeleted': instance.isDeleted,
      'lastAccessedAt': instance.lastAccessedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
      'groupType': _$GroupTypeEnumMap[instance.groupType]!,
      'parentGroupId': instance.parentGroupId,
      'childGroupIds': instance.childGroupIds,
      'memberPermissions': instance.memberPermissions,
      'defaultPermission': instance.defaultPermission,
      'inheritParentLists': instance.inheritParentLists,
    };

const _$SyncStatusEnumMap = {
  SyncStatus.synced: 'synced',
  SyncStatus.pending: 'pending',
  SyncStatus.local: 'local',
};

const _$GroupTypeEnumMap = {
  GroupType.shopping: 'shopping',
  GroupType.todo: 'todo',
};
