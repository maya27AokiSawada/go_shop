import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

import '../firebase_options.dart';

// Logger instance
final _logger = Logger();

/// メール送信ステータスを確認するスクリプト
void main() async {
  _logger.i('🔍 メール送信ステータスチェック開始...\n');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.i('✅ Firebase初期化完了\n');

    final firestore = FirebaseFirestore.instance;
    
    // mailコレクションの全ドキュメントを取得
    final mailSnapshot = await firestore
        .collection('mail')
        .orderBy('delivery.startTime', descending: true)
        .limit(10)
        .get();

    if (mailSnapshot.docs.isEmpty) {
      _logger.e('❌ mailコレクションにドキュメントがありません');
      return;
    }

    _logger.i('📧 最近のメール送信ステータス (最新10件):\n');
    _logger.i('=' * 80);

    for (var doc in mailSnapshot.docs) {
      final data = doc.data();
      _logger.i('\n📨 ドキュメントID: ${doc.id}');
      _logger.i('   宛先: ${data['to']}');
      _logger.i('   件名: ${data['message']?['subject'] ?? 'N/A'}');
      
      if (data['delivery'] != null) {
        final delivery = data['delivery'] as Map<String, dynamic>;
        _logger.i('   配送状態: ${delivery['state'] ?? 'PENDING'}');
        _logger.i('   開始時刻: ${delivery['startTime']?.toDate() ?? 'N/A'}');
        _logger.i('   終了時刻: ${delivery['endTime']?.toDate() ?? 'N/A'}');
        _logger.i('   試行回数: ${delivery['attempts'] ?? 0}');
        
        if (delivery['error'] != null) {
          _logger.e('   ❌ エラー情報:');
          final error = delivery['error'];
          if (error is String) {
            _logger.i('      $error');
          } else if (error is Map) {
            error.forEach((key, value) {
              _logger.i('      $key: $value');
            });
          }
        }
        
        if (delivery['info'] != null) {
          final info = delivery['info'];
          if (info is Map) {
            _logger.i('   ℹ️  追加情報:');
            info.forEach((key, value) {
              _logger.i('      $key: $value');
            });
          }
        }
      } else {
        _logger.i('   配送状態: ⏳ PENDING (処理待ち)');
      }
      
      _logger.i('   ${'-' * 76}');
    }

    _logger.i('\n${'=' * 80}');
    _logger.i('\n💡 トラブルシューティング:');
    _logger.i('1. 配送状態がREJECTEDの場合:');
    _logger.i('   - SMTPサーバー認証情報を確認');
    _logger.i('   - Gmailアプリパスワードが正しいか確認');
    _logger.i('   - 送信元メールアドレスが正しいか確認');
    _logger.i('\n2. 配送状態がPENDINGのまま変わらない場合:');
    _logger.i('   - Firebase Console → Functions でログを確認');
    _logger.i('   - Extension設定を確認 (リージョン、コレクション名など)');
    _logger.e('\n3. エラー情報がある場合:');
    _logger.e('   - エラーメッセージを詳しく読んで対応');
    
  } catch (e, stackTrace) {
    _logger.e('❌ エラー: $e');
    _logger.i('スタックトレース: $stackTrace');
  }
}
