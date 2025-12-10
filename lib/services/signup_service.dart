// lib/services/signup_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/app_logger.dart';
import '../models/shared_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_name_provider.dart';
import '../datastore/hybrid_purchase_group_repository.dart';
import 'user_preferences_service.dart';

/// サインアップ時のデータ移行を処理するサービス
class SignupService {
  final Ref _ref;

  SignupService(this._ref);

  /// サインアップ処理のメイン実行
  ///
  /// Returns: 処理が成功したかどうか
  Future<bool> processSignup({
    required User user,
    String? displayName,
  }) async {
    try {
      Log.info('🔄 [SIGNUP_SERVICE] サインアップ処理開始: ${user.email}');

      // STEP1: ユーザープロフィール設定
      await _setupUserProfile(user, displayName);

      // STEP2: ローカルデフォルトグループの検出
      final localDefaultGroup = await _detectLocalDefaultGroup();

      // STEP3: Firebase形式のデフォルトグループ作成
      final firebaseGroupId = await _createFirebaseDefaultGroup(user);

      // STEP4: ローカルデータの移行（存在する場合）
      if (localDefaultGroup != null) {
        await _migrateLocalData(localDefaultGroup, firebaseGroupId, user);
      }

      // STEP5: プロバイダーの更新
      await _refreshProviders();

      Log.info('✅ [SIGNUP_SERVICE] サインアップ処理完了');
      return true;
    } catch (e, stackTrace) {
      Log.error('❌ [SIGNUP_SERVICE] サインアップ処理エラー: $e');
      Log.error('❌ [SIGNUP_SERVICE] スタックトレース: $stackTrace');
      return false;
    }
  }

  /// ユーザープロフィールの設定
  Future<void> _setupUserProfile(User user, String? displayName) async {
    String finalDisplayName = displayName ?? user.displayName ?? 'ユーザー';

    // ユーザー名の優先順位決定
    try {
      final prefsName = await _ref
          .read(userNameNotifierProvider.notifier)
          .restoreUserNameFromPreferences();

      if (prefsName == null || prefsName.isEmpty || prefsName == 'あなた') {
        // Firebase優先
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          finalDisplayName = user.displayName!;
        }
        await _ref
            .read(userNameNotifierProvider.notifier)
            .setUserName(finalDisplayName);
      } else {
        // プリファレンス優先
        finalDisplayName = prefsName;
        await user.updateDisplayName(finalDisplayName);
        await user.reload();
      }
    } catch (e) {
      Log.warning('⚠️ [SIGNUP_SERVICE] ユーザー名決定エラー: $e');
    }

    // メールアドレスをSharedPreferencesに保存
    if (user.email != null && user.email!.isNotEmpty) {
      await UserPreferencesService.saveUserEmail(user.email!);
    }

    Log.info(
        '✅ [SIGNUP_SERVICE] ユーザープロファイル設定完了: ${AppLogger.maskName(finalDisplayName)}');
  }

  /// ローカルデフォルトグループの検出
  Future<SharedGroup?> _detectLocalDefaultGroup() async {
    try {
      final repository = _ref.read(SharedGroupRepositoryProvider);
      if (repository is HybridSharedGroupRepository) {
        final allGroups = await repository.getLocalGroups();
        return allGroups.where((g) => g.groupId == 'default_group').firstOrNull;
      }
    } catch (e) {
      Log.warning('⚠️ [SIGNUP_SERVICE] ローカルデータ検出エラー: $e');
    }
    return null;
  }

  /// Firebase形式のデフォルトグループ作成
  Future<String> _createFirebaseDefaultGroup(User user) async {
    final repository = _ref.read(SharedGroupRepositoryProvider);
    final newGroupId = 'default_${user.uid}';

    // 既存チェック
    try {
      await repository.getGroupById(newGroupId);
      return newGroupId; // 既に存在する場合
    } catch (e) {
      // 存在しない場合は作成
    }

    // オーナーメンバーを作成
    final ownerMember = SharedGroupMember.create(
      memberId: user.uid,
      name: user.displayName ?? 'ユーザー',
      contact: user.email ?? '',
      role: SharedGroupRole.owner,
      isSignedIn: true,
    );

    // デフォルトグループを作成
    await repository.createGroup(newGroupId, 'My Lists', ownerMember);

    Log.info('✅ [SIGNUP_SERVICE] Firebaseデフォルトグループ作成: $newGroupId');
    return newGroupId;
  }

  /// ローカルデータの移行
  Future<void> _migrateLocalData(
    SharedGroup localDefaultGroup,
    String newGroupId,
    User user,
  ) async {
    final repository = _ref.read(SharedGroupRepositoryProvider);

    // メンバーの移行（オーナーのmemberIdをFirebase UIDに変更）
    final migratedMembers = <SharedGroupMember>[];
    for (final member in localDefaultGroup.members ?? []) {
      if (member.role == SharedGroupRole.owner) {
        final updatedOwner = member.copyWith(
          memberId: user.uid,
          name: user.displayName ?? member.name,
          contact: user.email ?? member.contact,
          isSignedIn: true,
        );
        migratedMembers.add(updatedOwner);
      } else {
        migratedMembers.add(member);
      }
    }

    // グループの更新
    final migratedGroup = localDefaultGroup.copyWith(
      groupId: newGroupId,
      groupName: 'My Lists',
      members: migratedMembers,
      ownerUid: user.uid,
    );

    await repository.updateGroup(newGroupId, migratedGroup);

    // デフォルトグループのownerメンバーIDをFirebase UIDに更新
    try {
      final defaultGroup = await repository.getGroupById('default_group');
      final updatedMembers = defaultGroup.members?.map((member) {
            if (member.role == SharedGroupRole.owner) {
              return member.copyWith(memberId: user.uid);
            }
            return member;
          }).toList() ??
          [];

      final updatedDefaultGroup = defaultGroup.copyWith(
        members: updatedMembers,
        ownerUid: user.uid,
      );

      await repository.updateGroup('default_group', updatedDefaultGroup);
      Log.info('✅ [SIGNUP_SERVICE] デフォルトグループのownerメンバーIDをFirebase UIDに更新完了');
    } catch (e) {
      Log.warning('⚠️ [SIGNUP_SERVICE] デフォルトグループ更新エラー: $e');
    }

    Log.info('✅ [SIGNUP_SERVICE] ローカルデータ移行完了');
  }

  /// プロバイダーの更新
  Future<void> _refreshProviders() async {
    _ref.invalidate(allGroupsProvider);
    _ref.invalidate(userNameProvider);

    // 少し待って更新を確実に
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// サインアップサービスのプロバイダー
final signupServiceProvider = Provider<SignupService>((ref) {
  return SignupService(ref);
});
