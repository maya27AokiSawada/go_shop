import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/subscription_sales_config.dart';
import '../utils/app_logger.dart';

/// プレオープン特典の状態
class PreOpenBenefitStatus {
  const PreOpenBenefitStatus({required this.isActive, this.endDate});

  static const none = PreOpenBenefitStatus(isActive: false);

  /// Premium 相当の機能を解放中か
  final bool isActive;

  /// 特典の終了日時（対象外なら null）
  final DateTime? endDate;
}

/// プレオープン特典（課金開始日より前に作成したアカウントを、
/// 課金開始日の1か月後まで Premium 相当にする）の判定サービス。
///
/// 判定にはクライアントから書き換えられない値だけを使う。
/// - アカウント作成日時: Firebase Auth の `metadata.creationTime`
/// - 課金開始日: Firestore の `appConfig/subscription.salesStartDate`
/// Firestore の `purchaseType` は変更しない（課金状態とは独立して付与する）。
class PreOpenBenefitService {
  static const String _logTag = 'PRE_OPEN_BENEFIT';

  /// 取得済みの課金開始日（未設定だった場合は既定値）
  static DateTime? _cachedSalesStartDate;

  /// Firestore の `appConfig/subscription` から課金開始日を取得する。
  /// ドキュメントまたはフィールドが未設定の場合は null を返す。
  static Future<DateTime?> fetchSalesStartDate() async {
    final doc = await FirebaseFirestore.instance
        .doc(SubscriptionSalesConfig.firestoreDocPath)
        .get();
    final value = doc.data()?[SubscriptionSalesConfig.salesStartDateField];
    final date = value is Timestamp ? value.toDate() : null;
    _cachedSalesStartDate =
        date ?? SubscriptionSalesConfig.defaultSalesStartDate;
    return date;
  }

  /// 課金開始日を返す。取得済みならその値、取得に失敗したら既定値を使う。
  static Future<DateTime> getSalesStartDate() async {
    final cached = _cachedSalesStartDate;
    if (cached != null) return cached;
    try {
      return await fetchSalesStartDate() ??
          SubscriptionSalesConfig.defaultSalesStartDate;
    } catch (e) {
      Log.warning('[$_logTag] 課金開始日の取得に失敗したため既定値を使用: $e');
      return SubscriptionSalesConfig.defaultSalesStartDate;
    }
  }

  /// [user] のプレオープン特典の状態を返す。
  static Future<PreOpenBenefitStatus> getStatus(User? user) async {
    final createdAt = user?.metadata.creationTime;
    if (createdAt == null) return PreOpenBenefitStatus.none;

    final startDate = await getSalesStartDate();
    if (!createdAt.isBefore(startDate)) return PreOpenBenefitStatus.none;

    return PreOpenBenefitStatus(
      isActive: SubscriptionSalesConfig.isPreOpenBenefitActive(
        accountCreatedAt: createdAt,
        startDate: startDate,
      ),
      endDate: SubscriptionSalesConfig.preOpenBenefitEndDate(startDate),
    );
  }

  /// サインイン中のユーザーがプレオープン特典を利用中か
  static Future<bool> isActiveForCurrentUser() async {
    final status = await getStatus(FirebaseAuth.instance.currentUser);
    return status.isActive;
  }
}
