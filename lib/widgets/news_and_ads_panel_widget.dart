import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/news_widget.dart';
import '../l10n/l10n.dart';

/// ニュース＆広告パネルウィジェット
class NewsAndAdsPanelWidget extends ConsumerWidget {
  const NewsAndAdsPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.newspaper, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  texts.newsPanelTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ニュースウィジェット（常に表示）
            // 課金催促条件に該当する場合は自動的に警告表示に切り替わる
            const NewsWidget(),

            // 認証済みユーザー向けの追加コンテンツ
            // （PaymentReminderWidgetとHomeAdBannerWidgetは削除済み）
          ],
        ),
      ),
    );
  }
}
