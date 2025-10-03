// lib/providers/hive_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../models/user_settings.dart';

final logger = Logger();

// 安全なBoxアクセス用のプロバイダー（エラーハンドリング強化）
final purchaseGroupBoxProvider = Provider<Box<PurchaseGroup>>((ref) {
  try {
    if (Hive.isBoxOpen('purchaseGroups')) {
      return Hive.box<PurchaseGroup>('purchaseGroups');
    } else {
      // Boxが閉じている場合のメッセージ
      logger.w('⚠️ PurchaseGroup box is not open. This may be normal during app restart.');
      throw StateError('PurchaseGroup box is not open. Please initialize Hive first.');
    }
  } catch (e) {
    logger.e('❌ Failed to access PurchaseGroup box: $e');
    rethrow;
  }
});

final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  try {
    if (Hive.isBoxOpen('shoppingLists')) {
      return Hive.box<ShoppingList>('shoppingLists');
    } else {
      logger.w('⚠️ ShoppingList box is not open. This may be normal during app restart.');
      throw StateError('ShoppingList box is not open. Please initialize Hive first.');
    }
  } catch (e) {
    logger.e('❌ Failed to access ShoppingList box: $e');
    rethrow;
  }
});

final userSettingsBoxProvider = Provider<Box<UserSettings>>((ref) {
  try {
    if (Hive.isBoxOpen('userSettings')) {
      return Hive.box<UserSettings>('userSettings');
    } else {
      logger.w('⚠️ UserSettings box is not open. This may be normal during app restart.');
      throw StateError('UserSettings box is not open. Please initialize Hive first.');
    }
  } catch (e) {
    logger.e('❌ Failed to access UserSettings box: $e');
    rethrow;
  }
});
