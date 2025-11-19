// すもものデフォルトグループ修復スクリプト
// UserSettings Boxをクリアしてデフォルトグループを再作成

import 'dart:io';

void main() {
  print('=== すももユーザーのHive修復 ===\n');

  // UserSettings Boxのパスを表示
  final appDataPath = Platform.environment['APPDATA'] ?? '';
  final hiveBasePath = '$appDataPath\\go_shop\\hive';

  print('📁 Hiveベースパス: $hiveBasePath');
  print('\nすももユーザーのUID: K35DAuQUktfhSr4XWFoAtBNL32E3');
  print(
      'UserSettings Boxパス: $hiveBasePath\\K35DAuQUktfhSr4XWFoAtBNL32E3\\userSettings.hive');

  print('\n【修復手順】');
  print('1. Windowsアプリを完全に終了');
  print('2. 以下のファイルを削除:');
  print('   - userSettings.hive');
  print('   - userSettings.lock');
  print('3. Windowsアプリを再起動');
  print('4. すもも(fatima.yatomi@outlook.com)でログイン');
  print('5. デフォルトグループが自動作成される');

  print('\n【手動削除コマンド】');
  print(
      'Remove-Item "$hiveBasePath\\K35DAuQUktfhSr4XWFoAtBNL32E3\\userSettings.*" -Force');

  print('\n✅ 修復完了後、Firestoreに同期されます');
}
