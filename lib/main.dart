import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
// import 'package:firebase_core/firebase_core.dart';  // 一時的にコメントアウト
// import 'firebase_options.dart';  // 一時的にコメントアウト
import 'screens/home_screen.dart';
import 'services/user_specific_hive_service.dart';
import 'flavors.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = Logger();
  
  // フレーバーの設定
  F.appFlavor = Flavor.dev; // 安全なDEVモードを継続
  
  // Firebase初期化 (一時的にコメントアウト - Firebase SDK ダウンロード時間を回避)
  // if (F.appFlavor == Flavor.prod) {
  //   logger.i("🔥 Starting Go Shop app in PRODUCTION mode with Firebase");
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   logger.i("✅ Firebase initialized successfully");
  // } else {
    logger.i("💡 Starting Go Shop app in DEV mode (Hive only, no Firebase)");
  // }
  
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    );
  }
}
