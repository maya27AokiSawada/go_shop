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

  String _getRoleDisplayName(PurchaseGroupRole role) {
    switch (role) {
      case PurchaseGroupRole.owner:
        return 'オーナー';
      case PurchaseGroupRole.manager:
        return '管理者';
      case PurchaseGroupRole.member:
        return 'メンバー';
    }
  }

  Future<void> _editMember(PurchaseGroupMember member, int index) async {
    final result = await showDialog<PurchaseGroupMember>(
      context: context,
      builder: (context) => _EditMemberDialog(member: member),
    );
    
    if (result != null) {
      try {
        final currentGroup = ref.read(purchaseGroupProvider).value;
        if (currentGroup != null) {
          final updatedMembers = List<PurchaseGroupMember>.from(currentGroup.members ?? []);
          updatedMembers[index] = result;
          final updatedGroup = currentGroup.copyWith(members: updatedMembers);
          await ref.read(purchaseGroupProvider.notifier).updateGroup(updatedGroup);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メンバーの更新に失敗しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteMember(PurchaseGroupMember member, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text('${member.name}をこのグループから削除しますか？\n\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final currentGroup = ref.read(purchaseGroupProvider).value;
        if (currentGroup != null) {
          final updatedMembers = List<PurchaseGroupMember>.from(currentGroup.members ?? []);
          updatedMembers.removeAt(index);
          final updatedGroup = currentGroup.copyWith(members: updatedMembers);
          await ref.read(purchaseGroupProvider.notifier).updateGroup(updatedGroup);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${member.name}を削除しました')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メンバーの削除に失敗しました: $e')),
          );
        }
      }
    }
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
          initialValue: validSelectedGroupId,
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
                          member.role == PurchaseGroupRole.owner ? Icons.star :
                          member.role == PurchaseGroupRole.manager ? Icons.admin_panel_settings :
                          Icons.person,
                          color: member.role == PurchaseGroupRole.owner ? Colors.amber :
                                 member.role == PurchaseGroupRole.manager ? Colors.blue :
                                 null,
                        ),
                        title: Text(member.name),
                        subtitle: Text('${_getRoleDisplayName(member.role)} - ${member.contact}'),
                        trailing: isCurrentUser ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        onTap: () => _editMember(member, index),
                        onLongPress: member.role != PurchaseGroupRole.owner 
                          ? () => _deleteMember(member, index)
                          : null,
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
                  // BuildContextを事前に保存
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
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
                        messenger.showSnackBar(
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
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text('グループ「$groupName」を作成しました')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
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
                // BuildContextを事前に保存
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                
                try {
                  await ref.read(purchaseGroupProvider.notifier).deleteGroup(groupId);
                  if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('グループ「$groupId」を削除しました')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
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

class _EditMemberDialog extends StatefulWidget {
  final PurchaseGroupMember member;

  const _EditMemberDialog({required this.member});

  @override
  State<_EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<_EditMemberDialog> {
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late PurchaseGroupRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _contactController = TextEditingController(text: widget.member.contact);
    _selectedRole = widget.member.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('メンバー編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名前',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: '連絡先',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PurchaseGroupRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: '役割',
                border: OutlineInputBorder(),
              ),
              items: PurchaseGroupRole.values.map((role) {
                String roleName;
                switch (role) {
                  case PurchaseGroupRole.owner:
                    roleName = 'オーナー';
                    break;
                  case PurchaseGroupRole.manager:
                    roleName = '管理者';
                    break;
                  case PurchaseGroupRole.member:
                    roleName = 'メンバー';
                    break;
                }
                return DropdownMenuItem(
                  value: role,
                  child: Text(roleName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _canSave() ? () {
            final updatedMember = widget.member.copyWith(
              name: _nameController.text.trim(),
              contact: _contactController.text.trim(),
              role: _selectedRole,
            );
            Navigator.of(context).pop(updatedMember);
          } : null,
          child: const Text('保存'),
        ),
      ],
    );
  }

  bool _canSave() {
    return _nameController.text.trim().isNotEmpty &&
           _contactController.text.trim().isNotEmpty;
  }
}
