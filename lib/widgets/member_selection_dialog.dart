import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';

enum MemberSelectionType {
  fromPool,    // プールから選択
  newMember,   // 新規メンバー
}

class MemberSelectionDialog extends ConsumerStatefulWidget {
  const MemberSelectionDialog({super.key});

  @override
  ConsumerState<MemberSelectionDialog> createState() => _MemberSelectionDialogState();
}

class _MemberSelectionDialogState extends ConsumerState<MemberSelectionDialog> {
  MemberSelectionType selectedType = MemberSelectionType.fromPool;
  PurchaseGroupMember? selectedPoolMember;
  List<PurchaseGroupMember> poolMembers = [];
  bool isLoadingPool = false;
  
  // 新規メンバー用
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  PurchaseGroupRole selectedRole = PurchaseGroupRole.member;
  
  // 重複確認用
  PurchaseGroupMember? duplicateMember;
  bool showDuplicateConfirmation = false;

  @override
  void initState() {
    super.initState();
    _loadPoolMembers();
  }

  Future<void> _loadPoolMembers() async {
    setState(() {
      isLoadingPool = true;
    });
    
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      await repository.syncMemberPool(); // プールを最新に同期
      final members = await repository.searchMembersInPool('');
      setState(() {
        poolMembers = members;
        isLoadingPool = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPool = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メンバープールの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _checkForDuplicate() async {
    final email = contactController.text.trim();
    if (email.isEmpty) return;
    
    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final existing = await repository.findMemberByEmail(email);
      
      if (existing != null) {
        setState(() {
          duplicateMember = existing;
          showDuplicateConfirmation = true;
        });
      }
    } catch (e) {
      // エラーは無視して続行
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('メンバーを追加'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 選択タイプ
            Row(
              children: [
                Expanded(
                  child: RadioListTile<MemberSelectionType>(
                    title: const Text('プールから選択'),
                    value: MemberSelectionType.fromPool,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                        showDuplicateConfirmation = false;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<MemberSelectionType>(
                    title: const Text('新規メンバー'),
                    value: MemberSelectionType.newMember,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                        showDuplicateConfirmation = false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // プール選択画面
            if (selectedType == MemberSelectionType.fromPool) ...[
              _buildPoolSelection(),
            ],
            
            // 新規メンバー画面
            if (selectedType == MemberSelectionType.newMember) ...[
              _buildNewMemberForm(),
            ],
            
            // 重複確認ダイアログ
            if (showDuplicateConfirmation) ...[
              _buildDuplicateConfirmation(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _canConfirm() ? _confirmSelection : null,
          child: const Text('追加'),
        ),
      ],
    );
  }

  Widget _buildPoolSelection() {
    if (isLoadingPool) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (poolMembers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('プールにメンバーがいません'),
      );
    }
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: poolMembers.length,
        itemBuilder: (context, index) {
          final member = poolMembers[index];
          return RadioListTile<PurchaseGroupMember>(
            title: Text(member.name),
            subtitle: Text('${member.contact} (${member.role.name})'),
            value: member,
            groupValue: selectedPoolMember,
            onChanged: (value) {
              setState(() {
                selectedPoolMember = value;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildNewMemberForm() {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '名前',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: contactController,
          decoration: const InputDecoration(
            labelText: 'メールアドレス',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            // メールアドレス変更時に重複チェック
            setState(() {
              showDuplicateConfirmation = false;
            });
            _checkForDuplicate();
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<PurchaseGroupRole>(
          value: selectedRole,
          decoration: const InputDecoration(
            labelText: '役割',
            border: OutlineInputBorder(),
          ),
          items: PurchaseGroupRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role == PurchaseGroupRole.owner ? 'オーナー' : 'メンバー'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedRole = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDuplicateConfirmation() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${duplicateMember?.name}さんのことですか？',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text('メールアドレス: ${duplicateMember?.contact}'),
          Text('役割: ${duplicateMember?.role.name}'),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  // 既存メンバーを使用
                  setState(() {
                    selectedPoolMember = duplicateMember;
                    selectedType = MemberSelectionType.fromPool;
                    showDuplicateConfirmation = false;
                  });
                },
                child: const Text('はい'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    showDuplicateConfirmation = false;
                  });
                },
                child: const Text('いいえ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canConfirm() {
    if (selectedType == MemberSelectionType.fromPool) {
      return selectedPoolMember != null;
    } else {
      return nameController.text.isNotEmpty && contactController.text.isNotEmpty;
    }
  }

  void _confirmSelection() {
    PurchaseGroupMember memberToAdd;
    
    if (selectedType == MemberSelectionType.fromPool) {
      // プールからの選択：新しいIDで追加
      memberToAdd = selectedPoolMember!.copyWith(
        memberId: 'member_${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      // 新規メンバー
      memberToAdd = PurchaseGroupMember.create(
        name: nameController.text,
        contact: contactController.text,
        role: selectedRole,
        isSignedIn: false,
      );
    }
    
    Navigator.of(context).pop(memberToAdd);
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    super.dispose();
  }
}