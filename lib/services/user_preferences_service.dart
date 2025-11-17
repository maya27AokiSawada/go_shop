// lib/services/user_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

/// ユーザーの基本情報をSharedPreferencesで管理するサービス
class UserPreferencesService {
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyDataVersion = 'data_version';
  static const String _keyUserId = 'user_id';
  static const String _keySavedEmailForSignIn =
      'saved_email_for_signin'; // ホーム画面ログイン用

  /// ユーザー名を取得
  static Future<String?> getUserName() async {
    return ErrorHandler.handleAsync<String>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final userName = prefs.getString(_keyUserName);
        Log.info('📱 SharedPreferences getUserName: $userName');
        return userName ?? '';
      },
      context: 'USER_PREFS:getUserName',
      defaultValue: null,
    );
  }

  /// ユーザー名を保存
  static Future<bool> saveUserName(String userName) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.setString(_keyUserName, userName);
            Log.info(
                '💾 SharedPreferences saveUserName: $userName - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveUserName',
          defaultValue: false,
        ) ??
        false;
  }

  /// メールアドレスを取得
  static Future<String?> getUserEmail() async {
    return ErrorHandler.handleAsync<String>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString(_keyUserEmail);
        Log.info('📱 SharedPreferences getUserEmail: $userEmail');
        return userEmail ?? '';
      },
      context: 'USER_PREFS:getUserEmail',
      defaultValue: null,
    );
  }

  /// メールアドレスを保存
  static Future<bool> saveUserEmail(String userEmail) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.setString(_keyUserEmail, userEmail);
            Log.info(
                '💾 SharedPreferences saveUserEmail: $userEmail - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveUserEmail',
          defaultValue: false,
        ) ??
        false;
  }

  /// ユーザーIDを取得
  static Future<String?> getUserId() async {
    return ErrorHandler.handleAsync<String>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString(_keyUserId);
        Log.info('📱 SharedPreferences getUserId: $userId');
        return userId ?? '';
      },
      context: 'USER_PREFS:getUserId',
      defaultValue: null,
    );
  }

  /// ユーザーIDを保存
  static Future<bool> saveUserId(String userId) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.setString(_keyUserId, userId);
            Log.info('💾 SharedPreferences saveUserId: $userId - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveUserId',
          defaultValue: false,
        ) ??
        false;
  }

  /// データバージョンを取得
  static Future<int> getDataVersion() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final version = prefs.getInt(_keyDataVersion) ?? 1;
            Log.info('📱 SharedPreferences getDataVersion: $version');
            return version;
          },
          context: 'USER_PREFS:getDataVersion',
          defaultValue: 1,
        ) ??
        1;
  }

  /// データバージョンを保存
  static Future<bool> saveDataVersion(int version) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.setInt(_keyDataVersion, version);
            Log.info(
                '💾 SharedPreferences saveDataVersion: $version - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveDataVersion',
          defaultValue: false,
        ) ??
        false;
  }

  /// ユーザー情報をすべて取得
  static Future<Map<String, dynamic>> getAllUserInfo() async {
    return {
      'userName': await getUserName(),
      'userEmail': await getUserEmail(),
      'userId': await getUserId(),
      'dataVersion': await getDataVersion(),
    };
  }

  /// ユーザー認証情報のみクリア（ユーザー名・UIDは保持）
  /// 注: UIDは次回ログイン時のUID変更検出のため保持する
  static Future<bool> clearAuthInfo() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_keyUserEmail);
            // UIDは削除しない - 次回ログイン時にUID変更を検出するため保持
            // await prefs.remove(_keyUserId);
            Log.info(
                '🗑️ SharedPreferences メールアドレスをクリア完了（ユーザー名・UID・データバージョン保持）');
            return true;
          },
          context: 'USER_PREFS:clearAuthInfo',
          defaultValue: false,
        ) ??
        false;
  }

  /// ユーザー情報をすべてクリア（ユーザー名は保持）
  /// @deprecated clearAuthInfo()を使用してください
  static Future<bool> clearAllUserInfo() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_keyUserEmail);
            await prefs.remove(_keyUserId);
            Log.info('🗑️ SharedPreferences ユーザー情報をクリア完了（ユーザー名は保持）');
            return true;
          },
          context: 'USER_PREFS:clearAllUserInfo',
          defaultValue: false,
        ) ??
        false;
  }

  /// 完全リセット（ユーザー名・データバージョンも含めてすべて削除）
  /// ⚠️ 注意: 開発・デバッグ用途のみ使用。ユーザー名も削除される
  static Future<bool> completeReset() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_keyUserName);
            await prefs.remove(_keyUserEmail);
            await prefs.remove(_keyUserId);
            await prefs.remove(_keyDataVersion);
            await prefs.remove(_keySavedEmailForSignIn);
            Log.info('🔥 SharedPreferences 完全リセット完了（ユーザー名も削除）');
            return true;
          },
          context: 'USER_PREFS:completeReset',
          defaultValue: false,
        ) ??
        false;
  }

  // ==================== ホーム画面サインイン用メールアドレス記憶機能 ====================

  /// サインイン画面用の記憶メールアドレスを取得
  static Future<String?> getSavedEmailForSignIn() async {
    return ErrorHandler.handleAsync<String>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString(_keySavedEmailForSignIn);
        Log.info('📧 記憶メールアドレス取得: $email');
        return email ?? '';
      },
      context: 'USER_PREFS:getSavedEmailForSignIn',
      defaultValue: null,
    );
  }

  /// サインイン画面用のメールアドレスを記憶
  static Future<bool> saveEmailForSignIn(String email) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success =
                await prefs.setString(_keySavedEmailForSignIn, email);
            Log.info('💾 記憶メールアドレス保存: $email - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveEmailForSignIn',
          defaultValue: false,
        ) ??
        false;
  }

  /// サインイン画面用の記憶メールアドレスを削除
  static Future<bool> clearSavedEmailForSignIn() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.remove(_keySavedEmailForSignIn);
            Log.info('🗑️ 記憶メールアドレス削除完了');
            return success;
          },
          context: 'USER_PREFS:clearSavedEmailForSignIn',
          defaultValue: false,
        ) ??
        false;
  }

  /// サインイン画面用メールアドレスを保存または削除
  static Future<bool> saveOrClearEmailForSignIn({
    required String email,
    required bool shouldRemember,
  }) async {
    if (shouldRemember && email.isNotEmpty) {
      return await saveEmailForSignIn(email);
    } else {
      return await clearSavedEmailForSignIn();
    }
  }
}
