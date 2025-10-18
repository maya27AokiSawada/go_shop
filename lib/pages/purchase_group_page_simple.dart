import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_name_provider.dart';

class PurchaseGroupPageSimple extends ConsumerWidget {
  const PurchaseGroupPageSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    final allGroupsAsync = ref.watch(allGroupsProvider);

    print('🏷️ [SIMPLE PAGE] selectedGroupId: $selectedGroupId');
    print('🏷️ [SIMPLE PAGE] allGroupsAsync: $allGroupsAsync');

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ管理'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // グループ選択
            _buildGroupSelector(ref, allGroupsAsync, selectedGroupId),
            const SizedBox(height: 20),
            // グループ詳細
            Expanded(
              child: _buildGroupContent(ref, selectedGroupId),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('🔄 [SIMPLE FAB] 追加ボタンをタップしました');
          _showAddGroupDialog(context, ref);
        },
        backgroundColor: const Color(0xFF2E8B57),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupSelector(WidgetRef ref, AsyncValue<List<PurchaseGroup>> allGroupsAsync, String? selectedGroupId) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'グループ選択',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            allGroupsAsync.when(
              data: (groups) {
                print('📋 [SIMPLE SELECTOR] グループ数: ${groups.length}');
                
                if (groups.isEmpty) {
                  return const Text('グループがありません');
                }

                return DropdownButton<String>(
                  isExpanded: true,
                  value: selectedGroupId,
                  hint: const Text('グループを選択してください'),
                  items: groups.map((group) {
                    final displayName = group.groupId == 'defaultGroup' 
                        ? 'マイグループ' 
                        : group.groupName;
                    return DropdownMenuItem<String>(
                      value: group.groupId,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (newGroupId) {
                    print('📋 [SIMPLE SELECTOR] 選択: $newGroupId');
                    if (newGroupId != null) {
                      ref.read(selectedGroupIdProvider.notifier).selectGroup(newGroupId);
                    }
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('エラー: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupContent(WidgetRef ref, String? selectedGroupId) {
    if (selectedGroupId == null) {
      return const Card(
        child: Center(
          child: Text('グループを選択してください'),
        ),
      );
    }

    final purchaseGroupAsync = ref.watch(selectedGroupProvider);
    
    return purchaseGroupAsync.when(
      data: (group) {
        if (group == null) {
          print('📋 [SIMPLE CONTENT] グループデータがnullです');
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('グループデータがありません'),
            ),
          );
        }
        
        print('📋 [SIMPLE CONTENT] グループデータ: ${group.groupName}');
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.groupName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('メンバー数: ${group.members?.length ?? 0}'),
                const SizedBox(height: 10),
                if (group.members != null && group.members!.isNotEmpty) ...[
                  const Text(
                    'メンバー:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  ...group.members!.map((member) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text('• ${member.name}'),
                    ),
                  ),
                ] else
                  const Text('メンバーがいません'),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 10),
              Text('エラー: $error'),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('機能準備中'),
          content: const Text('グループ追加機能は現在準備中です。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}