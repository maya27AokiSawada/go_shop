// lib/providers/user_name_provider.dart
import "package:flutter_riverpod/flutter_riverpod.dart";
import '../utils/app_logger.dart';
import "../services/user_preferences_service.dart";
import "../services/firestore_user_name_service.dart";
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

// シンプルなユーザー名表示用Provider（プリファレンスベース）
class UserNameDisplayNotifier extends StateNotifier<AsyncValue<String?>> {
  UserNameDisplayNotifier() : super(const AsyncValue.loading()) {
    Log.info('🚀 UserNameDisplayNotifier: コンストラクタ実行開始');
    // 初期読み込みを即座に実行（再起動時の問題を回避）
    _loadInitialUserName();
    Log.info('🚀 UserNameDisplayNotifier: コンストラクタ実行完了');
  }

  /// 初期ユーザー名をプリファレンスから読み込み
  Future<void> _loadInitialUserName() async {
    try {
      Log.info('🔄 UserNameDisplayNotifier: 初期ユーザー名読み込み開始');
      final userName = await UserPreferencesService.getUserName();
      Log.info('📱 プリファレンスからユーザー名読み込み: $userName');

      if (mounted) {
        state = AsyncValue.data(userName);
        Log.info('✅ UserNameDisplayNotifier: 状態更新完了 - $userName');
      } else {
        Log.warning('⚠️ UserNameDisplayNotifier: mounted=false のため状態更新スキップ');
      }
    } catch (e) {
      Log.error('❌ ユーザー名読み込みエラー: $e');
      if (mounted) {
        state = const AsyncValue.data(null);
      }
    }
  }

  /// プリファレンスから再読み込み（シンプル）
  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final userName = await UserPreferencesService.getUserName();
      Log.info('📱 ユーザー名再読み込み: $userName');

      if (mounted) {
        state = AsyncValue.data(userName);
      }
    } catch (e) {
      Log.warning('⚠️ ユーザー名再読み込みエラー: $e');
      if (mounted) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  /// ユーザー名を更新（プリファレンス + Firestore同期）
  Future<void> updateUserName(String newUserName) async {
    try {
      state = const AsyncValue.loading();

      // 1. SharedPreferencesに保存
      await UserPreferencesService.saveUserName(newUserName);
      Log.info('📱 プリファレンスにユーザー名保存: $newUserName');

      // 2. Firestore同期（一時的に無効化）
      Log.info('🔧 Firestore同期は一時的に無効化されています（デバッグ用）');

      // 3. 状態更新
      if (mounted) {
        state = AsyncValue.data(newUserName);
      }
    } catch (e) {
      Log.error('❌ ユーザー名更新エラー: $e');
      if (mounted) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}

// シンプルなユーザー名Provider（プリファレンスベース）
final userNameProvider =
    StateNotifierProvider<UserNameDisplayNotifier, AsyncValue<String?>>((ref) {
  return UserNameDisplayNotifier();
});
