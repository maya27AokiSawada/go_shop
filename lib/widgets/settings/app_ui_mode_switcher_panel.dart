// lib/widgets/settings/app_ui_mode_switcher_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_ui_mode_config.dart';
import '../../providers/app_ui_mode_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/purchase_type_provider.dart';
import '../../datastore/user_settings_repository.dart';
import '../../services/user_preferences_service.dart';
import '../../models/purchase_type.dart';
import '../../utils/app_logger.dart';

/// AppUIモード切り替えパネル（シングル ↔ マルチ）
///
/// マルチモードへの切り替えは課金アクティブ時のみ可能。
/// - isPremiumActive (trial / yearly / threeYear) または
/// - PurchaseType.subscribe / PurchaseType.purchase
class AppUIModeSwicherPanel extends ConsumerWidget {
  const AppUIModeSwicherPanel({super.key});

  /// 課金状態で Multi への切り替えが許可されているか
  bool _canSwitchToMulti(
      bool isPremium, AsyncValue<PurchaseType> purchaseTypeAsync) {
    if (isPremium) return true;
    final purchaseType = purchaseTypeAsync.valueOrNull;
    if (purchaseType == null) return false;
    return purchaseType == PurchaseType.subscribe ||
        purchaseType == PurchaseType.purchase;
  }

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
    bool canSwitchToMulti,
  ) async {
    if (currentMode == AppUIMode.single) {
      // Single → Multi：課金チェック
      if (!canSwitchToMulti) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('マルチモードはプレミアムプランへのアップグレードが必要です'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      await _saveMode(ref, AppUIMode.multi);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('マルチモードに切り替えました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Multi → Single：確認ダイアログ
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('シングルモードに切り替え'),
          content: const Text(
            '現在のカレントグループとカレントリストのみ表示されます。\n他のデータは削除されません。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('切り替える'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _saveMode(ref, AppUIMode.single);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('シングルモードに切り替えました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appUIModeProvider);
    final isPremium = ref.watch(isPremiumActiveProvider);
    final purchaseTypeAsync = ref.watch(purchaseTypeProvider);
    final canSwitchToMulti = _canSwitchToMulti(isPremium, purchaseTypeAsync);
    final isMulti = currentMode == AppUIMode.multi;

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
                  '管理モード',
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
            isMulti ? 'マルチモード：複数のグループ・リストを管理' : 'シングルモード：1グループ・1リストで使用',
            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
          ),
          const SizedBox(height: 12),
          Tooltip(
            message: (!isMulti && !canSwitchToMulti)
                ? 'マルチモードへの切り替えはプレミアムプランが必要です'
                : '',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Text(
                    isMulti ? 'マルチ' : 'シングル',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (!isMulti && !canSwitchToMulti) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.lock, size: 16, color: Colors.grey.shade500),
                  ],
                ],
              ),
              subtitle: Text(
                isMulti ? '複数グループ・リスト管理（プレミアム）' : '1グループ・1リスト専用（無料）',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              value: isMulti,
              onChanged: (!isMulti && !canSwitchToMulti)
                  ? null // 無効化
                  : (_) =>
                      _onToggle(context, ref, currentMode, canSwitchToMulti),
              activeThumbColor: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
