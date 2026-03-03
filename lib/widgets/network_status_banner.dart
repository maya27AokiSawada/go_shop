import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_monitor_service.dart';
import '../utils/app_logger.dart';

/// ネットワーク状態を表示するバナーウィジェット
///
/// オフライン時にアプリ上部に表示され、次のリトライまでの
/// カウントダウンと手動リトライボタンを提供する。
///
/// オンライン状態では非表示になる。
class NetworkStatusBanner extends ConsumerStatefulWidget {
  const NetworkStatusBanner({super.key});

  @override
  ConsumerState<NetworkStatusBanner> createState() =>
      _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends ConsumerState<NetworkStatusBanner> {
  /// カウントダウン表示用のタイマー
  Timer? _countdownTimer;

  /// 残り時間の表示テキスト
  String _remainingTimeText = '';

  @override
  void initState() {
    super.initState();

    // カウントダウン表示を1秒ごとに更新
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateRemainingTime();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 残り時間のテキストを更新
  void _updateRemainingTime() {
    final networkMonitor = ref.read(networkMonitorProvider);
    final remaining = networkMonitor.timeUntilNextRetry;

    if (remaining == null) {
      _remainingTimeText = '';
      return;
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    _remainingTimeText = '次の確認まで: $minutes分$seconds秒';
  }

  /// 手動リトライボタンを押した時の処理
  Future<void> _onManualRetry() async {
    final networkMonitor = ref.read(networkMonitorProvider);

    AppLogger.info('🔄 [BANNER] 手動リトライボタンが押されました');

    // 手動リトライを実行
    final isOnline = await networkMonitor.manualRetry();

    AppLogger.info(
        '🔄 [BANNER] 手動リトライ結果: ${isOnline ? "オンライン復帰成功" : "まだオフライン"}');

    if (isOnline && mounted) {
      // オンラインに復帰した場合、Snackbarで通知
      AppLogger.info('✅ [BANNER] SnackBar表示: ネットワーク接続が復帰しました');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ネットワーク接続が復帰しました'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ネットワーク状態を監視
    final networkStatusAsync = ref.watch(networkStatusStreamProvider);

    return networkStatusAsync.when(
      data: (status) {
        AppLogger.info('📱 [BANNER] データ受信: $status');

        // オンライン状態なら非表示
        if (status == NetworkStatus.online) {
          AppLogger.info('📱 [BANNER] オンライン状態 → バナー非表示');
          return const SizedBox.shrink();
        }

        // カウントダウンテキストを更新
        _updateRemainingTime();

        // オフラインまたはチェック中の場合、バナーを表示
        AppLogger.info('📱 [BANNER] オフライン/チェック中 → バナー表示: $status');
        return _buildBanner(context, status);
      },
      loading: () {
        AppLogger.info('📱 [BANNER] Loading状態 → バナー非表示');
        return const SizedBox.shrink();
      },
      error: (error, stack) {
        // エラー時は非表示
        AppLogger.error('❌ [BANNER] ネットワーク状態の監視エラー: $error');
        return const SizedBox.shrink();
      },
    );
  }

  /// バナーウィジェットを構築
  Widget _buildBanner(BuildContext context, NetworkStatus status) {
    final isChecking = status == NetworkStatus.checking;
    final backgroundColor =
        isChecking ? Colors.blue.shade600 : Colors.orange.shade700;
    final icon = isChecking ? Icons.sync : Icons.wifi_off;
    final message = isChecking ? 'ネットワーク接続を確認中...' : 'ネットワーク障害が回復するまでお待ちください';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // アイコン
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),

          // メッセージとカウントダウン
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isChecking && _remainingTimeText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _remainingTimeText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 手動リトライボタン（チェック中は非表示）
          if (!isChecking) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _onManualRetry,
              tooltip: '手動でリトライ',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
