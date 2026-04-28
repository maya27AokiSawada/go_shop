import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_news.dart';
import '../providers/news_provider.dart';
import '../providers/subscription_provider.dart';
import '../pages/premium_page.dart';
import '../services/app_launch_service.dart';
import '../services/feedback_status_service.dart';
import '../services/feedback_prompt_service.dart';
import '../utils/app_logger.dart';

/// ホーム画面用ニュース表示ウィジェット
class NewsWidget extends ConsumerWidget {
  const NewsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 課金催促条件をチェック
    final shouldShowPaymentReminder =
        ref.watch(shouldShowPaymentReminderProvider);

    // 課金催促条件に当てはまる場合は警告表示に差し替え
    if (shouldShowPaymentReminder) {
      return _buildPaymentReminderCard(context, ref);
    }

    // 🔥 フィードバック催促ロジック
    return FutureBuilder<bool>(
      future: _shouldShowFeedbackPrompt(),
      builder: (context, promptSnapshot) {
        // フィードバック催促を表示すべき場合
        if (promptSnapshot.connectionState == ConnectionState.done &&
            promptSnapshot.hasData &&
            promptSnapshot.data == true) {
          return _buildFeedbackPromptCard(context);
        }

        // 通常のニュース表示
        final newsAsync = ref.watch(currentNewsProvider);
        return newsAsync.when(
          data: (news) => _buildNewsCard(context, news),
          loading: () => _buildLoadingCard(),
          error: (error, stack) => _buildTipsCard(context),
        );
      },
    );
  }

  /// フィードバック催促を表示すべきか判定
  Future<bool> _shouldShowFeedbackPrompt() async {
    try {
      final launchCount = await AppLaunchService.getLaunchCount();
      final isFeedbackSubmitted =
          await FeedbackStatusService.isFeedbackSubmitted();

      AppLogger.info('🔍 [NEWS] フィードバック催促判定開始');
      AppLogger.info('📱 [NEWS] 起動回数: $launchCount 回');
      AppLogger.info('📝 [NEWS] フィードバック送信済み: $isFeedbackSubmitted');

      final shouldShow = await FeedbackPromptService.shouldShowFeedbackPrompt(
        launchCount: launchCount,
        isFeedbackSubmitted: isFeedbackSubmitted,
      );

      AppLogger.info('🎯 [NEWS] 催促表示判定結果: $shouldShow');

      return shouldShow;
    } catch (e) {
      AppLogger.error('❌ [NEWS] フィードバック催促判定エラー: $e');
      return false;
    }
  }

  /// フィードバック催促カード
  Widget _buildFeedbackPromptCard(BuildContext context) {
    // Google フォームのリンク（クローズドテスト用）
    const String feedbackFormUrl = 'https://forms.gle/wTvWG2EZ4p1HQcST7';

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[50]!,
              Colors.purple[100]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  Icon(
                    Icons.feedback,
                    color: Colors.purple[700],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ご意見・ご感想をお聞かせください',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // メッセージ
              Text(
                'ユーザーの皆様からのご意見は、アプリの改善に役立てさせていただきます。'
                'わずか1分程度で答えられるアンケートです。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.purple[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // ボタン
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          if (await canLaunchUrl(Uri.parse(feedbackFormUrl))) {
                            await launchUrl(
                              Uri.parse(feedbackFormUrl),
                              mode: LaunchMode.externalApplication,
                            );

                            // フィードバック送信済みにマーク
                            await FeedbackStatusService.markFeedbackSubmitted();
                            AppLogger.info('✅ [FEEDBACK] フィードバック送信済みにマーク');

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ご協力ありがとうございます！'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          AppLogger.error('❌ [FEEDBACK] フォーム開封エラー: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('フォームを開けませんでした: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('アンケートに答える'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        AppLogger.info('⏭️ [FEEDBACK] 催促をスキップ');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('後でお願いします'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Text(
                        '後で',
                        style: TextStyle(color: Colors.purple[700]),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// トライアル終了警告カード
  Widget _buildPaymentReminderCard(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(subscriptionProvider.notifier);
    final message = notifier.paymentReminderMessage;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange[100]!,
              Colors.orange[200]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 警告ヘッダー
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, AppNews news) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ニュースヘッダー
              Row(
                children: [
                  Icon(
                    Icons.announcement,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ニュース',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  if (news.createdAt.isAfter(
                      DateTime.now().subtract(const Duration(days: 7))))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[500],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ニュースタイトル
              Text(
                news.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // ニュース内容
              Text(
                news.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              // 画像表示（もしある場合）
              if (news.imageUrl != null && news.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    news.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // アクションボタン
              if (news.actionText != null && news.actionText!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(news.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _handleAction(context, news),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        news.actionText!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  _formatDate(news.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 12),
              Text(
                'ニュースを読み込み中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(BuildContext? ctx) {
    // \u30e9\u30f3\u30c0\u30e0\u8868\u793a\u7528\u306e\u30c8\u30a4\u30d7\u30b9\u4e00\u89a7
    const tips = [
      _AppTip(
        icon: Icons.touch_app,
        color: Colors.blue,
        title: '\u57fa\u672c\u64cd\u4f5c: \u30bf\u30c3\u30d7',
        body:
            '\u30a2\u30a4\u30c6\u30e0\u306e\u8cfc\u5165\u72b6\u614b\u5207\u66ff\u3001\u30b0\u30eb\u30fc\u30d7\u306e\u30ab\u30ec\u30f3\u30c8\u9078\u629e\u306a\u3069\u30e1\u30a4\u30f3\u64cd\u4f5c\u306f\u30bf\u30c3\u30d7\u3067\u884c\u3048\u307e\u3059\u3002',
      ),
      _AppTip(
        icon: Icons.touch_app,
        color: Colors.green,
        title: '\u9ab8\u6280: \u30c0\u30d6\u30eb\u30bf\u30c3\u30d7',
        body:
            '\u30a2\u30a4\u30c6\u30e0\u306e\u7de8\u96c6\u3001\u30e1\u30f3\u30d0\u30fc\u306e\u30db\u30ef\u30a4\u30c8\u30dc\u30fc\u30c9\u8868\u793a\u306a\u3069\u306f\u30c0\u30d6\u30eb\u30bf\u30c3\u30d7\u3067\u958b\u304d\u307e\u3059\u3002',
      ),
      _AppTip(
        icon: Icons.touch_app,
        color: Colors.red,
        title: '\u5b89\u5168\u64cd\u4f5c: \u9577\u62bc\u3057',
        body:
            '\u30a2\u30a4\u30c6\u30e0\u524a\u9664\u3001\u30b0\u30eb\u30fc\u30d7\u9000\u51fa\u3068\u3044\u3063\u305f\u7834\u58ca\u7684\u306a\u64cd\u4f5c\u306f\u9577\u62bc\u3057\u3067\u5b89\u5168\u306b\u5b9f\u884c\u3067\u304d\u307e\u3059\u3002',
      ),
      _AppTip(
        icon: Icons.group,
        color: Colors.orange,
        title: '\u30b0\u30eb\u30fc\u30d7\u753b\u9762',
        body:
            '\u30b0\u30eb\u30fc\u30d7\u3092\u30bf\u30c3\u30d7\u2192\u30ab\u30ec\u30f3\u30c8\u9078\u629e\u3001\u30c0\u30d6\u30eb\u30bf\u30c3\u30d7\u2192\u30e1\u30f3\u30d0\u30fc\u7ba1\u7406\u3001\u9577\u62bc\u3057\u2192\u524a\u9664/\u9000\u51fa\u3067\u3059\u3002',
      ),
      _AppTip(
        icon: Icons.people,
        color: Colors.purple,
        title: '\u30e1\u30f3\u30d0\u30fc\u4e00\u89a7\u753b\u9762',
        body:
            '\u30e1\u30f3\u30d0\u30fc\u30bf\u30c3\u30d7\u2192\u30ed\u30fc\u30eb\u5909\u66f4\uff08\u30aa\u30fc\u30ca\u30fc\uff09\u307e\u305f\u306f\u60c5\u5831\u8868\u793a\u3001\u30c0\u30d6\u30eb\u30bf\u30c3\u30d7\u2192\u30db\u30ef\u30a4\u30c8\u30dc\u30fc\u30c9\u3002',
      ),
    ];

    // \u8d77\u52d5\u6642\u523b\u3067Tip\u3092\u6c7a\u5b9a\uff08\u7565\u4f3c\u30e9\u30f3\u30c0\u30e0\uff09
    final tipIndex = DateTime.now().minute % tips.length;
    final tip = tips[tipIndex];

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tip.color.withOpacity(0.05),
              tip.color.withOpacity(0.12),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: tip.color.withOpacity(0.8), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Tips',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tip.color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(tip.icon, color: tip.color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, AppNews news) async {
    if (news.actionUrl != null && news.actionUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(news.actionUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('リンクを開けませんでした')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('リンクが無効です')),
          );
        }
      }
    } else {
      // 内部ページへの遷移など
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ありがとうございます！')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

/// Tips表示用データクラス
class _AppTip {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _AppTip({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

/// コンパクトなニュース表示ウィジェット
class CompactNewsWidget extends ConsumerWidget {
  const CompactNewsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsStreamProvider);

    return newsAsync.when(
      data: (news) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.announcement, color: Colors.blue[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                news.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

