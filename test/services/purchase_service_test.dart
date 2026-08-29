import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:goshopping/services/purchase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePurchasePlatform fakePlatform;
  late TestPurchaseService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    fakePlatform = FakePurchasePlatform();
    InAppPurchasePlatform.instance = fakePlatform;
    service = TestPurchaseService();
  });

  tearDown(() async {
    service.dispose();
    await fakePlatform.close();
    debugDefaultTargetPlatformOverride = null;
  });

  test('initializeを並行実行しても購入ストリームを一度だけ購読する', () async {
    await Future.wait([service.initialize(), service.initialize()]);

    expect(fakePlatform.purchaseStreamReadCount, 1);
  });

  test('権限保存後に購入をcompleteする', () async {
    await service.initialize();
    final completed = service.statusStream.firstWhere(
      (state) => state.status == PurchaseFlowStatus.purchased,
    );
    final purchase = createPurchase(PurchaseStatus.purchased)
      ..pendingCompletePurchase = true;

    fakePlatform.emit([purchase]);
    await completed;

    expect(service.verifyCallCount, 1);
    expect(fakePlatform.completedProductIds, ['goshopping_premium_monthly']);
  });

  test('Functionsでacknowledge済みの場合はクライアントでcompleteしない', () async {
    service.storeAcknowledged = true;
    await service.initialize();
    final completed = service.statusStream.firstWhere(
      (state) => state.status == PurchaseFlowStatus.purchased,
    );
    final purchase = createPurchase(PurchaseStatus.purchased)
      ..pendingCompletePurchase = true;

    fakePlatform.emit([purchase]);
    await completed;

    expect(service.verifyCallCount, 1);
    expect(fakePlatform.completedProductIds, isEmpty);
  });

  test('権限保存に失敗した購入はcompleteしない', () async {
    service.failVerification = true;
    await service.initialize();
    final failed = service.statusStream.firstWhere(
      (state) => state.status == PurchaseFlowStatus.error,
    );
    final purchase = createPurchase(PurchaseStatus.purchased)
      ..pendingCompletePurchase = true;

    fakePlatform.emit([purchase]);
    await failed;

    expect(fakePlatform.completedProductIds, isEmpty);
  });

  test('pendingとcanceledは権限保存もcompleteもしない', () async {
    await service.initialize();

    final pendingState = service.statusStream.firstWhere(
      (state) => state.status == PurchaseFlowStatus.pending,
    );
    fakePlatform.emit([createPurchase(PurchaseStatus.pending)]);
    await pendingState;

    final canceledState = service.statusStream.firstWhere(
      (state) => state.status == PurchaseFlowStatus.canceled,
    );
    fakePlatform.emit([createPurchase(PurchaseStatus.canceled)]);
    await canceledState;

    expect(service.verifyCallCount, 0);
    expect(fakePlatform.completedProductIds, isEmpty);
  });

  test('未対応SKUは権限保存もcompleteもしない', () async {
    await service.initialize();
    final failed = service.statusStream.firstWhere(
      (state) => state.status == PurchaseFlowStatus.error,
    );
    final purchase = createPurchase(
      PurchaseStatus.purchased,
      productId: 'unknown_product',
    )..pendingCompletePurchase = true;

    fakePlatform.emit([purchase]);
    await failed;

    expect(service.verifyCallCount, 0);
    expect(fakePlatform.completedProductIds, isEmpty);
  });

  test('復元対象がない場合は処理中状態を解除する', () async {
    await service.initialize();

    await service.restorePurchases();

    expect(service.currentState.status, PurchaseFlowStatus.idle);
    expect(service.currentState.message, contains('購入履歴を確認しました'));
  });
}

PurchaseDetails createPurchase(
  PurchaseStatus status, {
  String productId = 'goshopping_premium_monthly',
}) {
  return PurchaseDetails(
    purchaseID: 'purchase-1',
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
    transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
    status: status,
  );
}

class TestPurchaseService extends PurchaseService {
  int verifyCallCount = 0;
  bool failVerification = false;
  bool storeAcknowledged = false;

  @override
  Future<VerifiedPurchaseResult> verifyPurchaseWithServer(
    PurchaseDetails purchase,
  ) async {
    verifyCallCount++;
    if (failVerification) {
      throw StateError('verification failed');
    }
    return VerifiedPurchaseResult(storeAcknowledged: storeAcknowledged);
  }
}

class FakePurchasePlatform extends InAppPurchasePlatform {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  final List<String> completedProductIds = [];
  int purchaseStreamReadCount = 0;

  void emit(List<PurchaseDetails> purchases) {
    _controller.add(purchases);
  }

  Future<void> close() => _controller.close();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream {
    purchaseStreamReadCount++;
    return _controller.stream;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: const [],
      notFoundIDs: const [],
    );
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedProductIds.add(purchase.productID);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
}
