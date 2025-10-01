// lib/pages/purchase_group_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/new_member_input_form.dart';
import '../widgets/member_list_tile_widget.dart';
import '../services/invitation_service.dart';

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
                const SizedBox(height: 16),
                
                // 🎯 招待機能ボタンを追加
                ElevatedButton.icon(
                  onPressed: () async {
                    final user = authState.asData?.value;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('サインインが必要です')),
                      );
                      return;
                    }
                    await _showInviteDialog(context, purchaseGroup);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('メンバーを招待'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
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

  /// 招待ダイアログを表示
  Future<void> _showInviteDialog(BuildContext context, PurchaseGroup group) async {
    final emailController = TextEditingController();
    PurchaseGroupRole selectedRole = PurchaseGroupRole.child;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('メンバーを招待'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      border: OutlineInputBorder(),
                      hintText: 'example@email.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PurchaseGroupRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: '権限',
                      border: OutlineInputBorder(),
                    ),
                    items: PurchaseGroupRole.values.map((role) {
                      String displayName;
                      switch (role) {
                        case PurchaseGroupRole.leader:
                          displayName = 'リーダー';
                          break;
                        case PurchaseGroupRole.parent:
                          displayName = '親';
                          break;
                        case PurchaseGroupRole.child:
                          displayName = '子';
                          break;
                      }
                      return DropdownMenuItem(
                        value: role,
                        child: Text(displayName),
                      );
                    }).toList(),
                    onChanged: (role) {
                      setState(() {
                        selectedRole = role!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.isNotEmpty) {
                      try {
                        final invitationService = InvitationService();
                        final inviteLink = await invitationService.inviteUserToGroup(
                          groupId: group.groupId,
                          inviteeEmail: emailController.text,
                          role: selectedRole,
                        );
                        
                        Navigator.of(context).pop();
                        
                        // 招待リンクを表示
                        _showInviteLinkDialog(context, inviteLink);
                        
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('招待に失敗しました: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('招待する'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 招待リンクを表示するダイアログ
  void _showInviteLinkDialog(BuildContext context, String inviteLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('招待リンクが生成されました'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('以下のリンクを相手に送信してください：'),
            const SizedBox(height: 8),
            SelectableText(
              inviteLink,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
