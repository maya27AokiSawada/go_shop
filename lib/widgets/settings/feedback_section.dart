import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/feedback_status_service.dart';
import '../../utils/app_logger.dart';

/// フィードバック送信セクション（全ユーザー表示）
class FeedbackSection extends StatefulWidget {
  const FeedbackSection({super.key});

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  Future<void> _openFeedbackForm() async {
    try {
      const String feedbackFormUrl = 'https://forms.gle/wTvWG2EZ4p1HQcST7';

      if (!await canLaunchUrl(Uri.parse(feedbackFormUrl))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フォームを開くことができませんでした'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await launchUrl(
        Uri.parse(feedbackFormUrl),
        mode: LaunchMode.externalApplication,
      );

      AppLogger.info('✅ [SETTINGS] フィードバックフォームを開きました');

      await FeedbackStatusService.markFeedbackSubmitted();
      AppLogger.info('✅ [SETTINGS] フィードバック送信済みにマーク');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ご協力ありがとうございます！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ [SETTINGS] フィードバックフォーム開封エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.feedback, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'フィードバック送信',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ご意見・ご感想をお聞かせください',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'テスト版の改善にご協力いただきます。わずか1分程度です。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _openFeedbackForm();
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('アンケートに答える'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
