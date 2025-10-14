import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Hiveの全データをクリアするスクリプト
/// 
/// 使用方法:
/// dart run scripts/clear_hive_data.dart
/// 
/// このスクリプトはHiveの全てのボックスとデータを削除します

Future<void> main() async {
  print('🧹 Hive データクリア開始...');
  
  try {
    // Hiveディレクトリを取得
    final appDocDir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${appDocDir.path}/hive_db');
    
    print('📂 Hiveディレクトリ: ${hiveDir.path}');
    
    if (!hiveDir.existsSync()) {
      print('📭 Hiveディレクトリが存在しません（既にクリア済み）');
      return;
    }
    
    // 確認メッセージ
    print('⚠️  Hiveの全データを削除します');
    print('続行しますか？ (y/N): ');
    
    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'y') {
      print('❌ 操作がキャンセルされました');
      return;
    }
    
    // Hiveディレクトリ全体を削除
    hiveDir.deleteSync(recursive: true);
    
    print('✅ 全てのHiveデータがクリアされました');
    print('💡 アプリを再起動して初期状態から開始してください');
    
  } catch (e) {
    print('❌ エラーが発生しました: $e');
    print('💡 手動でHiveディレクトリを削除してください');
  }
}