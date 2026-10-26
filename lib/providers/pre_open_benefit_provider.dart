// lib/providers/pre_open_benefit_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pre_open_benefit_service.dart';
import 'auth_provider.dart';

/// サインイン中のユーザーのプレオープン特典の状態
///
/// 特典の終了日時を過ぎたら再評価して、起動したままでも Premium 相当を解除する。
final preOpenBenefitProvider =
    FutureProvider<PreOpenBenefitStatus>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return PreOpenBenefitStatus.none;

  final status = await PreOpenBenefitService.getStatus(user);
  final endDate = status.endDate;
  if (status.isActive && endDate != null) {
    // 長いタイマーを避けるため最大1日ごとに再評価する
    var wait = endDate.difference(DateTime.now());
    if (wait > const Duration(days: 1)) wait = const Duration(days: 1);
    final timer = Timer(wait, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return status;
});

/// プレオープン特典で Premium 相当の機能を解放中か（読み込み中は false）
final isPreOpenBenefitActiveProvider = Provider<bool>((ref) {
  return ref.watch(preOpenBenefitProvider).valueOrNull?.isActive ?? false;
});
