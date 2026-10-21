import 'dart:async';
import 'dart:math';

import 'app_logger.dart';

/// 再接続までの待ち時間（失敗が続くほど長くし、最後の値で繰り返す）
const List<Duration> defaultSnapshotRetryDelays = [
  Duration(seconds: 5),
  Duration(seconds: 15),
  Duration(seconds: 30),
  Duration(seconds: 60),
];

/// エラーで止まっても購読し直す Firestore 監視ストリームを返す
///
/// Firestore の `snapshots()` はエラー（App Check の判定失敗による
/// permission-denied など）が1回起きるとストリームが終わり、自動では再接続しない。
/// このストリームはエラーを購読側に流さず、[retryDelays] の間隔を空けて
/// [subscribe] で購読し直す。値を受け取ったら待ち時間を最初に戻す。
Stream<T> retryingSnapshots<T>(
  Stream<T> Function() subscribe, {
  required String label,
  List<Duration> retryDelays = defaultSnapshotRetryDelays,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? retryTimer;
  var failures = 0;

  void listen() {
    subscription = subscribe().listen(
      (value) {
        failures = 0;
        controller.add(value);
      },
      onError: (Object error) {
        final delay = retryDelays[min(failures, retryDelays.length - 1)];
        failures++;
        subscription = null;
        Log.warning(
            '⚠️ [$label] リスナーが停止しました。${delay.inSeconds}秒後に再接続します: $error');
        retryTimer = Timer(delay, () {
          Log.info('🔄 [$label] リスナーを再接続します（$failures回目）');
          listen();
        });
      },
      onDone: () {
        if (subscription != null) controller.close();
      },
      cancelOnError: true,
    );
  }

  controller = StreamController<T>(
    onListen: listen,
    onCancel: () async {
      retryTimer?.cancel();
      await subscription?.cancel();
    },
  );
  return controller.stream;
}
