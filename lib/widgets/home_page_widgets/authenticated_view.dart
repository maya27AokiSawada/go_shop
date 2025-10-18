// lib/widgets/home_page_widgets/authenticated_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ログイン済み時のUI
class AuthenticatedView extends ConsumerWidget {
  final User user;
  final String? userName;
  final TextEditingController userNameController;
  final VoidCallback onSaveUserName;
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenGroupManagement;
  final VoidCallback onOpenShoppingList;

  const AuthenticatedView({
    super.key,
    required this.user,
    this.userName,
    required this.userNameController,
    required this.onSaveUserName,
    required this.onSignOut,
    required this.onOpenGroupManagement,
    required this.onOpenShoppingList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ようこそ、${userName ?? user.email ?? "ユーザー"}さん',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // ユーザー名編集
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ユーザー名設定',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: userNameController,
                    decoration: const InputDecoration(
                      labelText: 'ユーザー名',
                      border: OutlineInputBorder(),
                      hintText: '表示名を入力してください',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ユーザー名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSaveUserName,
                          icon: const Icon(Icons.save),
                          label: const Text('ユーザー名を保存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // メイン機能ボタン
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.group, color: Colors.blue),
                  title: const Text('グループ管理'),
                  subtitle: const Text('メンバーの追加・削除、招待管理'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: onOpenGroupManagement,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.shopping_cart, color: Colors.green),
                  title: const Text('買い物リスト'),
                  subtitle: const Text('共有リストの表示・編集'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: onOpenShoppingList,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // サインアウトボタン
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('サインアウト'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ログイン状態: ${user.email ?? "不明"}',
            style: const TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
