import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../providers/shared_group_provider.dart';
import '../widgets/accept_invitation_widget.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../config/app_mode_config.dart';
import '../l10n/l10n.dart';

/// 初回セットアップ画面
///
/// グループが0個の場合に表示され、以下の2つの選択肢を提供：
/// 1. 最初のグループを作成
/// 2. QRコードをスキャンして既存グループに参加
class InitialSetupWidget extends ConsumerStatefulWidget {
  const InitialSetupWidget({super.key});

  @override
  ConsumerState<InitialSetupWidget> createState() => _InitialSetupWidgetState();
}

class _InitialSetupWidgetState extends ConsumerState<InitialSetupWidget> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // アプリアイコン＆タイトル
                const Icon(
                  Icons.shopping_bag,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  texts.welcomeToGoShop,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  texts.initialSetupDesc(texts.sharedListNameForMode(
                      AppModeSettings.currentMode == AppMode.shopping)),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 選択肢1: 最初のグループを作成
                ElevatedButton.icon(
                  onPressed: () => _showCreateGroupDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(
                    texts.createFirstGroup,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // 選択肢2: QRコードでグループに参加
                OutlinedButton.icon(
                  onPressed: () => _showQRScanner(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(
                    texts.joinGroupByQR,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                const SizedBox(height: 48),

                // 説明テキスト
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              texts.aboutGroups,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        texts.aboutGroupsDesc,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// グループ作成ダイアログを表示
  void _showCreateGroupDialog(BuildContext context) {
    final groupNameController = TextEditingController();
    final mediaQuery = MediaQuery.of(context);

    if (!context.mounted) return;
    showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(texts.createFirstGroup),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: mediaQuery.size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.enterGroupName),
                const SizedBox(height: 16),
                TextField(
                  controller: groupNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: texts.groupName,
                    hintText: texts.groupNameHint,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    final groupName = value.trim();
                    if (groupName.isNotEmpty) {
                      Navigator.pop(dialogContext, groupName);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: Text(texts.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final groupName = groupNameController.text.trim();
              if (groupName.isNotEmpty) {
                Navigator.pop(dialogContext, groupName);
              }
            },
            child: Text(texts.create),
          ),
        ],
      ),
    ).then((groupName) async {
      groupNameController.dispose();
      if (groupName == null || groupName.isEmpty) return;
      if (!mounted) return;
      // ダイアログのクローズアニメーション完了後に実行し、
      // route破棄とprovider再計算の競合（_dependents.isEmpty）を回避する。
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      unawaited(_createGroup(context, groupName));
    });
  }

  /// グループを作成
  Future<void> _createGroup(BuildContext context, String groupName) async {
    if (!mounted) return;
    Log.info('🆕 [INITIAL_SETUP] グループ作成: $groupName');
    try {
      await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
      Log.info('✅ [INITIAL_SETUP] グループ作成完了 - allGroupsProvider更新により自動遷移');
      // allGroupsProvider が AsyncData([newGroup]) に更新されると
      // SharedGroupPage が自動的に GroupListWidget に切り替わる
    } catch (e, stackTrace) {
      Log.error('❌ [INITIAL_SETUP] グループ作成エラー: $e');
      Log.error('スタックトレース: $stackTrace');
      if (mounted) {
        SnackBarHelper.showCustom(
          this.context,
          message: '${texts.createGroupFailed}: ${e.toString()}',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  /// QRスキャナーを表示
  void _showQRScanner(BuildContext context) {
    Log.info('📷 [INITIAL_SETUP] QRスキャナー表示');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(texts.scanQRCode),
          ),
          body: const AcceptInvitationWidget(),
        ),
      ),
    );
  }
}
