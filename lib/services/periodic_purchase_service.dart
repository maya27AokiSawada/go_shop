import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_list.dart';
import '../providers/shared_list_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../utils/app_logger.dart';

/// 定期購入アイテムの自動リセットサービス
///
/// **主要機能**:
/// - 購入済み + 定期購入間隔設定済みアイテムの自動リセット
/// - 購入日から指定間隔経過後、未購入状態に戻す
/// - 購入日をクリア
///
/// **処理条件**:
/// - `isPurchased = true`
/// - `shoppingInterval > 0`
/// - `purchaseDate + shoppingInterval日 <= 現在日時`
class PeriodicPurchaseService {
  final Ref _ref;

  PeriodicPurchaseService(this._ref);

  /// 全リストの定期購入アイテムをチェックしてリセット
  ///
  /// **戻り値**: リセットされたアイテム数
  Future<int> resetPeriodicPurchaseItems() async {
    try {
      Log.info('🔄 定期購入アイテムリセットサービス開始');

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

      Log.info('📊 対象リスト数: ${allLists.length}');

      int totalResetCount = 0;

      // 各リストをチェック
      for (final list in allLists) {
        final resetCount =
            await _resetPeriodicPurchaseItemsInList(list, repository);
        totalResetCount += resetCount;
      }

      Log.info('✅ 定期購入リセット完了: $totalResetCount 件のアイテムをリセット');

      return totalResetCount;
    } catch (e) {
      Log.error('❌ 定期購入リセットエラー: $e');
      return 0;
    }
  }

  /// 特定リストの定期購入アイテムをリセット
  ///
  /// [listId]: リストID
  ///
  /// **戻り値**: リセットされたアイテム数
  Future<int> resetPeriodicPurchaseItemsForList(String listId) async {
    try {
      Log.info('🔄 特定リストの定期購入アイテムリセット: listId=$listId');

      final repository = _ref.read(sharedListRepositoryProvider);

      // リストを取得
      final list = await repository.getSharedListById(listId);
      if (list == null) {
        Log.warning('⚠️ リストが見つかりません: $listId');
        return 0;
      }

      return await _resetPeriodicPurchaseItemsInList(list, repository);
    } catch (e) {
      Log.error('❌ 特定リストの定期購入リセットエラー: $e');
      return 0;
    }
  }

  /// リスト内の定期購入アイテムをリセット（内部処理）
  Future<int> _resetPeriodicPurchaseItemsInList(
    SharedList list,
    dynamic repository,
  ) async {
    int resetCount = 0;
    final now = DateTime.now();

    // リセット対象アイテムを検出
    final itemsToReset = <SharedItem>[];
    for (final item in list.activeItems) {
      if (_shouldResetItem(item, now)) {
        itemsToReset.add(item);
      }
    }

    if (itemsToReset.isEmpty) {
      return 0;
    }

    Log.info('📝 リスト「${list.listName}」でリセット対象: ${itemsToReset.length} 件');

    // アイテムを未購入状態にリセット
    final updatedItems = Map<String, SharedItem>.from(list.items);
    for (final item in itemsToReset) {
      final resetItem = item.copyWith(
        isPurchased: false,
        purchaseDate: null, // 購入日をクリア
      );
      updatedItems[item.itemId] = resetItem;

      Log.info(
          '🔄 リセット: ${item.name} (${item.shoppingInterval}日間隔, 購入日: ${item.purchaseDate})');
      resetCount++;
    }

    // リストを更新
    final updatedList = list.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await repository.updateSharedList(updatedList);

    return resetCount;
  }

  /// アイテムをリセットすべきか判定
  bool _shouldResetItem(SharedItem item, DateTime now) {
    // 購入済みでない場合はスキップ
    if (!item.isPurchased) return false;

    // 定期購入間隔が0の場合はスキップ（通常購入）
    if (item.shoppingInterval <= 0) return false;

    // 購入日がnullの場合はスキップ
    if (item.purchaseDate == null) return false;

    // 購入日 + 間隔日数 <= 現在日時 の場合にリセット
    final nextPurchaseDate =
        item.purchaseDate!.add(Duration(days: item.shoppingInterval));

    return now.isAfter(nextPurchaseDate) ||
        now.isAtSameMomentAs(nextPurchaseDate);
  }

  /// 定期購入アイテム情報を取得（デバッグ用）
  Future<Map<String, dynamic>> getPeriodicPurchaseInfo() async {
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

      int totalPeriodicItems = 0;
      int readyToResetItems = 0;
      final now = DateTime.now();

      for (final list in allLists) {
        for (final item in list.activeItems) {
          if (item.shoppingInterval > 0) {
            totalPeriodicItems++;
            if (_shouldResetItem(item, now)) {
              readyToResetItems++;
            }
          }
        }
      }

      return {
        'totalLists': allLists.length,
        'totalPeriodicItems': totalPeriodicItems,
        'readyToResetItems': readyToResetItems,
      };
    } catch (e) {
      Log.error('❌ 定期購入情報取得エラー: $e');
      return {
        'totalLists': 0,
        'totalPeriodicItems': 0,
        'readyToResetItems': 0,
        'error': e.toString(),
      };
    }
  }
}

/// プロバイダー
final periodicPurchaseServiceProvider = Provider<PeriodicPurchaseService>(
  (ref) => PeriodicPurchaseService(ref),
);
