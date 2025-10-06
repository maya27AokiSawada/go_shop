import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_name_provider.dart';
import '../providers/security_provider.dart';
import '../models/purchase_group.dart';
import '../widgets/member_selection_dialog.dart';
import '../helpers/validation_service.dart';

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
    // セキュリティチェック
    final canViewData = ref.watch(dataVisibilityProvider);
    final authRequired = ref.watch(authRequiredProvider);
    
    if (!canViewData && authRequired) {
      return Scaffold(
        appBar: AppBar(title: const Text('グループ管理')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'シークレットモードが有効です',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'グループデータを表示するにはログインが必要です',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    final purchaseGroupAsync = ref.watch(purchaseGroupProvider);
    final allGroupsAsync = ref.watch(allGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    final currentUserName = ref.watch(userNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ管理'),
        actions: [
          // 設定メニュー
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              switch (value) {
                case 'delete_group':
                  if (selectedGroupId != 'defaultGroup') {
                    _showDeleteGroupDialog(context, selectedGroupId);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              if (selectedGroupId != 'defaultGroup')
                const PopupMenuItem(
                  value: 'delete_group',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('グループを削除'),
                    ],
                  ),
                ),
            ],
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
                data: (purchaseGroup) => _buildGroupContent(purchaseGroup, currentUserName, ref),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('エラー: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, selectedGroupId),
    );
  }

  Widget _buildGroupDropdown(AsyncValue<List<PurchaseGroup>> allGroupsAsync, String? selectedGroupId) {
    return allGroupsAsync.when(
      data: (groups) {
        // 選択されたグループが存在するかチェック
        final groupExists = groups.any((group) => group.groupId == selectedGroupId);
        final validSelectedGroupId = groupExists ? selectedGroupId : (groups.isNotEmpty ? groups.first.groupId : null);
        
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'グループを選択',
            border: OutlineInputBorder(),
          ),
          value: validSelectedGroupId,
          items: groups.map((group) => DropdownMenuItem(
            value: group.groupId,
            child: Text(group.groupId == 'defaultGroup' ? 'デフォルトグループ' : group.groupName),
          )).toList(),
          onChanged: (newGroupId) {
            if (newGroupId != null) {
              ref.read(selectedGroupIdProvider.notifier).selectGroup(newGroupId);
            }
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }

  Widget _buildGroupContent(PurchaseGroup purchaseGroup, String? currentUserName, WidgetRef ref) {
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
                    // 既存グループを取得して重複チェック
                    final allGroupsAsync = ref.read(allGroupsProvider);
                    final allGroups = allGroupsAsync.when(
                      data: (groups) => groups,
                      loading: () => <PurchaseGroup>[],
                      error: (_, __) => <PurchaseGroup>[],
                    );
                    
                    // バリデーション実行
                    final validation = ValidationService.validateGroupName(groupName, allGroups);
                    
                    if (validation.hasError) {
                      // エラー表示
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(validation.errorMessage!),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    
                    // グループ作成実行
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

  // フローティングアクションボタンの構築
  Widget _buildFloatingActionButton(BuildContext context, String? selectedGroupId) {
    return FloatingActionButton.extended(
      onPressed: () => _showActionMenu(context),
      label: const Text('追加'),
      icon: const Icon(Icons.add),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // アクションメニューを表示（グループ追加・メンバー追加）
  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '追加メニュー',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('新しいグループを追加'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddGroupDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('メンバーを追加'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddMemberDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // メンバー追加ダイアログ
  void _showAddMemberDialog(BuildContext context) async {
    final selectedMember = await showDialog<PurchaseGroupMember>(
      context: context,
      builder: (context) => const MemberSelectionDialog(),
    );

    if (selectedMember != null) {
      _addMemberToGroup(selectedMember);
    }
  }

  // グループにメンバーを追加
  void _addMemberToGroup(PurchaseGroupMember member) {
    final purchaseGroupNotifier = ref.read(purchaseGroupProvider.notifier);

    final currentGroup = ref.read(purchaseGroupProvider).value;
    if (currentGroup != null) {
      final updatedGroup = currentGroup.addMember(member);
      purchaseGroupNotifier.updateGroup(updatedGroup);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name}さんをメンバーに追加しました')),
      );
    }
  }
}
