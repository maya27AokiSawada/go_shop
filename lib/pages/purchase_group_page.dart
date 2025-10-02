import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_name_provider.dart';
import '../models/purchase_group.dart';

class PurchaseGroupPage extends ConsumerStatefulWidget {
  const PurchaseGroupPage({super.key});

  @override
  ConsumerState<PurchaseGroupPage> createState() => _PurchaseGroupPageState();
}

class _PurchaseGroupPageState extends ConsumerState<PurchaseGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseGroupAsync = ref.watch(purchaseGroupProvider);
    final allGroupsAsync = ref.watch(allGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    final currentUserName = ref.watch(userNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ管理'),
        actions: [
          // グループ追加ボタン
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGroupDialog(context),
          ),
          // グループ削除ボタン（デフォルトグループ以外）
          if (selectedGroupId != 'defaultGroup')
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteGroupDialog(context, selectedGroupId),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // グループ選択ドロップダウン
            _buildGroupDropdown(allGroupsAsync, selectedGroupId),
            const SizedBox(height: 16),
            // グループ内容表示
            Expanded(
              child: purchaseGroupAsync.when(
                data: (purchaseGroup) => _buildGroupContent(purchaseGroup, currentUserName),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('エラー: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupDropdown(AsyncValue<List<PurchaseGroup>> allGroupsAsync, String? selectedGroupId) {
    return allGroupsAsync.when(
      data: (groups) => DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'グループを選択',
          border: OutlineInputBorder(),
        ),
        initialValue: selectedGroupId,
        items: groups.map((group) => DropdownMenuItem(
          value: group.groupId,
          child: Text(group.groupId == 'defaultGroup' ? 'デフォルトグループ' : group.groupName),
        )).toList(),
        onChanged: (newGroupId) {
          if (newGroupId != null) {
            ref.read(selectedGroupIdProvider.notifier).selectGroup(newGroupId);
          }
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }

  Widget _buildGroupContent(PurchaseGroup purchaseGroup, String? currentUserName) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'グループ名: ${purchaseGroup.groupName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('グループID: ${purchaseGroup.groupId}'),
                const SizedBox(height: 8),
                Text('メンバー数: ${purchaseGroup.members?.length ?? 0}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: (purchaseGroup.members?.isEmpty ?? true)
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'メンバーがいません\n新しいメンバーを追加してください',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: purchaseGroup.members!.length,
                  itemBuilder: (context, index) {
                    final member = purchaseGroup.members![index];
                    final isCurrentUser = member.name == currentUserName;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          member.role.name == 'owner' ? Icons.star : Icons.person,
                          color: member.role.name == 'owner' ? Colors.amber : null,
                        ),
                        title: Text(member.name),
                        subtitle: Text('${member.role.name} - ${member.contact}'),
                        trailing: isCurrentUser ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('買い物リストへ'),
        ),
      ],
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新しいグループを作成'),
          content: TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(
              labelText: 'グループ名',
              hintText: 'グループ名を入力してください',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupName = _groupNameController.text.trim();
                if (groupName.isNotEmpty) {
                  try {
                    await ref.read(purchaseGroupProvider.notifier).createNewGroup(groupName);
                    _groupNameController.clear();
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('グループ「$groupName」を作成しました')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('グループの作成に失敗しました: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('作成'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteGroupDialog(BuildContext context, String? groupId) {
    if (groupId == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('グループを削除'),
          content: Text('グループ「$groupId」を削除しますか？\nこの操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await ref.read(purchaseGroupProvider.notifier).deleteGroup(groupId);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('グループ「$groupId」を削除しました')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('グループの削除に失敗しました: $e')),
                    );
                  }
                }
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }
}
