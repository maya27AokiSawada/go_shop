import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'pages/invitation_accept_page.dart';
import 'services/user_specific_hive_service.dart';
import 'services/deep_link_service.dart';
import 'services/user_initialization_service.dart';
import 'flavors.dart';

final logger = Logger();

// /// 【デバッグ用】Hiveデータをクリアする関数 - 使用済み
// /// memberID問題解決のため、既存の問題があるデータを削除
// Future<void> _clearHiveDataForDebugging() async {
//   try {
//     logger.w("🗑️ デバッグ用: Hiveデータをクリア中...");
//     await Hive.deleteFromDisk();
//     logger.i("✅ Hiveデータのクリアが完了");
//   } catch (e) {
//     logger.e("❌ Hiveデータクリア中にエラー: $e");
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = Logger();
  
  // フレーバーの設定
  F.appFlavor = Flavor.prod; // Firebase統合デバッグのためPRODモード
  
  // Firebase初期化
  if (F.appFlavor == Flavor.prod) {
    logger.i("🔥 Starting Go Shop app in PRODUCTION mode with Firebase");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i("✅ Firebase initialized successfully");
  } else {
    logger.i("💡 Starting Go Shop app in DEV mode (Hive only, no Firebase)");
  }
  
  // 【デバッグ用】既存のHiveデータをクリア（memberID問題のため）
  // TODO: この部分は問題解決後に削除する
  // await _clearHiveDataForDebugging(); // 既にクリア済み
  
  // グローバルHive初期化（アダプター登録のみ）
  // Windows版: UserSpecificHiveServiceでUID固有フォルダ管理
  // Android/iOS版: 従来通りの動作（アプリ再開時も同じHiveデータを使用）
  await UserSpecificHiveService.initializeAdapters();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // ユーザー初期化サービスを開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userInitService = ref.read(userInitializationServiceProvider);
      userInitService.startAuthStateListener();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: F.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: F.appFlavor != Flavor.prod,
      home: const HomeScreen(),
      routes: {
        '/invitation_accept': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return InvitationAcceptPage(inviteCode: args['inviteCode']!);
        },
      },
      builder: (context, child) {
        // アプリ起動時にディープリンクを初期化
        DeepLinkService.initializeDeepLinks(context);
        return child!;
      },
    );
  }
}
