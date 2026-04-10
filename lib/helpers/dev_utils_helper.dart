import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';
import '../providers/auth_provider.dart';
import '../providers/enhanced_group_provider.dart';
import '../providers/hive_provider.dart' as hive_provider;
import '../providers/shared_list_provider.dart';
import '../providers/user_settings_provider.dart';

class DevUtilsHelper {
  /// Hiveデータクリア機能（開発環境のみ）
  static Widget buildHiveDataClearButton({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onComplete,
  }) {
    // 開発環境以外では何も表示しない
    if (F.appFlavor != Flavor.dev) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.delete_forever, color: Colors.red),
      tooltip: 'Hiveデータクリア（デバッグ用）',
      onPressed: () => _handleHiveDataClear(
        context: context,
        ref: ref,
        onComplete: onComplete,
      ),
    );
  }

  /// Hiveデータクリア処理のメイン実装
  static Future<void> _handleHiveDataClear({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onComplete,
  }) async {
    final shouldClear = await _showClearConfirmationDialog(context);

    if (shouldClear == true) {
      try {
        await _performDataClear(ref);
        if (!context.mounted) return;
        await _showSuccessMessage(context);
        onComplete();
      } catch (e) {
        Log.error('🗑️ Hiveデータクリアエラー: $e');
        if (!context.mounted) return;
        await _showErrorMessage(context, e);
      }
    }
  }

  /// 削除確認ダイアログを表示
  static Future<bool?> _showClearConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hiveデータクリア'),
        content: const Text('全てのローカルデータが削除されます。続行しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 実際のデータクリア処理
  static Future<void> _performDataClear(WidgetRef ref) async {
    // 全ての設定をクリア
    await ref.read(userSettingsProvider.notifier).clearAllSettings();

    // Hiveボックスをクリア
    final SharedGroupBox = ref.read(hive_provider.SharedGroupBoxProvider);
    final sharedListBox = ref.read(hive_provider.sharedListBoxProvider);
    final userSettingsBox = ref.read(hive_provider.userSettingsBoxProvider);

    await SharedGroupBox.clear();
    await sharedListBox.clear();
    await userSettingsBox.clear();

    // Firebase認証からサインアウト
    await ref.read(authProvider).signOut();

    // プロバイダーを無効化
    ref.invalidate(enhancedGroupProvider);
    ref.invalidate(sharedListProvider);
    ref.invalidate(userSettingsProvider);

    Log.info('🗑️ 全てのHiveデータをクリアしました');
  }

  /// 成功メッセージを表示
  static Future<void> _showSuccessMessage(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hiveデータをクリアしました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// エラーメッセージを表示
  static Future<void> _showErrorMessage(
      BuildContext context, dynamic error) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('データクリアに失敗しました: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 開発環境チェックヘルパー
  static bool get isDevelopmentMode => F.appFlavor == Flavor.dev;
}
