// lib/pages/shared_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_list.dart';
import '../providers/current_list_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shared_list_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/shopping_list_header_widget.dart';
import '../utils/app_logger.dart';

/// 共有リスト画面
/// カレントグループとカレントリストを使用したシンプルな実装
class SharedListPage extends ConsumerStatefulWidget {
  const SharedListPage({super.key});

  @override
  ConsumerState<SharedListPage> createState() => _SharedListPageState();
}

class _SharedListPageState extends ConsumerState<SharedListPage> {
  String? _previousGroupId; // 前回のグループIDを保存
  DateTime? _selectedDeadline; // 選択された期限
  DateTime? _selectedRepeatDate; // 繰り返し購入日

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
              const SharedListHeaderWidget(),

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
    bool isSubmitting = false; // 🔥 二重送信防止フラグ

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('買い物アイテムを追加'),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await _selectDeadlineForDialog(context);
                    if (picked != null) {
                      setDialogState(() {
                        _selectedDeadline = picked;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDeadline == null
                                ? '購入期限を選択（任意）'
                                : '期限: ${_formatDate(_selectedDeadline!)}',
                            style: TextStyle(
                              color: _selectedDeadline == null
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                        ),
                        if (_selectedDeadline != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setDialogState(() {
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
                  onTap: () async {
                    final picked = await _selectRepeatDateForDialog(context);
                    if (picked != null) {
                      setDialogState(() {
                        _selectedRepeatDate = picked;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat),
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
                            onPressed: () {
                              setDialogState(() {
                                _selectedRepeatDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // 🔥 二重送信防止：処理中は無効化
                      if (isSubmitting) return;

                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('商品名を入力してください')),
                        );
                        return;
                      }

                      final quantity =
                          int.tryParse(quantityController.text) ?? 1;

                      final currentList = ref.read(currentListProvider);
                      if (currentList == null) return;

                      // 現在のユーザーIDを取得
                      final currentUser = ref.read(authStateProvider).value;
                      final currentMemberId = currentUser?.uid ?? 'anonymous';

                      // 🔥 送信開始：ボタン無効化
                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        // 新しいアイテムを作成（itemIdは自動生成）
                        final newItem = SharedItem.createNow(
                          memberId: currentMemberId,
                          name: name,
                          quantity: quantity,
                          deadline: _selectedDeadline, // 期限を追加
                          shoppingInterval: _selectedRepeatDate != null
                              ? _calculateInterval(_selectedRepeatDate!)
                              : 0,
                          // itemId: 自動生成される
                        );

                        // 🆕 差分同期: 単一アイテムのみ追加
                        final repository =
                            ref.read(sharedListRepositoryProvider);
                        await repository.addSingleItem(
                            currentList.listId, newItem);

                        // StreamBuilderが自動的に更新を検知するため、invalidateは不要

                        Log.info(
                            '✅ アイテム追加成功: $name x $quantity (itemId: ${newItem.itemId})');

                        // 期限と定期購入をリセット
                        setState(() {
                          _selectedDeadline = null;
                          _selectedRepeatDate = null;
                        });

                        // ダイアログを閉じる
                        if (context.mounted) {
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('「$name」を追加しました')),
                          );
                        }
                      } catch (e, stackTrace) {
                        Log.error('❌ アイテム追加エラー: $e', stackTrace);

                        // エラー時は送信フラグをリセット
                        setDialogState(() {
                          isSubmitting = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('アイテム追加に失敗しました: $e')),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  /// 期限選択ダイアログを表示（ダイアログ内で使用）
  Future<DateTime?> _selectDeadlineForDialog(BuildContext context) async {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final oneYearLater = DateTime(now.year + 1, now.month, now.day);

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDeadline ?? tomorrow,
        firstDate: tomorrow,
        lastDate: oneYearLater,
      );

      return picked;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('日付選択エラー: $e')),
        );
      }
      return null;
    }
  }

  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  /// 定期購入日選択ダイアログを表示（ダイアログ内で使用）
  Future<DateTime?> _selectRepeatDateForDialog(BuildContext context) async {
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

      return picked;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('日付選択エラー: $e')),
        );
      }
      return null;
    }
  }

  /// 次回購入日から購入間隔（日数）を計算
  int _calculateInterval(DateTime nextPurchaseDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(
        nextPurchaseDate.year, nextPurchaseDate.month, nextPurchaseDate.day);
    return targetDate.difference(today).inDays;
  }
}

/// アイテム一覧を表示するウィジェット
class _SharedItemsListWidget extends ConsumerWidget {
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

    // アイテムをソートするメソッド
    // 優先順位: 1. 未購入を上に、2. 期限が早い順、3. 購入済みを下に
    List<SharedItem> sortItems(List<SharedItem> items) {
      final sortedItems = [...items];
      sortedItems.sort((a, b) {
        // 1. 購入済みを下に
        if (a.isPurchased != b.isPurchased) {
          return a.isPurchased ? 1 : -1;
        }

        // 2. 未購入内で期限順（期限が早い順、nullは最後）
        if (!a.isPurchased) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1; // nullは最後
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        }

        // 3. 購入済み内は元の順序を維持
        return 0;
      });
      return sortedItems;
    }

    // リアルタイム同期用のStreamBuilder
    final repository = ref.read(sharedListRepositoryProvider);

    return StreamBuilder<SharedList?>(
      key: ValueKey(currentList.listId), // リストIDが変わったら再構築
      stream: repository.watchSharedList(selectedGroupId, currentList.listId),
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

        // 🆕 アクティブアイテムのみ表示（isDeleted=falseのみ）
        if (liveList.activeItems.isEmpty) {
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

        // 🆕 アクティブアイテムのみ表示し、ソート
        final activeItems = sortItems(liveList.activeItems);
        return ListView.builder(
          itemCount: activeItems.length,
          itemBuilder: (context, index) {
            final item = activeItems[index];
            return _SharedItemTile(item: item);
          },
        );
      },
    );
  }
}

/// アイテム1件を表示するウィジェット
class _SharedItemTile extends ConsumerWidget {
  final SharedItem item;

  const _SharedItemTile({
    required this.item,
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
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('数量: ${item.quantity}'),
            if (item.deadline != null) _buildDeadlineBadge(item.deadline!),
            if (item.shoppingInterval > 0)
              _buildRepeatBadge(item.shoppingInterval),
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

  /// 期限バッジを作成
  Widget _buildDeadlineBadge(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = deadlineDay.difference(today).inDays;

    Color badgeColor;
    IconData icon;
    String text;

    if (difference < 0) {
      // 期限切れ
      badgeColor = Colors.red;
      icon = Icons.error_outline;
      text = '期限切れ';
    } else if (difference == 0) {
      // 今日が期限
      badgeColor = Colors.orange;
      icon = Icons.warning_amber;
      text = '今日まで';
    } else if (difference <= 3) {
      // 期限間近（3日以内）
      badgeColor = Colors.orange;
      icon = Icons.schedule;
      text = 'あと$difference日';
    } else if (difference <= 7) {
      // 1週間以内
      badgeColor = Colors.blue;
      icon = Icons.schedule;
      text = 'あと$difference日';
    } else {
      // それ以上
      badgeColor = Colors.green;
      icon = Icons.check_circle_outline;
      text = '${deadline.month}/${deadline.day}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(color: badgeColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 定期購入バッジを作成
  Widget _buildRepeatBadge(int intervalDays) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        border: Border.all(color: Colors.purple, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 14, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            '$intervalDays日毎',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleItemPurchased(WidgetRef ref, bool isPurchased) async {
    final currentList = ref.read(currentListProvider);
    if (currentList == null) return;

    try {
      // 🆕 差分同期: 単一アイテムのみ更新
      final updatedItem = item.copyWith(
        isPurchased: isPurchased,
        purchaseDate: isPurchased ? DateTime.now() : null,
      );

      final repository = ref.read(sharedListRepositoryProvider);
      await repository.updateSingleItem(currentList.listId, updatedItem);

      // StreamBuilderが自動的に更新を検知するため、invalidateは不要

      Log.info(
          '✅ アイテム購入状態更新: ${item.name} -> $isPurchased (itemId: ${item.itemId})');
    } catch (e, stackTrace) {
      Log.error('❌ 購入状態保存エラー: $e', stackTrace);
    }
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
            onPressed: () async {
              final currentList = ref.read(currentListProvider);
              if (currentList == null) return;

              try {
                // 🆕 論理削除: isDeleted=trueに設定
                final repository = ref.read(sharedListRepositoryProvider);
                await repository.removeSingleItem(
                    currentList.listId, item.itemId);

                // StreamBuilderが自動的に更新を検知するため、invalidateは不要

                Log.info('🗑️ アイテム論理削除: ${item.name} (itemId: ${item.itemId})');

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${item.name}」を削除しました')),
                );
              } catch (e, stackTrace) {
                Log.error('❌ アイテム削除エラー: $e', stackTrace);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('削除に失敗しました: $e')),
                );
              }
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
