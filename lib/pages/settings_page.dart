import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../services/user_initialization_service.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';
import '../widgets/settings/auth_status_panel.dart';
import '../widgets/settings/firestore_sync_status_panel.dart';
import '../widgets/settings/app_mode_switcher_panel.dart';
import '../widgets/settings/app_ui_mode_switcher_panel.dart';
import '../providers/app_ui_mode_provider.dart';
import '../config/app_ui_mode_config.dart';
import '../widgets/settings/privacy_settings_panel.dart';
import '../widgets/settings/whiteboard_settings_panel.dart';
import '../widgets/settings/developer_tools_section.dart';
import '../widgets/settings/feedback_debug_section.dart';
import '../widgets/settings/data_maintenance_section.dart';
import '../widgets/settings/feedback_section.dart';
import '../widgets/settings/account_deletion_section.dart';
import '../widgets/settings/purchase_plan_panel.dart';

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
                AuthStatusPanel(user: user),
                const SizedBox(height: 12),
                if (isAuthenticated)
                  FirestoreSyncStatusPanel(syncStatus: syncStatus),
                if (isAuthenticated && syncStatus != 'idle')
                  const SizedBox(height: 12),
                const SizedBox(height: 20),
                // 課金UI無効化（配信停止方針のため非表示）
                // const AppUIModeSwicherPanel(),
                // const SizedBox(height: 20),
                // if (ref.watch(appUIModeProvider) == AppUIMode.multi)
                //   const AppModeSwitcherPanel(),
                // if (ref.watch(appUIModeProvider) == AppUIMode.multi)
                //   const SizedBox(height: 20),
                // const PurchasePlanPanel(),
                // const SizedBox(height: 20),
                const PrivacySettingsPanel(),
                const SizedBox(height: 20),
                const WhiteboardSettingsPanel(),
                const SizedBox(height: 20),
                if (F.appFlavor == Flavor.dev) ...[
                  DeveloperToolsSection(user: user),
                  const SizedBox(height: 20),
                  const FeedbackDebugSection(),
                  const SizedBox(height: 20),
                  DataMaintenanceSection(user: user),
                  const SizedBox(height: 20),
                ],
                const FeedbackSection(),
                const SizedBox(height: 20),
                if (user != null) ...[
                  AccountDeletionSection(user: user),
                  const SizedBox(height: 20),
                ],
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
                Text(
                  'Error: $err',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
