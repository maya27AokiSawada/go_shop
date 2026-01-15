import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../models/whiteboard.dart';
import '../providers/whiteboard_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/drawing_converter.dart';
import '../utils/app_logger.dart';

/// ホワイトボード編集画面（フルスクリーン）
class WhiteboardEditorPage extends ConsumerStatefulWidget {
  final Whiteboard whiteboard;
  final String groupId;

  const WhiteboardEditorPage({
    super.key,
    required this.whiteboard,
    required this.groupId,
  });

  @override
  ConsumerState<WhiteboardEditorPage> createState() =>
      _WhiteboardEditorPageState();
}

class _WhiteboardEditorPageState extends ConsumerState<WhiteboardEditorPage> {
  late final SignatureController _controller;
  bool _isSaving = false;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;

  @override
  void initState() {
    super.initState();

    // 既存のストロークをポイントリストに変換
    List<Point> initialPoints = [];
    if (widget.whiteboard.strokes.isNotEmpty) {
      initialPoints =
          DrawingConverter.strokesToPoints(widget.whiteboard.strokes);
      AppLogger.info(
          '🎨 [WHITEBOARD] ${widget.whiteboard.strokes.length}個のストロークを復元 (${initialPoints.length}ポイント)');
    }

    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _selectedColor,
      points: initialPoints,
    );

    AppLogger.info('🎨 [WHITEBOARD] SignatureController初期化完了');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 保存処理
  Future<void> _saveWhiteboard() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      // 現在の描画をキャプチャ
      final strokes = DrawingConverter.captureFromSignatureController(
        controller: _controller,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Unknown',
        strokeColor: _selectedColor,
        strokeWidth: _strokeWidth,
      );

      // 既存のストロークと結合
      final updatedWhiteboard = widget.whiteboard.copyWith(
        strokes: [...widget.whiteboard.strokes, ...strokes],
        updatedAt: DateTime.now(),
      );

      // Firestoreに保存
      final repository = ref.read(whiteboardRepositoryProvider);
      await repository.updateWhiteboard(updatedWhiteboard);

      AppLogger.info('✅ ホワイトボード保存成功');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      }
    } catch (e) {
      AppLogger.error('❌ ホワイトボード保存エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// プライベート設定切り替え
  Future<void> _togglePrivate() async {
    try {
      final repository = ref.read(whiteboardRepositoryProvider);
      await repository.togglePrivate(widget.whiteboard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.whiteboard.isPrivate
                  ? '他の人も編集できるようになりました'
                  : '自分だけ編集できるようになりました',
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ プライベート設定エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final canEdit =
        currentUser != null && widget.whiteboard.canEdit(currentUser.uid);

    AppLogger.info(
        '🎨 [WHITEBOARD] build - canEdit: $canEdit, userId: ${currentUser?.uid}');
    AppLogger.info(
        '🎨 [WHITEBOARD] whiteboard - isPrivate: ${widget.whiteboard.isPrivate}, ownerId: ${widget.whiteboard.ownerId}');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.whiteboard.isGroupWhiteboard ? 'グループ共通ホワイトボード' : '個人用ホワイトボード',
        ),
        actions: [
          // プライベート設定スイッチ（個人用のみ）
          if (widget.whiteboard.isPersonalWhiteboard &&
              widget.whiteboard.ownerId == currentUser?.uid)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('編集制限', style: TextStyle(fontSize: 12)),
                Switch(
                  value: widget.whiteboard.isPrivate,
                  onChanged: (_) => _togglePrivate(),
                ),
              ],
            ),
          // 保存ボタン
          if (canEdit)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveWhiteboard,
              tooltip: '保存',
            ),
        ],
      ),
      body: canEdit
          ? Column(
              children: [
                // 描画ツールバー
                _buildToolbar(),
                // キャンバス
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Signature(
                      controller: _controller,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '編集権限がありません',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.whiteboard.isPrivate
                        ? 'このホワイトボードは${widget.whiteboard.ownerId}さん専用です'
                        : '閲覧のみ可能です',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
    );
  }

  /// 描画ツールバー
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        children: [
          // 色選択
          _buildColorButton(Colors.black),
          _buildColorButton(Colors.red),
          _buildColorButton(Colors.blue),
          _buildColorButton(Colors.green),
          _buildColorButton(Colors.yellow),
          _buildColorButton(Colors.orange),
          _buildColorButton(Colors.purple),
          const SizedBox(width: 16),
          // 線幅選択
          const Text('太さ:'),
          Slider(
            value: _strokeWidth,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            label: _strokeWidth.toStringAsFixed(0),
            onChanged: (value) {
              setState(() {
                _strokeWidth = value;
                // SignatureControllerは再作成が必要
                final points = _controller.points;
                _controller.dispose();
                _controller = SignatureController(
                  penStrokeWidth: value,
                  penColor: _selectedColor,
                  points: points,
                );
              });
            },
          ),
          const Spacer(),
          // 消去ボタン
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _controller.clear(),
            tooltip: '全消去',
          ),
        ],
      ),
    );
  }

  /// 色選択ボタン
  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          // SignatureControllerは再作成が必要
          final points = _controller.points;
          _controller.dispose();
          _controller = SignatureController(
            penStrokeWidth: _strokeWidth,
            penColor: color,
            points: points,
          );
        });
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
