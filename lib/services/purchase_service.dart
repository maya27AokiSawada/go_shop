import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/purchase_type.dart';
import '../services/error_log_service.dart';
import '../utils/app_logger.dart';

enum PurchaseFlowStatus {
  idle,
  pending,
  purchased,
  restored,
  canceled,
  error,
}

class PurchaseFlowState {
  final PurchaseFlowStatus status;
  final String? message;

  const PurchaseFlowState(this.status, {this.message});
}

class VerifiedPurchaseResult {
  final bool storeAcknowledged;

  const VerifiedPurchaseResult({required this.storeAcknowledged});
}

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
  Future<void>? _initializationFuture;
  final StreamController<PurchaseFlowState> _statusController =
      StreamController<PurchaseFlowState>.broadcast();

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  PurchaseFlowState _currentState =
      const PurchaseFlowState(PurchaseFlowStatus.idle);

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get isAvailable => _isAvailable;
  PurchaseFlowState get currentState => _currentState;
  Stream<PurchaseFlowState> get statusStream => _statusController.stream;

  void _setStatus(PurchaseFlowStatus status, {String? message}) {
    _currentState = PurchaseFlowState(status, message: message);
    if (!_statusController.isClosed) {
      _statusController.add(_currentState);
    }
  }

  /// ストリーム監視を開始し、ストアが利用可能か確認する
  Future<void> initialize() {
    return _initializationFuture ??= _initialize().whenComplete(() {
      if (!_isAvailable) {
        _initializationFuture = null;
      }
    });
  }

  Future<void> _initialize() async {
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
          _setStatus(
            PurchaseFlowStatus.error,
            message: '購入状態の確認に失敗しました。時間をおいて再度お試しください。',
          );
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
        _setStatus(
          PurchaseFlowStatus.error,
          message: 'Premium商品を取得できませんでした。',
        );
        return;
      }

      Log.info('[$_logTag] Premium Monthly の購入フローを開始');
      _setStatus(
        PurchaseFlowStatus.pending,
        message: 'ストアで購入手続きを進めています。',
      );
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _setStatus(
          PurchaseFlowStatus.error,
          message: '購入手続きを開始できませんでした。',
        );
      }
    } catch (e) {
      Log.error('[$_logTag] buyPremiumMonthly エラー: $e');
      await ErrorLogService.logOperationError('Premium購入', '$e');
      _setStatus(
        PurchaseFlowStatus.error,
        message: '購入手続きでエラーが発生しました。',
      );
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
      _setStatus(
        PurchaseFlowStatus.pending,
        message: '購入履歴を確認しています。',
      );
      await _iap.restorePurchases();
      Log.info('[$_logTag] 購入履歴の復元が完了しました');
      if (_currentState.status == PurchaseFlowStatus.pending) {
        _setStatus(
          PurchaseFlowStatus.idle,
          message: '購入履歴を確認しました。復元対象がある場合は自動的に反映されます。',
        );
      }
    } catch (e) {
      Log.error('[$_logTag] restorePurchases エラー: $e');
      await ErrorLogService.logOperationError('購入の復元', '$e');
      _setStatus(
        PurchaseFlowStatus.error,
        message: '購入履歴の復元に失敗しました。',
      );
    }
  }

  /// 購入ストリームのコールバック
  Future<void> _onPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      try {
        await _handlePurchase(purchase);
      } catch (e, stackTrace) {
        Log.error('[$_logTag] 購入更新処理エラー: $e', e, stackTrace);
        await ErrorLogService.logOperationError('購入状態更新', '$e', stackTrace);
        _setStatus(
          PurchaseFlowStatus.error,
          message: '購入状態を反映できませんでした。購入の復元をお試しください。',
        );
      }
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    Log.info(
        '[$_logTag] 購入更新: id=${purchase.productID}, status=${purchase.status}');

    switch (purchase.status) {
      case PurchaseStatus.pending:
        _setStatus(
          PurchaseFlowStatus.pending,
          message: '購入処理を確認しています。',
        );
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (!_isSupportedProduct(purchase.productID)) {
          throw StateError('未対応の商品IDです: ${purchase.productID}');
        }

        // Functionsでストア検証と権限付与が完了した場合だけ取引を完了する。
        final verification = await verifyPurchaseWithServer(purchase);
        Log.info('[$_logTag] サーバー購入検証完了: ${purchase.productID}');

        if (purchase.pendingCompletePurchase &&
            !verification.storeAcknowledged) {
          await _iap.completePurchase(purchase);
        }

        final restored = purchase.status == PurchaseStatus.restored;
        _setStatus(
          restored ? PurchaseFlowStatus.restored : PurchaseFlowStatus.purchased,
          message: restored ? 'Premiumプランを復元しました。' : 'Premiumプランが有効になりました。',
        );
        return;
      case PurchaseStatus.error:
        final message = purchase.error?.message ?? '購入処理でエラーが発生しました。';
        Log.error('[$_logTag] 購入エラー: ${purchase.error}');
        await ErrorLogService.logOperationError('Premium購入', message);
        _setStatus(PurchaseFlowStatus.error, message: message);
        return;
      case PurchaseStatus.canceled:
        _setStatus(
          PurchaseFlowStatus.canceled,
          message: '購入はキャンセルされました。',
        );
        return;
    }
  }

  bool _isSupportedProduct(String productId) {
    return isSupportedProductId(productId);
  }

  static bool isSupportedProductId(String productId) {
    return productId == _ProductIds.subscription ||
        productId == _ProductIds.premiumMonthly ||
        productId == _ProductIds.premiumYearly ||
        productId == _ProductIds.oneTimePurchase;
  }

  PurchaseType _purchaseTypeForProduct(String productId) {
    return purchaseTypeForProductId(productId);
  }

  static PurchaseType purchaseTypeForProductId(String productId) {
    switch (productId) {
      case _ProductIds.subscription:
      case _ProductIds.premiumMonthly:
      case _ProductIds.premiumYearly:
        return PurchaseType.subscribe;
      case _ProductIds.oneTimePurchase:
        return PurchaseType.purchase;
      default:
        throw ArgumentError.value(productId, 'productId', '未対応の商品IDです');
    }
  }

  Future<VerifiedPurchaseResult> verifyPurchaseWithServer(
    PurchaseDetails purchase,
  ) async {
    final source = purchase.verificationData.source;
    final platform = switch (source) {
      'google_play' => 'google_play',
      'app_store' => 'app_store',
      _ => throw StateError('未対応の購入元です: $source'),
    };
    final verificationData = purchase.verificationData.serverVerificationData;
    if (verificationData.isEmpty) {
      throw StateError('ストア検証データが空です');
    }

    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-northeast1',
    ).httpsCallable('verifyPurchase');
    final response = await callable.call<Map<String, dynamic>>({
      'platform': platform,
      'productId': purchase.productID,
      'verificationData': verificationData,
    });
    final data = response.data;
    if (data['verified'] != true || data['purchaseType'] != 'subscribe') {
      throw StateError('サーバーが購入を承認しませんでした');
    }

    return VerifiedPurchaseResult(
      storeAcknowledged: data['storeAcknowledged'] == true,
    );
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
    _subscription = null;
    _initializationFuture = null;
    _statusController.close();
  }
}
