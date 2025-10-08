// lib/widgets/invitation_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/invitation_service.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';

/// 招待ダイアログ
class InvitationDialog extends ConsumerStatefulWidget {
  final PurchaseGroup group;

  const InvitationDialog({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends ConsumerState<InvitationDialog> {

  bool _isLoading = false;
  String? _generatedCode;
  List<PurchaseGroupMember> _candidateMembers = [];
  PurchaseGroupMember? _selectedMember;

  @override

  void initState() {
    super.initState();
    _loadCandidateMembers();
  }

  Future<void> _loadCandidateMembers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final repo = ref.read(purchaseGroupRepositoryProvider);
      await repo.syncMemberPool();
      final pool = await repo.getOrCreateMemberPool();
      final group = widget.group;
      final groupMemberIds = (group.members ?? []).map((m) => m.memberId).toSet();
      final groupContacts = (group.members ?? []).map((m) => m.contact).toSet();
    bool isFirebaseUid(String id) {
    // Firebase UIDは28文字の英数字
    final reg = RegExp(r'^[A-Za-z0-9]{28}$');
    return reg.hasMatch(id);
    }
    final candidates = (pool.members ?? [])
      .where((m) =>
        !groupMemberIds.contains(m.memberId) &&
        !groupContacts.contains(m.contact) &&
        !isFirebaseUid(m.memberId))
      .toList();
      setState(() {
        _candidateMembers = candidates;
        _selectedMember = candidates.isNotEmpty ? candidates.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('候補ユーザーの取得に失敗しました: $e')),
        );
      }
    }
  }


  Future<void> _sendInvitation() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('招待するユーザーを選択してください')),
      );
      return;
    }
    // すでに招待中かどうか
    if (_selectedMember!.isInvited && !_selectedMember!.isInvitationAccepted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('再送確認'),
          content: Text('${_selectedMember!.name}さんはすでに招待中です。再送しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('再送'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final invitationService = ref.read(invitationServiceProvider);
      final inviteCode = await invitationService.inviteUserToGroup(
        groupId: widget.group.groupId,
        groupName: widget.group.groupName,
        inviteeEmail: _selectedMember!.contact,
      );
      setState(() {
        _generatedCode = inviteCode;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('招待メールを送信しました\n招待コード: $inviteCode'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('招待の送信に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'グループ「${widget.group.groupName}」に招待',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '未認証ユーザーの中から招待したいユーザー名を選択してください。\n（すでに認証済みのユーザーやグループ参加済みユーザーは表示されません）',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!_isLoading && _candidateMembers.isEmpty)
              const Text('招待可能な未認証ユーザーがいません'),
            if (!_isLoading && _candidateMembers.isNotEmpty)
              DropdownButtonFormField<PurchaseGroupMember>(
                initialValue: _selectedMember,
                items: _candidateMembers.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text('${m.name}（${m.contact}）'),
                )).toList(),
                onChanged: _isLoading ? null : (member) {
                  setState(() {
                    _selectedMember = member;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'ユーザー名',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_generatedCode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '招待コード生成完了',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('コード: $_generatedCode'),
                    const SizedBox(height: 4),
                    Text(
                      '有効期限: 24時間',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading || _selectedMember == null ? null : _sendInvitation,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('招待を送信'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 招待ボタンウィジェット
class InviteButton extends StatelessWidget {
  final PurchaseGroup group;

  const InviteButton({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => InvitationDialog(group: group),
        );
      },
      icon: const Icon(Icons.person_add),
      label: const Text('メンバーを招待'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}