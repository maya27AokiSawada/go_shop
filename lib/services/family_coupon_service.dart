import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

/// 家族特典を受けている家族（発行者側から見た一覧の1人）
class FamilyMember {
  const FamilyMember({required this.uid, required this.displayName});

  final String uid;
  final String displayName;
}

/// 自分の users/{uid} にある家族特典の情報
class FamilyCouponStatus {
  const FamilyCouponStatus({
    this.couponCode,
    this.members = const [],
    this.sponsorUid,
    this.sponsorDisplayName,
  });

  /// 発行者として持っているクーポン（未発行なら null）
  final String? couponCode;

  /// 発行者として特典を渡している家族
  final List<FamilyMember> members;

  /// 家族特典を受けている場合の発行者（課金ユーザー）の uid
  final String? sponsorUid;
  final String? sponsorDisplayName;

  factory FamilyCouponStatus.fromUserData(Map<String, dynamic>? data) {
    final coupon = data?['familyCoupon'] as Map<String, dynamic>?;
    final benefit = data?['familyBenefit'] as Map<String, dynamic>?;
    final rawMembers =
        (coupon?['members'] as Map<String, dynamic>?) ?? const {};
    final members = rawMembers.entries
        .map((e) => FamilyMember(
              uid: e.key,
              displayName:
                  ((e.value as Map<String, dynamic>?)?['displayName']
                          as String?) ??
                      '',
            ))
        .toList();
    return FamilyCouponStatus(
      couponCode: coupon?['code'] as String?,
      members: members,
      sponsorUid: benefit?['sponsorUid'] as String?,
      sponsorDisplayName: benefit?['sponsorDisplayName'] as String?,
    );
  }
}

/// クーポン操作の失敗理由（Functions の details.reason）
class FamilyCouponException implements Exception {
  const FamilyCouponException(this.reason);

  /// invalid-code / own-coupon / not-family / sponsor-inactive /
  /// limit-reached / already-member / other-benefit-active / not-premium / unknown
  final String reason;

  @override
  String toString() => 'FamilyCouponException($reason)';
}

/// 家族特典クーポンのサービス（発行・入力・解除は Functions 経由）
class FamilyCouponService {
  FamilyCouponService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  /// 同時に特典を受けられる家族の人数（Functions の FAMILY_MEMBER_LIMIT と同じ）
  static const int memberLimit = 5;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  Stream<FamilyCouponStatus> watchStatus() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const FamilyCouponStatus());
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => FamilyCouponStatus.fromUserData(snapshot.data()));
  }

  /// Premium ユーザーのクーポンを取得する（未発行なら発行する）
  Future<String> issueCoupon() async {
    final data = await _call('issueFamilyCoupon', const {});
    return data['code'] as String;
  }

  /// クーポンを入力して家族特典を受け取る。発行者の表示名を返す。
  Future<String> redeemCoupon(String code) async {
    final data = await _call('redeemFamilyCoupon', {'code': code});
    return (data['sponsorDisplayName'] as String?) ?? '';
  }

  /// 発行者が家族の特典を解除する
  Future<void> removeMember(String memberUid) async {
    await _call('removeFamilyMember', {'memberUid': memberUid});
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(params);
      return response.data;
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      Log.warning('⚠️ [FAMILY_COUPON] $name 失敗: ${e.code} ${reason ?? e.message}');
      throw FamilyCouponException(reason ?? 'unknown');
    } catch (e) {
      Log.warning('⚠️ [FAMILY_COUPON] $name エラー: $e');
      throw const FamilyCouponException('unknown');
    }
  }
}
