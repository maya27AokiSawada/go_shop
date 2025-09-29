// lib/providers/page_index_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageIndexNotifier extends StateNotifier<int> {
  // 初期値を設定します (例: 0)。
  PageIndexNotifier() : super(0);

  // 状態を変更するためのパブリックメソッドを定義します。
  // 状態は 'state' プロパティを通じて変更します。
  void setPageIndex(int newIndex) {
    state = newIndex;
  }
}
// StateNotifierProvider.autoDispose を使用して、
// リソースが不要になったら自動的に破棄されるようにします。
final pageIndexProvider = StateNotifierProvider.autoDispose<PageIndexNotifier, int>(
  (ref) {
    // StateNotifier のインスタンスを返します。
    return PageIndexNotifier();
  },
);
