// lib/widgets/home_page_widgets/unauthenticated_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 未ログイン時のUI
class UnauthenticatedView extends ConsumerStatefulWidget {
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSaveUserName;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onSignUp;

  const UnauthenticatedView({
    super.key,
    required this.userNameController,
    required this.emailController,
    required this.passwordController,
    required this.onSaveUserName,
    required this.onSignIn,
    required this.onSignUp,
  });

  @override
  ConsumerState<UnauthenticatedView> createState() => _UnauthenticatedViewState();
}

class _UnauthenticatedViewState extends ConsumerState<UnauthenticatedView> {
  bool showSignInForm = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          const Icon(Icons.shopping_cart, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Go Shop',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '家族・グループで共有する買い物リスト',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          
          // ユーザー名入力欄（常に表示）
          TextFormField(
            controller: widget.userNameController,
            decoration: const InputDecoration(
              labelText: 'User Name',
              border: OutlineInputBorder(),
              hintText: 'ユーザー名を入力してください',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'ユーザー名を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // サインインフォームが表示されていない時のみ表示
          if (!showSignInForm) ...[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showSignInForm = true;
                });
              },
              child: const Text('サインイン / サインアップ'),
            ),
          ],
          
          // サインインフォーム
          if (showSignInForm) ...[
            TextFormField(
              controller: widget.emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                hintText: 'メールアドレスを入力してください',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                hintText: 'パスワードを入力してください',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onSignIn,
                    child: const Text('サインイン'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onSignUp,
                    child: const Text('サインアップ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  showSignInForm = false;
                });
              },
              child: const Text('キャンセル'),
            ),
          ],
          
          const SizedBox(height: 40),
          const Text(
            'アカウントなしでも利用できます',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
