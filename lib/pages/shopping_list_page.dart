import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/purchase_group_provider.dart';

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
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shoppingListAsync = ref.watch(shoppingListProvider);
    final purchaseGroupAsync = ref.watch(purchaseGroupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物リスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
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
          // ドロップダウンでリスト選択
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: purchaseGroupAsync.when(
              data: (group) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedListId ?? 'current_list',
                            isExpanded: true,
                            hint: const Text('リストを選択'),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'current_list',
                                child: Text(group.groupName),
                              ),
                              // 将来的に複数リスト対応時はここで追加
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                selectedListId = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('グループ情報を読み込み中...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              error: (error, stack) => Text('エラー: $error'),
            ),
          ),
          
          // 買い物アイテムリスト
          Expanded(
            child: shoppingListAsync.when(
              data: (shoppingList) {
                if (shoppingList.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('買い物アイテムがありません', style: TextStyle(color: Colors.grey)),
                        Text('右上の + ボタンでアイテムを追加してください', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                
                // 未購入と購入済みに分けて表示
                final unpurchasedItems = shoppingList.items.where((item) => !item.isPurchased).toList();
                final purchasedItems = shoppingList.items.where((item) => item.isPurchased).toList();
                
                // 未購入アイテムをdeadlineでソート（期限が近い順）
                _sortItemsByDeadline(unpurchasedItems);
                
                // 購入済みアイテムを購入日でソート（新しい順）
                _sortPurchasedItemsByDate(purchasedItems);
                
                return ListView(
                  children: [
                    if (unpurchasedItems.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          '未購入',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...unpurchasedItems.map((item) => _buildShoppingItemTile(item)),
                    ],
                    if (purchasedItems.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          '購入済み',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                      ...purchasedItems.map((item) => _buildShoppingItemTile(item)),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('買い物リストを読み込み中...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              error: (error, stack) => Center(child: Text('エラー: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItemTile(ShoppingItem item) {
    // 期限による背景色を決定
    Color? backgroundColor;
    if (item.deadline != null && !item.isPurchased) {
      backgroundColor = _getDeadlineColor(item.deadline!);
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: backgroundColor,
      child: GestureDetector(
        // タップで編集
        onTap: () => _showEditItemDialog(context, item),
        // ダブルタップで購入済み切り替え
        onDoubleTap: () {
          ref.read(shoppingListProvider.notifier).togglePurchased(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                item.isPurchased 
                  ? '「${item.name}」を未購入に変更しました' 
                  : '「${item.name}」を購入済みに変更しました'
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        // 長押しで削除
        onLongPress: () => _showDeleteConfirmDialog(context, item),
        child: ListTile(
          leading: Checkbox(
            value: item.isPurchased,
            onChanged: (bool? value) {
              ref.read(shoppingListProvider.notifier).togglePurchased(item);
            },
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              color: item.isPurchased ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('数量: ${item.quantity}'),
              if (item.deadline != null)
                Text(
                  '期限: ${_formatDate(item.deadline!)} (${_getDaysUntilDeadlineText(item.deadline!)})',
                  style: TextStyle(
                    color: _isDeadlinePassed(item.deadline!) 
                      ? Colors.red 
                      : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              if (item.shoppingInterval > 0)
                Text(
                  '繰り返し: ${item.shoppingInterval}日間隔',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          trailing: item.isPurchased
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
      ),
    );
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
                onTap: _isLoading ? null : () => _selectDeadline(context, setState),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: _isLoading ? Colors.grey : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDeadline == null
                              ? '購入期限を選択（任意）'
                              : '期限: ${_formatDate(_selectedDeadline!)}',
                          style: TextStyle(
                            color: _selectedDeadline == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (_selectedDeadline != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _isLoading ? null : () {
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
                onTap: _isLoading ? null : () => _selectRepeatDate(context, setState),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, color: _isLoading ? Colors.grey : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedRepeatDate == null
                              ? '次回購入予定日（任意）'
                              : '次回: ${_formatDate(_selectedRepeatDate!)} (${_calculateInterval(_selectedRepeatDate!)}日間隔)',
                          style: TextStyle(
                            color: _selectedRepeatDate == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (_selectedRepeatDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _isLoading ? null : () {
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
              onPressed: _isLoading ? null : () => _addItemWithLoading(context, setState),
              child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                onTap: _isLoading ? null : () => _selectDeadline(context, setState),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: _isLoading ? Colors.grey : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDeadline == null
                              ? '購入期限を選択（任意）'
                              : '期限: ${_formatDate(_selectedDeadline!)}',
                          style: TextStyle(
                            color: _selectedDeadline == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (_selectedDeadline != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _isLoading ? null : () {
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
                onTap: _isLoading ? null : () => _selectRepeatDate(context, setState),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, color: _isLoading ? Colors.grey : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedRepeatDate == null
                              ? '次回購入予定日（任意）'
                              : '次回: ${_formatDate(_selectedRepeatDate!)} (${_calculateInterval(_selectedRepeatDate!)}日間隔)',
                          style: TextStyle(
                            color: _selectedRepeatDate == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (_selectedRepeatDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _isLoading ? null : () {
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
              onPressed: _isLoading ? null : () => _updateItemWithLoading(context, item, setState),
              child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                await ref.read(shoppingListProvider.notifier).removeItem(item);
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

  Future<void> _addItemWithLoading(BuildContext context, StateSetter setState) async {
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
      final newItem = ShoppingItem.createNow(
        memberId: 'defaultUser',
        name: name,
        quantity: quantity,
        deadline: _selectedDeadline,
        shoppingInterval: _selectedRepeatDate != null ? _calculateInterval(_selectedRepeatDate!) : 0,
      );
      
      await ref.read(shoppingListProvider.notifier).addItem(newItem);
      
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

  Future<void> _selectDeadline(BuildContext context, StateSetter setState) async {
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

  Color _getDeadlineColor(DateTime deadline) {
    final daysUntil = _getDaysUntilDeadline(deadline);
    
    if (daysUntil < 0) {
      return Colors.red.shade100; // 期限切れ - 赤
    } else if (daysUntil == 0) {
      return Colors.orange.shade100; // 今日期限 - オレンジ
    } else if (daysUntil == 1) {
      return Colors.yellow.shade100; // 明日期限 - 黄色
    } else if (daysUntil <= 3) {
      return Colors.blue.shade50; // 3日以内 - 薄い青
    } else {
      return Colors.white; // 余裕あり - 白
    }
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

  Future<void> _selectRepeatDate(BuildContext context, StateSetter setState) async {
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
    final targetDate = DateTime(nextPurchaseDate.year, nextPurchaseDate.month, nextPurchaseDate.day);
    return targetDate.difference(today).inDays;
  }

  Future<void> _updateItemWithLoading(BuildContext context, ShoppingItem oldItem, StateSetter setState) async {
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
        shoppingInterval: _selectedRepeatDate != null ? _calculateInterval(_selectedRepeatDate!) : 0,
        deadline: _selectedDeadline,
      );
      
      await ref.read(shoppingListProvider.notifier).updateItem(oldItem, updatedItem);
      
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
                await ref.read(shoppingListProvider.notifier).clearPurchasedItems();
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
}