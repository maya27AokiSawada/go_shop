import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/page_index_provider.dart';
import '../pages/home_page.dart';
import '../pages/purchase_group_page_simple.dart';
import '../pages/shopping_list_page.dart';
import '../widgets/hive_initialization_wrapper.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key}); 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);
    ref.watch(isFormVisibleProvider);
    final List<Widget> pages = [
    const HomePage(),
    const PurchaseGroupPageSimple(),
    const ShoppingListPage(),
  ];

    return HiveInitializationWrapper(
      child: Scaffold(
        body: pages[pageIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: pageIndex,
          onTap: (index) {
            ref.read(pageIndexProvider.notifier).setPageIndex(index);
         },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'グループ'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: '買い物リスト'),
          ],
        ),
      ),
    );
  }
}
