import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/purchase_group_provider.dart';
import '../widgets/group_creation_with_copy_dialog.dart';
import '../widgets/accept_invitation_widget.dart';
import '../utils/app_logger.dart';

/// 初回セットアップ画面
///
/// グループが0個の場合に表示され、以下の2つの選択肢を提供：
/// 1. 最初のグループを作成
/// 2. QRコードをスキャンして既存グループに参加
class InitialSetupWidget extends ConsumerWidget {
  const InitialSetupWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                'GoShoppingへようこそ！',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '買い物リストをグループで共有できるアプリです。\nまずはグループを作成するか、\n既存のグループに参加してください。',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // 選択肢1: 最初のグループを作成
              ElevatedButton.icon(
                onPressed: () => _showCreateGroupDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text(
                  '最初のグループを作成',
                  style: TextStyle(fontSize: 16),
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
                onPressed: () => _showQRScanner(context, ref),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  'QRコードでグループに参加',
                  style: TextStyle(fontSize: 16),
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
                        Text(
                          'グループについて',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• グループ内で買い物リストを共有できます\n'
                      '• 家族、友人、同僚など複数のグループを作成可能\n'
                      '• QRコードで簡単に招待・参加できます',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// グループ作成ダイアログを表示
  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    Log.info('🆕 [INITIAL_SETUP] グループ作成ダイアログ表示');

    final groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最初のグループを作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('グループ名を入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: groupNameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'グループ名',
                hintText: '例: 家族、友人、会社',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _createGroup(context, ref, value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              groupNameController.dispose();
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final groupName = groupNameController.text.trim();
              if (groupName.isNotEmpty) {
                Navigator.pop(context);
                _createGroup(context, ref, groupName);
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
    ).then((_) => groupNameController.dispose());
  }

  /// グループを作成
  Future<void> _createGroup(
      BuildContext context, WidgetRef ref, String groupName) async {
    Log.info('🆕 [INITIAL_SETUP] グループ作成: $groupName');

    // ローディングダイアログのBuildContextを保存
    BuildContext? dialogContext;

    try {
      // ローディング表示
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            dialogContext = ctx; // ダイアログのcontextを保存
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }

      // グループ作成
      await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);

      Log.info('✅ [INITIAL_SETUP] グループ作成完了');

      // ローディング閉じる（ダイアログのcontextを使用）
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // 成功メッセージ（元のcontextで表示できる場合のみ）
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「$groupName」を作成しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Log.error('❌ [INITIAL_SETUP] グループ作成エラー: $e');

      // ローディング閉じる（ダイアログのcontextを使用）
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // エラーメッセージ
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('グループ作成に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// QRスキャナーを表示
  void _showQRScanner(BuildContext context, WidgetRef ref) {
    Log.info('📷 [INITIAL_SETUP] QRスキャナー表示');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('QRコードをスキャン'),
          ),
          body: const AcceptInvitationWidget(),
        ),
      ),
    );
  }
}
