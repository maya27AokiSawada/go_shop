import 'dart:io';
import 'package:path/path.dart' as path;
import '../lib/utils/app_logger.dart';

void main() {
  // 修正対象のファイルパターン
  final patterns = [
    'lib/**/*.dart',
    'test/**/*.dart',
  ];

  for (final pattern in patterns) {
    final files = Directory.current
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) {
      final relativePath = path.relative(f.path, from: Directory.current.path);
      return _matchesPattern(relativePath, pattern);
    }).toList();

    AppLogger.info('Processing pattern: $pattern (${files.length} files)');

    for (final file in files) {
      final result = fixLoggerImport(file.readAsStringSync(), file.path);
      if (result.changed) {
        file.writeAsStringSync(result.content);
        AppLogger.success('✅ Fixed: ${file.path}');
      }
    }
  }
}

bool _matchesPattern(String filePath, String pattern) {
  filePath = filePath.replaceAll(r'\', '/');
  pattern = pattern.replaceAll(r'\', '/');
  
  if (pattern.endsWith('**/*.dart')) {
    final prefix = pattern.substring(0, pattern.length - '**/*.dart'.length);
    return filePath.startsWith(prefix) && filePath.endsWith('.dart');
  }
  
  return false;
}

class FixResult {
  final String content;
  final bool changed;
  
  FixResult(this.content, this.changed);
}

FixResult fixLoggerImport(String content, String filePath) {
  // Logger関連の問題を探す
  if (!content.contains('final _logger = Logger();') || 
      !content.contains("import 'package:logger/logger.dart';")) {
    return FixResult(content, false);
  }

  final lines = content.split('\n');
  List<String> newLines = [];
  bool hasLoggerImport = false;
  bool hasLoggerInstance = false;
  int firstImportIndex = -1;
  int lastImportIndex = -1;
  
  // 既存のimportとlogger宣言を除去し、正しい位置を特定
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    
    if (line.startsWith("import '") || line.startsWith('import "')) {
      if (firstImportIndex == -1) firstImportIndex = i;
      lastImportIndex = i;
      
      if (line == "import 'package:logger/logger.dart';") {
        hasLoggerImport = true;
        continue; // この行は除去
      }
    } else if (line == 'final _logger = Logger();') {
      hasLoggerInstance = true;
      continue; // この行は除去
    } else if (line.startsWith('// Logger instance')) {
      continue; // この行も除去
    }
    
    newLines.add(lines[i]);
  }

  // Logger importとinstanceを正しい位置に追加
  if (hasLoggerImport && hasLoggerInstance && firstImportIndex != -1) {
    // logger importを他のimportと一緒に追加（アルファベット順に）
    List<String> importSection = [];
    List<String> otherLines = [];
    bool inImportSection = true;
    
    for (int i = 0; i < newLines.length; i++) {
      final line = newLines[i].trim();
      
      if (inImportSection && (line.startsWith("import '") || line.startsWith('import "'))) {
        importSection.add(newLines[i]);
      } else if (inImportSection && line.isEmpty && importSection.isNotEmpty) {
        // importセクションの終わり
        inImportSection = false;
        
        // logger importを適切な位置に挿入
        bool loggerInserted = false;
        List<String> sortedImports = [];
        
        for (final importLine in importSection) {
          sortedImports.add(importLine);
          if (!loggerInserted && shouldInsertLoggerAfter(importLine)) {
            sortedImports.add("import 'package:logger/logger.dart';");
            loggerInserted = true;
          }
        }
        
        if (!loggerInserted) {
          sortedImports.add("import 'package:logger/logger.dart';");
        }
        
        otherLines.addAll(sortedImports);
        otherLines.add(newLines[i]); // 空行
        
        // logger instance を import の後に追加
        otherLines.add('');
        otherLines.add('// Logger instance');
        otherLines.add('final _logger = Logger();');
      } else {
        if (!inImportSection) {
          otherLines.add(newLines[i]);
        } else {
          // import section以外の最初の行
          inImportSection = false;
          otherLines.add(newLines[i]);
        }
      }
    }
    
    return FixResult(otherLines.join('\n'), true);
  }
  
  return FixResult(content, false);
}

bool shouldInsertLoggerAfter(String importLine) {
  return importLine.contains('package:') && 
         importLine.compareTo("import 'package:logger/logger.dart';") < 0;
}