/// Premiumプランの新規受付期間。
///
/// 課金開始日より前はプレ公開期間として新規購入を受け付けない。
/// 課金開始日は Firestore の [firestoreDocPath] ドキュメントで管理する。
class SubscriptionSalesConfig {
  /// Canonical public page for Premium plan features, pricing, and availability.
  static const String premiumPlanDetailsUrl =
      'https://maya27aokisawada.github.io/go_shop/specifications/premium_plan';

  /// 課金開始日を保存する Firestore ドキュメントのパス。
  static const String firestoreDocPath = 'appConfig/subscription';

  /// 課金開始日のフィールド名（Timestamp 型）。
  static const String salesStartDateField = 'salesStartDate';

  /// Firestore から取得できない場合に使う課金開始日（端末のローカル時刻）。
  static final DateTime defaultSalesStartDate = DateTime(2027, 1, 1);

  /// [now] の時点で [startDate] からの新規受付が始まっているか。
  static bool isSalesOpen(DateTime startDate, [DateTime? now]) {
    return !(now ?? DateTime.now()).isBefore(startDate);
  }

  /// プレオープン特典の期間（課金開始日からの月数）。
  static const int preOpenBenefitMonths = 1;

  /// プレオープン特典の終了日時（課金開始日の [preOpenBenefitMonths] か月後）。
  ///
  /// 月末日始まりで翌月に同じ日がない場合は翌月の末日にする（1/31 → 2/28）。
  static DateTime preOpenBenefitEndDate(DateTime startDate) {
    final year = startDate.year;
    final month = startDate.month + preOpenBenefitMonths;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
      year,
      month,
      startDate.day > lastDay ? lastDay : startDate.day,
      startDate.hour,
      startDate.minute,
      startDate.second,
    );
  }

  /// [accountCreatedAt] に作成したアカウントが [now] の時点で
  /// プレオープン特典（Premium 相当）を受けられるか。
  ///
  /// 課金開始日より前に作成したアカウントが対象で、特典は終了日時まで続く。
  static bool isPreOpenBenefitActive({
    required DateTime accountCreatedAt,
    required DateTime startDate,
    DateTime? now,
  }) {
    if (!accountCreatedAt.isBefore(startDate)) return false;
    return (now ?? DateTime.now()).isBefore(preOpenBenefitEndDate(startDate));
  }
}
