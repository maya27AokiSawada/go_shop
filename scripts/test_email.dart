import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Trigger Email のテスト送信スクリプト
/// 
/// 使用方法:
/// dart run scripts/test_email.dart

Future<void> main() async {
  print('📧 テストメール送信開始...');
  
  try {
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase初期化完了');
    
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
    
    print('📤 メール送信リクエストをFirestoreに追加中...');
    final docRef = await firestore.collection('mail').add(emailData);
    print('✅ ドキュメントID: ${docRef.id}');
    print('');
    print('📋 送信内容:');
    print('   宛先: fatima.sumomo@gmail.com');
    print('   件名: Go Shop テストメール');
    print('');
    print('⏳ メール送信処理が開始されました...');
    print('');
    print('💡 送信ステータスを確認するには:');
    print('   Firebase Console → Firestore → mail コレクション → ${docRef.id}');
    print('   delivery フィールドを確認してください');
    print('');
    print('📧 数秒～数分以内にメールが届くはずです！');
    
  } catch (e, stackTrace) {
    print('❌ エラーが発生しました: $e');
    print('スタックトレース: $stackTrace');
    rethrow;
  }
}
