import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/security_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/group_list_widget.dart';
import '../widgets/group_creation_with_copy_dialog.dart';

class PurchaseGroupPage extends ConsumerStatefulWidget {
  const PurchaseGroupPage({super.key});

  @override
  ConsumerState<PurchaseGroupPage> createState() => _PurchaseGroupPageState();
}

class _PurchaseGroupPageState extends ConsumerState<PurchaseGroupPage> {
  @override
  Widget build(BuildContext context) {
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    // セキュリティチェック
    final canViewData = ref.watch(dataVisibilityProvider);
    final authRequired = ref.watch(authRequiredProvider);

    if (!canViewData && authRequired) {
      return Scaffold(
        appBar: AppBar(title: const Text('グループ管理')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'シークレットモードが有効です',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'グループデータを表示するにはログインが必要です',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    Log.info('🏷️ [PAGE BUILD] PurchaseGroupPage表示開始');

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 設定メニュー
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              switch (value) {
                case 'delete_group':
                  // グループが選択されており、ユーザーのデフォルトグループ(uid==groupId)でない場合のみ削除可能
                  if (selectedGroupId != null) {
                    final currentUser = ref.read(authProvider).currentUser;
                    final isDefaultGroup = currentUser != null &&
                        selectedGroupId == currentUser.uid;
                    if (!isDefaultGroup) {
                      _showDeleteGroupDialog(context, selectedGroupId);
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              final currentUser = ref.read(authProvider).currentUser;
              final isDefaultGroup =
                  currentUser != null && selectedGroupId == currentUser.uid;
              return [
                if (!isDefaultGroup)
                  const PopupMenuItem(
                    value: 'delete_group',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('グループを削除'),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: GroupListWidget(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add),
        label: const Text('新しいグループ'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    // ダイアログ内で直接allGroupsProviderを参照するため、
    // ここでは何も取得せずにダイアログを表示
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const GroupCreationWithCopyDialog(),
    );

    // ダイアログが閉じられた後、結果に応じてSnackbarを表示
    if (!mounted) return;

    if (result == true) {
      // 成功
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('グループを作成しました'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (result == false) {
      // エラー
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('グループ作成に失敗しました'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
    // result == null の場合はキャンセルなので何もしない
  }

  void _showDeleteGroupDialog(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを削除'),
        content: const Text('このグループを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref
                    .read(purchaseGroupRepositoryProvider)
                    .deleteGroup(groupId);
                ref.invalidate(allGroupsProvider);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('グループを削除しました')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('削除に失敗しました: $e')),
                );
              }
            },
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
