import 'dart:io';

import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_shop/firebase_options.dart';

// Logger instance
final _logger = Logger();

/// Firestoreの全データをクリアするスクリプト
///
/// 使用方法:
/// dart run scripts/clear_firestore_data.dart
///
/// このスクリプトは以下のコレクションをクリアします:
/// - users
/// - purchase_groups
/// - shopping_lists
/// - invitations
/// - その他全てのコレクション

Future<void> main() async {
  _logger.i('🧹 Firestore データクリア開始...');

  try {
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;

    // 削除対象のコレクション一覧
    final collections = [
      'users',
      'purchase_groups',
      'shopping_lists',
      'invitations',
      'accepted_invitations',
      'user_settings',
      'notifications',
    ];

    // 確認メッセージ
    _logger.w('⚠️  以下のFirestoreコレクションを削除します:');
    for (final collection in collections) {
      _logger.i('   - $collection');
    }
    _logger.i('\n続行しますか？ (y/N): ');

    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'y') {
      _logger.e('❌ 操作がキャンセルされました');
      return;
    }

    // 各コレクションの削除実行
    for (final collectionName in collections) {
      await clearCollection(firestore, collectionName);
    }

    _logger.i('\n✅ 全てのFirestoreデータがクリアされました');
    _logger.i('💡 アプリを再起動して初期状態から開始してください');
  } catch (e) {
    _logger.e('❌ エラーが発生しました: $e');
  }
}

/// 指定されたコレクションの全ドキュメントを削除
Future<void> clearCollection(
    FirebaseFirestore firestore, String collectionName) async {
  _logger.i('🗑️  $collectionName コレクションをクリア中...');

  try {
    final collection = firestore.collection(collectionName);
    final snapshot = await collection.get();

    if (snapshot.docs.isEmpty) {
      _logger.i('   📭 $collectionName は既に空です');
      return;
    }

    // バッチ削除 (最大500件まで)
    final batch = firestore.batch();
    int count = 0;

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;

      // バッチサイズ上限に達したら実行
      if (count >= 500) {
        await batch.commit();
        _logger.i('   🗑️  $count件削除完了');
        count = 0;
      }
    }

    // 残りのドキュメントを削除
    if (count > 0) {
      await batch.commit();
    }

    _logger.i('   ✅ $collectionName コレクション完全削除 (${snapshot.docs.length}件)');
  } catch (e) {
    _logger.e('   ❌ $collectionName の削除に失敗: $e');
  }
}
