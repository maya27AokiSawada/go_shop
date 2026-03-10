import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_group_provider.dart';
import '../providers/user_specific_hive_provider.dart';
import '../services/user_preferences_service.dart';
import '../services/user_initialization_service.dart';
import '../services/list_cleanup_service.dart';
import '../services/shared_list_data_migration_service.dart';
import '../services/periodic_purchase_service.dart';
import '../services/user_profile_migration_service.dart';
import '../services/app_launch_service.dart';
import '../services/feedback_status_service.dart';
import '../services/feedback_prompt_service.dart';
import '../widgets/test_scenario_widget.dart';
import '../debug/fix_maya_group.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';
import '../widgets/settings/auth_status_panel.dart';
import '../widgets/settings/firestore_sync_status_panel.dart';
import '../widgets/settings/app_mode_switcher_panel.dart';
import '../widgets/settings/privacy_settings_panel.dart';
import '../providers/user_settings_provider.dart';
import '../datastore/user_settings_repository.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppLogger.info('SettingsPage初期化開始 - SharedPreferencesからユーザー名読み込み');

    // プロバイダーとは別に、直接SharedPreferencesから読み込みを実行
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          final userName = await UserPreferencesService.getUserName();
          if (userName != null && userName.isNotEmpty) {
            userNameController.text = userName;
            AppLogger.info('ユーザー名読み込み成功: ${AppLogger.maskName(userName)}');
          } else {
            AppLogger.warning('ユーザー名が保存されていません');
          }
        } catch (e) {
          AppLogger.error('UserPreferences読み込みエラー', e);
        }
      }
    });
  }

  @override
  void dispose() {
    userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final syncStatus = ref.watch(firestoreSyncStatusProvider);

    return SafeArea(
      child: authState.when(
        data: (user) {
          final isAuthenticated = user != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ステータス表示
                AuthStatusPanel(user: user),

                const SizedBox(height: 12),

                // Firestore同期状態表示（サインイン済みの場合のみ）
                if (isAuthenticated)
                  FirestoreSyncStatusPanel(syncStatus: syncStatus),

                if (isAuthenticated && syncStatus != 'idle')
                  const SizedBox(height: 12),

                const SizedBox(height: 20),

                // アプリモード切り替えパネル（常に表示）
                const AppModeSwitcherPanel(),

                const SizedBox(height: 20),

                // プライバシー設定パネル（認証済み時または開発環境で表示）
                if (isAuthenticated || true) ...[
                  const PrivacySettingsPanel(),
                  const SizedBox(height: 20),
                ],

                // ホワイトボード設定パネル
                const WhiteboardSettingsPanel(),
                const SizedBox(height: 20),

                // 開発者ツールパネル（開発環境用）
                if (F.appFlavor == Flavor.dev) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.teal.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '開発者ツール',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Firebase認証とCRUD操作のテストシナリオを実行できます',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TestScenarioWidget(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_circle_filled,
                                    size: 16),
                                label: const Text(
                                  'テストシナリオ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade100,
                                  foregroundColor: Colors.teal.shade800,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FixMayaGroupScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.build, size: 16),
                                label: const Text(
                                  'グループ修正',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade100,
                                  foregroundColor: Colors.orange.shade800,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Firestoreデータ確認ボタン
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ログインが必要です')),
                              );
                              return;
                            }

                            try {
                              final firestore = FirebaseFirestore.instance;
                              final snapshot = await firestore
                                  .collection('SharedGroups')
                                  .where('allowedUid', arrayContains: user.uid)
                                  .get();

                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Firestoreデータ'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('現在のUID: ${user.uid}'),
                                          const SizedBox(height: 8),
                                          Text('メール: ${user.email}'),
                                          const Divider(height: 16),
                                          Text(
                                            'Firestoreグループ数: ${snapshot.docs.length}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...snapshot.docs.map((doc) {
                                            final data = doc.data();
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'グループ名: ${data['groupName'] ?? 'N/A'}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text('ID: ${doc.id}'),
                                                    Text(
                                                        'ownerUid: ${data['ownerUid'] ?? 'N/A'}'),
                                                    Text(
                                                        'allowedUid: ${data['allowedUid']?.toString() ?? 'N/A'}'),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('閉じる'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('エラー'),
                                    content: Text('Firestore確認エラー:\n$e'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('閉じる'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.cloud, size: 16),
                          label: const Text(
                            'Firestoreデータ確認',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade100,
                            foregroundColor: Colors.purple.shade800,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: const Size(double.infinity, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Firestoreから同期ボタン
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ログインが必要です')),
                              );
                              return;
                            }

                            try {
                              // 同期開始メッセージ
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Firestoreから同期中...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              // UserInitializationServiceを使って同期
                              final initService =
                                  ref.read(userInitializationServiceProvider);
                              await initService.syncFromFirestoreToHive(user);

                              // グループプロバイダーを更新
                              ref.invalidate(allGroupsProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ 同期完了しました'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('同期エラー: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text(
                            'Firestoreから同期',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: const Size(double.infinity, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // グループ状態確認ボタン（Hive）
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final groupsAsync = ref.read(allGroupsProvider);
                              await groupsAsync.when(
                                data: (groups) {
                                  final message = groups.isEmpty
                                      ? '❌ グループが見つかりません\n\n'
                                          '現在のユーザー: ${user?.uid ?? "未ログイン"}\n'
                                          '現在のメール: ${user?.email ?? "N/A"}'
                                      : '✅ グループ数: ${groups.length}\n\n'
                                          '${groups.map((g) => '・${g.groupName} (ID: ${g.groupId})').join('\n')}\n\n'
                                          '現在のユーザー: ${user?.uid ?? "未ログイン"}';

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('グループ状態'),
                                      content: SingleChildScrollView(
                                        child: Text(message),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('閉じる'),
                                        ),
                                        // 🔥 REMOVED: デフォルトグループ機能廃止
                                        // グループが0個の場合は初回セットアップ画面でグループ作成
                                      ],
                                    ),
                                  );
                                },
                                loading: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('読み込み中...')),
                                  );
                                },
                                error: (error, stack) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('エラー'),
                                      content: Text('グループ読み込みエラー:\n$error'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('閉じる'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('確認エラー: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text(
                            'グループ状態確認',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade800,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: const Size(double.infinity, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔥 フィードバック関連デバッグ（開発環境のみ）
                  if (F.appFlavor == Flavor.dev)
                    Card(
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
                                Icon(Icons.bug_report,
                                    color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'フィードバック催促（デバッグ）',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
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
                              future:
                                  FeedbackStatusService.isFeedbackSubmitted(),
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
                                    color: isActive
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('起動回数をリセットしました'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('起動回数リセット'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade100,
                                    foregroundColor: Colors.blue.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),

                                // フィードバック状態をリセット
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await FeedbackStatusService
                                        .resetFeedbackStatus();
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('フィードバック状態をリセットしました'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('FB状態リセット'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade100,
                                    foregroundColor: Colors.blue.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),

                                // テスト状態を ON に設定
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await FeedbackPromptService
                                        .setTestingActive(true);
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('テスト状態を ON に設定しました'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  icon:
                                      const Icon(Icons.check_circle, size: 16),
                                  label: const Text('テスト ON'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade100,
                                    foregroundColor: Colors.green.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),

                                // テスト状態を OFF に設定
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await FeedbackPromptService
                                        .setTestingActive(false);
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('テスト状態を OFF に設定しました'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.cancel, size: 16),
                                  label: const Text('テスト OFF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade100,
                                    foregroundColor: Colors.red.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 🆕 データメンテナンス（開発環境のみ）
                  if (F.appFlavor == Flavor.dev)
                    Card(
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
                                Icon(Icons.cleaning_services,
                                    color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'データメンテナンス',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            // 🆕 定期購入アイテムのリセット
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            // 🆕 ユーザープロファイル移行
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
                                onPressed: user == null
                                    ? null
                                    : () async {
                                        await _migrateUserProfile(user);
                                      },
                                icon: const Icon(Icons.sync_alt, size: 18),
                                label: const Text('プロファイル移行実行'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade100,
                                  foregroundColor: Colors.green.shade800,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            // 🆕 Hiveデータクリア（緊急用）
                            Text(
                              'Hiveデータを完全削除',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
                                onPressed: user == null
                                    ? null
                                    : () async {
                                        await _clearAllHiveData(user);
                                      },
                                icon:
                                    const Icon(Icons.delete_forever, size: 18),
                                label: const Text('Hiveデータをクリア'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red.shade800,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            // 🆕 Firestore同期
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            // 🆕 データ移行
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
                                    icon: const Icon(Icons.info_outline,
                                        size: 16),
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
                    ),
                  const SizedBox(height: 20),
                ],

                // 🔥 フィードバック送信セクション（全ユーザー表示）
                Card(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
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
                ),

                const SizedBox(height: 20),

                // 🆕 アカウント削除セクション（認証済みユーザー向け）
                if (isAuthenticated) ...[
                  Card(
                    elevation: 2,
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.delete_forever,
                                  color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'アカウント削除',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'アカウントと全てのデータを完全に削除します',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '⚠️ この操作は取り消せません',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _deleteAccount(user);
                              },
                              icon: const Icon(Icons.delete_forever, size: 18),
                              label: const Text('アカウントを削除'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 設定ページのコンテンツをここに追加予定
                Center(
                  child: Text(
                    '設定ページ（仮）',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // フッター情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.settings, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Go Shop 設定',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('認証状態を確認中...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'エラーが発生しました',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: $err',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ), // authState.when閉じ
    ); // SafeArea閉じ
  }

  /// クリーンアップ実行メソッド
  /// フィードバックフォームを開く
  Future<void> _openFeedbackForm() async {
    try {
      // Google フォームのリンク（クローズドテスト用）
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

      // フォームを開く
      await launchUrl(
        Uri.parse(feedbackFormUrl),
        mode: LaunchMode.externalApplication,
      );

      AppLogger.info('✅ [SETTINGS] フィードバックフォームを開きました');

      // フィードバック送信済みにマーク
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

  Future<void> _performCleanup() async {
    try {
      // 確認ダイアログ表示
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

      // ローディング表示
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

      // クリーンアップ実行
      final cleanupService = ref.read(listCleanupServiceProvider);
      final cleanedCount = await cleanupService.cleanupAllLists(
        olderThanDays: 30,
        forceCleanup: false, // needsCleanup判定あり
      );

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
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

      // エラー時もローディングを閉じる
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

  /// 🆕 デフォルトグループFirestore同期メソッド
  Future<void> _syncDefaultGroup() async {
    try {
      // 認証状態確認
      final user = ref.read(authStateProvider).value;
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

      // 確認ダイアログ表示
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

      // ローディング表示
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

      // 同期実行
      final allGroupsNotifier = ref.read(allGroupsProvider.notifier);
      final success = await allGroupsNotifier.syncDefaultGroupToFirestore(user);

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
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
                ? 'デフォルトグループをFirestoreに同期しました。\n\nアプリを再起動すると、買い物リストもクラウドに保存されるようになります。'
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

      // エラー時もローディングを閉じる
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

  /// ユーザープロファイル移行メソッド
  Future<void> _migrateUserProfile(User user) async {
    try {
      // ローディング表示
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

      // 移行状況チェック
      final status = await migrationService.checkMigrationStatus(user.uid);

      if (status['migrated'] == true) {
        // 既に移行済み
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

      // 移行実行
      final success = await migrationService.migrateCurrentUserProfile();

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
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

      // エラー時もローディングを閉じる
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

  /// 定期購入アイテムのリセットメソッド
  Future<void> _resetPeriodicPurchaseItems() async {
    try {
      // ローディング表示
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

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
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

      // エラー時もローディングを閉じる
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

  /// 移行状況確認メソッド
  Future<void> _checkMigrationStatus() async {
    try {
      // ローディング表示
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

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
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

  /// データ移行実行メソッド
  Future<void> _performMigration() async {
    try {
      // 確認ダイアログ表示
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

      // ローディング表示
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

      // 移行実行
      final migrationService = ref.read(sharedListDataMigrationServiceProvider);
      final migratedCount = await migrationService.migrateAllData();

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 結果表示
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

  /// Hiveデータを完全削除（緊急用）
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
        content: const Text(
          '⚠️ ローカルの全データを削除しますか？\n\n'
          '・全グループ\n'
          '・全買い物リスト\n'
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
      // ローディング表示
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

      // ユーザー固有のBox名を構築
      final boxSuffix = user.uid;
      final sharedGroupBoxName = 'SharedGroups_$boxSuffix';
      final sharedListBoxName = 'SharedLists_$boxSuffix';

      // SharedGroups Boxを削除
      if (Hive.isBoxOpen(sharedGroupBoxName)) {
        await Hive.box(sharedGroupBoxName).close();
      }
      await Hive.deleteBoxFromDisk(sharedGroupBoxName);
      AppLogger.info('✅ [HIVE_CLEAR] SharedGroups削除完了');

      // SharedLists Boxを削除
      if (Hive.isBoxOpen(sharedListBoxName)) {
        await Hive.box(sharedListBoxName).close();
      }
      await Hive.deleteBoxFromDisk(sharedListBoxName);
      AppLogger.info('✅ [HIVE_CLEAR] SharedLists削除完了');

      // Boxを再オープン
      final hiveService = ref.read(userSpecificHiveProvider);
      await hiveService.initializeForUser(user.uid);
      AppLogger.info('✅ [HIVE_CLEAR] Hive再初期化完了');

      // Providerをリセット
      ref.invalidate(allGroupsProvider);
      ref.invalidate(selectedGroupIdProvider);
      AppLogger.info('✅ [HIVE_CLEAR] Provider無効化完了');

      // Firestoreから再同期
      final initService = ref.read(userInitializationServiceProvider);
      await initService.syncFromFirestoreToHive(user);
      AppLogger.info('✅ [HIVE_CLEAR] Firestore同期完了');

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 成功メッセージ
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

  /// 再認証ダイアログ（パスワード入力）
  Future<String?> _showReauthDialog() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.orange),
              SizedBox(width: 8),
              Text('再認証が必要です'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'セキュリティのため、パスワードを再入力してください。',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) {
                  final password = passwordController.text.trim();
                  if (password.isNotEmpty) {
                    Navigator.of(context).pop(password);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(password);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );
  }

  /// アカウント削除メソッド
  Future<void> _deleteAccount(User user) async {
    try {
      // 確認ダイアログ（ステップ1: 警告）
      final confirm1 = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('アカウント削除'),
            ],
          ),
          content: const Text(
            '⚠️ この操作は取り消せません\n\n'
            '以下のデータが完全に削除されます:\n'
            '• アカウント情報\n'
            '• 全ての買い物リスト\n'
            '• 作成したグループ（オーナーの場合）\n'
            '• ホワイトボードデータ\n'
            '• 通知履歴\n\n'
            '本当に削除しますか？',
            style: TextStyle(fontSize: 15),
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

      if (confirm1 != true) return;

      // 確認ダイアログ（ステップ2: 最終確認）
      final confirm2 = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('最終確認'),
          content: Text(
            'メールアドレス: ${user.email}\n\n'
            'このアカウントを本当に削除しますか？\n\n'
            'この操作は取り消せません。',
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
              child: const Text('完全に削除'),
            ),
          ],
        ),
      );

      if (confirm2 != true) return;

      // ローディング表示
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
                  Text('アカウントを削除中...'),
                  SizedBox(height: 8),
                  Text(
                    'データ削除 → 認証削除',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      AppLogger.info(
          '🗑️ [DELETE_ACCOUNT] アカウント削除開始: ${AppLogger.maskUserId(user.uid)}');

      // 1. Firestoreデータ削除
      final firestore = FirebaseFirestore.instance;

      // ⚠️ 重要: Batch削除を2段階に分ける
      // Batch1: サブコレクション（sharedLists, whiteboards）のみ
      // Batch2: 親グループ + 通知 + 招待 + ユーザープロファイル
      //
      // 理由: Batch内で親グループと子を同時に削除すると、
      // 子の削除時に get() で親を取得しようとして失敗する

      // === Batch 1: サブコレクション削除（先に実行） ===
      final batch1 = firestore.batch();
      int subCollectionCount = 0;

      // オーナーのグループを取得
      final ownerGroups = await firestore
          .collection('SharedGroups')
          .where('ownerUid', isEqualTo: user.uid)
          .get();

      AppLogger.info(
          '📝 [DELETE_ACCOUNT] オーナーグループ数: ${ownerGroups.docs.length}');

      for (var doc in ownerGroups.docs) {
        // グループ内のリスト削除
        final lists = await doc.reference.collection('sharedLists').get();
        for (var listDoc in lists.docs) {
          batch1.delete(listDoc.reference);
          subCollectionCount++;
        }
        AppLogger.info(
            '📝 [DELETE_ACCOUNT] グループ ${AppLogger.maskGroupId(doc.id, currentUserId: user.uid)} のリスト削除: ${lists.docs.length}件');

        // グループ内のホワイトボード削除
        final whiteboards = await doc.reference.collection('whiteboards').get();
        for (var wbDoc in whiteboards.docs) {
          batch1.delete(wbDoc.reference);
          subCollectionCount++;
        }
        AppLogger.info(
            '📝 [DELETE_ACCOUNT] グループ ${AppLogger.maskGroupId(doc.id, currentUserId: user.uid)} のホワイトボード削除: ${whiteboards.docs.length}件');
      }

      // Batch 1 実行（サブコレクションのみ）
      if (subCollectionCount > 0) {
        await batch1.commit();
        AppLogger.info('✅ [DELETE_ACCOUNT] サブコレクション削除完了（$subCollectionCount件）');
      }

      // === Batch 2: 親グループ + メンバー離脱 + 通知 + 招待 + ユーザープロファイル ===
      final batch2 = firestore.batch();

      // オーナーグループ削除
      for (var doc in ownerGroups.docs) {
        batch2.delete(doc.reference);
        AppLogger.info(
            '📝 [DELETE_ACCOUNT] オーナーグループ削除予約: ${AppLogger.maskGroupId(doc.id, currentUserId: user.uid)}');
      }

      // メンバーとして参加しているグループから離脱（allowedUidから自分のUIDを削除）
      final memberGroups = await firestore
          .collection('SharedGroups')
          .where('allowedUid', arrayContains: user.uid)
          .get();

      int leaveGroupCount = 0;
      for (var doc in memberGroups.docs) {
        final data = doc.data();
        // オーナーでない場合のみ離脱処理
        if (data['ownerUid'] != user.uid) {
          batch2.update(doc.reference, {
            'allowedUid': FieldValue.arrayRemove([user.uid]),
            'members': FieldValue.arrayRemove([
              {
                'memberId': user.uid,
                // 他のフィールドは削除時に必要ないため省略
              }
            ]),
          });
          leaveGroupCount++;
          AppLogger.info(
              '📝 [DELETE_ACCOUNT] グループ離脱予約: ${AppLogger.maskGroupId(doc.id, currentUserId: user.uid)}');
        }
      }
      AppLogger.info('📝 [DELETE_ACCOUNT] メンバーグループ離脱数: $leaveGroupCount');

      // 通知削除
      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      AppLogger.info('📝 [DELETE_ACCOUNT] 通知数: ${notifications.docs.length}');

      for (var doc in notifications.docs) {
        batch2.delete(doc.reference);
      }

      // 招待削除（invitedByが自分のもの）
      final invitations = await firestore
          .collection('invitations')
          .where('invitedBy', isEqualTo: user.uid)
          .get();

      AppLogger.info('📝 [DELETE_ACCOUNT] 招待数: ${invitations.docs.length}');

      for (var doc in invitations.docs) {
        batch2.delete(doc.reference);
      }

      // ユーザープロファイル削除（最後に削除）
      final userDoc = firestore.collection('users').doc(user.uid);
      batch2.delete(userDoc);
      AppLogger.info('📝 [DELETE_ACCOUNT] ユーザープロファイル削除予約（最後）');

      // Batch 2 実行（親グループ + 通知 + 招待 + プロファイル）
      await batch2.commit();
      AppLogger.info('✅ [DELETE_ACCOUNT] Firestoreデータ削除完了');

      // 2. Hiveデータ削除
      final boxSuffix = user.uid;
      final sharedGroupBoxName = 'SharedGroups_$boxSuffix';
      final sharedListBoxName = 'SharedLists_$boxSuffix';

      if (Hive.isBoxOpen(sharedGroupBoxName)) {
        await Hive.box(sharedGroupBoxName).close();
      }
      await Hive.deleteBoxFromDisk(sharedGroupBoxName);

      if (Hive.isBoxOpen(sharedListBoxName)) {
        await Hive.box(sharedListBoxName).close();
      }
      await Hive.deleteBoxFromDisk(sharedListBoxName);

      AppLogger.info('✅ [DELETE_ACCOUNT] Hiveデータ削除完了');

      // 3. SharedPreferences削除
      await UserPreferencesService.clearAllUserInfo();
      AppLogger.info('✅ [DELETE_ACCOUNT] SharedPreferences削除完了');

      // 4. Firebase Authアカウント削除
      try {
        await user.delete();
        AppLogger.info('✅ [DELETE_ACCOUNT] Firebase Authアカウント削除完了');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          AppLogger.warning('⚠️ [DELETE_ACCOUNT] 再認証が必要です');

          // ローディング閉じる
          if (!mounted) return;
          Navigator.of(context).pop();

          // 再認証ダイアログ表示
          final password = await _showReauthDialog();
          if (password == null || password.isEmpty) {
            // キャンセルされた
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('キャンセルされました'),
                content: const Text('アカウント削除をキャンセルしました。'),
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

          // 再認証実行
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );

          try {
            await user.reauthenticateWithCredential(credential);
            AppLogger.info('✅ [DELETE_ACCOUNT] 再認証成功');

            // ローディング再表示
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            // 再度削除試行
            await user.delete();
            AppLogger.info('✅ [DELETE_ACCOUNT] Firebase Authアカウント削除完了（再認証後）');
          } on FirebaseAuthException catch (e) {
            // ローディング閉じる
            if (mounted) Navigator.of(context).pop();

            AppLogger.error('❌ [DELETE_ACCOUNT] 再認証失敗: ${e.code}');

            if (!mounted) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('認証エラー'),
                  ],
                ),
                content: Text(
                  e.code == 'wrong-password'
                      ? 'パスワードが正しくありません。'
                      : '認証に失敗しました。\n\nエラー: ${e.message}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            );
            return;
          }
        } else {
          // その他のエラー
          rethrow;
        }
      }

      // 5. Provider無効化
      ref.invalidate(authStateProvider);
      ref.invalidate(allGroupsProvider);
      ref.invalidate(selectedGroupIdProvider);

      // ローディング閉じる
      if (!mounted) return;
      Navigator.of(context).pop();

      // 成功メッセージ
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('削除完了'),
            ],
          ),
          content: const Text(
            'アカウントとすべてのデータを削除しました。\n\n'
            'Go Shopをご利用いただきありがとうございました。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ホーム画面に戻る
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      AppLogger.error('❌ [DELETE_ACCOUNT] エラー', e, stack);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('削除失敗'),
            ],
          ),
          content: Text(
            'アカウント削除中にエラーが発生しました。\n\n'
            'エラー内容:\n$e\n\n'
            'お手数ですが、開発者にお問い合わせください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }
}

/// ホワイトボード設定パネル
class WhiteboardSettingsPanel extends ConsumerWidget {
  const WhiteboardSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: Colors.purple.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ホワイトボード設定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'カスタム色設定',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '基本4色（黒・赤・緑・黄）に加えて、2色を自由に設定できます',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // 色5の選択
              Row(
                children: [
                  const Text('色5: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildColorSelector(
                    context,
                    ref,
                    settings,
                    isColor5: true,
                    currentColor: Color(settings.whiteboardColor5),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 色6の選択
              Row(
                children: [
                  const Text('色6: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildColorSelector(
                    context,
                    ref,
                    settings,
                    isColor5: false,
                    currentColor: Color(settings.whiteboardColor6),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }

  Widget _buildColorSelector(BuildContext context, WidgetRef ref, settings,
      {required bool isColor5, required Color currentColor}) {
    // よく使う色のプリセット
    final presetColors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    return Wrap(
      spacing: 8,
      children: presetColors.map((color) {
        final isSelected = currentColor.value == color.value;
        return GestureDetector(
          onTap: () async {
            // 色を保存
            final repository = ref.read(userSettingsRepositoryProvider);
            final newSettings = isColor5
                ? settings.copyWith(whiteboardColor5: color.value)
                : settings.copyWith(whiteboardColor6: color.value);
            await repository.saveSettings(newSettings);
            ref.invalidate(userSettingsProvider);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
