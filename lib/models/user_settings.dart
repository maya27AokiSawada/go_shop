import 'package:hive/hive.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@HiveType(typeId: 6)
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @HiveField(0) @Default('') String userName,
    @HiveField(1) @Default('') String lastUsedGroupId, // 空文字列で初期化、グループリストから自動選択
    @HiveField(2) @Default('') String lastUsedShoppingListId,
    @HiveField(3) @Default('') String userId,
    @HiveField(4) @Default('') String userEmail, // メールアドレスフィールドを追加
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
