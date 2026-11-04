import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/l10n/l10n.dart';

void main() {
  tearDown(() => AppLocalizations.setLanguage('ja'));

  test('すべてのサポート言語が切り替え後に同じ言語コードを返し、表示名がある', () {
    for (final code in AppLocalizations.supportedLanguages) {
      AppLocalizations.setLanguage(code);
      expect(AppLocalizations.currentLanguageCode, code);
      expect(AppLocalizations.getLanguageName(code), isNot(code));
    }
  });

  test('日本語以外のコンテンツは英語版を使う', () {
    for (final code in AppLocalizations.supportedLanguages) {
      AppLocalizations.setLanguage(code);
      expect(AppLocalizations.isJapaneseContent, code == 'ja', reason: code);
    }
  });

  test('zh_Hant で繁体字のテキストに切り替わる', () {
    AppLocalizations.setLanguage('zh_Hant');
    expect(AppLocalizations.current, isA<AppTextsZhHant>());
    expect(AppLocalizations.getLanguageName('zh_Hant'), '中文（繁體）');
    expect(texts.signIn, '登入');
    expect(texts.languageChangedEn, contains('繁體中文'));
  });

  test('zh は従来どおり簡体字のまま', () {
    AppLocalizations.setLanguage('zh');
    expect(AppLocalizations.current, isA<AppTextsZhHans>());
    expect(texts.signIn, '登录');
  });
}
