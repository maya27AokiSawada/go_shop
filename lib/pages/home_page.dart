import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/user_name_provider.dart';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../flavors.dart';
import '../helper/firebase_diagnostics.dart';

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
    
    // 設定から現在のユーザー名を確認
    final currentUserName = ref.read(userNameProvider);
    logger.i('👤 現在のユーザー名（設定から）: $currentUserName');
    
    if (currentUserName != null && currentUserName.isNotEmpty) {
      userNameController.text = currentUserName;
      logger.i('✅ ユーザー名が設定から復元されました: $currentUserName');
    } else {
      logger.i('⚠️ 設定にユーザー名がないため、グループから読み込み');
      _loadUserNameFromDefaultGroup();
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
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
    final currentUserName = ref.watch(userNameProvider);
    
    // 認証状態が変わった時にユーザー名をチェック
    ref.listen(authStateProvider, (previous, next) {
      logger.i('🔎 認証状態変更を検知');
      next.whenData((user) {
        logger.i('🔐 ユーザー: ${user?.email ?? "null"}, 現在のユーザー名: $currentUserName');
        if (currentUserName == null || currentUserName.isEmpty) {
          logger.i('🔄 ユーザー名がないのでグループから読み込みを実行');
          // ユーザー名がない場合は認証状態に関係なくグループから読み込み
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadUserNameFromDefaultGroup();
          });
        } else {
          logger.i('🚫 ユーザー名読み込みをスキップ: ユーザー名が既に存在=$currentUserName');
        }
      });
    });
    
    return Scaffold(
    appBar: AppBar(title: const Text('Go Shopping')),
    body: Center(
      child: Builder(
        builder: (context) {
          // Replace with your actual logic to check authentication state
          return authState.when(
            data: (user) {
              if (user == null) { // 未ログイン状態ならサインイン・サインアップボタンを表示
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ユーザー名入力
                        TextFormField(
                          controller: userNameController,
                          decoration: const InputDecoration(
                            labelText: 'User Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'ユーザー名を入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // サインインボタン（カーソル位置）
                        ElevatedButton(
                          onPressed: () {
                            if (userNameController.text.isNotEmpty) {
                              setState(() {
                                showSignInForm = true;
                              });
                              // ユーザー名を保存
                              _saveUserName();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ユーザー名を入力してください')),
                              );
                            }
                          },
                          child: const Text('サインイン'),
                        ),
                        const SizedBox(height: 16),
                        
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
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ようこそ、${savedUserName ?? user.email ?? "ユーザー"}さん'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(authProvider).signOut();
                        // Mock環境では状態を手動でクリア
                        if (F.appFlavor == Flavor.dev) {
                          ref.read(mockAuthStateProvider.notifier).state = null;
                        }
                        // ログアウト時にユーザー名もクリア
                        // ユーザー名をクリア（今回はコメントアウト）
                        // await ref.read(userNameNotifierProvider.notifier).clearUserName();
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
                      'ログイン状態: ${user.email}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
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
                  if (user != null && currentMember.contact != user.email && user.email != null) {
                    logger.i('📬 メールアドレスでメンバーを再検索: ${user.email}');
                    final emailMatchMember = group.members!.firstWhere(
                      (member) => member.contact == user.email,
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

  // ユーザー名を保存するメソッド
  void _saveUserName() async {
    final userName = userNameController.text;
    if (userName.isNotEmpty) {
      // userInfoSaveが全てを処理するので、これだけで十分
      await userInfoSave();
    }
  }

  // デフォルトグループにユーザー名を保存
  // サインイン処理を実行するメソッド
  Future<void> _performSignIn() async {
    final email = emailController.text;
    final password = passwordController.text;
    
    try {
      final user = await ref.read(authProvider).signIn(email, password);
      
      // Mock環境では状態を手動で更新
      if (F.appFlavor == Flavor.dev && user != null) {
        ref.read(mockAuthStateProvider.notifier).state = user;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインしました')),
        );
        
        // フォームをリセット
        setState(() {
          showSignInForm = false;
        });
        emailController.clear();
        passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        // サインイン失敗時の処理
        final bool? shouldSignUp = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ログインに失敗しました'),
              content: Text('メールアドレス "$email" でのログインに失敗しました。\n新しいアカウントを作成しますか？'),
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
    }
  }

  // サインアップ処理を実行するメソッド
  Future<void> _performSignUp() async {
    final email = emailController.text;
    final password = passwordController.text;
    
    try {
      final user = await ref.read(authProvider).signUp(email, password);
      
      // Mock環境では状態を手動で更新
      if (F.appFlavor == Flavor.dev && user != null) {
        ref.read(mockAuthStateProvider.notifier).state = user;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アカウントを作成してログインしました')),
        );
        
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
    final userName = userNameController.text;
    
    if (userName.isNotEmpty) {
      try {
        const groupId = 'defaultGroup';
        
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
          // 既存グループのownerメンバーを更新
          final updatedMembers = existingGroup.members?.map((member) {
            logger.i('userInfoSave: メンバーチェック - ${member.name} (${member.role})');
            if (member.role == PurchaseGroupRole.owner) {
              logger.i('userInfoSave: ownerメンバーを更新: ${member.name} -> $userName');
              return member.copyWith(name: userName);
            }
            return member;
          }).toList() ?? [];
          
          // ownerが存在しない場合は新規作成
          if (!updatedMembers.any((m) => m.role == PurchaseGroupRole.owner)) {
            logger.i('userInfoSave: ownerが存在しないため新規作成: $userName');
            updatedMembers.add(PurchaseGroupMember(
              memberId: 'defaultUser',
              name: userName,
              contact: 'default@example.com',
              role: PurchaseGroupRole.owner,
              isSignedIn: true,
            ));
          }
          
          logger.i('userInfoSave: 更新後のメンバー数: ${updatedMembers.length}');
          for (var member in updatedMembers) {
            logger.i('  - ${member.name} (${member.role}) - ${member.contact}');
          }
          
          defaultGroup = existingGroup.copyWith(members: updatedMembers);
        } else {
          // 新しいデフォルトグループを作成
          defaultGroup = PurchaseGroup(
            groupId: groupId,
            groupName: 'あなたのグループ',
            members: [
              PurchaseGroupMember(
                memberId: 'defaultUser',
                name: userName,
                contact: 'default@example.com',
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
        logger.i('userInfoSave: グループ保存完了');
        
        // ユーザー名プロバイダーにも保存（重要！）
        await ref.read(userNameNotifierProvider.notifier).setUserName(userName);
        logger.i('userInfoSave: ユーザー名プロバイダー保存完了');
        
        // デバッグ用ログ
        logger.i('userInfoSave: ユーザー名 "$userName" で デフォルトグループを更新しました');
        logger.i('userInfoSave: プロバイダーにもユーザー名 "$userName" を保存しました');
        
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
}
