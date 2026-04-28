// lib/providers/purchase_sync_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_type.dart';
import 'purchase_type_provider.dart';
import 'subscription_provider.dart';

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
        // Google Playで有料購入済み → Hiveをプレミアム状態に同期
        // すでにプレミアムならスキップ（無駄な書き込み防止）
        if (!currentState.isPremiumActive) {
          notifier.syncFromGooglePlay(purchaseType);
        }
        break;
      case PurchaseType.free:
        // Firestoreがfreeの場合、試用期間が有効なら何もしない
        // （試用期間はFirestoreに依存せずHiveで管理するため）
        break;
    }
  });
});
