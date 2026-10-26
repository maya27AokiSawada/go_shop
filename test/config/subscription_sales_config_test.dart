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

  group('プレオープン特典', () {
    test('終了日時は課金開始日の1か月後', () {
      expect(
        SubscriptionSalesConfig.preOpenBenefitEndDate(DateTime(2027, 1, 1)),
        DateTime(2027, 2, 1),
      );
      expect(
        SubscriptionSalesConfig.preOpenBenefitEndDate(DateTime(2026, 12, 15)),
        DateTime(2027, 1, 15),
      );
    });

    test('翌月に同じ日がなければ翌月の末日を終了日時にする', () {
      expect(
        SubscriptionSalesConfig.preOpenBenefitEndDate(DateTime(2027, 1, 31)),
        DateTime(2027, 2, 28),
      );
    });

    test('課金開始日より前に作成したアカウントは終了日時まで有効', () {
      bool isActive(DateTime createdAt, DateTime now) =>
          SubscriptionSalesConfig.isPreOpenBenefitActive(
            accountCreatedAt: createdAt,
            startDate: startDate,
            now: now,
          );

      final createdAt = DateTime(2026, 10, 26);
      // プレオープン期間中から特典を利用できる
      expect(isActive(createdAt, DateTime(2026, 11, 1)), isTrue);
      expect(isActive(createdAt, DateTime(2027, 1, 31, 23, 59, 59)), isTrue);
      expect(isActive(createdAt, DateTime(2027, 2, 1)), isFalse);
    });

    test('課金開始日以降に作成したアカウントは対象外', () {
      expect(
        SubscriptionSalesConfig.isPreOpenBenefitActive(
          accountCreatedAt: DateTime(2027, 1, 1),
          startDate: startDate,
          now: DateTime(2027, 1, 2),
        ),
        isFalse,
      );
    });
  });
}
