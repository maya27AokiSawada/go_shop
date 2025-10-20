import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

import '../providers/user_settings_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/user_specific_hive_provider.dart';
import '../widgets/user_data_migration_dialog.dart';

class UserIdChangeHelper {
  

  static Future<void> handleUserIdChange({
    required WidgetRef ref,
    required BuildContext context,
    required String newUserId,
    required String userEmail,
    required bool mounted,
  }) async {
    try {
      // 仮設定UID（MockやLocalテスト用）の場合は処理をスキップ
      if (_isTemporaryUid(newUserId)) {
        Log.info('🔄 仮設定UID検出 - UID変更処理をスキップ: $newUserId');
        return;
      }
      
      final userSettings = ref.read(userSettingsProvider.notifier);
      final hiveService = ref.read(userSpecificHiveProvider);
      final hasChanged = await userSettings.hasUserIdChanged(newUserId);
      final isWindows = Platform.isWindows;
      
      if (hasChanged) {
        // UIDが変更された場合、ユーザーに選択を求める
        if (mounted) {
          final shouldKeepData = await UserDataMigrationDialog.show(
            context,
            previousUser: '前回のユーザー',
            newUser: userEmail,
          );
          
          if (shouldKeepData == false) {
            // データを消去する場合
            Log.info('🗑️ ユーザーがデータ消去を選択');
            
            if (isWindows) {
              // Windows版: ユーザー固有のHiveデータベースに切り替え
              await hiveService.initializeForUser(newUserId);
              // TODO: clearCurrentUserData メソッドを実装
            } else {
              // Android/iOS版: 現在のHiveデータをクリア（フォルダは変更しない）
              // TODO: clearCurrentUserData メソッドを実装
            }
            
            // 安全にプロバイダーを無効化（遅延実行で順次）
            await _invalidateProvidersSequentially(ref);
            
          } else {
            // データを引き継ぐ場合
            Log.info('🔄 ユーザーがデータ引き継ぎを選択');
            
            if (isWindows) {
              // Windows版: ユーザー固有フォルダに切り替え
              await hiveService.initializeForUser(newUserId);
              // TODO: migrateDataFromDefault メソッドを実装
            }
            // Android/iOS版: 何もしない（既存データをそのまま使用）
            
            // 安全にプロバイダーを無効化（遅延実行で順次）
            await _invalidateProvidersSequentially(ref);
          }
        }
      } else {
        // UIDが変更されていない場合
        if (isWindows && hiveService.currentUserId != newUserId) {
          // Windows版のみ: 適切なユーザーデータベースに切り替え
          Log.info('🔄 [Windows] Switching to user-specific Hive database: $newUserId');
          await hiveService.initializeForUser(newUserId);
          
          // プロバイダーの無効化を大幅に遅延させて競合を回避
          await _invalidateProvidersWithLongDelay(ref);
        }
        // Android/iOS版: 何もしない（既存のHiveをそのまま使用）
      }
      
      // 新しいUIDを保存（Hive初期化完了後に実行）
      await Future.delayed(const Duration(milliseconds: 500));
      await userSettings.updateUserId(newUserId);
      
    } catch (e) {
      Log.info('❌ UID変更処理エラー: $e');
    }
  }

  /// 仮設定UIDかどうかを判定
  static bool _isTemporaryUid(String uid) {
    const temporaryPrefixes = ['mock_', 'test_', 'temp_', 'local_'];
    return temporaryPrefixes.any((prefix) => uid.toLowerCase().startsWith(prefix));
  }

  /// プロバイダーを順次無効化（通常の遅延）
  static Future<void> _invalidateProvidersSequentially(WidgetRef ref) async {
    await Future.delayed(const Duration(milliseconds: 200));
    ref.invalidate(userSettingsProvider);
    await Future.delayed(const Duration(milliseconds: 200));
    ref.invalidate(shoppingListProvider);
    await Future.delayed(const Duration(milliseconds: 200));
    ref.invalidate(selectedGroupProvider);
    ref.invalidate(allGroupsProvider);
  }

  /// プロバイダーを長時間遅延で無効化（Windows版用）
  static Future<void> _invalidateProvidersWithLongDelay(WidgetRef ref) async {
    await Future.delayed(const Duration(milliseconds: 500));
    ref.invalidate(userSettingsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    ref.invalidate(shoppingListProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    ref.invalidate(selectedGroupProvider);
    ref.invalidate(allGroupsProvider);
  }
}