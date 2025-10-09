import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/app_news.dart';
import '../flavors.dart';

final logger = Logger();

/// Firestoreからアプリニュースを取得するサービス
class FirestoreNewsService {
  static const String _collectionName = 'furestorenews';
  static const String _documentName = 'current_news';

  /// 現在のニュースを取得
  static Future<AppNews> getCurrentNews() async {
    try {
      // DEV環境ではダミーデータを返す
      if (F.appFlavor == Flavor.dev) {
        logger.i('📰 DEV環境: ダミーニュースを返します');
        return AppNews(
          title: '🎉 Go Shop v2.0 リリース！',
          content: 'Go Shopが大幅にアップデートされました！新機能として招待システム、プレミアムプラン、ハイブリッド同期機能が追加されました。ぜひお試しください！',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          actionText: '詳細を見る',
          actionUrl: 'https://example.com/news',
        );
      }

      // PROD環境ではFirestoreから取得
      logger.i('📰 Firestoreからニュースを取得中...');
      final doc = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(_documentName)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        logger.i('📰 ニュース取得成功: ${data['title']}');
        return AppNews.fromMap(data);
      } else {
        logger.w('📰 ニュースドキュメントが存在しません');
        return _getDefaultNews();
      }
    } catch (e) {
      logger.e('📰 ニュース取得エラー: $e');
      return _getDefaultNews();
    }
  }

  /// リアルタイムニュース更新をリッスン
  static Stream<AppNews> watchCurrentNews() {
    try {
      // DEV環境では固定データのストリーム
      if (F.appFlavor == Flavor.dev) {
        return Stream.value(AppNews(
          title: '開発環境でのテスト',
          content: 'これは開発環境でのテストメッセージです。本番環境ではFirestoreから取得されます。',
          createdAt: DateTime.now(),
        ));
      }

      // PROD環境ではFirestoreのリアルタイム更新
      return FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(_documentName)
          .snapshots()
          .map((doc) {
        if (doc.exists && doc.data() != null) {
          return AppNews.fromMap(doc.data()!);
        } else {
          return _getDefaultNews();
        }
      }).handleError((error) {
        logger.e('📰 ニュースストリームエラー: $error');
        return _getDefaultNews();
      });
    } catch (e) {
      logger.e('📰 ニュースストリーム開始エラー: $e');
      return Stream.value(_getDefaultNews());
    }
  }

  /// デフォルトニュースを取得
  static AppNews _getDefaultNews() {
    return AppNews(
      title: 'Go Shopへようこそ！',
      content: 'Go Shopは家族・グループで買い物リストを共有できるアプリです。メンバーを招待して、みんなで買い物を効率化しましょう！',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      actionText: 'はじめる',
      actionUrl: null, // 内部ページなのでnull
    );
  }

  /// ニュース更新（管理者用）
  static Future<void> updateNews({
    required String title,
    required String content,
    String? imageUrl,
    String? actionUrl,
    String? actionText,
    bool isActive = true,
  }) async {
    try {
      if (F.appFlavor == Flavor.dev) {
        logger.i('📰 DEV環境: ニュース更新はスキップされます');
        return;
      }

      final newsData = AppNews(
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: isActive,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        actionText: actionText,
      );

      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(_documentName)
          .set(newsData.toMap());

      logger.i('📰 ニュース更新完了: $title');
    } catch (e) {
      logger.e('📰 ニュース更新エラー: $e');
      rethrow;
    }
  }
}