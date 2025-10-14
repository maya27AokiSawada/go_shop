import 'dart:io';

/// 全データをクリアする統合スクリプト
/// 
/// 使用方法:
/// dart run scripts/reset_all_data.dart
/// 
/// このスクリプトは以下を順番に実行します:
/// 1. Firebase Authentication ユーザー削除
/// 2. Firestore データ削除
/// 3. Hive データ削除

Future<void> main() async {
  print('🔄 Go Shop アプリ 完全リセット開始');
  print('=====================================');
  
  // 最終確認
  print('⚠️  以下の全データが削除されます:');
  print('   - Firebase Authentication ユーザー');
  print('   - Firestore 全コレクション');
  print('   - Hive ローカルデータベース');
  print('\n本当に続行しますか？ (y/N): ');
  
  final input = stdin.readLineSync();
  if (input?.toLowerCase() != 'y') {
    print('❌ 操作がキャンセルされました');
    return;
  }
  
  print('\n🚀 リセット開始...\n');
  
  try {
    // 1. Firebase Authentication ユーザー削除
    print('1️⃣ Firebase Authentication ユーザー削除中...');
    final authResult = await Process.run(
      'dart', 
      ['run', 'scripts/clear_auth_user.dart'],
      workingDirectory: Directory.current.path,
    );
    
    if (authResult.exitCode == 0) {
      print('✅ Authentication ユーザー削除完了');
    } else {
      print('⚠️ Authentication ユーザー削除でエラー: ${authResult.stderr}');
    }
    
    print('');
    
    // 2. Firestore データ削除
    print('2️⃣ Firestore データ削除中...');
    final firestoreResult = await Process.run(
      'dart',
      ['run', 'scripts/clear_firestore_data.dart'],
      workingDirectory: Directory.current.path,
    );
    
    if (firestoreResult.exitCode == 0) {
      print('✅ Firestore データ削除完了');
    } else {
      print('⚠️ Firestore データ削除でエラー: ${firestoreResult.stderr}');
    }
    
    print('');
    
    // 3. Hive データ削除
    print('3️⃣ Hive データ削除中...');
    final hiveResult = await Process.run(
      'dart',
      ['run', 'scripts/clear_hive_data.dart'],
      workingDirectory: Directory.current.path,
    );
    
    if (hiveResult.exitCode == 0) {
      print('✅ Hive データ削除完了');
    } else {
      print('⚠️ Hive データ削除でエラー: ${hiveResult.stderr}');
    }
    
    print('\n🎉 完全リセット完了！');
    print('=====================================');
    print('💡 次の手順:');
    print('   1. Android端末のアプリをアンインストール');
    print('   2. flutter clean && flutter pub get');
    print('   3. flutter run でアプリを再インストール');
    print('   4. 新規ユーザー登録から開始');
    
  } catch (e) {
    print('❌ リセット中にエラーが発生しました: $e');
  }
}