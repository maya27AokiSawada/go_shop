import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_mode_config.dart';

/// AppMode変更を通知するためのProvider
/// HomeScreenなどのUIを強制的に再構築するために使用
final appModeNotifierProvider = StateProvider<AppMode>((ref) {
  return AppModeSettings.currentMode;
});
