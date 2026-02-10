import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'firebase_options.dart';
import 'screens/home_screen.dart';
// QRコード招待機能
import 'screens/qr_scan_screen.dart';
import 'pages/shared_group_page_simple.dart';
import 'services/hive_lock_cleaner.dart';
import 'services/user_specific_hive_service.dart';
import 'widgets/app_initialize_widget.dart';
import 'flavors.dart';
// 🔥 後方互換性のためカスタムアダプター
import 'adapters/shopping_item_adapter_override.dart';
import 'adapters/user_settings_adapter_override.dart';
import 'utils/app_logger.dart';

void main() async {
  // 🔥 Windows/Linux/macOS用 Sentry初期化
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await SentryFlutter.init(
      (options) {
        // 🔥 DSN設定
        // NOTE: Sentry DSNは公開情報として設計されています（書き込み専用、読み取り不可）
        // セキュリティはSentry管理画面の「Allowed Domains」設定で保護してください
        options.dsn =
            'https://9aa7459e94ab157f830e81c9f1a585b3@o4510820521738240.ingest.us.sentry.io/4510820522786816';

        // 🔥 CRITICAL: リリースモードでもSentryを有効化
        options.debug = false; // リリースでは詳細ログなし（パフォーマンス重視）
        options.environment = kDebugMode ? 'development' : 'production';

        // パフォーマンス監視設定
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2; // リリースは20%サンプリング
        options.enableAutoPerformanceTracing = true;

        // 🔥 ネイティブSDK統合（C++クラッシュも捕捉）
        options.enableNativeCrashHandling = true; // C++レベルのクラッシュも捕捉
        options.enableAutoSessionTracking = true; // セッション追跡

        // クラッシュ時スクリーンショット（Windows版でも動作）
        options.attachScreenshot = true;
        options.screenshotQuality = SentryScreenshotQuality.medium;

        // プライバシー保護：個人情報マスキング
        options.beforeSend = (event, hint) {
          // ユーザーIDマスキング
          if (event.user?.id != null) {
            event = event.copyWith(
              user: event.user?.copyWith(
                id: AppLogger.maskUserId(event.user?.id),
              ),
            );
          }
          return event;
        };
      },
      appRunner: () => _initializeApp(),
    );
  } else {
    // Android/iOS: Sentryなしで直接初期化
    await _initializeApp();
  }
}

Future<void> _initializeApp() async {
  AppLogger.info('▶️ main() 開始');
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('✅ WidgetsFlutterBinding.ensureInitialized() 完了');

  // 🔥 環境変数の初期化（最優先）
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info('✅ 環境変数読み込み成功');
  } catch (e) {
    AppLogger.error('❌ 環境変数読み込みエラー: $e');
    AppLogger.info('ℹ️ .envファイルが見つかりません - デフォルト値を使用します');
  }

  // 🔥 DEV: フレーバーの設定 - 開発環境（gotoshop-572b7）
  F.appFlavor = Flavor.dev;
  AppLogger.info('⚙️ フレーバー設定完了: ${F.appFlavor}');

  // Firebase初期化（prodとdev両方で有効化 - 2025-12-08変更）
  if (F.appFlavor == Flavor.prod || F.appFlavor == Flavor.dev) {
    try {
      AppLogger.info('🔄 Firebase初期化開始...');

      // Android環境でのネットワークスタック初期化待機（DNS解決問題対策）
      if (defaultTargetPlatform == TargetPlatform.android) {
        AppLogger.info('⏳ Android環境 - ネットワークスタック初期化待機中（2秒）...');
        await Future.delayed(const Duration(seconds: 2));
        AppLogger.info('✅ ネットワークスタック初期化待機完了');
      }

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
      AppLogger.info('✅ Firebase.initializeApp() 完了');

      // Firebase Auth の状態確認
      AppLogger.info('🔐 Firebase Auth インスタンス: ${FirebaseAuth.instance}');
      final currentUser = FirebaseAuth.instance.currentUser;
      AppLogger.info(
          '🔐 現在のユーザー: ${currentUser != null ? AppLogger.maskUserId(currentUser.uid) : "未ログイン"}');

      // Firestore の状態確認
      AppLogger.info('🗃️ Firestore インスタンス: ${FirebaseFirestore.instance}');

      // 🔥 クラッシュレポート初期化（Platform判定で分岐）
      if (Platform.isAndroid || Platform.isIOS) {
        // Android/iOS: Firebase Crashlytics
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
          AppLogger.error(
              '❌ [Crashlytics] Flutter Fatal Error: ${errorDetails.exception}');
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          AppLogger.error('❌ [Crashlytics] Async Error: $error');
          return true;
        };

        AppLogger.info('✅ Firebase Crashlytics初期化成功（Android/iOS）');
      } else {
        // Windows/Linux/macOS: Sentry
        // Sentry初期化はmain()で実行済み
        AppLogger.info('✅ Sentry初期化完了（Windows/Linux/macOS）');
      }
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

  AppLogger.info('🔄 Hive初期化プロセス開始...');
  // ホットリスタート対応：既存のHiveロックファイルをクリア
  await HiveLockCleaner.clearOneDriveLocks();
  AppLogger.info('✅ HiveLockCleaner.clearOneDriveLocks() 完了');

  // 🔥 後方互換性のためカスタムアダプター登録
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SharedItemAdapterOverride());
    AppLogger.info(
        '✅ SharedItemAdapterOverride registered (backward compatible)');
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(UserSettingsAdapterOverride());
    AppLogger.info(
        '✅ UserSettingsAdapterOverride registered (backward compatible)');
  }

  // グローバルHiveアダプター登録のみ実行（Box開封はUserSpecificHiveServiceに委任）
  await UserSpecificHiveService.initializeAdapters();
  AppLogger.info('✅ UserSpecificHiveService.initializeAdapters() 完了');

  AppLogger.info('🚀 runApp() 実行開始');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.info('🎨 MyApp.build() 開始');
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
