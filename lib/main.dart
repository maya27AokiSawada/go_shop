import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
// QRコード招待機能
import 'screens/qr_scan_screen.dart';
import 'pages/purchase_group_page_simple.dart';
import 'services/hive_initialization_service.dart';
import 'services/hive_lock_cleaner.dart';
import 'widgets/app_initialize_widget.dart';
import 'flavors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // フレーバーの設定 - 開発環境（Hive のみ、Firestore無効）
  F.appFlavor = Flavor.dev;

  // Firebase初期化（詳細なエラー情報を表示）
  if (F.appFlavor == Flavor.prod) {
    try {
      print('🔄 Firebase初期化開始...');
      print('📋 プロジェクトID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      print('📋 アプリID: ${DefaultFirebaseOptions.currentPlatform.appId}');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase初期化成功');
    } catch (e, stackTrace) {
      print('❌ Firebase初期化エラー詳細: $e');
      print('📚 スタックトレース: $stackTrace');
      // Firebase初期化に失敗してもアプリは続行（Hiveで動作）
    }
  } else {
    print('💡 開発環境：Firebaseをスキップ（Hiveのみ使用）');
  }

  // ホットリスタート対応：既存のHiveロックファイルをクリア
  await HiveLockCleaner.clearOneDriveLocks();

  // Hive初期化（アダプター登録、Box開封、データバージョンチェック）
  await HiveInitializationService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: F.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: F.appFlavor != Flavor.prod,
      home: const AppInitializeWidget(child: HomeScreen()),
      routes: {
        '/qr_scan': (context) => const QrScanScreen(),
        '/group_simple': (context) => const PurchaseGroupPageSimple(),
      },
    );
  }
}
