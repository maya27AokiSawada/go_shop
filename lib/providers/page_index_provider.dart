// lib/providers/page_index_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'page_index_provider.g.dart';

@riverpod
class PageIndexProvider extends _$PageIndexProvider {
  @override
  int build() => 0;

  void setPageIndex(int index) {
    state = index;
  }
}
