import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_shop/firebase_options.dart';

// Logger instance
final _logger = Logger();

/// Trigger Email のテスト送信スクリプト
/// 
/// 使用方法:
/// dart run scripts/test_email.dart

Future<void> main() async {
  _logger.i('📧 テストメール送信開始...');
  
  try {
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.i('✅ Firebase初期化完了');
    
    final firestore = FirebaseFirestore.instance;
    
    // mailコレクションにドキュメントを追加
    final emailData = {
      'to': 'fatima.sumomo@gmail.com',
      'message': {
        'subject': 'Go Shop テストメール',
        'text': '''
こんにちは！

これはGo Shopアプリからのテストメールです。

Trigger Email Extension が正しく動作していることを確認しています。

このメールが届いたら、メール送信機能が正常に動作しています！

Go Shop チーム
        ''',
        'html': '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .footer { background-color: #f1f1f1; padding: 10px; text-align: center; font-size: 12px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🛒 Go Shop</h1>
  </div>
  <div class="content">
    <h2>テストメール送信成功！</h2>
    <p>こんにちは！</p>
    <p>これはGo Shopアプリからのテストメールです。</p>
    <p>Trigger Email Extension が正しく動作していることを確認しています。</p>
    <p><strong>このメールが届いたら、メール送信機能が正常に動作しています！</strong></p>
    <hr>
    <p>主な機能:</p>
    <ul>
      <li>✅ 買い物リストの共有</li>
      <li>✅ グループ管理</li>
      <li>✅ リアルタイム同期</li>
      <li>✅ QRコード招待</li>
    </ul>
  </div>
  <div class="footer">
    <p>Go Shop チーム</p>
    <p>このメールは自動送信されています</p>
  </div>
</body>
</html>
        ''',
      },
    };
    
    _logger.i('📤 メール送信リクエストをFirestoreに追加中...');
    final docRef = await firestore.collection('mail').add(emailData);
    _logger.i('✅ ドキュメントID: ${docRef.id}');
    _logger.i('');
    _logger.i('📋 送信内容:');
    _logger.i('   宛先: fatima.sumomo@gmail.com');
    _logger.i('   件名: Go Shop テストメール');
    _logger.i('');
    _logger.i('⏳ メール送信処理が開始されました...');
    _logger.i('');
    _logger.i('💡 送信ステータスを確認するには:');
    _logger.i('   Firebase Console → Firestore → mail コレクション → ${docRef.id}');
    _logger.i('   delivery フィールドを確認してください');
    _logger.i('');
    _logger.i('📧 数秒～数分以内にメールが届くはずです！');
    
  } catch (e, stackTrace) {
    _logger.e('❌ エラーが発生しました: $e');
    _logger.i('スタックトレース: $stackTrace');
    rethrow;
  }
}
