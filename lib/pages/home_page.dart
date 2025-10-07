import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer;
import '../providers/auth_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/user_name_provider.dart';
import '../helper/mock_auth_service.dart';
import '../providers/user_settings_provider.dart';
import '../providers/user_specific_hive_provider.dart';
import '../providers/device_settings_provider.dart';
import '../providers/hive_provider.dart' as hive_provider;
import '../datastore/user_settings_repository.dart';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../flavors.dart';
import '../helper/firebase_diagnostics.dart';
import '../widgets/user_data_migration_dialog.dart';
import 'hybrid_sync_test_page.dart';
import 'help_page.dart';

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

  @override
  void initState() {
    super.initState();
    logger.i('🏠 HomePage: initState開始');
    // デフォルトグループからユーザー名を読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.i('🏠 HomePage: PostFrameCallback実行');
      _initializeUserName();
    });
  }

  // ユーザー名の初期化処理
  void _initializeUserName() async {
    logger.i('🔧 _initializeUserName開始');
    
    // 少し待ってからプロバイダーの値を取得（Riverpodの初期化完了を待つ）
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 設定から現在のユーザー名を確認
    final currentUserName = ref.read(userNameProvider);
    logger.i('👤 現在のユーザー名（設定から）: $currentUserName');
    
    if (currentUserName != null && currentUserName.isNotEmpty) {
      if (mounted) {
        userNameController.text = currentUserName;
        logger.i('✅ ユーザー名が設定から復元されました: $currentUserName');
      }
    } else {
      logger.i('⚠️ 設定にユーザー名がないため、グループから読み込み');
      _loadUserNameFromDefaultGroup();
      
      // グループからロード後、少し待ってから再度チェック
      await Future.delayed(const Duration(milliseconds: 200));
      final updatedUserName = ref.read(userNameProvider);
      if (updatedUserName != null && updatedUserName.isNotEmpty && mounted) {
        userNameController.text = updatedUserName;
        logger.i('✅ ユーザー名がグループから復元されました: $updatedUserName');
      }
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Firebase UserとMockUserの両方からemailを取得するヘルパーメソッド
  String? _getUserEmail(dynamic user) {
    if (user == null) return null;
    // Firebase UserまたはMockUserの場合
    return user.email;
  }

  // UID変更をハンドリングするメソッド
  Future<void> _handleUserIdChange(String newUserId, String userEmail) async {
    try {
      final userSettings = ref.read(userSettingsProvider.notifier);
      final hiveService = ref.read(userSpecificHiveProvider);
      final hasChanged = await userSettings.hasUserIdChanged(newUserId);
      final isWindows = Platform.isWindows;
      
      if (hasChanged) {
        // UIDが変更された場合、ユーザーに選択を求める
        if (mounted) {
          final shouldKeepData = await UserDataMigrationDialog.show(
            context,
            previousUser: '前回のユーザー',
            newUser: userEmail,
          );
          
          if (shouldKeepData == false) {
            // データを消去する場合
            logger.i('🗑️ ユーザーがデータ消去を選択');
            
            if (isWindows) {
              // Windows版: ユーザー固有のHiveデータベースに切り替え
              await hiveService.initializeForUser(newUserId);
              // TODO: clearCurrentUserData メソッドを実装
            } else {
              // Android/iOS版: 現在のHiveデータをクリア（フォルダは変更しない）
              // TODO: clearCurrentUserData メソッドを実装
            }
            
            // 安全にプロバイダーを無効化（遅延実行で順次）
            await Future.delayed(const Duration(milliseconds: 200));
            ref.invalidate(userSettingsProvider);
            await Future.delayed(const Duration(milliseconds: 200));
            ref.invalidate(shoppingListProvider);
            await Future.delayed(const Duration(milliseconds: 200));
            ref.invalidate(purchaseGroupProvider);
            
          } else {
            // データを引き継ぐ場合
            logger.i('🔄 ユーザーがデータ引き継ぎを選択');
            
            if (isWindows) {
              // Windows版: ユーザー固有フォルダに切り替え
              await hiveService.initializeForUser(newUserId);
              // TODO: migrateDataFromDefault メソッドを実装
            }
            // Android/iOS版: 何もしない（既存データをそのまま使用）
            
            // 安全にプロバイダーを無効化（遅延実行で順次）
            await Future.delayed(const Duration(milliseconds: 200));
            ref.invalidate(userSettingsProvider);
            await Future.delayed(const Duration(milliseconds: 200));
            ref.invalidate(shoppingListProvider);
            await Future.delayed(const Duration(milliseconds: 200));
            ref.invalidate(purchaseGroupProvider);
          }
        }
      } else {
        // UIDが変更されていない場合
        if (isWindows && hiveService.currentUserId != newUserId) {
          // Windows版のみ: 適切なユーザーデータベースに切り替え
          logger.i('🔄 [Windows] Switching to user-specific Hive database: $newUserId');
          await hiveService.initializeForUser(newUserId);
          
          // プロバイダーの無効化を大幅に遅延させて競合を回避
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(userSettingsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(shoppingListProvider);
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(purchaseGroupProvider);
        }
        // Android/iOS版: 何もしない（既存のHiveをそのまま使用）
      }
      
      // 新しいUIDを保存（Hive初期化完了後に実行）
      await Future.delayed(const Duration(milliseconds: 500));
      await userSettings.updateUserId(newUserId);
      
    } catch (e) {
      logger.i('❌ UID変更処理エラー: $e');
    }
  }

  // ユーザーがログインしているかどうかをチェックするヘルパーメソッド
  bool _isUserLoggedIn(dynamic user) {
    return user != null;
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
    final currentUserName = ref.watch(userNameProvider);
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
        
        logger.i('🔐 現在のユーザー: ${currentUserEmail ?? "null"}, UID: $currentUserId, ユーザー名: $currentUserName');
        
        if (currentUserId.isNotEmpty) {
          // サインイン済みの場合、UID変更をチェック
          await _handleUserIdChange(currentUserId, currentUserEmail ?? 'メール未設定');
        } else {
          // サインアウト時は何もしない
          logger.i('� サインアウト状態 - 処理をスキップ');
        }
        
        // 初回サインイン時またはユーザー名がない場合のみグループから読み込み
        if ((currentUserName == null || currentUserName.isEmpty) && currentUserId.isNotEmpty) {
          logger.i('🔄 ユーザー名がないのでグループから読み込みを実行');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadUserNameFromDefaultGroup();
          });
        }
      });
    });
    
    return Scaffold(
    appBar: AppBar(
      title: const Text('Go Shopping'),
      actions: [
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
        if (F.appFlavor == Flavor.dev)
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Hiveデータクリア（デバッグ用）',
            onPressed: () async {
              final shouldClear = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hiveデータクリア'),
                  content: const Text('全てのローカルデータが削除されます。続行しますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('削除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (shouldClear == true) {
                try {
                  // 全ての設定をクリア
                  await ref.read(userSettingsProvider.notifier).clearAllSettings();
                  
                  // Hiveボックスをクリア
                  final purchaseGroupBox = ref.read(hive_provider.purchaseGroupBoxProvider);
                  final shoppingListBox = ref.read(hive_provider.shoppingListBoxProvider);
                  final userSettingsBox = ref.read(hive_provider.userSettingsBoxProvider);
                  
                  await purchaseGroupBox.clear();
                  await shoppingListBox.clear();
                  await userSettingsBox.clear();
                  
                  // 認証状態をクリア
                  ref.read(mockAuthStateProvider.notifier).state = null;
                  
                  // プロバイダーを無効化
                  ref.invalidate(purchaseGroupProvider);
                  ref.invalidate(shoppingListProvider);
                  ref.invalidate(userSettingsProvider);
                  
                  logger.i('🗑️ 全てのHiveデータをクリアしました');
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hiveデータをクリアしました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  
                  // ページをリフレッシュ
                  setState(() {
                    userNameController.clear();
                    emailController.clear();
                    passwordController.clear();
                    showSignInForm = false;
                  });
                  
                } catch (e) {
                  logger.e('🗑️ Hiveデータクリアエラー: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('データクリアに失敗しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
          
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
                case 'help':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HelpPage(),
                    ),
                  );
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
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
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 未ログイン状態では常にユーザー名入力欄を表示
                        Consumer(
                          builder: (context, ref, child) {
                            final currentUserName = ref.watch(userNameProvider);
                            
                            // ユーザー名プロバイダーの値が変更された時にテキストフィールドを更新
                            if (currentUserName != null && 
                                currentUserName.isNotEmpty && 
                                userNameController.text != currentUserName) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  userNameController.text = currentUserName;
                                }
                              });
                            }
                            
                            return TextFormField(
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
                            );
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
                            decoration: const InputDecoration(
                              labelText: 'パスワード',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
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
                          
                          // 🔥 Firebase接続診断ボタン（本番環境でも表示）
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text('🔧 Firebase診断', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
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
                        ],
                      ],
                    ),
                  ),
                );
              } else {
                // ログイン済みUI
                final savedUserName = ref.watch(userNameProvider);
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ようこそ、${savedUserName ?? _getUserEmail(user) ?? "ユーザー"}さん',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      
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
                                Consumer(
                                  builder: (context, ref, child) {
                                    // ユーザー名プロバイダーを監視してテキストフィールドを更新
                                    final currentUserName = ref.watch(userNameProvider);
                                    
                                    // テキストフィールドが空または異なる値の場合のみ更新
                                    if (currentUserName != null && 
                                        currentUserName.isNotEmpty && 
                                        userNameController.text != currentUserName) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        userNameController.text = currentUserName;
                                      });
                                    }
                                    
                                    return TextFormField(
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
                                    );
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
                                    final currentUserName = ref.read(userNameProvider);
                                    final userSettings = await ref.read(userSettingsProvider.future);
                                    logger.i('🔍 userNameProvider: $currentUserName');
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
                          
                          // 3. Mock環境では状態を手動でクリア
                          if (F.appFlavor == Flavor.dev) {
                            ref.read(mockAuthStateProvider.notifier).state = null;
                          }
                          
                          // 4. 全ての設定をクリア
                          await ref.read(userSettingsProvider.notifier).clearAllSettings();
                          
                          // 5. グループデータとショッピングリストも無効化
                          ref.invalidate(purchaseGroupProvider);
                          ref.invalidate(shoppingListProvider);
                          ref.invalidate(userSettingsProvider);
                          
                          developer.log('🚪 完全サインアウト完了 - 全状態がクリアされました');
                        } catch (e) {
                          developer.log('❌ サインアウトエラー: $e');
                        }
                      },
                      child: const Text('ログアウト'),
                    ),
                    
                    // 🔥 ログイン後でもFirebase診断ボタンを表示
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
                    Text(
                      'ログイン状態: ${_getUserEmail(user) ?? "不明"}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
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

  // デフォルトグループからユーザー名を読み込む
  void _loadUserNameFromDefaultGroup() async {
    logger.i('🔍 _loadUserNameFromDefaultGroup 開始');
    try {
      final purchaseGroupAsync = ref.read(purchaseGroupProvider);
      final authState = ref.read(authStateProvider);
      final currentUserName = ref.read(userNameProvider);
      
      logger.i('📊 現在のuserNameProviderの値: $currentUserName');
      
      await Future.wait([
        purchaseGroupAsync.when(
          data: (group) async {
            logger.i('📋 グループデータ取得成功: ${group.groupName}');
            logger.i('👥 メンバー数: ${group.members?.length ?? 0}');
            
            if (group.members != null) {
              for (var i = 0; i < group.members!.length; i++) {
                final member = group.members![i];
                logger.i('👤 メンバー$i: ${member.name} (${member.role}) - ${member.contact}');
              }
            }
            
            await authState.when(
              data: (user) async {
                logger.i('🔐 認証ユーザー: ${user?.email ?? "null"}');
                
                // 認証状態に関係なく、leaderのユーザー名を取得
                if (group.members != null && group.members!.isNotEmpty) {
                  // ownerを優先して探す
                  var currentMember = group.members!.firstWhere(
                    (member) => member.role == PurchaseGroupRole.owner,
                    orElse: () {
                      logger.i('⚠️ ownerが見つからないので最初のメンバーを使用');
                      return group.members!.first;
                    },
                  );
                  
                  logger.i('🏆 選択されたメンバー: ${currentMember.name} (${currentMember.role})');
                  
                  // ログイン済みの場合のみメールアドレスでマッチするメンバーを再検索
                  final userEmail = _getUserEmail(user);
                  if (_isUserLoggedIn(user) && currentMember.contact != userEmail && userEmail != null) {
                    logger.i('📬 メールアドレスでメンバーを再検索: $userEmail');
                    final emailMatchMember = group.members!.firstWhere(
                      (member) => member.contact == userEmail,
                      orElse: () {
                        logger.i('📬 メールアドレスマッチなし、leaderを使用');
                        return currentMember;
                      },
                    );
                    if (emailMatchMember.name.isNotEmpty) {
                      logger.i('📬 メールマッチメンバーを使用: ${emailMatchMember.name}');
                      currentMember = emailMatchMember;
                    }
                  }
                  
                  if (currentMember.name.isNotEmpty) {
                    logger.i('✅ ユーザー名をプロバイダーに設定: ${currentMember.name}');
                    await ref.read(userNameNotifierProvider.notifier).setUserName(currentMember.name);
                    if (mounted) {
                      setState(() {
                        userNameController.text = currentMember.name;
                      });
                      logger.i('✅ UIを更新しました');
                    } else {
                      logger.i('⚠️ ウィジェットがmountedではないためUI更新をスキップ');
                    }
                  } else {
                    logger.i('⚠️ メンバー名が空です');
                  }
                } else {
                  logger.i('⚠️ メンバーがいません');
                }
              },
              loading: () async {
                logger.i('🔄 認証状態ロード中...');
              },
              error: (err, stack) async {
                logger.i('❌ 認証エラー: $err');
              },
            );
          },
          loading: () async {
            logger.i('🔄 グループデータロード中...');
          },
          error: (err, stack) async {
            logger.i('❌ グループエラー: $err');
          },
        ),
      ]);
    } catch (e) {
      logger.i('❌ ユーザー名の読み込みに失敗: $e');
    }
    logger.i('🏁 _loadUserNameFromDefaultGroup 終了');
  }

  // 全グループで同じUID/メールアドレスのメンバー名を更新するメソッド
  Future<void> _updateUserNameInAllGroups(String newUserName, String userEmail) async {
    try {
      logger.i('🌍 _updateUserNameInAllGroups開始: 名前="$newUserName", メール="$userEmail"');
      
      // 現在のログインユーザーのUIDを取得
      final authState = ref.read(authStateProvider);
      final currentUserId = authState.when(
        data: (user) => user?.uid ?? '',
        loading: () => '',
        error: (_, __) => '',
      );
      logger.i('🔐 現在のユーザーID: $currentUserId');
      
      // 全グループを取得
      final repository = ref.read(purchaseGroupRepositoryProvider);
      final allGroups = await repository.getAllGroups();
      logger.i('🌍 全グループ取得完了: ${allGroups.length}個のグループ');
      
      for (final group in allGroups) {
        logger.i('🔍 グループ "${group.groupName}" (ID: ${group.groupId}) をチェック中...');
        
        bool groupUpdated = false;
        final updatedMembers = <PurchaseGroupMember>[];
        
        // 各メンバーをチェック
        for (final member in group.members ?? []) {
          bool shouldUpdate = false;
          
          // 1. メールアドレスが一致する場合
          if (member.contact == userEmail && userEmail.isNotEmpty) {
            shouldUpdate = true;
            logger.i('📧 メールアドレス一致: ${member.name} → $newUserName (メール: ${member.contact})');
          }
          
          // 2. デフォルトユーザーの場合（UID: defaultUser）
          if (member.memberId == 'defaultUser') {
            shouldUpdate = true;
            logger.i('🆔 デフォルトユーザー: ${member.name} → $newUserName (ID: ${member.memberId})');
          }
          
          // 3. 現在のログインユーザーのUIDと一致する場合
          if (currentUserId.isNotEmpty && member.memberId == currentUserId) {
            shouldUpdate = true;
            logger.i('🔐 UID一致: ${member.name} → $newUserName (UID: ${member.memberId})');
          }
          
          if (shouldUpdate && member.name != newUserName) {
            // メンバー名を更新
            final updatedMember = member.copyWith(name: newUserName);
            updatedMembers.add(updatedMember);
            groupUpdated = true;
            logger.i('✅ メンバー更新: ${member.name} → $newUserName (グループ: ${group.groupName})');
          } else {
            // 更新不要、そのまま追加
            updatedMembers.add(member);
          }
        }
        
        // グループが更新された場合のみ保存
        if (groupUpdated) {
          final updatedGroup = group.copyWith(
            members: updatedMembers,
            // オーナー情報も更新（オーナーが変更対象の場合）
            ownerName: group.ownerEmail == userEmail || group.ownerUid == 'defaultUser' || group.ownerUid == currentUserId 
                ? newUserName 
                : group.ownerName,
          );
          
          await repository.updateGroup(group.groupId, updatedGroup);
          logger.i('💾 グループ "${group.groupName}" を更新しました');
        } else {
          logger.i('⏭️ グループ "${group.groupName}" は更新不要');
        }
      }
      
      logger.i('✅ _updateUserNameInAllGroups完了');
    } catch (e) {
      logger.e('❌ _updateUserNameInAllGroups エラー: $e');
    }
  }

  // ユーザー名を保存するメソッド
  void _saveUserName() async {
    if (_userNameFormKey.currentState?.validate() ?? false) {
      try {
        final newUserName = userNameController.text.trim();
        
        if (newUserName.isNotEmpty) {
          logger.i('💾 ユーザー名保存開始: $newUserName');
          
          // 1. UserSettingsにユーザー名を保存
          await ref.read(userSettingsProvider.notifier).updateUserName(newUserName);
          logger.i('✅ UserSettingsに保存完了');
          
          // 2. プロバイダーを無効化して最新データを反映
          ref.invalidate(userNameProvider);
          
          // 3. 少し待ってから確認
          await Future.delayed(const Duration(milliseconds: 100));
          final savedUserName = ref.read(userNameProvider);
          logger.i('🔍 保存後のユーザー名確認: $savedUserName');
          
          // 4. デフォルトグループの情報も更新
          await userInfoSave();
          logger.i('✅ デフォルトグループ更新完了');
          
          logger.i('✅ ユーザー名を保存しました: $newUserName');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ユーザー名「$newUserName」を保存しました'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        logger.e('❌ ユーザー名保存エラー: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ユーザー名の保存に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // バリデーションエラーがある場合
      logger.w('⚠️ ユーザー名のバリデーションエラー');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー名を正しく入力してください'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // デフォルトグループにユーザー名を保存
  // サインイン処理を実行するメソッド
  Future<void> _performSignIn() async {
    final email = emailController.text;
    final password = passwordController.text;
    
    try {
      logger.i('🔧 _performSignIn: サインイン開始');
      logger.i('🔧 _performSignIn: フレーバー = ${F.appFlavor}');
      logger.i('🔧 _performSignIn: email = $email');
      
      final authService = ref.read(authProvider);
      logger.i('🔧 _performSignIn: authService = ${authService.runtimeType}');
      
      final user = await authService.signIn(email, password);
      logger.i('🔧 _performSignIn: signIn完了 - user: $user (type: ${user.runtimeType})');
      
      // Mock環境では状態を手動で更新
      if (F.appFlavor == Flavor.dev && user != null) {
        ref.read(mockAuthStateProvider.notifier).state = user;
        logger.i('🔧 _performSignIn: mockAuthStateProvider更新完了');
        
        // 更新後の状態を確認
        final updatedMockState = ref.read(mockAuthStateProvider);
        logger.i('🔧 _performSignIn: 更新後のmockAuthStateProvider: $updatedMockState');
        logger.i('🔧 _performSignIn: 更新後のemail: ${updatedMockState?.email}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインしました')),
        );
        
        // サインイン成功後、メールアドレスを含むユーザー情報を更新
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // 認証状態から現在のユーザー名を取得してメールアドレスを更新
          final authState = ref.read(authStateProvider);
          String? currentUserName;
          
          authState.whenData((user) {
            if (user != null) {
              logger.i('🔧 PostFrameCallback: user type = ${user.runtimeType}');
              logger.i('🔧 PostFrameCallback: user.email = ${user.email}');
              
              // MockUserかFirebase Userかによって処理を分ける
              if (user is MockUser) {
                currentUserName = user.displayName;
                logger.i('🔧 PostFrameCallback: MockUser displayName = "${user.displayName}"');
              } else {
                // Firebase User
                currentUserName = user.displayName;
                logger.i('🔧 PostFrameCallback: Firebase User displayName = "${user.displayName}"');
              }
              
              logger.i('🔧 PostFrameCallback: 最終的なユーザー名 = "$currentUserName"');
            }
          });
          
          // ユーザー名が取得できない場合は、入力フォームまたは設定から取得
          if (currentUserName == null || currentUserName!.isEmpty) {
            currentUserName = userNameController.text;
            if (currentUserName == null || currentUserName!.isEmpty) {
              final settingsUserName = ref.read(userNameProvider);
              if (settingsUserName != null && settingsUserName.isNotEmpty) {
                currentUserName = settingsUserName;
                logger.i('🔧 PostFrameCallback: 設定からユーザー名取得 = "$currentUserName"');
              }
            }
          }
          
          if (currentUserName != null && currentUserName!.isNotEmpty) {
            logger.i('🔧 サインイン後のuserInfoSave()を実行します...');
            await userInfoSave(); // メールアドレスを含む情報を更新
            
            // 強制的にプロバイダーを再読み込みして最新のデータを反映
            ref.invalidate(purchaseGroupProvider);
            
            logger.i('🔧 サインイン後のユーザー情報更新完了');
          } else {
            logger.w('🔧 認証済みユーザー名が取得できないため、userInfoSave()をスキップします');
          }
          _loadUserNameFromDefaultGroup();
        });
        
        // フォームをリセット
        setState(() {
          showSignInForm = false;
        });
        emailController.clear();
        passwordController.clear();
      }
    } catch (e) {
      logger.e('🚨 ログイン失敗: $e');
      logger.e('🚨 エラーの詳細: ${e.runtimeType}');
      if (e.toString().contains('FirebaseAuthException')) {
        logger.e('🚨 Firebase Auth エラーコード: ${e.toString()}');
      }
      
      if (mounted) {
        String errorMessage = 'ログインに失敗しました';
        bool offerSignUp = false;
        
        // Firebaseエラーの詳細を判定
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'このメールアドレスは登録されていません';
          offerSignUp = true;
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'パスワードが間違っています';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'メールアドレスの形式が正しくありません';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'ログイン試行回数が多すぎます。しばらく待ってから再試行してください';
        } else if (e.toString().contains('unknown-error')) {
          errorMessage = 'ログインに失敗しました。アカウントが存在しない可能性があります';
          offerSignUp = true;  // unknown-errorの場合もサインアップを提案
        }
        
        if (offerSignUp) {
          // ユーザー名が保存されているかをチェック
          final currentUserName = ref.read(userNameProvider);
          final inputUserName = userNameController.text.trim();
          
          if ((currentUserName == null || currentUserName.isEmpty) && 
              (inputUserName.isEmpty)) {
            // ユーザー名が設定されていない場合、ユーザー名の設定を促す
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('ユーザー名が必要です'),
                  content: const Text('サインアップするには、まずユーザー名を設定してください。\n\n画面上部のユーザー名入力欄にお名前を入力してから再度お試しください。'),
                  actions: [
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        // サインインフォームを閉じて、ユーザー名入力にフォーカスを促す
                        setState(() {
                          showSignInForm = false;
                        });
                        
                        // もしユーザー名が入力されていたら、それを保存
                        final inputUserName = userNameController.text.trim();
                        if (inputUserName.isNotEmpty) {
                          try {
                            logger.i('💾 ダイアログからユーザー名保存開始: $inputUserName');
                            
                            // UserSettingsとデフォルトグループ両方に保存
                            await ref.read(userSettingsProvider.notifier).updateUserName(inputUserName);
                            await userInfoSave(); // デフォルトグループも更新
                            
                            logger.i('✅ ダイアログからユーザー名保存完了: $inputUserName');
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ユーザー名「$inputUserName」を保存しました'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            logger.e('❌ ダイアログからユーザー名保存エラー: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ユーザー名の保存に失敗しました: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                        
                        // ユーザー名入力欄にフォーカスを当てる（オプション）
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: const Text('了解'),
                    ),
                  ],
                );
              },
            );
          } else {
            // ユーザー名が設定されている場合、従来通りサインアップを提案
            final bool? shouldSignUp = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                String dialogTitle = 'アカウントが見つかりません';
                String dialogContent = 'メールアドレス "$email" は登録されていません。\n新しいアカウントを作成しますか？';
                
                if (e.toString().contains('unknown-error')) {
                  dialogTitle = 'ログインエラー';
                  dialogContent = 'メールアドレス "$email" でのログインに失敗しました。\n新しいアカウントを作成しますか？';
                }
                
                return AlertDialog(
                  title: Text(dialogTitle),
                  content: Text(dialogContent),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('アカウント作成'),
                    ),
                  ],
                );
              },
            );

            if (shouldSignUp == true && mounted) {
              await _performSignUp();
            }
          }
        } else {
          // パスワード間違いやその他のエラーの場合は単純にエラーメッセージを表示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  // サインアップ処理を実行するメソッド
  Future<void> _performSignUp() async {
    final email = emailController.text;
    final password = passwordController.text;
    
    try {
      final user = await ref.read(authProvider).signUp(email, password);
      logger.i('🔧 _performSignUp: signUp完了 - user: $user (type: ${user.runtimeType})');
      
      // Mock環境では状態を手動で更新
      if (F.appFlavor == Flavor.dev && user != null) {
        ref.read(mockAuthStateProvider.notifier).state = user;
        logger.i('🔧 _performSignUp: mockAuthStateProvider更新完了');
        
        // 更新後の状態を確認
        final updatedMockState = ref.read(mockAuthStateProvider);
        logger.i('🔧 _performSignUp: 更新後のmockAuthStateProvider: $updatedMockState');
        logger.i('🔧 _performSignUp: 更新後のemail: ${updatedMockState?.email}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アカウントを作成してログインしました')),
        );
        
        // サインアップ成功後、ユーザー情報を更新（サインイン処理と同様）
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // 認証状態から現在のユーザー名を取得してメールアドレスを更新
          final authState = ref.read(authStateProvider);
          String? currentUserName;
          
          authState.whenData((user) {
            if (user != null) {
              logger.i('🔧 PostFrameCallback(SignUp): user type = ${user.runtimeType}');
              logger.i('🔧 PostFrameCallback(SignUp): user.email = ${user.email}');
              
              // MockUserかFirebase Userかによって処理を分ける
              if (user is MockUser) {
                currentUserName = user.displayName;
                logger.i('🔧 PostFrameCallback(SignUp): MockUser displayName = "${user.displayName}"');
              } else {
                // Firebase User
                currentUserName = user.displayName;
                logger.i('🔧 PostFrameCallback(SignUp): Firebase User displayName = "${user.displayName}"');
              }
              
              logger.i('🔧 PostFrameCallback(SignUp): 最終的なユーザー名 = "$currentUserName"');
            }
          });
          
          // ユーザー名が取得できない場合は、入力フォームまたは設定から取得
          if (currentUserName == null || currentUserName!.isEmpty) {
            currentUserName = userNameController.text;
            if (currentUserName == null || currentUserName!.isEmpty) {
              final settingsUserName = ref.read(userNameProvider);
              if (settingsUserName != null && settingsUserName.isNotEmpty) {
                currentUserName = settingsUserName;
                logger.i('🔧 PostFrameCallback(SignUp): 設定からユーザー名取得 = "$currentUserName"');
              }
            }
          }
          
          if (currentUserName != null && currentUserName!.isNotEmpty) {
            logger.i('🔧 サインアップ後のuserInfoSave()を実行します...');
            await userInfoSave(); // メールアドレスを含む情報を更新
            
            // 強制的にプロバイダーを再読み込みして最新のデータを反映
            ref.invalidate(purchaseGroupProvider);
            
            logger.i('🔧 サインアップ後のユーザー情報更新完了');
          } else {
            logger.w('🔧 認証済みユーザー名が取得できないため、userInfoSave()をスキップします');
          }
          _loadUserNameFromDefaultGroup();
        });
        
        // フォームをリセット
        setState(() {
          showSignInForm = false;
        });
        emailController.clear();
        passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アカウント作成に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> userInfoSave() async {
    logger.i('🚀 userInfoSave() 開始');
    
    // ユーザー名を複数の方法で取得（優先順位付き）
    String userName = '';
    
    // 1. まずフォームから取得
    if (userNameController.text.trim().isNotEmpty) {
      userName = userNameController.text.trim();
      logger.i('🚀 userInfoSave: フォームからユーザー名取得 = "$userName"');
    }
    
    // 2. フォームが空の場合、設定から取得
    if (userName.isEmpty) {
      final settingsUserName = ref.read(userNameProvider);
      if (settingsUserName != null && settingsUserName.isNotEmpty) {
        userName = settingsUserName;
        logger.i('🚀 userInfoSave: 設定からユーザー名取得 = "$userName"');
      }
    }
    
    // 3. それでも空の場合、認証状態から取得
    if (userName.isEmpty) {
      final authState = ref.read(authStateProvider);
      await authState.when(
        data: (user) async {
          if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
            userName = user.displayName!;
            logger.i('🚀 userInfoSave: 認証状態からユーザー名取得 = "$userName"');
          }
        },
        loading: () async {},
        error: (error, stack) async {},
      );
    }
    
    logger.i('🚀 userInfoSave() - 使用するユーザー名: "$userName"');
    
    if (userName.isNotEmpty) {
      try {
        const groupId = 'defaultGroup';
        
        // 現在の認証状態から実際のメールアドレスを取得（非同期対応）
        String userEmail = 'default@example.com'; // デフォルト値
        
        try {
          // デバッグ: 複数の認証状態をチェック
          logger.i('🔍 userInfoSave: 認証状態をデバッグ開始');
          
          // 1. authStateProviderから確認
          final authState = ref.read(authStateProvider);
          logger.i('🔍 authStateProvider状態: $authState');
          
          final currentUser = await authState.when(
            data: (user) async {
              logger.i('🔍 authStateProvider.data: $user (type: ${user.runtimeType})');
              if (user != null) {
                logger.i('🔍 user.email: ${user.email}');
                logger.i('🔍 user.uid: ${user.uid}');
                if (user is MockUser) {
                  logger.i('🔍 MockUser.displayName: ${user.displayName}');
                }
              }
              return user;
            },
            loading: () async {
              logger.i('🔍 authStateProvider.loading');
              return null;
            },
            error: (err, stack) async {
              logger.i('🔍 authStateProvider.error: $err');
              return null;
            },
          );
          
          // 2. 直接authProviderから確認
          final authService = ref.read(authProvider);
          final directUser = authService.currentUser;
          logger.i('🔍 authProvider.currentUser: $directUser (type: ${directUser.runtimeType})');
          if (directUser != null) {
            logger.i('🔍 directUser.email: ${directUser.email}');
          }
          
          // 3. mockAuthStateProviderから直接確認（DEV環境の場合）
          if (F.appFlavor == Flavor.dev) {
            final mockUser = ref.read(mockAuthStateProvider);
            logger.i('🔍 mockAuthStateProvider: $mockUser');
            if (mockUser != null) {
              logger.i('🔍 mockUser.email: ${mockUser.email}');
            }
          }
          
          // 実際のメールアドレスを決定
          String? actualEmail;
          
          if (currentUser != null) {
            actualEmail = _getUserEmail(currentUser);
            logger.i('🔍 _getUserEmail(currentUser): $actualEmail');
          }
          
          // もし空の場合、直接認証サービスから取得
          if ((actualEmail == null || actualEmail.isEmpty) && directUser != null) {
            actualEmail = _getUserEmail(directUser);
            logger.i('🔍 _getUserEmail(directUser): $actualEmail');
          }
          
          // メールアドレスの設定
          if (actualEmail != null && actualEmail.isNotEmpty) {
            userEmail = actualEmail;
            logger.i('userInfoSave: 認証済みユーザーのメールアドレス: $userEmail');
          } else {
            // DEV環境では入力されたメールアドレスを使用
            if (emailController.text.isNotEmpty) {
              userEmail = emailController.text;
              logger.i('userInfoSave: フォーム入力のメールアドレスを使用: $userEmail');
            } else {
              logger.i('userInfoSave: メールアドレスが取得できないため、デフォルトを使用: $userEmail');
            }
          }
        } catch (e) {
          logger.w('userInfoSave: 認証状態取得エラー、デフォルトメールアドレスを使用: $e');
        }
        
        // 既存のデフォルトグループを取得
        PurchaseGroup? existingGroup;
        try {
          existingGroup = await ref.read(purchaseGroupProvider.future);
        } catch (e) {
          // グループが存在しない場合はnull
          existingGroup = null;
        }
        
        PurchaseGroup defaultGroup;
        if (existingGroup != null) {
          logger.i('userInfoSave: 既存グループを更新 - ユーザー名: $userName');
          
          // 新しいサインインユーザーを必ずオーナーにする
          final updatedMembers = <PurchaseGroupMember>[];
          
          // 既存のメンバーから非オーナーのみを保持
          for (var member in (existingGroup.members ?? [])) {
            if (member.role != PurchaseGroupRole.owner) {
              updatedMembers.add(member);
              logger.i('userInfoSave: 非オーナーメンバーを保持: ${member.name} (${member.role})');
            } else {
              logger.i('userInfoSave: 既存オーナーを削除: ${member.name}');
            }
          }
          
          // 新しいオーナーを追加
          updatedMembers.add(PurchaseGroupMember(
            memberId: 'defaultUser',
            name: userName,
            contact: userEmail,
            role: PurchaseGroupRole.owner,
            isSignedIn: true,
          ));
          logger.i('userInfoSave: 新しいオーナーを追加: $userName ($userEmail)');
          
          logger.i('userInfoSave: 更新後のメンバー数: ${updatedMembers.length}');
          for (var member in updatedMembers) {
            logger.i('  - ${member.name} (${member.role}) - ${member.contact}');
          }
          
          defaultGroup = existingGroup.copyWith(
            members: updatedMembers,
            ownerName: userName,
            ownerEmail: userEmail,
            ownerUid: 'defaultUser',
          );
        } else {
          // 新しいデフォルトグループを作成
          defaultGroup = PurchaseGroup(
            groupId: groupId,
            groupName: 'あなたのグループ',
            members: [
              PurchaseGroupMember(
                memberId: 'defaultUser',
                name: userName,
                contact: userEmail, // 動的に取得したメールアドレスを使用
                role: PurchaseGroupRole.owner,
                isSignedIn: true,
              )
            ],
          );
        }
        
        // デフォルトShoppingListを作成（既存の場合は更新しない）
        try {
          final existingShoppingList = await ref.read(shoppingListProvider.future);
          logger.i('userInfoSave: 既存のShoppingListを発見: ${existingShoppingList.items.length}個のアイテム');
          for (var item in existingShoppingList.items) {
            logger.i('  - ${item.name} (数量: ${item.quantity}, 購入済み: ${item.isPurchased})');
          }
          // 既に存在する場合は何もしない
        } catch (e) {
          logger.i('userInfoSave: ShoppingListが存在しないため新規作成します');
          // 存在しない場合のみ作成
          final defaultShoppingList = ShoppingList(
            ownerUid: 'defaultUser',
            groupId: groupId,
            groupName: 'あなたのグループ',
            items: [
              ShoppingItem.createNow(
                memberId: 'defaultUser',
                name: 'サンプル商品',
                quantity: 1,
              ),
            ],
          );
          await ref.read(shoppingListProvider.notifier).updateShoppingList(defaultShoppingList);
          logger.i('userInfoSave: デフォルトShoppingListを作成しました（サンプル商品含む）');
        }
        
        // 購入グループを保存
        await ref.read(purchaseGroupProvider.notifier).updateGroup(defaultGroup);
        logger.i('userInfoSave: デフォルトグループ保存完了');
        
        // 🌟 新機能: 全グループで同じUID/メールアドレスのメンバー名を更新
        await _updateUserNameInAllGroups(userName, userEmail);
        
        // ユーザー名プロバイダーにも保存（重要！）
        await ref.read(userNameNotifierProvider.notifier).setUserName(userName);
        logger.i('userInfoSave: ユーザー名プロバイダー保存完了');
        
        // 保存後の確認ログ
        try {
          final savedGroup = await ref.read(purchaseGroupProvider.future);
          final ownerMember = savedGroup.members?.firstWhere((m) => m.role == PurchaseGroupRole.owner);
          logger.i('userInfoSave確認: 保存後のownerメンバー - 名前: ${ownerMember?.name}, メール: ${ownerMember?.contact}');
        } catch (e) {
          logger.w('userInfoSave確認: 保存確認でエラー: $e');
        }
        
        // デバッグ用ログ
        logger.i('userInfoSave: ユーザー名 "$userName" で デフォルトグループを更新しました');
        logger.i('userInfoSave: プロバイダーにもユーザー名 "$userName" を保存しました');
        logger.i('userInfoSave: 使用したメールアドレス: $userEmail');
        
        // UserSettingsにもユーザー情報を保存
        logger.i('userInfoSave: UserSettingsにユーザー情報を保存開始');
        try {
          final userSettingsRepository = ref.read(userSettingsRepositoryProvider);
          await userSettingsRepository.updateUserName(userName);
          await userSettingsRepository.updateUserEmail(userEmail);
          logger.i('userInfoSave: UserSettings保存完了 - 名前: $userName, メール: $userEmail');
        } catch (e) {
          logger.w('userInfoSave: UserSettings保存エラー: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ユーザー情報を保存しました')),
          );
        }
      } catch (e) {
        // エラーメッセージ
        logger.i('userInfoSave エラー: $e');
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
          const SnackBar(content: Text('ユーザー名を入力してください')),
        );
      }
    }
  }

  /// 🔥 Firebase包括診断
  Future<void> _runFirebaseDiagnostics() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🩺 Firebase完全診断開始...'),
          backgroundColor: Colors.orange,
        ),
      );

      logger.i('🩺 === Firebase完全診断開始 ===');
      
      // Firebase診断実行
      final diagnostics = await FirebaseDiagnostics.runDiagnostics();
      final solutions = FirebaseDiagnostics.getSolutions(diagnostics);
      
      // 結果をログ出力
      logger.i('📊 診断結果:');
      diagnostics.forEach((key, value) {
        logger.i('  $key: $value');
      });
      
      logger.i('💡 推奨解決策:');
      for (final solution in solutions) {
        logger.i('  $solution');
      }
      
      // UI表示
      if (mounted) {
        final isHealthy = diagnostics['firestore_connection'] == true && 
                         diagnostics['firestore_write'] == true;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHealthy 
                ? '✅ Firebase診断完了: 全て正常'
                : '⚠️ Firebase診断完了: 問題を検出 (コンソール確認)'
            ),
            backgroundColor: isHealthy ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      logger.i('⛔ Firebase診断エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Firebase診断失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔥 Firebase接続テスト
  Future<void> _firebaseConnectionTest() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Firebase接続テスト開始...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Firestoreインスタンスを取得
      final firestore = FirebaseFirestore.instance;
      
      // テスト用ドキュメントを作成
      final testDocRef = firestore
          .collection('connection_test')
          .doc('test_${DateTime.now().millisecondsSinceEpoch}');
      
      logger.i('🔥 Firebase接続テスト: Firestoreへの書き込みを試行中...');
      
      // Firestoreに書き込み
      await testDocRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test_data': 'Firebase connection test from Go Shop app',
        'user_agent': 'Flutter Web',
      });
      
      logger.i('✅ Firebase接続テスト: 書き込み成功');
      
      // 書き込み直後に読み込みテスト
      final doc = await testDocRef.get();
      if (doc.exists) {
        logger.i('✅ Firebase接続テスト: 読み込み成功');
        logger.i('📄 Document data: ${doc.data()}');
        
        // テスト用ドキュメントを削除
        await testDocRef.delete();
        logger.i('🗑️ Firebase接続テスト: クリーンアップ完了');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Firebase接続テスト成功！読み書き共に正常'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Document was not created');
      }
    } catch (e) {
      logger.i('⛔ Firebase接続テストエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Firebase接続テスト失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        const Text('開発者: 青木沢田 真矢'),
        const Text('お問い合わせ: maya27AokiSawada@example.com'),
        const SizedBox(height: 16),
        const Text('© 2024 Go Shop. All rights reserved.'),
      ],
    );
  }
}
