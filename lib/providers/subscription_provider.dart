import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../providers/auth_provider.dart';

/// 課金プランの種類
enum SubscriptionPlan {
  free, // 無料プラン（広告あり）
  yearly, // 年間プラン（500円）
  threeYear, // 3年プラン（800円）
}

/// 課金状態
class SubscriptionState {
  final SubscriptionPlan plan;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final bool isTrialActive;
  final DateTime? trialStartDate;
  final int trialDays;

  const SubscriptionState({
    this.plan = SubscriptionPlan.free,
    this.purchaseDate,
    this.expiryDate,
    this.isTrialActive = false,
    this.trialStartDate,
    this.trialDays = 7,
  });

  /// プレミアム機能が利用可能かどうか
  bool get isPremiumActive {
    final now = DateTime.now();

    // 無料体験期間中
    if (isTrialActive && trialStartDate != null) {
      final trialEnd = trialStartDate!.add(Duration(days: trialDays));
      if (now.isBefore(trialEnd)) {
        return true;
      }
    }

    // 有料プラン契約中
    if (plan != SubscriptionPlan.free && expiryDate != null) {
      return now.isBefore(expiryDate!);
    }

    return false;
  }

  /// 無料体験期間の残り日数
  int get remainingTrialDays {
    if (!isTrialActive || trialStartDate == null) return 0;

    final now = DateTime.now();
    final trialEnd = trialStartDate!.add(Duration(days: trialDays));

    if (now.isAfter(trialEnd)) return 0;

    return trialEnd.difference(now).inDays + 1; // 当日も含める
  }

  /// プランの表示名
  String get planDisplayName {
    switch (plan) {
      case SubscriptionPlan.free:
        return '無料プラン';
      case SubscriptionPlan.yearly:
        return '年間プラン（¥500）';
      case SubscriptionPlan.threeYear:
        return '3年プラン（¥800）';
    }
  }

  /// プランの価格
  int get planPrice {
    switch (plan) {
      case SubscriptionPlan.free:
        return 0;
      case SubscriptionPlan.yearly:
        return 500;
      case SubscriptionPlan.threeYear:
        return 800;
    }
  }

  SubscriptionState copyWith({
    SubscriptionPlan? plan,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    bool? isTrialActive,
    DateTime? trialStartDate,
    int? trialDays,
  }) {
    return SubscriptionState(
      plan: plan ?? this.plan,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialDays: trialDays ?? this.trialDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan.index,
      'purchaseDate': purchaseDate?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'isTrialActive': isTrialActive,
      'trialStartDate': trialStartDate?.millisecondsSinceEpoch,
      'trialDays': trialDays,
    };
  }

  factory SubscriptionState.fromMap(Map<String, dynamic> map) {
    return SubscriptionState(
      plan: SubscriptionPlan.values[map['plan'] ?? 0],
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['purchaseDate'])
          : null,
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
          : null,
      isTrialActive: map['isTrialActive'] ?? false,
      trialStartDate: map['trialStartDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['trialStartDate'])
          : null,
      trialDays: map['trialDays'] ?? 7,
    );
  }
}

/// 課金状態管理プロバイダー
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    _loadSubscriptionState();
  }

  static const String _boxKey = 'subscription_state';

  Box<Map>? get _box {
    try {
      if (Hive.isBoxOpen('subscriptions')) {
        return Hive.box<Map>('subscriptions');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 課金状態をHiveから読み込み
  Future<void> _loadSubscriptionState() async {
    try {
      final box = _box;
      if (box != null && box.containsKey(_boxKey)) {
        final data = Map<String, dynamic>.from(box.get(_boxKey) ?? {});
        state = SubscriptionState.fromMap(data);
      }
      // 未ログイン状態では何もしない（広告も表示しない）
    } catch (e) {
      // エラー時はデフォルト状態を維持
    }
  }

  /// 課金状態をHiveに保存
  Future<void> _saveSubscriptionState() async {
    try {
      final box = _box;
      if (box != null) {
        await box.put(_boxKey, state.toMap());
      }
    } catch (e) {
      // 保存エラーは無視（メモリ上の状態は維持）
    }
  }

  /// サインアップ時の無料期間を開始（1か月間）
  Future<void> startSignupFreePeriod() async {
    state = state.copyWith(
      isTrialActive: true,
      trialStartDate: DateTime.now(),
      trialDays: 30, // 1か月間無料
    );
    await _saveSubscriptionState();
  }

  /// 無料体験を開始（既存メソッド保持）
  Future<void> startFreeTrial() async {
    state = state.copyWith(
      isTrialActive: true,
      trialStartDate: DateTime.now(),
      trialDays: 30, // サインアップ時は1か月
    );
    await _saveSubscriptionState();
  }

  /// 年間プランを購入
  Future<void> purchaseYearlyPlan() async {
    final now = DateTime.now();
    state = state.copyWith(
      plan: SubscriptionPlan.yearly,
      purchaseDate: now,
      expiryDate: now.add(const Duration(days: 365)),
      isTrialActive: false, // 体験版は終了
    );
    await _saveSubscriptionState();
  }

  /// 3年プランを購入
  Future<void> purchaseThreeYearPlan() async {
    final now = DateTime.now();
    state = state.copyWith(
      plan: SubscriptionPlan.threeYear,
      purchaseDate: now,
      expiryDate: now.add(const Duration(days: 365 * 3)),
      isTrialActive: false, // 体験版は終了
    );
    await _saveSubscriptionState();
  }

  /// 無料プランに戻す（テスト用）
  Future<void> resetToFree() async {
    state = const SubscriptionState();
    await _saveSubscriptionState();
  }

  /// プレミアム機能が利用可能かどうか
  bool get isPremiumActive => state.isPremiumActive;

  /// 広告を表示すべきかどうか
  bool get shouldShowAds => !isPremiumActive;

  /// 課金催促メッセージを表示すべきかどうか（3週間後）
  bool get shouldShowPaymentReminder {
    if (!state.isTrialActive || state.trialStartDate == null) return false;

    final now = DateTime.now();
    final reminderDate =
        state.trialStartDate!.add(const Duration(days: 21)); // 3週間後

    return now.isAfter(reminderDate) && !isPremiumActive;
  }

  /// 課金催促メッセージを取得
  String get paymentReminderMessage {
    final remainingDays = state.remainingTrialDays;
    if (remainingDays > 0) {
      return '無料期間は残り$remainingDays日です。継続利用には課金が必要になります。';
    } else {
      return '無料期間が終了しました。プレミアムプランにアップグレードしてください。';
    }
  }
}

/// 課金状態プロバイダー
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(),
);

/// プレミアム機能が利用可能かどうかのプロバイダー
final isPremiumActiveProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.isPremiumActive;
});

/// 広告表示が必要かどうかのプロバイダー（認証状態考慮）
final shouldShowAdsProvider = Provider<bool>((ref) {
  // 認証状態を確認
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        // 未ログイン状態では広告を表示しない
        return false;
      } else {
        // ログイン済みの場合はプレミアム状態をチェック
        final isPremium = ref.watch(isPremiumActiveProvider);
        return !isPremium;
      }
    },
    loading: () => false, // ロード中は広告なし
    error: (_, __) => false, // エラー時は広告なし
  );
});

/// 課金催促メッセージを表示すべきかどうかのプロバイダー
final shouldShowPaymentReminderProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false; // 未ログインでは表示しない

      final notifier = ref.read(subscriptionProvider.notifier);
      return notifier.shouldShowPaymentReminder;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});
