import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../models/whiteboard.dart';
import '../providers/whiteboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/notification_service.dart';
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
  // 固定キャンバスサイズ（16:9比率 - 横長）
  static const double _fixedCanvasWidth = 1280.0;
  static const double _fixedCanvasHeight = 720.0;

  SignatureController? _controller;
  bool _isSaving = false;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  int _controllerKey = 0; // コントローラー再作成カウンター
  final List<DrawingStroke> _workingStrokes = []; // 作業中のストロークリスト

  // スクロール用のコントローラー
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // キャンバスズーム倍率
  double _canvasScale = 1.0; // デフォルト等倍

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

    // 初期スクロール位置を中央に設定（画面構築後に実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCenter();
    });

    AppLogger.info('🎨 [WHITEBOARD] SignatureController初期化完了');
  }

  @override
  void dispose() {
    _controller?.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  /// スクロール位置を中央に移動
  void _scrollToCenter() {
    if (!_horizontalScrollController.hasClients ||
        !_verticalScrollController.hasClients) {
      return;
    }

    try {
      // 横スクロールを中央に
      final maxHorizontalScroll =
          _horizontalScrollController.position.maxScrollExtent;
      if (maxHorizontalScroll > 0) {
        _horizontalScrollController.jumpTo(maxHorizontalScroll / 2);
      }

      // 縦スクロールを中央に
      final maxVerticalScroll =
          _verticalScrollController.position.maxScrollExtent;
      if (maxVerticalScroll > 0) {
        _verticalScrollController.jumpTo(maxVerticalScroll / 2);
      }

      AppLogger.info('📍 [WHITEBOARD] スクロール位置を中央に設定');
    } catch (e) {
      AppLogger.error('❌ [WHITEBOARD] スクロール中央設定エラー: $e');
    }
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

      // 🔔 他メンバーに更新通知を送信
      try {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.sendWhiteboardUpdateNotification(
          groupId: widget.groupId,
          whiteboardId: widget.whiteboard.whiteboardId,
          isGroupWhiteboard: widget.whiteboard.isGroupWhiteboard,
          ownerId: widget.whiteboard.ownerId,
        );
        AppLogger.info('✅ ホワイトボード更新通知送信完了');
      } catch (notificationError) {
        // 通知送信エラーは無視（保存自体は成功している）
        AppLogger.error('⚠️ 通知送信エラー（保存は成功）: $notificationError');
      }

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
        '🎨 [WHITEBOARD] build - canEdit: $canEdit, userId: ${AppLogger.maskUserId(currentUser?.uid)}');
    AppLogger.info(
        '🎨 [WHITEBOARD] whiteboard - isPrivate: ${widget.whiteboard.isPrivate}, ownerId: ${AppLogger.maskUserId(widget.whiteboard.ownerId)}');
    AppLogger.info(
        '🎨 [WHITEBOARD] isGroupWhiteboard: ${widget.whiteboard.isGroupWhiteboard}, isPersonalWhiteboard: ${widget.whiteboard.isPersonalWhiteboard}');
    AppLogger.info(
        '🎨 [WHITEBOARD] AppBar title will be: ${widget.whiteboard.isGroupWhiteboard ? "グループ共通" : "個人用"}');

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
      body: Column(
        children: [
          // 編集可能な場合のみツールバー表示
          if (canEdit) _buildToolbar(),

          // キャンバス（閲覧専用または編集可能）
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
                      physics: _isScrollLocked && canEdit
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        scrollDirection: Axis.vertical,
                        physics: _isScrollLocked && canEdit
                            ? const NeverScrollableScrollPhysics()
                            : const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          width: _fixedCanvasWidth * _canvasScale,
                          height: _fixedCanvasHeight * _canvasScale,
                          child: Transform.scale(
                            scale: _canvasScale,
                            alignment: Alignment.topLeft,
                            child: Container(
                              width: _fixedCanvasWidth,
                              height: _fixedCanvasHeight,
                              color: Colors.white,
                              child: Stack(
                                children: [
                                  // グリッド線（最背面）
                                  _buildGridOverlay(constraints.maxWidth,
                                      constraints.maxHeight),
                                  // 背景：保存済みストロークを描画
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter:
                                          DrawingStrokePainter(_workingStrokes),
                                    ),
                                  ),
                                  // 前景：現在の描画セッション（編集可能な場合のみ）
                                  if (canEdit)
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
                    ),
                  ),
                );
              },
            ),
          ),

          // 閲覧専用インジケーター
          if (!canEdit)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.orange[900]),
                  const SizedBox(width: 8),
                  Text(
                    widget.whiteboard.isPrivate
                        ? '閲覧専用: このホワイトボードは編集制限されています'
                        : '閲覧専用',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 描画ツールバー（2段構成）
  Widget _buildToolbar() {
    return Container(
      width: double.infinity, // 親の幅いっぱいに広げる
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
              mainAxisAlignment: MainAxisAlignment.start, // 左寄せ
              children: [
                const Text('色:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 4),
                _buildColorButton(Colors.black),
                _buildColorButton(Colors.red),
                _buildColorButton(Colors.green),
                _buildColorButton(Colors.yellow),
                _buildColorButton(_getCustomColor5()), // 設定から取得
                _buildColorButton(_getCustomColor6()), // 設定から取得
                const SizedBox(width: 16), // Spacerの代わりに固定幅
                // スクロール/描画モード切り替えボタン
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isScrollLocked ? Icons.brush : Icons.open_with,
                    color: _isScrollLocked ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isScrollLocked = !_isScrollLocked;
                    });
                  },
                  tooltip: _isScrollLocked ? '描画モード（筆）' : 'スクロールモード（十字）',
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 下段：線幅5段階 + ズーム + 消去
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start, // 左寄せ
              children: [
                // ペン太さ5段階
                _buildStrokeWidthButton(1.0, 1),
                _buildStrokeWidthButton(2.0, 2),
                _buildStrokeWidthButton(4.0, 3),
                _buildStrokeWidthButton(6.0, 4),
                _buildStrokeWidthButton(8.0, 5),
                const SizedBox(width: 16),
                // ズームアウト
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 20),
                  onPressed: () {
                    setState(() {
                      if (_canvasScale > 0.5) {
                        _canvasScale -= 0.5;
                        print('🔍 ズームアウト: ${_canvasScale}x');
                      }
                    });
                  },
                  tooltip: 'ズームアウト',
                ),
                // ズーム倍率表示
                Text('${_canvasScale.toStringAsFixed(1)}x'),
                // ズームイン
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: () {
                    setState(() {
                      if (_canvasScale < 4.0) {
                        _canvasScale += 0.5;
                        print('🔍 ズームイン: ${_canvasScale}x');
                      }
                    });
                  },
                  tooltip: 'ズームイン',
                ),
                const SizedBox(width: 16), // Spacerの代わりに固定幅
                // 消去ボタン
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, size: 20),
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

  /// カスタム色5を取得（設定から）
  Color _getCustomColor5() {
    final settings = ref.watch(userSettingsProvider).value;
    if (settings != null && settings.whiteboardColor5 != 0) {
      return Color(settings.whiteboardColor5);
    }
    return Colors.blue; // デフォルト：青
  }

  /// カスタム色6を取得（設定から）
  Color _getCustomColor6() {
    final settings = ref.watch(userSettingsProvider).value;
    if (settings != null && settings.whiteboardColor6 != 0) {
      return Color(settings.whiteboardColor6);
    }
    return Colors.orange; // デフォルト：オレンジ
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

  /// ペン太さボタン（5段階）
  Widget _buildStrokeWidthButton(double width, int level) {
    final isSelected = _strokeWidth == width;
    return IconButton(
      icon: Container(
        width: 8.0 + (level * 2),
        height: 8.0 + (level * 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
      onPressed: () {
        setState(() {
          // 現在の描画を保存
          _captureCurrentDrawing();
          _strokeWidth = width;
          // SignatureControllerは再作成が必要（空でスタート）
          _controller?.dispose();
          _controller = SignatureController(
            penStrokeWidth: width,
            penColor: _selectedColor,
          );
          _controllerKey++; // キー更新でウィジェット再構築
        });
      },
      tooltip: '太さ $level',
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
