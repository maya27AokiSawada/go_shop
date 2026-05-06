import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../l10n/l10n.dart';

/// プレミアム管理画面
class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final isPremium = subscription.isPremiumActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(texts.premiumPlan),
        backgroundColor: Colors.amber[100],
        foregroundColor: Colors.amber[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プレミアムステータス表示
            _buildStatusCard(context, subscription, isPremium),
            const SizedBox(height: 20),

            // 広告プレビュー
            if (!isPremium) ...[
              const Text(
                '📺 広告プレビュー',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const AdBannerWidget(height: 100),
              const SizedBox(height: 8),
              Text(
                'プレミアムプランにアップグレードすると、このような広告が表示されなくなります',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // プレミアム特典一覧
            _buildFeaturesCard(context),
            const SizedBox(height: 20),

            // 料金プラン
            if (!isPremium) ...[
              _buildPricingCard(context, ref),
              const SizedBox(height: 20),
            ],

            // デバッグ用コントロール（開発時のみ）
            _buildDebugControls(context, ref, subscription),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, SubscriptionState subscription, bool isPremium) {
    return Card(
      color: isPremium ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.schedule,
                  color: isPremium ? Colors.amber : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isPremium ? 'プレミアム会員' : subscription.planDisplayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (subscription.isTrialActive &&
                subscription.remainingTrialDays > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '無料体験期間 残り${subscription.remainingTrialDays}日',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${subscription.remainingTrialDays}日後に広告が表示されるようになります',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ] else if (isPremium) ...[
              Text(
                '広告非表示 + プレミアム機能をご利用いただけます',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[600],
                ),
              ),
              if (subscription.expiryDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  '有効期限: ${_formatDate(subscription.expiryDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ] else ...[
              Text(
                '広告が表示されます。プレミアムプランで非表示にできます。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✨ プレミアム特典',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('広告の完全非表示', '煩わしい広告が一切表示されません', true),
            _buildFeatureItem('プレミアムサポート', '優先サポートでお困りごとを解決', true),
            _buildFeatureItem('新機能の優先アクセス', 'β版機能をいち早く体験できます', true),
            _buildFeatureItem('データ優先同期', 'クラウド同期の優先処理', false), // 未実装
            _buildFeatureItem('テーマカスタマイズ', 'アプリの見た目をお好みに変更', false), // 未実装
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.schedule,
            color: isAvailable ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                Text(
                  isAvailable ? description : '$description (準備中)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💰 料金プラン',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 年間プラン
            _PricingPlanTile(
              title: '年間プラン',
              price: '¥500',
              period: '/年',
              monthlyPrice: '月額約¥42',
              features: const ['広告非表示', 'プレミアムサポート'],
              isRecommended: true,
              onTap: () => _purchaseYearlyPlan(context, ref),
            ),
            const SizedBox(height: 12),

            // 3年プラン
            _PricingPlanTile(
              title: '3年プラン',
              price: '¥800',
              period: '/3年',
              monthlyPrice: '月額約¥22（超お得！）',
              features: const ['広告非表示', 'プレミアムサポート', '長期割引'],
              isRecommended: false,
              onTap: () => _purchaseThreeYearPlan(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugControls(
      BuildContext context, WidgetRef ref, SubscriptionState subscription) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 開発者用コントロール',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(subscriptionProvider.notifier)
                          .startFreeTrial();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(texts.trialStarted)),
                        );
                      }
                    },
                    child: Text(texts.startTrial),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(subscriptionProvider.notifier)
                          .resetToFree();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(texts.resetToFree)),
                        );
                      }
                    },
                    child: Text(texts.resetToFree),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${subscription.planDisplayName}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (subscription.isTrialActive) ...[
              Text(
                'Trial: ${subscription.remainingTrialDays} days left',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _purchaseYearlyPlan(BuildContext context, WidgetRef ref) {
    // 実際のアプリ内課金処理をここに実装
    ref.read(subscriptionProvider.notifier).purchaseYearlyPlan();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texts.upgradedToAnnualPlan),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _purchaseThreeYearPlan(BuildContext context, WidgetRef ref) {
    // 実際のアプリ内課金処理をここに実装
    ref.read(subscriptionProvider.notifier).purchaseThreeYearPlan();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texts.upgradedTo3YearPlan),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

/// 料金プランタイル
class _PricingPlanTile extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String monthlyPrice;
  final List<String> features;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PricingPlanTile({
    required this.title,
    required this.price,
    required this.period,
    required this.monthlyPrice,
    required this.features,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRecommended ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRecommended ? Colors.blue[300]! : Colors.grey[300]!,
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'おすすめ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        monthlyPrice,
                        style: TextStyle(
                          fontSize: 14,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            isRecommended ? Colors.blue[700] : Colors.grey[700],
                      ),
                    ),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: features
                  .map((feature) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isRecommended ? Colors.blue[600] : Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(texts.selectPlan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
