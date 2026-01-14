import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/whiteboard.dart';
import '../providers/whiteboard_provider.dart';
import '../providers/auth_provider.dart';
import '../pages/whiteboard_editor_page.dart';
import '../utils/app_logger.dart';

/// グループ情報エリアに表示するホワイトボードプレビュー
class WhiteboardPreviewWidget extends ConsumerWidget {
  final String groupId;

  const WhiteboardPreviewWidget({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whiteboardAsync = ref.watch(groupWhiteboardProvider(groupId));
    final currentUser = ref.watch(authStateProvider).value;

    return whiteboardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        AppLogger.error('❌ ホワイトボードプレビューエラー: $error');
        return const SizedBox.shrink();
      },
      data: (whiteboard) {
        // ホワイトボードがまだ作成されていない場合は作成ボタン表示
        if (whiteboard == null) {
          return _buildCreateButton(context, ref);
        }

        // プレビュー表示
        return GestureDetector(
          onDoubleTap: () => _openEditor(context, ref, whiteboard),
          child: Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                // プレビュー画像（簡易版）
                Center(
                  child: whiteboard.strokes.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.draw, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'グループ共通ホワイトボード',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ダブルタップで編集',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        )
                      : CustomPaint(
                          size: Size.infinite,
                          painter: _WhiteboardPreviewPainter(whiteboard),
                        ),
                ),
                // 右上に編集アイコン
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${whiteboard.strokes.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ホワイトボード作成ボタン
  Widget _buildCreateButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onDoubleTap: () => _createAndOpenWhiteboard(context, ref),
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.blue[200]!, width: 2, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 40, color: Colors.blue[700]),
              const SizedBox(height: 8),
              Text(
                'グループ共通ホワイトボードを作成',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ダブルタップで作成',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ホワイトボード作成＆編集画面を開く
  Future<void> _createAndOpenWhiteboard(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final repository = ref.read(whiteboardRepositoryProvider);
      final whiteboard = await repository.createWhiteboard(
        groupId: groupId,
        ownerId: null, // グループ共通
      );

      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WhiteboardEditorPage(
              whiteboard: whiteboard,
              groupId: groupId,
            ),
          ),
        );

        // 画面から戻ったらプロバイダーを更新
        ref.invalidate(groupWhiteboardProvider(groupId));
      }
    } catch (e) {
      AppLogger.error('❌ ホワイトボード作成エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('作成に失敗しました: $e')),
        );
      }
    }
  }

  /// 編集画面を開く
  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Whiteboard whiteboard,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhiteboardEditorPage(
          whiteboard: whiteboard,
          groupId: groupId,
        ),
      ),
    );

    // 画面から戻ったらプロバイダーを更新
    ref.invalidate(groupWhiteboardProvider(groupId));
  }
}

/// ホワイトボードプレビュー描画用CustomPainter
class _WhiteboardPreviewPainter extends CustomPainter {
  final Whiteboard whiteboard;

  _WhiteboardPreviewPainter(this.whiteboard);

  @override
  void paint(Canvas canvas, Size size) {
    // スケール計算（キャンバスサイズに合わせる）
    final scaleX = size.width / whiteboard.canvasWidth;
    final scaleY = size.height / whiteboard.canvasHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    for (final stroke in whiteboard.strokes) {
      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final points =
          stroke.points.map((p) => Offset(p.x * scale, p.y * scale)).toList();

      if (points.length < 2) continue;

      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPreviewPainter oldDelegate) {
    return whiteboard.strokes.length != oldDelegate.whiteboard.strokes.length;
  }
}
