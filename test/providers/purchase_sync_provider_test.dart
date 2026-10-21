import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/purchase_type.dart';
import 'package:goshopping/providers/purchase_sync_provider.dart';
import 'package:goshopping/providers/purchase_type_provider.dart';
import 'package:goshopping/providers/subscription_provider.dart';

void main() {
  group('purchaseSyncProvider', () {
    late StreamController<PurchaseType> purchaseTypes;
    late ProviderContainer container;

    setUp(() {
      purchaseTypes = StreamController<PurchaseType>();
      container = ProviderContainer(overrides: [
        purchaseTypeProvider.overrideWith((ref) => purchaseTypes.stream),
      ]);
      addTearDown(() {
        container.dispose();
        purchaseTypes.close();
      });
      // 画面などが課金状態を監視している状態にする
      container.listen(subscriptionProvider, (_, __) {});
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('課金状態を受け取った後に起動しても例外にならず Premium を反映する', () async {
      container.listen(purchaseTypeProvider, (_, __) {});
      purchaseTypes.add(PurchaseType.subscribe);
      await settle();

      // 起動時点で purchaseType が確定していると、build 中に同期処理が走る
      container.read(purchaseSyncProvider);
      await settle();

      expect(container.read(subscriptionProvider).isPremiumActive, isTrue);
    });

    test('起動後の課金状態の変化を反映する', () async {
      container.read(purchaseSyncProvider);

      purchaseTypes.add(PurchaseType.family);
      await settle();
      expect(container.read(subscriptionProvider).isPremiumActive, isTrue);

      purchaseTypes.add(PurchaseType.free);
      await settle();
      expect(container.read(subscriptionProvider).isPremiumActive, isFalse);
    });
  });
}
