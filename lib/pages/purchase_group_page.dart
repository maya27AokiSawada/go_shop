// lib/pages/purchase_group_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/new_member_input_form.dart';
import '../widgets/member_list_tile_widget.dart';

class PurchaseGroupPage extends ConsumerStatefulWidget {
  const PurchaseGroupPage({super.key});

  @override
  ConsumerState<PurchaseGroupPage> createState() => _PurchaseGroupPageState();
}

class _PurchaseGroupPageState extends ConsumerState<PurchaseGroupPage> {
  late TextEditingController groupNameController;
  late TextEditingController listNameController;

  @override
  void dispose() {
    groupNameController.dispose();
    listNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseGroupAsync = ref.watch(purchaseGroupProvider);
    final authState = ref.watch(authStateProvider);

    return purchaseGroupAsync.when(
      data: (purchaseGroup) {
        groupNameController = TextEditingController(text: purchaseGroup.groupName);
        listNameController = TextEditingController(text: purchaseGroup.groupID);

        return Scaffold(
          appBar: AppBar(title: const Text('グループ管理')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // グループ名編集
                TextFormField(
                  controller: groupNameController,
                  decoration: const InputDecoration(labelText: 'グループ名'),
                ),
                const SizedBox(height: 8),
                // リスト名編集
                TextFormField(
                  controller: listNameController,
                  decoration: const InputDecoration(labelText: 'リスト名'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('メンバー一覧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () async {
                        final newMember = await showDialog<PurchaseGroupMember>(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: PurchaseGroupMemberForm(),
                          ),
                        );
                        if (newMember != null) {
                          await ref.read(purchaseGroupProvider.notifier).addMember(newMember);
                        }
                      },
                      child: const Text('メンバー追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: purchaseGroup.members.length,
                    itemBuilder: (context, index) {
                      final member = purchaseGroup.members[index];
                      return MemberListTile(
                        member: member,
                        onTap: () async {
                          final editedMember = await showDialog<PurchaseGroupMember>(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: PurchaseGroupMemberForm(),
                            ),
                          );
                          if (editedMember != null) {
                            final updatedMembers = List<PurchaseGroupMember>.from(purchaseGroup.members);
                            updatedMembers[index] 
                              = editedMember.copyWith(memberID: member.memberID);
                            ref.read(purchaseGroupProvider.notifier).updateMembers(updatedMembers);
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    // ログインチェック
                    final user = authState.asData?.value;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ログインしてください')),
                      );
                      return;
                    }
                    // 保存処理
                    final updatedGroup = purchaseGroup.copyWith(
                      groupName: groupNameController.text,
                      groupID: listNameController.text,
                    );
                    // 必要ならProviderのsaveメソッドを呼ぶ
                    await ref.read(purchaseGroupProvider.notifier).updateMembers(updatedGroup.members);
                    await ref.read(purchaseGroupProvider.notifier).state = AsyncValue.data(updatedGroup);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('保存しました')),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('エラーが発生しました: $e')),
      ),
    );
  }
}
