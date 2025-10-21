import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../models/user_settings.dart';
import '../datastore/user_settings_repository.dart';

class UserSettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final repository = ref.read(userSettingsRepositoryProvider);
    return await repository.getSettings();
  }

  Future<void> updateUserName(String userName) async {
    final repository = ref.read(userSettingsRepositoryProvider);
    await repository.updateUserName(userName);
    ref.invalidateSelf();
  }

  Future<void> updateLastUsedGroupId(String groupId) async {
    final repository = ref.read(userSettingsRepositoryProvider);
    await repository.updateLastUsedGroupId(groupId);
    ref.invalidateSelf();
  }

  Future<void> updateLastUsedShoppingListId(String shoppingListId) async {
    final repository = ref.read(userSettingsRepositoryProvider);
    await repository.updateLastUsedShoppingListId(shoppingListId);
    ref.invalidateSelf();
  }

  Future<void> clearAllSettings() async {
    final repository = ref.read(userSettingsRepositoryProvider);
    await repository.clearAllSettings();
    ref.invalidateSelf();
  }

  Future<void> updateUserId(String userId) async {
    final repository = ref.read(userSettingsRepositoryProvider);
    await repository.updateUserId(userId);
    ref.invalidateSelf();
  }

  Future<void> updateUserEmail(String userEmail) async {
    final repository = ref.read(userSettingsRepositoryProvider);
    await repository.updateUserEmail(userEmail);
    ref.invalidateSelf();
  }

  Future<bool> hasUserIdChanged(String newUserId) async {
    final repository = ref.read(userSettingsRepositoryProvider);
    return await repository.hasUserIdChanged(newUserId);
  }
}

final userSettingsProvider = AsyncNotifierProvider<UserSettingsNotifier, UserSettings>(
  () => UserSettingsNotifier(),
);

// 個別のプロバイダー（便利なアクセス用）
final userNameFromSettingsProvider = Provider<String>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.when(
    data: (settings) => settings.userName,
    loading: () => '',
    error: (_, __) => '',
  );
});

final lastUsedGroupIdProvider = Provider<String>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.when(
    data: (settings) => settings.lastUsedGroupId,
    loading: () => 'default_group',
    error: (_, __) => 'default_group',
  );
});

final lastUsedShoppingListIdProvider = Provider<String>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.when(
    data: (settings) => settings.lastUsedShoppingListId,
    loading: () => '',
    error: (_, __) => '',
  );
});
