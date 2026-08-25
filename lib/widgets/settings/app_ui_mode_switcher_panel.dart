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
import '../../providers/subscription_provider.dart'; // 🆕 Premium チェック用
import '../../datastore/user_settings_repository.dart';
import '../../services/user_preferences_service.dart';
import '../../services/purchase_service.dart'; // 🆕 課金処理
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

    // Firestore（Windows/desktopではオフラインキャッシュ非対応のためタイムアウト付き）
    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'appUIMode': newMode.index}, SetOptions(merge: true)).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            Log.warning('⚠️ [UI MODE] Firestore保存タイムアウト（ローカルには保存済み）');
          },
        );
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
      // 🆕 Single → Multi（Free → Premium）：課金フロー
      final isPremium = ref.read(isPremiumActiveProvider);

      if (!isPremium) {
        // Premium でない場合は課金確認
        if (!context.mounted) return;
        final t = texts;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🎁 Premium にアップグレード'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.premiumBenefits),
                const SizedBox(height: 16),
                const Text('✨ 複数グループを作成・管理できます'),
                const Text('✨ より詳細なリスト管理が可能です'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('¥500/月で Premium に'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        // 🆕 課금フロー発火（PurchaseService）
        try {
          Log.info('💳 [MODE SWITCH] Premium 購入フローを開始');
          // TODO: 実装時に PurchaseService.buyPremiumMonthly() を呼び出す
          // 課金UI/ストア連携は別で実装
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('課金フローを開始します...'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          Log.error('❌ [MODE SWITCH] 課金エラー: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('エラーが発生しました: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Mode 切り替え
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
      // 🆕 Multi → Single（Premium → Free）：グループ数確認 + 削除促促
      final groups = ref.read(allGroupsProvider).valueOrNull ?? [];

      if (groups.length > 3) {
        // グループが4個以上：切り替えをブロック
        if (!context.mounted) return;
        final t = texts;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ グループ数が多すぎます'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Free プランは最大 3 グループまでです。\n現在: ${groups.length} グループ'),
                const SizedBox(height: 12),
                Text(
                  '${groups.length - 3} グループを削除してから切り替えてください。',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.ok),
              ),
            ],
          ),
        );
        return;
      }

      final groupsOverMemberLimit =
          groups.where((group) => (group.members?.length ?? 0) > 10).toList();
      if (groupsOverMemberLimit.isNotEmpty) {
        if (!context.mounted) return;
        final t = texts;
        final groupDetails = groupsOverMemberLimit
            .map((group) =>
                '・${group.groupName}: ${group.members?.length ?? 0}人')
            .join('\n');
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ メンバー数が多すぎます'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Free プランは1グループにつき最大10人までです。'),
                const SizedBox(height: 12),
                Text(
                  groupDetails,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('メンバーを10人以下にしてから切り替えてください。'),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.ok),
              ),
            ],
          ),
        );
        return;
      }

      // グループ数が 3 個以下：通常の Single 切り替えフロー
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

      // 🆕 Free への切り替え時にサブスク キャンセル処理
      Log.info('💳 [MODE SWITCH] サブスク キャンセル処理を開始');
      try {
        // TODO: 実装時に RevenueCat / in_app_purchase でキャンセル処理
        // 次回更新日の前日にキャンセル要求
        await ref.read(subscriptionProvider.notifier).resetToFree();
        Log.info('✅ [MODE SWITCH] サブスク キャンセル完了（ローカル）');
      } catch (e) {
        Log.error('⚠️ [MODE SWITCH] キャンセルエラー（続行）: $e');
      }

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
