import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/news_widget.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/payment_reminder_widget.dart';

/// ニュース＆広告パネルウィジェット
class NewsAndAdsPanelWidget extends ConsumerWidget {
  const NewsAndAdsPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.newspaper, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '📰 ニュース・お知らせ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ニュースウィジェット（常に表示）
            const NewsWidget(),

            // 認証済みユーザー向けの追加コンテンツ
            authState.when(
              data: (user) {
                if (user != null) {
                  return const Column(
                    children: [
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 16),

                      // 支払いリマインダー（認証済みユーザー向け）
                      PaymentReminderWidget(),

                      SizedBox(height: 16),

                      // ホーム画面広告バナー（認証済みユーザー向け）
                      HomeAdBannerWidget(),
                    ],
                  );
                } else {
                  // 未認証時は追加コンテンツなし
                  return const SizedBox.shrink();
                }
              },
              loading: () => const SizedBox(
                height: 20,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'コンテンツの読み込みに失敗しました',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
