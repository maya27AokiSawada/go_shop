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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
          subtitle: Text('数量: ${item.quantity}'),
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
        shoppingInterval: oldItem.shoppingInterval,
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