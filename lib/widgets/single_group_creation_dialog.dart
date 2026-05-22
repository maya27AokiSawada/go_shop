// lib/widgets/single_group_creation_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_list_provider.dart';
import '../providers/current_list_provider.dart';
import '../datastore/hybrid_shared_list_repository.dart';
import '../utils/app_logger.dart';
import '../screens/qr_scan_screen.dart';
import '../l10n/l10n.dart';

/// シングルモード用グループ作成ダイアログ
///
/// サインアップ完了後に表示される。
/// グループを1つ作成し、デフォルトリストを自動生成してカレントに設定する。
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

  Future<void> _scanQR() async {
    // ダイアログを閉じずにQRスキャナーを上に重ねて表示
    // （PopScope(canPop:false)によるブロックを回避するため先にpopしない）
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (!mounted) return;
    // スキャンでグループに参加できていたらダイアログを閉じる
    final groups = ref.read(allGroupsProvider).valueOrNull ?? [];
    if (groups.isNotEmpty) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final groupName = _groupNameController.text.trim();
      // UID・repositoryをawaitより前に取得（非同期中にウィジェットが破棄される可能性があるため）
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      final listRepo =
          ref.read(sharedListRepositoryProvider) as HybridSharedListRepository;

      // グループ作成（selectedGroupIdProvider も内部で更新される）
      // 注意: createNewGroup() 完了後に allGroupsProvider が更新され
      // SharedGroupPage が再ビルドされてダイアログのコンテキストが破棄される場合があるため、
      // 以降の ref.read() は mounted チェック不要な操作のみ行う。
      await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
      AppLogger.info('✅ [SINGLE DIALOG] グループ作成完了: $groupName');

      // createNewGroup() 側で選択済みIDが設定されるため、
      // ここでは allGroupsProvider を再読込せず selectedGroupId を利用する。
      // 注意: ref.read() はmount状態に依存しないため、ダイアログ破棄後も使用可能。
      final newGroupId = ref.read(selectedGroupIdProvider);
      if (newGroupId == null || newGroupId.isEmpty) {
        AppLogger.error('❌ [SINGLE DIALOG] 作成後のselectedGroupIdが取得できません');
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // デフォルトリストを自動作成（重複作成を防ぐ）
      // ダイアログが既に破棄済みでも ref.read() は有効なので処理を続行する
      if (uid != null) {
        final defaultListName = texts.defaultShoppingListName;
        final existingLists = await listRepo.getSharedListsByGroup(newGroupId);
        final existingDefault = existingLists
            .where((l) => l.listName == defaultListName)
            .firstOrNull;

        final targetList = existingDefault ??
            (existingLists.isNotEmpty
                ? existingLists.first
                : await listRepo.createSharedList(
                    ownerUid: uid,
                    groupId: newGroupId,
                    listName: defaultListName,
                    customListId: 'default_$newGroupId',
                  ));

        if (existingDefault != null) {
          AppLogger.info(
              'ℹ️ [SINGLE DIALOG] 既存デフォルトリストを再利用: ${existingDefault.listId}');
        } else if (existingLists.isNotEmpty) {
          AppLogger.info(
              'ℹ️ [SINGLE DIALOG] 既存リストがあるため作成をスキップ: ${targetList.listId}');
        } else {
          AppLogger.info(
              '✅ [SINGLE DIALOG] デフォルトリスト作成完了: ${targetList.listId}');
        }

        // カレントリストに設定（ref.read() はmount状態に依存しない）
        await ref
            .read(currentListProvider.notifier)
            .selectList(targetList, groupId: newGroupId);
        AppLogger.info('✅ [SINGLE DIALOG] カレントリスト設定完了');
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      AppLogger.error('❌ [SINGLE DIALOG] 作成エラー: $e');
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
    final mediaQuery = MediaQuery.of(context);

    return PopScope(
      canPop: false, // サインアップ後は必ずグループを作成させる
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('グループを作成'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: mediaQuery.size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Form(
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
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'または',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _scanQR,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('QRコードでグループに参加'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
