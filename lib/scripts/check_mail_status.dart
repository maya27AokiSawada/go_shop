import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// メール送信ステータスを確認するスクリプト
void main() async {
  print('🔍 メール送信ステータスチェック開始...\n');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase初期化完了\n');

    final firestore = FirebaseFirestore.instance;
    
    // mailコレクションの全ドキュメントを取得
    final mailSnapshot = await firestore
        .collection('mail')
        .orderBy('delivery.startTime', descending: true)
        .limit(10)
        .get();

    if (mailSnapshot.docs.isEmpty) {
      print('❌ mailコレクションにドキュメントがありません');
      return;
    }

    print('📧 最近のメール送信ステータス (最新10件):\n');
    print('=' * 80);

    for (var doc in mailSnapshot.docs) {
      final data = doc.data();
      print('\n📨 ドキュメントID: ${doc.id}');
      print('   宛先: ${data['to']}');
      print('   件名: ${data['message']?['subject'] ?? 'N/A'}');
      
      if (data['delivery'] != null) {
        final delivery = data['delivery'] as Map<String, dynamic>;
        print('   配送状態: ${delivery['state'] ?? 'PENDING'}');
        print('   開始時刻: ${delivery['startTime']?.toDate() ?? 'N/A'}');
        print('   終了時刻: ${delivery['endTime']?.toDate() ?? 'N/A'}');
        print('   試行回数: ${delivery['attempts'] ?? 0}');
        
        if (delivery['error'] != null) {
          print('   ❌ エラー情報:');
          final error = delivery['error'];
          if (error is String) {
            print('      $error');
          } else if (error is Map) {
            error.forEach((key, value) {
              print('      $key: $value');
            });
          }
        }
        
        if (delivery['info'] != null) {
          final info = delivery['info'];
          if (info is Map) {
            print('   ℹ️  追加情報:');
            info.forEach((key, value) {
              print('      $key: $value');
            });
          }
        }
      } else {
        print('   配送状態: ⏳ PENDING (処理待ち)');
      }
      
      print('   ' + '-' * 76);
    }

    print('\n' + '=' * 80);
    print('\n💡 トラブルシューティング:');
    print('1. 配送状態がREJECTEDの場合:');
    print('   - SMTPサーバー認証情報を確認');
    print('   - Gmailアプリパスワードが正しいか確認');
    print('   - 送信元メールアドレスが正しいか確認');
    print('\n2. 配送状態がPENDINGのまま変わらない場合:');
    print('   - Firebase Console → Functions でログを確認');
    print('   - Extension設定を確認 (リージョン、コレクション名など)');
    print('\n3. エラー情報がある場合:');
    print('   - エラーメッセージを詳しく読んで対応');
    
  } catch (e, stackTrace) {
    print('❌ エラー: $e');
    print('スタックトレース: $stackTrace');
  }
}
