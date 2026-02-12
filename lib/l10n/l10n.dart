/// 多言語対応システム
///
/// このパッケージは、アプリ全体の文字列を多言語対応するための仕組みを提供します。
///
/// ## 使用方法
///
/// ### 基本的な使い方
/// ```dart
/// import 'package:goshopping/l10n/l10n.dart';
///
/// Text(texts.groupName);  // "グループ名"
/// Text(texts.createGroup);  // "グループを作成"
/// ```
///
/// ### 言語切り替え
/// ```dart
/// AppLocalizations.setLanguage('en');  // 英語に切り替え
/// AppLocalizations.setLanguage('ja');  // 日本語に切り替え
/// ```
///
/// ### 現在の言語確認
/// ```dart
/// String currentLang = AppLocalizations.currentLanguageCode;  // 'ja'
/// ```
///
/// ## 実装状況
///
/// - ✅ 日本語 (ja) - 実装済み
/// - ⏳ 英語 (en) - 未実装
/// - ⏳ 中国語 (zh) - 未実装
/// - ⏳ スペイン語 (es) - 未実装
///
/// ## 新しい言語の追加方法
///
/// 1. `lib/l10n/app_texts_XX.dart` を作成（XX は言語コード）
/// 2. `AppTexts` を継承して実装
/// 3. `app_localizations.dart` の `setLanguage()` に追加
///
/// ```dart
/// // app_texts_en.dart
/// class AppTextsEn extends AppTexts {
///   @override
///   String get appName => 'GoShopping';
///
///   @override
///   String get createGroup => 'Create Group';
///
///   // ...
/// }
/// ```
library l10n;

export 'app_texts.dart';
export 'app_texts_ja.dart';
export 'app_localizations.dart';

/// グローバルアクセス用のショートカット
///
/// 使用例:
/// ```dart
/// Text(texts.groupName);
/// ```
import 'app_localizations.dart';

AppTexts get texts => AppLocalizations.current;
