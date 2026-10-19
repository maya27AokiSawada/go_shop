import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_type.dart';
import '../services/ad_service.dart';
import 'purchase_type_provider.dart';

/// 広告同意がないためマルチモードへの切り替えを禁止するか
///
/// 広告を表示できない（UMP の canRequestAds() が false）無料ユーザーのみ true。
/// 広告が表示されない課金ユーザーは対象外。
/// 同意状態を変えた後は ref.invalidate() で再評価する。
final multiModeBlockedByAdConsentProvider = FutureProvider<bool>((ref) async {
  final purchaseType = await ref.watch(purchaseTypeProvider.future);
  if (purchaseType.hidesBannerAds) return false;
  return ref.watch(adServiceProvider).isAdConsentMissing();
});
