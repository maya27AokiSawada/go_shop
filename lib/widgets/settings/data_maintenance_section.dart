import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/shared_group_provider.dart';
import '../../providers/user_specific_hive_provider.dart';
import '../../services/list_cleanup_service.dart';
import '../../services/shared_list_data_migration_service.dart';
import '../../services/periodic_purchase_service.dart';
import '../../services/user_profile_migration_service.dart';
import '../../services/user_initialization_service.dart';
import '../../utils/app_logger.dart';
import '../../config/app_mode_config.dart';

/// データメンテナンスパネル（開発環境のみ）
class DataMaintenanceSection extends ConsumerStatefulWidget {
  final User? user;
  const DataMaintenanceSection({super.key, required this.user});

  @override
  ConsumerState<DataMaintenanceSection> createState() =>
      _DataMaintenanceSectionState();
}

class _DataMaintenanceSectionState
    extends ConsumerState<DataMaintenanceSection> {
  Future<void> _performCleanup() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cleaning_services, color: Colors.blue),
              SizedBox(width: 8),
              Text('クリーンアップ確認'),
            ],
          ),
          content: const Text(
            '30日以上経過した削除済みアイテムを完全削除します。\nこの操作は取り消せません。\n\n実行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('実行'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('クリーンアップ中...'),
                ],
              ),
            ),
          ),
        ),
      );

      final cleanupService = ref.read(listCleanupServiceProvider);
      final cleanedCount = await cleanupService.cleanupAllLists(
        olderThanDays: 30,
        forceCleanup: false,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                cleanedCount > 0 ? Icons.check_circle : Icons.info,
                color: cleanedCount > 0 ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('クリーンアップ完了'),
            ],
          ),
          content: Text(
            cleanedCount > 0
                ? '$cleanedCount個のアイテムを削除しました'
                : 'クリーンアップ対象のアイテムはありませんでした',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('クリーンアップエラー', e);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('エラー'),
            ],
          ),
          content: Text('クリーンアップ中にエラーが発生しました\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _syncDefaultGroup() async {
    try {
      final user = widget.user;
      if (user == null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('認証が必要です'),
              ],
            ),
            content: const Text('Firestore同期にはサインインが必要です。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.green),
              SizedBox(width: 8),
              Text('Firestore同期確認'),
            ],
          ),
          content: const Text(
            'ローカルのみのデフォルトグループをFirestoreに同期します。\n同期後、他のデバイスからもアクセスできるようになります。\n\n実行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('実行'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Firestore同期中...'),
                ],
              ),
            ),
          ),
        ),
      );

      final allGroupsNotifier = ref.read(allGroupsProvider.notifier);
      final success = await allGroupsNotifier.syncDefaultGroupToFirestore(user);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(success ? '同期完了' : '同期失敗'),
            ],
          ),
          content: Text(
            success
                ? 'デフォルトグループをFirestoreに同期しました。\n\nアプリを再起動すると、${AppModeSettings.config.sharedList}もクラウドに保存されるようになります。'
                : '同期に失敗しました。ネットワーク接続を確認してください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('Firestore同期エラー', e);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('同期エラー'),
            ],
          ),
          content: Text('エラーが発生しました:\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _migrateUserProfile(User user) async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('プロファイルを移行中...'),
                ],
              ),
            ),
          ),
        ),
      );

      final migrationService = UserProfileMigrationService();

      final status = await migrationService.checkMigrationStatus(user.uid);

      if (status['migrated'] == true) {
        if (!mounted) return;
        Navigator.of(context).pop();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('移行不要'),
              ],
            ),
            content: const Text('プロファイルは既に新構造に移行済みです。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final success = await migrationService.migrateCurrentUserProfile();

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text(success ? '移行完了' : '移行失敗'),
            ],
          ),
          content: Text(
            success
                ? 'ユーザープロファイルを新構造に移行しました。\n\n旧構造: /users/{uid}/profile/profile\n新構造: /users/{uid}'
                : 'プロファイルの移行に失敗しました。\nログを確認してください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('プロファイル移行エラー', e);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('移行エラー'),
            ],
          ),
          content: Text('エラー: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _resetPeriodicPurchaseItems() async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('定期購入アイテムをリセット中...'),
                ],
              ),
            ),
          ),
        ),
      );

      final periodicService = ref.read(periodicPurchaseServiceProvider);
      final resetCount = await periodicService.resetPeriodicPurchaseItems();

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(resetCount > 0 ? Icons.check_circle : Icons.info,
                  color: resetCount > 0 ? Colors.green : Colors.blue),
              const SizedBox(width: 8),
              const Text('定期購入リセット完了'),
            ],
          ),
          content: Text(
            resetCount > 0
                ? '$resetCount 件のアイテムを未購入状態にリセットしました。\n\n購入間隔が経過した定期購入アイテムが自動的に未購入に戻されました。'
                : 'リセット対象のアイテムはありませんでした。\n\n定期購入間隔が経過したアイテムがない場合、リセットは実行されません。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('定期購入リセットエラー', e);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('リセットエラー'),
            ],
          ),
          content: Text('エラーが発生しました:\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkMigrationStatus() async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('確認中...'),
                ],
              ),
            ),
          ),
        ),
      );

      final migrationService = ref.read(sharedListDataMigrationServiceProvider);
      final status = await migrationService.checkMigrationStatus();

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('移行状況'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('総リスト数: ${status['total']}'),
              const SizedBox(height: 8),
              Text('移行済み: ${status['migrated']}',
                  style: const TextStyle(color: Colors.green)),
              Text('未移行: ${status['remaining']}',
                  style: TextStyle(
                      color: status['remaining']! > 0
                          ? Colors.orange
                          : Colors.grey)),
              const SizedBox(height: 12),
              Text(
                status['remaining']! > 0
                    ? '「移行実行」ボタンで移行してください'
                    : '全てのリストが移行済みです',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('移行状況確認エラー', e);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('エラー'),
            ],
          ),
          content: Text('移行状況確認中にエラーが発生しました\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _performMigration() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('データ移行確認'),
            ],
          ),
          content: const Text(
            'データ形式を配列からMapに移行します。\n\nFirestoreにバックアップを作成してから実行しますが、念のためデータのエクスポートをお勧めします。\n\n実行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('実行'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('移行中...'),
                  SizedBox(height: 8),
                  Text(
                    'バックアップ作成 → データ変換 → 保存',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final migrationService = ref.read(sharedListDataMigrationServiceProvider);
      final migratedCount = await migrationService.migrateAllData();

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                migratedCount > 0 ? Icons.check_circle : Icons.info,
                color: migratedCount > 0 ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('移行完了'),
            ],
          ),
          content: Text(
            migratedCount > 0
                ? '$migratedCount個のリストを移行しました\n\nバックアップはFirestoreの\nusers/[uid]/backups に保存されています'
                : '移行対象のリストはありませんでした',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('データ移行エラー', e);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('エラー'),
            ],
          ),
          content: Text('データ移行中にエラーが発生しました\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _clearAllHiveData(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('確認'),
          ],
        ),
        content: Text(
          '⚠️ ローカルの全データを削除しますか？\n\n'
          '・全グループ\n'
          '・全${AppModeSettings.config.sharedList}\n'
          '・全アイテム\n\n'
          'Firestoreから再同期されますが、ローカルのみのデータは失われます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Hiveデータ削除中...'),
                ],
              ),
            ),
          ),
        ),
      );

      AppLogger.info('🗑️ [HIVE_CLEAR] Hiveデータ削除開始');

      final boxSuffix = user.uid;
      final sharedGroupBoxName = 'SharedGroups_$boxSuffix';
      final sharedListBoxName = 'SharedLists_$boxSuffix';

      if (Hive.isBoxOpen(sharedGroupBoxName)) {
        await Hive.box(sharedGroupBoxName).close();
      }
      await Hive.deleteBoxFromDisk(sharedGroupBoxName);
      AppLogger.info('✅ [HIVE_CLEAR] SharedGroups削除完了');

      if (Hive.isBoxOpen(sharedListBoxName)) {
        await Hive.box(sharedListBoxName).close();
      }
      await Hive.deleteBoxFromDisk(sharedListBoxName);
      AppLogger.info('✅ [HIVE_CLEAR] SharedLists削除完了');

      final hiveService = ref.read(userSpecificHiveProvider);
      await hiveService.initializeForUser(user.uid);
      AppLogger.info('✅ [HIVE_CLEAR] Hive再初期化完了');

      ref.invalidate(allGroupsProvider);
      ref.invalidate(selectedGroupIdProvider);
      AppLogger.info('✅ [HIVE_CLEAR] Provider無効化完了');

      final initService = ref.read(userInitializationServiceProvider);
      await initService.syncFromFirestoreToHive(user);
      AppLogger.info('✅ [HIVE_CLEAR] Firestore同期完了');

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('完了'),
            ],
          ),
          content: const Text(
            'Hiveデータを削除し、Firestoreから再同期しました。\n\n'
            'アプリを再起動してください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      AppLogger.error('❌ [HIVE_CLEAR] エラー', e, stack);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('エラー'),
            ],
          ),
          content: Text('Hiveデータ削除中にエラーが発生しました\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
                Icon(Icons.cleaning_services, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'データメンテナンス',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '削除済みアイテムのクリーンアップ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '30日以上経過した削除済みアイテムを完全削除します',
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
                  await _performCleanup();
                },
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('クリーンアップ実行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade800,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              '定期購入アイテムの自動リセット',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '購入済み + 定期購入間隔経過のアイテムを未購入に戻します',
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
                  await _resetPeriodicPurchaseItems();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('定期購入リセット実行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade100,
                  foregroundColor: Colors.purple.shade800,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'ユーザープロファイル移行',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '旧構造から新構造へユーザープロファイルを移行します',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.user == null
                    ? null
                    : () async {
                        await _migrateUserProfile(widget.user!);
                      },
                icon: const Icon(Icons.sync_alt, size: 18),
                label: const Text('プロファイル移行実行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green.shade800,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'Hiveデータを完全削除',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '⚠️ ローカルの全データを削除します。Firestoreから再同期されます。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.red.shade600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.user == null
                    ? null
                    : () async {
                        await _clearAllHiveData(widget.user!);
                      },
                icon: const Icon(Icons.delete_forever, size: 18),
                label: const Text('Hiveデータをクリア'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade800,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'デフォルトグループのFirestore同期',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'ローカルのみのデフォルトグループをクラウドに同期します',
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
                  await _syncDefaultGroup();
                },
                icon: const Icon(Icons.cloud_upload, size: 18),
                label: const Text('Firestore同期'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green.shade800,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'データ形式移行（開発者向け）',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '配列形式 → Map形式への移行（通常は自動実行）',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _checkMigrationStatus();
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('状況確認'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _performMigration();
                    },
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('移行実行'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
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
