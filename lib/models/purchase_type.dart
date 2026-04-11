/// アプリ内課金タイプ
enum PurchaseType {
  /// 無料（広告あり）
  free,

  /// サブスク：¥100/2ヶ月（全広告非表示）
  subscribe,

  /// 買い切り：¥1,000（インタースティシャル広告のみ非表示）
  purchase,
}

extension PurchaseTypeExt on PurchaseType {
  /// Firestore保存用文字列
  String get firestoreValue {
    switch (this) {
      case PurchaseType.free:
        return 'free';
      case PurchaseType.subscribe:
        return 'subscribe';
      case PurchaseType.purchase:
        return 'purchase';
    }
  }

  /// 表示名
  String get displayName {
    switch (this) {
      case PurchaseType.free:
        return '無料プラン';
      case PurchaseType.subscribe:
        return 'サブスク（¥100/2ヶ月）';
      case PurchaseType.purchase:
        return '買い切り（¥1,000）';
    }
  }

  /// Firestore文字列からの変換
  static PurchaseType fromFirestoreValue(String? value) {
    switch (value) {
      case 'subscribe':
        return PurchaseType.subscribe;
      case 'purchase':
        return PurchaseType.purchase;
      default:
        return PurchaseType.free;
    }
  }

  /// インタースティシャル広告を非表示にするか
  bool get hidesInterstitialAds =>
      this == PurchaseType.subscribe || this == PurchaseType.purchase;

  /// バナー広告を非表示にするか
  bool get hidesBannerAds => this == PurchaseType.subscribe;
}
