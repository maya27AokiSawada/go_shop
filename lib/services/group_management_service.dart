// lib/services/group_management_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_name_provider.dart';
import 'user_preferences_service.dart';

final groupManagementServiceProvider = Provider<GroupManagementService>((ref) {
  return GroupManagementService(ref);
});

/// グループ関連の処理を管理するサービス
class GroupManagementService {
  final Ref _ref;

  GroupManagementService(this._ref);

  /// デフォルトグループからユーザー名を読み込む
  ///
  /// 優先順位:
  /// 1. ownerメンバー
  /// 2. メールアドレスが一致するメンバー（ログイン時）
  /// 3. 最初のメンバー
  Future<String?> loadUserNameFromDefaultGroup() async {
    Log.info('🔍 loadUserNameFromDefaultGroup 開始');

    try {
      final purchaseGroupAsync = _ref.read(selectedGroupProvider);
      final currentUserName = await UserPreferencesService.getUserName();

      Log.info('📊 現在のSharedPreferences userName: $currentUserName');

      return await purchaseGroupAsync.when(
        data: (group) async {
          if (group == null) {
            Log.info('⚠️ グループが見つかりません');
            return null;
          }

          Log.info('📋 グループデータ取得成功: ${group.groupName}');
          Log.info('👥 メンバー数: ${group.members?.length ?? 0}');

          if (group.members != null) {
            for (var i = 0; i < group.members!.length; i++) {
              final member = group.members![i];
              Log.info(
                  '👤 メンバー$i: ${member.name} (${member.role}) - ${member.contact}');
            }
          }

          if (group.members == null || group.members!.isEmpty) {
            Log.info('⚠️ メンバーがいません');
            return null;
          }

          // 認証状態を取得
          final authState = _ref.read(authStateProvider);
          final user = await authState.when(
            data: (user) async => user,
            loading: () async => null,
            error: (err, stack) async {
              Log.info('❌ 認証エラー: $err');
              return null;
            },
          );

          Log.info('🔐 認証ユーザー: ${user?.email ?? "null"}');

          // ownerを優先して探す
          var currentMember = group.members!.firstWhere(
            (member) => member.role == PurchaseGroupRole.owner,
            orElse: () {
              Log.info('⚠️ ownerが見つからないので最初のメンバーを使用');
              return group.members!.first;
            },
          );

          Log.info(
              '🏆 選択されたメンバー: ${currentMember.name} (${currentMember.role})');

          // ログイン済みの場合のみメールアドレスでマッチするメンバーを再検索
          final userEmail = user?.email;
          if (user != null &&
              currentMember.contact != userEmail &&
              userEmail != null) {
            Log.info('📬 メールアドレスでメンバーを再検索: $userEmail');
            final emailMatchMember = group.members!.firstWhere(
              (member) => member.contact == userEmail,
              orElse: () {
                Log.info('📬 メールアドレスマッチなし、ownerを使用');
                return currentMember;
              },
            );
            if (emailMatchMember.name.isNotEmpty) {
              Log.info('📬 メールマッチメンバーを使用: ${emailMatchMember.name}');
              currentMember = emailMatchMember;
            }
          }

          if (currentMember.name.isNotEmpty) {
            Log.info('✅ ユーザー名をプロバイダーに設定: ${currentMember.name}');
            await _ref
                .read(userNameNotifierProvider.notifier)
                .setUserName(currentMember.name);
            return currentMember.name;
          } else {
            Log.info('⚠️ メンバー名が空です');
            return null;
          }
        },
        loading: () async {
          Log.info('🔄 グループデータロード中...');
          return null;
        },
        error: (err, stack) async {
          Log.info('❌ グループエラー: $err');
          return null;
        },
      );
    } catch (e) {
      Log.info('❌ ユーザー名の読み込みに失敗: $e');
      return null;
    } finally {
      Log.info('🏁 loadUserNameFromDefaultGroup 終了');
    }
  }

  /// 全グループのユーザー名を更新
  ///
  /// 更新条件:
  /// 1. メールアドレスが一致
  /// 2. デフォルトユーザー（memberId: defaultUser）
  /// 3. 現在のログインユーザーのUIDと一致
  Future<void> updateUserNameInAllGroups(
      String newUserName, String userEmail) async {
    try {
      Log.info(
          '🌍 updateUserNameInAllGroups開始: 名前="$newUserName", メール="$userEmail"');

      // 現在のログインユーザーのUIDを取得
      final authState = _ref.read(authStateProvider);
      final currentUserId = authState.when(
        data: (user) => user?.uid ?? '',
        loading: () => '',
        error: (_, __) => '',
      );
      Log.info('🔐 現在のユーザーID: $currentUserId');

      // 全グループを取得
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      final allGroups = await repository.getAllGroups();
      Log.info('🌍 全グループ取得完了: ${allGroups.length}個のグループ');

      for (final group in allGroups) {
        Log.info(
            '🔍 グループ "${group.groupName}" (ID: ${group.groupId}) をチェック中...');

        bool groupUpdated = false;
        final updatedMembers = <PurchaseGroupMember>[];

        // 各メンバーをチェック
        for (final member in group.members ?? []) {
          bool shouldUpdate = false;

          // 1. メールアドレスが一致する場合
          if (member.contact == userEmail && userEmail.isNotEmpty) {
            shouldUpdate = true;
            Log.info(
                '📧 メールアドレス一致: ${member.name} → $newUserName (メール: ${member.contact})');
          }

          // 2. デフォルトユーザーの場合（UID: defaultUser）
          if (member.memberId == 'defaultUser') {
            shouldUpdate = true;
            Log.info(
                '🆔 デフォルトユーザー: ${member.name} → $newUserName (ID: ${member.memberId})');
          }

          // 3. 現在のログインユーザーのUIDと一致する場合
          if (currentUserId.isNotEmpty && member.memberId == currentUserId) {
            shouldUpdate = true;
            Log.info(
                '🔐 UID一致: ${member.name} → $newUserName (UID: ${member.memberId})');
          }

          if (shouldUpdate && member.name != newUserName) {
            // メンバー名を更新
            final updatedMember = member.copyWith(name: newUserName);
            updatedMembers.add(updatedMember);
            groupUpdated = true;
            Log.info(
                '✅ メンバー更新: ${member.name} → $newUserName (グループ: ${group.groupName})');
          } else {
            // 更新不要、そのまま追加
            updatedMembers.add(member);
          }
        }

        // グループが更新された場合のみ保存
        if (groupUpdated) {
          final updatedGroup = group.copyWith(
            members: updatedMembers,
            // オーナー情報も更新（オーナーが変更対象の場合）
            ownerName: group.ownerEmail == userEmail ||
                    group.ownerUid == 'defaultUser' ||
                    group.ownerUid == currentUserId
                ? newUserName
                : group.ownerName,
          );

          await repository.updateGroup(group.groupId, updatedGroup);
          Log.info('💾 グループ "${group.groupName}" を更新しました');
        } else {
          Log.info('⏭️ グループ "${group.groupName}" は更新不要');
        }
      }

      Log.info('✅ updateUserNameInAllGroups完了');
    } catch (e) {
      Log.error('❌ updateUserNameInAllGroups エラー: $e');
      rethrow;
    }
  }

  /// 特定のグループからユーザー名を取得
  ///
  /// 取得条件:
  /// 1. メールアドレスが一致するメンバー
  /// 2. UIDが一致するメンバー
  Future<String?> getUserNameFromGroup({
    required String groupId,
    String? userEmail,
    String? userId,
  }) async {
    try {
      Log.info(
          '🔍 getUserNameFromGroup開始: groupId=$groupId, email=$userEmail, uid=$userId');

      final repository = _ref.read(purchaseGroupRepositoryProvider);
      final group = await repository.getGroupById(groupId);

      if (group.members == null || group.members!.isEmpty) {
        Log.info('⚠️ グループにメンバーがいません');
        return null;
      }

      // 1. メールアドレスで検索
      if (userEmail != null && userEmail.isNotEmpty) {
        final memberByEmail = group.members!.firstWhere(
          (member) => member.contact == userEmail,
          orElse: () => PurchaseGroupMember.create(
            memberId: '',
            name: '',
            contact: '',
            role: PurchaseGroupRole.member,
          ),
        );

        if (memberByEmail.name.isNotEmpty) {
          Log.info('📧 メールアドレスでメンバー発見: ${memberByEmail.name}');
          return memberByEmail.name;
        }
      }

      // 2. UIDで検索
      if (userId != null && userId.isNotEmpty) {
        final memberByUid = group.members!.firstWhere(
          (member) => member.memberId == userId,
          orElse: () => PurchaseGroupMember.create(
            memberId: '',
            name: '',
            contact: '',
            role: PurchaseGroupRole.member,
          ),
        );

        if (memberByUid.name.isNotEmpty) {
          Log.info('🔐 UIDでメンバー発見: ${memberByUid.name}');
          return memberByUid.name;
        }
      }

      Log.info('⚠️ 条件に一致するメンバーが見つかりません');
      return null;
    } catch (e) {
      Log.error('❌ getUserNameFromGroup エラー: $e');
      return null;
    }
  }

  /// グループの全メンバーを取得
  Future<List<PurchaseGroupMember>> getGroupMembers(String groupId) async {
    try {
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      final group = await repository.getGroupById(groupId);
      return group.members ?? [];
    } catch (e) {
      Log.error('❌ getGroupMembers エラー: $e');
      return [];
    }
  }

  /// 現在選択中のグループを取得
  Future<PurchaseGroup?> getCurrentGroup() async {
    final groupAsync = _ref.read(selectedGroupProvider);
    return await groupAsync.when(
      data: (group) async => group,
      loading: () async => null,
      error: (err, stack) async {
        Log.error('❌ getCurrentGroup エラー: $err');
        return null;
      },
    );
  }
}
