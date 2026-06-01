import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../models/app_news.dart';
import '../flavors.dart';

/// Firestoreからアプリニュースを取得するサービス
class FirestoreNewsService {
  static const String _collectionName = 'firestoreNews';
  static const String _documentName = 'current_news';
  static const String _documentNameEn = 'current_news_eng';

  /// 言語コードからドキュメント名を返す
  static String _docName(String languageCode) =>
      languageCode == 'en' ? _documentNameEn : _documentName;

  /// 現在のニュースを取得
  static Future<AppNews> getCurrentNews({String languageCode = 'ja'}) async {
    final docName = _docName(languageCode);
    try {
      // Firestoreから取得
      Log.info('📰 Firestoreからニュースを取得中... (lang=$languageCode, doc=$docName)');
      final doc = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(docName)
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
  static Stream<AppNews> watchCurrentNews({String languageCode = 'ja'}) {
    final docName = _docName(languageCode);
    try {
      // DEV環境では固定データのストリーム
      if (F.appFlavor == Flavor.dev) {
        Log.info('📰 DEV環境: 固定ニュースを返します');
        return Stream.value(AppNews(
          title: languageCode == 'en' ? 'Dev Environment Test' : '開発環境でのテスト',
          content: languageCode == 'en'
              ? 'This is a test message for the dev environment. In production, this is fetched from Firestore.'
              : 'これは開発環境でのテストメッセージです。本番環境ではFirestoreから取得されます。',
          createdAt: DateTime.now(),
        ));
      }

      // PROD環境ではFirestoreのリアルタイム更新
      Log.info(
          '📰 PROD環境: Firestoreストリームを開始 (lang=$languageCode, doc=$docName)');

      return FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(docName)
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
        return _getDefaultNews(languageCode: languageCode);
      }).handleError((error) {
        Log.error('📰 ニュースストリームエラー: $error');
      }).handleError((error) {
        // タイムアウトエラーを捕捉してデフォルトニュースを返す
        return Stream.value(_getDefaultNews(languageCode: languageCode));
      });
    } catch (e) {
      Log.error('📰 ニュースストリーム開始エラー: $e');
      return Stream.value(_getDefaultNews(languageCode: languageCode));
    }
  }

  /// デフォルトニュースを取得
  static AppNews _getDefaultNews({String languageCode = 'ja'}) {
    if (languageCode == 'en') {
      return AppNews(
        title: 'Welcome to GoShopping!',
        content:
            'GoShopping lets you share shopping lists with family and groups. Invite members and shop efficiently together!',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        actionText: 'Get Started',
        actionUrl: null,
      );
    }
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
