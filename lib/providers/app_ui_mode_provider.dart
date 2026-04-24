// lib/providers/app_ui_mode_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_ui_mode_config.dart';

/// AppUIMode変更を通知するためのProvider
final appUIModeProvider = StateProvider<AppUIMode>((ref) {
  return AppUIModeSettings.currentMode;
});
