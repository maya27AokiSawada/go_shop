// lib/services/user_name_initialization_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import 'user_preferences_service.dart';
import 'group_management_service.dart';

final userNameInitializationServiceProvider =
    Provider<UserNameInitializationService>((ref) {
  return UserNameInitializationService(ref);
});

/// ユーザー名の初期化処理を管理するサービス
class UserNameInitializationService {
  final Ref _ref;

  UserNameInitializationService(this._ref);

  /// ユーザー名を初期化
  ///
  /// 優先順位:
  /// 1. SharedPreferencesから復元
  /// 2. グループから読み込み
  Future<String?> initializeUserName() async {
    Log.info('🔧 initializeUserName開始');

    // 少し待ってからプロバイダーの値を取得（Riverpodの初期化完了を待つ）
    await Future.delayed(const Duration(milliseconds: 300));

    // 設定から現在のユーザー名を確認
    final currentUserName = await UserPreferencesService.getUserName();
    Log.info('👤 現在のユーザー名（設定から）: ${AppLogger.maskName(currentUserName)}');

    if (currentUserName != null && currentUserName.isNotEmpty) {
      Log.info('✅ ユーザー名が設定から復元されました: ${AppLogger.maskName(currentUserName)}');
      return currentUserName;
    }

    // 設定にユーザー名がない場合、グループから読み込み
    Log.info('⚠️ 設定にユーザー名がないため、グループから読み込み');
    final groupManagement = _ref.read(groupManagementServiceProvider);
    final userNameFromGroup =
        await groupManagement.loadUserNameFromDefaultGroup();

    if (userNameFromGroup != null && userNameFromGroup.isNotEmpty) {
      Log.info(
          '✅ ユーザー名がグループから復元されました: ${AppLogger.maskName(userNameFromGroup)}');
      return userNameFromGroup;
    }

    Log.info('⚠️ ユーザー名を復元できませんでした');
    return null;
  }

  /// ユーザー名を保存
  ///
  /// 保存先:
  /// 1. SharedPreferences
  /// 2. Firestore (UserNameNotifier経由)
  /// 3. 全グループのメンバー情報
  Future<void> saveUserName({
    required String userName,
    required String userEmail,
  }) async {
    if (userName.isEmpty) {
      Log.warning('⚠️ 空のユーザー名は保存できません');
      return;
    }

    Log.info('💾 ユーザー名保存開始: ${AppLogger.maskName(userName)}');

    try {
      // 1. SharedPreferences + Firestoreに保存
      await UserPreferencesService.saveUserName(userName);
      Log.info('✅ SharedPreferences + Firestoreに保存完了');

      // 2. 全グループのメンバー情報を更新
      final groupManagement = _ref.read(groupManagementServiceProvider);
      await groupManagement.updateUserNameInAllGroups(userName, userEmail);
      Log.info('✅ 全グループのメンバー情報更新完了');

      Log.info('✅ ユーザー名保存完了: ${AppLogger.maskName(userName)}');
    } catch (e) {
      Log.error('❌ ユーザー名保存エラー: $e');
      rethrow;
    }
  }

  /// ユーザー名をクリア
  Future<void> clearUserName() async {
    await ErrorHandler.handleAsync(
      operation: () async {
        await UserPreferencesService.saveUserName('');
        Log.info('🗑️ ユーザー名をクリアしました');
      },
      context: 'USER_NAME_INIT:clearUserName',
      defaultValue: null,
    );
  }

  /// 現在のユーザー名を取得
  Future<String?> getCurrentUserName() async {
    return await UserPreferencesService.getUserName();
  }
}
