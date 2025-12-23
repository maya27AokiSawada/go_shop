// lib/widgets/shared_list_header_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_list.dart';
import '../providers/current_list_provider.dart';
import '../providers/group_shopping_lists_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shared_list_provider.dart';
import '../utils/app_logger.dart';

/// 買い物リスト画面のヘッダーウィジェット
/// - カレントグループ表示
/// - リスト選択ドロップダウン
class SharedListHeaderWidget extends ConsumerWidget {
  const SharedListHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    final allGroupsAsync = ref.watch(allGroupsProvider);
    final currentList = ref.watch(currentListProvider);
    final groupListsAsync = ref.watch(groupSharedListsProvider);

    // selectedGroupIdからcurrentGroupを取得
    final currentGroup = allGroupsAsync.whenOrNull(
      data: (groups) =>
          groups.where((g) => g.groupId == selectedGroupId).firstOrNull,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // グループ表示を削除（AppBarに統合済み）
          if (currentGroup == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'グループ画面でグループを選択してください',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (currentGroup != null) ...[
            const SizedBox(height: 12),

            // リスト選択ドロップダウン
            groupListsAsync.when(
              data: (lists) {
                if (lists.isEmpty) {
                  return _buildNoListsMessage(context, ref);
                }

                return _buildListDropdown(
                  context,
                  ref,
                  lists,
                  currentList,
                  currentGroup.groupId,
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'リスト取得エラー: $error',
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoListsMessage(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.list_alt, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '買い物リストがありません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade900,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showCreateListDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('作成', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildListDropdown(
    BuildContext context,
    WidgetRef ref,
    List<SharedList> lists,
    SharedList? currentList,
    String? currentGroupId,
  ) {
    // currentListIdがlists内に存在するかチェック
    final currentListId = currentList?.listId;

    // デバッグ: lists内の全listIdを表示
    if (lists.isNotEmpty) {
      Log.info(
          '🔍 [DEBUG] lists内のlistId: ${lists.map((l) => l.listId).join(", ")}');
    }

    final isCurrentListInLists = currentListId != null &&
        lists.any((list) => list.listId == currentListId);
    final validValue = isCurrentListInLists ? currentListId : null;

    Log.info(
        '🔍 [DEBUG] _buildListDropdown - currentList: ${currentList?.listName}, currentListId: $currentListId, validValue: $validValue, lists.length: ${lists.length}');

    return Row(
      children: [
        Icon(Icons.list, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: validValue,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
            ),
            hint: const Text('リストを選択'),
            items: lists.map((list) {
              return DropdownMenuItem<String>(
                value: list.listId,
                child: Text(
                  list.listName,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (listId) {
              if (listId != null) {
                final selectedList = lists.firstWhere(
                  (list) => list.listId == listId,
                );
                ref.read(currentListProvider.notifier).selectList(
                      selectedList,
                      groupId: currentGroupId,
                    );
                Log.info(
                    '📝 リスト選択: ${selectedList.listName} (グループ: $currentGroupId)');
              }
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle, color: Colors.blue.shade700),
          onPressed: () => _showCreateListDialog(context, ref),
          tooltip: '新しいリストを作成',
        ),
        // リスト削除ボタン（現在のリストが選択されている場合のみ表示）
        if (currentList != null)
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
            onPressed: () => _showDeleteListDialog(context, ref, currentList),
            tooltip: 'リストを削除',
          ),
      ],
    );
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しい買い物リストを作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'リスト名',
                hintText: '例: 週末の買い物',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                hintText: '例: 土曜日のスーパーで',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('リスト名を入力してください')),
                );
                return;
              }

              final selectedGroupId = ref.read(selectedGroupIdProvider);
              if (selectedGroupId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('グループが選択されていません')),
                );
                return;
              }

              // allGroupsProviderからcurrentGroupを取得
              final allGroupsAsync = ref.read(allGroupsProvider);
              final currentGroup = await allGroupsAsync.when(
                data: (groups) async => groups
                    .where((g) => g.groupId == selectedGroupId)
                    .firstOrNull,
                loading: () async => null,
                error: (_, __) async => null,
              );

              if (currentGroup == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('グループ情報の取得に失敗しました')),
                );
                return;
              }

              try {
                // リポジトリから新しいリストを作成
                final repository = ref.read(sharedListRepositoryProvider);
                final newList = await repository.createSharedList(
                  ownerUid: currentGroup.members?.isNotEmpty == true
                      ? currentGroup.members!.first.memberId
                      : 'dev_user',
                  groupId: currentGroup.groupId,
                  listName: name,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                Log.info(
                    '✅ 新しいリスト作成成功: ${newList.listName} (ID: ${newList.listId})');

                // 作成したリストをカレントリストに設定（Preferencesに保存）
                await ref.read(currentListProvider.notifier).selectList(
                      newList,
                      groupId: currentGroup.groupId,
                    );
                Log.info('📝 カレントリストに設定完了: ${newList.listName}');

                if (!context.mounted) return;
                Navigator.of(context).pop();

                // リスト一覧を無効化（次回アクセス時に再取得）
                ref.invalidate(groupSharedListsProvider);
                Log.info('✅ リスト一覧を無効化 - 次回アクセス時に自動更新');

                // 🔥 Windows環境でのフリーズ回避のため、await削除
                // StreamBuilderが次回アクセス時に自動的に最新データを取得

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「$name」を作成しました')),
                );
              } catch (e, stackTrace) {
                Log.error('❌ リスト作成エラー: $e', stackTrace);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('リスト作成に失敗しました: $e')),
                );
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  void _showDeleteListDialog(
      BuildContext context, WidgetRef ref, SharedList listToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リストを削除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${listToDelete.listName}」を削除しますか？'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'この操作は取り消せません',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                final repository = ref.read(sharedListRepositoryProvider);

                // リストを削除
                await repository.deleteSharedList(
                    listToDelete.groupId, listToDelete.listId);
                Log.info(
                    '✅ リスト削除成功: ${listToDelete.listName} (${listToDelete.listId})');

                // カレントリストをクリア（削除したリストが選択されていた場合）
                final currentList = ref.read(currentListProvider);
                if (currentList?.listId == listToDelete.listId) {
                  ref.read(currentListProvider.notifier).clearSelection();
                  Log.info('✅ カレントリスト選択をクリア');
                }

                // リスト一覧を更新して完了を待つ
                ref.invalidate(groupSharedListsProvider);
                try {
                  await ref.read(groupSharedListsProvider.future);
                  Log.info('✅ リスト一覧更新完了 - 削除後');
                } catch (e) {
                  Log.error('❌ リスト一覧更新エラー: $e');
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${listToDelete.listName}」を削除しました')),
                );
              } catch (e, stackTrace) {
                Log.error('❌ リスト削除エラー: $e', stackTrace);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('リスト削除に失敗しました: $e')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
