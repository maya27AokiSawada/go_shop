import 'package:flutter/material.dart';
import '../../services/app_launch_service.dart';
import '../../services/feedback_status_service.dart';
import '../../services/feedback_prompt_service.dart';

/// フィードバック催促デバッグパネル（開発環境のみ）
class FeedbackDebugSection extends StatefulWidget {
  const FeedbackDebugSection({super.key});

  @override
  State<FeedbackDebugSection> createState() => _FeedbackDebugSectionState();
}

class _FeedbackDebugSectionState extends State<FeedbackDebugSection> {
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
                Icon(Icons.bug_report, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'フィードバック催促（デバッグ）',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 起動回数表示
            FutureBuilder<int>(
              future: AppLaunchService.getLaunchCount(),
              builder: (context, snapshot) {
                final launchCount = snapshot.data ?? 0;
                return Text(
                  '起動回数: $launchCount 回',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                );
              },
            ),

            // フィードバック送信状態表示
            const SizedBox(height: 8),
            FutureBuilder<bool>(
              future: FeedbackStatusService.isFeedbackSubmitted(),
              builder: (context, snapshot) {
                final isSubmitted = snapshot.data ?? false;
                return Text(
                  'フィードバック送信済み: ${isSubmitted ? '✅はい' : '❌いいえ'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSubmitted
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                );
              },
            ),

            // テスト状態表示
            const SizedBox(height: 8),
            FutureBuilder<bool>(
              future: FeedbackPromptService.isTestingActive(),
              builder: (context, snapshot) {
                final isActive = snapshot.data ?? false;
                return Text(
                  'テスト実施中: ${isActive ? '✅はい' : '❌いいえ'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        isActive ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // ボタン群
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 起動回数をリセット
                ElevatedButton.icon(
                  onPressed: () async {
                    await AppLaunchService.resetLaunchCount();
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('起動回数をリセットしました'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('起動回数リセット'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade800,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                // フィードバック状態をリセット
                ElevatedButton.icon(
                  onPressed: () async {
                    await FeedbackStatusService.resetFeedbackStatus();
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('フィードバック状態をリセットしました'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('FB状態リセット'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade800,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                // テスト状態を ON に設定
                ElevatedButton.icon(
                  onPressed: () async {
                    await FeedbackPromptService.setTestingActive(true);
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('テスト状態を ON に設定しました'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('テスト ON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade800,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                // テスト状態を OFF に設定
                ElevatedButton.icon(
                  onPressed: () async {
                    await FeedbackPromptService.setTestingActive(false);
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('テスト状態を OFF に設定しました'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('テスト OFF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade800,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
