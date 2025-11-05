// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_group_v4.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseGroupMemberV4Adapter extends TypeAdapter<PurchaseGroupMemberV4> {
  @override
  final int typeId = 16;

  @override
  PurchaseGroupMemberV4 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseGroupMemberV4(
      uid: fields[0] as String,
      displayName: fields[1] as String,
      role: fields[2] as PurchaseGroupRoleV4,
      joinedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseGroupMemberV4 obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.joinedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseGroupMemberV4Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PurchaseGroupV4Adapter extends TypeAdapter<PurchaseGroupV4> {
  @override
  final int typeId = 17;

  @override
  PurchaseGroupV4 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseGroupV4(
      groupId: fields[0] as String,
      groupName: fields[1] as String,
      ownerUid: fields[2] as String,
      members: (fields[3] as List).cast<PurchaseGroupMemberV4>(),
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseGroupV4 obj) {
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
      other is PurchaseGroupV4Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PurchaseGroupRoleV4Adapter extends TypeAdapter<PurchaseGroupRoleV4> {
  @override
  final int typeId = 15;

  @override
  PurchaseGroupRoleV4 read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PurchaseGroupRoleV4.owner;
      case 1:
        return PurchaseGroupRoleV4.member;
      case 2:
        return PurchaseGroupRoleV4.manager;
      default:
        return PurchaseGroupRoleV4.owner;
    }
  }

  @override
  void write(BinaryWriter writer, PurchaseGroupRoleV4 obj) {
    switch (obj) {
      case PurchaseGroupRoleV4.owner:
        writer.writeByte(0);
        break;
      case PurchaseGroupRoleV4.member:
        writer.writeByte(1);
        break;
      case PurchaseGroupRoleV4.manager:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseGroupRoleV4Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseGroupMemberV4Impl _$$PurchaseGroupMemberV4ImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseGroupMemberV4Impl(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      role: $enumDecode(_$PurchaseGroupRoleV4EnumMap, json['role']),
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
    );

Map<String, dynamic> _$$PurchaseGroupMemberV4ImplToJson(
        _$PurchaseGroupMemberV4Impl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'displayName': instance.displayName,
      'role': _$PurchaseGroupRoleV4EnumMap[instance.role]!,
      'joinedAt': instance.joinedAt?.toIso8601String(),
    };

const _$PurchaseGroupRoleV4EnumMap = {
  PurchaseGroupRoleV4.owner: 'owner',
  PurchaseGroupRoleV4.member: 'member',
  PurchaseGroupRoleV4.manager: 'manager',
};

_$PurchaseGroupV4Impl _$$PurchaseGroupV4ImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseGroupV4Impl(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      ownerUid: json['ownerUid'] as String,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) =>
                  PurchaseGroupMemberV4.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PurchaseGroupV4ImplToJson(
        _$PurchaseGroupV4Impl instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'groupName': instance.groupName,
      'ownerUid': instance.ownerUid,
      'members': instance.members,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
