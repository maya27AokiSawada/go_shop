import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// エラーログをSharedPreferencesに保存・取得するサービス
///
/// - 最新20件のみ保存（FIFO方式）
/// - ローカル保存のみ（Firestore同期なし）
/// - 軽量でコストゼロ
class ErrorLogService {
  static const String _keyErrorLogs = 'error_logs';
  static const int _maxLogCount = 20;

  /// エラーログを保存
  ///
  /// [errorType]: エラータイプ（permission, network, sync, validation, operation）
  /// [operation]: 実行していた操作（例：「リスト作成」「アイテム追加」）
  /// [message]: エラーメッセージ
  /// [context]: 追加のコンテキスト情報（Map）
  static Future<void> logError({
    required String errorType,
    required String operation,
    required String message,
    Map<String, dynamic>? context,
    String? stackTrace,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 既存のログを取得
      final logs = await getErrorLogs();

      // 新しいログを先頭に追加
      logs.insert(0, {
        'errorType': errorType,
        'operation': operation,
        'message': message,
        'context': context ?? {},
        'stackTrace': stackTrace,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });

      // 最新20件のみ保持（古いものを削除）
      if (logs.length > _maxLogCount) {
        logs.removeRange(_maxLogCount, logs.length);
      }

      // JSON形式で保存
      final jsonString = jsonEncode(logs);
      await prefs.setString(_keyErrorLogs, jsonString);

      AppLogger.debug('📝 エラーログ保存: $operation - $message');
    } catch (e) {
      AppLogger.error('❌ エラーログ保存失敗: $e');
    }
  }

  /// エラーログを取得
  static Future<List<Map<String, dynamic>>> getErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyErrorLogs);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      AppLogger.error('❌ エラーログ取得失敗: $e');
      return [];
    }
  }

  /// エラーログを既読にする
  static Future<void> markAsRead(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = await getErrorLogs();

      if (index >= 0 && index < logs.length) {
        logs[index]['read'] = true;

        final jsonString = jsonEncode(logs);
        await prefs.setString(_keyErrorLogs, jsonString);
      }
    } catch (e) {
      AppLogger.error('❌ エラーログ既読マーク失敗: $e');
    }
  }

  /// 既読エラーログを削除
  static Future<int> deleteReadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = await getErrorLogs();

      final unreadLogs = logs.where((log) => log['read'] != true).toList();
      final deletedCount = logs.length - unreadLogs.length;

      final jsonString = jsonEncode(unreadLogs);
      await prefs.setString(_keyErrorLogs, jsonString);

      AppLogger.info('🗑️ 既読エラーログ削除: $deletedCount件');
      return deletedCount;
    } catch (e) {
      AppLogger.error('❌ 既読エラーログ削除失敗: $e');
      return 0;
    }
  }

  /// 全エラーログを削除
  static Future<void> clearAllLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyErrorLogs);
      AppLogger.info('🗑️ 全エラーログ削除完了');
    } catch (e) {
      AppLogger.error('❌ 全エラーログ削除失敗: $e');
    }
  }

  /// 未読エラーログの件数を取得
  static Future<int> getUnreadCount() async {
    try {
      final logs = await getErrorLogs();
      return logs.where((log) => log['read'] != true).length;
    } catch (e) {
      AppLogger.error('❌ 未読件数取得失敗: $e');
      return 0;
    }
  }

  /// よく使うエラータイプ用のショートカットメソッド

  /// 権限エラーを記録
  static Future<void> logPermissionError(
      String operation, String message) async {
    await logError(
      errorType: 'permission',
      operation: operation,
      message: message,
    );
  }

  /// ネットワークエラーを記録
  static Future<void> logNetworkError(String operation, String message) async {
    await logError(
      errorType: 'network',
      operation: operation,
      message: message,
    );
  }

  /// 同期エラーを記録
  static Future<void> logSyncError(String operation, String message) async {
    await logError(
      errorType: 'sync',
      operation: operation,
      message: message,
    );
  }

  /// 入力検証エラーを記録
  static Future<void> logValidationError(
      String operation, String message) async {
    await logError(
      errorType: 'validation',
      operation: operation,
      message: message,
    );
  }

  /// 操作エラーを記録
  static Future<void> logOperationError(String operation, String message,
      [StackTrace? stackTrace]) async {
    await logError(
      errorType: 'operation',
      operation: operation,
      message: message,
      stackTrace: stackTrace?.toString(),
    );
  }
}
