import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_settings_provider.dart';
import '../../datastore/user_settings_repository.dart';
import '../../pages/notification_history_page.dart';

/// 通知設定パネルウィジェット
class NotificationSettingsPanel extends ConsumerWidget {
  const NotificationSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '通知設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'リスト変更通知の設定',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final userSettingsAsync = ref.watch(userSettingsProvider);

              return userSettingsAsync.when(
                data: (userSettings) {
                  return SwitchListTile(
                    title: const Text(
                      'リスト変更通知',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'アイテムの追加・削除・購入完了を5分ごとに通知',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: userSettings.enableListNotifications,
                    onChanged: (value) async {
                      final repository =
                          ref.read(userSettingsRepositoryProvider);
                      final updatedSettings = userSettings.copyWith(
                        enableListNotifications: value,
                      );
                      await repository.saveSettings(updatedSettings);

                      // プロバイダーを更新
                      ref.invalidate(userSettingsProvider);

                      // SnackBar表示
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                value ? 'リスト変更通知をオンにしました' : 'リスト変更通知をオフにしました'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    activeThumbColor: Colors.amber.shade700,
                    contentPadding: EdgeInsets.zero,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Text(
                  'エラー: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // 通知履歴を見るボタン
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryPage(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('通知履歴を見る'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }
}
