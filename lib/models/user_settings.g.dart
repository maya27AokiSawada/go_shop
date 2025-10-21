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
      lastUsedShoppingListId: fields[2] as String,
      userId: fields[3] as String,
      userEmail: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userName)
      ..writeByte(1)
      ..write(obj.lastUsedGroupId)
      ..writeByte(2)
      ..write(obj.lastUsedShoppingListId)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.userEmail);
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
      lastUsedGroupId: json['lastUsedGroupId'] as String? ?? 'default_group',
      lastUsedShoppingListId: json['lastUsedShoppingListId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'userName': instance.userName,
      'lastUsedGroupId': instance.lastUsedGroupId,
      'lastUsedShoppingListId': instance.lastUsedShoppingListId,
      'userId': instance.userId,
      'userEmail': instance.userEmail,
    };
