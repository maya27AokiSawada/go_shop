import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../models/app_news.dart';
import '../flavors.dart';

/// Firestoreからアプリニュースを取得するサービス
class FirestoreNewsService {
  static const String _collectionName = 'furestorenews';
  static const String _documentName = 'current_news';

  /// 現在のニュースを取得
  static Future<AppNews> getCurrentNews() async {
    try {
      // Firestoreから取得
      Log.info('📰 Firestoreからニュースを取得中...');
      final doc = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(_documentName)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        Log.info('📰 ニュース取得成功: ${data['title']}');
        return AppNews.fromMap(data);
      } else {
        Log.warning('📰 ニュースドキュメントが存在しません');
        return _getDefaultNews();
      }
    } catch (e) {
      Log.error('📰 ニュース取得エラー: $e');
      return _getDefaultNews();
    }
  }

  /// リアルタイムニュース更新をリッスン
  static Stream<AppNews> watchCurrentNews() {
    try {
      // DEV環境では固定データのストリーム
      if (F.appFlavor == Flavor.dev) {
        Log.info('📰 DEV環境: 固定ニュースを返します');
        return Stream.value(AppNews(
          title: '開発環境でのテスト',
          content: 'これは開発環境でのテストメッセージです。本番環境ではFirestoreから取得されます。',
          createdAt: DateTime.now(),
        ));
      }

      // PROD環境ではFirestoreのリアルタイム更新
      Log.info('📰 PROD環境: Firestoreストリームを開始');
      Log.info('📰 コレクション名: $_collectionName, ドキュメント名: $_documentName');

      return FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(_documentName)
          .snapshots()
          .timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) {
          Log.warning('📰 Firestoreタイムアウト（30秒）: デフォルトニュースを使用');
          sink.close();
        },
      ).map((doc) {
        Log.info(
            '📰 [DEBUG] スナップショット受信: exists=${doc.exists}, isFromCache=${doc.metadata.isFromCache}');

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            Log.info('📰 [DEBUG] データ取得成功 - キー: ${data.keys.join(", ")}');
            Log.info('📰 [DEBUG] title: ${data['title']}');
            return AppNews.fromMap(data);
          } else {
            Log.warning('📰 [DEBUG] doc.data()がnull');
          }
        } else {
          Log.warning('📰 [DEBUG] doc.existsがfalse');
        }

        Log.warning('📰 ドキュメントが存在しません: デフォルトニュースを返します');
        return _getDefaultNews();
      }).handleError((error) {
        Log.error('📰 ニュースストリームエラー: $error');
      }).handleError((error) {
        // タイムアウトエラーを捕捉してデフォルトニュースを返す
        return Stream.value(_getDefaultNews());
      });
    } catch (e) {
      Log.error('📰 ニュースストリーム開始エラー: $e');
      return Stream.value(_getDefaultNews());
    }
  }

  /// デフォルトニュースを取得
  static AppNews _getDefaultNews() {
    return AppNews(
      title: 'GoShoppingへようこそ！',
      content:
          'GoShoppingは家族・グループで買い物リストを共有できるアプリです。メンバーを招待して、みんなで買い物を効率化しましょう！',
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
        Log.info('📰 DEV環境: ニュース更新はスキップされます');
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

      Log.info('📰 ニュース更新完了: $title');
    } catch (e) {
      Log.error('📰 ニュース更新エラー: $e');
      rethrow;
    }
  }
}
