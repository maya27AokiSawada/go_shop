// lib/widgets/member_role_management_widget.dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';

/// メンバーのRole管理ウィジェット（オーナー専用）
class MemberRoleManagementWidget extends ConsumerWidget {
  final PurchaseGroup purchaseGroup;
  final String currentUserUid;

  const MemberRoleManagementWidget({
    Key? key,
    required this.purchaseGroup,
    required this.currentUserUid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在のユーザーがオーナーかどうかチェック
    final isOwner = purchaseGroup.ownerUid == currentUserUid;

    if (!isOwner) {
      return const SizedBox.shrink(); // オーナー以外には表示しない
    }

    final members = purchaseGroup.members ?? [];
    final nonOwnerMembers = members
        .where((member) => member.role != PurchaseGroupRole.owner)
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
    PurchaseGroupMember member,
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
      title: Text(member.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (member.contact != null) Text(member.contact!),
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
    PurchaseGroupMember member,
  ) {
    if (member.role == PurchaseGroupRole.member) {
      // メンバーを管理者に昇格
      return IconButton(
        onPressed: () => _showPromoteDialog(context, ref, member),
        icon: const Icon(
          Icons.arrow_upward,
          color: Colors.orange,
        ),
        tooltip: '管理者に昇格',
      );
    } else if (member.role == PurchaseGroupRole.manager) {
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
    PurchaseGroupMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('管理者に昇格'),
        content: Text(
          '${member.displayName} さんを管理者に昇格させますか？\n\n'
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
      await _updateMemberRole(ref, member, PurchaseGroupRole.manager);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.displayName} さんを管理者に昇格しました'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _showDemoteDialog(
    BuildContext context,
    WidgetRef ref,
    PurchaseGroupMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーに降格'),
        content: Text(
          '${member.displayName} さんをメンバーに降格させますか？\n\n'
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
      await _updateMemberRole(ref, member, PurchaseGroupRole.member);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.displayName} さんをメンバーに降格しました'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _updateMemberRole(
    WidgetRef ref,
    PurchaseGroupMember member,
    PurchaseGroupRole newRole,
  ) async {
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);

      // メンバーのロールを更新
      final updatedMembers = purchaseGroup.members.map((m) {
        if (m.uid == member.uid) {
          return m.copyWith(role: newRole);
        }
        return m;
      }).toList();

      final updatedGroup = purchaseGroup.copyWith(members: updatedMembers);

      await repository.updateGroup(purchaseGroup.groupId, updatedGroup);

      // プロバイダーを更新
      ref.invalidate(selectedGroupNotifierProvider);
    } catch (e) {
      Log.error('❌ メンバーロール更新エラー: $e');
    }
  }

  Color _getRoleColor(PurchaseGroupRole role) {
    switch (role) {
      case PurchaseGroupRole.owner:
        return Colors.red;
      case PurchaseGroupRole.manager:
        return Colors.orange;
      case PurchaseGroupRole.member:
        return Colors.blue;
      case PurchaseGroupRole.friend:
        return Colors.pink;
    }
  }

  IconData _getRoleIcon(PurchaseGroupRole role) {
    switch (role) {
      case PurchaseGroupRole.owner:
        return Icons.star;
      case PurchaseGroupRole.manager:
        return Icons.admin_panel_settings;
      case PurchaseGroupRole.member:
        return Icons.person;
      case PurchaseGroupRole.friend:
        return Icons.favorite;
    }
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
        return 'フレンド';
    }
  }
}
