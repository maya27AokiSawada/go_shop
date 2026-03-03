import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

/// ネットワーク接続状態
enum NetworkStatus {
  online, // 接続成功
  offline, // 接続失敗またはタイムアウト
  checking, // 接続確認中
}

/// ネットワーク監視サービス
///
/// Firestoreへの接続状態をチェックし、オフライン時には自動的に
/// 10分間隔でリトライを実行する。
///
/// 使用例:
/// ```dart
/// final networkMonitor = ref.read(networkMonitorProvider);
///
/// // 手動で接続確認
/// final isOnline = await networkMonitor.checkFirestoreConnection();
///
/// // 状態をストリームで監視
/// ref.listen(networkMonitorProvider, (previous, next) {
///   if (next.currentStatus == NetworkStatus.online) {
///     // オンラインに復帰
///   }
/// });
/// ```
class NetworkMonitorService {
  NetworkMonitorService() {
    // 🔥 初期状態をStreamに流す（StreamProviderのloading状態を解消）
    _statusController.add(_currentStatus);
    AppLogger.info('🌐 [NETWORK_MONITOR] 初期化完了 - 初期状態: $_currentStatus');

    // 🔥 初回接続チェックを非同期で実行（実際の接続状態を検証）
    Future.microtask(() async {
      AppLogger.info('🔍 [NETWORK_MONITOR] 初回接続チェック開始');
      await checkFirestoreConnection();
    });
  }

  /// 現在のネットワーク状態
  NetworkStatus _currentStatus = NetworkStatus.online;
  NetworkStatus get currentStatus => _currentStatus;

  /// ネットワーク状態のストリーム
  final _statusController = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// 自動リトライタイマー
  Timer? _retryTimer;

  /// 最後にチェックした時刻
  DateTime? _lastCheckTime;

  /// リトライ間隔（10分）
  static const retryInterval = Duration(minutes: 10);

  /// 接続タイムアウト（5秒）
  static const connectionTimeout = Duration(seconds: 5);

  /// Firestore接続をチェック
  ///
  /// 認証済みユーザーの場合は自分のユーザードキュメント（users/{uid}）を取得。
  /// 未認証の場合は公開ニュースコレクション（furestorenews）を取得。
  /// 5秒以内に成功すればオンラインと判定する。
  ///
  /// Returns: 接続が成功した場合はtrue、失敗した場合はfalse
  Future<bool> checkFirestoreConnection() async {
    AppLogger.info('🔍 [NETWORK_MONITOR] Firestore接続チェック開始');

    // 状態を「チェック中」に更新
    _updateStatus(NetworkStatus.checking);
    _lastCheckTime = DateTime.now();

    try {
      // Firestoreからデータ取得を試行（キャッシュを使わず、サーバーから取得）
      AppLogger.info('🔍 [NETWORK_MONITOR] Firestoreクエリ実行中...');

      final currentUser = FirebaseAuth.instance.currentUser;
      final DocumentSnapshot snapshot;

      if (currentUser != null) {
        // 認証済み：自分のユーザードキュメントを取得（必ず読み取り可能）
        AppLogger.info(
            '🔍 [NETWORK_MONITOR] 認証済み - ユーザードキュメントで接続チェック: ${AppLogger.maskUserId(currentUser.uid)}');
        snapshot = await FirebaseFirestore.instance
            .doc('users/${currentUser.uid}')
            .get(const GetOptions(source: Source.server))
            .timeout(connectionTimeout);
      } else {
        // 未認証：公開ニュースコレクションを取得（誰でも読み取り可能）
        AppLogger.info('🔍 [NETWORK_MONITOR] 未認証 - 公開ニュースで接続チェック');
        final querySnapshot = await FirebaseFirestore.instance
            .collection('furestorenews')
            .limit(1)
            .get(const GetOptions(source: Source.server))
            .timeout(connectionTimeout);
        snapshot = querySnapshot.docs.isNotEmpty
            ? querySnapshot.docs.first
            : throw Exception('No documents');
      }

      // 接続成功
      AppLogger.info(
          '✅ [NETWORK_MONITOR] Firestore接続成功 - ドキュメント存在: ${snapshot.exists}');
      _updateStatus(NetworkStatus.online);

      // 自動リトライを停止（オンラインに復帰したため）
      stopAutoRetry();

      return true;
    } on TimeoutException catch (e) {
      // タイムアウト
      AppLogger.warning('⏱️ [NETWORK_MONITOR] Firestore接続タイムアウト（5秒）: $e');
      _updateStatus(NetworkStatus.offline);
      return false;
    } on FirebaseException catch (e) {
      // Firebaseエラー
      AppLogger.warning(
          '❌ [NETWORK_MONITOR] Firestore接続エラー: ${e.code} - ${e.message}');
      _updateStatus(NetworkStatus.offline);
      return false;
    } catch (e, stackTrace) {
      // その他のエラー
      AppLogger.error('❌ [NETWORK_MONITOR] Firestore接続エラー（予期しない）: $e');
      AppLogger.error('📍 [NETWORK_MONITOR] スタックトレース: $stackTrace');
      _updateStatus(NetworkStatus.offline);
      return false;
    }
  }

  /// 自動リトライを開始
  ///
  /// 10分間隔でFirestore接続チェックを実行する。
  /// オンラインに復帰すると自動的に停止する。
  void startAutoRetry() {
    // 既に実行中なら何もしない
    if (_retryTimer != null && _retryTimer!.isActive) {
      AppLogger.info('ℹ️ [NETWORK_MONITOR] 自動リトライは既に実行中');
      return;
    }

    AppLogger.info('🔄 [NETWORK_MONITOR] 自動リトライ開始（10分間隔）');

    // 10分間隔のタイマーを作成
    _retryTimer = Timer.periodic(retryInterval, (timer) async {
      AppLogger.info('🔄 [NETWORK_MONITOR] 自動リトライ実行中...');

      final isOnline = await checkFirestoreConnection();

      if (isOnline) {
        // オンラインに復帰したのでタイマーを停止
        AppLogger.info('✅ [NETWORK_MONITOR] オンライン復帰のため自動リトライ停止');
        timer.cancel();
      } else {
        AppLogger.info('❌ [NETWORK_MONITOR] まだオフライン、次回リトライまで10分');
      }
    });
  }

  /// 自動リトライを停止
  void stopAutoRetry() {
    if (_retryTimer != null && _retryTimer!.isActive) {
      AppLogger.info('⏹️ [NETWORK_MONITOR] 自動リトライ停止');
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  /// 手動リトライ
  ///
  /// ユーザーが手動でリトライボタンを押した時に呼び出す。
  ///
  /// Returns: 接続が成功した場合はtrue、失敗した場合はfalse
  Future<bool> manualRetry() async {
    AppLogger.info('🔄 [NETWORK_MONITOR] 手動リトライ実行');

    final isOnline = await checkFirestoreConnection();

    if (!isOnline) {
      // まだオフラインなら自動リトライを開始
      startAutoRetry();
    }

    return isOnline;
  }

  /// 次のリトライまでの残り時間
  ///
  /// 自動リトライが実行されていない場合はnullを返す。
  Duration? get timeUntilNextRetry {
    if (_lastCheckTime == null ||
        _retryTimer == null ||
        !_retryTimer!.isActive) {
      return null;
    }

    final elapsed = DateTime.now().difference(_lastCheckTime!);
    final remaining = retryInterval - elapsed;

    // 残り時間がマイナスになる場合は0を返す
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 状態を更新してストリームに通知
  void _updateStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      final oldStatus = _currentStatus;
      _currentStatus = status;
      _statusController.add(status);
      AppLogger.info('📡 [NETWORK_MONITOR] 状態変更: $oldStatus → $status');
      AppLogger.info('📤 [NETWORK_MONITOR] Stream emit完了: $status');

      // 🔥 オフラインになった時は自動リトライを開始
      if (status == NetworkStatus.offline) {
        AppLogger.info('🔄 [NETWORK_MONITOR] オフライン検出 → 自動リトライ開始');
        startAutoRetry();
      }
    } else {
      AppLogger.info('🔄 [NETWORK_MONITOR] 状態変化なし: $status');
    }
  }

  /// リソースをクリーンアップ
  void dispose() {
    AppLogger.info('🗑️ [NETWORK_MONITOR] リソースをクリーンアップ');
    stopAutoRetry();
    _statusController.close();
  }
}

/// NetworkMonitorServiceのプロバイダー
///
/// アプリ全体で1つのインスタンスを共有する。
final networkMonitorProvider = Provider<NetworkMonitorService>((ref) {
  final service = NetworkMonitorService();

  // プロバイダーが破棄される時にリソースをクリーンアップ
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// ネットワーク状態のストリームプロバイダー
///
/// UIでネットワーク状態を監視するために使用する。
final networkStatusStreamProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(networkMonitorProvider);
  return service.statusStream;
});
