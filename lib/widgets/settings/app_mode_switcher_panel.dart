import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_mode_config.dart';
import '../../config/app_ui_mode_config.dart';
import '../../providers/app_mode_notifier_provider.dart';
import '../../providers/app_ui_mode_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../datastore/user_settings_repository.dart';
import '../../l10n/l10n.dart';

/// アプリモード切り替えパネルウィジェット
class AppModeSwitcherPanel extends ConsumerWidget {
  const AppModeSwitcherPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // シングルモード時は非表示（shopping固定）
    if (ref.watch(appUIModeProvider) == AppUIMode.single) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texts.appModeTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            texts.appModeDesc,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final currentMode = ref.watch(appModeNotifierProvider);

              return SegmentedButton<AppMode>(
                segments: [
                  ButtonSegment<AppMode>(
                    value: AppMode.shopping,
                    label: Text(texts.shoppingListMode),
                    icon: const Icon(Icons.shopping_cart, size: 16),
                  ),
                  ButtonSegment<AppMode>(
                    value: AppMode.todo,
                    label: Text(texts.todoShareMode),
                    icon: const Icon(Icons.task_alt, size: 16),
                  ),
                ],
                selected: {currentMode},
                onSelectionChanged: (Set<AppMode> newSelection) async {
                  final newMode = newSelection.first;

                  // UserSettingsに保存
                  final userSettingsAsync =
                      await ref.read(userSettingsProvider.future);
                  final updatedSettings = userSettingsAsync.copyWith(
                    appMode: newMode.index,
                  );
                  final repository = ref.read(userSettingsRepositoryProvider);
                  await repository.saveSettings(updatedSettings);

                  // AppModeSettingsに反映
                  AppModeSettings.setMode(newMode);

                  // UIを更新
                  ref.read(appModeNotifierProvider.notifier).state = newMode;

                  // SnackBar表示
                  if (context.mounted) {
                    final modeName = newMode == AppMode.shopping
                        ? texts.shoppingListMode
                        : texts.todoShareMode;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(texts.modeChanged(modeName)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
