import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/shared_list.dart';
import '../providers/shared_list_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../flavors.dart';

/// 買い物リストデータ移行サービス
///
/// **目的**: 配列形式 → Map形式へのデータ移行
///
/// **移行対象**:
/// - Hive: ローカルに保存された全リスト
/// - Firestore: ユーザーの全リスト（認証済みの場合）
///
/// **移行処理**:
/// 1. 既存の配列形式データを検出
/// 2. 各アイテムにitemIdを自動生成（UUID）
/// 3. Map<String, SharedItem>形式に変換
/// 4. isDeleted=false, deletedAt=nullで初期化
/// 5. バックアップ作成（Firestore）
class SharedListDataMigrationService {
  final Ref _ref;
  final _uuid = const Uuid();

  SharedListDataMigrationService(this._ref);

  /// 全データ移行を実行（Hive + Firestore）
  ///
  /// **戻り値**: 移行されたリスト数
  Future<int> migrateAllData() async {
    developer.log('🔄 [MIGRATION] データ移行開始');

    int totalMigrated = 0;

    // 1. Hive移行
    final hiveMigrated = await _migrateHiveData();
    totalMigrated += hiveMigrated;

    // 2. Firestore移行（認証済みの場合のみ） {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firestoreMigrated = await _migrateFirestoreData(user);
        totalMigrated += firestoreMigrated;
      } else {
        developer.log('ℹ️ [MIGRATION] 未サインイン - Firestore移行スキップ');
      }
    } else {
      developer.log('ℹ️ [MIGRATION] Dev環境 - Firestore移行スキップ');
    }

    developer.log('✅ [MIGRATION] データ移行完了: $totalMigratedリスト');
    return totalMigrated;
  }

  /// Hiveデータの移行
  Future<int> _migrateHiveData() async {
    try {
      developer.log('🔄 [MIGRATION] Hive移行開始');

      final repository = _ref.read(sharedListRepositoryProvider);
      final allGroupsAsync = _ref.read(allGroupsProvider);
      final allGroups = allGroupsAsync.when(
        data: (groups) => groups,
        loading: () => [],
        error: (_, __) => [],
      );

      int migratedCount = 0;

      for (final group in allGroups) {
        final lists = await repository.getSharedListsByGroup(group.groupId);

        for (final list in lists) {
          if (_needsMigration(list)) {
            developer.log(
                '🔄 [MIGRATION] Hive移行: リスト「${list.listName}」(${list.activeItems.length}アイテム)');

            final migratedList = _migrateList(list);
            await repository.updateSharedList(migratedList);
            migratedCount++;

            developer.log('✅ [MIGRATION] Hive移行完了: リスト「${list.listName}」');
          }
        }
      }

      if (migratedCount > 0) {
        // Providerを無効化してUIを更新
        _ref.invalidate(allGroupsProvider);
      }

      developer.log('✅ [MIGRATION] Hive移行完了: $migratedCountリスト');
      return migratedCount;
    } catch (e, stackTrace) {
      developer.log('❌ [MIGRATION] Hive移行エラー: $e', stackTrace: stackTrace);
      return 0;
    }
  }

  /// Firestoreデータの移行
  Future<int> _migrateFirestoreData(User user) async {
    try {
      developer.log('🔄 [MIGRATION] Firestore移行開始');

      final firestore = FirebaseFirestore.instance;
      int migratedCount = 0;

      // 全グループのリストを取得
      final allGroupsAsync = _ref.read(allGroupsProvider);
      final allGroups = allGroupsAsync.when(
        data: (groups) => groups,
        loading: () => [],
        error: (_, __) => [],
      );

      for (final group in allGroups) {
        // グループのリストコレクションを取得
        final listsCollection = firestore
            .collection('users')
            .doc(user.uid)
            .collection('groups')
            .doc(group.groupId)
            .collection('shopping_lists');

        final listsSnapshot = await listsCollection.get();

        for (final doc in listsSnapshot.docs) {
          final data = doc.data();

          // 配列形式かチェック
          if (data['items'] is List) {
            developer
                .log('🔄 [MIGRATION] Firestore移行: リスト「${data['listName']}」');

            // バックアップ作成
            await _createBackup(user.uid, group.groupId, doc.id, data);

            // Map形式に変換
            final items = data['items'] as List<dynamic>;
            final migratedItems = <String, Map<String, dynamic>>{};

            for (final itemData in items) {
              final itemMap = itemData as Map<String, dynamic>;
              final itemId = itemMap['itemId'] ?? _uuid.v4();

              migratedItems[itemId] = {
                'memberId': itemMap['memberId'] ?? '',
                'name': itemMap['name'] ?? '',
                'quantity': itemMap['quantity'] ?? 1,
                'registeredDate': itemMap['registeredDate'],
                'purchaseDate': itemMap['purchaseDate'],
                'isPurchased': itemMap['isPurchased'] ?? false,
                'shoppingInterval': itemMap['shoppingInterval'] ?? 0,
                'deadline': itemMap['deadline'],
                'itemId': itemId,
                'isDeleted': itemMap['isDeleted'] ?? false,
                'deletedAt': itemMap['deletedAt'],
              };
            }

            // Firestoreに保存
            await doc.reference.update({
              'items': migratedItems,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            migratedCount++;
            developer
                .log('✅ [MIGRATION] Firestore移行完了: リスト「${data['listName']}」');
          }
        }
      }

      developer.log('✅ [MIGRATION] Firestore移行完了: $migratedCountリスト');
      return migratedCount;
    } catch (e, stackTrace) {
      developer.log('❌ [MIGRATION] Firestore移行エラー: $e', stackTrace: stackTrace);
      return 0;
    }
  }

  /// リストが移行対象かチェック
  ///
  /// **判定基準**: items.valuesの最初のアイテムにitemIdがないか確認
  bool _needsMigration(SharedList list) {
    if (list.items.isEmpty) return false;

    // すでにMap形式の場合はスキップ
    final firstItem = list.items.values.first;
    return firstItem.itemId.isEmpty;
  }

  /// リストをMap形式に移行
  SharedList _migrateList(SharedList list) {
    final migratedItems = <String, SharedItem>{};

    for (final item in list.items.values) {
      // itemIdがない場合は生成
      final itemId = item.itemId.isNotEmpty ? item.itemId : _uuid.v4();

      migratedItems[itemId] = item.copyWith(
        itemId: itemId,
        isDeleted: item.isDeleted, // 既存値保持
        deletedAt: item.deletedAt, // 既存値保持
      );
    }

    return list.copyWith(
      items: migratedItems,
      updatedAt: DateTime.now(),
    );
  }

  /// Firestoreバックアップ作成
  Future<void> _createBackup(
    String userId,
    String groupId,
    String listId,
    Map<String, dynamic> data,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final backupRef = firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc('shopping_lists_migration')
          .collection(groupId)
          .doc(listId);

      await backupRef.set({
        ...data,
        'backupCreatedAt': FieldValue.serverTimestamp(),
        'migrationVersion': '1.0',
      });

      developer.log('✅ [MIGRATION] バックアップ作成: リストID=$listId');
    } catch (e) {
      developer.log('⚠️ [MIGRATION] バックアップ作成エラー: $e');
      // バックアップ失敗でも移行は続行
    }
  }

  /// ロールバック: バックアップから復元
  ///
  /// **注意**: Firestoreのみ対応（Hiveはローカルなので手動復元）
  Future<int> rollbackFromBackup(User user) async {
    try {
      developer.log('🔄 [MIGRATION] ロールバック開始');

      final firestore = FirebaseFirestore.instance;
      int restoredCount = 0;

      // バックアップコレクションを取得
      final backupCollection = firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('shopping_lists_migration')
          .collection('all');

      final backupSnapshot = await backupCollection.get();

      for (final backupDoc in backupSnapshot.docs) {
        final data = backupDoc.data();
        final groupId = data['groupId'] as String;
        final listId = backupDoc.id;

        // 元の場所に復元
        final originalRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('groups')
            .doc(groupId)
            .collection('shopping_lists')
            .doc(listId);

        // バックアップメタデータを削除してから復元
        final restoredData = Map<String, dynamic>.from(data);
        restoredData.remove('backupCreatedAt');
        restoredData.remove('migrationVersion');

        await originalRef.set(restoredData);
        restoredCount++;

        developer.log('✅ [MIGRATION] ロールバック完了: リストID=$listId');
      }

      developer.log('✅ [MIGRATION] ロールバック完了: $restoredCountリスト');
      return restoredCount;
    } catch (e, stackTrace) {
      developer.log('❌ [MIGRATION] ロールバックエラー: $e', stackTrace: stackTrace);
      return 0;
    }
  }

  /// 移行状況を確認
  ///
  /// **戻り値**: {total: 総リスト数, migrated: 移行済み数, remaining: 未移行数}
  Future<Map<String, int>> checkMigrationStatus() async {
    try {
      final repository = _ref.read(sharedListRepositoryProvider);
      final allGroupsAsync = _ref.read(allGroupsProvider);
      final allGroups = allGroupsAsync.when(
        data: (groups) => groups,
        loading: () => [],
        error: (_, __) => [],
      );

      int total = 0;
      int migrated = 0;
      int remaining = 0;

      for (final group in allGroups) {
        final lists = await repository.getSharedListsByGroup(group.groupId);
        total += lists.length;

        for (final list in lists) {
          if (_needsMigration(list)) {
            remaining++;
          } else {
            migrated++;
          }
        }
      }

      return {
        'total': total,
        'migrated': migrated,
        'remaining': remaining,
      };
    } catch (e) {
      developer.log('❌ [MIGRATION] 状況確認エラー: $e');
      return {'total': 0, 'migrated': 0, 'remaining': 0};
    }
  }
}

/// SharedListDataMigrationServiceのプロバイダー
final sharedListDataMigrationServiceProvider =
    Provider<SharedListDataMigrationService>((ref) {
  return SharedListDataMigrationService(ref);
});
