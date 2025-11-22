// lib/pages/shopping_list_page_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list.dart';
import '../providers/current_list_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/shopping_list_header_widget.dart';
import '../utils/app_logger.dart';

/// 買い物リスト画面（新バージョン）
/// カレントグループとカレントリストを使用したシンプルな実装
class ShoppingListPageV2 extends ConsumerStatefulWidget {
  const ShoppingListPageV2({super.key});

  @override
  ConsumerState<ShoppingListPageV2> createState() => _ShoppingListPageV2State();
}

class _ShoppingListPageV2State extends ConsumerState<ShoppingListPageV2> {
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
        SafeArea(
          child: Column(
            children: [
              // ヘッダー：グループ選択＋リスト選択
              const ShoppingListHeaderWidget(),

              // アイテム一覧
              Expanded(
                child: _ShoppingItemsListWidget(),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('リストを選択してください')),
          );
          return;
        }
        _showAddItemDialog(context, ref);
      },
      tooltip: 'アイテムを追加',
      child: const Icon(Icons.add),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('買い物アイテムを追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '商品名',
                hintText: '例: 牛乳',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: '数量',
              ),
              keyboardType: TextInputType.number,
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('商品名を入力してください')),
                );
                return;
              }

              final quantity = int.tryParse(quantityController.text) ?? 1;

              final currentList = ref.read(currentListProvider);
              if (currentList == null) return;

              try {
                // 新しいアイテムを作成
                final newItem = ShoppingItem.createNow(
                  memberId: 'dev_user',
                  name: name,
                  quantity: quantity,
                );

                // リストに追加
                final updatedList = currentList.copyWith(
                  items: [...currentList.items, newItem],
                );

                // リポジトリに保存
                final repository = ref.read(shoppingListRepositoryProvider);
                await repository.updateShoppingList(updatedList);

                // StreamBuilderが自動的に更新を検知するため、invalidateは不要

                Log.info('✅ アイテム追加成功: $name x $quantity (リアルタイム同期)');

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「$name」を追加しました')),
                );
              } catch (e, stackTrace) {
                Log.error('❌ アイテム追加エラー: $e', stackTrace);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('アイテム追加に失敗しました: $e')),
                );
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
}

/// アイテム一覧を表示するウィジェット
class _ShoppingItemsListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentList = ref.watch(currentListProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    if (currentList == null || selectedGroupId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'リストを選択してください',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'グループ画面でグループを選択後、',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            Text(
              '上部のドロップダウンからリストを選んでください',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // リアルタイム同期用のStreamBuilder
    final repository = ref.read(shoppingListRepositoryProvider);

    return StreamBuilder<ShoppingList?>(
      stream: repository.watchShoppingList(selectedGroupId, currentList.listId),
      initialData: currentList, // 初期データは既存のcurrentListを使用
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          Log.error('❌ [STREAM] エラー: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'データ取得エラー',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final liveList = snapshot.data ?? currentList;

        if (liveList.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  '買い物アイテムがありません',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  '右下の + ボタンから追加してください',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: liveList.items.length,
          itemBuilder: (context, index) {
            final item = liveList.items[index];
            return _ShoppingItemTile(item: item, index: index);
          },
        );
      },
    );
  }
}

/// アイテム1件を表示するウィジェット
class _ShoppingItemTile extends ConsumerWidget {
  final ShoppingItem item;
  final int index;

  const _ShoppingItemTile({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (bool? value) {
            if (value != null) {
              _toggleItemPurchased(ref, value);
            }
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey : null,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Text('数量: ${item.quantity}'),
            if (item.deadline != null) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.schedule,
                size: 14,
                color: _getDeadlineColor(item.deadline!),
              ),
              const SizedBox(width: 4),
              Text(
                '期限: ${item.deadline!.month}/${item.deadline!.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: _getDeadlineColor(item.deadline!),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: () => _deleteItem(context, ref),
          tooltip: '削除',
        ),
      ),
    );
  }

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    if (difference < 0) return Colors.red;
    if (difference <= 3) return Colors.orange;
    return Colors.green;
  }

  void _toggleItemPurchased(WidgetRef ref, bool isPurchased) {
    final currentList = ref.read(currentListProvider);
    if (currentList == null) return;

    final updatedItems = List<ShoppingItem>.from(currentList.items);
    updatedItems[index] = updatedItems[index].copyWith(
      isPurchased: isPurchased,
      purchaseDate: isPurchased ? DateTime.now() : null,
    );

    final updatedList = currentList.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    // StreamBuilderが自動的に更新を検知するため、invalidateは不要

    Log.info('✅ アイテム購入状態更新: ${item.name} -> $isPurchased (リアルタイム同期)');

    // リポジトリに保存（バックグラウンドで実行）
    final repository = ref.read(shoppingListRepositoryProvider);
    repository.updateShoppingList(updatedList).catchError((e, stackTrace) {
      Log.error('❌ 購入状態保存エラー: $e', stackTrace);
    });
  }

  void _deleteItem(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${item.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final currentList = ref.read(currentListProvider);
              if (currentList == null) return;

              final updatedItems = List<ShoppingItem>.from(currentList.items);
              updatedItems.removeAt(index);

              final updatedList = currentList.copyWith(
                items: updatedItems,
                updatedAt: DateTime.now(),
              );

              // StreamBuilderが自動的に更新を検知するため、invalidateは不要

              Log.info('🗑️ アイテム削除: ${item.name} (リアルタイム同期)');

              // リポジトリに保存（バックグラウンドで実行）
              final repository = ref.read(shoppingListRepositoryProvider);
              repository
                  .updateShoppingList(updatedList)
                  .catchError((e, stackTrace) {
                Log.error('❌ アイテム削除保存エラー: $e', stackTrace);
              });

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「${item.name}」を削除しました')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
