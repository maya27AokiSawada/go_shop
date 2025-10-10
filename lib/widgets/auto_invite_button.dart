// lib/widgets/auto_invite_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../services/invitation_service.dart';

/// 自動招待ボタンウィジェット
class AutoInviteButton extends ConsumerWidget {
  final PurchaseGroup group;
  
  const AutoInviteButton({
    super.key, 
    required this.group,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _handleAutoInvite(context, ref),
      icon: const Icon(Icons.send),
      label: const Text('メンバーを招待'),
    );
  }

  Future<void> _handleAutoInvite(BuildContext context, WidgetRef ref) async {
    try {
      // 未受諾ユーザーを抽出
      final pendingMembers = _getPendingMembers();
      
      if (pendingMembers.isEmpty) {
        _showNoInviteesDialog(context);
        return;
      }

      // 既に招待送信済みのユーザーがいるかチェック
      final alreadyInvitedMembers = pendingMembers.where((m) => m.isInvited).toList();
      final notInvitedMembers = pendingMembers.where((m) => !m.isInvited).toList();

      List<PurchaseGroupMember> membersToInvite;

      if (alreadyInvitedMembers.isNotEmpty) {
        // 確認ダイアログを表示
        final shouldInviteAll = await _showReinviteConfirmDialog(
          context, 
          alreadyInvitedMembers, 
          notInvitedMembers
        );
        
        if (shouldInviteAll == null) return; // キャンセル
        
        membersToInvite = shouldInviteAll ? pendingMembers : notInvitedMembers;
      } else {
        membersToInvite = notInvitedMembers;
      }

      if (membersToInvite.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('招待対象のユーザーがいません')),
        );
        return;
      }

      // 招待送信実行
      await _sendBulkInvitations(context, ref, membersToInvite);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  List<PurchaseGroupMember> _getPendingMembers() {
    bool isFirebaseUid(String id) {
      final reg = RegExp(r'^[A-Za-z0-9]{28}$');
      return reg.hasMatch(id);
    }

    return (group.members ?? [])
        .where((m) {
          // 既に招待受諾済みは除外
          if (m.isInvitationAccepted) return false;
          
          // Firebase UIDを持ち、かつサインイン済みは除外
          if (isFirebaseUid(m.memberId) && m.isSignedIn) return false;
          
          return true;
        })
        .toList();
  }

  Future<bool?> _showReinviteConfirmDialog(
    BuildContext context,
    List<PurchaseGroupMember> alreadyInvited,
    List<PurchaseGroupMember> notInvited,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('招待確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${alreadyInvited.length}人が既に招待済みです：'),
            ...alreadyInvited.map((m) => Text('• ${m.name}', style: const TextStyle(color: Colors.orange))),
            if (notInvited.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${notInvited.length}人が未招待です：'),
              ...notInvited.map((m) => Text('• ${m.name}')),
            ],
            const SizedBox(height: 16),
            const Text('どうしますか？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('キャンセル'),
          ),
          if (notInvited.isNotEmpty)
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('未招待のみ送信 (${notInvited.length}人)'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('全員に送信 (${alreadyInvited.length + notInvited.length}人)'),
          ),
        ],
      ),
    );
  }

  void _showNoInviteesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('招待対象なし'),
        content: const Text('招待可能なメンバーがいません。\n\n• 全員が既に参加済みか\n• 認証済みユーザーのみです'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBulkInvitations(
    BuildContext context,
    WidgetRef ref,
    List<PurchaseGroupMember> members,
  ) async {
    final invitationService = ref.read(invitationServiceProvider);
    
    // 進行状況ダイアログを表示
    final progressContext = context;
    showDialog(
      context: progressContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('招待送信中...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${members.length}人に招待を送信しています'),
          ],
        ),
      ),
    );

    int successCount = 0;
    int errorCount = 0;
    List<String> errorMessages = [];

    for (final member in members) {
      try {
        await invitationService.inviteUserToGroup(
          groupId: group.groupId,
          groupName: group.groupName,
          inviteeEmail: member.contact,
          inviterName: 'Go Shop User', // TODO: 実際のユーザー名に置き換える
        );

        // メンバーの招待状態を更新
        await _updateMemberInvitationStatus(ref, member.memberId);
        successCount++;
      } catch (e) {
        errorCount++;
        errorMessages.add('${member.name}: $e');
      }
    }

    // 進行状況ダイアログを閉じる
    Navigator.of(progressContext).pop();

    // 結果を表示
    _showInvitationResult(context, successCount, errorCount, errorMessages);
  }

  Future<void> _updateMemberInvitationStatus(WidgetRef ref, String memberId) async {
    try {
      final updatedMembers = group.members?.map((m) {
        if (m.memberId == memberId) {
          return m.copyWith(
            isInvited: true,
            isInvitationAccepted: false,
            invitedAt: DateTime.now(),
          );
        }
        return m;
      }).toList() ?? [];
      
      final updatedGroup = group.copyWith(members: updatedMembers);
      final repo = ref.read(purchaseGroupRepositoryProvider);
      await repo.updateGroup(group.groupId, updatedGroup);
      ref.invalidate(purchaseGroupProvider);
    } catch (e) {
      print('⚠️ メンバー招待状態更新エラー: $e');
    }
  }

  void _showInvitationResult(
    BuildContext context,
    int successCount,
    int errorCount,
    List<String> errorMessages,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('招待送信完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ 成功: $successCount件'),
            if (errorCount > 0) ...[
              Text('❌ 失敗: $errorCount件', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              const Text('エラー詳細:'),
              ...errorMessages.map((msg) => Text('• $msg', style: const TextStyle(fontSize: 12))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}