import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_settings.dart';
import '../utils/app_logger.dart';

abstract class UserSettingsRepository {
  Future<UserSettings> getSettings();
  Future<void> saveSettings(UserSettings settings);
  Future<void> updateUserName(String userName);
  Future<void> updateLastUsedGroupId(String groupId);
  Future<void> updateLastUsedSharedListId(String sharedListId);
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
        Log.warning(
            'Warning: Invalid UserSettings type found (${rawSettings.runtimeType}), clearing...');
        await _box.delete(_settingsKey);
      }

      return const UserSettings();
    } catch (e, stackTrace) {
      Log.error('Error loading UserSettings: $e', e, stackTrace);
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
    Log.info('💾 ユーザー名更新開始: $userName');

    final currentSettings = await getSettings();
    Log.info('📖 現在の設定: ${currentSettings.toString()}');

    final updatedSettings = currentSettings.copyWith(userName: userName);
    Log.info('🔄 更新後の設定: ${updatedSettings.toString()}');

    await saveSettings(updatedSettings);
    Log.info('✅ ユーザー名更新完了: $userName');

    // 確認のため再読み込み
    final verifySettings = await getSettings();
    Log.info('🔍 保存確認: ${verifySettings.userName}');
  }

  @override
  Future<void> updateLastUsedGroupId(String groupId) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(lastUsedGroupId: groupId);
    await saveSettings(updatedSettings);
  }

  @override
  Future<void> updateLastUsedSharedListId(String sharedListId) async {
    final currentSettings = await getSettings();
    final updatedSettings =
        currentSettings.copyWith(lastUsedSharedListId: sharedListId);
    await saveSettings(updatedSettings);
  }

  @override
  Future<void> clearAllSettings() async {
    await _box.delete(_settingsKey);
    Log.info('🗑️ 全ユーザー設定を削除しました');
  }

  @override
  Future<void> updateUserId(String userId) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(userId: userId);
    await saveSettings(updatedSettings);
    Log.info('🆔 ユーザーIDを更新: $userId');
  }

  @override
  Future<void> updateUserEmail(String userEmail) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(userEmail: userEmail);
    await saveSettings(updatedSettings);
    Log.info('📧 ユーザーメールアドレスを更新: ${Log.maskEmail(userEmail)}');
  }

  @override
  Future<bool> hasUserIdChanged(String newUserId) async {
    final currentSettings = await getSettings();
    final currentUserId = currentSettings.userId;

    Log.info(
        '🔍 [UID_CHECK] Stored UID: "$currentUserId", New UID: "$newUserId"');

    // 新しいUIDが仮設定の場合は常にfalseを返す（変更として扱わない）
    if (_isTemporaryUid(newUserId)) {
      Log.info('🔄 新しいUIDが仮設定 - 変更なしとして扱います: $currentUserId → $newUserId');
      return false;
    }

    // 初回サインイン時（前回のUIDが空 or 仮設定）はfalseを返す
    if (currentUserId.isEmpty || _isTemporaryUid(currentUserId)) {
      Log.info('🆕 初回UID設定 or 仮設定から本設定へ: "$currentUserId" → "$newUserId"');
      return false;
    }

    // UIDが変更されたかチェック（両方とも有効なUIDの場合のみ）
    final hasChanged = currentUserId != newUserId;
    if (hasChanged) {
      Log.info('⚠️ UID変更を検知: $currentUserId → $newUserId');
    } else {
      Log.info('✅ 同じUIDでサインイン: $newUserId');
    }

    return hasChanged;
  }

  // 仮設定UID（開発・テスト用）かどうかを判定するヘルパーメソッド
  bool _isTemporaryUid(String uid) {
    // 空文字列は仮設定として扱わない（初回ログインとして扱う）
    if (uid.isEmpty) {
      return false;
    }

    // MockAuthServiceが生成する仮設定UIDパターンを検出
    if (uid.startsWith('mock_')) {
      return true;
    }

    // ローカルテスト用の仮設定UIDパターンを検出
    if (uid.startsWith('local_') ||
        uid.startsWith('temp_') ||
        uid.startsWith('dev_')) {
      return true;
    }

    // 明らかに無効なUID（短すぎる）も仮設定として扱う
    if (uid.length < 10) {
      return true;
    }

    return false;
  }
}

// Providers
final userSettingsBoxProvider = Provider<Box<UserSettings>>((ref) {
  return Hive.box<UserSettings>('userSettings');
});

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return HiveUserSettingsRepository(ref);
});
