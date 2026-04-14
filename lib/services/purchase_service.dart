import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/purchase_type.dart';
import '../services/firestore_user_name_service.dart';
import '../utils/app_logger.dart';

/// Google Play 商品ID
class _ProductIds {
  /// サブスク：¥100 / 2ヶ月
  static const String subscription = 'goshopping_subscribe_2month';

  /// 買い切り：¥1,000（非消費型）
  static const String oneTimePurchase = 'goshopping_onetime_1000';

  static const Set<String> all = {subscription, oneTimePurchase};
}

/// アプリ内課金サービス
///
/// 購入フロー:
/// 1. [initialize] でストリーム監視を開始
/// 2. [loadProducts] で商品情報取得
/// 3. [buySubscription] / [buyOneTimePurchase] で購入開始
/// 4. 購入完了後Firestoreへ [savePurchaseType] 書き込み
/// 5. [dispose] でリソース解放
class PurchaseService {
  static const String _logTag = 'PurchaseService';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get isAvailable => _isAvailable;

  /// ストリーム監視を開始し、ストアが利用可能か確認する
  Future<void> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        Log.warning('[$_logTag] ストアが利用できません');
        return;
      }

      // 購入完了ストリームを購読
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onError: (Object error) {
          Log.error('[$_logTag] 購入ストリームエラー: $error');
        },
        cancelOnError: false,
      );

      await loadProducts();
    } catch (e) {
      Log.error('[$_logTag] 初期化エラー: $e');
    }
  }

  /// 商品情報を Google Play から取得
  Future<void> loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_ProductIds.all);

      if (response.error != null) {
        Log.error('[$_logTag] 商品取得エラー: ${response.error}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        Log.warning('[$_logTag] 未登録の商品ID: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      Log.info('[$_logTag] 商品取得完了: ${_products.map((p) => p.id).toList()}');
    } catch (e) {
      Log.error('[$_logTag] loadProducts エラー: $e');
    }
  }

  /// サブスクリプション（¥100/2ヶ月）を購入
  Future<void> buySubscription() async {
    await _buy(_ProductIds.subscription, isSubscription: true);
  }

  /// 買い切り（¥1,000）を購入
  Future<void> buyOneTimePurchase() async {
    await _buy(_ProductIds.oneTimePurchase, isSubscription: false);
  }

  Future<void> _buy(String productId, {required bool isSubscription}) async {
    if (!_isAvailable) {
      Log.warning('[$_logTag] ストアが利用不可');
      return;
    }

    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      Log.warning('[$_logTag] 商品が見つかりません: $productId');
      return;
    }

    final PurchaseParam param = PurchaseParam(productDetails: product);

    try {
      if (isSubscription) {
        await _iap.buyNonConsumable(purchaseParam: param);
      } else {
        await _iap.buyNonConsumable(purchaseParam: param);
      }
    } catch (e) {
      Log.error('[$_logTag] 購入エラー: $e');
    }
  }

  /// 購入の復元（再インストール時など）
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      Log.error('[$_logTag] 購入復元エラー: $e');
    }
  }

  /// 購入ストリームのコールバック
  Future<void> _onPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    Log.info(
        '[$_logTag] 購入更新: id=${purchase.productID}, status=${purchase.status}');

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Firestore に課金タイプを保存
      final type = _purchaseTypeForProduct(purchase.productID);
      await FirestoreUserNameService.savePurchaseType(type);
      Log.info('[$_logTag] 課金タイプ更新: ${type.firestoreValue}');
    }

    if (purchase.status == PurchaseStatus.error) {
      Log.error('[$_logTag] 購入エラー: ${purchase.error}');
    }

    // Android: 購入確定（consumeまたはacknowledge）
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  PurchaseType _purchaseTypeForProduct(String productId) {
    switch (productId) {
      case _ProductIds.subscription:
        return PurchaseType.subscribe;
      case _ProductIds.oneTimePurchase:
        return PurchaseType.purchase;
      default:
        return PurchaseType.free;
    }
  }

  /// 商品の価格文字列を取得（商品が見つからない場合はデフォルト表示）
  String getPrice(String productId, String fallback) {
    final product = _products.where((p) => p.id == productId).firstOrNull;
    return product?.price ?? fallback;
  }

  String get subscriptionPrice =>
      getPrice(_ProductIds.subscription, '¥100/2ヶ月');

  String get oneTimePurchasePrice =>
      getPrice(_ProductIds.oneTimePurchase, '¥1,000');

  void dispose() {
    _subscription?.cancel();
  }
}
