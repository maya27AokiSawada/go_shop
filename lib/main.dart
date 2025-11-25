import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
// QRコード招待機能
import 'screens/qr_scan_screen.dart';
import 'pages/purchase_group_page_simple.dart';
import 'services/hive_lock_cleaner.dart';
import 'services/user_specific_hive_service.dart';
import 'widgets/app_initialize_widget.dart';
import 'flavors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // フレーバーの設定 - 本番環境（Firestore + Hive Hybrid - crash-proof実装テスト）
  F.appFlavor = Flavor.prod;

  // Firebase初期化（詳細なエラー情報を表示）
  if (F.appFlavor == Flavor.prod) {
    try {
      print('🔄 Firebase初期化開始...');
      print('🎯 現在のプラットフォーム: $defaultTargetPlatform');
      print('📋 プロジェクトID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      print('📋 アプリID: ${DefaultFirebaseOptions.currentPlatform.appId}');
      print('📋 API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey}');
      print(
          '📋 Auth Domain: ${DefaultFirebaseOptions.currentPlatform.authDomain}');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase初期化成功');

      // Firebase Auth の状態確認
      print('🔐 Firebase Auth インスタンス: ${FirebaseAuth.instance}');
      print('🔐 現在のユーザー: ${FirebaseAuth.instance.currentUser}');

      // Firestore の状態確認
      print('🗃️ Firestore インスタンス: ${FirebaseFirestore.instance}');
    } catch (e, stackTrace) {
      print('❌ Firebase初期化エラー詳細: $e');
      print('📚 エラータイプ: ${e.runtimeType}');
      print('📚 スタックトレース: $stackTrace');

      // duplicate-appエラーは既に初期化済みなので無視
      if (e.toString().contains('duplicate-app')) {
        print('ℹ️ Firebase既に初期化済み - 続行します');
      } else {
        // その他のエラーは再スロー
        print('⚠️ 重大なFirebaseエラー - アプリ起動を中止');
        rethrow;
      }
    }
  } else {
    print('💡 開発環境：Firebaseをスキップ（Hiveのみ使用）');
  }

  // ホットリスタート対応：既存のHiveロックファイルをクリア
  await HiveLockCleaner.clearOneDriveLocks();

  // グローバルHiveアダプター登録のみ実行（Box開封はUserSpecificHiveServiceに委任）
  await UserSpecificHiveService.initializeAdapters();

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
        '/group_simple': (context) => const SharedGroupPageSimple(),
      },
    );
  }
}
