/// Premiumプランの新規受付期間。
///
/// 課金開始日より前はプレ公開期間として新規購入を受け付けない。
/// 課金開始日は Firestore の [firestoreDocPath] ドキュメントで管理する。
class SubscriptionSalesConfig {
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
}
