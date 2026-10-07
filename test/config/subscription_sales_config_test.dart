import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/config/subscription_sales_config.dart';

void main() {
  final startDate = SubscriptionSalesConfig.defaultSalesStartDate;

  test('既定の課金開始日は2027年1月1日', () {
    expect(startDate, DateTime(2027, 1, 1));
  });

  test('課金開始日より前は新規受付を開始していない', () {
    expect(
      SubscriptionSalesConfig.isSalesOpen(startDate, DateTime(2026, 10, 7)),
      isFalse,
    );
    expect(
      SubscriptionSalesConfig.isSalesOpen(
        startDate,
        DateTime(2026, 12, 31, 23, 59, 59),
      ),
      isFalse,
    );
  });

  test('課金開始日以降は新規受付を開始する', () {
    expect(
      SubscriptionSalesConfig.isSalesOpen(startDate, DateTime(2027, 1, 1)),
      isTrue,
    );
    expect(
      SubscriptionSalesConfig.isSalesOpen(startDate, DateTime(2027, 6, 1)),
      isTrue,
    );
  });
}
