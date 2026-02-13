// デバッグ用：現在のグループ状態を確認
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goshopping/providers/auth_provider.dart';
import 'package:goshopping/providers/purchase_group_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: GroupDebugScreen(),
      ),
    ),
  );
}

class GroupDebugScreen extends ConsumerWidget {
  const GroupDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);
    final allGroupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('グループデバッグ')),
      body: authStateAsync.when(
        data: (user) {
          return allGroupsAsync.when(
            data: (groups) {
              // 注: デフォルトグループ機能は削除されました（2026-02-12）
              // groupId == user.uid の判定のみ実施
              final legacyDefaultGroups = groups
                  .where((g) =>
                      g.groupId == user?.uid || g.groupId == 'default_group')
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('現在のUID: ${user?.uid ?? "未ログイン"}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('全グループ数: ${groups.length}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    'レガシーデフォルトグループ数: ${legacyDefaultGroups.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: legacyDefaultGroups.length > 1
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 32),
                  const Text('全グループ一覧:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...groups.map((g) {
                    final isLegacyDefault =
                        g.groupId == user?.uid || g.groupId == 'default_group';
                    return Card(
                      color: isLegacyDefault ? Colors.yellow[100] : null,
                      child: ListTile(
                        title: Text(g.groupName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${g.groupId}'),
                            Text('syncStatus: ${g.syncStatus}'),
                            Text('isDeleted: ${g.isDeleted}'),
                          ],
                        ),
                        trailing: isLegacyDefault
                            ? const Icon(Icons.star, color: Colors.orange)
                            : null,
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('エラー: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('認証エラー: $e')),
      ),
    );
  }
}
