// Simple script to enable secret mode
import 'dart:io';

void main() async {
  // Windows のSharedPreferences保存場所に直接アクセス
  // C:\Users\[username]\AppData\Roaming\[app_name]\shared_preferences\

  final appDataPath = Platform.environment['APPDATA'];
  if (appDataPath == null) {
    print('❌ APPDATA環境変数が見つかりません');
    return;
  }

  // go_shopのSharedPreferencesファイルパス
  final prefsDir = Directory('$appDataPath\\go_shop\\shared_preferences');

  print('🔍 SharedPreferences検索パス: ${prefsDir.path}');

  if (await prefsDir.exists()) {
    final files = await prefsDir.list().toList();
    for (final file in files) {
      print('📁 見つかったファイル: ${file.path}');
    }
  } else {
    print('❌ SharedPreferencesディレクトリが存在しません: ${prefsDir.path}');
  }

  print('');
  print('📝 手動でシークレットモードを有効にする方法：');
  print('   1. アプリを起動');
  print('   2. ホームページでユーザー名部分を10回連続タップ');
  print('   3. シークレットモード切り替えダイアログが表示される');
  print('   4. シークレットモードを有効にする');
}
