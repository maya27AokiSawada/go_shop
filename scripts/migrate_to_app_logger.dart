import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:go_shop/utils/app_logger.dart';

void main() {
  AppLogger.info('🔄 AppLoggerへの一括移行開始...');

  // 移行対象のパターン
  final patterns = [
    'lib/services/*.dart',
    'lib/widgets/*.dart',
    'lib/pages/*.dart',
    'lib/providers/*.dart',
    'lib/helpers/*.dart',
  ];

  int totalFiles = 0;
  int updatedFiles = 0;

  for (final pattern in patterns) {
    final files = _getFilesMatchingPattern(pattern);
    totalFiles += files.length;

    AppLogger.info('\n📁 処理中: $pattern (${files.length} files)');

    for (final file in files) {
      if (_migrateFileToAppLogger(file)) {
        updatedFiles++;
        AppLogger.success('  ✅ ${path.basename(file.path)}');
      }
    }
  }

  AppLogger.success('\n🎉 移行完了!');
  AppLogger.info('📊 総ファイル数: $totalFiles');
  AppLogger.info('📝 更新ファイル数: $updatedFiles');
}

List<File> _getFilesMatchingPattern(String pattern) {
  final directory = Directory('.');
  final prefix = pattern.split('*').first;
  final suffix = pattern.split('*').last;

  final dir = Directory(prefix.isEmpty ? '.' : prefix);
  if (!dir.existsSync()) return [];

  return dir
      .listSync(recursive: pattern.contains('**'))
      .whereType<File>()
      .where((f) => f.path.endsWith(suffix))
      .toList();
}

bool _migrateFileToAppLogger(File file) {
  try {
    String content = file.readAsStringSync();
    String originalContent = content;
    bool changed = false;

    // main.dartへのimportを削除
    final mainImportPattern = RegExp("import\\s+['\"].*main\\.dart['\"];\\s*");
    if (content.contains(mainImportPattern)) {
      content = content.replaceAll(mainImportPattern, '');
      changed = true;
    }

    // logger宣言を削除
    final loggerDeclarations = [
      'final logger = Logger();',
      'final _logger = Logger();',
      'static final Logger _logger = Logger();',
      'static final Logger logger = Logger();',
    ];

    for (final declaration in loggerDeclarations) {
      if (content.contains(declaration)) {
        content = content.replaceAll(declaration, '');
        changed = true;
      }
    }

    // AppLoggerのimportを追加（まだなければ）
    if (!content.contains('app_logger.dart')) {
      // 最初のimport行を探す
      final lines = content.split('\n');
      int insertIndex = -1;

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('import ') && lines[i].contains('package:')) {
          insertIndex = i + 1;
        }
      }

      if (insertIndex > -1) {
        lines.insert(insertIndex, "import '../utils/app_logger.dart';");
        content = lines.join('\n');
        changed = true;
      }
    }

    // logger呼び出しを変換
    final loggerReplacements = {
      '_Log.': 'Log.', // _Log を Log に修正
      'logger.i(': 'Log.info(',
      '_logger.i(': 'Log.info(',
      'logger.w(': 'Log.warning(',
      '_logger.w(': 'Log.warning(',
      'logger.e(': 'Log.error(',
      '_logger.e(': 'Log.error(',
      'logger.d(': 'Log.debug(',
      '_logger.d(': 'Log.debug(',
      'logger.t(': 'Log.verbose(',
      '_logger.t(': 'Log.verbose(',
    };

    for (final entry in loggerReplacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
      }
    }

    // ファイルが変更された場合のみ書き込み
    if (changed) {
      file.writeAsStringSync(content);
      return true;
    }

    return false;
  } catch (e) {
    print('  ❌ エラー: ${file.path} - $e');
    return false;
  }
}
