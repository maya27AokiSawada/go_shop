import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

import '../providers/user_settings_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shopping_list_provider.dart' hide shoppingListBoxProvider;
import '../providers/user_specific_hive_provider.dart';
import '../providers/hive_provider.dart';
import '../widgets/user_data_migration_dialog.dart';
import '../services/firestore_group_sync_service.dart';
import '../services/firestore_user_name_service.dart';
import '../services/user_preferences_service.dart';
import '../flavors.dart';

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
            // データを消去する場合（Hiveローカルデータのみ。Firestoreは残す）
            Log.info('🗑️ ユーザーがデータ消去を選択 - Hiveデータをクリア');

            // Hiveの全ボックスをクリア
            await _clearAllHiveBoxes(ref);

            if (isWindows) {
              // Windows版: 新ユーザー用のHiveデータベースに切り替え
              await hiveService.initializeForUser(newUserId);
            }

            // プロバイダーを無効化する前に少し待機（Hive DBの完全なクリアを保証）
            await Future.delayed(const Duration(milliseconds: 300));
            Log.info('⏱️ Hiveクリア後の待機完了');

            // Firestoreから新ユーザーのデータをダウンロード（本番環境のみ）
            if (F.appFlavor == Flavor.prod) {
              Log.info('🔄 新ユーザーのFirestoreデータをダウンロード中...');

              // 1. グループデータを同期
              final groups =
                  await FirestoreGroupSyncService.syncGroupsOnSignIn();
              Log.info('✅ Firestoreから${groups.length}件のグループをダウンロード');

              // 2. ユーザー名を復帰
              final firestoreName =
                  await FirestoreUserNameService.getUserName();
              if (firestoreName != null && firestoreName.isNotEmpty) {
                await UserPreferencesService.saveUserName(firestoreName);
                Log.info('✅ Firestoreからユーザー名を復帰: $firestoreName');
              }
            }

            // 安全にプロバイダーを無効化（遅延実行で順次）
            await _invalidateProvidersSequentially(ref);

            // デフォルトグループを作成（Firestoreに0件の場合）
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              Log.info('🆕 [UID変更] デフォルトグループ作成チェック...');
              final groupNotifier = ref.read(allGroupsProvider.notifier);
              await groupNotifier.createDefaultGroup(user);
              Log.info('✅ [UID変更] デフォルトグループ作成完了');
            }
          } else {
            // データを引き継ぐ場合
            Log.info('🔄 ユーザーがデータ引き継ぎを選択');

            // TODO: マージ処理を実装すべき
            // 通常シナリオ: パスワード/メールアドレス忘れで新アカウント作成
            // → 旧データを新UIDでそのまま使いたい
            //
            // 理想的な処理:
            // 1. 既存グループのallowedUidに新UIDを追加（アクセス権維持）
            // 2. デフォルトグループのgroupIdを新UIDに更新
            // 3. Firestore同期時に競合を回避
            //
            // 現状: 既存データをそのまま使用（allowedUidは古いUIDのまま）

            if (isWindows) {
              // Windows版: ユーザー固有フォルダに切り替え
              await hiveService.initializeForUser(newUserId);
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
          Log.info(
              '🔄 [Windows] Switching to user-specific Hive database: $newUserId');
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
    return temporaryPrefixes
        .any((prefix) => uid.toLowerCase().startsWith(prefix));
  }

  /// プロバイダーを順次無効化（通常の遅延）
  static Future<void> _invalidateProvidersSequentially(WidgetRef ref) async {
    // 選択中のグループIDをクリア（重要！）
    ref.read(selectedGroupIdProvider.notifier).clearSelection();

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

  /// Hiveの全ボックスをクリア（Firestoreは残す）
  static Future<void> _clearAllHiveBoxes(WidgetRef ref) async {
    try {
      Log.info('🗑️ Hiveボックスのクリア開始');

      // 各Hiveボックスを取得してクリア
      final purchaseGroupBox = ref.read(purchaseGroupBoxProvider);
      final shoppingListBox = ref.read(shoppingListBoxProvider);

      await purchaseGroupBox.clear();
      Log.info('✅ PurchaseGroupボックスをクリア');

      await shoppingListBox.clear();
      Log.info('✅ ShoppingListボックスをクリア');

      Log.info('✅ Hiveボックスのクリア完了');
    } catch (e) {
      Log.error('❌ Hiveボックスクリアエラー: $e');
    }
  }
}
