import 'package:hive/hive.dart';
import '../models/user_settings.dart';

/// UserSettingsAdapter Override
///
/// **Purpose**: フィールド追加時の後方互換性を確保
///
/// **Background**:
/// - HiveField(6) `enableListNotifications` は新規追加フィールド
/// - 既存のHiveデータには`enableListNotifications`フィールドが存在しない
/// - 生成されたアダプター（UserSettingsAdapter）は `fields[6] as bool` でキャストするため
///   nullの場合に `type 'Null' is not a subtype of type 'bool'` エラーが発生
///
/// **Solution**:
/// - カスタムアダプターでnullチェックを追加
/// - 存在しないフィールドはデフォルト値を使用
///
/// **Registration**:
/// - `main.dart`で優先的に登録（生成されたアダプターより前）
///
/// **Modified**: 2025-12-03 by AI Agent
class UserSettingsAdapterOverride extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 6; // UserSettingsのtypeId

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      userName: (fields[0] as String?) ?? '',
      lastUsedGroupId: (fields[1] as String?) ?? '',
      lastUsedSharedListId: (fields[2] as String?) ?? '',
      userId: (fields[3] as String?) ?? '',
      userEmail: (fields[4] as String?) ?? '',
      appMode: (fields[5] as int?) ?? 0,

      // 🔥 NEW FIELD: 存在しない場合はデフォルト値を使用
      enableListNotifications: (fields[6] as bool?) ?? true, // デフォルト: true
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(7) // 全フィールド数
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
      ..write(obj.enableListNotifications);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapterOverride &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
