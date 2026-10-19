import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/family_coupon_service.dart';
import 'auth_provider.dart';

final familyCouponServiceProvider =
    Provider<FamilyCouponService>((ref) => FamilyCouponService());

/// 自分の家族特典の情報（発行したクーポン・特典を渡している家族・発行者）
final familyCouponStatusProvider = StreamProvider<FamilyCouponStatus>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream<FamilyCouponStatus>.empty(),
    error: (_, __) => const Stream<FamilyCouponStatus>.empty(),
    data: (user) {
      if (user == null) return Stream.value(const FamilyCouponStatus());
      return ref.watch(familyCouponServiceProvider).watchStatus();
    },
  );
});
