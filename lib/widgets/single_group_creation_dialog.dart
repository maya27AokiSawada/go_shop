// lib/widgets/single_group_creation_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_list_provider.dart';
import '../providers/current_list_provider.dart';
import '../datastore/hybrid_shared_list_repository.dart';
import '../utils/app_logger.dart';

/// シングルモード用グループ作成ダイアログ
///
/// サインアップ完了後に表示される。
/// グループを1つ作成し、デフォルトリスト「買い物リスト」を自動生成してカレントに設定する。
class SingleGroupCreationDialog extends ConsumerStatefulWidget {
  const SingleGroupCreationDialog({super.key});

  @override
  ConsumerState<SingleGroupCreationDialog> createState() =>
      _SingleGroupCreationDialogState();
}

class _SingleGroupCreationDialogState
    extends ConsumerState<SingleGroupCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final groupName = _groupNameController.text.trim();

      // グループ作成（selectedGroupIdProvider も内部で更新される）
      await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
      Log.info('✅ [SINGLE DIALOG] グループ作成完了: $groupName');

      // 作成したグループIDを取得
      final allGroups = await ref.read(allGroupsProvider.future);
      final newGroup = allGroups
          .where((g) => g.groupName == groupName)
          .fold<dynamic>(null, (prev, g) => prev ?? g);

      if (newGroup == null) {
        Log.error('❌ [SINGLE DIALOG] グループが見つかりません');
        return;
      }

      // デフォルトリスト「買い物リスト」を自動作成
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid != null) {
        final listRepo = ref.read(sharedListRepositoryProvider)
            as HybridSharedListRepository;
        final newList = await listRepo.createSharedList(
          ownerUid: uid,
          groupId: newGroup.groupId,
          listName: '買い物リスト',
        );
        Log.info('✅ [SINGLE DIALOG] デフォルトリスト作成完了: ${newList.listId}');

        // カレントリストに設定
        await ref
            .read(currentListProvider.notifier)
            .selectList(newList, groupId: newGroup.groupId);
        Log.info('✅ [SINGLE DIALOG] カレントリスト設定完了');
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      Log.error('❌ [SINGLE DIALOG] 作成エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('グループ作成に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // サインアップ後は必ずグループを作成させる
      child: AlertDialog(
        title: const Text('グループを作成'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'まず最初にグループ名を入力してください。\n買い物リストはグループ内で管理されます。',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _groupNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'グループ名',
                  hintText: '例：家族の買い物',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _create(),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'グループ名を入力してください';
                  if (v.length > 50) return '50文字以内で入力してください';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: _isLoading ? null : _create,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('作成'),
          ),
        ],
      ),
    );
  }
}
