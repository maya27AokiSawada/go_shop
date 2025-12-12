// lib/services/shopping_list_migration_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// UID変更時にデフォルトグループのSharedListをマイグレーションするサービス
class SharedListMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 旧デフォルトグループのリストを新デフォルトグループに移行
  ///
  /// Firestoreデータ構造: /SharedGroups/{groupId}/sharedLists/{listId}
  ///
  /// 処理:
  /// 1. 旧グループID配下の全リストを取得
  /// 2. 各リストのgroupIdを新グループIDに書き換え
  /// 3. 新グループID配下に同じlistIdでコピー
  /// 4. 旧リストは削除（オプション）
  static Future<void> migrateDefaultGroupLists({
    required String oldGroupId,
    required String newGroupId,
  }) async {
    try {
      Log.info('🔄 [MIGRATION] リストマイグレーション開始');
      Log.info('🔄 [MIGRATION] 旧グループID: $oldGroupId');
      Log.info('🔄 [MIGRATION] 新グループID: $newGroupId');

      // 1. 旧グループの全リストを取得
      final oldCollectionRef = _firestore
          .collection('SharedGroups')
          .doc(oldGroupId)
          .collection('sharedLists');

      final oldListsSnapshot = await oldCollectionRef.get();

      if (oldListsSnapshot.docs.isEmpty) {
        Log.info('💡 [MIGRATION] 旧グループにリストなし - マイグレーション不要');
        return;
      }

      Log.info('🔍 [MIGRATION] 旧グループのリスト数: ${oldListsSnapshot.docs.length}件');

      // 2. 新グループのコレクション参照
      final newCollectionRef = _firestore
          .collection('SharedGroups')
          .doc(newGroupId)
          .collection('sharedLists');

      int successCount = 0;
      int errorCount = 0;

      // 3. 各リストを新グループにコピー
      for (final oldDoc in oldListsSnapshot.docs) {
        try {
          final oldData = oldDoc.data();

          // groupIdを新IDに書き換え
          final newData = Map<String, dynamic>.from(oldData);
          newData['groupId'] = newGroupId;
          newData['migratedFrom'] = oldGroupId;
          newData['migratedAt'] = FieldValue.serverTimestamp();

          // 新グループ配下に同じlistIdでコピー
          await newCollectionRef.doc(oldDoc.id).set(newData);

          Log.info(
              '✅ [MIGRATION] リスト移行成功: ${oldData['listName']} (${oldDoc.id})');
          successCount++;
        } catch (e) {
          Log.error('❌ [MIGRATION] リスト移行エラー: ${oldDoc.id} - $e');
          errorCount++;
        }
      }

      Log.info('✅ [MIGRATION] マイグレーション完了: 成功=$successCount, 失敗=$errorCount');

      // 4. 旧リストを削除（オプション - コメントアウト状態で保持）
      // await _deleteOldLists(oldCollectionRef, oldListsSnapshot.docs);
    } catch (e, stackTrace) {
      Log.error('❌ [MIGRATION] マイグレーション全体エラー: $e');
      Log.info('スタックトレース: $stackTrace');
      // エラーでも処理を続行（既存の新デフォルトグループは使える状態にする）
    }
  }

  /// 旧リストを削除（安全性のため現在は未使用）
  static Future<void> _deleteOldLists(
    CollectionReference collectionRef,
    List<QueryDocumentSnapshot> docs,
  ) async {
    Log.info('🗑️ [MIGRATION] 旧リスト削除開始: ${docs.length}件');

    final batch = _firestore.batch();
    for (final doc in docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    Log.info('✅ [MIGRATION] 旧リスト削除完了');
  }
}
