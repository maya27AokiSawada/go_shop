// lib/config/app_ui_mode_config.dart

/// UIモード（グループ・リスト管理の粒度）
enum AppUIMode {
  single, // シングルモード：1グループ・1リスト固定
  multi, // マルチモード：複数グループ・リスト管理
}

/// UIモード管理
class AppUIModeSettings {
  static AppUIMode _currentMode = AppUIMode.single;

  static AppUIMode get currentMode => _currentMode;

  /// UIモードを変更
  static void setMode(AppUIMode mode) {
    _currentMode = mode;
  }
}
