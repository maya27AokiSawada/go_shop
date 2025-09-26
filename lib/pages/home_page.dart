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
    final isVisible = ref.watch(showFormProvider);

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
                    if (!isVisible)
                      ElevatedButton(
                        onPressed: () { // サインイン用入力フォーム表示
                          ref.read(showFormProvider.notifier).state = true;
                        },
                        child: const Text('ログイン / サインアップ'),
                      ),
                    if (isVisible) SignUpForm(),                
                  ],
                );
              } else {
                // ログイン済みUI
                return Scaffold(
                  body: Column(
                    children: [
                      TextField(
                        controller: userNameController,
                        decoration: const InputDecoration(labelText: 'User Name'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await ref.read(authProvider).signOut();
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
