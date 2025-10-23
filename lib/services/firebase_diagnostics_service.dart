import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

import '../helper/firebase_diagnostics.dart';

/// Firebase診断サービス
/// Firebase接続テストと完全診断を提供
class FirebaseDiagnosticsService {
  FirebaseDiagnosticsService._();

  /// Firebase完全診断を実行
  ///
  /// Returns: DiagnosticsResult (診断結果とソリューション)
  static Future<DiagnosticsResult> runFullDiagnostics() async {
    try {
      Log.info('🩺 === Firebase完全診断開始 ===');

      // Firebase診断実行
      final diagnostics = await FirebaseDiagnostics.runDiagnostics();
      final solutions = FirebaseDiagnostics.getSolutions(diagnostics);

      // 結果をログ出力
      Log.info('📊 診断結果:');
      diagnostics.forEach((key, value) {
        Log.info('  $key: $value');
      });

      Log.info('💡 推奨解決策:');
      for (final solution in solutions) {
        Log.info('  $solution');
      }

      // 診断結果を判定
      final isHealthy = diagnostics['firestore_connection'] == true &&
          diagnostics['firestore_write'] == true;

      return DiagnosticsResult(
        isHealthy: isHealthy,
        diagnostics: diagnostics,
        solutions: solutions,
      );
    } catch (e) {
      Log.error('⛔ Firebase診断エラー: $e');
      return DiagnosticsResult(
        isHealthy: false,
        diagnostics: {},
        solutions: [],
        error: e.toString(),
      );
    }
  }

  /// Firebase接続テストを実行
  ///
  /// Firestoreへの読み書きテストを実行し、接続状態を確認
  /// Returns: ConnectionTestResult (テスト結果)
  static Future<ConnectionTestResult> runConnectionTest() async {
    try {
      // Firestoreインスタンスを取得
      final firestore = FirebaseFirestore.instance;

      // テスト用ドキュメントを作成
      final testDocRef = firestore
          .collection('connection_test')
          .doc('test_${DateTime.now().millisecondsSinceEpoch}');

      Log.info('🔥 Firebase接続テスト: Firestoreへの書き込みを試行中...');

      // Firestoreに書き込み
      await testDocRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test_data': 'Firebase connection test from Go Shop app',
        'user_agent': 'Flutter App',
      });

      Log.info('✅ Firebase接続テスト: 書き込み成功');

      // 書き込み直後に読み込みテスト
      final doc = await testDocRef.get();
      if (doc.exists) {
        Log.info('✅ Firebase接続テスト: 読み込み成功');
        Log.info('📄 Document data: ${doc.data()}');

        // テスト用ドキュメントを削除
        await testDocRef.delete();
        Log.info('🗑️ Firebase接続テスト: クリーンアップ完了');

        return ConnectionTestResult(
          success: true,
          message: '✅ Firebase接続テスト成功！読み書き共に正常',
          documentData: doc.data(),
        );
      } else {
        throw Exception('Document was not created');
      }
    } catch (e) {
      Log.error('⛔ Firebase接続テストエラー: $e');
      return ConnectionTestResult(
        success: false,
        message: '❌ Firebase接続テスト失敗',
        error: e.toString(),
      );
    }
  }
}

/// 診断結果クラス
class DiagnosticsResult {
  final bool isHealthy;
  final Map<String, dynamic> diagnostics;
  final List<String> solutions;
  final String? error;

  DiagnosticsResult({
    required this.isHealthy,
    required this.diagnostics,
    required this.solutions,
    this.error,
  });

  /// ユーザー向けメッセージを取得
  String get userMessage {
    if (error != null) {
      return '❌ Firebase診断失敗: $error';
    }
    return isHealthy
        ? '✅ Firebase診断完了: 全て正常'
        : '⚠️ Firebase診断完了: 問題を検出 (コンソール確認)';
  }

  /// 開始メッセージ
  static const String startMessage = '🩺 Firebase完全診断開始...';
}

/// 接続テスト結果クラス
class ConnectionTestResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? documentData;
  final String? error;

  ConnectionTestResult({
    required this.success,
    required this.message,
    this.documentData,
    this.error,
  });

  /// 詳細メッセージを取得
  String get detailMessage {
    if (error != null) {
      return '$message: $error';
    }
    return message;
  }

  /// 開始メッセージ
  static const String startMessage = '🔍 Firebase接続テスト開始...';
}
