// lib/services/user_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';


/// ユーザーの基本情報をSharedPreferencesで管理するサービス
class UserPreferencesService {
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyDataVersion = 'data_version';
  static const String _keyUserId = 'user_id';

  /// ユーザー名を取得
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString(_keyUserName);
      Log.info('📱 SharedPreferences getUserName: $userName');
      return userName;
    } catch (e) {
      Log.error('❌ SharedPreferences getUserName エラー: $e');
      return null;
    }
  }

  /// ユーザー名を保存
  static Future<bool> saveUserName(String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_keyUserName, userName);
      Log.info('💾 SharedPreferences saveUserName: $userName - 成功: $success');
      return success;
    } catch (e) {
      Log.error('❌ SharedPreferences saveUserName エラー: $e');
      return false;
    }
  }

  /// メールアドレスを取得
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString(_keyUserEmail);
      Log.info('📱 SharedPreferences getUserEmail: $userEmail');
      return userEmail;
    } catch (e) {
      Log.error('❌ SharedPreferences getUserEmail エラー: $e');
      return null;
    }
  }

  /// メールアドレスを保存
  static Future<bool> saveUserEmail(String userEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_keyUserEmail, userEmail);
      Log.info('💾 SharedPreferences saveUserEmail: $userEmail - 成功: $success');
      return success;
    } catch (e) {
      Log.error('❌ SharedPreferences saveUserEmail エラー: $e');
      return false;
    }
  }

  /// ユーザーIDを取得
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_keyUserId);
      Log.info('📱 SharedPreferences getUserId: $userId');
      return userId;
    } catch (e) {
      Log.error('❌ SharedPreferences getUserId エラー: $e');
      return null;
    }
  }

  /// ユーザーIDを保存
  static Future<bool> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_keyUserId, userId);
      Log.info('💾 SharedPreferences saveUserId: $userId - 成功: $success');
      return success;
    } catch (e) {
      Log.error('❌ SharedPreferences saveUserId エラー: $e');
      return false;
    }
  }

  /// データバージョンを取得
  static Future<int> getDataVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt(_keyDataVersion) ?? 1; // デフォルト値 1
      Log.info('📱 SharedPreferences getDataVersion: $version');
      return version;
    } catch (e) {
      Log.error('❌ SharedPreferences getDataVersion エラー: $e');
      return 1; // エラー時はバージョン1を返す
    }
  }

  /// データバージョンを保存
  static Future<bool> saveDataVersion(int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setInt(_keyDataVersion, version);
      Log.info('💾 SharedPreferences saveDataVersion: $version - 成功: $success');
      return success;
    } catch (e) {
      Log.error('❌ SharedPreferences saveDataVersion エラー: $e');
      return false;
    }
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

  /// ユーザー情報をすべてクリア
  static Future<bool> clearAllUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserId);
      // データバージョンは削除しない（次回起動時の判定に必要）
      Log.info('🗑️ SharedPreferences 全ユーザー情報をクリア完了');
      return true;
    } catch (e) {
      Log.error('❌ SharedPreferences clearAllUserInfo エラー: $e');
      return false;
    }
  }

  /// 完全リセット（データバージョンも含めてすべて削除）
  static Future<bool> completeReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyDataVersion);
      Log.info('🔥 SharedPreferences 完全リセット完了');
      return true;
    } catch (e) {
      Log.error('❌ SharedPreferences completeReset エラー: $e');
      return false;
    }
  }
}