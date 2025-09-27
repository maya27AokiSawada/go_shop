import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../forms/sign_up_form.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../models/purchase_group.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final userNameController = TextEditingController();

  @override
  void dispose() {
    userNameController.dispose();
    super.dispose();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // 開発中メッセージを表示
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('開発中')),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    bool isFormVisible = false;
    return Scaffold(
    appBar: AppBar(title: const Text('Go Shopping')),
    body: Center(
      child: Builder(
        builder: (context) {
          // Replace with your actual logic to check authentication state
          return authState.when(
            data: (user) {
              if (user == null) { // 未ログイン状態ならサインイン・サインアップボタンを表示
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: userNameController,
                      decoration: const InputDecoration(labelText: 'User Name'),
                    ),
                    if (!isFormVisible)
                      ElevatedButton(
                        onPressed: () { // サインイン用入力フォーム表示
                          isFormVisible = true;
                        },
                        child: const Text('ログイン / サインアップ'),
                      ),
                    if (isFormVisible) SignUpForm(),                    
                    ElevatedButton(
                      onPressed: () async => await userInfoSave(),
                      child: const Text('保存')
                    ),
                  ],
                );
              } else {
                // ログイン済みUI
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ようこそ、${user.email ?? "ユーザー"}さん'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(authProvider).signOut();
                      },
                      child: const Text('ログアウト'),
                    ),
                  ],
                );
              }
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error: $err'),
          );
        },
      ),
    ),
  );
  }

  Future<void> userInfoSave() async {
  final userName = userNameController.text;
  
  if (userName.isNotEmpty && email.isNotEmpty) {
    try {
      // デフォルトグループを作成
      final defaultGroup = PurchaseGroup(
        groupId: 'defaultGroup',
        groupName: 'あなたのグループ',
        members: [
          PurchaseGroupMember(
            name: 'あなた',
            contact: '',
            role: PurchaseGroupRole.leader,
          )
        ],
      );
      
      // Hiveボックスにセーブ
      await ref.read(saveDefaultGroupProvider(defaultGroup).future);
      
      // 成功メッセージ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('デフォルトグループを保存しました')),
        );
      }
    } catch (e) {
      // エラーメッセージ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  } else {
    // 入力不足のメッセージ
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザー名とメールアドレスを入力してください')),
      );
    }
  }
}
}
