// lib/pages/purchase_group_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/page_index_provider.dart';
class PurchaseGroupPage extends ConsumerWidget {
  const PurchaseGroupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final user = FirebaseAuth.instance.currentUser;
  final purchaseGroupAsync = ref.watch(purchaseGroupProvider);
   if (user == null) {
    // ユーザーがサインインしていない場合の処理
    Future.microtask(() async {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('サインインしてください。')),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        // pageIndexプロバイダーを0にセットしてhome_pageに遷移
        ref.read(pageIndexProvider.notifier).setPageIndex(0);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
   }
  return purchaseGroupAsync.when(
    data: (purchaseGroup) {
      final members = List<String>.from(purchaseGroup.members);
      final controller = TextEditingController();

      return Scaffold(
        appBar: AppBar(title: const Text('購入グループメンバー')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('メンバー一覧:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      title: Text(member),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          members.removeAt(index);
                          await ref.read(purchaseGroupProvider.notifier).updateMembers(members);
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: '新しいメンバーのメールアドレス',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final email = controller.text.trim();
                      if (email.isNotEmpty && !members.contains(email)) {
                        members.add(email);
                        await ref.read(purchaseGroupProvider.notifier).updateMembers(members);
                        controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
    loading: () => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    error: (e, st) => Scaffold(
      body: Center(child: Text('エラーが発生しました: $e')),
    ),
  );
  }
}


