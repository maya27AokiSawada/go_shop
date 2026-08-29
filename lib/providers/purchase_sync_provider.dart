// lib/providers/purchase_sync_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_type.dart';
import 'purchase_type_provider.dart';
import 'subscription_provider.dart';

bool shouldResetSubscriptionToFree(SubscriptionState currentState) {
  return !currentState.isTrialActive || currentState.remainingTrialDays == 0;
}

/// Firestore課金状態（purchaseTypeProvider）をHive課金状態（subscriptionProvider）に橋渡しするProvider
///
/// このProviderをwatch/listenすることで、Google Play課金の結果が
/// isPremiumActiveProvider（Hiveベース）にリアクティブに反映される。
///
/// - `subscribe`/`purchase` → SubscriptionNotifier を年間プラン相当に更新
/// - `free` → 試用期間が残っていない場合のみ subscriptionProvider を無料状態にリセット
final purchaseSyncProvider = Provider<void>((ref) {
  final purchaseTypeAsync = ref.watch(purchaseTypeProvider);

  purchaseTypeAsync.whenData((purchaseType) {
    final notifier = ref.read(subscriptionProvider.notifier);
    final currentState = ref.read(subscriptionProvider);

    switch (purchaseType) {
      case PurchaseType.subscribe:
      case PurchaseType.purchase:
        // Firestoreの更新ごとにローカル猶予期限も更新する。
        notifier.syncFromGooglePlay(purchaseType);
        break;
      case PurchaseType.free:
        // Firestoreの失効・解約反映をHiveにも適用する。
        // 有効な無料体験だけはFirestoreのpurchaseTypeに依存しないため維持する。
        if (shouldResetSubscriptionToFree(currentState)) {
          notifier.resetToFree();
        }
        break;
    }
  });
});
