import 'package:flutter/material.dart';

/// ホワイトボードエディターのツールバーウィジェット（2段構成）
///
/// 色選択・ペン太さ・Undo/Redo・ズーム・消去ボタンを提供する。
/// すべてのアクションはコールバック経由で親ウィジェットへ委譲する。
class WhiteboardToolbar extends StatelessWidget {
  final Color selectedColor;
  final double strokeWidth;
  final bool canUndo;
  final bool canRedo;
  final bool isScrollLocked;
  final bool isTogglingMode;
  final double canvasScale;
  final Color customColor5;
  final Color customColor6;

  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onToggleScrollMode;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onClearWhiteboard;

  const WhiteboardToolbar({
    super.key,
    required this.selectedColor,
    required this.strokeWidth,
    required this.canUndo,
    required this.canRedo,
    required this.isScrollLocked,
    required this.isTogglingMode,
    required this.canvasScale,
    required this.customColor5,
    required this.customColor6,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleScrollMode,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onClearWhiteboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上段：色選択（6色） + スクロール/描画モード切り替え
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 🔄 モード切り替えボタン（左側に配置して常に見えるように）
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: isTogglingMode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isScrollLocked ? Icons.brush : Icons.open_with,
                          color: isScrollLocked
                              ? Colors.blue
                              : Colors.red.shade600,
                          size: 20,
                        ),
                  onPressed: isTogglingMode ? null : onToggleScrollMode,
                  tooltip: isScrollLocked ? '描画モード（筆）' : 'スクロールモード（十字）',
                ),
                const SizedBox(width: 12),
                const Text('色:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 4),
                _buildColorButton(Colors.black),
                _buildColorButton(Colors.red),
                _buildColorButton(Colors.green),
                _buildColorButton(Colors.yellow),
                _buildColorButton(customColor5),
                _buildColorButton(customColor6),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 下段：線幅3段階 + Undo/Redo + ズーム + 消去
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // ペン太さ3段階（細・中・太）
                _buildStrokeWidthButton(2.0, 1, label: '細'),
                _buildStrokeWidthButton(4.0, 2, label: '中'),
                _buildStrokeWidthButton(6.0, 3, label: '太'),
                const SizedBox(width: 16),
                // Undoボタン
                IconButton(
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: canUndo ? onUndo : null,
                  tooltip: !canUndo ? 'これ以上戻せません' : '元に戻す',
                ),
                // Redoボタン
                IconButton(
                  icon: const Icon(Icons.redo, size: 20),
                  onPressed: canRedo ? onRedo : null,
                  tooltip: !canRedo ? 'これ以上進めません' : 'やり直す',
                ),
                const SizedBox(width: 16),
                // ズームアウト
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 20),
                  onPressed: canvasScale > 0.5 ? onZoomOut : null,
                  tooltip: 'ズームアウト',
                ),
                // ズーム倍率表示
                Text('${canvasScale.toStringAsFixed(1)}x'),
                // ズームイン
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: canvasScale < 4.0 ? onZoomIn : null,
                  tooltip: 'ズームイン',
                ),
                const SizedBox(width: 16),
                // 消去ボタン
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onClearWhiteboard,
                  tooltip: '全消去',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    // 色の比較は toARGB32() で行う（.value は deprecated）
    final isSelected = selectedColor.toARGB32() == color.toARGB32();

    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
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

  Widget _buildStrokeWidthButton(double width, int level, {String? label}) {
    final isSelected = strokeWidth == width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Container(
              width: 8.0 + (level * 3),
              height: 8.0 + (level * 3),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            onPressed: () => onStrokeWidthChanged(width),
            tooltip: '太さ $level',
          ),
          if (label != null)
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}
