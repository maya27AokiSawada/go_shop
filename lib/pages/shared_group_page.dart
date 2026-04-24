import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';
import '../providers/security_provider.dart';
import '../providers/app_ui_mode_provider.dart';
import '../config/app_ui_mode_config.dart';
import '../widgets/group_list_widget.dart';
import '../widgets/group_creation_with_copy_dialog.dart';
import '../widgets/accept_invitation_widget.dart';

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
        appBar: AppBar(title: const Text('グループ管理')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'シークレットモードが有効です',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'グループデータを表示するにはログインが必要です',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    Log.info('🏷️ [PAGE BUILD] SharedGroupPage表示開始');

    final isSingle = ref.watch(appUIModeProvider) == AppUIMode.single;

    return Scaffold(
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: GroupListWidget(),
        ),
      ),
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
                  label: const Text('新しいグループ'),
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
