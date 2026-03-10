// lib/widgets/member_role_management_widget.dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../models/shared_group.dart';
import '../providers/shared_group_provider.dart';

/// メンバーのRole管理ウィジェット（オーナー専用）
class MemberRoleManagementWidget extends ConsumerWidget {
  final SharedGroup group;
  final String currentUserUid;

  const MemberRoleManagementWidget({
    Key? key,
    required this.group,
    required this.currentUserUid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在のユーザーがオーナーかどうかチェック
    final isOwner = group.ownerUid == currentUserUid;

    if (!isOwner) {
      return const SizedBox.shrink(); // オーナー以外には表示しない
    }

    final members = group.members ?? [];
    final nonOwnerMembers = members
        .where((member) => member.role != SharedGroupRole.owner)
        .toList();

    if (nonOwnerMembers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👥 メンバー管理',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('招待されたメンバーはここに表示されます。'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👥 メンバー管理',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...nonOwnerMembers.map((member) => _buildMemberTile(
                  context,
                  ref,
                  member,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    WidgetRef ref,
    SharedGroupMember member,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRoleColor(member.role),
        child: Icon(
          _getRoleIcon(member.role),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(member.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.contact),
          Text(
            _getRoleDisplayName(member.role),
            style: TextStyle(
              color: _getRoleColor(member.role),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      trailing: _buildRoleChangeButton(context, ref, member),
    );
  }

  Widget? _buildRoleChangeButton(
    BuildContext context,
    WidgetRef ref,
    SharedGroupMember member,
  ) {
    if (member.role == SharedGroupRole.member) {
      // メンバーを管理者に昇格
      return IconButton(
        onPressed: () => _showPromoteDialog(context, ref, member),
        icon: const Icon(
          Icons.arrow_upward,
          color: Colors.orange,
        ),
        tooltip: '管理者に昇格',
      );
    } else if (member.role == SharedGroupRole.manager) {
      // 管理者をメンバーに降格
      return IconButton(
        onPressed: () => _showDemoteDialog(context, ref, member),
        icon: const Icon(
          Icons.arrow_downward,
          color: Colors.blue,
        ),
        tooltip: 'メンバーに降格',
      );
    }
    return null;
  }

  Future<void> _showPromoteDialog(
    BuildContext context,
    WidgetRef ref,
    SharedGroupMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('管理者に昇格'),
        content: Text(
          '${member.name} さんを管理者に昇格させますか？\n\n'
          '管理者はグループの設定変更や他のメンバーの管理ができるようになります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('昇格'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _updateMemberRole(ref, member, SharedGroupRole.manager);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} さんを管理者に昇格しました'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _showDemoteDialog(
    BuildContext context,
    WidgetRef ref,
    SharedGroupMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーに降格'),
        content: Text(
          '${member.name} さんをメンバーに降格させますか？\n\n'
          'グループの設定変更権限が取り消されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('降格'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _updateMemberRole(ref, member, SharedGroupRole.member);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} さんをメンバーに降格しました'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _updateMemberRole(
    WidgetRef ref,
    SharedGroupMember member,
    SharedGroupRole newRole,
  ) async {
    try {
      final repository = ref.read(SharedGroupRepositoryProvider);

      // メンバーのロールを更新
      final updatedMembers = group.members?.map((m) {
        if (m.memberId == member.memberId) {
          return m.copyWith(role: newRole);
        }
        return m;
      }).toList();

      final updatedGroup = group.copyWith(members: updatedMembers);

      await repository.updateGroup(group.groupId, updatedGroup);

      // プロバイダーを更新
      ref.invalidate(selectedGroupNotifierProvider);
    } catch (e) {
      Log.error('❌ メンバーロール更新エラー: $e');
    }
  }

  Color _getRoleColor(SharedGroupRole role) {
    switch (role) {
      case SharedGroupRole.owner:
        return Colors.red;
      case SharedGroupRole.manager:
        return Colors.orange;
      case SharedGroupRole.member:
        return Colors.blue;
      case SharedGroupRole.partner:
        return Colors.purple;
    }
  }

  IconData _getRoleIcon(SharedGroupRole role) {
    switch (role) {
      case SharedGroupRole.owner:
        return Icons.star;
      case SharedGroupRole.manager:
        return Icons.admin_panel_settings;
      case SharedGroupRole.member:
        return Icons.person;
      case SharedGroupRole.partner:
        return Icons.handshake;
    }
  }

  String _getRoleDisplayName(SharedGroupRole role) {
    switch (role) {
      case SharedGroupRole.owner:
        return 'オーナー';
      case SharedGroupRole.manager:
        return '管理者';
      case SharedGroupRole.member:
        return 'メンバー';
      case SharedGroupRole.partner:
        return 'パートナー';
    }
  }
}
