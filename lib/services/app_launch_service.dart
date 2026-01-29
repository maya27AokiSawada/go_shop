import 'package:shared_preferences/shared_preferences.dart';
import 'package:goshopping/utils/app_logger.dart';

/// アプリ起動回数をカウントし管理するサービス
class AppLaunchService {
  static const String _launchCountKey = 'app_launch_count';
  static const String _lastLaunchTimeKey = 'app_last_launch_time';

  /// アプリ起動回数をインクリメント
  static Future<int> incrementLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_launchCountKey) ?? 0;
      final newCount = currentCount + 1;

      await prefs.setInt(_launchCountKey, newCount);
      await prefs.setInt(
          _lastLaunchTimeKey, DateTime.now().millisecondsSinceEpoch);

      AppLogger.info('📱 [APP_LAUNCH] 起動回数更新: $newCount 回');

      return newCount;
    } catch (e) {
      AppLogger.error('❌ [APP_LAUNCH] 起動回数更新エラー: $e');
      return 0;
    }
  }

  /// 現在の起動回数を取得
  static Future<int> getLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_launchCountKey) ?? 0;
    } catch (e) {
      AppLogger.error('❌ [APP_LAUNCH] 起動回数取得エラー: $e');
      return 0;
    }
  }

  /// 起動回数をリセット（デバッグ用）
  static Future<void> resetLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_launchCountKey);
      await prefs.remove(_lastLaunchTimeKey);
      AppLogger.info('🔄 [APP_LAUNCH] 起動回数リセット完了');
    } catch (e) {
      AppLogger.error('❌ [APP_LAUNCH] 起動回数リセットエラー: $e');
    }
  }
}
