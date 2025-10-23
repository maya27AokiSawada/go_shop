import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../pages/premium_page.dart';

/// 課金催促メッセージウィジェット（3週間後に表示）
class PaymentReminderWidget extends ConsumerWidget {
  const PaymentReminderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowPaymentReminderProvider);
    final subscription = ref.watch(subscriptionProvider);

    if (!shouldShow) return const SizedBox.shrink();

    final notifier = ref.read(subscriptionProvider.notifier);
    final message = notifier.paymentReminderMessage;

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[100]!, Colors.orange[200]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[400]!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.orange[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '無料期間終了のお知らせ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PremiumPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('プレミアムプラン'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // 後で通知を非表示にする機能（将来実装）
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('明日また通知します'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      '後で',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ),
              ],
            ),
            if (subscription.remainingTrialDays > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '残り${subscription.remainingTrialDays}日で広告表示が開始されます',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
