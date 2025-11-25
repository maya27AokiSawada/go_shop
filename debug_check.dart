import 'package:hive/hive.dart';
import 'dart:io';

// デバッグ用: Hiveのデータを確認するスクリプト
void main() async {
  final documentsDir = Directory(
      '${Platform.environment['USERPROFILE']}\\OneDrive\\Documents\\hive_db');
  print('Hive directory: ${documentsDir.path}');
  print('Directory exists: ${documentsDir.existsSync()}');

  if (documentsDir.existsSync()) {
    print('\nFiles in hive_db:');
    final files = documentsDir.listSync();
    for (final file in files) {
      print('  - ${file.path}');
    }
  }

  // Hiveを初期化して確認
  Hive.init(documentsDir.path);

  try {
    final box = await Hive.openBox('sharedGroups');
    print('\nBox opened successfully!');
    print('Number of groups: ${box.length}');
    print('\nAll keys:');
    for (final key in box.keys) {
      print('  - $key');
    }
  } catch (e) {
    print('Error opening box: $e');
  }
}
