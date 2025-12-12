// lib/services/hive_initialization_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../models/shared_group.dart';
import '../models/shared_list.dart';
import '../models/user_settings.dart';
import 'data_version_service.dart';

/// Hive初期化を統合管理するサービス
class HiveInitializationService {
  /// Hiveを初期化（アダプター登録、Box開封、データバージョンチェック）
  static Future<void> initialize() async {
    try {
      AppLogger.info('Hive初期化開始');

      // 1. Hiveの基本初期化（プラットフォーム別）
      if (kIsWeb) {
        // Web環境：ブラウザのIndexedDBを使用
        await Hive.initFlutter();
        AppLogger.info('Hive基本初期化完了 (Web環境: IndexedDB)');
      } else {
        // モバイル・デスクトップ環境：アプリ専用ディレクトリを使用
        final appDocDir = await getApplicationDocumentsDirectory();
        final hiveDir = Directory('${appDocDir.path}/hive_db');
        if (!await hiveDir.exists()) {
          await hiveDir.create(recursive: true);
        }

        await Hive.initFlutter(hiveDir.path);
        AppLogger.info('Hive基本初期化完了 (保存先: ${hiveDir.path})');
      }

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
        Hive.registerAdapter(SharedGroupRoleAdapter());
        AppLogger.info('SharedGroupRoleAdapter (typeId: 0) 登録');
      }

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SharedGroupMemberAdapter());
        AppLogger.info('SharedGroupMemberAdapter (typeId: 1) 登録');
      }

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SharedGroupAdapter());
        AppLogger.info('SharedGroupAdapter (typeId: 2) 登録');
      }

      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(SharedItemAdapter());
        AppLogger.info('SharedItemAdapter (typeId: 3) 登録');
      }

      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(SharedListAdapter());
        AppLogger.info('SharedListAdapter (typeId: 4) 登録');
      }

      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(UserSettingsAdapter());
        AppLogger.info('UserSettingsAdapter (typeId: 5) 登録');
      }

      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(InvitationStatusAdapter());
        AppLogger.info('InvitationStatusAdapter (typeId: 8) 登録');
      }

      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(InvitationTypeAdapter());
        AppLogger.info('InvitationTypeAdapter (typeId: 9) 登録');
      }

      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(SyncStatusAdapter());
        AppLogger.info('SyncStatusAdapter (typeId: 10) 登録');
      }

      AppLogger.info('Hiveアダプター登録完了');
    } catch (e) {
      AppLogger.error('Hiveアダプター登録エラー: $e');
      rethrow;
    }
  }

  /// デフォルトBoxを開く
  static Future<void> _openDefaultBoxes() async {
    try {
      AppLogger.info('デフォルトBox開封開始');

      // SharedGroupBox
      if (!Hive.isBoxOpen('SharedGroupBox')) {
        await Hive.openBox<SharedGroup>('SharedGroupBox');
        AppLogger.info('SharedGroupBox 開封完了');
      }

      // SharedListBox
      if (!Hive.isBoxOpen('sharedListBox')) {
        await Hive.openBox<SharedList>('sharedListBox');
        AppLogger.info('sharedListBox 開封完了');
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
