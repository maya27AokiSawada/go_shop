/// アプリ内課金タイプ
enum PurchaseType {
  /// 無料（広告あり）
  free,

  /// Premiumプラン（月額）（全広告非表示）
  subscribe,

  /// 早期ダウンロード特典（1年間・全広告非表示・Premium同等の上限）
  /// 期限切れは Functions が Firestore を `free` に戻して反映する。
  purchase,

  /// 家族特典（Premium 利用者のクーポンで付与・全広告非表示・Premium同等の上限）
  /// 発行者の Premium が無効になると Functions が Firestore を `free` に戻す。
  family,
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
      case PurchaseType.family:
        return 'family';
    }
  }

  /// 表示名
  String get displayName {
    switch (this) {
      case PurchaseType.free:
        return '無料プラン';
      case PurchaseType.subscribe:
        return 'Premiumプラン（月額）';
      case PurchaseType.purchase:
        return '早期ダウンロード特典';
      case PurchaseType.family:
        return '家族特典';
    }
  }

  /// Firestore文字列からの変換
  static PurchaseType fromFirestoreValue(String? value) {
    switch (value) {
      case 'subscribe':
        return PurchaseType.subscribe;
      case 'purchase':
        return PurchaseType.purchase;
      case 'family':
        return PurchaseType.family;
      default:
        return PurchaseType.free;
    }
  }

  /// インタースティシャル広告を非表示にするか
  bool get hidesInterstitialAds => this != PurchaseType.free;

  /// バナー広告を非表示にするか
  bool get hidesBannerAds => this != PurchaseType.free;
}
