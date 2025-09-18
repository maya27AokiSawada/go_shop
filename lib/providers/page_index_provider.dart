// lib/providers/navigation_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageIndexNotifier extends StateNotifier<int> {
  // コンストラクタで初期値を0に設定
  PageIndexNotifier() : super(0);

  // pageIndexの値を更新するメソッド
  void setPageIndex(int newIndex) {
    state = newIndex;
  }
  int getState() => state;
}
final pageIndexProvider = StateNotifierProvider<PageIndexNotifier, int>((ref) {
  return PageIndexNotifier();
});
