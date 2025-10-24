import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/access_control_service.dart';
import '../services/user_preferences_service.dart';
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
  bool _isSecretMode = false;

  @override
  void initState() {
    super.initState();
    print('🚀 HomePage: initState実行 - 直接SharedPreferencesからユーザー名を読み込み');

    // プロバイダーとは別に、直接SharedPreferencesから読み込みを実行
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          final userName = await UserPreferencesService.getUserName();
          if (userName != null && userName.isNotEmpty) {
            userNameController.text = userName;
            print('✅ HomePage: UserPreferencesServiceから直接ユーザー名取得: $userName');
          } else {
            print('❌ HomePage: UserPreferencesServiceにユーザー名が保存されていません');
          }

          // シークレットモード状態も読み込み
          final accessControl = ref.read(accessControlServiceProvider);
          final isSecretMode = await accessControl.isSecretModeEnabled();
          setState(() {
            _isSecretMode = isSecretMode;
          });
        } catch (e) {
          print('❌ HomePage: UserPreferences読み込みエラー: $e');
        }
      }
    });
  }

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
                    color: isAuthenticated
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAuthenticated
                          ? Colors.green.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAuthenticated
                            ? Icons.check_circle
                            : Icons.account_circle,
                        color: isAuthenticated ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAuthenticated ? 'ログイン済み: ${user.email}' : '未ログイン状態',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isAuthenticated
                                ? Colors.green.shade800
                                : Colors.blue.shade800,
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
                    print('🔄 HomePage: ユーザー名保存成功（シンプル）');
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

                // 5. シークレットモード切り替えボタン（認証済み時または開発環境で表示）
                if (isAuthenticated || true) ...[
                  // 開発環境では常に表示
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'プライバシー設定',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'シークレットモードをオンにすると、サインインが必要になります',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final accessControl =
                                  ref.read(accessControlServiceProvider);
                              await accessControl.toggleSecretMode();
                              // 状態を更新（SharedPreferencesから直接読み込み）
                              final newSecretMode =
                                  await accessControl.isSecretModeEnabled();
                              setState(() {
                                _isSecretMode = newSecretMode;
                              });
                            },
                            icon: Icon(
                              _isSecretMode
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            label: Text(
                              _isSecretMode
                                  ? 'シークレットモード: ON'
                                  : 'シークレットモード: OFF',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSecretMode
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                              foregroundColor: _isSecretMode
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 6. サインアウトボタン（認証済み時のみ表示）
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
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('キャンセル'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
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
                const Text(
                  'エラーが発生しました',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
