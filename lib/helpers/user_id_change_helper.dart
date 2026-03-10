import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

import '../models/shared_group.dart';
import '../providers/user_settings_provider.dart';
import '../providers/shared_group_provider.dart';
import '../providers/current_list_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_list_provider.dart' hide sharedListBoxProvider;
import '../providers/user_specific_hive_provider.dart';
import '../providers/hive_provider.dart';
import '../widgets/user_data_migration_dialog.dart';
import '../services/firestore_group_sync_service.dart';
import '../services/firestore_user_name_service.dart';
import '../services/user_preferences_service.dart';
import '../services/shared_list_migration_service.dart';
import '../flavors.dart';

class UserIdChangeHelper {
  static Future<void>? _activeTransition;

  static bool get isTransitionInProgress => _activeTransition != null;

  /// サインイン後にユーザーコンテキストを正しい状態へ切り替える
  ///
  /// 同時に複数箇所から呼ばれても、1回の切り替え処理へ集約する。
  static Future<void> ensureUserContextReady({
    required WidgetRef ref,
    required BuildContext context,
    required User user,
    required bool mounted,
  }) {
    final existingTransition = _activeTransition;
    if (existingTransition != null) {
      Log.info('⏳ [USER_SWITCH] 既存の切り替え処理に合流します');
      return existingTransition;
    }

    final transition = _ensureUserContextReadyInternal(
      ref: ref,
      context: context,
      user: user,
      mounted: mounted,
    );
    _activeTransition = transition;

    transition.whenComplete(() {
      _activeTransition = null;
    });

    return transition;
  }

  static Future<void> _ensureUserContextReadyInternal({
    required WidgetRef ref,
    required BuildContext context,
    required User user,
    required bool mounted,
  }) async {
    final newUserId = user.uid;
    final storedUid = await UserPreferencesService.getUserId();
    final hiveService = ref.read(userSpecificHiveProvider);
    final isWindows = Platform.isWindows;

    Log.info(
        '🔄 [USER_SWITCH] ユーザーコンテキスト準備開始: ${AppLogger.maskUserId(storedUid)} → ${AppLogger.maskUserId(newUserId)}');

    if (_isTemporaryUid(newUserId)) {
      Log.info('🔄 [USER_SWITCH] 仮設定UID検出 - 切り替え処理をスキップ: $newUserId');
      return;
    }

    final hasStoredUser = storedUid != null && storedUid.isNotEmpty;
    final uidChanged = hasStoredUser && storedUid != newUserId;

    if (uidChanged) {
      Log.info('⚠️ [USER_SWITCH] 別ユーザー検出 - ローカル状態を完全切り替え');
      await _clearAllHiveBoxes(ref);

      if (isWindows) {
        await hiveService.initializeForUser(newUserId);
        await hiveService.saveLastUsedUid(newUserId);
      }

      await UserPreferencesService.clearUserSwitchState();
      await _invalidateProvidersSequentially(ref);
    } else if (isWindows && hiveService.currentUserId != newUserId) {
      Log.info('🔄 [USER_SWITCH] 同一ユーザーだがHiveフォルダ不一致 - Windows Hive再初期化');
      await hiveService.initializeForUser(newUserId);
      await hiveService.saveLastUsedUid(newUserId);
      await _invalidateProvidersSequentially(ref);
    } else {
      Log.info('✅ [USER_SWITCH] 追加切り替え不要');
    }

    await UserPreferencesService.saveUserId(newUserId);
    Log.info('💾 [USER_SWITCH] 現在UID保存完了: ${AppLogger.maskUserId(newUserId)}');

    await _restoreSignedInUserGroups(ref, newUserId);
  }

  /// ログアウト時のローカル状態クリーンアップ
  static Future<void> performSignOutCleanup({
    required WidgetRef ref,
  }) async {
    Log.info('🔓 [USER_SWITCH] サインアウト前クリーンアップ開始');

    await _clearAllHiveBoxes(ref);
    await UserPreferencesService.clearUserSwitchState();

    final hiveService = ref.read(userSpecificHiveProvider);
    if (Platform.isWindows) {
      await hiveService.initializeForDefaultUser();
    }

    await _invalidateProvidersSequentially(ref);
    Log.info('✅ [USER_SWITCH] サインアウト前クリーンアップ完了');
  }

  static Future<void> _restoreSignedInUserGroups(
    WidgetRef ref,
    String userId,
  ) async {
    if (F.appFlavor != Flavor.prod && F.appFlavor != Flavor.dev) {
      return;
    }

    Log.info(
        '🔄 [USER_SWITCH] Firestore優先でグループ復元開始: ${AppLogger.maskUserId(userId)}');

    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        ref.invalidate(forceSyncProvider);
        await ref.read(forceSyncProvider.future);
        await ref.read(allGroupsProvider.notifier).cleanupInvalidHiveGroups();
        await ref.read(allGroupsProvider.notifier).refresh();

        final groups = await ref.read(allGroupsProvider.future);
        Log.info('📊 [USER_SWITCH] グループ復元結果 (試行$attempt): ${groups.length}件');

        if (groups.isNotEmpty) {
          return;
        }

        final currentUser = ref.read(authStateProvider).value;
        if (currentUser == null || currentUser.uid != userId) {
          Log.warning('⚠️ [USER_SWITCH] 認証状態変化を検出 - 復元試行を中断');
          return;
        }

        if (attempt == 1) {
          Log.warning('⚠️ [USER_SWITCH] 0件のため再試行します');
          await Future.delayed(const Duration(milliseconds: 800));
        }
      } catch (e) {
        Log.error('❌ [USER_SWITCH] グループ復元エラー (試行$attempt): $e');
        if (attempt == 1) {
          await Future.delayed(const Duration(milliseconds: 800));
          continue;
        }
      }
    }

    Log.warning('⚠️ [USER_SWITCH] Firestore復元後もグループ0件でした');
  }

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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Log.warning('⚠️ [AUTO_CLEAR] currentUserがnullのためスキップ');
        return;
      }

      await ensureUserContextReady(
        ref: ref,
        context: context,
        user: currentUser,
        mounted: mounted,
      );

      Log.info('✅ [AUTO_CLEAR] UID変更自動クリア処理完了');
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
              // 🔥 REMOVED: デフォルトグループ機能廃止
              Log.info('📝 [UID変更] グループが0個→初回セットアップ画面表示');

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
    // 選択中状態を永続化データごとクリア
    await ref
        .read(selectedGroupIdProvider.notifier)
        .clearSelectionAndPersistence();
    await ref.read(currentListProvider.notifier).clearSelectionAndPersistence();

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
