// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvitationAdapter extends TypeAdapter<Invitation> {
  @override
  final int typeId = 5;

  @override
  Invitation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invitation(
      id: fields[0] as String,
      groupId: fields[1] as String,
      inviteCode: fields[2] as String,
      inviterUid: fields[3] as String,
      inviteeEmail: fields[4] as String,
      createdAt: fields[5] as DateTime,
      expiresAt: fields[6] as DateTime,
      isAccepted: fields[7] as bool,
      acceptedByUid: fields[8] as String?,
      acceptedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Invitation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.inviteCode)
      ..writeByte(3)
      ..write(obj.inviterUid)
      ..writeByte(4)
      ..write(obj.inviteeEmail)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.expiresAt)
      ..writeByte(7)
      ..write(obj.isAccepted)
      ..writeByte(8)
      ..write(obj.acceptedByUid)
      ..writeByte(9)
      ..write(obj.acceptedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InvitationImpl _$$InvitationImplFromJson(Map<String, dynamic> json) =>
    _$InvitationImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      inviteCode: json['inviteCode'] as String,
      inviterUid: json['inviterUid'] as String,
      inviteeEmail: json['inviteeEmail'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isAccepted: json['isAccepted'] as bool? ?? false,
      acceptedByUid: json['acceptedByUid'] as String?,
      acceptedAt: json['acceptedAt'] == null
          ? null
          : DateTime.parse(json['acceptedAt'] as String),
    );

Map<String, dynamic> _$$InvitationImplToJson(_$InvitationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'inviteCode': instance.inviteCode,
      'inviterUid': instance.inviterUid,
      'inviteeEmail': instance.inviteeEmail,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'isAccepted': instance.isAccepted,
      'acceptedByUid': instance.acceptedByUid,
      'acceptedAt': instance.acceptedAt?.toIso8601String(),
    };
