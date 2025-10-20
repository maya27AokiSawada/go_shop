import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../helpers/validation_service.dart';

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
  PurchaseGroupRole selectedRole = PurchaseGroupRole.member; // オーナー以外を初期値に設定
  
  // 重複確認用
  PurchaseGroupMember? duplicateMember;
  bool showDuplicateConfirmation = false;
  String? emailValidationError;
  String? nameValidationError;

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
      // メンバープールプロバイダーを使用
      final memberPoolNotifier = ref.read(memberPoolProvider.notifier);
      await memberPoolNotifier.syncPool(); // プールを最新に同期
      final members = await memberPoolNotifier.searchMembers('');
      setState(() {
        poolMembers = members;
        isLoadingPool = false;
        
        // 選択されているメンバーがすでにグループメンバーなら選択解除
        if (selectedPoolMember != null) {
          final currentGroup = ref.read(selectedGroupNotifierProvider).value;
          final isAlreadyMember = currentGroup?.members?.any(
            (groupMember) => groupMember.memberId == selectedPoolMember!.memberId || 
                           groupMember.contact == selectedPoolMember!.contact
          ) ?? false;
          
          if (isAlreadyMember) {
            selectedPoolMember = null;
          }
        }
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
          emailValidationError = null;
        });
      } else {
        setState(() {
          showDuplicateConfirmation = false;
          emailValidationError = null;
        });
      }
    } catch (e) {
      // エラーは無視して続行
    }
  }
  
  // メンバー名とメールアドレスのバリデーション
  void _validateMemberInputs() {
    if (selectedType != MemberSelectionType.newMember) return;
    
    final currentGroupAsync = ref.read(selectedGroupNotifierProvider);
    currentGroupAsync.whenData((currentGroup) {
      final existingMembers = currentGroup?.members ?? [];
      
      // 名前のバリデーション
      final nameValidation = ValidationService.validateMemberName(
        nameController.text, 
        existingMembers
      );
      
      // メールアドレスのバリデーション
      final emailValidation = ValidationService.validateMemberEmail(
        contactController.text, 
        existingMembers
      );
      
      setState(() {
        nameValidationError = nameValidation.hasError ? nameValidation.errorMessage : null;
        emailValidationError = emailValidation.hasError ? emailValidation.errorMessage : null;
        
        // 重複の場合は別途処理
        if (emailValidation.hasDuplicate) {
          duplicateMember = emailValidation.duplicateMember;
          showDuplicateConfirmation = true;
          emailValidationError = null;
        }
      });
    });
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
            Column(
              children: [
                Card(
                  color: selectedType == MemberSelectionType.fromPool ? Colors.blue.shade50 : null,
                  child: ListTile(
                    leading: Icon(
                      selectedType == MemberSelectionType.fromPool ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: selectedType == MemberSelectionType.fromPool ? Colors.blue : Colors.grey,
                    ),
                    title: const Text('プールから選択'),
                    onTap: () {
                      setState(() {
                        selectedType = MemberSelectionType.fromPool;
                        showDuplicateConfirmation = false;
                      });
                    },
                  ),
                ),
                Card(
                  color: selectedType == MemberSelectionType.newMember ? Colors.blue.shade50 : null,
                  child: ListTile(
                    leading: Icon(
                      selectedType == MemberSelectionType.newMember ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: selectedType == MemberSelectionType.newMember ? Colors.blue : Colors.grey,
                    ),
                    title: const Text('新規メンバー'),
                    onTap: () {
                      setState(() {
                        selectedType = MemberSelectionType.newMember;
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
          final isSelected = selectedPoolMember == member;
          
          // 現在のグループのメンバーかチェック
          final currentGroup = ref.watch(selectedGroupNotifierProvider).value;
          final isAlreadyMember = currentGroup?.members?.any(
            (groupMember) => groupMember.memberId == member.memberId || 
                           groupMember.contact == member.contact
          ) ?? false;
          
          return Card(
            color: isSelected ? Colors.blue.shade50 : 
                   isAlreadyMember ? Colors.grey.shade100 : null,
            child: ListTile(
              enabled: !isAlreadyMember,
              leading: Icon(
                isSelected ? Icons.radio_button_checked : 
                isAlreadyMember ? Icons.block : 
                Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : 
                       isAlreadyMember ? Colors.grey : 
                       Colors.grey,
              ),
              title: Text(
                member.name,
                style: TextStyle(
                  color: isAlreadyMember ? Colors.grey : null,
                ),
              ),
              subtitle: Text(
                isAlreadyMember 
                  ? '${member.contact} (${_getRoleDisplayName(member.role)}) - すでにメンバーです'
                  : '${member.contact} (${_getRoleDisplayName(member.role)})',
                style: TextStyle(
                  color: isAlreadyMember ? Colors.grey : null,
                ),
              ),
              onTap: isAlreadyMember ? null : () {
                setState(() {
                  selectedPoolMember = member;
                });
              },
            ),
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
          decoration: InputDecoration(
            labelText: '名前',
            border: const OutlineInputBorder(),
            errorText: nameValidationError,
          ),
          onChanged: (_) {
            _validateMemberInputs();
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: contactController,
          decoration: InputDecoration(
            labelText: 'メールアドレス',
            border: const OutlineInputBorder(),
            errorText: emailValidationError,
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            // メールアドレス変更時に重複チェック
            setState(() {
              showDuplicateConfirmation = false;
              emailValidationError = null;
            });
            _validateMemberInputs();
            _checkForDuplicate();
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<PurchaseGroupRole>(
          initialValue: selectedRole,
          decoration: const InputDecoration(
            labelText: '役割',
            border: OutlineInputBorder(),
            helperText: 'オーナーは作成者が自動的に設定されます',
          ),
          items: PurchaseGroupRole.values
            .where((role) => role != PurchaseGroupRole.owner) // オーナーロールを除外
            .map((role) {
            String roleName;
            switch (role) {
              case PurchaseGroupRole.owner:
                roleName = 'オーナー'; // この場合は表示されない
                break;
              case PurchaseGroupRole.manager:
                roleName = '管理者';
                break;
              case PurchaseGroupRole.member:
                roleName = 'メンバー';
                break;
              case PurchaseGroupRole.friend:
                roleName = 'フレンド';
                break;
            }
            return DropdownMenuItem(
              value: role,
              child: Text(roleName),
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
      if (selectedPoolMember == null) return false;
      
      // 現在のグループのメンバーかチェック
      final currentGroup = ref.read(selectedGroupNotifierProvider).value;
      final isAlreadyMember = currentGroup?.members?.any(
        (groupMember) => groupMember.memberId == selectedPoolMember!.memberId || 
                       groupMember.contact == selectedPoolMember!.contact
      ) ?? false;
      
      return !isAlreadyMember;
    } else {
      // 新規メンバーの場合：必要な情報が入力され、かつバリデーションエラーがない
      return nameController.text.isNotEmpty && 
             contactController.text.isNotEmpty &&
             nameValidationError == null &&
             emailValidationError == null;
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

  // ロール名を日本語で表示するヘルパーメソッド
  String _getRoleDisplayName(PurchaseGroupRole role) {
    switch (role) {
      case PurchaseGroupRole.owner:
        return 'オーナー';
      case PurchaseGroupRole.manager:
        return '管理者';
      case PurchaseGroupRole.member:
        return 'メンバー';
      case PurchaseGroupRole.friend:
        return 'フレンド';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    super.dispose();
  }
}