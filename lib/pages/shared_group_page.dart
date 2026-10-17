import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../providers/security_provider.dart';
import '../providers/app_ui_mode_provider.dart';
import '../providers/page_index_provider.dart';
import '../providers/shared_group_provider.dart';
import '../config/app_ui_mode_config.dart';
import '../widgets/group_list_widget.dart';
import '../widgets/group_creation_with_copy_dialog.dart';
import '../widgets/accept_invitation_widget.dart';
import '../l10n/l10n.dart';

class SharedGroupPage extends ConsumerStatefulWidget {
  const SharedGroupPage({super.key});

  @override
  ConsumerState<SharedGroupPage> createState() => _SharedGroupPageState();
}

class _SharedGroupPageState extends ConsumerState<SharedGroupPage> {
  /// シングルモードでマルチモードの案内を表示した回数を保存するキー。
  static const String _multiModeHintCountKey = 'multi_mode_hint_shown_count';

  /// マルチモードの案内を表示する回数（グループ画面を開いた最初のN回）。
  static const int _multiModeHintMaxCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showMultiModeHint());
  }

  /// シングルモードの間、グループ画面を開いた最初の数回だけ、
  /// 複数グループを使うにはマルチモードへ切り替える必要があることを案内する。
  Future<void> _showMultiModeHint() async {
    if (ref.read(appUIModeProvider) != AppUIMode.single) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final shownCount = prefs.getInt(_multiModeHintCountKey) ?? 0;
      if (shownCount >= _multiModeHintMaxCount) return;
      await prefs.setInt(_multiModeHintCountKey, shownCount + 1);
    } catch (e) {
      Log.warning('⚠️ [GROUP_PAGE] マルチモード案内の表示回数を記録できません: $e');
      return;
    }

    if (!mounted) return;
    // スナックバーはタブを移っても表示が残る一方、この画面は破棄されるため、
    // ボタンを押した時点で ref を使わないよう、先に notifier を取得しておく。
    final pageIndexNotifier = ref.read(pageIndexProvider.notifier);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texts.multiModeHint),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: texts.openSettings,
          // 下部ナビゲーションの設定タブ（index 3）へ移動する
          onPressed: () => pageIndexNotifier.setPageIndex(3),
        ),
      ),
    );
  }

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

    // シングルモードでグループが1つ以上あるときFABを無効化
    final isSingle = ref.watch(appUIModeProvider) == AppUIMode.single;
    final groupCount = ref.watch(allGroupsProvider).valueOrNull?.length ?? 0;
    final fabDisabled = isSingle && groupCount >= 1;

    // グループ数に関わらず常にGroupListWidgetを表示。
    // 空状態時の案内テキスト（作成 or QRスキャン）はGroupListWidget内が担当。
    return Scaffold(
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: GroupListWidget(),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: fabDisabled
                ? null
                : () {
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
            onPressed: fabDisabled
                ? null
                : () async {
                    await _showCreateGroupDialog(context);
                  },
            backgroundColor: fabDisabled ? Colors.grey.shade300 : Colors.blue,
            foregroundColor: fabDisabled ? Colors.grey.shade500 : Colors.white,
            icon: const Icon(Icons.group_add),
            label: Text(texts.newGroup),
            heroTag: 'create_group',
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final result = await showGroupCreationWithCopyDialog(context: context);
    if (result != true) {
      return;
    }

    ref.invalidate(allGroupsProvider);
    try {
      await ref.read(allGroupsProvider.future);
    } catch (e) {
      Log.warning('⚠️ [GROUP PAGE] グループ一覧再読み込みエラー: $e');
    }
  }
}
