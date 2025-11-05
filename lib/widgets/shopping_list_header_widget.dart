// lib/widgets/shopping_list_header_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list.dart';
import '../providers/current_group_provider.dart';
import '../providers/current_list_provider.dart';
import '../providers/group_shopping_lists_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../utils/app_logger.dart';

/// 買い物リスト画面のヘッダーウィジェット
/// - カレントグループ表示
/// - リスト選択ドロップダウン
class ShoppingListHeaderWidget extends ConsumerWidget {
  const ShoppingListHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentGroup = ref.watch(currentGroupProvider);
    final currentList = ref.watch(currentListProvider);
    final groupListsAsync = ref.watch(groupShoppingListsProvider);

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
          // カレントグループ表示
          Row(
            children: [
              Icon(Icons.group, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                currentGroup?.groupName ?? 'グループ未選択',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: currentGroup != null
                      ? Colors.blue.shade900
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),

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
    List<ShoppingList> lists,
    ShoppingList? currentList,
  ) {
    return Row(
      children: [
        Icon(Icons.list, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: currentList?.listId,
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
                ref.read(currentListProvider.notifier).selectList(selectedList);
                Log.info('📝 リスト選択: ${selectedList.listName}');
              }
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle, color: Colors.blue.shade700),
          onPressed: () => _showCreateListDialog(context, ref),
          tooltip: '新しいリストを作成',
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

              final currentGroup = ref.read(currentGroupProvider);
              if (currentGroup == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('グループが選択されていません')),
                );
                return;
              }

              try {
                // リポジトリから新しいリストを作成
                final repository = ref.read(shoppingListRepositoryProvider);
                final newList = await repository.createShoppingList(
                  ownerUid: currentGroup.members.firstOrNull?.uid ?? 'dev_user',
                  groupId: currentGroup.groupId,
                  listName: name,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                Log.info(
                    '✅ 新しいリスト作成成功: ${newList.listName} (ID: ${newList.listId})');

                // プロバイダーを更新してUIに反映
                ref.invalidate(groupShoppingListsProvider);

                // 作成したリストをカレントリストに設定
                ref.read(currentListProvider.notifier).selectList(newList);

                Navigator.of(context).pop();

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
}
