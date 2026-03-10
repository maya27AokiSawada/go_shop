import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_list.dart';
import '../providers/shared_list_provider.dart';
import '../providers/shared_group_provider.dart';

/// 買い物リストの論理削除アイテムクリーンアップサービス
///
/// **主要機能**:
/// - 指定日数以上経過した削除済みアイテムの物理削除
/// - 自動クリーンアップ（アプリ起動時）
/// - 手動クリーンアップ（設定画面から）
///
/// **デフォルト設定**:
/// - クリーンアップ対象: 30日以上経過した削除済みアイテム
class ListCleanupService {
  final Ref _ref;

  ListCleanupService(this._ref);

  /// 全リストの削除済みアイテムをクリーンアップ
  ///
  /// [olderThanDays]: 指定日数以上経過したアイテムを削除（デフォルト: 30日）
  /// [forceCleanup]: 強制クリーンアップ（needsCleanup判定を無視）
  ///
  /// **戻り値**: クリーンアップされたアイテム数
  Future<int> cleanupAllLists({
    int olderThanDays = 30,
    bool forceCleanup = false,
  }) async {
    try {
      developer.log('🧹 クリーンアップサービス開始 ($olderThanDays日以上経過)');

      final repository = _ref.read(sharedListRepositoryProvider);

      // 全グループから全リストを取得
      final allGroupsAsync = _ref.read(allGroupsProvider);
      final allGroups = allGroupsAsync.when(
        data: (groups) => groups,
        loading: () => [],
        error: (_, __) => [],
      );

      final allLists = <SharedList>[];
      for (final group in allGroups) {
        final groupLists =
            await repository.getSharedListsByGroup(group.groupId);
        allLists.addAll(groupLists);
      }

      if (allLists.isEmpty) {
        developer.log('ℹ️ クリーンアップ対象のリストがありません');
        return 0;
      }

      int totalCleaned = 0;

      for (final list in allLists) {
        // forceCleanup=false の場合、needsCleanup判定をチェック
        if (!forceCleanup && !list.needsCleanup) {
          developer.log(
              'ℹ️ スキップ: リスト「${list.listName}」(削除済み${list.deletedItemCount}個 < 10個)');
          continue;
        }

        final beforeCount = list.deletedItemCount;
        await repository.cleanupDeletedItems(list.listId,
            olderThanDays: olderThanDays);

        // クリーンアップ後のリストを取得して確認
        final updatedList = await repository.getSharedListById(list.listId);
        final afterCount = updatedList?.deletedItemCount ?? 0;
        final cleanedCount = beforeCount - afterCount;

        if (cleanedCount > 0) {
          totalCleaned += cleanedCount.toInt(); // 🆕 int型にキャスト
          developer.log('✅ リスト「${list.listName}」: $cleanedCount個のアイテムをクリーンアップ');
        }
      }

      if (totalCleaned > 0) {
        developer.log('🎉 クリーンアップ完了: 合計$totalCleaned個のアイテムを削除');
        // グループProviderを無効化してUIを更新
        _ref.invalidate(allGroupsProvider);
      } else {
        developer.log('ℹ️ クリーンアップ対象のアイテムがありませんでした');
      }

      return totalCleaned;
    } catch (e, stackTrace) {
      developer.log('❌ クリーンアップエラー: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 特定のリストのみクリーンアップ
  ///
  /// [listId]: クリーンアップ対象のリストID
  /// [olderThanDays]: 指定日数以上経過したアイテムを削除（デフォルト: 30日）
  ///
  /// **戻り値**: クリーンアップされたアイテム数
  Future<int> cleanupList(
    String listId, {
    int olderThanDays = 30,
  }) async {
    try {
      final repository = _ref.read(sharedListRepositoryProvider);
      final list = await repository.getSharedListById(listId);

      if (list == null) {
        developer.log('⚠️ リストが見つかりません (ID: $listId)');
        return 0;
      }

      final beforeCount = list.deletedItemCount;
      await repository.cleanupDeletedItems(listId,
          olderThanDays: olderThanDays);

      final updatedList = await repository.getSharedListById(listId);
      final afterCount = updatedList?.deletedItemCount ?? 0;
      final cleanedCount = beforeCount - afterCount;

      if (cleanedCount > 0) {
        developer.log('✅ リスト「${list.listName}」: $cleanedCount個のアイテムをクリーンアップ');
        _ref.invalidate(allGroupsProvider);
      } else {
        developer.log('ℹ️ クリーンアップ対象のアイテムがありませんでした');
      }

      return cleanedCount;
    } catch (e, stackTrace) {
      developer.log('❌ クリーンアップエラー (ListID: $listId): $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 削除済みアイテムの統計情報を取得
  ///
  /// **戻り値**: {リストID: 削除済みアイテム数} のマップ
  Future<Map<String, int>> getDeletedItemsStats() async {
    try {
      final repository = _ref.read(sharedListRepositoryProvider);
      final allGroupsAsync = _ref.read(allGroupsProvider);
      final allGroups = allGroupsAsync.when(
        data: (groups) => groups,
        loading: () => [],
        error: (_, __) => [],
      );

      final allLists = <SharedList>[];
      for (final group in allGroups) {
        final groupLists =
            await repository.getSharedListsByGroup(group.groupId);
        allLists.addAll(groupLists);
      }

      final stats = <String, int>{};
      for (final list in allLists) {
        stats[list.listId] = list.deletedItemCount;
      }

      return stats;
    } catch (e) {
      developer.log('❌ 統計情報取得エラー: $e');
      return {};
    }
  }

  /// クリーンアップが必要なリストを取得
  ///
  /// **戻り値**: needsCleanup = true のリスト一覧
  Future<List<SharedList>> getListsNeedingCleanup() async {
    try {
      final repository = _ref.read(sharedListRepositoryProvider);
      final allGroupsAsync = _ref.read(allGroupsProvider);
      final allGroups = allGroupsAsync.when(
        data: (groups) => groups,
        loading: () => [],
        error: (_, __) => [],
      );

      final allLists = <SharedList>[];
      for (final group in allGroups) {
        final groupLists =
            await repository.getSharedListsByGroup(group.groupId);
        allLists.addAll(groupLists);
      }

      return allLists.where((list) => list.needsCleanup).toList();
    } catch (e) {
      developer.log('❌ クリーンアップ必要リスト取得エラー: $e');
      return [];
    }
  }
}

/// ListCleanupServiceのプロバイダー
final listCleanupServiceProvider = Provider<ListCleanupService>((ref) {
  return ListCleanupService(ref);
});
