import 'app_texts.dart';
import 'app_texts_en.dart';
import 'app_texts_ja.dart';
import 'app_texts_pt.dart';
import 'app_texts_zh_hans.dart';
import 'app_texts_zh_hant.dart';

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
  /// - 'zh_Hant': 中国語繁体字（台湾）
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
      case 'zh_Hant':
        _currentTexts = AppTextsZhHant();
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
  ///
  /// pt / zh / zh_Hant の各クラスは [AppTextsEn] を継承しているため、
  /// [AppTextsEn] の判定より先にサブクラスを判定すること。
  static String get currentLanguageCode {
    if (_currentTexts is AppTextsJa) return 'ja';
    if (_currentTexts is AppTextsPt) return 'pt';
    if (_currentTexts is AppTextsZhHans) return 'zh';
    if (_currentTexts is AppTextsZhHant) return 'zh_Hant';
    // if (_currentTexts is AppTextsEs) return 'es';
    if (_currentTexts is AppTextsEn) return 'en';
    return 'ja';
  }

  /// 日本語以外のコンテンツ（ニュース・法的文書・日付書式など）は英語版を使う
  ///
  /// 翻訳済みのアプリ内テキスト（[AppTexts]）とは別に、日本語版と英語版しか
  /// 用意していないコンテンツで使う。
  static bool usesJapaneseContent(String languageCode) => languageCode == 'ja';

  /// 現在の言語で日本語版のコンテンツを使うか
  static bool get isJapaneseContent =>
      usesJapaneseContent(currentLanguageCode);

  /// サポートされている言語一覧
  static const List<String> supportedLanguages = [
    'ja', // 日本語
    'en', // 英語
    'pt', // Português
    'zh', // 中文（简体）
    'zh_Hant', // 中文（繁體）
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
      case 'zh_Hant':
        return '中文（繁體）';
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
