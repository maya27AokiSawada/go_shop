// lib/services/hive_initialization_service.dart
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../models/user_settings.dart';
import '../datastore/user_settings_repository.dart';
import '../providers/hive_provider.dart' as hive_provider;
import 'data_version_service.dart';
import 'user_specific_hive_service.dart';

/// Hive初期化を統合管理するサービス
class HiveInitializationService {
  

  /// Hiveを初期化（アダプター登録、Box開封、データバージョンチェック）
  static Future<void> initialize() async {
    try {
      Log.info('🔧 Hive初期化開始');
      
      // 1. Hiveの基本初期化
      await Hive.initFlutter();
      Log.info('✅ Hive基本初期化完了');
      
      // 2. アダプター登録
      await _registerAdapters();
      
      // 3. データバージョンチェックとマイグレーション
      final dataVersionService = DataVersionService();
      final wasCleared = await dataVersionService.checkAndMigrateData();
      
      if (wasCleared) {
        Log.info('🔄 データがクリアされたため、デフォルトBoxを開きます');
      }
      
      // 4. デフォルトBoxを開く
      await _openDefaultBoxes();
      
      Log.info('✅ Hive初期化完了');
    } catch (e, stackTrace) {
      Log.error('❌ Hive初期化エラー: $e');
      Log.error('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// ユーザー固有のHive初期化（UID変更時）
  static Future<void> initializeForUser({
    required String userId,
    required WidgetRef ref,
  }) async {
    try {
      Log.info('👤 ユーザー固有Hive初期化開始: UID=$userId');
      
      // Windows版のみユーザー固有のHiveサブディレクトリを使用
      if (Platform.isWindows) {
        await UserSpecificHiveService.instance.initializeForUser(userId);
        Log.info('✅ Windows版: ユーザー固有Hiveに切り替え完了');
        
        // プロバイダーの無効化を遅延させて競合を回避
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(hive_provider.purchaseGroupBoxProvider);
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(hive_provider.shoppingListBoxProvider);
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(hive_provider.userSettingsBoxProvider);
        
        Log.info('✅ プロバイダー無効化完了');
      } else {
        Log.info('ℹ️ Android/iOS版: 既存のHiveをそのまま使用');
      }
      
    } catch (e, stackTrace) {
      Log.error('❌ ユーザー固有Hive初期化エラー: $e');
      Log.error('スタックトレース: $stackTrace');
    }
  }

  /// 全Hiveデータをクリア（デバッグ用）
  static Future<void> clearAllData() async {
    try {
      Log.info('🗑️ 全Hiveデータクリア開始');
      
      // 開いている全てのBoxを閉じる
      await Hive.close();
      
      // Hiveディレクトリを削除（パスは環境から取得）
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final hiveDir = Directory('${appDocDir.path}/hive');
        if (await hiveDir.exists()) {
          await hiveDir.delete(recursive: true);
          Log.info('✅ Hiveディレクトリ削除完了');
        }
      } catch (e) {
        Log.warning('⚠️ Hiveディレクトリ削除中にエラー: $e');
      }
      
      // 再初期化
      await initialize();
      
      Log.info('✅ 全Hiveデータクリア完了');
    } catch (e, stackTrace) {
      Log.error('❌ Hiveデータクリアエラー: $e');
      Log.error('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// Hiveアダプターを登録
  static Future<void> _registerAdapters() async {
    try {
      Log.info('📦 Hiveアダプター登録開始');
      
      // PurchaseGroup関連
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PurchaseGroupRoleAdapter());
        Log.info('  ✅ PurchaseGroupRoleAdapter (typeId: 0) 登録');
      }
      
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PurchaseGroupMemberAdapter());
        Log.info('  ✅ PurchaseGroupMemberAdapter (typeId: 1) 登録');
      }
      
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(PurchaseGroupAdapter());
        Log.info('  ✅ PurchaseGroupAdapter (typeId: 2) 登録');
      }
      
      // ShoppingList関連
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ShoppingItemAdapter());
        Log.info('  ✅ ShoppingItemAdapter (typeId: 3) 登録');
      }
      
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ShoppingListAdapter());
        Log.info('  ✅ ShoppingListAdapter (typeId: 4) 登録');
      }
      
      // UserSettings
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(UserSettingsAdapter());
        Log.info('  ✅ UserSettingsAdapter (typeId: 5) 登録');
      }
      
      // InvitationStatus（新規追加）
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(InvitationStatusAdapter());
        Log.info('  ✅ InvitationStatusAdapter (typeId: 8) 登録');
      }
      
      Log.info('✅ Hiveアダプター登録完了');
    } catch (e) {
      Log.error('❌ Hiveアダプター登録エラー: $e');
      rethrow;
    }
  }

  /// デフォルトBoxを開く
  static Future<void> _openDefaultBoxes() async {
    try {
      Log.info('📂 デフォルトBox開封開始');
      
      // PurchaseGroupBox
      if (!Hive.isBoxOpen('purchaseGroupBox')) {
        await Hive.openBox<PurchaseGroup>('purchaseGroupBox');
        Log.info('  ✅ purchaseGroupBox 開封完了');
      }
      
      // ShoppingListBox
      if (!Hive.isBoxOpen('shoppingListBox')) {
        await Hive.openBox<ShoppingList>('shoppingListBox');
        Log.info('  ✅ shoppingListBox 開封完了');
      }
      
      // UserSettingsBox
      if (!Hive.isBoxOpen('userSettingsBox')) {
        await Hive.openBox<UserSettings>('userSettingsBox');
        Log.info('  ✅ userSettingsBox 開封完了');
      }
      
      Log.info('✅ デフォルトBox開封完了');
    } catch (e) {
      Log.error('❌ デフォルトBox開封エラー: $e');
      rethrow;
    }
  }

  /// Boxが開いているかチェック
  static bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  /// 特定のBoxを閉じる
  static Future<void> closeBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
        Log.info('📦 Box[$boxName]を閉じました');
      }
    } catch (e) {
      Log.error('❌ Box[$boxName]のクローズエラー: $e');
    }
  }

  /// 全てのBoxを閉じる
  static Future<void> closeAllBoxes() async {
    try {
      Log.info('🔒 全Boxクローズ開始');
      await Hive.close();
      Log.info('✅ 全Boxクローズ完了');
    } catch (e) {
      Log.error('❌ 全Boxクローズエラー: $e');
    }
  }
}
