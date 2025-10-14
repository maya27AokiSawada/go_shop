// lib/widgets/multi_group_invitation_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../services/enhanced_invitation_service.dart';
import 'dart:developer' as developer;

/// Dialog for selecting multiple groups to invite a user to
class MultiGroupInvitationDialog extends ConsumerStatefulWidget {
  final String targetEmail;
  final List<GroupInvitationOption> availableGroups;
  
  const MultiGroupInvitationDialog({
    super.key,
    required this.targetEmail,
    required this.availableGroups,
  });

  @override
  ConsumerState<MultiGroupInvitationDialog> createState() => _MultiGroupInvitationDialogState();
}

class _MultiGroupInvitationDialogState extends ConsumerState<MultiGroupInvitationDialog> {
  final Map<String, bool> _selectedGroups = {};
  final Map<String, PurchaseGroupRole> _selectedRoles = {};
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize selection state
    for (final option in widget.availableGroups) {
      if (option.canInvite) {
        _selectedGroups[option.group.groupId] = false;
        _selectedRoles[option.group.groupId] = PurchaseGroupRole.member; // Default role
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.group_add, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'グループ招待',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '招待先: ${widget.targetEmail}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Group selection list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '招待するグループを選択してください:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.availableGroups.length,
                      itemBuilder: (context, index) {
                        final option = widget.availableGroups[index];
                        return _buildGroupSelectionTile(option);
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Custom message
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'カスタムメッセージ (任意)',
                hintText: '招待に添えるメッセージを入力...',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canSendInvitation() && !_isLoading ? _sendInvitations : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('招待を送信 (${_getSelectedCount()}個)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSelectionTile(GroupInvitationOption option) {
    final group = option.group;
    final groupId = group.groupId;
    final isSelectable = option.canInvite;
    final isSelected = _selectedGroups[groupId] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        enabled: isSelectable,
        leading: Checkbox(
          value: isSelected,
          onChanged: isSelectable ? (value) {
            setState(() {
              _selectedGroups[groupId] = value ?? false;
            });
          } : null,
        ),
        title: Text(
          group.groupName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelectable ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('オーナー: ${group.ownerName ?? group.ownerEmail ?? 'Unknown'}'),
            Text('メンバー数: ${group.members?.length ?? 0}人'),
            if (!isSelectable && option.reason != null)
              Text(
                option.reason!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        trailing: isSelectable && isSelected
            ? DropdownButton<PurchaseGroupRole>(
                value: _selectedRoles[groupId],
                onChanged: (role) {
                  if (role != null) {
                    setState(() {
                      _selectedRoles[groupId] = role;
                    });
                  }
                },
                items: PurchaseGroupRole.values
                    .where((role) => role != PurchaseGroupRole.owner) // Don't allow owner role in invitations
                    .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(_getRoleDisplayName(role)),
                    ))
                    .toList(),
              )
            : null,
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
    }
  }

  bool _canSendInvitation() {
    return _selectedGroups.values.any((selected) => selected);
  }

  int _getSelectedCount() {
    return _selectedGroups.values.where((selected) => selected).length;
  }

  Future<void> _sendInvitations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final selectedGroups = <GroupInvitationData>[];
      
      for (final entry in _selectedGroups.entries) {
        if (entry.value) { // If selected
          final groupId = entry.key;
          final group = widget.availableGroups
              .firstWhere((option) => option.group.groupId == groupId)
              .group;
          
          selectedGroups.add(GroupInvitationData(
            groupId: groupId,
            groupName: group.groupName,
            targetRole: _selectedRoles[groupId] ?? PurchaseGroupRole.member,
          ));
        }
      }

      final invitationService = ref.read(enhancedInvitationServiceProvider);
      final result = await invitationService.sendInvitations(
        targetEmail: widget.targetEmail,
        selectedGroups: selectedGroups,
        customMessage: _messageController.text.trim().isEmpty 
            ? null 
            : _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(result);
        
        // Show result dialog
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('招待送信エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultDialog(InvitationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('招待結果'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('送信成功: ${result.totalSent}件'),
            Text('送信失敗: ${result.totalFailed}件'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('エラー詳細:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.map((error) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text('• $error', style: const TextStyle(fontSize: 12)),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Show multi-group invitation dialog
Future<InvitationResult?> showMultiGroupInvitationDialog({
  required BuildContext context,
  required String targetEmail,
  required List<GroupInvitationOption> availableGroups,
}) async {
  return await showDialog<InvitationResult>(
    context: context,
    builder: (context) => MultiGroupInvitationDialog(
      targetEmail: targetEmail,
      availableGroups: availableGroups,
    ),
  );
}