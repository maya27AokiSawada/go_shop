import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../models/whiteboard.dart';
import '../providers/whiteboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/notification_service.dart';
import '../services/whiteboard_edit_lock_service.dart';
import '../utils/drawing_converter.dart';
import '../utils/app_logger.dart';

// 🔒 編集ロックサービスのプロバイダー
final whiteboardEditLockProvider = Provider<WhiteboardEditLock>((ref) {
  return WhiteboardEditLock();
});

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

  // 🔒 編集ロック状態
  bool _isEditingLocked = false; // 他ユーザーが編集中
  EditLockInfo? _currentEditor; // 現在の編集中ユーザー情報
  bool _hasEditLock = false; // 自分が編集ロックを保持中

  // スクロール用のコントローラー
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // キャンバスズーム倍率
  double _canvasScale = 1.0; // デフォルト等倍

  // スクロールロック（trueでスクロール無効、falseでスクロール有効）
  bool _isScrollLocked = false;

  // カスタム色（設定から読み込み、キャッシュする）
  late Color _customColor5;
  late Color _customColor6;

  @override
  void initState() {
    super.initState();

    // カスタム色を初期化（設定から読み込み）
    _customColor5 = _loadCustomColor5();
    _customColor6 = _loadCustomColor6();

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

    // 🔒 描画開始時に編集ロックをチェック
    _controller?.onDrawStart = () async {
      await _onDrawingStart();
    };

    // 🔒 編集ロック状態を監視
    _watchEditLock();

    // 🗑️ 古いeditLocksコレクションをクリーンアップ（マイグレーション対応）
    _cleanupLegacyLocks();

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

    // 🔒 編集ロックを解除
    _releaseEditLock();

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

  /// 🔒 編集ロック状態をリアルタイム監視
  void _watchEditLock() {
    final lockService = ref.read(whiteboardEditLockProvider);
    lockService
        .watchEditLock(
      groupId: widget.groupId,
      whiteboardId: widget.whiteboard.whiteboardId,
    )
        .listen((lockInfo) {
      if (!mounted) return;

      setState(() {
        _currentEditor = lockInfo;

        final currentUser = ref.read(authStateProvider).value;
        final isMyLock = lockInfo?.userId == currentUser?.uid;

        _isEditingLocked = lockInfo != null && !isMyLock;
        _hasEditLock = lockInfo != null && isMyLock;
      });

      if (lockInfo != null && !_isEditingLocked) {
        AppLogger.info(
            '🔒 [LOCK] 編集ロック検出: ${AppLogger.maskName(lockInfo.userName)}');
      }
    });
  }

  /// 🔒 編集ロックを取得
  Future<bool> _acquireEditLock() async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return false;

    final lockService = ref.read(whiteboardEditLockProvider);
    final success = await lockService.acquireEditLock(
      groupId: widget.groupId,
      whiteboardId: widget.whiteboard.whiteboardId,
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'Unknown',
    );

    if (success) {
      setState(() {
        _hasEditLock = true;
        _isEditingLocked = false;
      });
    }

    return success;
  }

  /// 🔓 編集ロックを解除
  Future<void> _releaseEditLock() async {
    if (!_hasEditLock) return;

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    final lockService = ref.read(whiteboardEditLockProvider);
    await lockService.releaseEditLock(
      groupId: widget.groupId,
      whiteboardId: widget.whiteboard.whiteboardId,
      userId: currentUser.uid,
    );

    setState(() {
      _hasEditLock = false;
    });
  }

  /// �️ 古いeditLocksコレクションをクリーンアップ（マイグレーション対応）
  Future<void> _cleanupLegacyLocks() async {
    try {
      final lockService = ref.read(whiteboardEditLockProvider);
      final deletedCount = await lockService.cleanupLegacyEditLocks(
        groupId: widget.groupId,
      );

      if (deletedCount > 0) {
        AppLogger.info('🗑️ [WHITEBOARD] 古いロック${deletedCount}件を削除');
      }
    } catch (e) {
      AppLogger.error('❌ [WHITEBOARD] 古いロッククリーンアップエラー: $e');
    }
  }

  /// 💀 編集ロックを強制クリア（緊急時用）
  Future<void> _forceReleaseEditLock() async {
    // 確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('ロック強制解除'),
          ],
        ),
        content: const Text(
          '編集ロックを強制的に解除します。\n'
          '他のユーザーが実際に編集中の場合、作業が失われる可能性があります。\n\n'
          '本当に実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('強制解除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final lockService = ref.read(whiteboardEditLockProvider);
      final success = await lockService.forceReleaseEditLock(
        groupId: widget.groupId,
        whiteboardId: widget.whiteboard.whiteboardId,
      );

      if (success) {
        AppLogger.info('💀 [WHITEBOARD] 編集ロック強制解除成功');

        // ローカル状態をクリア
        setState(() {
          _currentEditor = null;
          _isEditingLocked = false;
          _hasEditLock = false;
        });

        // 成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('編集ロックを強制解除しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('強制解除に失敗しました');
      }
    } catch (e) {
      AppLogger.error('❌ [WHITEBOARD] 編集ロック強制解除エラー: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ロック解除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// �📱 編集開始時にロック取得を試行
  Future<void> _onDrawingStart() async {
    if (_hasEditLock) return; // 既にロック保持中

    final success = await _acquireEditLock();
    if (!success && _isEditingLocked) {
      // 編集中ユーザーがいる場合はダイアログ表示
      _showEditingInProgressDialog();
    }
  }

  /// ⚠️ 編集中ダイアログ表示
  void _showEditingInProgressDialog() {
    final editorName = _currentEditor?.userName ?? '他のユーザー';
    final remainingTime = _currentEditor?.remainingTimeText ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.orange),
            SizedBox(width: 8),
            Text('編集中'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLogger.maskName(editorName)} が編集中です'),
            const SizedBox(height: 8),
            Text('編集ロック: $remainingTime'),
            const SizedBox(height: 16),
            const Text(
              '他のユーザーが編集を完了するまでお待ちください。',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
        scale: _canvasScale, // スケーリング係数を渡す
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

  /// 保存処理（🔥 差分ストローク追加方式）
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
        scale: _canvasScale, // スケーリング係数を渡す
      );

      // 🔥 新しいストローク = 作業中ストローク + 現在の描画
      final newStrokes = [..._workingStrokes, ...currentStrokes];

      if (newStrokes.isEmpty) {
        AppLogger.info('📋 [SAVE] 新しいストロークなし、保存をスキップ');
        setState(() => _isSaving = false);
        return;
      }

      // 🔥 差分ストローク追加でFirestoreに安全に保存
      final repository = ref.read(whiteboardRepositoryProvider);
      await repository.addStrokesToWhiteboard(
        groupId: widget.groupId,
        whiteboardId: widget.whiteboard.whiteboardId,
        newStrokes: newStrokes,
      );

      AppLogger.info('✅ ホワイトボード差分保存成功: ${newStrokes.length}個のストローク');

      // 🔥 保存成功後は作業ストロークをクリア & SignatureControllerをリセット
      _workingStrokes.clear();
      _controller?.clear();

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
                        child: Container(
                          width: _fixedCanvasWidth * _canvasScale,
                          height: _fixedCanvasHeight * _canvasScale,
                          color: Colors.white,
                          child: Stack(
                            children: [
                              // グリッド線（最背面）- スケーリングされたサイズに合わせる
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: GridPainter(
                                    gridSize: 50.0 *
                                        _canvasScale, // ズームに応じてグリッドサイズも変更
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              // 背景：保存済みストロークを描画（スケーリング付き）
                              Positioned.fill(
                                child: Transform.scale(
                                  scale: _canvasScale,
                                  alignment: Alignment.topLeft,
                                  child: CustomPaint(
                                    size: const Size(
                                        _fixedCanvasWidth, _fixedCanvasHeight),
                                    painter:
                                        DrawingStrokePainter(_workingStrokes),
                                  ),
                                ),
                              ),
                              // 前景：現在の描画セッション（編集可能な場合のみ）
                              if (canEdit)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    ignoring:
                                        !_isScrollLocked, // スクロールロック時のみ描画可能
                                    child: SizedBox(
                                      width: _fixedCanvasWidth * _canvasScale,
                                      height: _fixedCanvasHeight * _canvasScale,
                                      child: Signature(
                                        key: ValueKey(
                                            'signature_$_controllerKey'),
                                        controller: _controller!,
                                        backgroundColor: Colors.transparent,
                                      ),
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
                const SizedBox(width: 16),

                // 🔒 編集ロック状態表示
                _buildEditLockStatus(),
                const SizedBox(width: 16),

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
                    if (_canvasScale > 0.5) {
                      // 現在の描画を保存
                      _captureCurrentDrawing();

                      setState(() {
                        _canvasScale -= 0.5;
                        print('🔍 ズームアウト: ${_canvasScale}x');

                        // コントローラーを再作成（ペン幅をスケーリングに合わせる）
                        _controller?.dispose();
                        _controller = SignatureController(
                          penStrokeWidth: _strokeWidth * _canvasScale,
                          penColor: _selectedColor,
                        );
                        // 🔒 描画開始時に編集ロックをチェック
                        _controller?.onDrawStart = () async {
                          await _onDrawingStart();
                        };
                        _controllerKey++;
                      });
                    }
                  },
                  tooltip: 'ズームアウト',
                ),
                // ズーム倍率表示
                Text('${_canvasScale.toStringAsFixed(1)}x'),
                // ズームイン
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: () {
                    if (_canvasScale < 4.0) {
                      // 現在の描画を保存
                      _captureCurrentDrawing();

                      setState(() {
                        _canvasScale += 0.5;
                        print('🔍 ズームイン: ${_canvasScale}x');

                        // コントローラーを再作成（ペン幅をスケーリングに合わせる）
                        _controller?.dispose();
                        _controller = SignatureController(
                          penStrokeWidth: _strokeWidth * _canvasScale,
                          penColor: _selectedColor,
                        );
                        // 🔒 描画開始時に編集ロックをチェック
                        _controller?.onDrawStart = () async {
                          await _onDrawingStart();
                        };
                        _controllerKey++;
                      });
                    }
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

  /// 🔒 編集ロック状態表示ウィジェット
  Widget _buildEditLockStatus() {
    if (_currentEditor == null) {
      return const SizedBox.shrink();
    }

    final isMyLock = _hasEditLock;
    final editorName = AppLogger.maskName(_currentEditor!.userName);
    final remainingMinutes = _currentEditor!.remainingMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMyLock ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyLock ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMyLock ? Icons.edit : Icons.lock,
            size: 14,
            color: isMyLock ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isMyLock ? '編集中' : '$editorName編集中',
            style: TextStyle(
              fontSize: 10,
              color: isMyLock ? Colors.green.shade800 : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (remainingMinutes > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$remainingMinutes分',
              style: TextStyle(
                fontSize: 9,
                color:
                    isMyLock ? Colors.green.shade600 : Colors.orange.shade600,
              ),
            ),
          ],
          // 💀 強制ロッククリアボタン（編集中表示がある場合のみ）
          if (!isMyLock) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _forceReleaseEditLock(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.clear,
                  size: 12,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// カスタム色5を読み込み（初期化時のみ）
  Color _loadCustomColor5() {
    final settings = ref.read(userSettingsProvider).value;
    if (settings != null && settings.whiteboardColor5 != 0) {
      return Color(settings.whiteboardColor5);
    }
    return Colors.blue; // デフォルト：青
  }

  /// カスタム色6を読み込み（初期化時のみ）
  Color _loadCustomColor6() {
    final settings = ref.read(userSettingsProvider).value;
    if (settings != null && settings.whiteboardColor6 != 0) {
      return Color(settings.whiteboardColor6);
    }
    return Colors.orange; // デフォルト：オレンジ
  }

  /// カスタム色5を取得（キャッシュから）
  Color _getCustomColor5() => _customColor5;

  /// カスタム色6を取得（キャッシュから）
  Color _getCustomColor6() => _customColor6;

  /// 色選択ボタン
  Widget _buildColorButton(Color color) {
    // 色の比較はvalueで行う（インスタンスではなく色値で比較）
    final isSelected = _selectedColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          // 現在の描画を保存
          _captureCurrentDrawing();

          _selectedColor = color;
          // SignatureControllerは再作成が必要（空でスタート）
          // ペン幅はスケーリングを考慮
          _controller?.dispose();
          _controller = SignatureController(
            penStrokeWidth: _strokeWidth * _canvasScale,
            penColor: color,
          );
          // 🔒 描画開始時に編集ロックをチェック
          _controller?.onDrawStart = () async {
            await _onDrawingStart();
          };
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
          // ペン幅はスケーリングを考慮
          _controller?.dispose();
          _controller = SignatureController(
            penStrokeWidth: width * _canvasScale,
            penColor: _selectedColor,
          );
          // 🔒 描画開始時に編集ロックをチェック
          _controller?.onDrawStart = () async {
            await _onDrawingStart();
          };
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
