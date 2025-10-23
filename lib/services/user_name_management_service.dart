// lib/services/user_name_management_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import 'user_preferences_service.dart';
import 'firestore_user_name_service.dart';
import '../models/purchase_group.dart';
import '../providers/user_name_provider.dart';
import '../flavors.dart';

/// ユーザー名の保存・復帰・更新を統合管理するサービス
class UserNameManagementService {
  /// ユーザー名を保存（SharedPreferences + Firestore）
  static Future<bool> saveUserName(String userName, WidgetRef ref) async {
    try {
      Log.info('💾 ユーザー名保存開始: $userName');

      // UserNameNotifierを使用してSharedPreferences + Firestoreに保存
      await ref.read(userNameNotifierProvider.notifier).setUserName(userName);

      Log.info('✅ ユーザー名保存完了');
      return true;
    } catch (e) {
      Log.error('❌ ユーザー名保存エラー: $e');
      return false;
    }
  }

  /// ユーザー名を復帰（SharedPreferences → Firestore → グループデータの順）
  static Future<String?> restoreUserName({
    required WidgetRef ref,
    String? userId,
    String? userEmail,
  }) async {
    try {
      Log.info('🔄 ユーザー名復帰開始: UID=$userId, Email=$userEmail');

      // 1. SharedPreferencesから復帰
      final prefsName = await UserPreferencesService.getUserName();
      if (prefsName != null && prefsName.isNotEmpty) {
        Log.info('✅ SharedPreferencesからユーザー名復帰: $prefsName');
        return prefsName;
      }

      // 2. Firestoreから復帰（サインイン時のみ）
      if (userId != null && F.appFlavor == Flavor.prod) {
        final firestoreName = await FirestoreUserNameService.getUserName();
        if (firestoreName != null && firestoreName.isNotEmpty) {
          // Firestoreから取得した名前をSharedPreferencesにも保存
          await UserPreferencesService.saveUserName(firestoreName);
          Log.info('✅ Firestoreからユーザー名復帰: $firestoreName');
          return firestoreName;
        }
      }

      Log.info('ℹ️ 復帰可能なユーザー名が見つかりませんでした');
      return null;
    } catch (e) {
      Log.error('❌ ユーザー名復帰エラー: $e');
      return null;
    }
  }

  /// グループデータからユーザー名を取得
  static String? getUserNameFromGroup({
    required PurchaseGroup group,
    String? userId,
    String? userEmail,
  }) {
    try {
      if (group.members == null || group.members!.isEmpty) {
        Log.info('⚠️ グループにメンバーがいません');
        return null;
      }

      // ownerを優先して探す
      var currentMember = group.members!.firstWhere(
        (member) => member.role == PurchaseGroupRole.owner,
        orElse: () {
          Log.info('⚠️ ownerが見つからないので最初のメンバーを使用');
          return group.members!.first;
        },
      );

      // ログイン済みの場合、メールアドレスまたはUIDでマッチするメンバーを再検索
      if (userId != null || userEmail != null) {
        final matchedMember = group.members!.firstWhere(
          (member) =>
              (userId != null && member.memberId == userId) ||
              (userEmail != null && member.contact == userEmail),
          orElse: () => currentMember,
        );

        if (matchedMember.name.isNotEmpty) {
          currentMember = matchedMember;
        }
      }

      if (currentMember.name.isNotEmpty) {
        Log.info('✅ グループからユーザー名取得: ${currentMember.name}');
        return currentMember.name;
      }

      return null;
    } catch (e) {
      Log.error('❌ グループからユーザー名取得エラー: $e');
      return null;
    }
  }

  /// 全グループで同じUID/メールアドレスのメンバー名を更新
  static Future<void> updateUserNameInAllGroups({
    required String newUserName,
    required String userEmail,
    required List<PurchaseGroup> groups,
  }) async {
    try {
      Log.info('🌍 全グループのユーザー名更新開始: 名前="$newUserName", メール="$userEmail"');

      int updatedCount = 0;

      for (final group in groups) {
        if (group.members == null) continue;

        bool groupModified = false;
        final updatedMembers = group.members!.map((member) {
          if (member.contact == userEmail && member.name != newUserName) {
            Log.info(
                '  📝 グループ[${group.groupName}]のメンバー[${member.name}]を[$newUserName]に更新');
            groupModified = true;
            return member.copyWith(name: newUserName);
          }
          return member;
        }).toList();

        if (groupModified) {
          updatedCount++;
          Log.info(
              '  グループ[${group.groupName}]の更新メンバー数: ${updatedMembers.length}');
          // TODO: グループデータをHive/Firestoreに保存
          // await groupRepository.updateGroup(group.copyWith(members: updatedMembers));
        }
      }

      Log.info('✅ 全グループ更新完了: $updatedCount件のグループを更新');
    } catch (e) {
      Log.error('❌ 全グループ更新エラー: $e');
    }
  }
}
