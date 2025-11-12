// lib/providers/group_shopping_lists_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/current_group_provider.dart';
import '../utils/app_logger.dart';

/// 現在のグループに属する買い物リスト一覧を取得するProvider
final groupShoppingListsProvider =
    FutureProvider.autoDispose<List<ShoppingList>>((ref) async {
  final currentGroup = ref.watch(currentGroupProvider);

  Log.info(
      '🔍 [DEBUG] groupShoppingListsProvider - currentGroup: ${currentGroup?.groupName} (${currentGroup?.groupId})');

  if (currentGroup == null) {
    Log.info('⚠️ カレントグループが未設定のため、空リストを返します');
    return [];
  }

  // 削除されたグループのリストは表示しない
  if (currentGroup.isDeleted) {
    Log.warning('⚠️ グループ「${currentGroup.groupName}」は削除済みのため、空リストを返します');
    return [];
  }

  Log.info('🔄 グループ「${currentGroup.groupName}」のリスト一覧を取得中...');

  final repository = ref.read(shoppingListRepositoryProvider);
  final groupLists =
      await repository.getShoppingListsByGroup(currentGroup.groupId);

  Log.info('✅ ${groupLists.length}件のリストを取得しました');
  return groupLists;
});
