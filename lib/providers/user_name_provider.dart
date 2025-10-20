// lib/providers/user_name_provider.dart
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:logger/logger.dart";
import '../utils/app_logger.dart';
import "../services/user_preferences_service.dart";
import "../services/firestore_user_name_service.dart";
import "../providers/auth_provider.dart";
import "../flavors.dart";

// Logger instance


// ユーザー名を設定するためのNotifier
class UserNameNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // 初期化は不要
  }

  /// ユーザー名をSharedPreferencesとFirestoreの両方に保存
  Future<void> setUserName(String userName) async {
    // SharedPreferences（ローカル）に保存
    await UserPreferencesService.saveUserName(userName);
    
    // Firestore（クラウド）に保存（本番環境のみ）
    if (F.appFlavor == Flavor.prod) {
      final success = await FirestoreUserNameService.saveUserName(userName);
      if (!success) {
        Log.warning('⚠️ Firestoreへのユーザー名保存に失敗（ローカル保存は成功）');
      }
    }
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

// ユーザー名を取得するためのProvider
final userNameProvider = FutureProvider<String?>((ref) async {
  return await UserPreferencesService.getUserName();
});
