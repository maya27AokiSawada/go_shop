//ログイン状態のHome画面の子ページウィジェット
//1.ユーザー名と購入リスト名の表示
//2.保存ボタン
//3.ログアウトボタン
//購入リストはドロップダウンリストとして新規リスト名の入力も可能とする
//当面ダミーとして開発中いうメッセージのみ表示する
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SignedInPage extends ConsumerStatefulWidget {
  const SignedInPage({Key? key}) : super(key: key);

  @override
  _SignedInPageState createState() => _SignedInPageState();
}

class _SignedInPageState extends ConsumerState<SignedInPage> {
  String? selectedList;
  final TextEditingController _newListController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ホーム'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: ref.read(authStateProvider.notifier).signOut(),
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16.0), child: Text('開発中です')),
    );
  }
}
