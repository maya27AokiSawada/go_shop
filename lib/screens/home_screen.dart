import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/page_index_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_notifier_provider.dart';
import '../pages/home_page.dart';
import '../pages/purchase_group_page.dart';
import '../pages/shopping_list_page_v2.dart';
import '../flavors.dart';
import '../config/app_mode_config.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);
    // AppMode変更を監視して自動的に再構築
    ref.watch(appModeNotifierProvider);

    final List<Widget> pages = [
      const HomePage(),
      const PurchaseGroupPage(),
      const ShoppingListPageV2(), // 新しいバージョンを使用
    ];

    return Scaffold(
      body: pages[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: (index) {
          // グループページ (index == 1) の場合は認証チェック（本番環境のみ）
          if (index == 1 && F.appFlavor == Flavor.prod) {
            final authState = ref.read(authStateProvider);
            final isAuthenticated = authState.maybeWhen(
              data: (user) => user != null,
              orElse: () => false,
            );

            if (!isAuthenticated) {
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
        ],
      ),
    );
  }
}
