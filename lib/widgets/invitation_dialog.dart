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
      final group = widget.group;
      
      bool isFirebaseUid(String id) {
        // Firebase UIDは28文字の英数字
        final reg = RegExp(r'^[A-Za-z0-9]{28}$');
        return reg.hasMatch(id);
      }
      
      // 購入グループのメンバーリストから招待候補者を選択
      final candidates = (group.members ?? [])
        .where((m) {
          // 既に招待受諾済み（参加済み）のユーザーは除外
          if (m.isInvitationAccepted) {
            return false;
          }
          
          // 🔧 デバッグ: メンバー情報をログ出力
          print('📋 メンバー: ${m.name}, memberId: ${m.memberId}, isInvited: ${m.isInvited}, isInvitationAccepted: ${m.isInvitationAccepted}');
          
          // Firebase UIDを持つユーザー（既にサインイン済み）は除外
          // ただし、実際のサインイン状態（isSignedIn）もチェック
          if (isFirebaseUid(m.memberId) && m.isSignedIn) {
            return false;
          }
          
          // 未招待または招待中のユーザーを表示
          return true;
        })
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


  /// グループメンバーの招待状態を更新
  Future<void> _updateGroupMemberInvitationStatus(PurchaseGroupMember member, String inviteCode) async {
    try {
      final group = widget.group;
      
      // 該当メンバーの状態を更新
      final updatedMembers = (group.members ?? []).map((m) {
        if (m.memberId == member.memberId || m.contact == member.contact) {
          return m.copyWith(
            isInvited: true,
            isInvitationAccepted: false,
            invitedAt: DateTime.now(),
          );
        }
        return m;
      }).toList();
      
      final updatedGroup = group.copyWith(members: updatedMembers);
      
      // グループを更新
      final repo = ref.read(purchaseGroupRepositoryProvider);
      await repo.updateGroup(group.groupId, updatedGroup);
      
      // Providerを無効化して再読み込みを促す
      ref.invalidate(selectedGroupNotifierProvider);
    } catch (e) {
      print('⚠️ グループメンバー更新エラー: $e');
      // エラーが発生してもメール送信は成功しているので、続行
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
        inviterName: 'Go Shop User', // TODO: 実際のユーザー名に置き換える
      );
      // 招待成功後、メンバープールの状態を更新
      await _updateGroupMemberInvitationStatus(_selectedMember!, inviteCode);
      
      setState(() {
        _generatedCode = inviteCode;
        _isLoading = false;
      });
      
      // 候補リストを再読み込みして表示を更新
      await _loadCandidateMembers();
      
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'グループ「${widget.group.groupName}」に招待',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'キャンセル',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '招待したいユーザー名を選択してください。\n• [招待中] マークがあるユーザーは再送確認が表示されます\n• 既にグループ参加済み・認証済みのユーザーは表示されません',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!_isLoading && _candidateMembers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '招待可能なユーザーがいません',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 新しいメンバーをメンバープールに追加してください\n• 既に参加済みのユーザーは表示されません\n• 認証済み（Firebase UID）のユーザーは表示されません',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            if (!_isLoading && _candidateMembers.isNotEmpty)
              DropdownButtonFormField<PurchaseGroupMember>(
                initialValue: _selectedMember,
                items: _candidateMembers.map((m) {
                  // 招待状態を確認
                  final isInvited = m.isInvited && !m.isInvitationAccepted;
                  final statusText = isInvited ? ' [招待中]' : '';
                  final textColor = isInvited ? Colors.orange : null;
                  
                  return DropdownMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${m.name}（${m.contact}）$statusText',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        if (isInvited)
                          const Icon(
                            Icons.mail_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  );
                }).toList(),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedMember == null ? null : _sendInvitation,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('招待を送信'),
                  ),
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