// lib/utils/app_logger.dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// アプリケーション全体で使用する統一されたロガー
class AppLogger {
  static final Logger _instance = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    output: ConsoleOutput(), // 常にlogger出力を有効化
  );

  /// ロガーインスタンスを取得
  static Logger get instance => _instance;

  /// プライバシー保護: ユーザーIDを隠蔽（最初の3文字のみ表示）
  static String maskUserId(String? userId) {
    if (userId == null || userId.isEmpty) return '***';
    if (userId.length <= 3) return userId;
    return '${userId.substring(0, 3)}***';
  }

  /// プライバシー保護: 名前を隠蔽（最初の2文字のみ表示）
  static String maskName(String? name) {
    if (name == null || name.isEmpty) return '**';
    if (name.length <= 2) return name;
    return '${name.substring(0, 2)}***';
  }

  /// プライバシー保護: グループ情報を隠蔽
  static String maskGroup(String? groupName, String? groupId) {
    final name = maskName(groupName);
    final id = groupId ?? '***';
    return '$name($id)';
  }

  /// プライバシー保護: リスト情報を隠蔽
  static String maskList(String? listName, String? listId) {
    final name = maskName(listName);
    final id = listId ?? '***';
    return '$name($id)';
  }

  /// プライバシー保護: アイテム情報を隠蔽
  static String maskItem(String? itemName, String? itemId) {
    final name = maskName(itemName);
    final id = itemId ?? '***';
    return '$name($id)';
  }

  /// プライバシー保護: グループIDを隠蔽（デフォルトグループの場合のみ）
  /// デフォルトグループのgroupIdはユーザーのUIDと同じため隠蔽が必要
  static String maskGroupId(String? groupId, {String? currentUserId}) {
    if (groupId == null || groupId.isEmpty) return '***';

    // デフォルトグループの判定
    // 1. groupId == 'default_group' (レガシー)
    // 2. groupId == currentUserId (正式仕様)
    final isDefaultGroup = groupId == 'default_group' ||
        (currentUserId != null && groupId == currentUserId);

    if (isDefaultGroup) {
      return maskUserId(groupId); // 最初の3文字のみ表示
    }

    return groupId; // 通常のグループIDはそのまま表示
  }

  /// 情報レベルのログ
  static void info(String message) {
    _instance.i(message);
    debugPrint(message);
  }

  /// 警告レベルのログ
  static void warning(String message) {
    _instance.w(message);
    debugPrint('⚠️ $message');
  }

  /// エラーレベルのログ
  /// 使い方:
  /// - Log.error('エラーメッセージ')
  /// - Log.error('エラーメッセージ', e)
  /// - Log.error('エラーメッセージ', e, stackTrace)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // Backward-compatible guard: some older call sites pass StackTrace as the
    // second positional argument. The logger package rejects a StackTrace in
    // the error slot, so normalize it here instead of crashing while logging.
    if (error is StackTrace && stackTrace == null) {
      stackTrace = error;
      error = null;
    }

    if (error != null && stackTrace != null) {
      _instance.e(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      _instance.e(message, error: error);
    } else {
      _instance.e(message);
    }
    debugPrint('❌ $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   StackTrace: $stackTrace');
    }
  }

  /// デバッグレベルのログ
  static void debug(String message) {
    _instance.d(message);
    debugPrint('🐛 $message');
  }

  /// 詳細レベルのログ
  static void verbose(String message) {
    _instance.t(message);
    debugPrint('📝 $message');
  }

  /// 成功メッセージ（infoレベル + 絵文字）
  static void success(String message) {
    _instance.i('✅ $message');
    debugPrint('✅ $message');
  }

  /// 処理中メッセージ（infoレベル + 絵文字）
  static void processing(String message) {
    _instance.i('🔄 $message');
    debugPrint('🔄 $message');
  }

  /// 保存メッセージ（infoレベル + 絵文字）
  static void save(String message) {
    _instance.i('💾 $message');
    debugPrint('💾 $message');
  }

  /// メール関連メッセージ（infoレベル + 絵文字）
  static void email(String message) {
    _instance.i('📧 $message');
    debugPrint('📧 $message');
  }

  /// 招待関連メッセージ（infoレベル + 絵文字）
  static void invitation(String message) {
    _instance.i('🤝 $message');
    debugPrint('🤝 $message');
  }

  /// セキュリティ関連メッセージ（warningレベル + 絵文字）
  static void security(String message) {
    _instance.w('🔐 $message');
    debugPrint('🔐 $message');
  }
}

/// 便利なエイリアス
typedef Log = AppLogger;
