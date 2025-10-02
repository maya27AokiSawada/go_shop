import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/user_settings.dart';

final logger = Logger();

abstract class UserSettingsRepository {
  Future<UserSettings> getSettings();
  Future<void> saveSettings(UserSettings settings);
  Future<void> updateUserName(String userName);
  Future<void> updateLastUsedGroupId(String groupId);
  Future<void> updateLastUsedShoppingListId(String shoppingListId);
}

class HiveUserSettingsRepository implements UserSettingsRepository {
  final Ref _ref;
  
  HiveUserSettingsRepository(this._ref);
  
  Box<UserSettings> get _box => _ref.read(userSettingsBoxProvider);
  
  static const String _settingsKey = 'user_settings';
  
  @override
  Future<UserSettings> getSettings() async {
    try {
      final dynamic rawSettings = _box.get(_settingsKey);
      
      // 型安全性チェック
      if (rawSettings is UserSettings) {
        return rawSettings;
      } else if (rawSettings != null) {
        // 不正な型の場合、削除してデフォルト値を返す
        logger.i('Warning: Invalid UserSettings type found (${rawSettings.runtimeType}), clearing...');
        await _box.delete(_settingsKey);
      }
      
      return const UserSettings();
    } catch (e) {
      logger.i('Error loading UserSettings: $e');
      // エラーの場合は念のためキーを削除してデフォルト値を返す
      try {
        await _box.delete(_settingsKey);
      } catch (_) {}
      return const UserSettings();
    }
  }
  
  @override
  Future<void> saveSettings(UserSettings settings) async {
    await _box.put(_settingsKey, settings);
  }
  
  @override
  Future<void> updateUserName(String userName) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(userName: userName);
    await saveSettings(updatedSettings);
  }
  
  @override
  Future<void> updateLastUsedGroupId(String groupId) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(lastUsedGroupId: groupId);
    await saveSettings(updatedSettings);
  }
  
  @override
  Future<void> updateLastUsedShoppingListId(String shoppingListId) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(lastUsedShoppingListId: shoppingListId);
    await saveSettings(updatedSettings);
  }
}

// Providers
final userSettingsBoxProvider = Provider<Box<UserSettings>>((ref) {
  return Hive.box<UserSettings>('userSettings');
});

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return HiveUserSettingsRepository(ref);
});
