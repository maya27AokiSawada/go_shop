// lib/services/hive_lock_cleaner.dart
import 'dart:io';
import '../utils/app_logger.dart';

/// Hiveロックファイルをクリアするサービス
class HiveLockCleaner {
  /// 指定されたディレクトリ内のすべての .lock ファイルを削除
  static Future<void> clearLockFiles(Directory directory) async {
    try {
      AppLogger.info('🔒 Hiveロックファイルクリア開始: ${directory.path}');

      if (!await directory.exists()) {
        AppLogger.info('📁 ディレクトリが存在しません: ${directory.path}');
        return;
      }

      final lockFiles = await directory
          .list(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.lock'))
          .cast<File>()
          .toList();

      if (lockFiles.isEmpty) {
        AppLogger.info('✅ ロックファイルは見つかりませんでした');
        return;
      }

      for (final lockFile in lockFiles) {
        try {
          await lockFile.delete();
          AppLogger.info('🗑️ ロックファイル削除: ${lockFile.path}');
        } catch (e) {
          AppLogger.warning('⚠️ ロックファイル削除失敗: ${lockFile.path} - $e');
          // 削除に失敗しても続行
        }
      }

      AppLogger.info('✅ Hiveロックファイルクリア完了');
    } catch (e) {
      AppLogger.error('❌ Hiveロックファイルクリアエラー: $e');
      // エラーが発生してもアプリケーションの起動は続行
    }
  }

  /// OneDriveドキュメントフォルダ内のロックファイルもクリア
  static Future<void> clearOneDriveLocks() async {
    try {
      final documentsPath = Platform.environment['USERPROFILE'];
      if (documentsPath != null) {
        final oneDriveDocsPath = '$documentsPath\\OneDrive\\Documents';
        final oneDriveDir = Directory(oneDriveDocsPath);

        if (await oneDriveDir.exists()) {
          AppLogger.info('🌐 OneDriveドキュメントフォルダのロックファイルもクリア');
          await clearLockFiles(oneDriveDir);
        }
      }
    } catch (e) {
      AppLogger.warning('⚠️ OneDriveロックファイルクリア中にエラー: $e');
    }
  }
}
