// デバッグ用スクリプト - グループデータを確認

import 'package:hive_flutter/hive_flutter.dart';
import 'lib/models/shared_group.dart';
import 'lib/models/shopping_list.dart';
import 'lib/models/user_settings.dart';
// import 'lib/models/invitation.dart';  // 削除済み - QRコードシステムに移行
// import 'lib/models/accepted_invitation.dart';  // 削除済み - QRコードシステムに移行
import 'lib/utils/app_logger.dart';

void main() async {
  Log.info('🔍 グループデータ診断開始...');

  try {
    // Hive初期化
    await Hive.initFlutter();

    // アダプター登録
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SharedGroupRoleAdapter());
      Hive.registerAdapter(SharedGroupMemberAdapter());
      Hive.registerAdapter(SharedGroupAdapter());
      Hive.registerAdapter(ShoppingItemAdapter());
      Hive.registerAdapter(ShoppingListAdapter());
      // Hive.registerAdapter(InvitationAdapter());  // 削除済み - QRコードシステムに移行
      // Hive.registerAdapter(AcceptedInvitationAdapter());  // 削除済み - QRコードシステムに移行
      Hive.registerAdapter(UserSettingsAdapter());
    }

    // SharedGroup Boxを開く
    final box = await Hive.openBox<SharedGroup>('SharedGroups');

    Log.info('📦 Box状態: ${box.isOpen ? "開いている" : "閉じている"}');
    Log.info('📊 保存されているキー数: ${box.keys.length}');
    Log.info('📋 キー一覧: ${box.keys.toList()}');

    // 各グループの詳細を表示
    for (final key in box.keys) {
      final group = box.get(key);
      if (group != null) {
        Log.info('');
        Log.info('🏷️  グループID: ${group.groupId}');
        Log.info('📝 グループ名: ${group.groupName}');
        Log.info('👥 メンバー数: ${group.members?.length ?? 0}');
        if (group.members?.isNotEmpty == true) {
          for (final member in group.members!) {
            Log.info(
                '   - ${member.name} (${member.role.name}, ID: ${member.memberId})');
          }
        }
        // 作成日はSharedGroupモデルに存在しない場合があります
        // Log.info('📅 作成日: ${group.createdAt}');
      }
    }

    // defaultGroupが存在するかチェック
    final defaultGroup = box.get('defaultGroup');
    if (defaultGroup != null) {
      Log.info('');
      Log.info('✅ defaultGroupが見つかりました');
    } else {
      Log.info('');
      Log.error('❌ defaultGroupが見つかりません - 作成が必要です');
    }

    await box.close();
  } catch (e, stackTrace) {
    Log.error('❌ エラー発生: $e');
    Log.info('📍 スタック: $stackTrace');
  }

  Log.info('🔍 診断完了');
}
