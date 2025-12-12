import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

import '../models/shared_group.dart';
import '../providers/user_settings_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shared_list_provider.dart' hide sharedListBoxProvider;
import '../providers/user_specific_hive_provider.dart';
import '../providers/hive_provider.dart';
import '../widgets/user_data_migration_dialog.dart';
import '../services/firestore_group_sync_service.dart';
import '../services/firestore_user_name_service.dart';
import '../services/user_preferences_service.dart';
import '../services/shopping_list_migration_service.dart';
import '../flavors.dart';

class UserIdChangeHelper {
  /// UID変更時の自動クリア処理（ダイアログなし）
  /// 別アカウントでサインインした場合、前のユーザーのローカルデータを自動的にクリアする
  static Future<void> handleUserIdChangeAutomatic({
    required WidgetRef ref,
    required BuildContext context,
    required String newUserId,
    required String userEmail,
    required bool mounted,
  }) async {
    try {
      Log.info('🗑️ [AUTO_CLEAR] UID変更検出 - 自動クリア開始');
      Log.info('🗑️ [AUTO_CLEAR] 新ユーザー: $userEmail ($newUserId)');

      // 仮設定UID（MockやLocalテスト用）の場合は処理をスキップ
      if (_isTemporaryUid(newUserId)) {
        Log.info('🔄 仮設定UID検出 - UID変更処理をスキップ: $newUserId');
        return;
      }

      final userSettings = ref.read(userSettingsProvider.notifier);
      final hiveService = ref.read(userSpecificHiveProvider);
      final isWindows = Platform.isWindows;

      // Hiveの全ボックスをクリア
      Log.info('🗑️ [AUTO_CLEAR] Hiveローカルデータをクリア中...');
      await _clearAllHiveBoxes(ref);

      if (isWindows) {
        // Windows版: 新ユーザー用のHiveデータベースに切り替え
        await hiveService.initializeForUser(newUserId);
      }

      // プロバイダーを無効化する前に少し待機（Hive DBの完全なクリアを保証）
      await Future.delayed(const Duration(milliseconds: 300));
      Log.info('⏱️ [AUTO_CLEAR] Hiveクリア後の待機完了');

      // 安全にプロバイダーを無効化（遅延実行で順次）
      await _invalidateProvidersSequentially(ref);

      // プロバイダー再構築を待機
      await Future.delayed(const Duration(milliseconds: 300));

      // Firestoreから新ユーザーのデータをダウンロード（本番環境のみ）
      List<SharedGroup> syncedGroups = [];
      if (F.appFlavor == Flavor.prod) {
        Log.info('🔄 [AUTO_CLEAR] 新ユーザーのFirestoreデータをダウンロード中...');

        // 1. グループデータを同期
        syncedGroups = await FirestoreGroupSyncService.syncGroupsOnSignIn();
        Log.info(
            '✅ [AUTO_CLEAR] Firestoreから${syncedGroups.length}件のグループをダウンロード');

        // 2. 取得したグループをHiveに保存
        if (syncedGroups.isNotEmpty) {
          final groupBox = ref.read(SharedGroupBoxProvider);
          for (final group in syncedGroups) {
            try {
              await groupBox.put(group.groupId, group);
              Log.info('📦 [AUTO_CLEAR] グループ「${group.groupName}」をHiveに保存');
            } catch (e) {
              Log.warning(
                  '⚠️ [AUTO_CLEAR] グループ「${group.groupName}」のHive保存失敗: $e');
            }
          }
          Log.info('✅ [AUTO_CLEAR] ${syncedGroups.length}件のグループをHiveに保存完了');

          // Hive保存後に必ずプロバイダーを無効化してUI更新
          Log.info('🔄 [AUTO_CLEAR] Firestore同期完了 - プロバイダーを更新');
          ref.invalidate(allGroupsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // 3. 買い物リストデータを同期（既存グループのリストを取得）
        // 注: 買い物リストはグループに紐づくため、グループ同期後に自動取得される
        Log.info('✅ [AUTO_CLEAR] 買い物リストはグループに紐づいて自動取得');
      }

      // ユーザー設定を更新
      await userSettings.updateUserId(newUserId);
      Log.info('💾 [AUTO_CLEAR] 新UID保存完了: $newUserId');

      // デフォルトグループの作成（Firestoreに同期済みグループがない場合）
      if (syncedGroups.isEmpty) {
        Log.info('🆕 [AUTO_CLEAR] デフォルトグループを作成');
        final user = FirebaseAuth.instance.currentUser;
        await ref.read(allGroupsProvider.notifier).createDefaultGroup(user);
        Log.info('✅ [AUTO_CLEAR] デフォルトグループ作成完了');
      }

      // プロバイダーを最終更新
      ref.invalidate(allGroupsProvider);
      ref.invalidate(selectedGroupProvider);
      await Future.delayed(const Duration(milliseconds: 300));

      Log.info('✅ [AUTO_CLEAR] UID変更自動クリア処理完了');

      // ユーザーに通知
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('新しいアカウントでサインインしました'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Log.error('❌ [AUTO_CLEAR] UID変更自動クリア処理エラー: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウント切り替え処理でエラーが発生しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// UID変更時にダイアログを表示してユーザーに選択させる処理（旧メソッド）
  /// @deprecated handleUserIdChangeAutomatic()を使用してください
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

      // 旧UIDを取得（マイグレーション用）
      final currentSettings = await ref.read(userSettingsProvider.future);
      final oldUserId = currentSettings.userId;

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

            // 安全にプロバイダーを無効化（遅延実行で順次）
            await _invalidateProvidersSequentially(ref);

            // プロバイダー再構築を待機
            await Future.delayed(const Duration(milliseconds: 300));

            // Firestoreから新ユーザーのデータをダウンロード（本番環境のみ）
            List<SharedGroup> syncedGroups = [];
            if (F.appFlavor == Flavor.prod) {
              Log.info('🔄 新ユーザーのFirestoreデータをダウンロード中...');

              // 1. グループデータを同期
              syncedGroups =
                  await FirestoreGroupSyncService.syncGroupsOnSignIn();
              Log.info('✅ Firestoreから${syncedGroups.length}件のグループをダウンロード');

              // 2. 取得したグループをHiveに保存
              if (syncedGroups.isNotEmpty) {
                final groupBox = ref.read(SharedGroupBoxProvider);
                for (final group in syncedGroups) {
                  try {
                    await groupBox.put(group.groupId, group);
                    Log.info('📦 グループ「${group.groupName}」をHiveに保存');
                  } catch (e) {
                    Log.warning('⚠️ グループ「${group.groupName}」のHive保存失敗: $e');
                  }
                }
                Log.info('✅ ${syncedGroups.length}件のグループをHiveに保存完了');

                // Hive保存後に必ずプロバイダーを無効化してUI更新
                Log.info('🔄 [UID変更] Firestore同期完了 - プロバイダーを更新');
                ref.invalidate(allGroupsProvider);
                await Future.delayed(const Duration(milliseconds: 300));
              }

              // 3. ユーザー名を復帰
              final firestoreName =
                  await FirestoreUserNameService.getUserName();
              if (firestoreName != null && firestoreName.isNotEmpty) {
                await UserPreferencesService.saveUserName(firestoreName);
                Log.info('✅ Firestoreからユーザー名を復帰: $firestoreName');
              }
            }

            // デフォルトグループの存在確認（groupId == user.uid のグループ）
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final hasDefaultGroup = syncedGroups.any(
                (group) => group.groupId == user.uid,
              );

              if (!hasDefaultGroup) {
                Log.info(
                    '🆕 [UID変更] デフォルトグループ(groupId=${user.uid})が存在しない - 作成します');
                final groupNotifier = ref.read(allGroupsProvider.notifier);
                await groupNotifier.createDefaultGroup(user);
                Log.info('✅ [UID変更] デフォルトグループ作成完了');

                // デフォルトグループ作成後にもう一度プロバイダーを無効化
                Log.info('🔄 [UID変更] デフォルトグループ作成後のUI更新');
                ref.invalidate(allGroupsProvider);
                await Future.delayed(const Duration(milliseconds: 200));
              } else {
                Log.info(
                    '💡 [UID変更] デフォルトグループ(groupId=${user.uid})は既に存在 - 作成スキップ');
              }

              // 旧デフォルトグループのリストをマイグレーション（グループが存在する場合）
              if (oldUserId.isNotEmpty && !_isTemporaryUid(oldUserId)) {
                Log.info('🔄 [UID変更] リストマイグレーション開始: $oldUserId → ${user.uid}');
                await SharedListMigrationService.migrateDefaultGroupLists(
                  oldGroupId: oldUserId,
                  newGroupId: user.uid,
                );
                Log.info('✅ [UID変更] リストマイグレーション完了');
              }
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

      // UserSettings (Hive) に保存
      await userSettings.updateUserId(newUserId);
      Log.info('💾 [UID_CHANGE] UserSettings (Hive)にUID保存完了: $newUserId');

      // SharedPreferences にも保存（次回ログイン時のUID変更検出に必要）
      await UserPreferencesService.saveUserId(newUserId);
      Log.info('💾 [UID_CHANGE] SharedPreferencesにUID保存完了: $newUserId');
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
    ref.invalidate(sharedListProvider);
    await Future.delayed(const Duration(milliseconds: 200));
    ref.invalidate(selectedGroupProvider);
    ref.invalidate(allGroupsProvider);
  }

  /// プロバイダーを長時間遅延で無効化（Windows版用）
  static Future<void> _invalidateProvidersWithLongDelay(WidgetRef ref) async {
    await Future.delayed(const Duration(milliseconds: 500));
    ref.invalidate(userSettingsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    ref.invalidate(sharedListProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    ref.invalidate(selectedGroupProvider);
    ref.invalidate(allGroupsProvider);
  }

  /// Hiveの全ボックスをクリア（Firestoreは残す）
  static Future<void> _clearAllHiveBoxes(WidgetRef ref) async {
    try {
      Log.info('🗑️ Hiveボックスのクリア開始');

      // 各Hiveボックスを取得してクリア
      final SharedGroupBox = ref.read(SharedGroupBoxProvider);
      final sharedListBox = ref.read(sharedListBoxProvider);

      await SharedGroupBox.clear();
      Log.info('✅ SharedGroupボックスをクリア');

      await sharedListBox.clear();
      Log.info('✅ SharedListボックスをクリア');

      Log.info('✅ Hiveボックスのクリア完了');
    } catch (e) {
      Log.error('❌ Hiveボックスクリアエラー: $e');
    }
  }
}
