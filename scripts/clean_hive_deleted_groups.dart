import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_shop/models/shared_group.dart';

/// 削除済みHiveデータをクリーンアップするスクリプト
///
/// 使用方法:
/// dart run scripts/clean_hive_deleted_groups.dart
///
/// このスクリプトは以下を実行します:
/// - isDeleted=true のグループを物理削除
/// - Hiveデータベースの最適化

Future<void> main() async {
  print('🧹 削除済みHiveデータのクリーンアップを開始します...\n');

  // Hive初期化
  await Hive.initFlutter();

  // SharedGroupアダプタを登録
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(SharedGroupAdapter());
  }

  // Boxを開く
  final box = await Hive.openBox<SharedGroup>('purchase_groups');

  print('📦 Box情報:');
  print('   - 総ドキュメント数: ${box.length}');
  print('   - Boxパス: ${box.path}\n');

  // 削除対象の検索
  final deletedGroups = box.values.where((group) => group.isDeleted).toList();
  final activeGroups = box.values.where((group) => !group.isDeleted).toList();

  print('📊 現在の状態:');
  print('   - アクティブグループ: ${activeGroups.length}個');
  print('   - 削除済みグループ: ${deletedGroups.length}個\n');

  if (deletedGroups.isEmpty) {
    print('✅ クリーンアップ不要: 削除済みグループはありません\n');
    await box.close();
    return;
  }

  // 削除済みグループのリスト表示
  print('🗑️  削除対象グループ:');
  for (final group in deletedGroups) {
    print('   - ${group.groupName} (${group.groupId})');
  }
  print('');

  // 確認メッセージ
  print('⚠️  警告: ${deletedGroups.length}個のグループを物理削除します');
  print('続行しますか？ (yes/no): ');

  // 実行確認（コメント解除して実行）
  // final input = stdin.readLineSync();
  // if (input?.toLowerCase() != 'yes') {
  //   print('❌ 操作がキャンセルされました\n');
  //   await box.close();
  //   return;
  // }

  // 自動実行モード（確認なし）
  print('💡 自動実行モード: 確認なしで削除を実行します\n');

  // 物理削除実行
  int deletedCount = 0;
  for (final group in deletedGroups) {
    try {
      // groupIdをキーとして削除
      await box.delete(group.groupId);
      deletedCount++;
      print('   ✓ 削除: ${group.groupName} (${group.groupId})');
    } catch (e) {
      print('   ✗ エラー: ${group.groupName} - $e');
    }
  }

  print('');
  print('✅ クリーンアップ完了:');
  print('   - 削除数: $deletedCount/${deletedGroups.length}');
  print('   - 残存グループ: ${box.length}個');
  print('   - Boxサイズ削減: ${deletedGroups.length}個分\n');

  // Box最適化
  print('🔧 Hive Box最適化中...');
  await box.compact();
  print('✅ 最適化完了\n');

  // 最終状態
  print('📊 最終状態:');
  print('   - 総ドキュメント数: ${box.length}');
  final remainingDeleted = box.values.where((g) => g.isDeleted).length;
  print('   - 削除済みフラグ: $remainingDeleted個 (0が理想)');
  print('');

  await box.close();

  print('🎉 クリーンアップが完了しました!');
  print('💡 次回アプリ起動時、Hiveデータが軽量化されています\n');
}
