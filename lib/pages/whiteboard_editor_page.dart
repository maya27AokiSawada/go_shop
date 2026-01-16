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
  SignatureController? _controller;
  bool _isSaving = false;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  int _controllerKey = 0; // コントローラー再作成カウンター
  final List<DrawingStroke> _workingStrokes = []; // 作業中のストロークリスト

  // スクロール用のコントローラー
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // キャンバスサイズ（デバイス画面サイズの倍数）
  double _canvasScale = 2.0; // 2倍のキャンバスサイズ

  // スクロールロック（trueでスクロール無効、falseでスクロール有効）
  bool _isScrollLocked = false;

  @override
  void initState() {
    super.initState();

    // 既存のストロークを作業リストに読み込む
    if (widget.whiteboard.strokes.isNotEmpty) {
      _workingStrokes.addAll(widget.whiteboard.strokes);
      AppLogger.info(
          '🎨 [WHITEBOARD] ${widget.whiteboard.strokes.length}個のストロークを復元');
    }

    // 空のコントローラーでスタート
    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _selectedColor,
    );

    AppLogger.info('🎨 [WHITEBOARD] SignatureController初期化完了');
  }

  @override
  void dispose() {
    _controller?.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  /// 現在の描画をキャプチャして_workingStrokesに追加
  void _captureCurrentDrawing() {
    if (_controller == null || _controller!.isEmpty) {
      return; // 何も描かれていなければスキップ
    }

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    try {
      // 現在の描画をキャプチャ
      final strokes = DrawingConverter.captureFromSignatureController(
        controller: _controller!,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Unknown',
        strokeColor: _selectedColor,
        strokeWidth: _strokeWidth,
      );

      // 作業リストに追加
      if (strokes.isNotEmpty) {
        _workingStrokes.addAll(strokes);
        AppLogger.info(
            '📸 [WHITEBOARD] ${strokes.length}個のストロークをキャプチャ (計${_workingStrokes.length}個)');
      }
    } catch (e) {
      AppLogger.error('❌ [WHITEBOARD] 描画キャプチャエラー: $e');
    }
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
      final currentStrokes = DrawingConverter.captureFromSignatureController(
        controller: _controller!,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Unknown',
        strokeColor: _selectedColor,
        strokeWidth: _strokeWidth,
      );

      // 作業中のストロークと現在の描画を結合
      final allStrokes = [..._workingStrokes, ...currentStrokes];

      final updatedWhiteboard = widget.whiteboard.copyWith(
        strokes: allStrokes,
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
                // キャンバス（スクロール可能）
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // キャンバスの実際のサイズを計算
                      final canvasWidth = constraints.maxWidth * _canvasScale;
                      final canvasHeight = constraints.maxHeight * _canvasScale;

                      return Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: true, // 常にスクロールバーを表示
                        trackVisibility: true,
                        child: Scrollbar(
                          controller: _verticalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          notificationPredicate: (notification) =>
                              notification.depth == 1,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: _isScrollLocked
                                ? const NeverScrollableScrollPhysics()
                                : const AlwaysScrollableScrollPhysics(),
                            child: SingleChildScrollView(
                              controller: _verticalScrollController,
                              scrollDirection: Axis.vertical,
                              physics: _isScrollLocked
                                  ? const NeverScrollableScrollPhysics()
                                  : const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                width: canvasWidth,
                                height: canvasHeight,
                                color: Colors.white,
                                child: Stack(
                                  children: [
                                    // グリッド線（最背面）
                                    _buildGridOverlay(
                                        canvasWidth, canvasHeight),
                                    // 背景：保存済みストロークを描画
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: DrawingStrokePainter(
                                            _workingStrokes),
                                      ),
                                    ),
                                    // 前景：現在の描画セッション（最前面）
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        ignoring:
                                            !_isScrollLocked, // スクロールロック時のみ描画可能
                                        child: Signature(
                                          key: ValueKey(
                                              'signature_$_controllerKey'),
                                          controller: _controller!,
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

  /// 描画ツールバー（2段構成）
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上段：色選択
          Row(
            children: [
              const Text('色:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildColorButton(Colors.black),
              _buildColorButton(Colors.red),
              _buildColorButton(Colors.blue),
              _buildColorButton(Colors.green),
              _buildColorButton(Colors.yellow),
              _buildColorButton(Colors.orange),
              _buildColorButton(Colors.purple),
            ],
          ),
          const SizedBox(height: 8),
          // 下段：線幅 + キャンバスサイズ + 消去ボタン
          Row(
            children: [
              const Text('太さ:'),
              Expanded(
                flex: 2,
                child: Slider(
                  value: _strokeWidth,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  label: _strokeWidth.toStringAsFixed(0),
                  onChanged: (value) {
                    setState(() {
                      // 現在の描画を保存
                      _captureCurrentDrawing();
                      _strokeWidth = value;
                      // SignatureControllerは再作成が必要（空でスタート）
                      _controller?.dispose();
                      _controller = SignatureController(
                        penStrokeWidth: value,
                        penColor: _selectedColor,
                      );
                      _controllerKey++; // キー更新でウィジェット再構築
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // キャンバスサイズ選択
              DropdownButton<double>(
                value: _canvasScale,
                items: const [
                  DropdownMenuItem(value: 1.0, child: Text('1x')),
                  DropdownMenuItem(value: 2.0, child: Text('2x')),
                  DropdownMenuItem(value: 3.0, child: Text('3x')),
                  DropdownMenuItem(value: 4.0, child: Text('4x')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _canvasScale = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              // スクロールロックボタン
              IconButton(
                icon: Icon(
                  _isScrollLocked ? Icons.lock : Icons.lock_open,
                  color: _isScrollLocked ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isScrollLocked = !_isScrollLocked;
                  });
                },
                tooltip: _isScrollLocked ? 'スクロール無効（描画モード）' : 'スクロール有効',
              ),
              const SizedBox(width: 8),
              // 消去ボタン
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    _workingStrokes.clear();
                    _controller!.clear();
                  });
                },
                tooltip: '全消去',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// グリッド線オーバーレイ（オプション）
  Widget _buildGridOverlay(double width, double height) {
    return CustomPaint(
      size: Size(width, height),
      painter: GridPainter(
        gridSize: 50.0, // 50pxごとにグリッド線
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  /// 色選択ボタン
  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          // 現在の描画を保存
          _captureCurrentDrawing();

          _selectedColor = color;
          // SignatureControllerは再作成が必要（空でスタート）
          _controller?.dispose();
          _controller = SignatureController(
            penStrokeWidth: _strokeWidth,
            penColor: color,
          );
          _controllerKey++; // キー更新でウィジェット再構築
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

/// 保存済みストロークを描画するCustomPainter
class DrawingStrokePainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  DrawingStrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // ストロークの各点を線で結ぶ
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(
          Offset(p1.x, p1.y),
          Offset(p2.x, p2.y),
          paint,
        );
      }

      // 単一点の場合は点を描画
      if (stroke.points.length == 1) {
        final p = stroke.points[0];
        canvas.drawCircle(
          Offset(p.x, p.y),
          stroke.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingStrokePainter oldDelegate) {
    return strokes != oldDelegate.strokes;
  }
}

/// グリッド線を描画するCustomPainter
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color color;

  GridPainter({
    required this.gridSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 縦線
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 横線
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return gridSize != oldDelegate.gridSize || color != oldDelegate.color;
  }
}
