//未ログイン状態のページウィジェット
//　ログインしなくても使えるが、ユーザー名と購入リスト名を入力してログインすることで、
//　購入リストの共用ができるようになる。
//1. ユーザー名と購入リスト名の入力欄
//2. ユーザー名と購入リスト名の保存ボタン
//3.ログインボタン　このボタンをタップしたらメールアドレスとパスワードの入力欄とサインイン、
// サインアップ、戻るの3ボタンを表示する。
import 'package:flutter/material.dart';

class NotSignedInPage extends StatefulWidget {
  const NotSignedInPage({Key? key}) : super(key: key);

  @override
  _NotSignedInPageState createState() => _NotSignedInPageState();
}

class _NotSignedInPageState extends State<NotSignedInPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();

  bool _showLoginFields = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _saveUserInfo() {
    // ユーザー名と購入リスト名の保存処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ユーザー名と購入リスト名を保存しました')),
    );
  }

  void _signIn() {
    // サインイン処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('サインインしました')),
    );
  }

  void _signUp() {
    // サインアップ処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('サインアップしました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('未ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(labelText: 'ユーザー名'),
            ),
            TextField(
              controller: _listNameController,
              decoration: const InputDecoration(labelText: '購入リスト名'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveUserInfo,
              child: const Text('保存'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showLoginFields = true;
                });
              },
              child: const Text('ログイン'),
            ),
            if (_showLoginFields) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _signIn,
                    child: const Text('サインイン'),
                  ),
                  ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('サインアップ'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showLoginFields = false;
                      });
                    },
                    child: const Text('戻る'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
