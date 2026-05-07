import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_news.dart';
import '../services/firestore_news_service.dart';
import '../l10n/app_localizations.dart';

/// 現在の表示言語コードを保持するプロバイダー
/// LanguageSettingsPanelで言語変更時に更新される
final newsLanguageCodeProvider = StateProvider<String>((ref) {
  return AppLocalizations.currentLanguageCode;
});

/// 現在のアプリニュースを取得するプロバイダー
final currentNewsProvider = FutureProvider<AppNews>((ref) async {
  final langCode = ref.watch(newsLanguageCodeProvider);
  return await FirestoreNewsService.getCurrentNews(languageCode: langCode);
});

/// リアルタイムニュース更新を監視するプロバイダー
final newsStreamProvider = StreamProvider<AppNews>((ref) {
  final langCode = ref.watch(newsLanguageCodeProvider);
  return FirestoreNewsService.watchCurrentNews(languageCode: langCode);
});

/// ニュースが読み込み中かどうかを示すプロバイダー
final isNewsLoadingProvider = Provider<bool>((ref) {
  final newsAsync = ref.watch(newsStreamProvider);
  return newsAsync.isLoading;
});

/// ニュース表示エラーを取得するプロバイダー
final newsErrorProvider = Provider<String?>((ref) {
  final newsAsync = ref.watch(newsStreamProvider);
  return newsAsync.hasError ? newsAsync.error.toString() : null;
});
