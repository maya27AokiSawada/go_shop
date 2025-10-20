import 'dart:io';

void main() {
  // debug_group_data.dartのlogger呼び出しを修正
  final file = File('debug_group_data.dart');
  if (!file.existsSync()) {
    print('❌ ファイルが見つかりません: debug_group_data.dart');
    return;
  }

  String content = file.readAsStringSync();
  
  // logger呼び出しをLog呼び出しに変換
  final replacements = {
    'logger.i(': 'Log.info(',
    'logger.w(': 'Log.warning(',
    'logger.e(': 'Log.error(',
    'logger.d(': 'Log.debug(',
    'logger.t(': 'Log.verbose(',
  };

  bool changed = false;
  for (final entry in replacements.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      changed = true;
      print('✅ ${entry.key} → ${entry.value}');
    }
  }

  if (changed) {
    file.writeAsStringSync(content);
    print('📝 debug_group_data.dart を更新しました');
  } else {
    print('ℹ️  変更は必要ありませんでした');
  }
}