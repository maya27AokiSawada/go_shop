import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/whiteboard.dart';
import '../providers/whiteboard_provider.dart';
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
    // 🔥 StreamProviderに変更してリアルタイム同期を実現
    final whiteboardAsync = ref.watch(watchGroupWhiteboardProvider(groupId));

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

        // 🔍 デバッグログ: プレビュー表示時のホワイトボード情報
        AppLogger.info(
            '🎨 [PREVIEW] ホワイトボードプレビューリアルタイム更新 - whiteboardId: ${whiteboard.whiteboardId}');
        AppLogger.info(
            '🎨 [PREVIEW] ownerId: ${AppLogger.maskUserId(whiteboard.ownerId)}, strokes: ${whiteboard.strokes.length}件');

        // プレビュー表示
        return GestureDetector(
          onDoubleTap: () => _openEditor(context, ref, whiteboard),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 200, // タブレット対応：最大高さ200px
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9, // 1280:720 = 16:9
                child: Stack(
                  children: [
                    // プレビュー画像（簡易版）
                    Center(
                      child: whiteboard.strokes.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.draw,
                                    size: 40, color: Colors.grey[400]),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.blue[200]!, width: 2, style: BorderStyle.solid),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 200, // タブレット対応：最大高さ200px
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9, // 1280:720 = 16:9
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 40, color: Colors.blue[700]),
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
      AppLogger.info(
          '🎨 [CREATE] グループ共通ホワイトボード作成開始 - groupId: $groupId, ownerId: null');

      final whiteboard = await repository.createWhiteboard(
        groupId: groupId,
        ownerId: null, // グループ共通
      );

      AppLogger.info(
          '🎨 [CREATE] 作成完了 - whiteboardId: ${whiteboard.whiteboardId}, ownerId: ${AppLogger.maskUserId(whiteboard.ownerId)}');
      AppLogger.info(
          '🎨 [CREATE] isGroupWhiteboard: ${whiteboard.isGroupWhiteboard}');

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
        // 🔥 StreamProviderを使用しているため、自動的に新規ホワイトボードが検知される
        AppLogger.info('✅ [PREVIEW] ホワイトボード作成完了 - リアルタイム同期開始');
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

    // 🔥 StreamProviderを使用しているため、手動でinvalidateは不要
    // Firestore snapshotsが自動的に変更を検知してUIを更新する
    AppLogger.info('✅ [PREVIEW] エディターから戻りました - リアルタイム同期継続中');
  }
}

/// ホワイトボードプレビュー描画用CustomPainter
class _WhiteboardPreviewPainter extends CustomPainter {
  final Whiteboard whiteboard;

  _WhiteboardPreviewPainter(this.whiteboard);

  @override
  void paint(Canvas canvas, Size size) {
    // 🔥 修正: プレビューサイズに合わせたスケール計算
    // キャンバスサイズ（1280x720）をプレビューサイズに正確にフィット
    final scaleX = size.width / whiteboard.canvasWidth;
    final scaleY = size.height / whiteboard.canvasHeight;

    // 🔥 重要: プレビューは16:9のアスペクト比で表示されるため
    // X軸とY軸で同じスケール値を使用（アスペクト比維持）
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // 🔥 中央配置のためのオフセット計算
    final scaledCanvasWidth = whiteboard.canvasWidth * scale;
    final scaledCanvasHeight = whiteboard.canvasHeight * scale;
    final offsetX = (size.width - scaledCanvasWidth) / 2;
    final offsetY = (size.height - scaledCanvasHeight) / 2;

    // 🔥 デバッグログ: スケール情報
    AppLogger.info('🎨 [PREVIEW_PAINT] size: ${size.width}x${size.height}');
    AppLogger.info(
        '🎨 [PREVIEW_PAINT] canvas: ${whiteboard.canvasWidth}x${whiteboard.canvasHeight}');
    AppLogger.info(
        '🎨 [PREVIEW_PAINT] scale: $scale, offset: ($offsetX, $offsetY)');

    // 🔥 クリッピング: 描画がプレビュー範囲を超えないよう制限
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 🔥 背景を白で塗りつぶし（キャンバスと同じ）
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, scaledCanvasWidth, scaledCanvasHeight),
      Paint()..color = Colors.white,
    );

    for (final stroke in whiteboard.strokes) {
      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // 🔥 座標変換: オフセットを適用して中央配置
      final points = stroke.points
          .map((p) => Offset(p.x * scale + offsetX, p.y * scale + offsetY))
          .toList();

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
