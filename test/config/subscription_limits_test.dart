import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/config/subscription_limits.dart';

void main() {
  group('SubscriptionLimits', () {
    test('Freeプランは最大3グループ、1グループ10人', () {
      final limits = SubscriptionLimits.forPremiumStatus(false);

      expect(limits.maxGroups, 3);
      expect(limits.maxMembersPerGroup, 10);
    });

    test('Premiumプランは最大20グループ、1グループ50人', () {
      final limits = SubscriptionLimits.forPremiumStatus(true);

      expect(limits.maxGroups, 20);
      expect(limits.maxMembersPerGroup, 50);
    });
  });
}
