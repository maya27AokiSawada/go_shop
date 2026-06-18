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
import 'l10n/app_localizations.dart';
import 'services/user_preferences_service.dart';

bool _envLoaded = false;

Future<void> _loadEnvOnce() async {
  if (_envLoaded) return;
  try {
    await dotenv.load(fileName: '.env');
    _envLoaded = true;
    AppLogger.info('✅ 環境変数読み込み成功');
  } catch (e) {
    AppLogger.error('❌ 環境変数読み込みエラー: $e');
    AppLogger.info('ℹ️ .envファイルが見つかりません - デフォルト値を使用します');
  }
}

String? _readSentryDsn() {
  final value = dotenv.env['SENTRY_DSN']?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

String _readSentryEnvironment() {
  final value = dotenv.env['SENTRY_ENVIRONMENT']?.trim();
  if (value != null && value.isNotEmpty) return value;
  return kDebugMode ? 'development' : 'production';
}

/// Firebase.initializeApp() を指数バックオフ（初回500ms）でリトライする。
/// Android のネットワークスタック初期化（DNS解決問題）に対応。
Future<void> _initFirebaseWithBackoff() async {
  const maxRetries = 4;
  var delay = const Duration(milliseconds: 500);
  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('✅ Firebase.initializeApp() 完了（試行 $attempt 回目）');
      return;
    } on Exception catch (e) {
      if (e.toString().contains('duplicate-app')) {
        AppLogger.info('ℹ️ Firebase既に初期化済み - 続行します');
        return;
      }
      if (attempt == maxRetries) rethrow;
      AppLogger.warning('⚠️ Firebase初期化 試行 $attempt/$maxRetries 失敗: $e');
      AppLogger.info('⏳ ${delay.inMilliseconds}ms 後にリトライ...');
      await Future.delayed(delay);
      delay = delay * 2;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnvOnce();

  // 🔥 Windows/Linux/macOS用 Sentry初期化
  final sentryDsn = _readSentryDsn();
  if ((Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
      sentryDsn != null) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;

        // 🔥 CRITICAL: リリースモードでもSentryを有効化
        options.debug = false; // リリースでは詳細ログなし（パフォーマンス重視）
        options.environment = _readSentryEnvironment();

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
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      AppLogger.info('ℹ️ SENTRY_DSN 未設定のため Sentry を無効化して起動します');
    }
    await _initializeApp();
  }
}

Future<void> _initializeApp() async {
  AppLogger.info('▶️ main() 開始');
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('✅ WidgetsFlutterBinding.ensureInitialized() 完了');

  // 🌐 手動言語設定（設定ページで選択した言語を優先）
  final savedLang = await UserPreferencesService.getLanguageCode();
  if (savedLang != null && savedLang.isNotEmpty) {
    AppLocalizations.setLanguage(savedLang);
    AppLogger.info('🌐 保存済み言語で起動: $savedLang');
  }

  await _loadEnvOnce();

  AppLogger.info('⚙️ フレーバー: ${F.appFlavor} (--dart-define=FLAVORで指定)');

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

      // 指数バックオフ（初回500ms）でFirebase初期化リトライ（Android DNS解決対応）
      await _initFirebaseWithBackoff();

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
