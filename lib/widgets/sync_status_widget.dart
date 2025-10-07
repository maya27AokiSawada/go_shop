import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_group_provider.dart';

/// 同期状態を表示するウィジェット
/// AppBarやDrawerで使用して、ユーザーに現在の同期状態を伝える
class SyncStatusWidget extends ConsumerWidget {
  final bool showLabel;
  
  const SyncStatusWidget({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIcon(syncStatus),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            _getStatusText(syncStatus),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getStatusColor(syncStatus),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.localOnly:
        return Icon(
          Icons.storage,
          size: 16,
          color: Colors.grey[600],
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          size: 16,
          color: Colors.orange[700],
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        );
      case SyncStatus.synced:
        return Icon(
          Icons.cloud_done,
          size: 16,
          color: Colors.green[600],
        );
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.localOnly:
        return 'ローカル';
      case SyncStatus.offline:
        return 'オフライン';
      case SyncStatus.syncing:
        return '同期中';
      case SyncStatus.synced:
        return '同期済み';
    }
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.localOnly:
        return Colors.grey[600]!;
      case SyncStatus.offline:
        return Colors.orange[700]!;
      case SyncStatus.syncing:
        return Colors.blue[600]!;
      case SyncStatus.synced:
        return Colors.green[600]!;
    }
  }
}

/// 同期管理ボタンウィジェット
/// デバッグ用や設定画面で使用
class SyncManagementWidget extends ConsumerWidget {
  const SyncManagementWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final forceSyncAsync = ref.watch(forceSyncProvider);
    final hybridRepo = ref.read(hybridRepositoryProvider);

    if (hybridRepo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child:                 const Text(
                  'ローカルモード（同期機能なし）',
                ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync),
                const SizedBox(width: 8),
                const Text(
                  '同期管理',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SyncStatusWidget(showLabel: true),
              ],
            ),
            const SizedBox(height: 16),
            
            // 同期ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: forceSyncAsync.isLoading ? null : () {
                  ref.invalidate(forceSyncProvider);
                },
                icon: forceSyncAsync.isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
                label: Text(
                  forceSyncAsync.isLoading ? '同期中...' : 'Firestoreから同期',
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // キャッシュクリアボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('キャッシュクリア'),
                      content: const Text('ローカルキャッシュをクリアしますか？\n次回起動時にFirestoreから再取得されます。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('クリア'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await hybridRepo.clearCache();
                    ref.invalidate(allGroupsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('キャッシュをクリアしました')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('キャッシュクリア'),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // オンライン状態切り替え（デバッグ用）
            if (syncStatus != SyncStatus.localOnly) ...[
              const Divider(),
              const Text(
                'デバッグ用',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('オンライン状態'),
                subtitle: Text(hybridRepo.isOnline ? '接続中' : 'オフライン'),
                value: hybridRepo.isOnline,
                onChanged: (value) {
                  hybridRepo.setOnlineStatus(value);
                  // 状態更新のためプロバイダーを再評価
                  ref.invalidate(syncStatusProvider);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}