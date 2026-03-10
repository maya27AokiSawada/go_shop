// lib/pages/enhanced_invitation_test_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/enhanced_group_provider.dart';
import '../widgets/multi_group_invitation_dialog.dart';
import '../widgets/group_creation_with_copy_dialog.dart';
import '../services/enhanced_invitation_service.dart';
import '../providers/shared_group_provider.dart';

/// Test page for enhanced invitation system
class EnhancedInvitationTestPage extends ConsumerStatefulWidget {
  const EnhancedInvitationTestPage({super.key});

  @override
  ConsumerState<EnhancedInvitationTestPage> createState() =>
      _EnhancedInvitationTestPageState();
}

class _EnhancedInvitationTestPageState
    extends ConsumerState<EnhancedInvitationTestPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enhancedGroupState = ref.watch(enhancedGroupProvider);
    final allGroupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('拡張招待システムテスト'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚀 Enhanced Invitation System',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• オーナーUID名コレクション構造'),
                    Text('• AcceptedUids管理による招待受諾'),
                    Text('• 複数グループ選択UI'),
                    Text('• 役割ベース招待権限 (オーナー・管理者のみ)'),
                    Text('• 既存メンバーコピー機能'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Invitation test section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📧 招待テスト',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '招待するメールアドレス',
                        hintText: 'example@email.com',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: enhancedGroupState.isLoading
                                ? null
                                : _testInvitation,
                            icon: const Icon(Icons.send),
                            label: const Text('招待送信テスト'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testAcceptInvitation,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('招待受諾テスト'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Group management section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👥 グループ管理',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showGroupCreationDialog,
                            icon: const Icon(Icons.group_add),
                            label: const Text('メンバーコピー付きグループ作成'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                ref.read(allGroupsProvider.notifier).refresh(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('グループ一覧更新'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Group list
            Expanded(
              child: allGroupsAsync.when(
                data: (groups) => _buildGroupList(groups),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text('グループ取得エラー: $error'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(allGroupsProvider),
                        child: const Text('再試行'),
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

  Widget _buildGroupList(List groups) {
    if (groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, color: Colors.grey, size: 48),
            SizedBox(height: 8),
            Text('グループがありません'),
            Text('新しいグループを作成してください'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'グループ一覧 (${groups.length}個)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.group),
                  ),
                  title: Text(group.groupName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${group.groupId}'),
                      Text(
                          'オーナー: ${group.ownerName ?? group.ownerEmail ?? 'Unknown'}'),
                      Text('メンバー数: ${group.members?.length ?? 0}人'),
                      if (group.sharedListIds.isNotEmpty)
                        Text('リスト数: ${group.sharedListIds.length}個'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => _handleGroupAction(action, group),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'select',
                        child: ListTile(
                          leading: Icon(Icons.check_circle),
                          title: Text('選択'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'invite',
                        child: ListTile(
                          leading: Icon(Icons.person_add),
                          title: Text('招待'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('コピーして作成'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _testInvitation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('メールアドレスを入力してください', Colors.orange);
      return;
    }

    try {
      final enhancedGroupNotifier = ref.read(enhancedGroupProvider.notifier);
      final result = await enhancedGroupNotifier.sendEnhancedInvitation(email);

      if (result != null) {
        // Direct invitation completed
        _showInvitationResult(result);
      } else {
        // Multi-group selection needed
        final groupState = ref.read(enhancedGroupProvider).value;
        if (groupState?.availableInvitationGroups.isNotEmpty == true) {
          _showMultiGroupDialog(email, groupState!.availableInvitationGroups);
        }
      }
    } catch (e) {
      _showSnackBar('招待エラー: $e', Colors.red);
    }
  }

  Future<void> _testAcceptInvitation() async {
    // Simulate invitation acceptance
    try {
      final enhancedGroupNotifier = ref.read(enhancedGroupProvider.notifier);
      await enhancedGroupNotifier.acceptInvitation(
        ownerUid: 'test-owner-uid',
        groupId: 'test-group-id',
        userUid: 'test-user-uid',
        userName: 'テストユーザー',
      );

      _showSnackBar('招待受諾テスト完了', Colors.green);
    } catch (e) {
      _showSnackBar('招待受諾エラー: $e', Colors.red);
    }
  }

  Future<void> _showGroupCreationDialog() async {
    if (mounted) {
      final result = await showGroupCreationWithCopyDialog(
        context: context,
      );

      if (result == true) {
        // Group created successfully, refresh list
        ref.invalidate(allGroupsProvider);
      }
    }
  }

  Future<void> _showMultiGroupDialog(
      String email, List<GroupInvitationOption> options) async {
    final result = await showMultiGroupInvitationDialog(
      context: context,
      targetEmail: email,
      availableGroups: options,
    );

    if (result != null) {
      _showInvitationResult(result);
    }

    // Clear pending invitation state
    ref.read(enhancedGroupProvider.notifier).clearPendingInvitation();
  }

  void _showInvitationResult(InvitationResult result) {
    final message = result.success
        ? '招待送信完了: 成功 ${result.totalSent}件'
        : '招待送信: 成功 ${result.totalSent}件, 失敗 ${result.totalFailed}件';

    _showSnackBar(message, result.success ? Colors.green : Colors.orange);
  }

  void _handleGroupAction(String action, group) {
    switch (action) {
      case 'select':
        ref.read(selectedGroupIdProvider.notifier).selectGroup(group.groupId);
        _showSnackBar('グループ「${group.groupName}」を選択しました', Colors.blue);
        break;
      case 'invite':
        if (_emailController.text.trim().isNotEmpty) {
          _testInvitation();
        } else {
          _showSnackBar('招待するメールアドレスを入力してください', Colors.orange);
        }
        break;
      case 'copy':
        _showGroupCreationDialog();
        break;
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
