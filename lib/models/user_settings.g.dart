// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 6;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      userName: fields[0] as String,
      lastUsedGroupId: fields[1] as String,
      lastUsedSharedListId: fields[2] as String,
      userId: fields[3] as String,
      userEmail: fields[4] as String,
      appMode: fields[5] as int,
      enableListNotifications: fields[6] as bool,
      whiteboardColor5: fields[7] as int,
      whiteboardColor6: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userName)
      ..writeByte(1)
      ..write(obj.lastUsedGroupId)
      ..writeByte(2)
      ..write(obj.lastUsedSharedListId)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.userEmail)
      ..writeByte(5)
      ..write(obj.appMode)
      ..writeByte(6)
      ..write(obj.enableListNotifications)
      ..writeByte(7)
      ..write(obj.whiteboardColor5)
      ..writeByte(8)
      ..write(obj.whiteboardColor6);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      userName: json['userName'] as String? ?? '',
      lastUsedGroupId: json['lastUsedGroupId'] as String? ?? '',
      lastUsedSharedListId: json['lastUsedSharedListId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      appMode: (json['appMode'] as num?)?.toInt() ?? 0,
      enableListNotifications: json['enableListNotifications'] as bool? ?? true,
      whiteboardColor5:
          (json['whiteboardColor5'] as num?)?.toInt() ?? 0xFF2196F3,
      whiteboardColor6:
          (json['whiteboardColor6'] as num?)?.toInt() ?? 0xFFFF9800,
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'userName': instance.userName,
      'lastUsedGroupId': instance.lastUsedGroupId,
      'lastUsedSharedListId': instance.lastUsedSharedListId,
      'userId': instance.userId,
      'userEmail': instance.userEmail,
      'appMode': instance.appMode,
      'enableListNotifications': instance.enableListNotifications,
      'whiteboardColor5': instance.whiteboardColor5,
      'whiteboardColor6': instance.whiteboardColor6,
    };
