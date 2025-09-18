// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceUserAdapter extends TypeAdapter<DeviceUser> {
  @override
  final int typeId = 3;

  @override
  DeviceUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceUser(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceUser obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
