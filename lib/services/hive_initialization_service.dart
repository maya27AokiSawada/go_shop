// lib/services/hive_initialization_service.dart
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../models/user_settings.dart';
import '../providers/hive_provider.dart' as hive_provider;
import 'data_version_service.dart';
import 'user_specific_hive_service.dart';

/// Hive初期化を統合管理するサービス
class HiveInitializationService {
  /// Hiveを初期化（アダプター登録、Box開封、データバージョンチェック）
  static Future<void> initialize() async {
    try {
      AppLogger.info('Hive初期化開始');

      // 1. Hiveの基本初期化（アプリ専用ディレクトリを使用）
      final appDocDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDocDir.path}/hive_db');
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
      }

      await Hive.initFlutter(hiveDir.path);
      AppLogger.info('Hive基本初期化完了 (保存先: ${hiveDir.path})');

      // 2. アダプター登録
      await _registerAdapters();

      // 3. データバージョンチェックとマイグレーション
      final dataVersionService = DataVersionService();
      final wasCleared = await dataVersionService.checkAndMigrateData();

      if (wasCleared) {
        AppLogger.info('データがクリアされたため、デフォルトBoxを開きます');
      }

      // 4. デフォルトBoxを開く
      await _openDefaultBoxes();

      AppLogger.info('Hive初期化完了');
    } catch (e, stackTrace) {
      AppLogger.error('Hive初期化エラー: $e');
      AppLogger.error('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// Hiveアダプターを登録
  static Future<void> _registerAdapters() async {
    try {
      AppLogger.info('Hiveアダプター登録開始');

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PurchaseGroupRoleAdapter());
        AppLogger.info('PurchaseGroupRoleAdapter (typeId: 0) 登録');
      }

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PurchaseGroupMemberAdapter());
        AppLogger.info('PurchaseGroupMemberAdapter (typeId: 1) 登録');
      }

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(PurchaseGroupAdapter());
        AppLogger.info('PurchaseGroupAdapter (typeId: 2) 登録');
      }

      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ShoppingItemAdapter());
        AppLogger.info('ShoppingItemAdapter (typeId: 3) 登録');
      }

      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ShoppingListAdapter());
        AppLogger.info('ShoppingListAdapter (typeId: 4) 登録');
      }

      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(UserSettingsAdapter());
        AppLogger.info('UserSettingsAdapter (typeId: 5) 登録');
      }

      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(InvitationStatusAdapter());
        AppLogger.info('InvitationStatusAdapter (typeId: 8) 登録');
      }

      AppLogger.info('Hiveアダプター登録完了');
    } catch (e) {
      AppLogger.error('Hiveアダプター登録エラー: -Forcee');
      rethrow;
    }
  }

  /// デフォルトBoxを開く
  static Future<void> _openDefaultBoxes() async {
    try {
      AppLogger.info('デフォルトBox開封開始');

      // PurchaseGroupBox
      if (!Hive.isBoxOpen('purchaseGroupBox')) {
        await Hive.openBox<PurchaseGroup>('purchaseGroupBox');
        AppLogger.info('purchaseGroupBox 開封完了');
      }

      // ShoppingListBox
      if (!Hive.isBoxOpen('shoppingListBox')) {
        await Hive.openBox<ShoppingList>('shoppingListBox');
        AppLogger.info('shoppingListBox 開封完了');
      }

      // UserSettingsBox
      if (!Hive.isBoxOpen('userSettingsBox')) {
        await Hive.openBox<UserSettings>('userSettingsBox');
        AppLogger.info('userSettingsBox 開封完了');
      }

      AppLogger.info('デフォルトBox開封完了');
    } catch (e) {
      AppLogger.error('デフォルトBox開封エラー: $e');
      rethrow;
    }
  }
}
