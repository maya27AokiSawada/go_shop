import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

  // ↩️ Undo/Redo履歴管理
  final List<List<DrawingStroke>> _history = []; // 履歴スタック
  int _historyIndex = -1; // 現在の履歴位置

  // � CRITICAL: 最新のホワイトボードデータをStateで管理（isPrivate更新対応）
  late Whiteboard _currentWhiteboard;

  // �🔒 編集ロック状態
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

  // Firestoreリアルタイム監視
  StreamSubscription<Whiteboard?>? _whiteboardSubscription;

  @override
  void initState() {
    super.initState();

    // 🔥 CRITICAL: Stateにホワイトボードデータを保持
    _currentWhiteboard = widget.whiteboard;

    // カスタム色を初期化（設定から読み込み）
    _customColor5 = _loadCustomColor5();
    _customColor6 = _loadCustomColor6();

    // 既存のストロークを作業リストに読み込む
    if (_currentWhiteboard.strokes.isNotEmpty) {
      _workingStrokes.addAll(_currentWhiteboard.strokes);
      AppLogger.info(
          '🎨 [WHITEBOARD] ${_currentWhiteboard.strokes.length}個のストロークを復元');
    }

    // 📚 初期状態を履歴に保存
    _saveToHistory();

    // 空のコントローラーでスタート
    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _selectedColor,
    );

    AppLogger.info('✅ [INIT] SignatureController初期化完了 - モード切り替えによるロック制御');

    // Firestoreリアルタイム監視を開始（他端末更新の即時反映）
    _startWhiteboardListener();

    // 🔒 編集ロック状態を監視（グループ共有ボードのみ）
    AppLogger.info(
        '🎨 [WHITEBOARD] ボードタイプ: isGroupWhiteboard=${_currentWhiteboard.isGroupWhiteboard}, isPersonalWhiteboard=${_currentWhiteboard.isPersonalWhiteboard}');

    if (_currentWhiteboard.isGroupWhiteboard) {
      AppLogger.info('🔒 [LOCK] グループ共有ボード - 編集ロック機能を初期化');
      _watchEditLock();

      // 🗑️ 古いeditLocksコレクションをクリーンアップ（マイグレーション対応）
      _cleanupLegacyLocks();
    } else {
      AppLogger.info('👤 [PERSONAL] 個人ボード - 編集ロック機能をスキップ');
    }

    // 初期スクロール位置を中央に設定（画面構築後に実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCenter();
    });

    AppLogger.info('🎨 [WHITEBOARD] SignatureController初期化完了');
  }

  @override
  void dispose() {
    _whiteboardSubscription?.cancel();
    _controller?.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();

    // 🔒 編集ロックを解除（非同期だがdisposeでは待機しない）
    // WillPopScopeで事前に解除済みのはず
    if (_hasEditLock) {
      _releaseEditLock(); // Fire-and-forget（Windows版クラッシュ防止）
    }

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

  /// Firestoreのホワイトボードをリアルタイム監視してUIに反映
  void _startWhiteboardListener() {
    _whiteboardSubscription?.cancel();

    final repository = ref.read(whiteboardRepositoryProvider);

    _whiteboardSubscription = repository
        .watchWhiteboard(widget.groupId, _currentWhiteboard.whiteboardId)
        .listen((latest) {
      if (!mounted || latest == null) return;

      // 自分が編集中（ロック保持中）の場合は上書きしない
      if (_hasEditLock) return;

      setState(() {
        // 🔥 CRITICAL: ホワイトボード全体を更新（isPrivateなどのプロパティも含む）
        _currentWhiteboard = latest;

        _workingStrokes
          ..clear()
          ..addAll(latest.strokes);

        // 📚 Firestore更新後の状態を履歴に記録（他ユーザーの変更も履歴に含める）
        _saveToHistory();
      });

      AppLogger.info(
          '🛰️ [WHITEBOARD] Firestore最新ストロークを反映: ${latest.strokes.length}本');
    });
  }

  /// Firestoreから最新のホワイトボードを再取得（ロック解除直後などの明示的リロード用）
  Future<void> _reloadWhiteboardFromFirestore({String reason = ''}) async {
    try {
      final repository = ref.read(whiteboardRepositoryProvider);
      final latest = await repository.getWhiteboardById(
        widget.groupId,
        _currentWhiteboard.whiteboardId,
      );

      if (latest == null) return;
      if (_hasEditLock) return; // 自分が編集中なら上書きしない

      setState(() {
        // 🔥 CRITICAL: ホワイトボード全体を更新（isPrivateも含む）
        _currentWhiteboard = latest;

        _workingStrokes
          ..clear()
          ..addAll(latest.strokes);

        // 📚 リロード後の状態を履歴に記録
        _saveToHistory();

        _workingStrokes
          ..clear()
          ..addAll(latest.strokes);
      });

      AppLogger.info(
          '🔄 [WHITEBOARD] Firestoreから再取得して反映: ${latest.strokes.length}本 ${reason.isNotEmpty ? '($reason)' : ''}');
    } catch (e) {
      AppLogger.error('❌ [WHITEBOARD] Firestore再取得エラー: $e');
    }
  }

  /// 🔒 編集ロック状態をリアルタイム監視（グループ共有ボードのみ）
  void _watchEditLock() {
    AppLogger.info('🔒 [LOCK] 編集ロック監視開始 - グループ共有ボード');

    final lockService = ref.read(whiteboardEditLockProvider);
    lockService
        .watchEditLock(
      groupId: widget.groupId,
      whiteboardId: _currentWhiteboard.whiteboardId,
    )
        .listen((lockInfo) {
      if (!mounted) return;

      final wasLockedByOthers = _isEditingLocked;

      AppLogger.info(
          '🔒 [LOCK] ロック状態更新: ${lockInfo != null ? AppLogger.maskName(lockInfo.userName) : "ロックなし"}');

      setState(() {
        _currentEditor = lockInfo;

        final currentUser = ref.read(authStateProvider).value;
        final isMyLock = lockInfo?.userId == currentUser?.uid;

        _isEditingLocked = lockInfo != null && !isMyLock;
        _hasEditLock = lockInfo != null && isMyLock;

        AppLogger.info(
            '🔒 [LOCK] 状態: isEditingLocked=$_isEditingLocked, hasEditLock=$_hasEditLock');
      });

      if (lockInfo != null && !_isEditingLocked) {
        AppLogger.info(
            '🔒 [LOCK] 編集ロック検出: ${AppLogger.maskName(lockInfo.userName)}');
      }

      // 他ユーザーのロックが解除されたタイミングで最新データを明示的に取得
      if (wasLockedByOthers && !_isEditingLocked) {
        _reloadWhiteboardFromFirestore(reason: 'lock released');
      }
    });
  }

  /// 🔒 編集ロックを取得（グループ共有ボードのみ）
  Future<bool> _acquireEditLock() async {
    // 個人ボードでは編集ロックをスキップ
    if (_currentWhiteboard.isPersonalWhiteboard) {
      return true;
    }

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return false;

    AppLogger.info(
        '🔒 [LOCK] 編集ロック取得開始 - ${AppLogger.maskUserId(currentUser.uid)}');

    try {
      final lockService = ref.read(whiteboardEditLockProvider);
      final success = await lockService.acquireEditLock(
        groupId: widget.groupId,
        whiteboardId: _currentWhiteboard.whiteboardId,
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Unknown',
      );

      AppLogger.info('🔒 [LOCK] 編集ロック取得結果: $success');

      if (success && mounted) {
        setState(() {
          _hasEditLock = true;
          _isEditingLocked = false;
        });
      }

      return success;
    } catch (e) {
      AppLogger.error('❌ [LOCK] 編集ロック取得エラー: $e');
      return false;
    }
  }

  /// 🔓 編集ロックを解除
  Future<void> _releaseEditLock() async {
    // グループ共有ボードのみ編集ロック解除
    if (!_currentWhiteboard.isGroupWhiteboard || !_hasEditLock) return;

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    try {
      final lockService = ref.read(whiteboardEditLockProvider);
      await lockService.releaseEditLock(
        groupId: widget.groupId,
        whiteboardId: _currentWhiteboard.whiteboardId,
        userId: currentUser.uid,
      );

      // 🔥 CRITICAL: mountedチェック（dispose後のsetState呼び出し防止）
      if (mounted) {
        setState(() {
          _hasEditLock = false;
        });
      }
    } catch (e) {
      AppLogger.error('❌ [LOCK] 編集ロック解除エラー: $e');
    }
  }

  /// �️ 古いeditLocksコレクションをクリーンアップ（マイグレーション対応）
  /// 🔥 DEPRECATED: 権限不足のため無効化
  Future<void> _cleanupLegacyLocks() async {
    // 🔥 古いeditLocksコレクションのクリーンアップは不要
    // permission-deniedエラーを避けるため処理をスキップ
    AppLogger.info('⏭️ [WHITEBOARD] 古いロッククリーンアップはスキップ');
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
        whiteboardId: _currentWhiteboard.whiteboardId,
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

  /// 📱 編集開始時にロック取得を試行
  Future<bool> _onDrawingStart() async {
    AppLogger.info(
        '🎨 [ON_DRAW_START] 編集開始処理 - ボードタイプ: isPersonal=${_currentWhiteboard.isPersonalWhiteboard}, isGroup=${_currentWhiteboard.isGroupWhiteboard}');

    // 個人ボードでは編集ロックをスキップ
    if (_currentWhiteboard.isPersonalWhiteboard) {
      AppLogger.info('👤 [ON_DRAW_START] 個人ボード - 編集ロックスキップ');
      return true;
    }

    AppLogger.info(
        '🔒 [ON_DRAW_START] グループボード - 編集ロック状態: hasLock=$_hasEditLock, isLocked=$_isEditingLocked');

    if (_hasEditLock) {
      AppLogger.info('✅ [ON_DRAW_START] 既にロック保持中 - 描画許可');
      return true; // 既にロック保持中
    }

    AppLogger.info('🔄 [ON_DRAW_START] 編集ロック取得開始');
    final success = await _acquireEditLock();
    AppLogger.info('🔒 [ON_DRAW_START] 編集ロック取得結果: $success');

    if (!success) {
      // ロック取得に失敗した場合
      if (_isEditingLocked && _currentEditor != null) {
        // 編集中ユーザーがいる場合はダイアログ表示
        AppLogger.warning('⚠️ [ON_DRAW_START] 他ユーザー編集中 - ダイアログ表示');
        _showEditingInProgressDialog();
      } else {
        // その他のエラー（Firestore接続問題など）
        AppLogger.error('❌ [ON_DRAW_START] ロック取得エラー - スナックバー表示');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('編集ロックの取得に失敗しました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      return false; // 描画をブロック
    }

    return true; // 描画を許可
  }

  /// ⚠️ 編集中ダイアログ表示
  void _showEditingInProgressDialog() {
    final editorName = _currentEditor?.userName ?? '他のユーザー';

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
            const SizedBox(height: 16),
            const Text(
              '編集が終わるまでお待ちください。',
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

        // 📚 履歴に保存
        _saveToHistory();
      }
    } catch (e) {
      AppLogger.error('❌ [WHITEBOARD] 描画キャプチャエラー: $e');
    }
  }

  /// 📚 現在の状態を履歴に保存
  void _saveToHistory() {
    // 現在位置より後ろの履歴を削除（新しい分岐を作る）
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    // 現在の状態を履歴に追加
    _history.add(List<DrawingStroke>.from(_workingStrokes));
    _historyIndex = _history.length - 1;

    // 履歴が多すぎる場合は古いものを削除（メモリ節約）
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }

    AppLogger.info(
        '📚 [HISTORY] 履歴保存: ${_history.length}個 (現在位置: $_historyIndex)');
  }

  /// ↩️ Undo: 1つ前の状態に戻る
  void _undo() {
    if (!_canUndo()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('これ以上戻せません'), duration: Duration(milliseconds: 500)),
      );
      return;
    }

    // 🔥 FIX: _captureCurrentDrawing()を呼ばない（履歴破壊の原因）
    // 履歴システムが既に状態を管理しているため、現在の描画キャプチャは不要

    setState(() {
      _historyIndex--;
      _workingStrokes
        ..clear()
        ..addAll(_history[_historyIndex]);

      // SignatureControllerをクリア
      _controller?.clear();
    });

    AppLogger.info(
        '↩️ [UNDO] 履歴位置: $_historyIndex/${_history.length - 1}, ストローク数: ${_workingStrokes.length}');
  }

  /// ↪️ Redo: 1つ先の状態に進む
  void _redo() {
    if (!_canRedo()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('これ以上進めません'), duration: Duration(milliseconds: 500)),
      );
      return;
    }

    setState(() {
      _historyIndex++;
      _workingStrokes
        ..clear()
        ..addAll(_history[_historyIndex]);

      // SignatureControllerをクリア
      _controller?.clear();
    });

    AppLogger.info(
        '↪️ [REDO] 履歴位置: $_historyIndex/${_history.length - 1}, ストローク数: ${_workingStrokes.length}');
  }

  /// Undoが可能かチェック
  bool _canUndo() => _historyIndex > 0;

  /// Redoが可能かチェック
  bool _canRedo() => _historyIndex < _history.length - 1;

  /// 保存処理（🔥 差分ストローク追加方式）
  Future<void> _saveWhiteboard() async {
    if (_isSaving) return;

    // 🔥 CRITICAL: Windows版クラッシュ対策 - mounted チェックを徹底
    if (!mounted) return;

    AppLogger.info('💾 [SAVE] 保存処理開始');
    setState(() => _isSaving = true);

    try {
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      AppLogger.info('💾 [SAVE] ユーザー認証OK: ${currentUser.uid}');

      // 🔥 Windows版対策：controller null チェック
      if (_controller == null) {
        AppLogger.error('❌ [SAVE] SignatureController が null です');
        if (mounted) setState(() => _isSaving = false);
        return;
      }

      AppLogger.info('💾 [SAVE] 描画キャプチャ開始');

      // 現在の描画をキャプチャ
      final currentStrokes = DrawingConverter.captureFromSignatureController(
        controller: _controller!,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Unknown',
        strokeColor: _selectedColor,
        strokeWidth: _strokeWidth,
        scale: _canvasScale, // スケーリング係数を渡す
      );

      AppLogger.info('💾 [SAVE] キャプチャ完了: ${currentStrokes.length}個のストローク');

      // 🔥 新しいストローク = 作業中ストローク + 現在の描画
      final newStrokes = [..._workingStrokes, ...currentStrokes];

      AppLogger.info(
          '💾 [SAVE] 合計ストローク数: ${newStrokes.length} (作業中: ${_workingStrokes.length}, 新規: ${currentStrokes.length})');

      if (newStrokes.isEmpty) {
        AppLogger.info('📋 [SAVE] 新しいストロークなし、保存をスキップ');
        if (mounted) setState(() => _isSaving = false);
        return;
      }

      AppLogger.info('💾 [SAVE] Firestore保存開始...');

      // 🔥 差分ストローク追加でFirestoreに安全に保存
      final repository = ref.read(whiteboardRepositoryProvider);
      await repository.addStrokesToWhiteboard(
        groupId: widget.groupId,
        whiteboardId: _currentWhiteboard.whiteboardId,
        newStrokes: newStrokes,
      );

      AppLogger.info('✅ [SAVE] Firestore保存完了: ${newStrokes.length}個のストローク');

      // 🔥 Windows版対策: Firestore保存後にmountedチェック
      if (!mounted) return;

      // 🔥 保存成功後の処理
      // 1. 新しく保存されたストロークをworkingStrokesに保存（UIで表示するため）
      _workingStrokes.clear();
      _workingStrokes.addAll(newStrokes);
      AppLogger.info('📐 [SAVE] ${newStrokes.length}個のストロークをworkingStrokesに復元');

      // 📚 保存後の状態を履歴に記録
      _saveToHistory();

      // 2. SignatureControllerのみクリア（新規描画開始のため）
      _controller?.clear();

      // 3. 変更を反映（mounted チェック済み）
      setState(() {});

      // 🔔 他メンバーに更新通知を送信（Windows版ではスキップ）
      if (!Platform.isWindows) {
        try {
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.sendWhiteboardUpdateNotification(
            groupId: widget.groupId,
            whiteboardId: _currentWhiteboard.whiteboardId,
            isGroupWhiteboard: _currentWhiteboard.isGroupWhiteboard,
            ownerId: _currentWhiteboard.ownerId,
          );
          AppLogger.info('✅ ホワイトボード更新通知送信完了');
        } catch (notificationError) {
          // 通知送信エラーは無視（保存自体は成功している）
          AppLogger.error('⚠️ 通知送信エラー（保存は成功）: $notificationError');
        }
      } else {
        AppLogger.info('💻 [WINDOWS] 通知送信をスキップ（クラッシュ防止）');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ ホワイトボード保存エラー: $e');

      // 🔥 Sentry/Crashlyticsにエラー送信（Platform判定）
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Windows/Linux/macOS: Sentry
        try {
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
            hint: Hint.withMap({
              'whiteboard_id': _currentWhiteboard.whiteboardId,
              'group_id': widget.groupId,
              'stroke_count': _workingStrokes.length,
              'is_group_whiteboard': _currentWhiteboard.isGroupWhiteboard,
              'platform': Platform.operatingSystem,
            }),
          );
          AppLogger.info('📤 [Sentry] エラーレポート送信完了');
        } catch (sentryError) {
          AppLogger.error('⚠️ [Sentry] レポート送信失敗: $sentryError');
        }
      } else {
        // Android/iOS: Firebase Crashlytics
        FirebaseCrashlytics.instance.recordError(e, stackTrace);
        AppLogger.info('📤 [Crashlytics] エラーレポート送信完了');
      }

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

      // 現在の状態を保存（メッセージ表示用）
      final wasPrivate = _currentWhiteboard.isPrivate;

      // Firestoreで更新
      await repository.togglePrivate(_currentWhiteboard);

      // 🔥 CRITICAL: Firestoreから最新データを明示的に取得してUIを更新
      await _reloadWhiteboardFromFirestore(reason: 'privacy toggle');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasPrivate ? '他の人も編集できるようになりました' : '自分だけ編集できるようになりました',
            ),
          ),
        );
      }

      AppLogger.info('✅ [PRIVATE] プライベート設定変更完了: $wasPrivate → ${!wasPrivate}');
    } catch (e) {
      AppLogger.error('❌ プライベート設定エラー: $e');
    }
  }

  /// 全消去確認ダイアログ
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全消去確認'),
        content: const Text('ボードのすべての描画を削除します。この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearWhiteboard();
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 全消去処理（Firestore保存）
  Future<void> _clearWhiteboard() async {
    try {
      final repository = ref.read(whiteboardRepositoryProvider);

      // 🔥 Firestoreから全ストロークを削除（本質的には空の状態で保存）
      await repository.clearWhiteboard(
        groupId: widget.groupId,
        whiteboardId: _currentWhiteboard.whiteboardId,
      );

      // ローカルも消去
      setState(() {
        _workingStrokes.clear();
        _controller?.clear();

        // 📚 履歴をリセット
        _history.clear();
        _historyIndex = -1;
        _saveToHistory(); // 空の状態を履歴に保存
      });

      AppLogger.info('✅ [DELETE] ホワイトボード全消去成功');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('全消去しました')),
        );
      }
    } catch (e) {
      AppLogger.error('❌ [DELETE] 全消去エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('全消去に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final canEdit =
        currentUser != null && _currentWhiteboard.canEdit(currentUser.uid);

    AppLogger.info(
        '🎨 [WHITEBOARD] build - canEdit: $canEdit, userId: ${AppLogger.maskUserId(currentUser?.uid)}');
    AppLogger.info(
        '🎨 [WHITEBOARD] whiteboard - isPrivate: ${_currentWhiteboard.isPrivate}, ownerId: ${AppLogger.maskUserId(_currentWhiteboard.ownerId)}');
    AppLogger.info(
        '🎨 [WHITEBOARD] isGroupWhiteboard: ${_currentWhiteboard.isGroupWhiteboard}, isPersonalWhiteboard: ${_currentWhiteboard.isPersonalWhiteboard}');
    AppLogger.info(
        '🎨 [WHITEBOARD] AppBar title will be: ${_currentWhiteboard.isGroupWhiteboard ? "グループ共通" : "個人用"}');

    return WillPopScope(
      onWillPop: () async {
        // 🔥 Windows版安定化: エディター終了時に自動保存
        if (Platform.isWindows && canEdit && !_isSaving) {
          AppLogger.info('🪟 [WINDOWS] エディター終了時に自動保存実行');
          await _saveWhiteboard();
        }

        // ページ離脱時に編集ロックを解除（保持中のみ）
        await _releaseEditLock();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentWhiteboard.isGroupWhiteboard
                ? 'グループ共通ホワイトボード'
                : '個人用ホワイトボード',
          ),
          actions: [
            // 編集ロック状態アイコン（グループ共有ボードのみ）
            if (_currentWhiteboard.isGroupWhiteboard && _isEditingLocked)
              IconButton(
                icon: const Icon(Icons.lock, color: Colors.orange),
                onPressed: () => _showEditingInProgressDialog(),
                tooltip: '編集中: ${_currentEditor?.userName ?? "Unknown"}',
              )
            else if (_currentWhiteboard.isGroupWhiteboard && _hasEditLock)
              const Icon(Icons.lock_open, color: Colors.green),
            // プライベート設定スイッチ（個人用のみ）
            if (_currentWhiteboard.isPersonalWhiteboard &&
                _currentWhiteboard.ownerId == currentUser?.uid)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('編集制限', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _currentWhiteboard.isPrivate,
                    onChanged: (_) => _togglePrivate(),
                  ),
                ],
              ),
            // 保存ボタン（🪟 Windows版は非表示 - エディター終了時に自動保存）
            if (canEdit && !Platform.isWindows)
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
            // 🪟 Windows版: 自動保存情報表示
            if (canEdit && Platform.isWindows)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '自動保存',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
                                      size: const Size(_fixedCanvasWidth,
                                          _fixedCanvasHeight),
                                      painter:
                                          DrawingStrokePainter(_workingStrokes),
                                    ),
                                  ),
                                ),
                                // 前景：現在の描画セッション（編集可能な場合のみ）
                                if (canEdit)
                                  Positioned.fill(
                                    child: _buildDrawingArea(),
                                  ),

                                // 編集ロック中のオーバーレイ（グループ共有ボードのみ）
                                if (_currentWhiteboard.isGroupWhiteboard &&
                                    _isEditingLocked &&
                                    canEdit)
                                  Positioned(
                                    top: 60,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${AppLogger.maskName(_currentEditor?.userName ?? '他のユーザー')} 編集中',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
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
                      _currentWhiteboard.isPrivate
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
                // 🔄 モード切り替えボタン（左側に配置して常に見えるように）
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isScrollLocked ? Icons.brush : Icons.open_with,
                    color: _isScrollLocked
                        ? Colors.blue
                        : Colors.red.shade600, // 🎨 スクロールモードは赤系（ペンモードの青と対比）
                    size: 20,
                  ),
                  onPressed: () async {
                    AppLogger.info(
                        '🎨 [MODE_TOGGLE] モード切り替え: ${_isScrollLocked ? 'スクロールモード' : '描画モード'}へ');

                    // 🔥 CRITICAL: Windows版クラッシュ対策
                    // Windowsのみ編集ロック処理をスキップ、Android/iOSは従来通り
                    final isWindows = Platform.isWindows;

                    if (isWindows) {
                      // ===== Windows版: 編集ロック処理なし（クラッシュ防止） =====
                      AppLogger.info('💻 [WINDOWS] 編集ロック処理をスキップ');

                      // 1. まず状態を切り替え
                      if (!mounted) return;
                      setState(() {
                        _isScrollLocked = !_isScrollLocked;
                      });

                      // 2. 描画データのキャプチャ（非同期処理なし）
                      if (!_isScrollLocked) {
                        AppLogger.info('🔓 [MODE_TOGGLE] 描画モード終了 - 描画データキャプチャ');
                        try {
                          _captureCurrentDrawing();
                        } catch (e) {
                          AppLogger.error('❌ [MODE_TOGGLE] 描画キャプチャエラー: $e');
                        }
                      } else {
                        AppLogger.info('🔒 [MODE_TOGGLE] 描画モード開始');
                      }
                    } else {
                      // ===== Android/iOS版: 従来通り編集ロック処理あり =====
                      if (_isScrollLocked) {
                        // 描画モード → スクロールモード: 現在の描画を保存 → ロック解除
                        AppLogger.info('🔓 [MODE_TOGGLE] 描画モード終了 - 描画保存');

                        // 描画データを一時保存（Firestoreには保存しない）
                        try {
                          _captureCurrentDrawing();
                        } catch (e) {
                          AppLogger.error('❌ [MODE_TOGGLE] 描画キャプチャエラー: $e');
                        }

                        await _releaseEditLock();
                      } else {
                        // スクロールモード → 描画モード: ロック取得
                        AppLogger.info('🔒 [MODE_TOGGLE] 描画モード開始 - ロック取得試行');
                        if (_currentWhiteboard.isGroupWhiteboard) {
                          final success = await _acquireEditLock();
                          if (!success && mounted) {
                            AppLogger.warning(
                                '❌ [MODE_TOGGLE] ロック取得失敗 - モード切り替えをキャンセル');
                            if (_isEditingLocked && _currentEditor != null) {
                              _showEditingInProgressDialog();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('編集ロックの取得に失敗しました')),
                              );
                            }
                            return; // モード切り替えをキャンセル
                          }
                        }
                      }

                      if (!mounted) return;
                      setState(() {
                        _isScrollLocked = !_isScrollLocked;
                      });
                    }

                    AppLogger.info(
                        '✅ [MODE_TOGGLE] モード切り替え完了: ${_isScrollLocked ? '描画モード' : 'スクロールモード'}');
                  },
                  tooltip: _isScrollLocked ? '描画モード（筆）' : 'スクロールモード（十字）',
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
                _buildColorButton(_getCustomColor5()), // 設定から取得
                _buildColorButton(_getCustomColor6()), // 設定から取得
                const SizedBox(width: 16),

                // 🔒 編集ロック状態表示（グループ共有ボードのみ）
                if (_currentWhiteboard.isGroupWhiteboard)
                  _buildEditLockStatus(),
                if (_currentWhiteboard.isGroupWhiteboard)
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
              mainAxisAlignment: MainAxisAlignment.start, // 左寄せ
              children: [
                // ペン太さ3段階（細・中・太）
                _buildStrokeWidthButton(2.0, 1, label: '細'),
                _buildStrokeWidthButton(4.0, 2, label: '中'),
                _buildStrokeWidthButton(6.0, 3, label: '太'),
                const SizedBox(width: 16),
                // Undoボタン
                IconButton(
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: (_canUndo() &&
                          !(_currentWhiteboard.isGroupWhiteboard &&
                              _isEditingLocked))
                      ? _undo
                      : null,
                  tooltip: !_canUndo()
                      ? 'これ以上戻せません'
                      : (_currentWhiteboard.isGroupWhiteboard &&
                              _isEditingLocked)
                          ? '編集ロック中'
                          : '元に戻す',
                ),
                // Redoボタン
                IconButton(
                  icon: const Icon(Icons.redo, size: 20),
                  onPressed: (_canRedo() &&
                          !(_currentWhiteboard.isGroupWhiteboard &&
                              _isEditingLocked))
                      ? _redo
                      : null,
                  tooltip: !_canRedo()
                      ? 'これ以上進めません'
                      : (_currentWhiteboard.isGroupWhiteboard &&
                              _isEditingLocked)
                          ? '編集ロック中'
                          : 'やり直す',
                ),
                const SizedBox(width: 16),
                // ズームアウト
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 20),
                  onPressed:
                      (_currentWhiteboard.isGroupWhiteboard && _isEditingLocked)
                          ? null
                          : () {
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
                                    final canDraw = await _onDrawingStart();
                                    if (!canDraw && mounted) {
                                      _controller?.clear();
                                    }
                                  };
                                  _controllerKey++;
                                });
                              }
                            },
                  tooltip:
                      (_currentWhiteboard.isGroupWhiteboard && _isEditingLocked)
                          ? '編集ロック中'
                          : 'ズームアウト',
                ),
                // ズーム倍率表示
                Text('${_canvasScale.toStringAsFixed(1)}x'),
                // ズームイン
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed:
                      (_currentWhiteboard.isGroupWhiteboard && _isEditingLocked)
                          ? null
                          : () {
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
                                    final canDraw = await _onDrawingStart();
                                    if (!canDraw && mounted) {
                                      _controller?.clear();
                                    }
                                  };
                                  _controllerKey++;
                                });
                              }
                            },
                  tooltip:
                      (_currentWhiteboard.isGroupWhiteboard && _isEditingLocked)
                          ? '編集ロック中'
                          : 'ズームイン',
                ),
                const SizedBox(width: 16), // Spacerの代わりに固定幅
                // 消去ボタン
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed:
                      (_currentWhiteboard.isGroupWhiteboard && _isEditingLocked)
                          ? null
                          : () async {
                              // 全消去ボタン押下時の処理
                              _showDeleteConfirmationDialog();
                            },
                  tooltip:
                      (_currentWhiteboard.isGroupWhiteboard && _isEditingLocked)
                          ? '編集ロック中'
                          : '全消去',
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

  /// 🔒 編集ロック状態表示ウィジェット（グループ共有ボードのみ）
  Widget _buildEditLockStatus() {
    // 個人ボードでは編集ロック状態を表示しない
    if (_currentWhiteboard.isPersonalWhiteboard) {
      return const SizedBox.shrink();
    }

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
    final isEnabled = _currentWhiteboard.isGroupWhiteboard
        ? !_isEditingLocked
        : true; // 🔒 個人ボードは常に有効、グループ共有ボードのみ編集ロックチェック

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                setState(() {
                  // 🔥 色変更前に現在の描画を保存
                  _captureCurrentDrawing();

                  _selectedColor = color;
                  // SignatureControllerは再作成が必要（空でスタート）
                  // ペン幅はスケーリングを考慮
                  _controller?.dispose();
                  _controller = SignatureController(
                    penStrokeWidth: _strokeWidth * _canvasScale,
                    penColor: color,
                  );
                  _controllerKey++; // キー更新でウィジェット再構築
                });
              }
            : null, // 編集ロック中はタップ無効
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
      ),
    );
  }

  /// ペン太さボタン（3段階：細・中・太）
  Widget _buildStrokeWidthButton(double width, int level, {String? label}) {
    final isSelected = _strokeWidth == width;
    final isEnabled = _currentWhiteboard.isGroupWhiteboard
        ? !_isEditingLocked
        : true; // 🔒 個人ボードは常に有効、グループ共有ボードのみ編集ロックチェック

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Container(
                width: 8.0 + (level * 3), // レベルに応じてサイズ変更
                height: 8.0 + (level * 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade400, // 🎨 選択時は濃い青、非選択時は薄いグレー
                  shape: BoxShape.circle,
                ),
              ),
              onPressed: isEnabled
                  ? () {
                      setState(() {
                        // 🔥 太さ変更前に現在の描画を保存
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
                          final canDraw = await _onDrawingStart();
                          if (!canDraw && mounted) {
                            _controller?.clear();
                          }
                        };
                        _controllerKey++; // キー更新でウィジェット再構築
                      });
                    }
                  : null, // 編集ロック中はタップ無効
              tooltip: isEnabled ? '太さ $level' : '編集ロック中',
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
      ),
    );
  }

  /// 描画エリアをビルド（編集ロック状態を考慮）
  Widget _buildDrawingArea() {
    AppLogger.info(
        '🏗️ [BUILD_DRAWING_AREA] 状態: isGroup=${_currentWhiteboard.isGroupWhiteboard}, isLocked=$_isEditingLocked, hasLock=$_hasEditLock, scrollLocked=$_isScrollLocked');
    AppLogger.info(
        '🏗️ [BUILD_DRAWING_AREA] 現在の編集者: ${_currentEditor?.userName ?? "なし"}');

    // 🔒 編集ロック中の場合（グループボードのみ）
    if (_currentWhiteboard.isGroupWhiteboard &&
        _isEditingLocked &&
        !_hasEditLock) {
      AppLogger.warning('🔒 [DRAWING_AREA] 編集ロック中 - ロックアイコン表示');
      // 描画エリアはそのまま表示しつつタップのみ無効化（控えめな挙動に）
      return AbsorbPointer(
        absorbing: true,
        child: Container(
          width: _fixedCanvasWidth * _canvasScale,
          height: _fixedCanvasHeight * _canvasScale,
          color: Colors.transparent,
        ),
      );
    }

    // 🎨 通常の描画モード
    if (_isScrollLocked) {
      AppLogger.info('🎨 [DRAWING_AREA] 描画モード有効 - Signatureウィジェット配置');
      return Container(
        width: _fixedCanvasWidth * _canvasScale,
        height: _fixedCanvasHeight * _canvasScale,
        color: Colors.green.withOpacity(0.1), // 🔥 デバッグ用背景色
        child: GestureDetector(
          onPanStart: (details) async {
            AppLogger.info('🎨 [GESTURE] 描画開始検出 - onPanStart');
            // 描画開始時の編集ロックチェックを実行
            final canDraw = await _onDrawingStart();
            if (!canDraw && mounted) {
              _controller?.clear();
              return;
            }
          },
          child: Signature(
            key: ValueKey('signature_$_controllerKey'),
            controller: _controller!,
            backgroundColor: Colors.transparent,
          ),
        ),
      );
    }

    // 📱 スクロールモード
    AppLogger.info('📱 [DRAWING_AREA] スクロールモード - 描画無効');
    return Container(
      width: _fixedCanvasWidth * _canvasScale,
      height: _fixedCanvasHeight * _canvasScale,
      color: Colors.blue.withOpacity(0.1), // 🔥 デバッグ用背景色
      child: Center(
        child: Icon(
          Icons.pan_tool,
          color: Colors.grey.withOpacity(0.5),
          size: 32,
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
