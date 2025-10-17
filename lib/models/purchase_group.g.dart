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
      shoppingListIds: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseGroup obj) {
    writer
      ..writeByte(8)
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
      ..writeByte(7)
      ..write(obj.shoppingListIds);
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
        return PurchaseGroupRole.friend;
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
      case PurchaseGroupRole.friend:
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
  final int typeId = 5;

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
