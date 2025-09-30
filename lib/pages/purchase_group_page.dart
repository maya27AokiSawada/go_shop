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
  @override
  Widget build(BuildContext context) {
    final purchaseGroupAsync = ref.watch(purchaseGroupProvider);
    final authState = ref.watch(authStateProvider);

    return purchaseGroupAsync.when(
      data: (purchaseGroup) {
        return Scaffold(
          appBar: AppBar(title: const Text('グループ管理')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: (purchaseGroup.members?.isEmpty ?? true)
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_add, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'メンバーがいません\n新しいメンバーを追加してください',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: purchaseGroup.members!.length,
                          itemBuilder: (context, index) {
                            final member = purchaseGroup.members![index];
                            return MemberListTile(
                              member: member,
                              onTap: () async {
                                final editedMember = await showDialog<PurchaseGroupMember>(
                                  context: context,
                                  builder: (context) => const AlertDialog(
                                    content: PurchaseGroupMemberForm(),
                                  ),
                                );
                                if (editedMember != null) {
                                  final updatedMembers = List<PurchaseGroupMember>.from(purchaseGroup.members ?? []);
                                  updatedMembers[index] 
                                    = editedMember.copyWith(memberId: member.memberId);
                                  await ref.read(purchaseGroupProvider.notifier).updateMembers(updatedMembers);
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
                        const SnackBar(content: Text('サインインしないと買い物リスト共有は出来ません')),
                      );
                      return;
                    }
                    // 保存処理（現在のグループを保存）
                    try {
                      await ref.read(purchaseGroupProvider.notifier).updateGroup(purchaseGroup);
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('保存しました')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('保存に失敗しました: $e')),
                        );
                      }
                    }
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
