import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/page_index_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_notifier_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../pages/home_page.dart';
import '../pages/shared_group_page.dart';
import '../pages/shopping_list_page_v2.dart';
import '../pages/settings_page.dart';
import '../flavors.dart';
import '../config/app_mode_config.dart';
import '../utils/app_logger.dart';
import '../widgets/common_app_bar.dart';

/// SyncStatusからSyncStateを計算するヘルパー関数
SyncState _getSyncState(SyncStatus syncStatus, bool isAuthenticated) {
  if (!isAuthenticated) {
    return SyncState.notLoggedIn;
  }

  switch (syncStatus) {
    case SyncStatus.synced:
      return SyncState.synced;
    case SyncStatus.syncing:
      return SyncState.syncing;
    case SyncStatus.offline:
    case SyncStatus.localOnly:
      return SyncState.offline;
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);
    // AppMode変更を監視して自動的に再構築
    ref.watch(appModeNotifierProvider);

    AppLogger.info('🔍 [HomeScreen] build() called - pageIndex: $pageIndex');

    // 認証状態を取得
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.when(
      data: (user) => user != null,
      loading: () => false,
      error: (_, __) => false,
    );

    // 同期状態を取得
    final syncStatus = ref.watch(syncStatusProvider);
    final syncState = _getSyncState(syncStatus, isAuthenticated);

    // 現在のグループを取得
    final selectedGroup = ref.watch(selectedGroupProvider).value;

    final List<Widget> pages = [
      const HomePage(),
      const SharedGroupPage(),
      const SharedListPageV2(),
      const SettingsPage(),
    ];

    // ページごとのAppBarを設定
    PreferredSizeWidget? appBar;
    switch (pageIndex) {
      case 0: // ホーム画面
        appBar = CommonAppBar(
          syncState: syncState,
          showUserName: true,
        );
        break;
      case 1: // グループ画面
        appBar = CommonAppBar(
          syncState: syncState,
          currentGroup: selectedGroup,
          showGroupName: true,
        );
        break;
      case 2: // リスト画面
        appBar = CommonAppBar(
          syncState: syncState,
          currentGroup: selectedGroup,
          showGroupName: true,
        );
        break;
      case 3: // 設定画面
        appBar = CommonAppBar(
          title: '設定',
          syncState: syncState,
        );
        break;
    }

    return Scaffold(
      appBar: appBar,
      body: pages[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIndex,
        onTap: (index) {
          AppLogger.info(
              '🔍 [HomeScreen] BottomNavigationBar tapped - index: $index, current: $pageIndex');

          // グループページ (index == 1) の場合は認証チェック（本番環境のみ）
          if (index == 1 && F.appFlavor == Flavor.prod) {
            final authState = ref.read(authStateProvider);
            final isAuthenticated = authState.maybeWhen(
              data: (user) => user != null,
              orElse: () => false,
            );

            if (!isAuthenticated) {
              AppLogger.info(
                  '🔍 [HomeScreen] User not authenticated - showing SnackBar');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${AppModeSettings.config.groupName}機能を使用するには、まずサインインしてください'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
          }

          AppLogger.info('🔍 [HomeScreen] Setting pageIndex to: $index');
          ref.read(pageIndexProvider.notifier).setPageIndex(index);
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: AppModeSettings.config.groupName,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: AppModeSettings.config.listName,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
