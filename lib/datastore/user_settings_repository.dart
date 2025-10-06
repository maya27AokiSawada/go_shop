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
  Future<void> clearAllSettings();
  Future<void> updateUserId(String userId);
  Future<void> updateUserEmail(String userEmail);
  Future<bool> hasUserIdChanged(String newUserId);
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
    logger.i('💾 ユーザー名更新開始: $userName');
    
    final currentSettings = await getSettings();
    logger.i('📖 現在の設定: ${currentSettings.toString()}');
    
    final updatedSettings = currentSettings.copyWith(userName: userName);
    logger.i('🔄 更新後の設定: ${updatedSettings.toString()}');
    
    await saveSettings(updatedSettings);
    logger.i('✅ ユーザー名更新完了: $userName');
    
    // 確認のため再読み込み
    final verifySettings = await getSettings();
    logger.i('🔍 保存確認: ${verifySettings.userName}');
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

  @override
  Future<void> clearAllSettings() async {
    await _box.delete(_settingsKey);
    logger.i('🗑️ 全ユーザー設定を削除しました');
  }

  @override
  Future<void> updateUserId(String userId) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(userId: userId);
    await saveSettings(updatedSettings);
    logger.i('🆔 ユーザーIDを更新: $userId');
  }

  @override
  Future<void> updateUserEmail(String userEmail) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(userEmail: userEmail);
    await saveSettings(updatedSettings);
    logger.i('📧 ユーザーメールアドレスを更新: $userEmail');
  }

  @override
  Future<bool> hasUserIdChanged(String newUserId) async {
    final currentSettings = await getSettings();
    final currentUserId = currentSettings.userId;
    
    // 初回サインイン時（前回のUIDが空）はfalseを返す
    if (currentUserId.isEmpty) {
      logger.i('🆕 初回UID設定: $newUserId');
      return false;
    }
    
    // UIDが変更されたかチェック
    final hasChanged = currentUserId != newUserId;
    if (hasChanged) {
      logger.i('🔄 UID変更を検知: $currentUserId → $newUserId');
    } else {
      logger.i('✅ 同じUIDでサインイン: $newUserId');
    }
    
    return hasChanged;
  }
}

// Providers
final userSettingsBoxProvider = Provider<Box<UserSettings>>((ref) {
  return Hive.box<UserSettings>('userSettings');
});

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return HiveUserSettingsRepository(ref);
});
