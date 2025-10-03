import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_settings_provider.dart';
import 'auth_provider.dart';

/// データ表示可否を判定するプロバイダー
final dataVisibilityProvider = Provider<bool>((ref) {
  final isSecretMode = ref.watch(secretModeProvider);
  final authState = ref.watch(authStateProvider);
  
  // シークレットモードが無効の場合は常に表示OK
  if (!isSecretMode) {
    return true;
  }
  
  // シークレットモードが有効の場合はログイン必須
  return authState.when(
    data: (user) => user != null,  // ログイン済みなら表示OK
    loading: () => false,          // ロード中は非表示
    error: (_, __) => false,       // エラー時は非表示
  );
});

/// 認証が必要かどうかを判定するプロバイダー
final authRequiredProvider = Provider<bool>((ref) {
  final isSecretMode = ref.watch(secretModeProvider);
  final authState = ref.watch(authStateProvider);
  
  // シークレットモードが無効の場合は認証不要
  if (!isSecretMode) {
    return false;
  }
  
  // シークレットモードが有効で未ログインの場合は認証が必要
  return authState.when(
    data: (user) => user == null,  // 未ログインなら認証必要
    loading: () => true,           // ロード中は認証必要として扱う
    error: (_, __) => true,        // エラー時は認証必要として扱う
  );
});