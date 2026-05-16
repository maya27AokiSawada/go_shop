import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';
import '../providers/security_provider.dart';
import '../providers/app_ui_mode_provider.dart';
import '../providers/shared_group_provider.dart';
import '../config/app_ui_mode_config.dart';
import '../widgets/group_list_widget.dart';
import '../widgets/group_creation_with_copy_dialog.dart';
import '../widgets/accept_invitation_widget.dart';
import '../widgets/initial_setup_widget.dart';
import '../l10n/l10n.dart';

class SharedGroupPage extends ConsumerStatefulWidget {
  const SharedGroupPage({super.key});

  @override
  ConsumerState<SharedGroupPage> createState() => _SharedGroupPageState();
}

class _SharedGroupPageState extends ConsumerState<SharedGroupPage> {
  @override
  Widget build(BuildContext context) {
    // セキュリティチェック
    final canViewData = ref.watch(dataVisibilityProvider);
    final authRequired = ref.watch(authRequiredProvider);

    if (!canViewData && authRequired) {
      return Scaffold(
        appBar: AppBar(title: Text(texts.groupManagement)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                texts.secretModeEnabled,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                texts.groupDataRequiresLogin,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    Log.info('🏷️ [PAGE BUILD] SharedGroupPage表示開始');

    final isSingle = ref.watch(appUIModeProvider) == AppUIMode.single;

    // シングルモードの場合、グループ数に応じて表示内容を切り替える
    Widget body;
    if (isSingle) {
      final groupsAsync = ref.watch(allGroupsProvider);
      body = groupsAsync.when(
        data: (groups) => groups.isEmpty
            ? const InitialSetupWidget()
            : const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: GroupListWidget(),
                ),
              ),
        loading: () {
          // ローディング中も直前データがあれば表示を維持し、
          // 0→1遷移時の急激なツリー置換を避ける。
          final cachedGroups = groupsAsync.valueOrNull;
          if (cachedGroups != null) {
            return cachedGroups.isEmpty
                ? const InitialSetupWidget()
                : const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: GroupListWidget(),
                    ),
                  );
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (_, __) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: GroupListWidget(),
          ),
        ),
      );
    } else {
      body = const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: GroupListWidget(),
        ),
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: isSingle
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const QRScannerScreen()));
                  },
                  heroTag: 'scan_qr_code',
                  child: const Icon(Icons.qr_code_scanner),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  onPressed: () => _showCreateGroupDialog(context),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.group_add),
                  label: Text(texts.newGroup),
                  heroTag: 'create_group',
                ),
              ],
            ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showGroupCreationWithCopyDialog(context: context);
  }
}
