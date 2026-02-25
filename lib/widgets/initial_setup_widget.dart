import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/purchase_group_provider.dart';
import '../providers/page_index_provider.dart';
import '../widgets/accept_invitation_widget.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';

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
                onPressed: () async =>
                    await _showCreateGroupDialog(context, ref),
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
  Future<void> _showCreateGroupDialog(
      BuildContext context, WidgetRef ref) async {
    // 🔥 FIX: ref.read() → ref.watch()に変更（依存関係追跡のため）
    // Firestoreからグループ一覧の同期完了を待つ（DropdownButton重複値エラー防止）
    try {
      AppLogger.info('🔄 [INITIAL_SETUP] allGroupsProvider同期開始...');
      // ref.read()は_dependents.isEmptyエラーを引き起こす可能性がある
      // ここでは同期待機が必要なので、watchで依存関係を確立してからfutureを待つ
      final groupsAsync = ref.watch(allGroupsProvider);
      await groupsAsync.when(
        data: (_) => Future.value(),
        loading: () => Future.value(),
        error: (e, _) => throw e,
      );
      AppLogger.info('✅ [INITIAL_SETUP] allGroupsProvider同期完了 - ダイアログ表示');
    } catch (e) {
      AppLogger.error('❌ [INITIAL_SETUP] allGroupsProvider読み込みエラー: $e');
      // エラー時も処理続行（Hiveキャッシュで動作可能）
    }

    final groupNameController = TextEditingController();

    // 🔥 FIX: 外側のcontextとrefを保存（ダイアログ内部のcontextと混同しないため）
    final outerContext = context;
    final outerRef = ref;

    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
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
                  Navigator.pop(dialogContext);
                  // 🔥 FIX: 外側のcontextとrefを使用
                  _createGroup(outerContext, outerRef, value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              groupNameController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final groupName = groupNameController.text.trim();
              if (groupName.isNotEmpty) {
                Navigator.pop(dialogContext);
                // 🔥 FIX: 外側のcontextとrefを使用
                _createGroup(outerContext, outerRef, groupName);
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

    bool dialogShown = false;

    try {
      // ローディング表示
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
        dialogShown = true;

        // ダイアログが表示されるのを少し待つ
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // グループ作成
      await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);

      Log.info('✅ [INITIAL_SETUP] グループ作成完了');

      // 🔥 FIX: グループ作成後、即座にグループページ（タブ1）に遷移
      // これにより0→1遷移時の競合を回避（InitialSetupWidgetから離れる）
      if (context.mounted) {
        // ローディングダイアログを閉じる
        Navigator.of(context, rootNavigator: true).pop();
        dialogShown = false;

        // 🔥 CRITICAL FIX: ProviderScopeから直接refを取得（widget-scopedなrefを使わない）
        // InitialSetupWidgetが削除されても、アプリ全体のProviderScopeは存続するため安全
        ProviderScope.containerOf(context)
            .read(pageIndexProvider.notifier)
            .setPageIndex(1);

        Log.info('✅ [INITIAL_SETUP] グループページに遷移 - 「$groupName」作成完了');

        // 🔥 CRITICAL: setPageIndex(1)でInitialSetupWidgetが削除されるため、
        // この時点でreturnして後続の処理（context/ref使用）を実行しない
        return;
      }
    } catch (e, stackTrace) {
      Log.error('❌ [INITIAL_SETUP] グループ作成エラー: $e');
      Log.error('スタックトレース: $stackTrace');

      // ローディング閉じる
      if (dialogShown && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (navError) {
          Log.warning('⚠️ [INITIAL_SETUP] Navigator.pop失敗: $navError');
        }
      }

      // エラーメッセージ
      if (context.mounted) {
        SnackBarHelper.showCustom(
          context,
          message: 'グループ作成に失敗しました: ${e.toString()}',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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
