import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
part  'device_user.g.dart';

@HiveType(typeId: 3)
class DeviceUser {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String email;
  @HiveField(3)
  String defaultGroupId='あなたのリスト';

  DeviceUser({
    required this.id,
    required this.name,
    required this.email,
    this.defaultGroupId = 'あなたのリスト',
  });
  DeviceUser copyWith({
    String? id,
    String? name,
    String? email,
    String? defaultGroupId,
  }) {
    return DeviceUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      defaultGroupId: defaultGroupId ?? this.defaultGroupId,
    );
  }
  factory DeviceUser.fromJson(Map<String, dynamic> json) {
    return DeviceUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      defaultGroupId: json['defaultGroupId'] ?? 'あなたのリスト',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}