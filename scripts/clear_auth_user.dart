import 'dart:io';

import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goshopping/firebase_options.dart';

// Logger instance
final _logger = Logger();

/// Firebase Authentication の現在のユーザーを削除するスクリプト
///
/// 使用方法:
/// dart run scripts/clear_auth_user.dart
///
/// このスクリプトは現在ログイン中のユーザーアカウントを削除します

Future<void> main() async {
  _logger.i('🧹 Firebase Authentication ユーザー削除開始...');

  try {
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      _logger.i('📭 ログイン中のユーザーがいません');
      return;
    }

    // 現在のユーザー情報表示
    _logger.i('👤 現在のユーザー:');
    _logger.i('   UID: ${currentUser.uid}');
    _logger.i('   Email: ${currentUser.email}');
    _logger.i('   DisplayName: ${currentUser.displayName}');

    // 確認メッセージ
    _logger.w('\n⚠️  上記のユーザーアカウントを完全に削除します');
    _logger.i('この操作は取り消せません。続行しますか？ (y/N): ');

    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'y') {
      _logger.e('❌ 操作がキャンセルされました');
      return;
    }

    // ユーザー削除実行
    await currentUser.delete();

    _logger.i('✅ ユーザーアカウントが削除されました');
    _logger.i('💡 アプリを再起動して新規ユーザー登録から開始してください');
  } catch (e) {
    _logger.e('❌ エラーが発生しました: $e');
    _logger.i('💡 Firebase Consoleから手動で削除してください');
  }
}
