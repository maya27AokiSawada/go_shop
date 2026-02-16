import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../utils/snackbar_helper.dart';

/// シンプルな広告バナーウィジェット（実際のAdMob等に置き換え可能）
class AdBannerWidget extends ConsumerWidget {
  final double? height;
  final EdgeInsets? margin;

  const AdBannerWidget({
    super.key,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowAds = ref.watch(shouldShowAdsProvider);

    // プレミアムユーザーには広告を表示しない
    if (!shouldShowAds) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height ?? 80,
      margin: margin ?? const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ads_click,
              color: Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '広告スペース',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'プレミアムで非表示',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// より目立つ広告バナー（ホーム画面用）
class HomeAdBannerWidget extends ConsumerWidget {
  const HomeAdBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowAds = ref.watch(shouldShowAdsProvider);
    final subscription = ref.watch(subscriptionProvider);

    // プレミアムユーザーには広告を表示しない
    if (!shouldShowAds) {
      return const SizedBox.shrink();
    }

    // 無料体験期間中の表示を調整
    final isTrialActive = subscription.isTrialActive;
    final remainingDays = subscription.remainingTrialDays;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        children: [
          if (isTrialActive && remainingDays > 0) ...[
            Row(
              children: [
                Icon(Icons.timer, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '無料体験期間 残り$remainingDays日',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'プレミアムプランで広告を非表示にしませんか？',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (isTrialActive && remainingDays > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPremiumDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      side: BorderSide(color: Colors.blue[300]!),
                    ),
                    child: const Text('プレミアムへ', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _PremiumUpgradeDialog(),
    );
  }
}

/// プレミアムアップグレードダイアログ
class _PremiumUpgradeDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.star, color: Colors.amber),
          SizedBox(width: 8),
          Text('プレミアムプラン'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨ プレミアム特典'),
          const SizedBox(height: 8),
          const Text('• 広告の完全非表示'),
          const Text('• プレミアムサポート'),
          const Text('• 新機能の優先アクセス'),
          const SizedBox(height: 16),
          if (subscription.isTrialActive) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Text(
                    '無料体験 残り${subscription.remainingTrialDays}日',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('料金プラン', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _PlanCard(
            title: '年間プラン',
            price: '¥500',
            period: '/年',
            description: '月額約42円',
            isRecommended: true,
            onTap: () => _purchaseYearlyPlan(context, ref),
          ),
          const SizedBox(height: 8),
          _PlanCard(
            title: '3年プラン',
            price: '¥800',
            period: '/3年',
            description: '月額約22円（お得！）',
            isRecommended: false,
            onTap: () => _purchaseThreeYearPlan(context, ref),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('後で'),
        ),
      ],
    );
  }

  void _purchaseYearlyPlan(BuildContext context, WidgetRef ref) {
    // 実際のアプリ内課金処理をここに実装
    ref.read(subscriptionProvider.notifier).purchaseYearlyPlan();

    Navigator.of(context).pop();
    SnackBarHelper.showSuccess(context, '年間プランにアップグレードしました！');
  }

  void _purchaseThreeYearPlan(BuildContext context, WidgetRef ref) {
    // 実際のアプリ内課金処理をここに実装
    ref.read(subscriptionProvider.notifier).purchaseThreeYearPlan();

    Navigator.of(context).pop();
    SnackBarHelper.showSuccess(context, '3年プランにアップグレードしました！');
  }
}

/// 料金プランカード
class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String description;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRecommended ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRecommended ? Colors.blue[300]! : Colors.grey[300]!,
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'おすすめ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isRecommended ? Colors.blue[700] : Colors.grey[700],
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
