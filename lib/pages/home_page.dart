import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../forms/sign_up_form.dart';
import '../providers/auth_provider.dart';

  
// login Information input form isVisible
final showFormProvider = StateProvider<bool>((ref) => false);
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final userNameController = TextEditingController();
  final listNameController = TextEditingController();
  final userNameControllerLoggedIn = TextEditingController();
  final listNameControllerLoggedIn = TextEditingController();

  @override
  void dispose() {
    userNameController.dispose();
    listNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 開発中メッセージを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開発中')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isVisible = ref.watch(showFormProvider);

    return Scaffold(
    appBar: AppBar(title: const Text('Go Shopping')),
    body: Center(
      child: Builder(
        builder: (context) {
          // Replace with your actual logic to check authentication state
          return authState.when(
            data: (user) {
              if (user == null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isVisible)
                      ElevatedButton(
                        onPressed: () {
                          ref.read(showFormProvider.notifier).state = true;
                        },
                        child: const Text('ログイン / サインアップ'),
                      ),
                    if (isVisible) SignUpForm(),
                    // 名前・リスト名フォームもここに
                    TextField(
                      controller: userNameController,
                      decoration: const InputDecoration(labelText: 'User Name'),
                    ),
                    TextField(
                      controller: listNameController,
                      decoration: const InputDecoration(labelText: 'List Name'),
                    ),                
                  ],
                );
              } else {
                // ログイン済みUI
                return Scaffold(
                  body: Column(
                    children: [
                      TextField(
                        controller: userNameControllerLoggedIn,
                        decoration: const InputDecoration(labelText: 'User Name'),
                        ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'List Name'),
                        controller: listNameControllerLoggedIn,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await ref.read(authStateProvider).signOut();
                        },
                        child: const Text('ログアウト'),
                      )
                    ],
                  ),
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
}

extension on AsyncValue<User?> {
  Future<void> signOut() {}
}