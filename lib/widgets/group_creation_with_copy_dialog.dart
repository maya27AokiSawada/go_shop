// lib/widgets/group_creation_with_copy_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_group.dart';
import '../providers/purchase_group_provider.dart';
import '../utils/app_logger.dart';
import 'dart:developer' as developer;

/// Dialog for creating new group with option to copy members from existing group
class GroupCreationWithCopyDialog extends ConsumerStatefulWidget {
  const GroupCreationWithCopyDialog({
    super.key,
  });

  @override
  ConsumerState<GroupCreationWithCopyDialog> createState() =>
      _GroupCreationWithCopyDialogState();
}

class _GroupCreationWithCopyDialogState
    extends ConsumerState<GroupCreationWithCopyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();

  SharedGroup? _selectedSourceGroup;
  final Map<String, bool> _selectedMembers = {};
  final Map<String, SharedGroupRole> _memberRoles = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('🔄 [GROUP_CREATION_WITH_COPY_DIALOG] build() 開始');

    // allGroupsProviderから既存グループを取得
    final allGroupsAsync = ref.watch(allGroupsProvider);

    return allGroupsAsync.when(
      data: (existingGroups) => _buildDialog(context, existingGroups),
      loading: () => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('エラー: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(BuildContext context, List<SharedGroup> existingGroups) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Stack(
          children: [
            // メインコンテンツ
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
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
                          final isDuplicate = existingGroups.any((group) =>
                              group.groupName.toLowerCase() ==
                              trimmedName.toLowerCase());

                          if (isDuplicate) {
                            return 'このグループ名は既に使用されています';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Source group selection
                      if (existingGroups.isNotEmpty) ...[
                        const Text(
                          'メンバーをコピーする既存グループ (任意):',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<SharedGroup>(
                          initialValue: _selectedSourceGroup,
                          decoration: const InputDecoration(
                            hintText: 'グループを選択...',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<SharedGroup>(
                              value: null,
                              child: Text('新しいグループ (メンバーなし)'),
                            ),
                            ...existingGroups.map(
                              (group) => DropdownMenuItem<SharedGroup>(
                                value: group,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(group.groupName),
                                    Text(
                                      'メンバー数: ${group.members?.length ?? 0}人',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
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
                      if (_selectedSourceGroup?.members?.isNotEmpty ==
                          true) ...[
                        const Text(
                          'コピーするメンバーとその役割を選択:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount:
                                  _selectedSourceGroup!.members?.length ?? 0,
                              itemBuilder: (context, index) {
                                final member =
                                    _selectedSourceGroup!.members![index];
                                return _buildMemberSelectionTile(member);
                              },
                            ),
                          ),
                        ),
                      ] else if (_selectedSourceGroup != null) ...[
                        Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: const Text(
                            '選択されたグループにはメンバーがいません',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ] else ...[
                        Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: const Text(
                            '既存グループを選択するとメンバーをコピーできます',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('キャンセル'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _createGroup,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('グループを作成'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ローディングオーバーレイ
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'グループを作成中...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelectionTile(SharedGroupMember member) {
    final memberId = member.memberId;
    final isSelected = _selectedMembers[memberId] ?? false;

    // Don't show owner in the copy list (they can't be copied with owner role)
    if (member.role == SharedGroupRole.owner) {
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
            ? DropdownButton<SharedGroupRole>(
                value: _memberRoles[memberId],
                onChanged: (role) {
                  if (role != null) {
                    setState(() {
                      _memberRoles[memberId] = role;
                    });
                  }
                },
                items: SharedGroupRole.values
                    .where((role) =>
                        role != SharedGroupRole.owner) // Don't allow owner role
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

  void _updateMemberSelection() {
    _selectedMembers.clear();
    _memberRoles.clear();

    final members = _selectedSourceGroup!.members;
    if (members != null) {
      for (final member in members) {
        if (member.role != SharedGroupRole.owner) {
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

    AppLogger.info('🔄 [CREATE GROUP DIALOG] グループ作成開始');
    setState(() {
      _isLoading = true;
      AppLogger.info('✅ [CREATE GROUP DIALOG] _isLoading = true に設定');
    });

    final groupName = _groupNameController.text.trim();
    final hasMembersToAdd = _selectedMembers.values.any((selected) => selected);

    try {
      // 🔥 同じ名前のグループが既に存在しないかチェック
      final allGroupsAsync = ref.read(allGroupsProvider);
      final allGroups = allGroupsAsync.when(
        data: (groups) => groups,
        loading: () => <SharedGroup>[],
        error: (_, __) => <SharedGroup>[],
      );

      final duplicateName =
          allGroups.any((group) => group.groupName == groupName);
      if (duplicateName) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「$groupName」という名前のグループは既に存在します'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      AppLogger.info('🔄 [CREATE GROUP DIALOG] createNewGroup() 呼び出し');
      // Create new group
      await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
      AppLogger.info('✅ [CREATE GROUP DIALOG] createNewGroup() 完了');

      // Add members BEFORE closing dialog (if needed)
      if (hasMembersToAdd) {
        AppLogger.info('🔄 [CREATE GROUP DIALOG] メンバー追加開始');
        final currentGroup = ref.read(selectedGroupNotifierProvider).value;
        if (currentGroup != null) {
          await _addSelectedMembers(currentGroup);
          AppLogger.info('✅ [CREATE GROUP DIALOG] メンバー追加完了');
        } else {
          AppLogger.warning(
              '⚠️ [CREATE GROUP DIALOG] currentGroupがnull - メンバー追加をスキップ');
        }
      }

      // ✅ グループ作成処理完了
      AppLogger.info(
          '✅ [CREATE GROUP DIALOG] グループ作成処理完了: ${AppLogger.maskName(groupName)}');
      AppLogger.info('🔍 [CREATE GROUP DIALOG] mounted状態: $mounted');

      // ローディング解除 - ユーザーに完了を視覚的に示す
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppLogger.info('✅ [CREATE GROUP DIALOG] ローディング解除完了');
      }

      // 🆕 Firestoreの非同期処理が完全に完了するまで十分な時間待機
      // Windowsプラグインのスレッド問題を回避するため、長めの遅延を設定
      AppLogger.info('⏳ [CREATE GROUP DIALOG] Firestore処理の完全な完了を待機中...');
      await Future.delayed(const Duration(milliseconds: 1500));
      AppLogger.info('✅ [CREATE GROUP DIALOG] 待機完了');

      if (mounted) {
        AppLogger.info('🔄 [CREATE GROUP DIALOG] Navigator.pop(true)を呼び出します');
        try {
          Navigator.of(context).pop(true);
          AppLogger.info('✅ [CREATE GROUP DIALOG] Navigator.pop()完了');
        } catch (e, stackTrace) {
          AppLogger.error('❌ [CREATE GROUP DIALOG] Navigator.pop()でエラー: $e');
          AppLogger.error('❌ [CREATE GROUP DIALOG] スタックトレース: $stackTrace');
        }
      } else {
        AppLogger.warning('⚠️ [CREATE GROUP DIALOG] mounted=false, popをスキップ');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [CREATE GROUP DIALOG] グループ作成エラー: $e');
      AppLogger.error('❌ [CREATE GROUP DIALOG] スタックトレース: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // エラー時はfalseを返す（Snackbarは呼び出し元で表示）
        Navigator.of(context).pop(false);
      }
    }
  }

  Future<void> _addSelectedMembers(SharedGroup newGroup) async {
    try {
      if (_selectedSourceGroup?.members == null) {
        AppLogger.info('⚠️ [ADD MEMBERS] ソースグループにメンバーがいません');
        return;
      }

      final selectedGroupNotifier =
          ref.read(selectedGroupNotifierProvider.notifier);

      final members = _selectedSourceGroup!.members;
      if (members != null) {
        for (final member in members) {
          final memberId = member.memberId;
          final isSelected = _selectedMembers[memberId] ?? false;

          if (isSelected && member.role != SharedGroupRole.owner) {
            final newRole = _memberRoles[memberId] ?? member.role;

            final newMember = SharedGroupMember.create(
              memberId: member.memberId,
              name: member.name,
              contact: member.contact,
              role: newRole,
            );

            try {
              await selectedGroupNotifier.addMember(newMember);
              developer.log(
                  '✅ メンバー追加成功: ${member.name} (役割: ${_getRoleDisplayName(newRole)})');
            } catch (e) {
              developer.log('❌ メンバー追加エラー: ${member.name} - $e');
              // 個別のメンバー追加失敗は続行（他のメンバーは追加）
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [ADD MEMBERS] メンバー追加処理でエラー発生: $e');
      AppLogger.error('❌ [ADD MEMBERS] スタックトレース: $stackTrace');
      rethrow; // 呼び出し元にエラーを伝播
    }
  }
}

/// Show group creation with copy dialog
Future<bool?> showGroupCreationWithCopyDialog({
  required BuildContext context,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => const GroupCreationWithCopyDialog(),
  );
}
