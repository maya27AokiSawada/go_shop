// lib/providers/user_name_provider.dart
import "package:flutter_riverpod/flutter_riverpod.dart";
import '../utils/app_logger.dart';
import "../services/user_preferences_service.dart";
import "../services/firestore_user_name_service.dart";
import "../flavors.dart";
import 'auth_provider.dart';
import 'user_settings_provider.dart';

// Logger instance

// ユーザー名を設定するためのNotifier
class UserNameNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // 初期化は不要
  }

  /// ユーザー名をSharedPreferencesとFirestoreの両方に保存
  Future<void> setUserName(String userName) async {
    Log.info('📝 ユーザー名保存開始: $userName');

    // SharedPreferences（ローカル）に保存
    final success = await UserPreferencesService.saveUserName(userName);
    Log.info('📝 SharedPreferences保存結果: $success');

    // Firestore（クラウド）に保存（本番環境のみ）
    if (F.appFlavor == Flavor.prod) {
      final firestoreSuccess =
          await FirestoreUserNameService.saveUserName(userName);
      if (!firestoreSuccess) {
        Log.warning('⚠️ Firestoreへのユーザー名保存に失敗（ローカル保存は成功）');
      }
    }

    Log.info('✅ ユーザー名保存完了: $userName');
  }

  /// サインイン時にFirestoreからユーザー名を復帰
  Future<String?> restoreUserNameFromFirestore() async {
    if (F.appFlavor != Flavor.prod) {
      return null;
    }

    final firestoreName = await FirestoreUserNameService.getUserName();
    if (firestoreName != null && firestoreName.isNotEmpty) {
      // Firestoreから取得した名前をSharedPreferencesにも保存
      await UserPreferencesService.saveUserName(firestoreName);
      return firestoreName;
    }
    return null;
  }

  /// SharedPreferencesからユーザー名を復帰
  Future<String?> restoreUserNameFromPreferences() async {
    return await UserPreferencesService.getUserName();
  }
}

final userNameNotifierProvider = AsyncNotifierProvider<UserNameNotifier, void>(
  () => UserNameNotifier(),
);

// ユーザー名表示用のStateNotifier
class UserNameDisplayNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  UserNameDisplayNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初回読み込み
    await loadUserName();

    // 認証状態の変化を監視
    _ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        // ユーザーがサインインまたは変更された場合、ユーザー名を再読み込み
        if (user != null) {
          Log.info('🔄 認証状態変化を検知、ユーザー名を再読み込み');
          loadUserName();
        }
      });
    });
  }

  Future<void> loadUserName() async {
    try {
      state = const AsyncValue.loading();
      Log.info('📱 ユーザー名読み込み開始');

      // 1. SharedPreferencesから取得
      final userName = await UserPreferencesService.getUserName();
      Log.info('📱 SharedPreferencesから取得したユーザー名: $userName');

      if (userName != null && userName.isNotEmpty) {
        state = AsyncValue.data(userName);
        return;
      }

      // 2. 空の場合、UserSettingsからも試行
      try {
        final userSettingsAsync = _ref.read(userSettingsProvider);
        await userSettingsAsync.when(
          data: (userSettings) async {
            final settingsUserName = userSettings.userName;
            Log.info('📱 UserSettingsから取得したユーザー名: $settingsUserName');

            if (settingsUserName.isNotEmpty) {
              state = AsyncValue.data(settingsUserName);
              // SharedPreferencesにも同期保存
              await UserPreferencesService.saveUserName(settingsUserName);
              return;
            }
          },
          loading: () async {},
          error: (error, stack) async {
            Log.warning('⚠️ UserSettings読み込みエラー: $error');
          },
        );
      } catch (e) {
        Log.warning('⚠️ UserSettings読み込みエラー: $e');
      } // 3. どちらも空の場合はnull
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      Log.error('❌ ユーザー名読み込みエラー: $error');
      state = AsyncValue.error(error, stack);
    }
  }

  // ユーザー名が更新された際に呼び出すメソッド
  Future<void> refresh() async {
    await loadUserName();
  }
}

// リアルタイム更新対応のユーザー名Provider
final userNameProvider =
    StateNotifierProvider<UserNameDisplayNotifier, AsyncValue<String?>>((ref) {
  return UserNameDisplayNotifier(ref);
});
