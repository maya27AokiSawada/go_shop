import 'dart:io';

void main() async {
  print('🔧 _Log参照を修正中...');
  
  final directories = ['lib/services', 'lib/widgets', 'lib/pages', 'lib/providers', 'lib/helpers'];
  int totalFixed = 0;
  
  for (final dir in directories) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;
    
    await for (final file in directory.list(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        final content = await file.readAsString();
        final fixedContent = content.replaceAll('_Log.', 'Log.');
        
        if (content != fixedContent) {
          await file.writeAsString(fixedContent);
          totalFixed++;
          print('  ✅ ${file.path}');
        }
      }
    }
  }
  
  print('🎉 修正完了: $totalFixed ファイル');
}