import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/news_widget.dart';

/// ニュース＆広告パネルウィジェット
class NewsAndAdsPanelWidget extends ConsumerWidget {
  const NewsAndAdsPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.newspaper, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '📰 ニュース・お知らせ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            // ニュースウィジェット（常に表示）
            // 課金催促条件に該当する場合は自動的に警告表示に切り替わる
            NewsWidget(),

            // 認証済みユーザー向けの追加コンテンツ
            // （PaymentReminderWidgetとHomeAdBannerWidgetは削除済み）
          ],
        ),
      ),
    );
  }
}
