import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/purchase_type.dart';
import '../services/firestore_user_name_service.dart';
import '../utils/app_logger.dart';

/// Google Play 商品ID
class _ProductIds {
  /// サブスク：¥200 / 3ヶ月（レガシー）
  static const String subscription = 'goshopping_subscribe';

  /// 買い切り：¥1,000（非消費型）
  static const String oneTimePurchase = 'goshopping_onetime_1000';

  /// Premium プラン月額（新規）
  static const String premiumMonthly = 'goshopping_premium_monthly';

  /// Premium プラン年額（新規）
  static const String premiumYearly = 'goshopping_premium_yearly';

  /// 現在ストアに登録済みのPremium月額SKUのみを取得する。
  static const Set<String> all = {
    premiumMonthly,
  };
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
  static const bool _monetizationEnabled = true;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get isAvailable => _isAvailable;

  /// ストリーム監視を開始し、ストアが利用可能か確認する
  Future<void> initialize() async {
    if (!_monetizationEnabled) {
      Log.info('[$_logTag] 課金機能は無効化されているため初期化をスキップ');
      _isAvailable = false;
      return;
    }

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        Log.warning('[$_logTag] ストアが利用できません');
        return;
      }

      // 購入完了ストリームを購読
      _subscription ??= _iap.purchaseStream.listen(
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
    if (!_monetizationEnabled) {
      Log.info('[$_logTag] 課金機能無効化のため商品取得をスキップ');
      return;
    }

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
    Log.info('[$_logTag] 課金機能は無効化されているため購入を中止');
  }

  /// 買い切り（¥1,000）を購入
  Future<void> buyOneTimePurchase() async {
    Log.info('[$_logTag] 課金機能は無効化されているため購入を中止');
  }

  /// Premium プラン（月額）を購入
  Future<void> buyPremiumMonthly() async {
    if (!_monetizationEnabled) {
      Log.warning('[$_logTag] 課金機能は無効化されているため Premium 購入を中止');
      return;
    }

    try {
      final product = _products
          .where((p) => p.id == _ProductIds.premiumMonthly)
          .firstOrNull;
      if (product == null) {
        Log.error(
            '[$_logTag] Premium Monthly 商品が見つかりません（SKU: ${_ProductIds.premiumMonthly}）');
        return;
      }

      Log.info('[$_logTag] Premium Monthly の購入フローを開始');
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      Log.error('[$_logTag] buyPremiumMonthly エラー: $e');
    }
  }

  /// Premium プラン（年額）を購入
  Future<void> buyPremiumYearly() async {
    if (!_monetizationEnabled) {
      Log.warning('[$_logTag] 課金機能は無効化されているため Premium 購入を中止');
      return;
    }

    try {
      final product =
          _products.where((p) => p.id == _ProductIds.premiumYearly).firstOrNull;
      if (product == null) {
        Log.error(
            '[$_logTag] Premium Yearly 商品が見つかりません（SKU: ${_ProductIds.premiumYearly}）');
        return;
      }

      Log.info('[$_logTag] Premium Yearly の購入フローを開始');
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      Log.error('[$_logTag] buyPremiumYearly エラー: $e');
    }
  }

  /// 🆕 購入の復元（再インストール時など）
  Future<void> restorePurchases() async {
    if (!_monetizationEnabled) {
      Log.info('[$_logTag] 課金機能は無効化されているため復元をスキップ');
      return;
    }

    try {
      Log.info('[$_logTag] 購入履歴を復元中...');
      await _iap.restorePurchases();
      Log.info('[$_logTag] 購入履歴の復元が完了しました');
    } catch (e) {
      Log.error('[$_logTag] restorePurchases エラー: $e');
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
      case _ProductIds.premiumMonthly:
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

  String get premiumMonthlyPrice =>
      getPrice(_ProductIds.premiumMonthly, _premiumMonthlyFallbackPrice);

  String get _premiumMonthlyFallbackPrice {
    switch (PlatformDispatcher.instance.locale.languageCode) {
      case 'ja':
        return '¥200/月';
      default:
        return 'US\$2/month';
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
