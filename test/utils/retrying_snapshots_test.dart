import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/utils/retrying_snapshots.dart';

void main() {
  const delays = [Duration(milliseconds: 10), Duration(milliseconds: 20)];

  test('エラーで止まったら購読し直し、エラーは購読側に流さない', () async {
    final sources = <StreamController<int>>[];
    final stream = retryingSnapshots<int>(() {
      final source = StreamController<int>();
      sources.add(source);
      return source.stream;
    }, label: 'TEST', retryDelays: delays);

    final values = <int>[];
    final errors = <Object>[];
    final sub = stream.listen(values.add, onError: errors.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    sources[0].add(1);
    sources[0].addError(Exception('permission-denied'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(sources, hasLength(2));
    sources[1].add(2);
    await Future<void>.delayed(Duration.zero);

    expect(values, [1, 2]);
    expect(errors, isEmpty);
  });

  test('失敗が続くと待ち時間を延ばし、値を受け取ったら最初に戻す', () async {
    final sources = <StreamController<int>>[];
    final stream = retryingSnapshots<int>(() {
      final source = StreamController<int>();
      sources.add(source);
      return source.stream;
    }, label: 'TEST', retryDelays: delays);
    final sub = stream.listen((_) {});
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    sources[0].addError(Exception('1'));
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(sources, hasLength(2)); // 10ms 後に再接続

    sources[1].addError(Exception('2'));
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(sources, hasLength(2)); // 2回目は 20ms 待つ
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(sources, hasLength(3));

    sources[2].add(1); // 値を受け取ったので待ち時間を戻す
    sources[2].addError(Exception('3'));
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(sources, hasLength(4));
  });

  test('購読をやめたら再接続しない', () async {
    final sources = <StreamController<int>>[];
    final stream = retryingSnapshots<int>(() {
      final source = StreamController<int>();
      sources.add(source);
      return source.stream;
    }, label: 'TEST', retryDelays: delays);
    final sub = stream.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    sources[0].addError(Exception('permission-denied'));
    await sub.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(sources, hasLength(1));
  });
}
