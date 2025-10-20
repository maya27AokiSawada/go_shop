import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_panel_widget.dart';
import '../widgets/user_name_panel_widget.dart';
import '../widgets/qr_code_panel_widget.dart';
import '../widgets/news_and_ads_panel_widget.dart';

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
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Shop'),
      ),
      body: authState.when(
        data: (user) {
          final isAuthenticated = user != null;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ステータス表示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAuthenticated ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAuthenticated ? Colors.green.shade200 : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAuthenticated ? Icons.check_circle : Icons.account_circle,
                        color: isAuthenticated ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAuthenticated 
                            ? 'ログイン済み: ${user.email}'
                            : '未ログイン状態',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isAuthenticated ? Colors.green.shade800 : Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 1. ニュース＆広告パネル（常に表示、認証状態で内容変更）
                const NewsAndAdsPanelWidget(),
                
                const SizedBox(height: 20),
                
                // 2. ユーザー名パネル（常に表示）
                UserNamePanelWidget(
                  userNameController: userNameController,
                  onSaveSuccess: () {
                    // ユーザー名保存成功時の処理
                  },
                ),
                
                const SizedBox(height: 20),
                
                // 3. サインインパネル（未認証時のみ表示）
                if (!isAuthenticated) ...[
                  AuthPanelWidget(
                    onAuthSuccess: () {
                      // 認証成功時の処理
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                
                // 4. QRコード招待パネル（ログイン済み時のみ表示）
                if (isAuthenticated) ...[
                  QRCodePanelWidget(
                    onShowSignInForm: () {
                      // サインインフォーム表示要求時の処理
                    },
                    onQRSuccess: () {
                      // QRコード処理成功時の処理
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                
                const SizedBox(height: 20),
                
                // 5. サインアウトボタン（認証済み時のみ表示）
                if (isAuthenticated) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // 確認ダイアログを表示
                        final shouldSignOut = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('ログアウト確認'),
                            content: const Text('ログアウトしますか？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('キャンセル'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('ログアウト'),
                              ),
                            ],
                          ),
                        );
                        
                        if (shouldSignOut == true) {
                          await ref.read(authProvider).signOut();
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('ログアウト'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // フッター情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Go Shop - モジュラー設計による買い物リスト共有アプリ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('認証状態を確認中...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $err',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}