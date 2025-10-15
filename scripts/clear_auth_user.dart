import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_shop/firebase_options.dart';

/// Firebase Authentication の現在のユーザーを削除するスクリプト
/// 
/// 使用方法:
/// dart run scripts/clear_auth_user.dart
/// 
/// このスクリプトは現在ログイン中のユーザーアカウントを削除します

Future<void> main() async {
  print('🧹 Firebase Authentication ユーザー削除開始...');
  
  try {
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    
    if (currentUser == null) {
      print('📭 ログイン中のユーザーがいません');
      return;
    }
    
    // 現在のユーザー情報表示
    print('👤 現在のユーザー:');
    print('   UID: ${currentUser.uid}');
    print('   Email: ${currentUser.email}');
    print('   DisplayName: ${currentUser.displayName}');
    
    // 確認メッセージ
    print('\n⚠️  上記のユーザーアカウントを完全に削除します');
    print('この操作は取り消せません。続行しますか？ (y/N): ');
    
    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'y') {
      print('❌ 操作がキャンセルされました');
      return;
    }
    
    // ユーザー削除実行
    await currentUser.delete();
    
    print('✅ ユーザーアカウントが削除されました');
    print('💡 アプリを再起動して新規ユーザー登録から開始してください');
    
  } catch (e) {
    print('❌ エラーが発生しました: $e');
    print('💡 Firebase Consoleから手動で削除してください');
  }
}