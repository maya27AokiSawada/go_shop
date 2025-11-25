// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accepted_invitation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AcceptedInvitationAdapter extends TypeAdapter<AcceptedInvitation> {
  @override
  final int typeId = 7;

  @override
  AcceptedInvitation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AcceptedInvitation(
      acceptorUid: fields[0] as String,
      acceptorEmail: fields[1] as String,
      acceptorName: fields[2] as String,
      SharedGroupId: fields[3] as String,
      shoppingListId: fields[4] as String,
      inviteRole: fields[5] as String,
      acceptedAt: fields[6] as DateTime,
      isProcessed: fields[7] as bool,
      processedAt: fields[8] as DateTime?,
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AcceptedInvitation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.acceptorUid)
      ..writeByte(1)
      ..write(obj.acceptorEmail)
      ..writeByte(2)
      ..write(obj.acceptorName)
      ..writeByte(3)
      ..write(obj.SharedGroupId)
      ..writeByte(4)
      ..write(obj.shoppingListId)
      ..writeByte(5)
      ..write(obj.inviteRole)
      ..writeByte(6)
      ..write(obj.acceptedAt)
      ..writeByte(7)
      ..write(obj.isProcessed)
      ..writeByte(8)
      ..write(obj.processedAt)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcceptedInvitationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AcceptedInvitationImpl _$$AcceptedInvitationImplFromJson(
        Map<String, dynamic> json) =>
    _$AcceptedInvitationImpl(
      acceptorUid: json['acceptorUid'] as String,
      acceptorEmail: json['acceptorEmail'] as String,
      acceptorName: json['acceptorName'] as String,
      SharedGroupId: json['SharedGroupId'] as String,
      shoppingListId: json['shoppingListId'] as String,
      inviteRole: json['inviteRole'] as String,
      acceptedAt: DateTime.parse(json['acceptedAt'] as String),
      isProcessed: json['isProcessed'] as bool? ?? false,
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$AcceptedInvitationImplToJson(
        _$AcceptedInvitationImpl instance) =>
    <String, dynamic>{
      'acceptorUid': instance.acceptorUid,
      'acceptorEmail': instance.acceptorEmail,
      'acceptorName': instance.acceptorName,
      'SharedGroupId': instance.SharedGroupId,
      'shoppingListId': instance.shoppingListId,
      'inviteRole': instance.inviteRole,
      'acceptedAt': instance.acceptedAt.toIso8601String(),
      'isProcessed': instance.isProcessed,
      'processedAt': instance.processedAt?.toIso8601String(),
      'notes': instance.notes,
    };
