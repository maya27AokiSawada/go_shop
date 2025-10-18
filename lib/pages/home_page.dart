import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer;

// Providers
import '../providers/auth_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/user_name_provider.dart';
import '../providers/user_settings_provider.dart';
import '../providers/user_specific_hive_provider.dart';
import '../providers/device_settings_provider.dart';
import '../providers/hive_provider.dart' as hive_provider;
import '../providers/subscription_provider.dart';

// Services
import '../services/user_preferences_service.dart';
import '../services/authentication_service.dart';
import '../services/email_management_service.dart';
import '../services/firebase_diagnostics_service.dart';
import '../services/group_management_service.dart';
import '../services/password_reset_service.dart';

import '../services/user_name_initialization_service.dart';
import '../services/user_info_service.dart';

// Helpers
import '../helpers/auth_state_helper.dart';
import '../helpers/dev_utils_helper.dart';
import '../helpers/user_id_change_helper.dart';
import '../helpers/qr_code_helper.dart';
import '../helpers/ui_helper.dart';

// Utilities
import '../flavors.dart';

// Widgets
import '../widgets/user_data_migration_dialog.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/news_widget.dart';
import '../widgets/payment_reminder_widget.dart';
import '../widgets/qr_invitation_widgets.dart';

// Pages
import 'hybrid_sync_test_page.dart';
import 'help_page.dart';
import 'premium_page.dart';

final logger = Logger();

class IsFormVisible extends StateNotifier<bool> {
  IsFormVisible() : super(false);
  void showForm() => state = true;
  void hideForm() => state = false;
}
final isFormVisibleProvider = StateNotifierProvider<IsFormVisible, bool>((ref) => IsFormVisible());

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _userNameFormKey = GlobalKey<FormState>(); // ユーザー名編集用のFormKey
  bool showSignInForm = false;
  bool _isPasswordVisible = false; // パスワード表示状態
  bool _isPasswordResetLoading = false; // パスワードリセット中の状態
  bool _rememberEmail = false; // メールアドレスを保存するかどうか

  @override
  void initState() {
    super.initState();
    logger.i('🏠 HomePage: initState開始');
    
    // 初期化処理を非同期で実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.i('🏠 HomePage: PostFrameCallback実行');
      _initializePage();
    });
  }

  /// ページ初期化処理
  Future<void> _initializePage() async {
    // ユーザー名初期化
    await _initializeUserName();
    
    // 保存されたメールアドレスを読み込み
    await _loadSavedEmail();
  }

  /// 保存されたメールアドレスを読み込む
  Future<void> _loadSavedEmail() async {
    final emailService = ref.read(emailManagementServiceProvider);
    final result = await emailService.loadSavedEmail();
    
    if (result.email != null && mounted) {
      setState(() {
        emailController.text = result.email!;
        _rememberEmail = result.shouldRemember;
      });
    }
  }

  /// メールアドレスを保存または削除
  Future<void> _saveOrClearEmail() async {
    final emailService = ref.read(emailManagementServiceProvider);
    await emailService.saveOrClearEmail(
      email: emailController.text,
      shouldRemember: _rememberEmail,
    );
  }

  /// ユーザー名の初期化処理
  Future<void> _initializeUserName() async {
    final userNameService = ref.read(userNameInitializationServiceProvider);
    final userName = await userNameService.initializeUserName();
    
    if (userName != null && userName.isNotEmpty && mounted) {
      setState(() {
        userNameController.text = userName;
      });
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Firebase Userからemailを取得するヘルパーメソッド
  String? _getUserEmail(User? user) {
    if (user == null) return null;
    return user.email;
  }

  // 仮設定UID（開発・テスト用）かどうかを判定するメソッド
  bool _isTemporaryUid(String uid) {
    // MockAuthServiceが生成する仮設定UIDパターンを検出
    if (uid.startsWith('mock_')) {
      return true;
    }
    
    // ローカルテスト用の仮設定UIDパターンを検出
    if (uid.startsWith('local_') || uid.startsWith('temp_') || uid.startsWith('dev_')) {
      return true;
    }
    
    // 空文字列や明らかに無効なUIDも仮設定として扱う
    if (uid.isEmpty || uid.length < 10) {
      return true;
    }
    
    return false;
  }

  // UID変更をハンドリングするメソッド（簡素化版）
  Future<void> _handleUserIdChange(String newUserId, String userEmail) async {
    await UserIdChangeHelper.handleUserIdChange(
      ref: ref,
      context: context,
      newUserId: newUserId,
      userEmail: userEmail,
      mounted: mounted,
    );

  // ユーザーがログインしているかどうかをチェックするヘルパーメソッド
  bool _isUserLoggedIn(dynamic user) {
    return user != null;
  }

  // SharedPreferencesからユーザー名を同期的に取得するヘルパーメソッド
  Future<String?> _getCurrentUserName() async {
    return await UserPreferencesService.getUserName();
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
    final hiveInitialized = ref.watch(hiveInitializationStatusProvider);
    
    // Hive初期化を監視（バックグラウンドで自動実行）
    ref.watch(hiveUserInitializationProvider);
    
    // Windows版のみHive初期化待ちのローディング表示
    // Android/iOS版は常にデータを表示（アプリ再開時に未ログインでもHiveをそのまま使用）
    if (Platform.isWindows && !hiveInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('データベースを初期化中...'),
            ],
          ),
        ),
      );
    }
    
    // 認証状態が変わった時の処理（UIDベースでユーザー切り替えを判定）
    ref.listen(authStateProvider, (previous, next) {
      logger.i('🔎 認証状態変更を検知');
      next.whenData((user) async {
        final currentUserEmail = _getUserEmail(user);
        final currentUserId = user?.uid ?? '';
        final currentUserName = await _getCurrentUserName();
        
        logger.i('🔐 現在のユーザー: ${currentUserEmail ?? "null"}, UID: $currentUserId, ユーザー名: ${currentUserName ?? "null"}');
        
        if (currentUserId.isNotEmpty && !_isTemporaryUid(currentUserId)) {
          // 実際のFirebase UIDの場合のみUID変更をチェック
          logger.i('✅ 有効なFirebase UID - UID変更チェックを実行');
          await _handleUserIdChange(currentUserId, currentUserEmail ?? 'メール未設定');
        } else if (_isTemporaryUid(currentUserId)) {
          // 仮設定UIDの場合はログ出力のみ
          logger.i('🔄 仮設定UID検出 - UID変更チェックをスキップ: $currentUserId');
        } else {
          // サインアウト時は何もしない
          logger.i('� サインアウト状態 - 処理をスキップ');
        }
        
        // ユーザー名の復帰処理
        // TODO: メソッドが後で定義されるため一時的にコメントアウト
        // WidgetsBinding.instance.addPostFrameCallback((_) async {
        //   await _restoreUserName(currentUserId, currentUserEmail);
        // });
      });
    });
    
    return Scaffold(
    appBar: AppBar(
      title: const Text('Go Shopping'),
      actions: [
        // QRコード読み取りボタン（招待受け取り用）
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: 'QRコードで招待を受け取る',
          onPressed: () => QrCodeHelper.handleQrCodeScan(context, ref, () {
            setState(() {
              showSignInForm = true;
            });
          }),
        ),
        // シークレットモード設定ボタン
        Consumer(
          builder: (context, ref, child) {
            final isSecretMode = ref.watch(secretModeProvider);
            return IconButton(
              icon: Icon(
                isSecretMode ? Icons.visibility_off : Icons.visibility,
                color: isSecretMode ? Colors.red : null,
              ),
              tooltip: isSecretMode ? 'シークレットモード ON' : 'シークレットモード OFF',
              onPressed: () async {
                // シークレットモードOFF→ONの場合は認証チェック
                if (isSecretMode) {
                  // ON→OFFにする場合は認証必須
                  final authState = ref.read(authStateProvider);
                  final isAuthenticated = authState.when(
                    data: (user) => user != null,
                    loading: () => false,
                    error: (_, __) => false,
                  );
                  
                  if (!isAuthenticated) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('シークレットモードを無効にするにはログインが必要です'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }
                }
                
                try {
                  await ref.read(secretModeProvider.notifier).toggleSecretMode();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isSecretMode 
                            ? 'シークレットモードを有効にしました。ログインが必要になります。'
                            : 'シークレットモードを無効にしました。',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('設定の変更に失敗しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            );
          },
        ),
        // デバッグ用：Hiveデータクリアボタン（開発環境のみ）
        DevUtilsHelper.buildHiveDataClearButton(
          context: context,
          ref: ref,
          onComplete: () {
            setState(() {
              userNameController.clear();
              emailController.clear();
              passwordController.clear();
              showSignInForm = false;
            });
          },
        ),
          
          // デバッグ用：メール送信テストボタン（onenessブランチでは無効）
          // if (F.appFlavor == Flavor.dev)
          //   IconButton(
          //     icon: const Icon(Icons.email, color: Colors.blue),
          //     tooltip: 'メール送信テスト（デバッグ用）',
          //     onPressed: () {
          //       Navigator.of(context).push(
          //         MaterialPageRoute(
          //           builder: context) => const DebugEmailTestPage(),
          //         ),
          //       );
          //     },
          //   ),
          
          // テストページボタン（ハイブリッド同期テスト用）
          if (F.appFlavor == Flavor.prod) // PRODモードでハイブリッド同期テスト可能
            IconButton(
              icon: const Icon(Icons.science),
              tooltip: 'ハイブリッド同期テスト',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HybridSyncTestPage(),
                  ),
                );
              },
            ),
            
          // 三点メニュー
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              switch (value) {
                case 'premium':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PremiumPage(),
                    ),
                  );
                  break;
                case 'help':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HelpPage(),
                    ),
                  );
                  break;
                case 'about':
                  // TODO: メソッド定義順の問題で一時コメントアウト
                  // _showAboutDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'premium',
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('プレミアム'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('ヘルプ'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('アプリについて'),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
    body: Center(
      child: Builder(
        builder: (context) {
          // Replace with your actual logic to check authentication state
          return authState.when(
            data: (user) {
              if (!_isUserLoggedIn(user)) { // 未ログイン状態ならサインイン・サインアップボタンを表示
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // � 未ログイン時もニュース表示
                        const NewsWidget(),
                        // 未ログイン状態では常にユーザー名入力欄を表示
                        TextFormField(
                          controller: userNameController,
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
                        
                        // サインインボタン（フォームが表示されていない時のみ表示）
                        if (!showSignInForm) ...[
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showSignInForm = true;
                              });
                            },
                            child: const Text('サインイン'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // メールアドレスとパスワード入力欄（サインインボタンが押された後に表示）
                        if (showSignInForm) ...[
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'メールアドレス',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'メールアドレスを入力してください';
                              }
                              if (!value.contains('@')) {
                                return '有効なメールアドレスを入力してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'パスワード',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                tooltip: _isPasswordVisible ? 'パスワードを隠す' : 'パスワードを表示',
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'パスワードを入力してください';
                              }
                              if (value.length < 6) {
                                return 'パスワードは6文字以上で入力してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          
                          // メールアドレス保存チェックボックス
                          CheckboxListTile(
                            value: _rememberEmail,
                            onChanged: (value) {
                              setState(() {
                                _rememberEmail = value ?? false;
                              });
                            },
                            title: const Text('メールアドレスを保存する'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          const SizedBox(height: 16),
                          
                          // サインイン実行ボタン
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await _performSignIn();
                              }
                            },
                            child: const Text('ログイン'),
                          ),
                          const SizedBox(height: 8),
                          
                          // パスワードリセットリンク
                          TextButton(
                            onPressed: _isPasswordResetLoading ? null : () async {
                              await _sendPasswordResetEmail();
                            },
                            child: _isPasswordResetLoading 
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text('送信中...'),
                                    ],
                                  )
                                : const Text('パスワードを忘れた場合'),
                          ),
                          const SizedBox(height: 8),
                          
                          // キャンセルボタン
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showSignInForm = false;
                              });
                            },
                            child: const Text('キャンセル'),
                          ),
                        ],
                        
                        // 従来の保存ボタン
                        if (!showSignInForm) ...[
                          ElevatedButton(
                            onPressed: () async => await userInfoSave(),
                            child: const Text('ユーザー名のみ保存')
                          ),
                          
                          // 🔥 Firebase接続診断ボタン（DEV環境でのみ表示）
                          if (F.appFlavor == Flavor.dev) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const Text('🔧 Firebase診断', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              // TODO: 一時無効化
                              onPressed: null, // () async => await _runFirebaseDiagnostics(),
                              icon: const Icon(Icons.medical_services),
                              label: const Text('Firebase完全診断'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async => await _firebaseConnectionTest(),
                              icon: const Icon(Icons.wifi_tethering),
                              label: const Text('Firebase接続テスト'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              } else {
                // ログイン済みUI
                return FutureBuilder<String?>(
                  future: _getCurrentUserName(),
                  builder: (context, snapshot) {
                    final savedUserName = snapshot.data;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ようこそ、${savedUserName ?? _getUserEmail(user) ?? "ユーザー"}さん',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      
                      // � Firestoreニュース表示（一時的にコメントアウト）
                      // const NewsWidget(),
                      
                      // 💳 支払いリマインダー（認証済みユーザー向け）
                      const PaymentReminderWidget(),
                      
                      // 📱 ホーム画面広告バナー
                      const HomeAdBannerWidget(),
                      const SizedBox(height: 20),
                      
                      // ユーザー名編集セクション
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _userNameFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ユーザー名設定',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                        onPressed: _saveUserName,
                                        icon: const Icon(Icons.save),
                                        label: const Text('ユーザー名を保存'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // デバッグ用: 現在の状態確認ボタン
                                ElevatedButton(
                                  onPressed: () async {
                                    logger.i('🔍 デバッグ: 現在の状態確認');
                                    final currentUserName = await _getCurrentUserName();
                                    final userSettings = await ref.read(userSettingsProvider.future);
                                    logger.i('🔍 SharedPreferences userName: $currentUserName');
                                    logger.i('🔍 userSettings.userName: ${userSettings.userName}');
                                    logger.i('🔍 userNameController.text: ${userNameController.text}');
                                    
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Provider: $currentUserName, Settings: ${userSettings.userName}, Controller: ${userNameController.text}'
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('状態確認'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 🧪 メール送信テストセクション
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🔗 QRコード招待システム',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'QRコードで簡単にグループ招待・参加',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              
                              // QRコード招待ボタン（サンプル用）
                              QRInviteButton(
                                shoppingListId: 'sample_list_id',
                                purchaseGroupId: 'sample_group_id',
                                groupName: 'サンプルグループ',
                                groupOwnerUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                                customMessage: 'Go Shopグループへようこそ！',
                              ),
                              const SizedBox(height: 12),
                              
                              // QRコード読み取りボタン
                              const QRScanButton(),
                              
                              // メール送信テスト（コメントアウト）
                              /*
                              const Text(
                                '🧪 メール送信テスト',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Firebase Extensions Trigger Email の動作確認用',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              const EmailTestButton(),
                              const SizedBox(height: 12),
                              const EmailDiagnosticsWidget(),
                              */
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      ElevatedButton(
                      onPressed: () async {
                        try {
                          // 1. Windows版のみユーザー固有Hiveサービスをデフォルトに切り替え
                          if (Platform.isWindows) {
                            final hiveService = ref.read(userSpecificHiveProvider);
                            await hiveService.initializeForDefaultUser();
                            logger.i('🚪 [Windows] Switched to default Hive folder');
                          }
                          // Android/iOS版: Hiveフォルダはそのまま維持
                          
                          // 2. Firebase認証のサインアウト
                          await ref.read(authProvider).signOut();
                          
                          // 3. 全ての設定をクリア
                          await ref.read(userSettingsProvider.notifier).clearAllSettings();
                          
                          // 5. グループデータとショッピングリストも無効化
                          ref.invalidate(selectedGroupProvider); ref.invalidate(allGroupsProvider);
                          ref.invalidate(shoppingListProvider);
                          ref.invalidate(userSettingsProvider);
                          
                          developer.log('🚪 完全サインアウト完了 - 全状態がクリアされました');
                        } catch (e) {
                          developer.log('❌ サインアウトエラー: $e');
                        }
                      },
                      child: const Text('ログアウト'),
                    ),
                    
                    // 🔥 ログイン後でもFirebase診断ボタンを表示（DEV環境でのみ）
                    if (F.appFlavor == Flavor.dev) ...[
                      const SizedBox(height: 30),
                      const Divider(),
                      const Text('🔧 Firebase診断', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async => await _runFirebaseDiagnostics(),
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Firebase完全診断'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async => await _firebaseConnectionTest(),
                        icon: const Icon(Icons.wifi_tethering),
                        label: const Text('Firebase接続テスト'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'ログイン状態: ${_getUserEmail(user) ?? "不明"}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                        ],
                      ),
                    );
                  },
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

  // デフォルトグループからユーザー名を読み込む
  /// デフォルトグループからユーザー名を読み込む
  Future<void> _loadUserNameFromDefaultGroup() async {
    final groupService = ref.read(groupManagementServiceProvider);
    final userName = await groupService.loadUserNameFromDefaultGroup();
    
    if (userName != null && userName.isNotEmpty && mounted) {
      setState(() {
        userNameController.text = userName;
      });
    }
  }

  // ユーザー名復帰処理（SharedPreferences → Firestore → グループから復帰）
  Future<void> _restoreUserName(String userId, String? userEmail) async {
    logger.i('🔄 _restoreUserName開始: UID=$userId, Email=$userEmail');
    
    try {
      // まずSharedPreferencesから復帰を試行
      final prefsName = await ref.read(userNameNotifierProvider.notifier).restoreUserNameFromPreferences();
      logger.i('📊 SharedPreferencesからのユーザー名: $prefsName');
      
      if (prefsName != null && prefsName.isNotEmpty) {
        // SharedPreferencesにユーザー名がある場合、UIに反映
        logger.i('✅ SharedPreferencesからユーザー名復帰: $prefsName');
        if (mounted) {
          setState(() {
            userNameController.text = prefsName;
          });
        }
        return;
      }
      
      // SharedPreferencesにない場合、Firestoreから復帰を試行（サインイン時のみ）
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        logger.i('🔍 SharedPreferencesにない - Firestoreから復帰を試行');
        final firestoreName = await ref.read(userNameNotifierProvider.notifier).restoreUserNameFromFirestore();
        if (firestoreName != null && firestoreName.isNotEmpty) {
          logger.i('✅ Firestoreからユーザー名復帰: $firestoreName');
          if (mounted) {
            setState(() {
              userNameController.text = firestoreName;
            });
          }
          return;
        }
      }
      
      // 両方にもない場合、グループから復帰
      logger.i('🔍 どちらにもない - グループから復帰を試行');
      _loadUserNameFromDefaultGroup(); // void戻り値なのでawaitなし
      
    } catch (e) {
      logger.e('❌ ユーザー名復帰エラー: $e');
      // エラー時は空のユーザー名でUI更新
      if (mounted) {
        setState(() {
          userNameController.text = '';
        });
      }
    }
    
    logger.i('🏁 _restoreUserName終了');
  }

  // 全グループで同じUID/メールアドレスのメンバー名を更新するメソッド
  /// 全グループのユーザー名を更新
  /// ユーザー名を保存
  Future<void> _saveUserName() async {
    if (!(_userNameFormKey.currentState?.validate() ?? false)) {
      UiHelper.showWarningMessage(context, 'ユーザー名を正しく入力してください');
      return;
    }

    try {
      final newUserName = userNameController.text.trim();
      
      if (newUserName.isEmpty) return;
      
      logger.i('💾 ユーザー名保存開始: $newUserName');
      
      // 1. UserNameNotifierを使用してSharedPreferences + Firestoreに保存
      await ref.read(userNameNotifierProvider.notifier).setUserName(newUserName);
      logger.i('✅ SharedPreferences + Firestoreに保存完了');
      
      // 2. デフォルトグループの情報も更新
      await userInfoSave();
      logger.i('✅ デフォルトグループ更新完了');
      
      logger.i('✅ ユーザー名を保存しました: $newUserName');
      
      if (mounted) {
        UiHelper.showSuccessMessage(context, 'ユーザー名「$newUserName」を保存しました');
      }
    } catch (e) {
      logger.e('❌ ユーザー名保存エラー: $e');
      if (mounted) {
        UiHelper.showErrorMessage(context, 'ユーザー名の保存に失敗しました: $e');
      }
    }
  }

  // デフォルトグループにユーザー名を保存
  // サインイン処理を実行するメソッド
  /// サインイン処理
  Future<void> _performSignIn() async {
    if (!mounted) return;
    
    final email = emailController.text.trim();
    final password = passwordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスとパスワードを入力してください');
      return;
    }

    try {
      logger.i('🔧 サインイン開始: $email');
      
      final userCredential = await AuthenticationService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential == null) {
        if (mounted) {
          UiHelper.showErrorMessage(context, 'ログインに失敗しました');
        }
        return;
      }
      
      // メールアドレスの保存/削除を実行
      await _saveOrClearEmail();
      
      if (mounted) {
        UiHelper.showSuccessMessage(context, 'ログインしました');
        
        // サインイン成功後の処理
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await userInfoSave();
          ref.invalidate(selectedGroupProvider);
          ref.invalidate(allGroupsProvider);
          await _loadUserNameFromDefaultGroup();
          // 保存された招待情報があれば自動処理
          await QrCodeHelper.processPendingInvitation(context, ref, () async {
            await _loadUserNameFromDefaultGroup();
          });
        });
        
        // フォームをリセット
        setState(() {
          showSignInForm = false;
        });
        emailController.clear();
        passwordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      logger.e('🚨 Firebase認証エラー: ${e.code} - ${e.message}');
      if (mounted) {
        _handleFirebaseAuthError(e, email, password);
      }
    } catch (e, stackTrace) {
      logger.e('🚨 ログイン失敗: $e\n$stackTrace');
      if (mounted) {
        UiHelper.showErrorMessage(context, 'ログインに失敗しました: $e');
      }
    }
  }

  /// Firebase認証エラーのハンドリング
  Future<void> _handleFirebaseAuthError(FirebaseAuthException e, String email, String password) async {
    String errorMessage;
    bool offerSignUp = false;
    
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'このメールアドレスは登録されていません';
        offerSignUp = true;
        break;
      case 'invalid-credential':
        errorMessage = 'ログイン情報が正しくありません。アカウントが存在しない可能性があります';
        offerSignUp = true;
        break;
      case 'wrong-password':
        errorMessage = 'パスワードが間違っています';
        break;
      case 'invalid-email':
        errorMessage = 'メールアドレスの形式が正しくありません';
        break;
      case 'too-many-requests':
        errorMessage = 'ログイン試行回数が多すぎます。しばらく待ってから再試行してください';
        break;
      default:
        errorMessage = 'ログインに失敗しました';
        offerSignUp = true;
    }
    
    if (offerSignUp) {
      await _offerSignUp(email);
    } else {
      UiHelper.showErrorMessage(context, errorMessage, duration: const Duration(seconds: 4));
    }
  }

  /// サインアップを提案
  Future<void> _offerSignUp(String email) async {
    // ユーザー名チェック
    final currentUserName = await _getCurrentUserName();
    final inputUserName = userNameController.text.trim();
    
    if ((currentUserName == null || currentUserName.isEmpty) && inputUserName.isEmpty) {
      // ユーザー名が未設定の場合
      if (mounted) {
        UiHelper.showInfoDialog(
          context,
          title: 'ユーザー名が必要です',
          message: 'サインアップするには、まずユーザー名を設定してください。\n\n画面上部のユーザー名入力欄にお名前を入力してから再度お試しください。',
        );
        setState(() {
          showSignInForm = false;
        });
      }
      return;
    }
    
    // ユーザー名が設定されている場合、サインアップを提案
    final shouldSignUp = await UiHelper.showConfirmDialog(
      context,
      title: 'アカウントが見つかりません',
      message: 'メールアドレス "$email" は登録されていません。\n新しいアカウントを作成しますか？',
      confirmText: 'アカウント作成',
    );

    if (shouldSignUp && mounted) {
      await _performSignUp();
    }
  }

  /// サインアップ処理
  Future<void> _performSignUp() async {
    if (!mounted) return;
    
    final email = emailController.text.trim();
    final password = passwordController.text;
    final userName = userNameController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      UiHelper.showWarningMessage(context, 'メールアドレスとパスワードを入力してください');
      return;
    }
    
    if (userName.isEmpty) {
      UiHelper.showWarningMessage(context, 'ユーザー名を入力してください');
      return;
    }

    try {
      logger.i('🔧 サインアップ開始: $email');
      
      final userCredential = await AuthenticationService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        userName: userName,
      );
      
      if (userCredential == null) {
        if (mounted) {
          UiHelper.showErrorMessage(context, 'アカウント作成に失敗しました');
        }
        return;
      }
      
      if (mounted) {
        UiHelper.showSuccessMessage(context, 'アカウントを作成してログインしました');
        
        // サインアップ成功後の処理
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await userInfoSave();
          
          // 🎉 サインアップ時に1か月間の無料期間を開始
          try {
            await ref.read(subscriptionProvider.notifier).startSignupFreePeriod();
            logger.i('🎉 サインアップ特典: 1か月間の無料期間を開始しました');
            
            if (mounted) {
              UiHelper.showSuccessMessage(
                context,
                '🎉 サインアップありがとうございます！1か月間広告なしでご利用いただけます',
                duration: const Duration(seconds: 4),
              );
            }
          } catch (e) {
            logger.e('❌ 無料期間開始エラー: $e');
          }
          
          ref.invalidate(selectedGroupProvider);
          ref.invalidate(allGroupsProvider);
          await _loadUserNameFromDefaultGroup();
          // 保存された招待情報があれば自動処理
          await QrCodeHelper.processPendingInvitation(context, ref, () async {
            await _loadUserNameFromDefaultGroup();
          });
        });
        
        // フォームをリセット
        setState(() {
          showSignInForm = false;
        });
        emailController.clear();
        passwordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      logger.e('🚨 Firebase認証エラー: ${e.code} - ${e.message}');
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'このメールアドレスは既に使用されています';
            break;
          case 'invalid-email':
            errorMessage = 'メールアドレスの形式が正しくありません';
            break;
          case 'weak-password':
            errorMessage = 'パスワードが弱すぎます。より強力なパスワードを入力してください';
            break;
          default:
            errorMessage = 'アカウント作成に失敗しました: ${e.message}';
        }
        UiHelper.showErrorMessage(context, errorMessage, duration: const Duration(seconds: 4));
      }
    } catch (e, stackTrace) {
      logger.e('🚨 サインアップ失敗: $e\n$stackTrace');
      if (mounted) {
        UiHelper.showErrorMessage(context, 'アカウント作成に失敗しました: $e');
      }
    }
  }

  /// ユーザー情報を保存(デフォルトグループ、ShoppingList、UserSettings)
  Future<void> userInfoSave() async {
    final userInfoService = ref.read(userInfoServiceProvider);
    final result = await userInfoService.saveUserInfo(
      userNameFromForm: userNameController.text,
      emailFromForm: emailController.text,
    );
    
    if (mounted) {
      if (result.success) {
        UiHelper.showSuccessMessage(context, result.message);
      } else {
        UiHelper.showWarningMessage(context, result.message);
      }
    }
  }

  /// パスワードリセットメール送信
  /// パスワードリセットメールを送信
  Future<void> _sendPasswordResetEmail() async {
    final email = emailController.text.trim();
    
    setState(() {
      _isPasswordResetLoading = true;
    });

    try {
      final passwordResetService = PasswordResetService();
      final result = await passwordResetService.sendPasswordResetEmail(email);
      
      if (mounted) {
        switch (result.severity) {
          case MessageSeverity.success:
            UiHelper.showSuccessMessage(context, result.message, duration: const Duration(seconds: 4));
            break;
          case MessageSeverity.warning:
            UiHelper.showWarningMessage(context, result.message);
            break;
          case MessageSeverity.error:
            UiHelper.showErrorMessage(context, result.message, duration: const Duration(seconds: 4));
            break;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPasswordResetLoading = false;
        });
      }
    }
  }

  /// 🔥 Firebase包括診断
  /// Firebase完全診断を実行
  Future<void> _runFirebaseDiagnostics() async {
    UiHelper.showInfoSnackBar(
      context,
      DiagnosticsResult.startMessage,
      backgroundColor: Colors.orange,
    );
    
    final result = await FirebaseDiagnosticsService.runFullDiagnostics();
    
    if (mounted) {
      UiHelper.showInfoSnackBar(
        context,
        result.userMessage,
        backgroundColor: result.isHealthy ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Firebase接続テストを実行
  Future<void> _firebaseConnectionTest() async {
    UiHelper.showInfoSnackBar(
      context,
      ConnectionTestResult.startMessage,
      backgroundColor: Colors.blue,
    );
    
    final result = await FirebaseDiagnosticsService.runConnectionTest();
    
    if (mounted) {
      UiHelper.showInfoSnackBar(
        context,
        result.detailMessage,
        backgroundColor: result.success ? Colors.green : Colors.red,
      );
    }
  }

  // アプリについてダイアログを表示
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Go Shop',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.shopping_cart,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('家族やグループで買い物リストを共有できるアプリです。'),
        const SizedBox(height: 16),
        const Text('主な機能:'),
        const Text('• グループでの買い物リスト共有'),
        const Text('• リアルタイム同期'),
        const Text('• オフライン対応'),
        const Text('• メンバー管理'),
        const SizedBox(height: 16),
        const Text('開発者: 金ヶ江 真也 ファーティマ (Maya Fatima Kanagae)'),
        const Text('お問い合わせ: fatima.sumomo@gmail.com'),
        const SizedBox(height: 16),
        const Text('© 2024 Go Shop. All rights reserved.'),
      ],
    );
  }
}