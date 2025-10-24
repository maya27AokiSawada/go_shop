import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/page_index_provider.dart';
import '../providers/auth_provider.dart';
import '../pages/home_page.dart';
import '../pages/purchase_group_page.dart';
import '../pages/shopping_list_page.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);

    final List<Widget> pages = [
      const HomePage(),
      const PurchaseGroupPage(),
      const ShoppingListPage(),
    ];

    return Scaffold(
      body: pages[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: (index) {
          // グループページ (index == 1) の場合は認証チェック
          if (index == 1) {
            final authState = ref.read(authStateProvider);
            final isAuthenticated = authState.maybeWhen(
              data: (user) => user != null,
              orElse: () => false,
            );

            if (!isAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('グループ機能を使用するには、まずサインインしてください'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
          }

          ref.read(pageIndexProvider.notifier).setPageIndex(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'グループ'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '買い物リスト'),
        ],
      ),
    );
  }
}
