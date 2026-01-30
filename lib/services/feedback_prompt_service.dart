import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goshopping/utils/app_logger.dart';

/// Firestore からテストステータスを取得・管理するサービス
class FeedbackPromptService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _testStatusPath = 'testingStatus/active';

  /// テスト実施中かどうかを確認
  /// Firestore の /testingStatus/active ドキュメントから isTestingActive フラグを取得
  static Future<bool> isTestingActive() async {
    try {
      final doc = await _firestore.doc(_testStatusPath).get();

      if (!doc.exists) {
        AppLogger.warning('⚠️ [FEEDBACK] testingStatus/active ドキュメントが見つかりません');
        return false;
      }

      final isActive = doc.data()?['isTestingActive'] as bool? ?? false;
      AppLogger.info('🧪 [FEEDBACK] テスト実施中フラグ: $isActive');

      return isActive;
    } catch (e) {
      AppLogger.error('❌ [FEEDBACK] テストステータス確認エラー: $e');
      return false;
    }
  }

  /// 催促メッセージを表示すべきかを判定
  /// - isTestingActive が false → 催促なし
  /// - 5回起動 → 初回催促
  /// - その後は20回ごとに催促（25回、45回、65回...）
  static Future<bool> shouldShowFeedbackPrompt({
    required int launchCount,
    required bool isFeedbackSubmitted,
  }) async {
    AppLogger.info(
        '🔍 [FEEDBACK] 催促判定開始 - 起動回数: $launchCount, 送信済み: $isFeedbackSubmitted');

    // テスト実施中でなければ催促なし
    final testActive = await isTestingActive();
    if (!testActive) {
      AppLogger.info('✅ [FEEDBACK] テスト実施中ではないため催促なし (isTestingActive=false)');
      return false;
    }

    AppLogger.info('🧪 [FEEDBACK] テスト実施中 - 催促条件をチェック');

    // 5回目で初回催促
    if (launchCount == 5) {
      AppLogger.info('🔔 [FEEDBACK] 5回起動達成：初回催促表示');
      return true;
    }

    // 5回以降は20回ごとに催促（25回、45回、65回...）
    if (launchCount > 5 && (launchCount - 5) % 20 == 0) {
      AppLogger.info('🔔 [FEEDBACK] $launchCount回起動達成：定期催促表示（20回ごと）');
      return true;
    }

    AppLogger.info('⏭️ [FEEDBACK] 催促条件未達成 - 催促なし (起動回数: $launchCount)');
    return false;
  }

  /// テスト状態を手動設定（デバッグ用）
  static Future<void> setTestingActive(bool value) async {
    try {
      await _firestore.doc(_testStatusPath).set(
        {'isTestingActive': value},
        SetOptions(merge: true),
      );
      AppLogger.info('✅ [FEEDBACK] テスト状態を更新: $value');
    } catch (e) {
      AppLogger.error('❌ [FEEDBACK] テスト状態更新エラー: $e');
    }
  }
}
