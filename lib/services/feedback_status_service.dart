import 'package:shared_preferences/shared_preferences.dart';
import 'package:goshopping/utils/app_logger.dart';

/// フィードバック送信状態を管理するサービス
class FeedbackStatusService {
  static const String _feedbackSubmittedKey = 'feedback_submitted';
  static const String _feedbackSubmitTimeKey = 'feedback_submit_time';

  /// フィードバックを送信済みにマーク
  static Future<void> markFeedbackSubmitted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_feedbackSubmittedKey, true);
      await prefs.setInt(
          _feedbackSubmitTimeKey, DateTime.now().millisecondsSinceEpoch);

      AppLogger.info('✅ [FEEDBACK] フィードバック送信済みにマーク');
    } catch (e) {
      AppLogger.error('❌ [FEEDBACK] フィードバック状態保存エラー: $e');
    }
  }

  /// フィードバック送信済みかどうかを確認
  static Future<bool> isFeedbackSubmitted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_feedbackSubmittedKey) ?? false;
    } catch (e) {
      AppLogger.error('❌ [FEEDBACK] フィードバック状態確認エラー: $e');
      return false;
    }
  }

  /// フィードバック送信状態をリセット（デバッグ用）
  static Future<void> resetFeedbackStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_feedbackSubmittedKey);
      await prefs.remove(_feedbackSubmitTimeKey);
      AppLogger.info('🔄 [FEEDBACK] フィードバック状態リセット完了');
    } catch (e) {
      AppLogger.error('❌ [FEEDBACK] フィードバック状態リセットエラー: $e');
    }
  }

  /// 送信時刻を取得
  static Future<DateTime?> getFeedbackSubmitTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_feedbackSubmitTimeKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      AppLogger.error('❌ [FEEDBACK] 送信時刻取得エラー: $e');
      return null;
    }
  }
}
