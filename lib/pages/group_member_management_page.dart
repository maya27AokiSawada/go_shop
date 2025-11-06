import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../utils/app_logger.dart';
import '../widgets/member_selection_dialog.dart';
import '../pages/group_invitation_page.dart';

/// グループのメンバー管理画面
/// 招待→ユーザー情報セットの流れに対応
class GroupMemberManagementPage extends ConsumerStatefulWidget {
  final PurchaseGroup group;

  const GroupMemberManagementPage({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupMemberManagementPage> createState() =>
      _GroupMemberManagementPageState();
}

class _GroupMemberManagementPageState
    extends ConsumerState<GroupMemberManagementPage> {
  bool _isDefaultGroup(PurchaseGroup group) {
    return group.groupId == 'default_group';
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroupAsync = ref.watch(selectedGroupProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.groupName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // デフォルトグループ（プライベート専用）では招待機能を非表示
          if (widget.group.groupId != 'default_group')
            IconButton(
              onPressed: () {
                _showInviteOptions(context);
              },
              icon: const Icon(Icons.person_add),
              tooltip: 'メンバーを招待',
            ),
        ],
      ),
      body: selectedGroupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(
              child: Text('グループが見つかりません'),
            );
          }
          return _buildMemberList(group);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('エラーが発生しました'),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(selectedGroupProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList(PurchaseGroup group) {
    final members = group.members ?? [];

    return Column(
      children: [
        // グループ情報ヘッダー
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDefaultGroup(group)
                ? Colors.green.shade50
                : Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'グループ情報',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isDefaultGroup(group)
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text('グループ名: ${group.groupName}'),
              if (_isDefaultGroup(group)) ...[
                Text(
                  'プライベート専用（あなたのみ）',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Text('メンバー数: ${members.length}人'),
                if (group.ownerName?.isNotEmpty == true)
                  Text('オーナー: ${group.ownerName}'),
              ],
            ],
          ),
        ),

        // メンバーリスト
        Expanded(
          child: members.isEmpty
              ? _buildEmptyMemberList()
              : ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _buildMemberTile(member, group);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(PurchaseGroupMember member, PurchaseGroup group) {
    final isOwner = member.role == PurchaseGroupRole.owner;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isOwner ? Colors.amber.shade100 : Colors.blue.shade100,
          child: Icon(
            isOwner ? Icons.star : Icons.person,
            color: isOwner ? Colors.amber.shade700 : Colors.blue.shade700,
          ),
        ),
        title: Text(
          member.name.isNotEmpty ? member.name : 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.contact),
            Text(
              _getRoleDisplayName(member.role),
              style: TextStyle(
                color: isOwner ? Colors.amber.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: isOwner
            ? const Icon(Icons.star, color: Colors.amber)
            : PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMemberAction(value, member, group),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit_role',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('権限を変更'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('メンバーを削除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyMemberList() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'メンバーがいません',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            '右上の + ボタンから\nメンバーを招待してください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showInviteOptions(context),
            icon: const Icon(Icons.person_add),
            label: const Text('メンバーを招待'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(PurchaseGroupRole role) {
    switch (role) {
      case PurchaseGroupRole.owner:
        return 'オーナー';
      case PurchaseGroupRole.manager:
        return '管理者';
      case PurchaseGroupRole.member:
        return 'メンバー';
      case PurchaseGroupRole.friend:
        return '友達';
    }
  }

  void _showInviteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'メンバー招待方法を選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text('QRコードで招待'),
              subtitle: const Text('QRコードを生成して相手にスキャンしてもらう'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GroupInvitationPage(group: widget.group),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.green),
              title: const Text('メールで招待'),
              subtitle: const Text('メールアドレスを指定して招待を送信'),
              onTap: () {
                Navigator.pop(context);
                _showEmailInviteDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.orange),
              title: const Text('手動でメンバー追加'),
              subtitle: const Text('メンバー情報を直接入力'),
              onTap: () {
                Navigator.pop(context);
                _showAddMemberDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailInviteDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メールで招待'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('招待するメールアドレスを入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                _sendEmailInvitation(emailController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('招待を送信'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => const MemberSelectionDialog(),
    ).then((member) {
      if (member != null && member is PurchaseGroupMember) {
        _addMember(member);
      }
    });
  }

  void _addMember(PurchaseGroupMember member) async {
    try {
      await ref.read(purchaseGroupRepositoryProvider).addMember(
            widget.group.groupId,
            member,
          );

      ref.invalidate(selectedGroupProvider);

      AppLogger.info('✅ [MEMBER_MGMT] メンバー追加完了: ${member.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} を追加しました')),
      );
    } catch (e) {
      AppLogger.error('❌ [MEMBER_MGMT] メンバー追加エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('追加に失敗しました: $e')),
      );
    }
  }

  void _sendEmailInvitation(String email) {
    // TODO: メール招待機能の実装
    AppLogger.info('📧 [MEMBER_MGMT] メール招待: $email');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$email に招待を送信しました')),
    );
  }

  void _handleMemberAction(
      String action, PurchaseGroupMember member, PurchaseGroup group) {
    switch (action) {
      case 'edit_role':
        _showRoleEditDialog(member, group);
        break;
      case 'remove':
        _showRemoveMemberDialog(member, group);
        break;
    }
  }

  void _showRoleEditDialog(PurchaseGroupMember member, PurchaseGroup group) {
    // TODO: 権限変更ダイアログの実装
    AppLogger.info('⚙️ [MEMBER_MGMT] 権限変更: ${member.name}');
  }

  void _showRemoveMemberDialog(
      PurchaseGroupMember member, PurchaseGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text('${member.name} をグループから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _removeMember(member, group);
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _removeMember(PurchaseGroupMember member, PurchaseGroup group) async {
    try {
      await ref.read(purchaseGroupRepositoryProvider).removeMember(
            group.groupId,
            member,
          );

      ref.invalidate(selectedGroupProvider);

      AppLogger.info('✅ [MEMBER_MGMT] メンバー削除完了: ${member.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} を削除しました')),
      );
    } catch (e) {
      AppLogger.error('❌ [MEMBER_MGMT] メンバー削除エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }
}
