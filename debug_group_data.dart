// デバッグ用スクリプト - グループデータを確認

import 'package:hive_flutter/hive_flutter.dart';
import 'lib/models/purchase_group.dart';
import 'lib/models/shopping_list.dart';
import 'lib/models/user_settings.dart';
import 'lib/models/invitation.dart';
import 'lib/models/accepted_invitation.dart';

void main() async {
  print('🔍 グループデータ診断開始...');
  
  try {
    // Hive初期化
    await Hive.initFlutter();
    
    // アダプター登録
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PurchaseGroupRoleAdapter());
      Hive.registerAdapter(PurchaseGroupMemberAdapter());
      Hive.registerAdapter(PurchaseGroupAdapter());
      Hive.registerAdapter(ShoppingItemAdapter());
      Hive.registerAdapter(ShoppingListAdapter());
      Hive.registerAdapter(InvitationAdapter());
      Hive.registerAdapter(AcceptedInvitationAdapter());
      Hive.registerAdapter(UserSettingsAdapter());
    }
    
    // PurchaseGroup Boxを開く
    final box = await Hive.openBox<PurchaseGroup>('purchaseGroups');
    
    print('📦 Box状態: ${box.isOpen ? "開いている" : "閉じている"}');
    print('📊 保存されているキー数: ${box.keys.length}');
    print('📋 キー一覧: ${box.keys.toList()}');
    
    // 各グループの詳細を表示
    for (final key in box.keys) {
      final group = box.get(key);
      if (group != null) {
        print('');
        print('🏷️  グループID: ${group.groupId}');
        print('📝 グループ名: ${group.groupName}');
        print('👥 メンバー数: ${group.members?.length ?? 0}');
        if (group.members?.isNotEmpty == true) {
          for (final member in group.members!) {
            print('   - ${member.name} (${member.role.name}, ID: ${member.memberId})');
          }
        }
        print('📅 作成日: ${group.createdAt}');
      }
    }
    
    // defaultGroupが存在するかチェック
    final defaultGroup = box.get('defaultGroup');
    if (defaultGroup != null) {
      print('');
      print('✅ defaultGroupが見つかりました');
    } else {
      print('');
      print('❌ defaultGroupが見つかりません - 作成が必要です');
    }
    
    await box.close();
    
  } catch (e, stackTrace) {
    print('❌ エラー発生: $e');
    print('📍 スタック: $stackTrace');
  }
  
  print('🔍 診断完了');
}