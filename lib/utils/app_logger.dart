// lib/utils/app_logger.dart
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
  );

  /// ロガーインスタンスを取得
  static Logger get instance => _instance;

  /// 情報レベルのログ
  static void info(String message) => _instance.i(message);

  /// 警告レベルのログ
  static void warning(String message) => _instance.w(message);

  /// エラーレベルのログ
  static void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _instance.e(message, error: error, stackTrace: stackTrace);

  /// デバッグレベルのログ
  static void debug(String message) => _instance.d(message);

  /// 詳細レベルのログ
  static void verbose(String message) => _instance.t(message);

  /// 成功メッセージ（infoレベル + 絵文字）
  static void success(String message) => _instance.i('✅ $message');

  /// 処理中メッセージ（infoレベル + 絵文字）
  static void processing(String message) => _instance.i('🔄 $message');

  /// 保存メッセージ（infoレベル + 絵文字）
  static void save(String message) => _instance.i('💾 $message');

  /// メール関連メッセージ（infoレベル + 絵文字）
  static void email(String message) => _instance.i('📧 $message');

  /// 招待関連メッセージ（infoレベル + 絵文字）
  static void invitation(String message) => _instance.i('🤝 $message');

  /// セキュリティ関連メッセージ（warningレベル + 絵文字）
  static void security(String message) => _instance.w('🔐 $message');
}

/// 便利なエイリアス
typedef Log = AppLogger;
