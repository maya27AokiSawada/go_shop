import 'dart:io';

import 'package:logger/logger.dart';

// Logger instance
final _logger = Logger();

/// 全データをクリアする統合スクリプト
///
/// 使用方法:
/// dart run scripts/reset_all_data.dart
///
/// このスクリプトは以下を順番に実行します:
/// 1. Firebase Authentication ユーザー削除
/// 2. Firestore データ削除
/// 3. Hive データ削除

Future<void> main() async {
  _logger.i('🔄 Go Shop アプリ 完全リセット開始');
  _logger.i('=====================================');

  // 最終確認
  _logger.w('⚠️  以下の全データが削除されます:');
  _logger.i('   - Firebase Authentication ユーザー');
  _logger.i('   - Firestore 全コレクション');
  _logger.i('   - Hive ローカルデータベース');
  _logger.i('\n本当に続行しますか？ (y/N): ');

  final input = stdin.readLineSync();
  if (input?.toLowerCase() != 'y') {
    _logger.e('❌ 操作がキャンセルされました');
    return;
  }

  _logger.i('\n🚀 リセット開始...\n');

  try {
    // 1. Firebase Authentication ユーザー削除
    _logger.i('1️⃣ Firebase Authentication ユーザー削除中...');
    final authResult = await Process.run(
      'dart',
      ['run', 'scripts/clear_auth_user.dart'],
      workingDirectory: Directory.current.path,
    );

    if (authResult.exitCode == 0) {
      _logger.i('✅ Authentication ユーザー削除完了');
    } else {
      _logger.w('⚠️ Authentication ユーザー削除でエラー: ${authResult.stderr}');
    }

    _logger.i('');

    // 2. Firestore データ削除
    _logger.i('2️⃣ Firestore データ削除中...');
    final firestoreResult = await Process.run(
      'dart',
      ['run', 'scripts/clear_firestore_data.dart'],
      workingDirectory: Directory.current.path,
    );

    if (firestoreResult.exitCode == 0) {
      _logger.i('✅ Firestore データ削除完了');
    } else {
      _logger.w('⚠️ Firestore データ削除でエラー: ${firestoreResult.stderr}');
    }

    _logger.i('');

    // 3. Hive データ削除
    _logger.i('3️⃣ Hive データ削除中...');
    final hiveResult = await Process.run(
      'dart',
      ['run', 'scripts/clear_hive_data.dart'],
      workingDirectory: Directory.current.path,
    );

    if (hiveResult.exitCode == 0) {
      _logger.i('✅ Hive データ削除完了');
    } else {
      _logger.w('⚠️ Hive データ削除でエラー: ${hiveResult.stderr}');
    }

    _logger.i('\n🎉 完全リセット完了！');
    _logger.i('=====================================');
    _logger.i('💡 次の手順:');
    _logger.i('   1. Android端末のアプリをアンインストール');
    _logger.i('   2. flutter clean && flutter pub get');
    _logger.i('   3. flutter run でアプリを再インストール');
    _logger.i('   4. 新規ユーザー登録から開始');
  } catch (e) {
    _logger.e('❌ リセット中にエラーが発生しました: $e');
  }
}
