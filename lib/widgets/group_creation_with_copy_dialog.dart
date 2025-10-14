// lib/widgets/group_creation_with_copy_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import 'dart:developer' as developer;

/// Dialog for creating new group with option to copy members from existing group
class GroupCreationWithCopyDialog extends ConsumerStatefulWidget {
  final List<PurchaseGroup> existingGroups;
  
  const GroupCreationWithCopyDialog({
    super.key,
    required this.existingGroups,
  });

  @override
  ConsumerState<GroupCreationWithCopyDialog> createState() => _GroupCreationWithCopyDialogState();
}

class _GroupCreationWithCopyDialogState extends ConsumerState<GroupCreationWithCopyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  
  PurchaseGroup? _selectedSourceGroup;
  final Map<String, bool> _selectedMembers = {};
  final Map<String, PurchaseGroupRole> _memberRoles = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.group_add, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '新しいグループを作成',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Group name input
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'グループ名 *',
                  hintText: 'グループ名を入力してください',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'グループ名を入力してください';
                  }
                  
                  // Check for duplicate group names
                  final trimmedName = value.trim();
                  final isDuplicate = widget.existingGroups.any((group) => 
                    group.groupName.toLowerCase() == trimmedName.toLowerCase());
                  
                  if (isDuplicate) {
                    return 'このグループ名は既に使用されています';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Source group selection
              if (widget.existingGroups.isNotEmpty) ...[
                const Text(
                  'メンバーをコピーする既存グループ (任意):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                
                DropdownButtonFormField<PurchaseGroup>(
                  value: _selectedSourceGroup,
                  decoration: const InputDecoration(
                    hintText: 'グループを選択...',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<PurchaseGroup>(
                      value: null,
                      child: Text('新しいグループ (メンバーなし)'),
                    ),
                    ...widget.existingGroups.map((group) => 
                      DropdownMenuItem<PurchaseGroup>(
                        value: group,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.groupName),
                            Text(
                              'メンバー数: ${group.members?.length ?? 0}人',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (group) {
                    setState(() {
                      _selectedSourceGroup = group;
                      _updateMemberSelection();
                    });
                  },
                ),
                
                const SizedBox(height: 16),
              ],
              
              // Member selection list
              if (_selectedSourceGroup?.members?.isNotEmpty == true) ...[
                const Text(
                  'コピーするメンバーとその役割を選択:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedSourceGroup!.members!.length,
                    itemBuilder: (context, index) {
                      final member = _selectedSourceGroup!.members![index];
                      return _buildMemberSelectionTile(member);
                    },
                  ),
                ),
              ] else if (_selectedSourceGroup != null) ...[
                const Expanded(
                  child: Center(
                    child: Text(
                      '選択されたグループにはメンバーがいません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Text(
                      '既存グループを選択するとメンバーをコピーできます',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
              
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
                    onPressed: _isLoading ? null : _createGroup,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('グループを作成'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberSelectionTile(PurchaseGroupMember member) {
    final memberId = member.memberId;
    final isSelected = _selectedMembers[memberId] ?? false;
    
    // Don't show owner in the copy list (they can't be copied with owner role)
    if (member.role == PurchaseGroupRole.owner) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              _selectedMembers[memberId] = value ?? false;
              if (value == true) {
                // Set default role (preserve original role but can be changed)
                _memberRoles[memberId] = member.role;
              }
            });
          },
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.contact),
            Text(
              '現在の役割: ${_getRoleDisplayName(member.role)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: isSelected
            ? DropdownButton<PurchaseGroupRole>(
                value: _memberRoles[memberId],
                onChanged: (role) {
                  if (role != null) {
                    setState(() {
                      _memberRoles[memberId] = role;
                    });
                  }
                },
                items: PurchaseGroupRole.values
                    .where((role) => role != PurchaseGroupRole.owner) // Don't allow owner role
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

  void _updateMemberSelection() {
    _selectedMembers.clear();
    _memberRoles.clear();
    
    if (_selectedSourceGroup?.members != null) {
      for (final member in _selectedSourceGroup!.members!) {
        if (member.role != PurchaseGroupRole.owner) {
          // Auto-select non-owner members by default
          _selectedMembers[member.memberId] = true;
          _memberRoles[member.memberId] = member.role;
        }
      }
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groupName = _groupNameController.text.trim();
      
      // Create new group
      final purchaseGroupNotifier = ref.read(purchaseGroupProvider.notifier);
      await purchaseGroupNotifier.createNewGroup(groupName);
      
      // If members were selected, add them to the new group
      if (_selectedMembers.values.any((selected) => selected)) {
        final currentGroup = ref.read(purchaseGroupProvider).value;
        if (currentGroup != null) {
          await _addSelectedMembers(currentGroup);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('グループ「$groupName」を作成しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('❌ グループ作成エラー: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('グループ作成エラー: $e'),
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

  Future<void> _addSelectedMembers(PurchaseGroup newGroup) async {
    if (_selectedSourceGroup?.members == null) return;

    final purchaseGroupNotifier = ref.read(purchaseGroupProvider.notifier);

    for (final member in _selectedSourceGroup!.members!) {
      final memberId = member.memberId;
      final isSelected = _selectedMembers[memberId] ?? false;
      
      if (isSelected && member.role != PurchaseGroupRole.owner) {
        final newRole = _memberRoles[memberId] ?? member.role;
        
        final newMember = PurchaseGroupMember.create(
          name: member.name,
          contact: member.contact,
          role: newRole,
          isSignedIn: member.isSignedIn,
          isInvited: member.isInvited,
          isInvitationAccepted: member.isInvitationAccepted,
          invitedAt: member.invitedAt,
          acceptedAt: member.acceptedAt,
        );
        
        try {
          await purchaseGroupNotifier.addMember(newMember);
          developer.log('✅ メンバー追加成功: ${member.name} (役割: ${_getRoleDisplayName(newRole)})');
        } catch (e) {
          developer.log('❌ メンバー追加エラー: ${member.name} - $e');
        }
      }
    }
  }
}

/// Show group creation with copy dialog
Future<bool?> showGroupCreationWithCopyDialog({
  required BuildContext context,
  required List<PurchaseGroup> existingGroups,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => GroupCreationWithCopyDialog(
      existingGroups: existingGroups,
    ),
  );
}