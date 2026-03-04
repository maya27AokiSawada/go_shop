import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import 'dart:io' show Platform;
import '../services/user_specific_hive_service.dart';
import 'auth_provider.dart';

/// ユーザー固有のHiveサービス管理プロバイダー
final userSpecificHiveProvider = Provider<UserSpecificHiveService>((ref) {
  return UserSpecificHiveService.instance;
});

/// ユーザーIDの変更を監視してHiveサービスを自動切り替えするプロバイダー
final hiveUserInitializationProvider = FutureProvider<void>((ref) async {
  final hiveService = ref.read(userSpecificHiveProvider);

  // Windows版のみUID固有フォルダを使用、Android/iOS版は従来通り
  final isWindows = Platform.isWindows;

  if (isWindows) {
    // Windows版: 前回使用UIDフォルダを自動継続（認証状態に関係なく）
    AppLogger.info('🔄 [Windows] Initializing Hive with last used UID folder');
    await hiveService.initializeForWindowsUser();
  } else {
    // Android/iOS版: 従来通りのデフォルトフォルダ
    AppLogger.info(
        '🔄 [${Platform.operatingSystem}] Using default Hive folder');
    await hiveService.initializeForDefaultUser();
  }
});

/// 現在のユーザーIDを取得するプロバイダー
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Hiveサービスが初期化されているかどうかを監視するプロバイダー
///
/// 🔥 FIX (2026-03-05): FutureProviderのloading状態でも、
/// app_initialize_widget.dartで直接初期化済みの場合はtrueを返す。
/// 理由: app_initialize_widget.dartがFutureProviderとは別経路で
/// UserSpecificHiveService.initializeForDefaultUser()を直接呼び出すため、
/// FutureProviderがまだloadingでもサービスは既に初期化完了している場合がある。
final hiveInitializationStatusProvider = Provider<bool>((ref) {
  // hiveUserInitializationProviderの状態を監視
  final initializationState = ref.watch(hiveUserInitializationProvider);

  return initializationState.when(
    data: (_) => true, // FutureProvider完了 → 確実に初期化済み
    loading: () {
      // FutureProviderがloading中でも、直接初期化が完了していればtrue
      return UserSpecificHiveService.instance.isInitialized;
    },
    error: (_, __) => false, // エラー
  );
});
