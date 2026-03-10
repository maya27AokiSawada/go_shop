// lib/providers/group_shared_lists_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_list.dart';
import '../providers/shared_list_provider.dart';
import '../providers/shared_group_provider.dart';
import '../providers/current_list_provider.dart';
import '../utils/app_logger.dart';

/// 現在のグループに属する買い物リスト一覧を取得するProvider
final groupSharedListsProvider =
    FutureProvider.autoDispose<List<SharedList>>((ref) async {
  final selectedGroupId = ref.watch(selectedGroupIdProvider);

  if (selectedGroupId == null) {
    Log.info('⚠️ グループが未選択のため、空リストを返します');
    return [];
  }

  // allGroupsProviderからcurrentGroupを取得
  final allGroupsAsync = ref.watch(allGroupsProvider);
  final currentGroup = await allGroupsAsync.when(
    data: (groups) async =>
        groups.where((g) => g.groupId == selectedGroupId).firstOrNull,
    loading: () async => null,
    error: (_, __) async => null,
  );

  Log.info(
      '🔍 [DEBUG] groupSharedListsProvider - currentGroup: ${currentGroup?.groupName} (${currentGroup?.groupId})');

  if (currentGroup == null) {
    Log.info('⚠️ グループ情報の取得に失敗したため、空リストを返します');
    return [];
  }

  // 削除されたグループのリストは表示しない
  if (currentGroup.isDeleted) {
    Log.warning('⚠️ グループ「${currentGroup.groupName}」は削除済みのため、空リストを返します');
    return [];
  }

  Log.info('🔄 グループ「${currentGroup.groupName}」のリスト一覧を取得中...');

  final repository = ref.read(sharedListRepositoryProvider);
  final groupLists =
      await repository.getSharedListsByGroup(currentGroup.groupId);

  Log.info('✅ ${groupLists.length}件のリストを取得しました');

  // リストが1つしかない場合は自動的にカレントリストに設定
  if (groupLists.length == 1) {
    final currentList = ref.read(currentListProvider);
    final onlyList = groupLists.first;

    // カレントリストが未設定、異なるグループのリスト、またはリスト一覧に存在しない場合に設定
    final shouldSetCurrent = currentList == null ||
        currentList.groupId != currentGroup.groupId ||
        !groupLists.any((list) => list.listId == currentList.listId);

    if (shouldSetCurrent) {
      Log.info('📌 リストが1件のみのため自動設定: ${onlyList.listName} (${onlyList.listId})');
      await ref.read(currentListProvider.notifier).selectList(
            onlyList,
            groupId: currentGroup.groupId,
          );
    } else {
      Log.info('ℹ️ カレントリストは既に正しく設定されています: ${currentList.listName}');
    }
  }

  return groupLists;
});
