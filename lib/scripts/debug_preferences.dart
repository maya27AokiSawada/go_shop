// lib/scripts/debug_preferences.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_preferences_service.dart';
import '../utils/app_logger.dart';

/// SharedPreferencesの状況をデバッグするスクリプト
void main() async {
  Log.info('🔍 SharedPreferences デバッグ開始\n');

  try {
    // SharedPreferences インスタンスを取得
    final prefs = await SharedPreferences.getInstance();

    Log.info('📱 SharedPreferences 全データ:');
    Log.info('=' * 50);

    // 全キーを取得
    final keys = prefs.getKeys();
    if (keys.isEmpty) {
      Log.warning('⚠️ SharedPreferencesにデータがありません');
    } else {
      for (String key in keys) {
        final value = prefs.get(key);
        Log.info('  $key: $value (${value.runtimeType})');
      }
    }

    Log.info('=' * 50);
    Log.info('\n🎯 ユーザー関連データの詳細確認:');

    // UserPreferencesServiceを使用してデータ確認
    final userName = await UserPreferencesService.getUserName();
    final userEmail = await UserPreferencesService.getUserEmail();
    final userId = await UserPreferencesService.getUserId();
    final dataVersion = await UserPreferencesService.getDataVersion();

    Log.info('📛 ユーザー名: $userName');
    Log.info('📧 メール: $userEmail');
    Log.info('🆔 ユーザーID: $userId');
    Log.info('📊 データバージョン: $dataVersion');

    // 全ユーザー情報を取得
    final allInfo = await UserPreferencesService.getAllUserInfo();
    Log.info('\n📋 全ユーザー情報:');
    allInfo.forEach((key, value) {
      Log.info('  $key: $value');
    });
  } catch (e, stackTrace) {
    Log.error('❌ エラー: $e');
    Log.info('スタックトレース: $stackTrace');
  }
}
