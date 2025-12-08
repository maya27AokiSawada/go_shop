import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
// QRコード招待機能
import 'screens/qr_scan_screen.dart';
import 'pages/purchase_group_page_simple.dart';
import 'services/hive_lock_cleaner.dart';
import 'services/user_specific_hive_service.dart';
import 'widgets/app_initialize_widget.dart';
import 'flavors.dart';
// 🔥 後方互換性のためカスタムアダプター
import 'adapters/shopping_item_adapter_override.dart';
import 'adapters/user_settings_adapter_override.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 環境変数の初期化（最優先）
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info('✅ 環境変数読み込み成功');
  } catch (e) {
    AppLogger.error('❌ 環境変数読み込みエラー: $e');
    AppLogger.info('ℹ️ .envファイルが見つかりません - デフォルト値を使用します');
  }

  // フレーバーの設定 - 本番環境（Firestore + Hive Hybrid + テスト広告）
  F.appFlavor = Flavor.prod;

  // Firebase初期化（prodとdev両方で有効化 - 2025-12-08変更）
  if (F.appFlavor == Flavor.prod || F.appFlavor == Flavor.dev) {
    try {
      AppLogger.info('🔄 Firebase初期化開始...');
      AppLogger.info('🎯 現在のプラットフォーム: $defaultTargetPlatform');
      AppLogger.info(
          '📋 プロジェクトID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      AppLogger.info(
          '📋 アプリID: ${DefaultFirebaseOptions.currentPlatform.appId}');
      AppLogger.info(
          '📋 API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey}');
      AppLogger.info(
          '📋 Auth Domain: ${DefaultFirebaseOptions.currentPlatform.authDomain}');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('✅ Firebase初期化成功');

      // Firebase Auth の状態確認
      AppLogger.info('🔐 Firebase Auth インスタンス: ${FirebaseAuth.instance}');
      AppLogger.info('🔐 現在のユーザー: ${FirebaseAuth.instance.currentUser}');

      // Firestore の状態確認
      AppLogger.info('🗃️ Firestore インスタンス: ${FirebaseFirestore.instance}');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Firebase初期化エラー詳細: $e');
      AppLogger.error('📚 エラータイプ: ${e.runtimeType}');
      AppLogger.error('📚 スタックトレース: $stackTrace');

      // duplicate-appエラーは既に初期化済みなので無視
      if (e.toString().contains('duplicate-app')) {
        AppLogger.info('ℹ️ Firebase既に初期化済み - 続行します');
      } else {
        // その他のエラーは再スロー
        AppLogger.warning('⚠️ 重大なFirebaseエラー - アプリ起動を中止');
        rethrow;
      }
    }
  } else {
    AppLogger.info('💡 開発環境：Firebaseをスキップ（Hiveのみ使用）');
  }

  // ホットリスタート対応：既存のHiveロックファイルをクリア
  await HiveLockCleaner.clearOneDriveLocks();

  // 🔥 後方互換性のためカスタムアダプター登録
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ShoppingItemAdapterOverride());
    AppLogger.info(
        '✅ ShoppingItemAdapterOverride registered (backward compatible)');
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(UserSettingsAdapterOverride());
    AppLogger.info(
        '✅ UserSettingsAdapterOverride registered (backward compatible)');
  }

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
