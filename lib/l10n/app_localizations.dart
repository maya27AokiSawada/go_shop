import 'app_texts.dart';
import 'app_texts_en.dart';
import 'app_texts_ja.dart';
import 'app_texts_pt.dart';
import 'app_texts_zh_hans.dart';

/// アプリ全体のローカライゼーション管理
///
/// 使用例:
/// ```dart
/// Text(AppLocalizations.current.groupName);
/// ```
class AppLocalizations {
  AppLocalizations._();

  static AppTexts _currentTexts = AppTextsJa();

  /// 現在のローカライゼーションテキストを取得
  static AppTexts get current => _currentTexts;

  /// 言語を変更する
  ///
  /// サポート言語:
  /// - 'ja': 日本語 (デフォルト)
  /// - 'en': 英語
  /// - 'pt': ポルトガル語
  /// - 'zh': 中国語簡体字
  /// - 'es': スペイン語 (未実装)
  static void setLanguage(String languageCode) {
    switch (languageCode) {
      case 'ja':
        _currentTexts = AppTextsJa();
        break;
      case 'en':
        _currentTexts = AppTextsEn();
        break;
      case 'pt':
        _currentTexts = AppTextsPt();
        break;
      case 'zh':
        _currentTexts = AppTextsZhHans();
        break;
      case 'es':
        // TODO: スペイン語実装
        // _currentTexts = AppTextsEs();
        throw UnimplementedError('スペイン語はまだ実装されていません');
      default:
        _currentTexts = AppTextsJa();
    }
  }

  /// 現在の言語コードを取得
  static String get currentLanguageCode {
    if (_currentTexts is AppTextsJa) return 'ja';
    if (_currentTexts is AppTextsEn) return 'en';
    if (_currentTexts is AppTextsPt) return 'pt';
    if (_currentTexts is AppTextsZhHans) return 'zh';
    // if (_currentTexts is AppTextsEs) return 'es';
    return 'ja';
  }

  /// サポートされている言語一覧
  static const List<String> supportedLanguages = [
    'ja', // 日本語
    'en', // 英語
    'pt', // Português
    'zh', // 中文（简体）
    // 'es', // スペイン語 (未実装)
  ];

  /// 言語の表示名を取得
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return '日本語';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文（简体）';
      case 'es':
        return 'Español';
      default:
        return languageCode;
    }
  }

  /// 言語変更時の通知文言を取得
  static String getLanguageChangedMessage(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return current.languageChangedJa;
      default:
        return current.languageChangedEn;
    }
  }
}
