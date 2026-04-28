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
  static const String _keySelectedGroupId = 'selected_group_id';
  static const String _keyCurrentListId = 'current_list_id';
  static const String _keyGroupListMap = 'group_list_map';

  // UserSettings相当のキー（Hive Boxから移行）
  static const String _keyLastUsedGroupId = 'last_used_group_id';
  static const String _keyLastUsedSharedListId = 'last_used_shared_list_id';
  static const String _legacyKeyLastUsedSharedListId =
      'last_used_shopping_list_id';
  static const String _keyAppMode = 'app_mode'; // 0=shopping, 1=todo
  static const String _keyAppUIMode = 'app_ui_mode'; // 0=single, 1=multi
  static const String _keyEnableListNotifications = 'enable_list_notifications';

  // 課金タイプキャッシュ（Firestoreデータロスト時のフォールバック用）
  static const String _keyPurchaseTypeCache = 'purchase_type_cache';
  static const String _keyPurchaseTypeCacheTimestamp =
      'purchase_type_cache_timestamp';

  /// ユーザー名を取得
  static Future<String?> getUserName() async {
    return ErrorHandler.handleAsync<String>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final userName = prefs.getString(_keyUserName);
        Log.info(
            '📱 SharedPreferences getUserName: ${AppLogger.maskName(userName)}');
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
        Log.info(
            '📱 SharedPreferences getUserId: ${AppLogger.maskUserId(userId)}');
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
            Log.info(
                '💾 SharedPreferences saveUserId: ${AppLogger.maskUserId(userId)} - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveUserId',
          defaultValue: false,
        ) ??
        false;
  }

  /// ユーザーIDをクリア（ログアウト時のUID変更検出用）
  static Future<bool> clearUserId() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.remove(_keyUserId);
            Log.info('🗑️ SharedPreferences clearUserId - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:clearUserId',
          defaultValue: false,
        ) ??
        false;
  }

  /// データバージョンを取得
  static Future<int> getDataVersion() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            // ✅ Anti-5 対応: 未保存 = 旧版ではなく初回起動扱い
            if (!prefs.containsKey(_keyDataVersion)) {
              Log.warning('⚠️ [DATA_VERSION] キー未保存 - containsKey ガードなしで呼出し。'
                  '呼び出し元で containsKey を確認してから呼ぶこと');
              // 旧版（v1）と誤認しないために -1 を返す
              // 呼び出し元で containsKey チェック後に呼ぶのが正しい使い方
              return -1;
            }
            final version = prefs.getInt(_keyDataVersion)!;
            Log.info('📱 SharedPreferences getDataVersion: $version');
            return version;
          },
          context: 'USER_PREFS:getDataVersion',
          defaultValue: -1, // 例外時も -1（未設定扱い）
        ) ??
        -1;
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

  /// ユーザー切り替え時のローカル状態をクリア
  ///
  /// 記憶したサインイン用メールアドレスやアプリ設定は保持し、
  /// 前ユーザーに紐づく表示・選択・キャッシュ参照キーだけを削除する。
  static Future<bool> clearUserSwitchState() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_keyUserName);
            await prefs.remove(_keyUserEmail);
            await prefs.remove(_keyUserId);
            await prefs.remove(_keySelectedGroupId);
            await prefs.remove(_keyLastUsedGroupId);
            await prefs.remove(_keyLastUsedSharedListId);
            await prefs.remove(_keyCurrentListId);
            await prefs.remove(_keyGroupListMap);
            Log.info('🗑️ SharedPreferences ユーザー切り替え状態をクリア完了');
            return true;
          },
          context: 'USER_PREFS:clearUserSwitchState',
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

  // ==================== UserSettings機能（Hive Boxから移行） ====================

  /// 最後に使用したグループIDを取得
  static Future<String> getLastUsedGroupId() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final groupId = prefs.getString(_keyLastUsedGroupId) ?? '';
            Log.info('📱 最後に使用したグループID: $groupId');
            return groupId;
          },
          context: 'USER_PREFS:getLastUsedGroupId',
          defaultValue: '',
        ) ??
        '';
  }

  /// 最後に使用したグループIDを保存
  static Future<bool> saveLastUsedGroupId(String groupId) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.setString(_keyLastUsedGroupId, groupId);
            Log.info('💾 最後に使用したグループID保存: $groupId - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveLastUsedGroupId',
          defaultValue: false,
        ) ??
        false;
  }

  /// 最後に使用したリストIDを取得
  static Future<String> getLastUsedSharedListId() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final listId = prefs.getString(_keyLastUsedSharedListId) ??
                prefs.getString(_legacyKeyLastUsedSharedListId) ??
                '';
            Log.info('📱 最後に使用したリストID: $listId');
            return listId;
          },
          context: 'USER_PREFS:getLastUsedSharedListId',
          defaultValue: '',
        ) ??
        '';
  }

  /// 最後に使用したリストIDを保存
  static Future<bool> saveLastUsedSharedListId(String listId) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success =
                await prefs.setString(_keyLastUsedSharedListId, listId);
            if (success) {
              await prefs.remove(_legacyKeyLastUsedSharedListId);
            }
            Log.info('💾 最後に使用したリストID保存: $listId - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveLastUsedSharedListId',
          defaultValue: false,
        ) ??
        false;
  }

  /// アプリモードを取得（0=shopping, 1=todo）
  static Future<int> getAppMode() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final mode = prefs.getInt(_keyAppMode) ?? 0;
            Log.info('📱 アプリモード: $mode (0=shopping, 1=todo)');
            return mode;
          },
          context: 'USER_PREFS:getAppMode',
          defaultValue: 0,
        ) ??
        0;
  }

  /// アプリモードを保存（0=shopping, 1=todo）
  static Future<bool> saveAppMode(int mode) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.setInt(_keyAppMode, mode);
            Log.info('💾 アプリモード保存: $mode (0=shopping, 1=todo) - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveAppMode',
          defaultValue: false,
        ) ??
        false;
  }

  /// UIモードを取得（0=single, 1=multi）
  static Future<int> getAppUIMode() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final mode = prefs.getInt(_keyAppUIMode) ?? 0;
            Log.info('📱 UIモード: $mode (0=single, 1=multi)');
            return mode;
          },
          context: 'USER_PREFS:getAppUIMode',
          defaultValue: 0,
        ) ??
        0;
  }

  /// UIモードを保存（0=single, 1=multi）
  static Future<bool> saveAppUIMode(int mode) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success = await prefs.setInt(_keyAppUIMode, mode);
            Log.info('💾 UIモード保存: $mode (0=single, 1=multi) - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveAppUIMode',
          defaultValue: false,
        ) ??
        false;
  }

  /// リスト通知設定を取得
  static Future<bool> getEnableListNotifications() async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final enabled = prefs.getBool(_keyEnableListNotifications) ?? true;
            Log.info('📱 リスト通知設定: $enabled');
            return enabled;
          },
          context: 'USER_PREFS:getEnableListNotifications',
          defaultValue: true,
        ) ??
        true;
  }

  /// リスト通知設定を保存
  static Future<bool> saveEnableListNotifications(bool enabled) async {
    return await ErrorHandler.handleAsync(
          operation: () async {
            final prefs = await SharedPreferences.getInstance();
            final success =
                await prefs.setBool(_keyEnableListNotifications, enabled);
            Log.info('💾 リスト通知設定保存: $enabled - 成功: $success');
            return success;
          },
          context: 'USER_PREFS:saveEnableListNotifications',
          defaultValue: false,
        ) ??
        false;
  }

  // ==================== 課金タイプキャッシュ（Firestoreロスト対策） ====================

  /// 課金タイプをローカルにキャッシュ保存
  ///
  /// Firestoreデータがロストした場合のフォールバック用。
  /// [value] は `'free'` / `'subscribe'` / `'purchase'` のいずれか。
  static Future<void> savePurchaseTypeCache(String value) async {
    await ErrorHandler.handleAsync(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyPurchaseTypeCache, value);
        await prefs.setInt(
          _keyPurchaseTypeCacheTimestamp,
          DateTime.now().millisecondsSinceEpoch,
        );
        Log.info('💾 課金タイプキャッシュ保存: $value');
      },
      context: 'USER_PREFS:savePurchaseTypeCache',
      defaultValue: null,
    );
  }

  /// キャッシュされた課金タイプを取得
  ///
  /// 90日以上古いキャッシュは無効とし `null` を返す。
  /// `null` の場合は呼び出し元で `'free'` にフォールバックすること。
  static Future<String?> loadPurchaseTypeCache() async {
    return await ErrorHandler.handleAsync<String?>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getString(_keyPurchaseTypeCache);
        if (value == null) return null;

        final timestamp = prefs.getInt(_keyPurchaseTypeCacheTimestamp);
        if (timestamp != null) {
          final age = DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
          if (age.inDays > 90) {
            Log.info('⚠️ 課金タイプキャッシュが古すぎます (${age.inDays}日): 無効化');
            return null;
          }
        }

        Log.info('📱 課金タイプキャッシュ取得: $value');
        return value;
      },
      context: 'USER_PREFS:loadPurchaseTypeCache',
      defaultValue: null,
    );
  }

  /// 課金タイプキャッシュをクリア（ログアウト時など）
  static Future<void> clearPurchaseTypeCache() async {
    await ErrorHandler.handleAsync(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyPurchaseTypeCache);
        await prefs.remove(_keyPurchaseTypeCacheTimestamp);
        Log.info('🗑️ 課金タイプキャッシュをクリア');
      },
      context: 'USER_PREFS:clearPurchaseTypeCache',
      defaultValue: null,
    );
  }
}
