import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/whiteboard.dart';
import '../providers/whiteboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_group_provider.dart';
import '../providers/user_settings_provider.dart';
import '../pages/group_member_management_page.dart';
import '../services/notification_service.dart';
import '../services/network_monitor_service.dart';
import '../utils/snackbar_helper.dart';
import '../utils/drawing_converter.dart';
import '../utils/app_logger.dart';
import '../services/error_log_service.dart';
import '../widgets/whiteboard/whiteboard_painters.dart';
import '../widgets/whiteboard/whiteboard_toolbar.dart';

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

class _WhiteboardEditorPageState extends ConsumerState<WhiteboardEditorPage>
    with WidgetsBindingObserver {
  // 固定キャンバスサイズ（16:9比率 - 横長）
  static const double _fixedCanvasWidth = 1280.0;
  static const double _fixedCanvasHeight = 720.0;

  SignatureController? _controller;
  bool _isSaving = false;
  bool _showSaveSpinner = false;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0; // 🎨 初期値は「中」の太さ
  int _controllerKey = 0; // コントローラー再作成カウンター
  List<DrawingStroke> _workingStrokes = []; // 作業中のストロークリスト（finalを削除）

  // 🔥 新機能: 未保存ストローク追跡（差分保存用）
  final Set<String> _unsavedStrokeIds = {}; // まだFirestoreに保存されていないstrokeIdのセット

  // ↩️ Undo/Redo履歴管理
  final List<List<DrawingStroke>> _history = []; // 履歴スタック
  int _historyIndex = -1; // 現在の履歴位置

  //  CRITICAL: 最新のホワイトボードデータをStateで管理（isPrivate更新対応）
  late Whiteboard _currentWhiteboard;

  // スクロール用のコントローラー
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // キャンバスズーム倍率
  double _canvasScale = 1.0; // デフォルト等倍

  // スクロールロック（trueでスクロール無効、falseでスクロール有効）
  bool _isScrollLocked = false;

  // 🔥 FIX: モード切り替え中フラグ（二重タップ防止）
  bool _isTogglingMode = false;

  // カスタム色（設定から読み込み、キャッシュする）
  late Color _customColor5;
  late Color _customColor6;

  // Firestoreリアルタイム監視
  StreamSubscription<Whiteboard?>? _whiteboardSubscription;

  // 🗑️ 全クリア処理中フラグ（Firestoreリスナーの上書きを防ぐ）
  bool _isClearing = false;

  // 👤 個人用ホワイトボード保存直後の自己反映スナップショット抑止
  bool _suppressNextPersonalSnapshot = false;

  SignatureController _createSignatureController({
    required Color penColor,
    required double strokeWidth,
  }) {
    return SignatureController(
      penStrokeWidth: strokeWidth * _canvasScale,
      penColor: penColor,
      onDrawStart: () async {
        AppLogger.info('🎨 [SIGNATURE] 描画開始検出 - onDrawStart');

        if (_controller != null && _controller!.isNotEmpty) {
          AppLogger.info('✋ [PEN_DOWN] 前回の描画をキャプチャ（履歴なし）');
          _captureCurrentStrokeWithoutHistory();
        }
      },
      onDrawEnd: () {
        AppLogger.info('🎨 [SIGNATURE] 描画完了検出 - onDrawEnd');

        if (_controller != null && _controller!.isNotEmpty) {
          AppLogger.info('✋ [PEN_UP] 描画完了 - ストロークをキャプチャして履歴に保存');
          _captureCurrentDrawing();
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🔥 CRITICAL: Stateにホワイトボードデータを保持
    _currentWhiteboard = widget.whiteboard;

    // カスタム色を初期化（設定から読み込み）
    _customColor5 = _loadCustomColor5();
    _customColor6 = _loadCustomColor6();

    // 既存のストロークを作業リストに読み込む
    if (_currentWhiteboard.strokes.isNotEmpty) {
      _workingStrokes.addAll(_currentWhiteboard.strokes);
      // 🔥 既存ストロークは保存済みなので、未保存リストには追加しない
      _unsavedStrokeIds.clear();
      AppLogger.info(
          '🎨 [WHITEBOARD] ${_currentWhiteboard.strokes.length}個のストロークを復元（全て保存済み）');
    }

    // 📚 初期状態を履歴に保存
    _saveToHistory();

    // 空のコントローラーでスタート
    _controller = _createSignatureController(
      penColor: _selectedColor,
      strokeWidth: _strokeWidth,
    );

    // Firestoreリアルタイム監視を開始（他端末更新の即時反映）
    _startWhiteboardListener();

    AppLogger.info(
        '🎨 [WHITEBOARD] ボードタイプ: isGroupWhiteboard=${_currentWhiteboard.isGroupWhiteboard}, isPersonalWhiteboard=${_currentWhiteboard.isPersonalWhiteboard}');

    // 初期スクロール位置を中央に設定（画面構築後に実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCenter();
    });

    AppLogger.info('🎨 [WHITEBOARD] SignatureController初期化完了');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _whiteboardSubscription?.cancel();
    _controller?.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No-op
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

      // 個人用ホワイトボードでは、自分の保存直後に同じ内容のスナップショットを
      // 再処理して履歴保存・再描画を二重実行すると、スピナー復帰遅延やUI劣化を招く。
      if (_suppressNextPersonalSnapshot &&
          _currentWhiteboard.isPersonalWhiteboard) {
        AppLogger.info('[LISTENER] 個人用ホワイトボードの自己反映スナップショットをスキップ');
        _suppressNextPersonalSnapshot = false;
        _currentWhiteboard = latest;
        return;
      }

      // 全クリア処理中はFirestoreリスナーからの更新を無視
      if (_isClearing) {
        AppLogger.info(
            '[LISTENER] 全クリア処理中 - Firestore更新を無視（strokes=${latest.strokes.length}）');
        return;
      }

      setState(() {
        // 🔥 CRITICAL: ホワイトボード全体を更新（isPrivateなどのプロパティも含む）
        _currentWhiteboard = latest;

        // 🔥 改善: ストロークをインテリジェントにマージ（strokeIdベース）
        _mergeStrokesFromFirestore(latest.strokes);

        // 📚 Firestore更新後の状態を履歴に記録（他ユーザーの変更も履歴に含める）
        _saveToHistory();
      });

      AppLogger.info(
          '🛰️ [WHITEBOARD] Firestore最新ストロークを反映: ${latest.strokes.length}本（ローカル${_workingStrokes.length}本）');
    });
  }

  /// 🔥 新機能: Firestoreストロークとローカルストロークをインテリジェントにマージ
  void _mergeStrokesFromFirestore(List<DrawingStroke> firestoreStrokes) {
    // strokeIdでストロークをマップ化
    final firestoreMap = {for (var s in firestoreStrokes) s.strokeId: s};
    final localMap = {for (var s in _workingStrokes) s.strokeId: s};

    // マージ結果
    final mergedMap = <String, DrawingStroke>{};

    // 1. Firestoreのストロークを追加（保存済みストローク）
    for (final entry in firestoreMap.entries) {
      mergedMap[entry.key] = entry.value;
      // Firestoreに存在するストロークは保存済みなので、未保存リストから削除
      _unsavedStrokeIds.remove(entry.key);
    }

    // 2. ローカルの未保存ストロークを追加（Firestoreにまだないもの）
    for (final entry in localMap.entries) {
      if (!firestoreMap.containsKey(entry.key)) {
        mergedMap[entry.key] = entry.value;
        // まだFirestoreにないので、未保存リストに保持
        _unsavedStrokeIds.add(entry.key);
      }
    }

    // 3. ストロークリストを更新（createdAt順にソート）
    _workingStrokes = mergedMap.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    AppLogger.info('🔄 [MERGE] マージ完了: Firestore=${firestoreStrokes.length}本, '
        'ローカル=${localMap.length}本, 結果=${_workingStrokes.length}本, 未保存=${_unsavedStrokeIds.length}本');
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

  /// ✋ ペンアップ時に現在のストロークを確定（履歴保存あり）
  void _captureCurrentStroke() {
    if (_controller == null || _controller!.isEmpty) {
      return; // 何も描かれていなければスキップ
    }

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    try {
      // 現在の描画をキャプチャ（ペンアップで1ストローク確定）
      final strokes = DrawingConverter.captureFromSignatureController(
        controller: _controller!,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Unknown',
        strokeColor: _selectedColor,
        strokeWidth: _strokeWidth,
        scale: _canvasScale,
      );

      // 作業リストに追加
      if (strokes.isNotEmpty) {
        _workingStrokes.addAll(strokes);

        // 🔥 新機能: 新規ストロークを未保存リストに追加
        for (final stroke in strokes) {
          _unsavedStrokeIds.add(stroke.strokeId);
        }

        AppLogger.info(
            '✋ [PEN_UP] ${strokes.length}個のストロークを確定 (計${_workingStrokes.length}個、未保存${_unsavedStrokeIds.length}個)');

        // 📚 履歴に保存
        _saveToHistory();

        // 🔥 CRITICAL: ペンアップ後はSignatureControllerをクリア
        // 次回描画時に新しいストロークとして開始
        _controller?.clear();
        AppLogger.info('🧹 [PEN_UP] SignatureControllerクリア完了');
      }
    } catch (e) {
      AppLogger.error('❌ [PEN_UP] ストローク確定エラー: $e');
    }
  }

  /// ✋ ストロークを確定するが履歴には保存しない（onPanStart用）
  void _captureCurrentStrokeWithoutHistory() {
    if (_controller == null || _controller!.isEmpty) {
      return; // 何も描かれていなければスキップ
    }

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    try {
      // 現在の描画をキャプチャ（ペンダウンで前回のストローク確定）
      final strokes = DrawingConverter.captureFromSignatureController(
        controller: _controller!,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Unknown',
        strokeColor: _selectedColor,
        strokeWidth: _strokeWidth,
        scale: _canvasScale,
      );

      // 作業リストに追加（履歴には保存しない）
      if (strokes.isNotEmpty) {
        _workingStrokes.addAll(strokes);

        // 🔥 新機能: 新規ストロークを未保存リストに追加
        for (final stroke in strokes) {
          _unsavedStrokeIds.add(stroke.strokeId);
        }

        AppLogger.info(
            '✋ [PEN_DOWN] ${strokes.length}個のストロークを確定（履歴保存なし、計${_workingStrokes.length}個、未保存${_unsavedStrokeIds.length}個）');

        // 🔥 CRITICAL: SignatureControllerをクリア
        _controller?.clear();
        AppLogger.info('🧹 [PEN_DOWN] SignatureControllerクリア完了');
      }
    } catch (e) {
      AppLogger.error('❌ [PEN_DOWN] ストローク確定エラー: $e');
    }
  }

  /// 📸 モード切り替え時に現在の描画をキャプチャ（バックアップ用）
  void _captureCurrentDrawing() {
    if (_controller == null || _controller!.isEmpty) {
      return; // 何も描かれていなければスキップ
    }

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    try {
      // モード切り替え時のキャプチャ（主にペンアップを逃した場合の安全策）
      final strokes = DrawingConverter.captureFromSignatureController(
        controller: _controller!,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Unknown',
        strokeColor: _selectedColor,
        strokeWidth: _strokeWidth,
        scale: _canvasScale,
      );

      // 作業リストに追加
      if (strokes.isNotEmpty) {
        _workingStrokes.addAll(strokes);

        // 🔥 新機能: 新規ストロークを未保存リストに追加
        for (final stroke in strokes) {
          _unsavedStrokeIds.add(stroke.strokeId);
        }

        AppLogger.info(
            '📸 [MODE_TOGGLE] ${strokes.length}個のストロークをキャプチャ (計${_workingStrokes.length}個、未保存${_unsavedStrokeIds.length}個)');

        // 📚 履歴に保存
        _saveToHistory();

        // 🔥 CRITICAL: キャプチャ後はSignatureControllerをクリア
        _controller?.clear();
        AppLogger.info('🧹 [MODE_TOGGLE] SignatureControllerクリア完了');
      }
    } catch (e) {
      AppLogger.error('❌ [MODE_TOGGLE] 描画キャプチャエラー: $e');
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
      SnackBarHelper.showCustom(context,
          message: 'これ以上戻せません', duration: const Duration(milliseconds: 500));
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
      SnackBarHelper.showCustom(context,
          message: 'これ以上進めません', duration: const Duration(milliseconds: 500));
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

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) {
      SnackBarHelper.showError(context, 'サインイン状態を確認できないため保存できません');
      return;
    }

    final canEdit = _currentWhiteboard.canEdit(currentUser.uid);
    if (!canEdit) {
      AppLogger.warning(
          '⛔ [SAVE] 編集不可のため保存を中止: user=${AppLogger.maskUserId(currentUser.uid)}, owner=${AppLogger.maskUserId(_currentWhiteboard.ownerId)}');
      SnackBarHelper.showWarning(context, 'このホワイトボードは保存できません（編集不可）');
      return;
    }

    final networkMonitor = ref.read(networkMonitorProvider);
    if (networkMonitor.currentStatus == NetworkStatus.offline) {
      AppLogger.warning('⛔ [SAVE] オフラインのため保存を中止');
      SnackBarHelper.showWarning(context, 'ネットワーク障害のため保存できません');
      return;
    }

    AppLogger.info('💾 [SAVE] 保存処理開始');
    setState(() {
      _isSaving = true;
      _showSaveSpinner = true;
    });

    var spinnerReleased = false;
    Timer? spinnerWatchdog;

    spinnerWatchdog = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_isSaving || !_showSaveSpinner) return;

      AppLogger.warning('⏳ [SAVE] 保存リクエスト継続中 - AppBarスピナーのみ解除');
      setState(() {
        _showSaveSpinner = false;
      });
      SnackBarHelper.showInfo(context, '保存処理は継続中です');
    });

    try {
      AppLogger.info('💾 [SAVE] ユーザー認証OK: ${currentUser.uid}');

      // 🔥 Windows版対策：controller null チェック
      if (_controller == null) {
        AppLogger.error('❌ [SAVE] SignatureController が null です');
        spinnerWatchdog.cancel();
        if (mounted) {
          setState(() {
            _isSaving = false;
            _showSaveSpinner = false;
          });
        }
        return;
      }

      AppLogger.info('💾 [SAVE] 保存前に最後の描画をキャプチャ');

      // 🔥 保存前に最後の描画をキャプチャ（ペンダウン時と同じ処理）
      if (_controller!.isNotEmpty) {
        _captureCurrentStroke();
      }

      // 🔥 改善: 未保存のストロークのみを抽出（差分保存）
      final newStrokes = _workingStrokes
          .where((stroke) => _unsavedStrokeIds.contains(stroke.strokeId))
          .toList();

      AppLogger.info(
          '💾 [SAVE] 未保存ストローク数: ${newStrokes.length}個（全体${_workingStrokes.length}個）');

      if (newStrokes.isEmpty) {
        AppLogger.info('📋 [SAVE] 新しいストロークなし、保存をスキップ');
        spinnerWatchdog.cancel();
        if (mounted) {
          setState(() {
            _isSaving = false;
            _showSaveSpinner = false;
          });
        }
        return;
      }

      AppLogger.info('💾 [SAVE] Firestore保存開始...');

      // 🔥 差分ストローク追加でFirestoreに安全に保存
      final repository = ref.read(whiteboardRepositoryProvider);

      if (_currentWhiteboard.isPersonalWhiteboard) {
        _suppressNextPersonalSnapshot = true;
      }

      await repository.addStrokesToWhiteboard(
        groupId: widget.groupId,
        whiteboardId: _currentWhiteboard.whiteboardId,
        newStrokes: newStrokes,
      );

      AppLogger.info('✅ [SAVE] Firestore保存完了: ${newStrokes.length}個のストローク');
      spinnerWatchdog.cancel();

      if (mounted) {
        setState(() {
          _isSaving = false;
          _showSaveSpinner = false;
        });
        spinnerReleased = true;
      }

      // 🔥 Windows版対策: Firestore保存後にmountedチェック
      if (!mounted) return;

      // 🔥 改善: 保存成功後、未保存リストから削除
      for (final stroke in newStrokes) {
        _unsavedStrokeIds.remove(stroke.strokeId);
      }
      AppLogger.info('📐 [SAVE] 未保存リストから削除: 残り${_unsavedStrokeIds.length}個');

      // 📚 保存後の状態を履歴に記録
      _saveToHistory();

      // SignatureControllerのみクリア（新規描画開始のため）
      _controller?.clear();

      // 変更を反映（mounted チェック済み）
      setState(() {});

      // 🔔 他メンバーに更新通知を送信（Windows版ではスキップ）
      if (!Platform.isWindows) {
        try {
          final notificationService = ref.read(notificationServiceProvider);
          unawaited(
            notificationService
                .sendWhiteboardUpdateNotification(
              groupId: widget.groupId,
              whiteboardId: _currentWhiteboard.whiteboardId,
              isGroupWhiteboard: _currentWhiteboard.isGroupWhiteboard,
              ownerId: _currentWhiteboard.ownerId,
            )
                .then((_) {
              AppLogger.info('✅ ホワイトボード更新通知送信完了');
            }).catchError((notificationError) {
              AppLogger.error('⚠️ 通知送信エラー（保存は成功）: $notificationError');
            }),
          );
        } catch (notificationError) {
          // 通知送信エラーは無視（保存自体は成功している）
          AppLogger.error('⚠️ 通知送信エラー（保存は成功）: $notificationError');
        }
      } else {
        AppLogger.info('💻 [WINDOWS] 通知送信をスキップ（クラッシュ防止）');
      }

      if (mounted) {
        SnackBarHelper.showSuccess(context, '保存しました');
      }
    } on FirebaseException catch (e, stackTrace) {
      spinnerWatchdog.cancel();
      _suppressNextPersonalSnapshot = false;
      AppLogger.error('❌ ホワイトボード保存 Firebase エラー: ${e.code} - ${e.message}');

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        try {
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
            hint: Hint.withMap({
              'whiteboard_id': _currentWhiteboard.whiteboardId,
              'group_id': widget.groupId,
              'firestore_code': e.code,
              'is_group_whiteboard': _currentWhiteboard.isGroupWhiteboard,
              'platform': Platform.operatingSystem,
            }),
          );
        } catch (sentryError) {
          AppLogger.error('⚠️ [Sentry] レポート送信失敗: $sentryError');
        }
      } else {
        FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }

      await ErrorLogService.logOperationError(
        'ホワイトボード保存',
        'Firebase エラー: ${e.code} - ${e.message}',
        stackTrace,
      );

      if (mounted) {
        if (e.code == 'permission-denied') {
          SnackBarHelper.showWarning(context, 'このホワイトボードは保存できません（編集権限なし）');
        } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
          SnackBarHelper.showWarning(context, 'ネットワーク障害のため保存できません');
        } else {
          SnackBarHelper.showError(
              context, '保存に失敗しました: ${e.message ?? e.code}');
        }
      }
    } catch (e, stackTrace) {
      spinnerWatchdog.cancel();
      _suppressNextPersonalSnapshot = false;
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

      await ErrorLogService.logOperationError(
        'ホワイトボード保存',
        '$e',
        stackTrace,
      );

      if (mounted) {
        SnackBarHelper.showError(context, '保存に失敗しました: $e');
      }
    } finally {
      spinnerWatchdog.cancel();
      if (mounted && !spinnerReleased) {
        setState(() {
          _isSaving = false;
          _showSaveSpinner = false;
        });
      }
    }
  }

  /// プライベート設定切り替え
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
      AppLogger.info('[DELETE] 全クリア開始');

      // まずローカルUIを即座にクリア（スクロールモードでも即座に反映）
      setState(() {
        // 全クリア処理フラグを立てる（Firestoreリスナーの上書きを防ぐ）
        _isClearing = true;

        // 🔥 CRITICAL: 新しいリストを作成してCustomPaintの再描画をトリガー
        _workingStrokes = [];
        _controller?.clear();

        // 🔥 改善: 未保存リストもクリア
        _unsavedStrokeIds.clear();

        // 📚 履歴をリセット
        _history.clear();
        _historyIndex = -1;
        _saveToHistory(); // 空の状態を履歴に保存
      });

      AppLogger.info('[DELETE] setState完了');

      // 次にFirestoreに保存（非同期）
      final repository = ref.read(whiteboardRepositoryProvider);
      await repository.clearWhiteboard(
        groupId: widget.groupId,
        whiteboardId: _currentWhiteboard.whiteboardId,
      );

      AppLogger.info('✅ [DELETE] Firestoreホワイトボード全消去成功');

      // 🔥 Firestoreへの保存完了後、少し待ってからフラグを解除
      await Future.delayed(const Duration(milliseconds: 500));

      // setState内でフラグを解除してUI再描画をトリガー
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
      AppLogger.info('✅ [DELETE] 全クリア処理完了 - Firestoreリスナー再開');

      if (mounted) {
        SnackBarHelper.showSuccess(context, '全消去しました');
      }
    } catch (e) {
      // エラー時もsetState内でフラグをリセット
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
      AppLogger.error('❌ [DELETE] 全消去エラー: $e');
      await ErrorLogService.logOperationError('ホワイトボード全消去', '$e');
      if (mounted) {
        SnackBarHelper.showError(context, '全消去に失敗しました: $e');
      }
    }
  }

  Future<void> _navigateToGroupDetail({required bool canEdit}) async {
    if (!mounted) return;

    if (_isSaving && _showSaveSpinner) {
      AppLogger.info('⏳ [WHITEBOARD] 保存中のため戻る処理を一時保留');
      SnackBarHelper.showInfo(context, '保存完了を待っています');
      return;
    }

    if (_isSaving && !_showSaveSpinner) {
      AppLogger.warning('↩️ [WHITEBOARD] 保存要求継続中だが、画面離脱を許可');
    }

    AppLogger.info('↩️ [WHITEBOARD] グループ詳細画面へ戻る処理開始');

    if (Platform.isWindows && canEdit) {
      AppLogger.info('🪟 [WINDOWS] 戻る前に自動保存を実行');
      await _saveWhiteboard();
      if (!mounted) return;
    }

    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      AppLogger.info('↩️ [WHITEBOARD] 既存のグループ詳細画面へpopで戻る');
      navigator.pop();
      return;
    }

    final groups = ref.read(allGroupsProvider).valueOrNull ?? const [];
    final targetGroup =
        groups.where((g) => g.groupId == widget.groupId).firstOrNull;

    if (targetGroup == null) {
      AppLogger.warning('⚠️ [WHITEBOARD] 戻り先グループが見つからないため通常popを実行');
      navigator.pop();
      return;
    }

    AppLogger.warning('⚠️ [WHITEBOARD] 戻り先がスタックにないため詳細画面を再生成');
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => GroupMemberManagementPage(group: targetGroup),
      ),
    );
  }

  /// スクロール/描画モード切り替え
  Future<void> _toggleScrollMode() async {
    AppLogger.info(
        '🎨 [MODE_TOGGLE] モード切り替え: ${_isScrollLocked ? 'スクロールモード' : '描画モード'}へ');

    if (mounted) {
      setState(() {
        _isTogglingMode = true;
      });
    }

    // 🔥 安全弁ウォッチドッグ: 何らかの原因でfinallyが遅延しても
    // 最大8秒でスピナーを強制解除（保存ウォッチドッグと同方式）
    Timer? toggleWatchdog;
    toggleWatchdog = Timer(const Duration(seconds: 8), () {
      if (!mounted || !_isTogglingMode) return;
      AppLogger.warning('⏳ [MODE_TOGGLE] ウォッチドッグ発動（8秒）- スピナー強制解除');
      setState(() {
        _isTogglingMode = false;
      });
    });

    try {
      if (_isScrollLocked) {
        AppLogger.info('🔓 [MODE_TOGGLE] 描画モード終了 - 描画保存');

        try {
          _captureCurrentDrawing();
        } catch (e) {
          AppLogger.error('❌ [MODE_TOGGLE] 描画キャプチャエラー: $e');
        }

        if (!mounted) return;
        setState(() {
          _isScrollLocked = false;
        });
      } else {
        AppLogger.info('🔒 [MODE_TOGGLE] 描画モード開始');
        if (!mounted) return;
        setState(() {
          _isScrollLocked = true;
        });
      }

      AppLogger.info(
          '✅ [MODE_TOGGLE] モード切り替え完了: ${_isScrollLocked ? '描画モード' : 'スクロールモード'}');
    } finally {
      toggleWatchdog.cancel();
      if (mounted) {
        setState(() {
          _isTogglingMode = false;
        });
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
        await _navigateToGroupDetail(canEdit: canEdit);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateToGroupDetail(canEdit: canEdit),
            tooltip: 'グループ詳細へ戻る',
          ),
          title: Text(
            _currentWhiteboard.isGroupWhiteboard
                ? 'グループ共通ホワイトボード'
                : '個人用ホワイトボード',
          ),
          actions: [
            // 保存ボタン（🪟 Windows版は非表示 - エディター終了時に自動保存）
            if (canEdit && !Platform.isWindows)
              IconButton(
                icon: _showSaveSpinner
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
            if (canEdit)
              WhiteboardToolbar(
                selectedColor: _selectedColor,
                strokeWidth: _strokeWidth,
                canUndo: _canUndo(),
                canRedo: _canRedo(),
                isScrollLocked: _isScrollLocked,
                isTogglingMode: _isTogglingMode,
                canvasScale: _canvasScale,
                customColor5: _customColor5,
                customColor6: _customColor6,
                onColorChanged: (color) {
                  setState(() {
                    _captureCurrentDrawing();
                    _selectedColor = color;
                    _controller?.dispose();
                    _controller = _createSignatureController(
                      penColor: color,
                      strokeWidth: _strokeWidth,
                    );
                    _controllerKey++;
                  });
                },
                onStrokeWidthChanged: (width) {
                  setState(() {
                    _captureCurrentDrawing();
                    _strokeWidth = width;
                    _controller?.dispose();
                    _controller = _createSignatureController(
                      penColor: _selectedColor,
                      strokeWidth: width,
                    );
                    _controllerKey++;
                  });
                },
                onUndo: _undo,
                onRedo: _redo,
                onToggleScrollMode: _toggleScrollMode,
                onZoomIn: () {
                  if (_canvasScale < 4.0) {
                    _captureCurrentDrawing();
                    setState(() {
                      _canvasScale += 0.5;
                      print('🔍 ズームイン: ${_canvasScale}x');
                      _controller?.dispose();
                      _controller = _createSignatureController(
                        penColor: _selectedColor,
                        strokeWidth: _strokeWidth,
                      );
                      _controllerKey++;
                    });
                  }
                },
                onZoomOut: () {
                  if (_canvasScale > 0.5) {
                    _captureCurrentDrawing();
                    setState(() {
                      _canvasScale -= 0.5;
                      print('🔍 ズームアウト: ${_canvasScale}x');
                      _controller?.dispose();
                      _controller = _createSignatureController(
                        penColor: _selectedColor,
                        strokeWidth: _strokeWidth,
                      );
                      _controllerKey++;
                    });
                  }
                },
                onClearWhiteboard: _showDeleteConfirmationDialog,
              ),

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

  /// 描画エリアをビルド（編集ロック状態を考慮）
  Widget _buildDrawingArea() {
    AppLogger.info(
        '🏗️ [BUILD_DRAWING_AREA] 状態: isGroup=${_currentWhiteboard.isGroupWhiteboard}, scrollLocked=$_isScrollLocked');

    // 🎨 通常の描画モード
    if (_isScrollLocked) {
      AppLogger.info('🎨 [DRAWING_AREA] 描画モード有効 - Signatureウィジェット配置');
      return SizedBox(
        width: _fixedCanvasWidth * _canvasScale,
        height: _fixedCanvasHeight * _canvasScale,
        child: Signature(
          key: ValueKey('signature_$_controllerKey'),
          controller: _controller!,
          backgroundColor: Colors.transparent,
        ),
      );
    }

    // 📱 スクロールモード
    AppLogger.info('📱 [DRAWING_AREA] スクロールモード - 描画無効');
    return SizedBox(
      width: _fixedCanvasWidth * _canvasScale,
      height: _fixedCanvasHeight * _canvasScale,
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
