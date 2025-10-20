import 'dart:io';

// Logger instance
final _logger = Logger();
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Hiveの全データをクリアするスクリプト
/// 
/// 使用方法:
/// dart run scripts/clear_hive_data.dart
/// 
/// このスクリプトはHiveの全てのボックスとデータを削除します

Future<void> main() async {
  _logger.i('🧹 Hive データクリア開始...');
  
  try {
    // Hiveディレクトリを取得
    final appDocDir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${appDocDir.path}/hive_db');
    
    _logger.i('📂 Hiveディレクトリ: ${hiveDir.path}');
    
    if (!hiveDir.existsSync()) {
      _logger.i('📭 Hiveディレクトリが存在しません（既にクリア済み）');
      return;
    }
    
    // 確認メッセージ
    _logger.w('⚠️  Hiveの全データを削除します');
    _logger.i('続行しますか？ (y/N): ');
    
    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'y') {
      _logger.e('❌ 操作がキャンセルされました');
      return;
    }
    
    // Hiveディレクトリ全体を削除
    hiveDir.deleteSync(recursive: true);
    
    _logger.i('✅ 全てのHiveデータがクリアされました');
    _logger.i('💡 アプリを再起動して初期状態から開始してください');
    
  } catch (e) {
    _logger.e('❌ エラーが発生しました: $e');
    _logger.i('💡 手動でHiveディレクトリを削除してください');
  }
}