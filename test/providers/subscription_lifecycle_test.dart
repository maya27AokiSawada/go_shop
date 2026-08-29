import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/purchase_type.dart';
import 'package:goshopping/providers/purchase_sync_provider.dart';
import 'package:goshopping/providers/subscription_provider.dart';
import 'package:goshopping/services/purchase_service.dart';

void main() {
  group('Subscription lifecycle', () {
    test('有効な無料体験中はFirestoreがfreeでも状態を維持する', () {
      final state = SubscriptionState(
        isTrialActive: true,
        trialStartDate: DateTime.now(),
        trialDays: 30,
      );

      expect(shouldResetSubscriptionToFree(state), isFalse);
    });

    test('有料状態はFirestoreがfreeになったらリセット対象になる', () {
      final state = SubscriptionState(
        plan: SubscriptionPlan.monthly,
        purchaseDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 35)),
      );

      expect(shouldResetSubscriptionToFree(state), isTrue);
    });

    test('期限切れの無料体験はリセット対象になる', () {
      final state = SubscriptionState(
        isTrialActive: true,
        trialStartDate: DateTime.now().subtract(const Duration(days: 31)),
        trialDays: 30,
      );

      expect(shouldResetSubscriptionToFree(state), isTrue);
    });

    test('Premium月額SKUはsubscribeへ変換される', () {
      expect(
        PurchaseService.purchaseTypeForProductId(
          'goshopping_premium_monthly',
        ),
        PurchaseType.subscribe,
      );
    });

    test('未対応SKUは無料権限として処理されない', () {
      expect(PurchaseService.isSupportedProductId('unknown_product'), isFalse);
      expect(
        () => PurchaseService.purchaseTypeForProductId('unknown_product'),
        throwsArgumentError,
      );
    });
  });
}
