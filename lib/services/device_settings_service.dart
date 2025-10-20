import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../utils/app_logger.dart';



/// 端末固有の設定管理サービス
class DeviceSettingsService {
  static DeviceSettingsService? _instance;
  static DeviceSettingsService get instance => _instance ??= DeviceSettingsService._();
  
  DeviceSettingsService._();
  
  // 設定キー
  static const String _secretModeKey = 'device_secret_mode';
  static const String _savedEmailKey = 'saved_email_address';
  
  /// 保存されたメールアドレスを取得
  Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_savedEmailKey);
      if (email != null) {
        Log.info('📧 Saved email loaded: $email');
      }
      return email;
    } catch (e) {
      Log.error('❌ Error getting saved email: $e');
      return null;
    }
  }
  
  /// メールアドレスを保存
  Future<void> saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedEmailKey, email);
      Log.info('💾 Email saved: $email');
    } catch (e) {
      Log.error('❌ Error saving email: $e');
      rethrow;
    }
  }
  
  /// 保存されたメールアドレスをクリア
  Future<void> clearSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedEmailKey);
      Log.info('🗑️ Saved email cleared');
    } catch (e) {
      Log.error('❌ Error clearing saved email: $e');
      rethrow;
    }
  }
  
  /// シークレットモードが有効かどうかを取得
  Future<bool> isSecretModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_secretModeKey) ?? false;
      Log.info('🔐 Secret mode status: $isEnabled');
      return isEnabled;
    } catch (e) {
      Log.error('❌ Error getting secret mode: $e');
      return false;
    }
  }
  
  /// シークレットモードのON/OFFを設定
  Future<void> setSecretMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_secretModeKey, enabled);
      Log.info('💾 Secret mode set to: $enabled');
    } catch (e) {
      Log.error('❌ Error setting secret mode: $e');
      rethrow;
    }
  }
  
  /// すべての端末設定をクリア
  Future<void> clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_secretModeKey);
      await prefs.remove(_savedEmailKey);
      Log.info('🗑️ All device settings cleared');
    } catch (e) {
      Log.error('❌ Error clearing settings: $e');
      rethrow;
    }
  }
}