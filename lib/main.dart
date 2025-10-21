import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
// QRコード招待機能
import 'screens/qr_scan_screen.dart';
import 'pages/purchase_group_page_simple.dart';
import 'services/hive_initialization_service.dart';
import 'widgets/app_initialize_widget.dart';
import 'flavors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // フレーバーの設定 - 本番環境（Firestore + Hive ハイブリッド）
  F.appFlavor = Flavor.prod;

  // Firebase初期化（DEV/PROD両方で初期化）
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Web環境での設定
  } catch (e) {
    // Firebase初期化に失敗してもアプリは続行（Hiveで動作）
    print('Firebase初期化エラー: $e');
  }

  // Hive初期化（アダプター登録、Box開封、データバージョンチェック）
  await HiveInitializationService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
      home: const AppInitializeWidget(
        child: HomeScreen(),
      ),
      routes: {
        '/qr_scan': (context) => const QrScanScreen(),
        '/group_simple': (context) => const PurchaseGroupPageSimple(),
      },
    );
  }
}
