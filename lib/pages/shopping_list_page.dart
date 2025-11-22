import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shopping_list.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/security_provider.dart';
import '../providers/current_list_provider.dart';
import '../services/access_control_service.dart';
import '../helpers/validation_service.dart';
import '../widgets/shopping_list_header_widget.dart';
import '../utils/app_logger.dart';

// NOTE: selectedGroupIdProviderはpurchase_group_provider.dartで定義済み

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  String? selectedListId;
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _selectedDeadline;
  DateTime? _selectedRepeatDate; // 繰り返し購入日
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ページ表示時に初回のグループを設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedGroup();
    });
  }

  void _initializeSelectedGroup() async {
    final allGroupsAsync = ref.read(allGroupsProvider);
    await allGroupsAsync.when(
      data: (groups) async {
        if (groups.isNotEmpty && selectedListId == null) {
          final firstGroupId = groups.first.groupId;
          setState(() {
            selectedListId = firstGroupId;
          });
          ref.read(selectedGroupIdProvider.notifier).selectGroup(firstGroupId);
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 シークレットモードチェック
    return FutureBuilder<GroupVisibilityMode>(
      future: ref.read(accessControlServiceProvider).getGroupVisibilityMode(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('買い物リスト')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final visibilityMode = snapshot.data!;

        // シークレットモードON + 未サインイン時はブロック
        if (visibilityMode == GroupVisibilityMode.defaultOnly) {
          return Scaffold(
            appBar: AppBar(title: const Text('買い物リスト')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_off,
                      size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    '🔒 サインインが必要です',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'シークレットモードがONになっています\nサインインするか、シークレットモードをOFFにしてください',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        // 通常モード: 既存のUI表示
        return _buildNormalShoppingListUI(context);
      },
    );
  }

  Widget _buildNormalShoppingListUI(BuildContext context) {
    // グループ変更を監視し、currentListをクリア
    ref.listen<String?>(selectedGroupIdProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        Log.info('🔄 グループ変更検出: $previous → $next');
        Log.info('🗑️ currentListProviderをクリア');
        ref.read(currentListProvider.notifier).clearSelection();
      }
    });

    // セキュリティチェック（既存の仕組み）
    final canViewData = ref.watch(dataVisibilityProvider);
    final authRequired = ref.watch(authRequiredProvider);

    if (!canViewData && authRequired) {
      return Scaffold(
        appBar: AppBar(title: const Text('買い物リスト')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'データ表示が制限されています',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '買い物リストを表示するにはログインが必要です',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    // グループが選択されていない場合は空リスト表示
    if (selectedGroupId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('買い物リスト')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('グループが選択されていません',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物リスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: () => _showAddShoppingListDialog(context),
            tooltip: 'リスト追加',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_purchased') {
                _clearPurchasedItems();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_purchased',
                child: Text('購入済みアイテムを削除'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 新しいヘッダーウィジェット
          const ShoppingListHeaderWidget(),

          // 以下は既存のアイテムリスト表示部分
          Expanded(
            child: _buildShoppingItemsList(context),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildShoppingItemsList(BuildContext context) {
    final currentList = ref.watch(currentListProvider);

    if (currentList == null) {
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
          ],
        ),
      );
    }

    if (currentList.items.isEmpty) {
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
      itemCount: currentList.items.length,
      itemBuilder: (context, index) {
        final item = currentList.items[index];
        return _buildShoppingItemTile(context, item, index);
      },
    );
  }

  Widget _buildShoppingItemTile(
      BuildContext context, ShoppingItem item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (bool? value) {
            if (value != null) {
              _toggleItemPurchased(index, value);
            }
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey : null,
          ),
        ),
        subtitle: Text('数量: ${item.quantity}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.deadline != null)
              Icon(
                Icons.schedule,
                size: 16,
                color: _getDeadlineColor(item.deadline!),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(index),
            ),
          ],
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

  void _toggleItemPurchased(int index, bool isPurchased) {
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

    ref.read(currentListProvider.notifier).updateList(updatedList);

    // リポジトリに保存
    final repository = ref.read(shoppingListRepositoryProvider);
    repository.updateShoppingList(updatedList);
  }

  void _deleteItem(int index) {
    final currentList = ref.read(currentListProvider);
    if (currentList == null) return;

    final updatedItems = List<ShoppingItem>.from(currentList.items);
    updatedItems.removeAt(index);

    final updatedList = currentList.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    ref.read(currentListProvider.notifier).updateList(updatedList);

    // リポジトリに保存
    final repository = ref.read(shoppingListRepositoryProvider);
    repository.updateShoppingList(updatedList);
  }

  void _showAddItemDialog(BuildContext context) {
    _itemNameController.clear();
    _quantityController.text = '1';
    _selectedDeadline = null;
    _selectedRepeatDate = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('新しいアイテムを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: '商品名',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: '数量',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isLoading
                    ? null
                    : () => _selectDeadline(context, setState),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: _isLoading ? Colors.grey : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDeadline == null
                              ? '購入期限を選択（任意）'
                              : '期限: ${_formatDate(_selectedDeadline!)}',
                          style: TextStyle(
                            color:
                                _selectedDeadline == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (_selectedDeadline != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedDeadline = null;
                                  });
                                },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isLoading
                    ? null
                    : () => _selectRepeatDate(context, setState),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.repeat,
                          color: _isLoading ? Colors.grey : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedRepeatDate == null
                              ? '次回購入予定日（任意）'
                              : '次回: ${_formatDate(_selectedRepeatDate!)} (${_calculateInterval(_selectedRepeatDate!)}日間隔)',
                          style: TextStyle(
                            color: _selectedRepeatDate == null
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                      if (_selectedRepeatDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedRepeatDate = null;
                                  });
                                },
                        ),
                    ],
                  ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('保存中...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _addItemWithLoading(context, setState),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, ShoppingItem item) {
    _itemNameController.text = item.name;
    _quantityController.text = item.quantity.toString();
    _selectedDeadline = item.deadline;
    _selectedRepeatDate = item.shoppingInterval > 0
        ? DateTime.now().add(Duration(days: item.shoppingInterval))
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('アイテムを編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: '商品名',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: '数量',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isLoading
                    ? null
                    : () => _selectDeadline(context, setState),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: _isLoading ? Colors.grey : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDeadline == null
                              ? '購入期限を選択（任意）'
                              : '期限: ${_formatDate(_selectedDeadline!)}',
                          style: TextStyle(
                            color:
                                _selectedDeadline == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (_selectedDeadline != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedDeadline = null;
                                  });
                                },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isLoading
                    ? null
                    : () => _selectRepeatDate(context, setState),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.repeat,
                          color: _isLoading ? Colors.grey : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedRepeatDate == null
                              ? '次回購入予定日（任意）'
                              : '次回: ${_formatDate(_selectedRepeatDate!)} (${_calculateInterval(_selectedRepeatDate!)}日間隔)',
                          style: TextStyle(
                            color: _selectedRepeatDate == null
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                      if (_selectedRepeatDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedRepeatDate = null;
                                  });
                                },
                        ),
                    ],
                  ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('更新中...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _updateItemWithLoading(context, item, setState),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('更新'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ShoppingItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイテムを削除'),
        content: Text('「${item.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final selectedGroupId = ref.read(selectedGroupIdProvider);
                if (selectedGroupId == null) return;
                await ref
                    .read(
                        shoppingListForGroupProvider(selectedGroupId).notifier)
                    .removeItem(item);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('「${item.name}」を削除しました')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('削除に失敗しました: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addItemWithLoading(
      BuildContext context, StateSetter setState) async {
    final name = _itemNameController.text.trim();
    final quantityText = _quantityController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品名を入力してください')),
      );
      return;
    }

    final quantity = int.tryParse(quantityText) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数量は1以上の数値で入力してください')),
      );
      return;
    }

    // カレントリスト選択チェック（必須）
    final selectedGroupId = ref.read(selectedGroupIdProvider);
    if (selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カレントリストを選択してください')),
      );
      return; // ここで処理を中断
    }

    // 既存アイテムの重複チェック
    try {
      final currentListAsync =
          ref.read(shoppingListForGroupProvider(selectedGroupId));

      await currentListAsync.when(
        data: (currentList) async {
          // バリデーション実行
          final validation = ValidationService.validateItemName(
              name, currentList.items, 'defaultUser');

          if (validation.hasWarning) {
            // 警告の場合は確認ダイアログを表示
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('重複確認'),
                content: Text(validation.errorMessage!),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('追加する'),
                  ),
                ],
              ),
            );

            if (shouldContinue != true) return;
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (e) {
      // エラー時は重複チェックをスキップして続行
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newItem = ShoppingItem.createNow(
        memberId: 'defaultUser',
        name: name,
        quantity: quantity,
        deadline: _selectedDeadline,
        shoppingInterval: _selectedRepeatDate != null
            ? _calculateInterval(_selectedRepeatDate!)
            : 0,
      );

      // 上でnullチェック済みだが念のため再確認
      final selectedGroupId = ref.read(selectedGroupIdProvider);
      if (selectedGroupId == null) {
        throw Exception('カレントリストが選択されていません');
      }
      await ref
          .read(shoppingListForGroupProvider(selectedGroupId).notifier)
          .addItem(newItem);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$name」を追加しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('追加に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDeadline(
      BuildContext context, StateSetter setState) async {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final oneYearLater = DateTime(now.year + 1, now.month, now.day);

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDeadline ?? tomorrow,
        firstDate: tomorrow,
        lastDate: oneYearLater,
        // Webでの互換性のためlocaleを削除
      );

      if (picked != null) {
        setState(() {
          _selectedDeadline = picked;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('日付選択エラー: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  bool _isDeadlinePassed(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDate.isBefore(today);
  }

  int _getDaysUntilDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDate.difference(today).inDays;
  }

  String _getDaysUntilDeadlineText(DateTime deadline) {
    final daysUntil = _getDaysUntilDeadline(deadline);

    if (daysUntil < 0) {
      return '${-daysUntil}日超過';
    } else if (daysUntil == 0) {
      return '今日期限';
    } else if (daysUntil == 1) {
      return '明日期限';
    } else {
      return 'あと$daysUntil日';
    }
  }

  void _sortItemsByDeadline(List<ShoppingItem> items) {
    items.sort((a, b) {
      // 期限なしのアイテムは最後に
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;

      // 期限が近い順（昇順）
      return a.deadline!.compareTo(b.deadline!);
    });
  }

  void _sortPurchasedItemsByDate(List<ShoppingItem> items) {
    items.sort((a, b) {
      // 購入日なしのアイテムは最後に
      if (a.purchaseDate == null && b.purchaseDate == null) return 0;
      if (a.purchaseDate == null) return 1;
      if (b.purchaseDate == null) return -1;

      // 購入日が新しい順（降順）
      return b.purchaseDate!.compareTo(a.purchaseDate!);
    });
  }

  Future<void> _selectRepeatDate(
      BuildContext context, StateSetter setState) async {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final oneYearLater = DateTime(now.year + 1, now.month, now.day);

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedRepeatDate ?? tomorrow,
        firstDate: tomorrow,
        lastDate: oneYearLater,
        helpText: '次回購入予定日を選択',
      );

      if (picked != null) {
        setState(() {
          _selectedRepeatDate = picked;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('日付選択エラー: $e')),
        );
      }
    }
  }

  int _calculateInterval(DateTime nextPurchaseDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(
        nextPurchaseDate.year, nextPurchaseDate.month, nextPurchaseDate.day);
    return targetDate.difference(today).inDays;
  }

  Future<void> _updateItemWithLoading(
      BuildContext context, ShoppingItem oldItem, StateSetter setState) async {
    final name = _itemNameController.text.trim();
    final quantityText = _quantityController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品名を入力してください')),
      );
      return;
    }

    final quantity = int.tryParse(quantityText) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数量は1以上の数値で入力してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedItem = ShoppingItem(
        memberId: oldItem.memberId,
        name: name,
        quantity: quantity,
        registeredDate: oldItem.registeredDate,
        purchaseDate: oldItem.purchaseDate,
        isPurchased: oldItem.isPurchased,
        shoppingInterval: _selectedRepeatDate != null
            ? _calculateInterval(_selectedRepeatDate!)
            : 0,
        deadline: _selectedDeadline,
      );

      await ref
          .read(shoppingListProvider.notifier)
          .updateItem(oldItem, updatedItem);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$name」を更新しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearPurchasedItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入済みアイテムを削除'),
        content: const Text('購入済みのアイテムをすべて削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final selectedGroupId = ref.read(selectedGroupIdProvider);
                if (selectedGroupId == null) return;
                await ref
                    .read(
                        shoppingListForGroupProvider(selectedGroupId).notifier)
                    .clearPurchasedItems();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('購入済みアイテムを削除しました')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('削除に失敗しました: $e')),
                  );
                }
              }
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  // フローティングアクションボタンの構築
  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddItemDialog(context),
      label: const Text('アイテム追加'),
      icon: const Icon(Icons.add_shopping_cart),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // 新しいショッピングリスト追加ダイアログ
  void _showAddShoppingListDialog(BuildContext context) {
    final listNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいリスト作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: listNameController,
              decoration: const InputDecoration(
                labelText: 'リスト名',
                hintText: '例: 今週の買い物',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              '※現在は1つのリストのみサポートしています',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              listNameController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final listName = listNameController.text.trim();
              if (listName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('リスト名を入力してください')),
                );
                return;
              }

              // 将来の機能として準備（現在は未実装）
              listNameController.dispose();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('複数リスト機能は将来リリース予定です')),
              );
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }
}
