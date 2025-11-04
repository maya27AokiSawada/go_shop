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
      uid: fields[0] as String,
      displayName: fields[1] as String,
      role: fields[2] as PurchaseGroupRole,
      joinedAt: fields[3] as DateTime?,
      contact: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseGroupMember obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.joinedAt)
      ..writeByte(4)
      ..write(obj.contact);
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

class LegacyPurchaseGroupMemberAdapter
    extends TypeAdapter<LegacyPurchaseGroupMember> {
  @override
  final int typeId = 14;

  @override
  LegacyPurchaseGroupMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LegacyPurchaseGroupMember(
      memberId: fields[0] as String,
      name: fields[1] as String,
      contact: fields[2] as String,
      role: fields[3] as PurchaseGroupRole,
      isSignedIn: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LegacyPurchaseGroupMember obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.memberId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.contact)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.isSignedIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyPurchaseGroupMemberAdapter &&
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
      groupId: fields[0] as String,
      groupName: fields[1] as String,
      ownerUid: fields[2] as String,
      members: (fields[3] as List).cast<PurchaseGroupMember>(),
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseGroup obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.groupId)
      ..writeByte(1)
      ..write(obj.groupName)
      ..writeByte(2)
      ..write(obj.ownerUid)
      ..writeByte(3)
      ..write(obj.members)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
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

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseGroupMemberImpl _$$PurchaseGroupMemberImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseGroupMemberImpl(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      role: $enumDecode(_$PurchaseGroupRoleEnumMap, json['role']),
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      contact: json['contact'] as String?,
    );

Map<String, dynamic> _$$PurchaseGroupMemberImplToJson(
        _$PurchaseGroupMemberImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'displayName': instance.displayName,
      'role': _$PurchaseGroupRoleEnumMap[instance.role]!,
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'contact': instance.contact,
    };

const _$PurchaseGroupRoleEnumMap = {
  PurchaseGroupRole.owner: 'owner',
  PurchaseGroupRole.member: 'member',
  PurchaseGroupRole.manager: 'manager',
};

_$LegacyPurchaseGroupMemberImpl _$$LegacyPurchaseGroupMemberImplFromJson(
        Map<String, dynamic> json) =>
    _$LegacyPurchaseGroupMemberImpl(
      memberId: json['memberId'] as String? ?? '',
      name: json['name'] as String,
      contact: json['contact'] as String,
      role: $enumDecode(_$PurchaseGroupRoleEnumMap, json['role']),
      isSignedIn: json['isSignedIn'] as bool? ?? false,
    );

Map<String, dynamic> _$$LegacyPurchaseGroupMemberImplToJson(
        _$LegacyPurchaseGroupMemberImpl instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'name': instance.name,
      'contact': instance.contact,
      'role': _$PurchaseGroupRoleEnumMap[instance.role]!,
      'isSignedIn': instance.isSignedIn,
    };

_$PurchaseGroupImpl _$$PurchaseGroupImplFromJson(Map<String, dynamic> json) =>
    _$PurchaseGroupImpl(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      ownerUid: json['ownerUid'] as String,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) =>
                  PurchaseGroupMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PurchaseGroupImplToJson(_$PurchaseGroupImpl instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'groupName': instance.groupName,
      'ownerUid': instance.ownerUid,
      'members': instance.members,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
