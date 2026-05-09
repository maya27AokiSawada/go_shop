import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/feedback_status_service.dart';
import '../../utils/app_logger.dart';
import '../../l10n/l10n.dart';

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
            SnackBar(
              content: Text(texts.formOpenFailed),
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
          SnackBar(
            content: Text(texts.feedbackThanks),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
                  texts.feedbackSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              texts.feedbackSectionDesc,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              texts.feedbackSectionSubDesc,
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
                label: Text(texts.feedbackButton),
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
