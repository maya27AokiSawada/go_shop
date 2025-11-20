// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseGroupMemberAdapter extends TypeAdapter<PurchaseGroupMember> {
  @override
  final int typeId = 1;

  @override
  PurchaseGroupMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseGroupMember(
      memberId: fields[0] as String,
      name: fields[1] as String,
      contact: fields[2] as String,
      role: fields[3] as PurchaseGroupRole,
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
  void write(BinaryWriter writer, PurchaseGroupMember obj) {
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
      other is PurchaseGroupMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PurchaseGroupAdapter extends TypeAdapter<PurchaseGroup> {
  @override
  final int typeId = 2;

  @override
  PurchaseGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseGroup(
      groupName: fields[0] as String,
      groupId: fields[1] as String,
      ownerName: fields[2] as String?,
      ownerEmail: fields[3] as String?,
      ownerUid: fields[4] as String?,
      members: (fields[5] as List?)?.cast<PurchaseGroupMember>(),
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
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseGroup obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.groupType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PurchaseGroupRoleAdapter extends TypeAdapter<PurchaseGroupRole> {
  @override
  final int typeId = 0;

  @override
  PurchaseGroupRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PurchaseGroupRole.owner;
      case 1:
        return PurchaseGroupRole.member;
      case 2:
        return PurchaseGroupRole.manager;
      case 3:
        return PurchaseGroupRole.partner;
      default:
        return PurchaseGroupRole.owner;
    }
  }

  @override
  void write(BinaryWriter writer, PurchaseGroupRole obj) {
    switch (obj) {
      case PurchaseGroupRole.owner:
        writer.writeByte(0);
        break;
      case PurchaseGroupRole.member:
        writer.writeByte(1);
        break;
      case PurchaseGroupRole.manager:
        writer.writeByte(2);
        break;
      case PurchaseGroupRole.partner:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseGroupRoleAdapter &&
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

_$PurchaseGroupMemberImpl _$$PurchaseGroupMemberImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseGroupMemberImpl(
      memberId: json['memberId'] as String? ?? '',
      name: json['name'] as String,
      contact: json['contact'] as String,
      role: $enumDecode(_$PurchaseGroupRoleEnumMap, json['role']),
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

Map<String, dynamic> _$$PurchaseGroupMemberImplToJson(
        _$PurchaseGroupMemberImpl instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'name': instance.name,
      'contact': instance.contact,
      'role': _$PurchaseGroupRoleEnumMap[instance.role]!,
      'isSignedIn': instance.isSignedIn,
      'invitationStatus': _$InvitationStatusEnumMap[instance.invitationStatus]!,
      'securityKey': instance.securityKey,
      'invitedAt': instance.invitedAt?.toIso8601String(),
      'acceptedAt': instance.acceptedAt?.toIso8601String(),
      'isInvited': instance.isInvited,
      'isInvitationAccepted': instance.isInvitationAccepted,
    };

const _$PurchaseGroupRoleEnumMap = {
  PurchaseGroupRole.owner: 'owner',
  PurchaseGroupRole.member: 'member',
  PurchaseGroupRole.manager: 'manager',
  PurchaseGroupRole.partner: 'partner',
};

const _$InvitationStatusEnumMap = {
  InvitationStatus.self: 'self',
  InvitationStatus.pending: 'pending',
  InvitationStatus.accepted: 'accepted',
  InvitationStatus.deleted: 'deleted',
};

_$PurchaseGroupImpl _$$PurchaseGroupImplFromJson(Map<String, dynamic> json) =>
    _$PurchaseGroupImpl(
      groupName: json['groupName'] as String,
      groupId: json['groupId'] as String,
      ownerName: json['ownerName'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      ownerUid: json['ownerUid'] as String?,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => PurchaseGroupMember.fromJson(e as Map<String, dynamic>))
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
    );

Map<String, dynamic> _$$PurchaseGroupImplToJson(_$PurchaseGroupImpl instance) =>
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
