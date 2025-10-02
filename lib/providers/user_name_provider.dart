// lib/providers/user_name_provider.dart
import "package:flutter_riverpod/flutter_riverpod.dart";
import "user_settings_provider.dart";

// ユーザー名を設定ベースで管理するプロバイダー
final userNameProvider = Provider<String?>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.when(
    data: (settings) => settings.userName.isEmpty ? null : settings.userName,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ユーザー名を設定するためのNotifier
class UserNameNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // 初期化は不要
  }

  Future<void> setUserName(String userName) async {
    await ref.read(userSettingsProvider.notifier).updateUserName(userName);
  }
}

final userNameNotifierProvider = AsyncNotifierProvider<UserNameNotifier, void>(
  () => UserNameNotifier(),
);
