// lib/providers/group_limit_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/subscription_limits.dart';
import 'shared_group_provider.dart';
import 'subscription_provider.dart';

/// 現在のプランに対するグループ数の状態
class GroupLimitStatus {
  final int groupCount;
  final int maxGroups;

  const GroupLimitStatus({required this.groupCount, required this.maxGroups});

  /// Premium 解除（家族特典の解除・解約など）でグループ数が上限を超えているか
  bool get isExceeded => groupCount > maxGroups;
}

/// グループ数がプラン上限を超えているかを判定する Provider
///
/// 超過中はリスト画面への遷移を止め、ホーム画面とグループ画面で削除を促す。
/// グループ一覧の読み込み中は超過扱いにしない（起動直後に誤ってブロックしないため）。
final groupLimitStatusProvider = Provider<GroupLimitStatus>((ref) {
  final isPremium = ref.watch(isPremiumActiveProvider);
  final limits = SubscriptionLimits.forPremiumStatus(isPremium);
  final groupCount = ref.watch(allGroupsProvider).valueOrNull?.length ?? 0;
  return GroupLimitStatus(
    groupCount: groupCount,
    maxGroups: limits.maxGroups,
  );
});
