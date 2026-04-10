// lib/pages/shared_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_list.dart';
import '../providers/current_list_provider.dart';
import '../providers/shared_group_provider.dart';
import '../providers/shared_list_provider.dart';
import '../widgets/shared_list_header_widget.dart';
import '../widgets/shared_item_edit_modal.dart';
import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../services/error_log_service.dart';

/// 共有リスト画面
/// カレントグループとカレントリストを使用したシンプルな実装
class SharedListPage extends ConsumerStatefulWidget {
  const SharedListPage({super.key});

  @override
  ConsumerState<SharedListPage> createState() => _SharedListPageState();
}

class _SharedListPageState extends ConsumerState<SharedListPage> {
  String? _previousGroupId; // 前回のグループIDを保存

  @override
  void initState() {
    super.initState();
    // ページ表示時にカレントグループの初期化を試みる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCurrentGroup();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeCurrentGroup();

    // グループ変更を検出
    final currentGroupId = ref.watch(selectedGroupIdProvider);
    if (_previousGroupId != null &&
        currentGroupId != null &&
        _previousGroupId != currentGroupId) {
      Log.info('🔄 グループ変更検出: $_previousGroupId → $currentGroupId');
      Log.info('🗑️ currentListProviderをクリア');
      ref.read(currentListProvider.notifier).clearSelection();
    }
    _previousGroupId = currentGroupId;
  }

  /// カレントグループの初期化
  /// 1. SharedPreferencesから保存されたグループIDを取得
  /// 2. IDが存在しない場合は最初のグループを自動選択
  Future<void> _initializeCurrentGroup() async {
    try {
      final selectedGroupId = ref.read(selectedGroupIdProvider);
      if (selectedGroupId != null) {
        // 既に選択されているグループが存在するか確認
        final allGroupsAsync = ref.read(allGroupsProvider);
        final groupExists = allGroupsAsync.when(
          data: (groups) => groups.any((g) => g.groupId == selectedGroupId),
          loading: () => false,
          error: (_, __) => false,
        );

        if (groupExists) {
          Log.info('✅ 既にグループが選択済み: $selectedGroupId');
          return;
        }
      }

      Log.info('🔄 カレントグループを初期化中...');

      final selectedGroupIdNotifier =
          ref.read(selectedGroupIdProvider.notifier);
      final savedGroupId = await selectedGroupIdNotifier.getSavedGroupId();

      // 全グループを取得
      final allGroupsAsync = ref.read(allGroupsProvider);

      await allGroupsAsync.when(
        data: (groups) async {
          if (groups.isEmpty) {
            Log.info('⚠️ グループが存在しません');
            return;
          }

          if (savedGroupId != null) {
            // 保存されたIDに一致するグループを探す
            final savedGroup =
                groups.where((g) => g.groupId == savedGroupId).firstOrNull;
            if (savedGroup != null) {
              await selectedGroupIdNotifier.selectGroup(savedGroup.groupId);
              Log.info('✅ カレントグループを復元: ${savedGroup.groupName}');
              return;
            } else {
              Log.info('⚠️ 保存されたグループID ($savedGroupId) が見つかりません');
            }
          }

          // 保存されたIDがない or 見つからない場合は最初のグループを選択
          final firstGroup = groups.first;
          await selectedGroupIdNotifier.selectGroup(firstGroup.groupId);
          Log.info('✅ 最初のグループを自動選択: ${firstGroup.groupName}');
        },
        loading: () {
          Log.info('⏳ グループ読み込み中...');
        },
        error: (error, stack) {
          Log.error('❌ グループ初期化エラー: $error');
        },
      );
    } catch (e, stackTrace) {
      Log.error('❌ カレントグループ初期化で予期しないエラー: $e', stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const SafeArea(
          child: Column(
            children: [
              // ヘッダー：グループ選択＋リスト選択
              SharedListHeaderWidget(),

              // アイテム一覧
              Expanded(
                child: _SharedItemsListWidget(),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildFloatingActionButton(context, ref),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () {
        final currentList = ref.read(currentListProvider);
        if (currentList == null) {
          SnackBarHelper.showError(context, 'リストを選択してください');
          return;
        }
        _showAddItemDialog(context, ref);
      },
      tooltip: 'アイテムを追加',
      child: const Icon(Icons.add),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final currentList = ref.read(currentListProvider);
    if (currentList == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SharedItemEditModal(
        listId: currentList.listId,
        item: null, // 新規作成モード
      ),
    );
  }
}

/// アイテム一覧を表示するウィジェット
class _SharedItemsListWidget extends ConsumerWidget {
  const _SharedItemsListWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentList = ref.watch(currentListProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    if (currentList == null || selectedGroupId == null) {
      return const _SharedListPlaceholder(
        icon: Icons.shopping_cart_outlined,
        message: 'リストを選択してください',
      );
    }

    final repository = ref.watch(sharedListRepositoryProvider);

    return StreamBuilder<SharedList?>(
      stream: repository.watchSharedList(selectedGroupId, currentList.listId),
      initialData: currentList,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _SharedListPlaceholder(
            icon: Icons.error_outline,
            message: 'リストの読み込みに失敗しました',
          );
        }

        final liveList = snapshot.data ?? currentList;
        final activeItems = liveList.activeItems;

        if (activeItems.isEmpty) {
          final isTodo = liveList.listType == ListType.todo;
          return _SharedListPlaceholder(
            icon: isTodo ? Icons.checklist : Icons.add_shopping_cart,
            message: isTodo ? 'タスクがありません' : '買い物アイテムがありません',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: activeItems.length,
          itemBuilder: (context, index) {
            final item = activeItems[index];
            return _SharedItemTile(
              list: liveList,
              item: item,
            );
          },
        );
      },
    );
  }
}

class _SharedListPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SharedListPlaceholder({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SharedItemTile extends ConsumerWidget {
  final SharedList list;
  final SharedItem item;

  const _SharedItemTile({
    required this.list,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onDoubleTap: () {
          final currentUser = ref.read(authStateProvider).value;
          if (currentUser == null) return;
          final canEdit = list.ownerUid == currentUser.uid ||
              item.memberId == currentUser.uid;
          if (!canEdit) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('編集権限がありません'),
                backgroundColor: Colors.red,
                duration: Duration(milliseconds: 500),
              ),
            );
            return;
          }
          _showEditItemModal(context);
        },
        onLongPress: () => _confirmDelete(context, ref),
        child: ListTile(
          leading: Checkbox(
            value: item.isPurchased,
            onChanged: (value) =>
                _togglePurchased(context, ref, value ?? false),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              color: item.isPurchased ? Colors.grey : null,
            ),
          ),
          subtitle: _buildSubtitle(),
        ),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final subtitleParts = <String>['数量: ${item.quantity}'];

    if (item.deadline != null) {
      subtitleParts.add('期限: ${_formatDate(item.deadline!)}');
    }

    if (item.shoppingInterval > 0) {
      subtitleParts.add('${item.shoppingInterval}日ごと');
    }

    if (subtitleParts.isEmpty) {
      return null;
    }

    return Text(subtitleParts.join(' / '));
  }

  Future<void> _togglePurchased(
    BuildContext context,
    WidgetRef ref,
    bool isPurchased,
  ) async {
    try {
      final updatedItem = item.copyWith(
        isPurchased: isPurchased,
        purchaseDate: isPurchased ? DateTime.now() : null,
      );

      await ref.read(sharedListRepositoryProvider).updateSingleItem(
            list.listId,
            updatedItem,
          );

      final updatedItems = Map<String, SharedItem>.from(list.items);
      updatedItems[item.itemId] = updatedItem;
      await ref.read(currentListProvider.notifier).updateList(
            list.copyWith(items: updatedItems, updatedAt: DateTime.now()),
            groupId: list.groupId,
          );
    } catch (e, stackTrace) {
      Log.error('❌ 購入状態保存エラー: $e', e, stackTrace);
      await ErrorLogService.logOperationError('購入状態更新', '$e', stackTrace);
      if (context.mounted) {
        SnackBarHelper.showError(context, '購入状態の更新に失敗しました: $e');
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${item.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await ref.read(sharedListRepositoryProvider).removeSingleItem(
                      list.listId,
                      item.itemId,
                    );

                final updatedItems = Map<String, SharedItem>.from(list.items);
                updatedItems[item.itemId] = item.copyWith(
                  isDeleted: true,
                  deletedAt: DateTime.now(),
                );
                await ref.read(currentListProvider.notifier).updateList(
                      list.copyWith(
                          items: updatedItems, updatedAt: DateTime.now()),
                      groupId: list.groupId,
                    );

                Log.info(
                    '🗑️ アイテム論理削除: ${AppLogger.maskItem(item.name, item.itemId)}');

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  SnackBarHelper.showSuccess(context, '「${item.name}」を削除しました');
                }
              } catch (e, stackTrace) {
                Log.error('❌ アイテム削除エラー: $e', e, stackTrace);
                await ErrorLogService.logOperationError(
                    'アイテム削除', '$e', stackTrace);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  SnackBarHelper.showError(context, '削除に失敗しました: $e');
                }
              }
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showEditItemModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SharedItemEditModal(
        listId: list.listId,
        item: item,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final shortYear = (date.year % 100).toString().padLeft(2, '0');
    return '$shortYear/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
