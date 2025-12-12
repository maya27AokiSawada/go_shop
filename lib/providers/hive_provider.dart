// lib/providers/hive_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../utils/app_logger.dart';
import '../models/shared_group.dart';
import '../models/shared_list.dart';
import '../models/user_settings.dart';

// 安全なBoxアクセス用のプロバイダー（エラーハンドリング強化）
final SharedGroupBoxProvider = Provider<Box<SharedGroup>>((ref) {
  try {
    if (Hive.isBoxOpen('SharedGroups')) {
      return Hive.box<SharedGroup>('SharedGroups');
    } else {
      // Boxが閉じている場合のメッセージ
      Log.warning(
          '⚠️ SharedGroup box is not open. This may be normal during app restart.');
      throw StateError(
          'SharedGroup box is not open. Please initialize Hive first.');
    }
  } catch (e) {
    Log.error('❌ Failed to access SharedGroup box: $e');
    rethrow;
  }
});

final sharedListBoxProvider = Provider<Box<SharedList>>((ref) {
  try {
    if (Hive.isBoxOpen('sharedLists')) {
      return Hive.box<SharedList>('sharedLists');
    } else {
      Log.warning(
          '⚠️ SharedList box is not open. This may be normal during app restart.');
      throw StateError(
          'SharedList box is not open. Please initialize Hive first.');
    }
  } catch (e) {
    Log.error('❌ Failed to access SharedList box: $e');
    rethrow;
  }
});

final userSettingsBoxProvider = Provider<Box<UserSettings>>((ref) {
  try {
    if (Hive.isBoxOpen('userSettings')) {
      return Hive.box<UserSettings>('userSettings');
    } else {
      Log.warning(
          '⚠️ UserSettings box is not open. This may be normal during app restart.');
      throw StateError(
          'UserSettings box is not open. Please initialize Hive first.');
    }
  } catch (e) {
    Log.error('❌ Failed to access UserSettings box: $e');
    rethrow;
  }
});
