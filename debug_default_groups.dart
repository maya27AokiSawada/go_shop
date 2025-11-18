// デバッグ用：現在のグループ状態を確認
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_shop/providers/auth_provider.dart';
import 'package:go_shop/providers/purchase_group_provider.dart';
import 'package:go_shop/utils/group_helpers.dart';

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
              final defaultGroups =
                  groups.where((g) => isDefaultGroup(g, user)).toList();

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
                    'デフォルトグループ数: ${defaultGroups.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          defaultGroups.length > 1 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 32),
                  const Text('全グループ一覧:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...groups.map((g) {
                    final isDefault = isDefaultGroup(g, user);
                    return Card(
                      color: isDefault ? Colors.yellow[100] : null,
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
                        trailing: isDefault
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
