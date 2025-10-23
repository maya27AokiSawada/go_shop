import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';

/// オーナー専用のメッセージ編集・表示ウィジェット
class OwnerMessageWidget extends ConsumerStatefulWidget {
  final PurchaseGroup purchaseGroup;
  final bool isOwner;

  const OwnerMessageWidget({
    super.key,
    required this.purchaseGroup,
    required this.isOwner,
  });

  @override
  ConsumerState<OwnerMessageWidget> createState() => _OwnerMessageWidgetState();
}

class _OwnerMessageWidgetState extends ConsumerState<OwnerMessageWidget> {
  late TextEditingController _messageController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.purchaseGroup.ownerMessage ?? '',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _saveMessage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(selectedGroupNotifierProvider.notifier);
      await notifier.updateOwnerMessage(
        widget.purchaseGroup.groupId,
        _messageController.text.trim(),
      );

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メッセージを保存しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _messageController.text = widget.purchaseGroup.ownerMessage ?? '';
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMessage = widget.purchaseGroup.ownerMessage?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'オーナーからのメッセージ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (widget.isOwner && !_isEditing)
                IconButton(
                  icon: Icon(
                    hasMessage ? Icons.edit : Icons.add,
                    color: Colors.orange[700],
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  tooltip: hasMessage ? 'メッセージを編集' : 'メッセージを追加',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing && widget.isOwner)
            // 編集モード
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'グループメンバーへのメッセージを入力してください',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : _cancelEdit,
                      child: const Text('キャンセル'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存'),
                    ),
                  ],
                ),
              ],
            )
          else
            // 表示モード
            hasMessage
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[100]!),
                    ),
                    child: Text(
                      widget.purchaseGroup.ownerMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  )
                : widget.isOwner
                    ? Text(
                        'メッセージが設定されていません。\n右上の + ボタンからメッセージを追加できます。',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        'オーナーからのメッセージはありません',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
        ],
      ),
    );
  }
}
