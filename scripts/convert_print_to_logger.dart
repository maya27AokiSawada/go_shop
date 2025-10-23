#!/usr/bin/env dart

import 'dart:io';
import 'package:go_shop/utils/app_logger.dart';

void main() {
  // 処理対象のファイルパターン（プロジェクトファイルのみ）
  final patterns = [
    'lib/**/*.dart',
    'scripts/*.dart',
    '*.dart', // ルートレベルのファイル
  ];

  // 各パターンのファイルを処理
  for (final pattern in patterns) {
    processFiles(pattern);
  }
}

void processFiles(String pattern) {
  final directory = Directory('.');
  final files = directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => matchesPattern(file.path, pattern))
      .toList();

  AppLogger.info('Processing pattern: $pattern (${files.length} files)');

  for (final file in files) {
    processFile(file);
  }
}

bool matchesPattern(String filePath, String pattern) {
  // Windowsパスを正規化
  filePath = filePath.replaceAll('\\', '/');
  pattern = pattern.replaceAll('\\', '/');

  if (pattern.endsWith('*.dart')) {
    final dirPattern = pattern.substring(0, pattern.length - 6);
    return filePath.contains(dirPattern) && filePath.endsWith('.dart');
  }
  return false;
}

void processFile(File file) {
  if (!file.existsSync()) {
    return;
  }

  String content = file.readAsStringSync();

  // print文の置換とloggerインポートの確認
  final result = convertPrintToLogger(content, file.path);

  if (result.changed) {
    file.writeAsStringSync(result.content);
    AppLogger.success('✅ Updated: ${file.path}');
  }
}

class ConversionResult {
  final String content;
  final bool changed;

  ConversionResult(this.content, this.changed);
}

ConversionResult convertPrintToLogger(String content, String filePath) {
  String updatedContent = content;
  bool changed = false;

  // 正規表現でprint文を検索して置換
  final printPattern =
      RegExp(r'print\((.+?)\);', multiLine: true, dotAll: true);
  final matches = printPattern.allMatches(updatedContent).toList();

  if (matches.isNotEmpty) {
    changed = true;

    // 後ろから前に向かって置換（オフセットの問題を避けるため）
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      final argument = match.group(1);

      String loggerMethod = '_logger.i'; // デフォルトはinfo

      // 絵文字に基づいてログレベルを決定
      if (argument != null) {
        if (argument.contains('❌') ||
            argument.contains('Failed') ||
            argument.contains('Error') ||
            argument.contains('エラー')) {
          loggerMethod = '_logger.e';
        } else if (argument.contains('⚠️') ||
            argument.contains('警告') ||
            argument.contains('Warning')) {
          loggerMethod = '_logger.w';
        }
      }

      final replacement = '$loggerMethod($argument);';
      updatedContent = updatedContent.substring(0, match.start) +
          replacement +
          updatedContent.substring(match.end);
    }
  }

  // loggerが使われている場合、インポートを追加
  if (changed &&
      !updatedContent.contains("import 'package:logger/logger.dart'")) {
    // 最初のimport文を探して、その後に追加
    final importPattern = RegExp(r"import '[^']*';");
    final firstImport = importPattern.firstMatch(updatedContent);

    if (firstImport != null) {
      final insertPoint = firstImport.end;
      updatedContent =
          "${updatedContent.substring(0, insertPoint)}\nimport 'package:logger/logger.dart';${updatedContent.substring(insertPoint)}";

      // loggerインスタンスも追加
      if (!updatedContent.contains('final _logger = Logger();')) {
        // import文の後にloggerインスタンスを追加
        final lastImportPattern = RegExp(r"import '[^']*';\n");
        final matches = lastImportPattern.allMatches(updatedContent);
        if (matches.isNotEmpty) {
          final lastImport = matches.last;
          final insertPoint = lastImport.end;
          updatedContent =
              "${updatedContent.substring(0, insertPoint)}\n// Logger instance\nfinal _logger = Logger();\n${updatedContent.substring(insertPoint)}";
        }
      }
    }
  }

  return ConversionResult(updatedContent, changed);
}
