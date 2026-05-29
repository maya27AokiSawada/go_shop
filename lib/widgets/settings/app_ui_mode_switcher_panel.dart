// lib/widgets/settings/app_ui_mode_switcher_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_ui_mode_config.dart';
import '../../providers/app_ui_mode_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shared_group_provider.dart';
import '../../providers/current_list_provider.dart';
import '../../providers/shared_list_provider.dart';
import '../../datastore/user_settings_repository.dart';
import '../../services/user_preferences_service.dart';
import '../../utils/app_logger.dart';
import '../../l10n/l10n.dart';

/// AppUIモード切り替えパネル（シングル ↔ マルチ）
class AppUIModeSwicherPanel extends ConsumerWidget {
  const AppUIModeSwicherPanel({super.key});

  Future<void> _saveMode(WidgetRef ref, AppUIMode newMode) async {
    // Hive
    final userSettingsAsync = await ref.read(userSettingsProvider.future);
    final updatedSettings =
        userSettingsAsync.copyWith(appUIMode: newMode.index);
    final repository = ref.read(userSettingsRepositoryProvider);
    await repository.saveSettings(updatedSettings);

    // SharedPreferences
    await UserPreferencesService.saveAppUIMode(newMode.index);

    // Firestore
    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'appUIMode': newMode.index}, SetOptions(merge: true));
      }
    } catch (e) {
      Log.error('⚠️ [UI MODE] Firestore保存エラー: $e');
    }

    // static & provider
    AppUIModeSettings.setMode(newMode);
    ref.read(appUIModeProvider.notifier).state = newMode;
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    AppUIMode currentMode,
  ) async {
    if (currentMode == AppUIMode.single) {
      await _saveMode(ref, AppUIMode.multi);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts.switchedToMultiMode),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Multi → Single：カレントリスト確認
      final selectedGroupId = ref.read(selectedGroupIdProvider);
      if (selectedGroupId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(texts.selectGroupBeforeSwitch),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final currentList = ref.read(currentListProvider);
      if (currentList == null || currentList.groupId != selectedGroupId) {
        // カレントリストが未選択 → グループのリスト一覧を確認
        final repository = ref.read(sharedListRepositoryProvider);
        final groupLists =
            await repository.getSharedListsByGroup(selectedGroupId);

        if (groupLists.isEmpty) {
          // リストがない → 自動作成して選択
          final uid = ref.read(authStateProvider).valueOrNull?.uid;
          if (uid == null) return;
          if (!context.mounted) return;
          final newList = await repository.createSharedList(
            ownerUid: uid,
            groupId: selectedGroupId,
            listName: texts.sharedList,
          );
          await ref
              .read(currentListProvider.notifier)
              .selectList(newList, groupId: selectedGroupId);
          Log.info('📌 [MODE SWITCH] リストを自動作成してカレントに設定: ${newList.listName}');
        } else if (groupLists.length == 1) {
          // リストが1つ → 自動選択
          await ref
              .read(currentListProvider.notifier)
              .selectList(groupLists.first, groupId: selectedGroupId);
          Log.info('📌 [MODE SWITCH] リストを自動選択: ${groupLists.first.listName}');
        } else {
          // リストが複数 → ユーザーに選択を促してブロック
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(texts.selectListBeforeSwitch),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      // 確認ダイアログ
      if (!context.mounted) return;
      final t = texts;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.switchToSingleMode),
          content: Text(t.switchToSingleModeBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.doSwitch),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _saveMode(ref, AppUIMode.single);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts.switchedToSingleMode),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appUIModeProvider);
    final isMulti = currentMode == AppUIMode.multi;
    final t = texts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.managementMode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isMulti ? t.multiModeDesc : t.singleModeDesc,
            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                isMulti ? t.multiModeLabel : t.singleModeLabel,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                isMulti ? t.multiModeDesc : t.singleModeDesc,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              value: isMulti,
              onChanged: (_) => _onToggle(context, ref, currentMode),
              activeThumbColor: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
