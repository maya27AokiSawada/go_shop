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
/// 初回3分・2回目5分・3回目以降10分間隔でリトライを実行する。
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
  static const offlineFailureThreshold = 2;
  static const transientRetryDelay = Duration(milliseconds: 700);
  static const initialCheckDelay = Duration(seconds: 2);

  NetworkMonitorService() {
    // 🔥 初期状態をStreamに流す（StreamProviderのloading状態を解消）
    _statusController.add(_currentStatus);
    AppLogger.info('🌐 [NETWORK_MONITOR] 初期化完了 - 初期状態: $_currentStatus');

    // 🔥 初回接続チェックは少し待ってから実行。
    // 起動直後は Firebase / Firestore / DNS のウォームアップ中で、
    // 手動リトライだけ成功する偽オフラインが出やすいため。
    Future.microtask(() async {
      AppLogger.info(
          '🔍 [NETWORK_MONITOR] 初回接続チェック待機開始（${initialCheckDelay.inSeconds}秒）');
      await Future.delayed(initialCheckDelay);
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

  /// リトライ間隔（初回: 3分、2回目: 5分、3回目以降: 10分）
  static const _retryInterval1 = Duration(minutes: 3);
  static const _retryInterval2 = Duration(minutes: 5);
  static const _retryIntervalN = Duration(minutes: 10);

  /// 接続タイムアウト（5秒）
  static const connectionTimeout = Duration(seconds: 5);

  /// 直近の接続チェック失敗回数
  int _consecutiveCheckFailures = 0;

  /// 最後に接続成功した時刻
  DateTime? _lastSuccessTime;

  /// 自動リトライの試行回数（startAutoRetry 呼び出しからの累計）
  int _retryAttemptCount = 0;

  /// 現在スケジュール中のリトライ間隔（timeUntilNextRetry 計算用）
  Duration _currentRetryInterval = _retryInterval1;

  /// Firestore接続をチェック
  ///
  /// 認証済みユーザーの場合は自分のユーザードキュメント（users/{uid}）を取得。
  /// 未認証の場合は公開ニュースコレクション（furestorenews）を取得。
  /// 5秒以内に成功すればオンラインと判定する。
  ///
  /// Returns: 接続が成功した場合はtrue、失敗した場合はfalse
  Future<bool> checkFirestoreConnection() async {
    AppLogger.info('🔍 [NETWORK_MONITOR] Firestore接続チェック開始');

    final previousStatus = _currentStatus;

    // 既にオフライン系状態の時だけ「チェック中」をUIへ反映する。
    // オンライン中の単発失敗ではバナーを出さないため、通常時は状態を維持する。
    if (previousStatus != NetworkStatus.online) {
      _updateStatus(NetworkStatus.checking);
    }
    _lastCheckTime = DateTime.now();

    for (var attempt = 1; attempt <= offlineFailureThreshold; attempt++) {
      try {
        // Firestoreからデータ取得を試行（キャッシュを使わず、サーバーから取得）
        AppLogger.info(
            '🔍 [NETWORK_MONITOR] Firestoreクエリ実行中... (attempt $attempt/$offlineFailureThreshold)');

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
        _consecutiveCheckFailures = 0;
        _lastSuccessTime = DateTime.now();
        AppLogger.info(
            '✅ [NETWORK_MONITOR] Firestore接続成功 - ドキュメント存在: ${snapshot.exists}');
        _updateStatus(NetworkStatus.online);

        // 自動リトライを停止（オンラインに復帰したため）
        stopAutoRetry();

        return true;
      } on TimeoutException catch (e) {
        AppLogger.warning(
            '⏱️ [NETWORK_MONITOR] Firestore接続タイムアウト（5秒）: $e (attempt $attempt/$offlineFailureThreshold)');

        if (_shouldRetryTransientFailure(previousStatus, attempt)) {
          AppLogger.warning(
              '⚠️ [NETWORK_MONITOR] 単発タイムアウトの可能性 - ${transientRetryDelay.inMilliseconds}ms 後に再試行');
          await Future.delayed(transientRetryDelay);
          continue;
        }

        _recordFailedCheckAndGoOffline();
        return false;
      } on FirebaseException catch (e) {
        // 🔥 P2 FIX: permission-denied / unauthenticated は認証問題であり、
        // ネットワーク障害ではない。公開コレクションで再チェックする。
        if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
          AppLogger.warning(
              '🔐 [NETWORK_MONITOR] 認証エラー検出（${e.code}）- 公開コレクションで再チェック');
          try {
            await FirebaseFirestore.instance
                .collection('furestorenews')
                .limit(1)
                .get(const GetOptions(source: Source.server))
                .timeout(connectionTimeout);
            // 公開コレクションアクセス成功 → ネットワークはオンライン
            _consecutiveCheckFailures = 0;
            _lastSuccessTime = DateTime.now();
            AppLogger.info('✅ [NETWORK_MONITOR] ネットワークはオンライン（認証エラーのみ）');
            _updateStatus(NetworkStatus.online);
            stopAutoRetry();
            return true;
          } catch (fallbackError) {
            AppLogger.warning(
                '❌ [NETWORK_MONITOR] 公開コレクションもアクセス不可: $fallbackError (attempt $attempt/$offlineFailureThreshold)');

            if (_shouldRetryTransientFailure(previousStatus, attempt)) {
              AppLogger.warning(
                  '⚠️ [NETWORK_MONITOR] 単発の名前解決失敗の可能性 - ${transientRetryDelay.inMilliseconds}ms 後に再試行');
              await Future.delayed(transientRetryDelay);
              continue;
            }

            _recordFailedCheckAndGoOffline();
            return false;
          }
        }

        AppLogger.warning(
            '❌ [NETWORK_MONITOR] Firestore接続エラー: ${e.code} - ${e.message} (attempt $attempt/$offlineFailureThreshold)');

        if (_shouldRetryTransientFailure(previousStatus, attempt)) {
          AppLogger.warning(
              '⚠️ [NETWORK_MONITOR] 一時的なFirebase接続失敗の可能性 - ${transientRetryDelay.inMilliseconds}ms 後に再試行');
          await Future.delayed(transientRetryDelay);
          continue;
        }

        _recordFailedCheckAndGoOffline();
        return false;
      } catch (e, stackTrace) {
        AppLogger.error(
            '❌ [NETWORK_MONITOR] Firestore接続エラー（予期しない）: $e (attempt $attempt/$offlineFailureThreshold)');
        AppLogger.error('📍 [NETWORK_MONITOR] スタックトレース: $stackTrace');

        if (_shouldRetryTransientFailure(previousStatus, attempt)) {
          AppLogger.warning(
              '⚠️ [NETWORK_MONITOR] 単発の予期しない失敗の可能性 - ${transientRetryDelay.inMilliseconds}ms 後に再試行');
          await Future.delayed(transientRetryDelay);
          continue;
        }

        _recordFailedCheckAndGoOffline();
        return false;
      }
    }

    return false;
  }

  bool _shouldRetryTransientFailure(
    NetworkStatus previousStatus,
    int attempt,
  ) {
    return previousStatus == NetworkStatus.online &&
        attempt < offlineFailureThreshold;
  }

  void _recordFailedCheckAndGoOffline() {
    _consecutiveCheckFailures += 1;
    final elapsedSinceLastSuccess = _lastSuccessTime == null
        ? 'unknown'
        : '${DateTime.now().difference(_lastSuccessTime!).inSeconds}s';
    AppLogger.warning(
        '📉 [NETWORK_MONITOR] オフライン判定: failures=$_consecutiveCheckFailures, lastSuccessAgo=$elapsedSinceLastSuccess');
    _updateStatus(NetworkStatus.offline);
  }

  /// 自動リトライを開始
  ///
  /// 初回3分・2回目5分・3回目以降10分間隔で Firestore 接続チェックを実行する。
  /// オンラインに復帰すると自動的に停止する。
  void startAutoRetry() {
    // 既に実行中なら何もしない
    if (_retryTimer != null && _retryTimer!.isActive) {
      AppLogger.info('ℹ️ [NETWORK_MONITOR] 自動リトライは既に実行中');
      return;
    }

    _retryAttemptCount = 0;
    _scheduleNextRetry();
  }

  void _scheduleNextRetry() {
    final Duration interval;
    if (_retryAttemptCount == 0) {
      interval = _retryInterval1;
    } else if (_retryAttemptCount == 1) {
      interval = _retryInterval2;
    } else {
      interval = _retryIntervalN;
    }
    _currentRetryInterval = interval;

    AppLogger.info(
        '🔄 [NETWORK_MONITOR] 自動リトライスケジュール（${interval.inMinutes}分後、試行${_retryAttemptCount + 1}回目）');

    _retryTimer = Timer(interval, () async {
      _retryAttemptCount++;
      AppLogger.info(
          '🔄 [NETWORK_MONITOR] 自動リトライ実行中（試行$_retryAttemptCount回目）...');

      final isOnline = await checkFirestoreConnection();

      if (!isOnline) {
        // checkFirestoreConnection 内で stopAutoRetry() が呼ばれないため次をスケジュール
        _scheduleNextRetry();
      }
      // isOnline の場合は checkFirestoreConnection 内で stopAutoRetry() が呼ばれる
    });
  }

  /// 自動リトライを停止
  void stopAutoRetry() {
    if (_retryTimer != null && _retryTimer!.isActive) {
      AppLogger.info('⏹️ [NETWORK_MONITOR] 自動リトライ停止');
      _retryTimer?.cancel();
      _retryTimer = null;
    }
    _retryAttemptCount = 0;
  }

  /// Firestore操作が成功したことを報告
  ///
  /// グループ作成やリスト操作など、Firestore操作が成功した時に呼び出す。
  /// 現在オフライン状態の場合、オンラインに復帰させてバナーを非表示にする。
  void reportFirestoreSuccess() {
    _consecutiveCheckFailures = 0;
    _lastSuccessTime = DateTime.now();
    if (_currentStatus != NetworkStatus.online) {
      AppLogger.info(
          '✅ [NETWORK_MONITOR] Firestore操作成功を検出 → オンライン復帰 (旧状態: $_currentStatus)');
      _updateStatus(NetworkStatus.online);
      stopAutoRetry();
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
    final remaining = _currentRetryInterval - elapsed;

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
