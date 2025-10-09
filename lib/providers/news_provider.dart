import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_news.dart';
import '../services/firestore_news_service.dart';

/// 現在のアプリニュースを取得するプロバイダー
final currentNewsProvider = FutureProvider<AppNews>((ref) async {
  return await FirestoreNewsService.getCurrentNews();
});

/// リアルタイムニュース更新を監視するプロバイダー
final newsStreamProvider = StreamProvider<AppNews>((ref) {
  return FirestoreNewsService.watchCurrentNews();
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