import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_list.dart';
import '../providers/shared_list_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';

/// アイテムの編集・新規作成を行うModalBottomSheet
class SharedItemEditModal extends ConsumerStatefulWidget {
  final String listId;
  final SharedItem? item; // nullなら新規作成、値があれば編集

  const SharedItemEditModal({
    super.key,
    required this.listId,
    this.item,
  });

  @override
  ConsumerState<SharedItemEditModal> createState() =>
      _SharedItemEditModalState();
}

class _SharedItemEditModalState extends ConsumerState<SharedItemEditModal> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  DateTime? _selectedDeadline;
  int _intervalValue = 0;
  String _intervalUnit = 'week';
  bool _isSubmitting = false;
  String? _validationError;

  // バリデーション定数
  static const int maxQuantity = 999;
  static const int maxNameLength = 50;

  @override
  void initState() {
    super.initState();

    // 編集モードの場合は既存データをセット
    if (widget.item != null) {
      _nameController = TextEditingController(text: widget.item!.name);
      _quantityController =
          TextEditingController(text: widget.item!.quantity.toString());
      _selectedDeadline = widget.item!.deadline;

      // 購入間隔から単位を逆算
      int intervalDays = widget.item!.shoppingInterval;
      if (intervalDays > 0) {
        if (intervalDays % 30 == 0) {
          _intervalUnit = 'month';
          _intervalValue = intervalDays ~/ 30;
        } else if (intervalDays % 7 == 0) {
          _intervalUnit = 'week';
          _intervalValue = intervalDays ~/ 7;
        } else {
          _intervalUnit = 'day';
          _intervalValue = intervalDays;
        }
      }
    } else {
      // 新規作成モード
      _nameController = TextEditingController();
      _quantityController = TextEditingController(text: '1');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.item != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditMode ? 'アイテムを編集' : '買い物アイテムを追加',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 商品名
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '商品名',
                hintText: '例: 牛乳',
                border: const OutlineInputBorder(),
                errorText: _validationError?.contains('商品名') == true
                    ? _validationError
                    : null,
                counterText: '${_nameController.text.length}/$maxNameLength',
              ),
              maxLength: maxNameLength,
              autofocus: !isEditMode,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // 数量
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: '数量',
                border: const OutlineInputBorder(),
                errorText: _validationError?.contains('数量') == true
                    ? _validationError
                    : null,
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // 期限設定
            InkWell(
              onTap: _selectDeadline,
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
                          color: _selectedDeadline == null ? Colors.grey : null,
                        ),
                      ),
                    ),
                    if (_selectedDeadline != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
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

            // 購入間隔設定
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.repeat),
                      SizedBox(width: 8),
                      Text('購入間隔（任意）'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 数値ドロップダウン
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          initialValue: _intervalValue,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('0 (なし)'),
                            ),
                            ...List.generate(30, (index) => index + 1)
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text('$value'),
                                    ))
                                .toList(),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _intervalValue = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 単位ドロップダウン
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _intervalUnit,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'day',
                              child: Text('日ごと'),
                            ),
                            DropdownMenuItem(
                              value: 'week',
                              child: Text('週ごと'),
                            ),
                            DropdownMenuItem(
                              value: 'month',
                              child: Text('ヶ月ごと'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _intervalUnit = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _intervalValue == 0
                        ? '繰り返し購入なし'
                        : '${_calculateIntervalDays(_intervalValue, _intervalUnit)}日ごとに購入',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // エラーメッセージ表示
            if (_validationError != null &&
                !_validationError!.contains('商品名') &&
                !_validationError!.contains('数量'))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (_validationError != null &&
                !_validationError!.contains('商品名') &&
                !_validationError!.contains('数量'))
              const SizedBox(height: 12),

            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitItem,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditMode ? '更新' : '追加'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 期限選択ダイアログを表示
  Future<void> _selectDeadline() async {
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

      if (picked != null) {
        setState(() {
          _selectedDeadline = picked;
        });
      }
    } catch (e) {
      Log.error('❌ 期限選択ダイアログエラー: $e');
    }
  }

  /// 日付を 'yyyy/MM/dd' 形式の文字列にフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  /// 購入間隔の数値と単位から日数を計算
  int _calculateIntervalDays(int value, String unit) {
    if (value == 0) return 0;
    switch (unit) {
      case 'day':
        return value;
      case 'week':
        return value * 7;
      case 'month':
        return value * 30; // 簡略化のため月は30日と仮定
      default:
        return 0;
    }
  }

  /// アイテムを保存（新規作成または更新）
  Future<void> _submitItem() async {
    if (_isSubmitting) return;

    // バリデーション実行
    final validationError = _validateInput();
    if (validationError != null) {
      setState(() {
        _validationError = validationError;
      });
      return;
    }

    final name = _nameController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentUser = ref.read(authStateProvider).value;
      final currentMemberId = currentUser?.uid ?? 'anonymous';

      if (widget.item == null) {
        // 新規作成
        final newItem = SharedItem.createNow(
          memberId: currentMemberId,
          name: name,
          quantity: quantity,
          deadline: _selectedDeadline,
          shoppingInterval:
              _calculateIntervalDays(_intervalValue, _intervalUnit),
        );

        await repository.addSingleItem(widget.listId, newItem);
        Log.info(
            '✅ アイテム追加成功: ${AppLogger.maskItem(name, newItem.itemId)} x $quantity');

        if (mounted && context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('「$name」を追加しました')),
          );
        }
      } else {
        // 更新
        final updatedItem = widget.item!.copyWith(
          name: name,
          quantity: quantity,
          deadline: _selectedDeadline,
          shoppingInterval:
              _calculateIntervalDays(_intervalValue, _intervalUnit),
        );

        await repository.updateSingleItem(widget.listId, updatedItem);
        Log.info(
            '✅ アイテム更新成功: ${AppLogger.maskItem(name, widget.item!.itemId)}');

        if (mounted && context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('「$name」を更新しました')),
          );
        }
      }
    } catch (e, stackTrace) {
      Log.error('❌ アイテム保存エラー: $e', stackTrace);

      setState(() {
        _isSubmitting = false;
        _validationError = null;
      });

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 入力値のバリデーション
  String? _validateInput() {
    final name = _nameController.text.trim();

    // 商品名チェック
    if (name.isEmpty) {
      return '商品名を入力してください';
    }
    if (name.length > maxNameLength) {
      return '商品名は$maxNameLength文字以内です';
    }

    // 数量チェック
    final quantityStr = _quantityController.text.trim();
    if (quantityStr.isEmpty) {
      return '数量を入力してください';
    }

    final quantity = int.tryParse(quantityStr);
    if (quantity == null || quantity <= 0) {
      return '数量は1以上の数値を入力してください';
    }
    if (quantity > maxQuantity) {
      return '数量は$maxQuantity以下にしてください';
    }

    // 期限チェック（期限が過去でないか）
    if (_selectedDeadline != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadlineDate = DateTime(
        _selectedDeadline!.year,
        _selectedDeadline!.month,
        _selectedDeadline!.day,
      );

      if (deadlineDate.isBefore(today)) {
        return '期限は本日以降の日付を選択してください';
      }
    }

    // 購入間隔チェック
    if (_intervalValue > 30) {
      return '購入間隔は30以下にしてください';
    }

    return null; // バリデーション成功
  }
}
