import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/models/purchase_type.dart';
import 'package:goshopping/services/family_coupon_service.dart';

void main() {
  group('PurchaseType.family', () {
    test('Firestore の family と相互変換できる', () {
      expect(PurchaseTypeExt.fromFirestoreValue('family'), PurchaseType.family);
      expect(PurchaseType.family.firestoreValue, 'family');
    });

    test('家族特典は Premium と同じく全広告を非表示にする', () {
      expect(PurchaseType.family.hidesBannerAds, isTrue);
      expect(PurchaseType.family.hidesInterstitialAds, isTrue);
      expect(PurchaseType.free.hidesInterstitialAds, isFalse);
    });
  });

  group('FamilyCouponStatus.fromUserData', () {
    test('発行者のクーポンと家族一覧を読み取る', () {
      final status = FamilyCouponStatus.fromUserData({
        'familyCoupon': {
          'code': 'ABCD-EFGH',
          'members': {
            'child': {'displayName': 'Kid'},
          },
        },
      });
      expect(status.couponCode, 'ABCD-EFGH');
      expect(status.members.single.uid, 'child');
      expect(status.members.single.displayName, 'Kid');
      expect(status.sponsorUid, isNull);
    });

    test('特典を受けている家族は発行者の uid を読み取る', () {
      final status = FamilyCouponStatus.fromUserData({
        'familyBenefit': {'sponsorUid': 'sponsor', 'sponsorDisplayName': 'Mom'},
      });
      expect(status.sponsorUid, 'sponsor');
      expect(status.sponsorDisplayName, 'Mom');
      expect(status.couponCode, isNull);
      expect(status.members, isEmpty);
    });

    test('ドキュメントがなくても空の状態を返す', () {
      final status = FamilyCouponStatus.fromUserData(null);
      expect(status.couponCode, isNull);
      expect(status.sponsorUid, isNull);
    });
  });
}
