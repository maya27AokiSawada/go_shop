import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/security_provider.dart';
import '../widgets/group_list_widget.dart';
import '../widgets/group_creation_with_copy_dialog.dart';
import '../widgets/accept_invitation_widget.dart';

class SharedGroupPage extends ConsumerStatefulWidget {
  const SharedGroupPage({super.key});

  @override
  ConsumerState<SharedGroupPage> createState() => _SharedGroupPageState();
}

class _SharedGroupPageState extends ConsumerState<SharedGroupPage> {
  @override
  Widget build(BuildContext context) {
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

    Log.info('🏷️ [PAGE BUILD] SharedGroupPage表示開始');

    return Scaffold(
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: GroupListWidget(),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QRScannerScreen()));
            },
            heroTag: 'scan_qr_code',
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () => _showCreateGroupDialog(context),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.group_add),
            label: const Text('新しいグループ'),
            heroTag: 'create_group',
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    // 🔥 同期完了を待機（同期中作成による赤画面エラーを防止）
    try {
      await ref.read(allGroupsProvider.future);
      AppLogger.info('✅ [GROUP_CREATION] allGroupsProvider同期完了 - ダイアログ表示');
    } catch (e) {
      AppLogger.error('❌ [GROUP_CREATION] allGroupsProvider読み込みエラー: $e');
      // エラーでもダイアログ表示は継続（Hiveフォールバック）
    }

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
                    .read(SharedGroupRepositoryProvider)
                    .deleteGroup(groupId);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('グループを削除しました')),
                );

                // 🔥 修正: SnackBar表示後にinvalidate
                ref.invalidate(allGroupsProvider);
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

  void _showCleanupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データベースクリーンアップ'),
        content: const Text(
          '削除済みのグループデータを物理的に削除します。\n'
          'この操作はデータベースを最適化し、ストレージ容量を解放します。\n\n'
          '実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              try {
                final repository = ref.read(SharedGroupRepositoryProvider);
                final deletedCount = await repository.cleanupDeletedGroups();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$deletedCount件の削除済みデータをクリーンアップしました'),
                    backgroundColor: Colors.green,
                  ),
                );

                // 🔥 修正: SnackBar表示後にinvalidate（グループリストを更新）
                ref.invalidate(allGroupsProvider);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('クリーンアップに失敗しました: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('実行', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
