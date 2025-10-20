import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../services/device_settings_service.dart';

/// デバイス設定サービスのプロバイダー
final deviceSettingsServiceProvider = Provider<DeviceSettingsService>((ref) {
  return DeviceSettingsService.instance;
});

/// シークレットモードの状態を管理するプロバイダー
final secretModeProvider = StateNotifierProvider<SecretModeNotifier, bool>((ref) {
  return SecretModeNotifier(ref.read(deviceSettingsServiceProvider));
});

/// シークレットモードの状態管理
class SecretModeNotifier extends StateNotifier<bool> {
  final DeviceSettingsService _deviceSettings;
  
  SecretModeNotifier(this._deviceSettings) : super(false) {
    _loadSecretMode();
  }
  
  /// 初期化時にシークレットモード設定を読み込み
  Future<void> _loadSecretMode() async {
    try {
      final isEnabled = await _deviceSettings.isSecretModeEnabled();
      state = isEnabled;
    } catch (e) {
      // エラー時はfalse（シークレットモード無効）
      state = false;
    }
  }
  
  /// シークレットモードを切り替え
  Future<void> toggleSecretMode() async {
    try {
      final newValue = !state;
      await _deviceSettings.setSecretMode(newValue);
      state = newValue;
    } catch (e) {
      // エラー時は状態を元に戻す
      rethrow;
    }
  }
  
  /// シークレットモードを直接設定
  Future<void> setSecretMode(bool enabled) async {
    try {
      await _deviceSettings.setSecretMode(enabled);
      state = enabled;
    } catch (e) {
      rethrow;
    }
  }
}