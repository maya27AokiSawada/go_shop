import 'package:hive_flutter/hive_flutter.dart';
import 'lib/models/shared_group.dart';

/// mayaのデフォルトグループを正しいFirebase UIDに修正
Future<void> main() async {
  await Hive.initFlutter();

  // Hiveアダプター登録
  Hive.registerAdapter(SharedGroupAdapter());
  Hive.registerAdapter(SharedGroupMemberAdapter());
  Hive.registerAdapter(SharedGroupRoleAdapter());

  // Boxを開く
  final box = await Hive.openBox<SharedGroup>('purchase_groups');

  print('===== グループ一覧 =====');
  for (var i = 0; i < box.length; i++) {
    final group = box.getAt(i);
    if (group != null) {
      print('グループ名: ${group.groupName}');
      print('groupId: ${group.groupId}');
      print('members: ${group.members?.length ?? 0}人');

      if (group.members != null && group.members!.isNotEmpty) {
        final owner = group.members!.first;
        print('  オーナー: ${owner.name}');
        print('  memberId: ${owner.memberId}');

        // mayaのデフォルトグループを検出（誤ったmemberIdまたはgroupId）
        if (owner.memberId == '831f3be8-0daf-43da-98e4-1bda6d55621c' ||
            group.groupId == 'default_group' ||
            (group.groupName.contains('maya') &&
                group.groupId != 'VqNEozvTyXXw55Q46mNiGNMNngw2')) {
          print('\n⚠️ デフォルトグループの修正が必要です！');
          print('  現在のgroupId: ${group.groupId}');
          print('  現在のmemberId: ${owner.memberId}');
          print('  現在のsyncStatus: ${group.syncStatus}');

          // 正しいFirebase UIDに修正
          final correctedMember = owner.copyWith(
            memberId: 'VqNEozvTyXXw55Q46mNiGNMNngw2',
          );

          final correctedMembers = [
            correctedMember,
            ...group.members!.skip(1),
          ];

          final correctedGroup = group.copyWith(
            groupId: 'VqNEozvTyXXw55Q46mNiGNMNngw2', // user.uidと同じ
            members: correctedMembers,
            syncStatus: SyncStatus.synced, // Firestoreに同期する
          );

          await box.putAt(i, correctedGroup);
          print('✅ 修正完了:');
          print('  新しいgroupId: VqNEozvTyXXw55Q46mNiGNMNngw2');
          print('  新しいmemberId: VqNEozvTyXXw55Q46mNiGNMNngw2');
          print('  新しいsyncStatus: synced');
          print('\n⚠️ 次のステップ: アプリを再起動してFirestoreに同期してください');
        }
      }
      print('---');
    }
  }

  print('\n===== 修正後の確認 =====');
  for (var i = 0; i < box.length; i++) {
    final group = box.getAt(i);
    if (group != null && group.members != null && group.members!.isNotEmpty) {
      print('${group.groupName}:');
      print('  groupId: ${group.groupId}');
      print('  memberId: ${group.members!.first.memberId}');
      print('  syncStatus: ${group.syncStatus}');
    }
  }

  await box.close();
  print('\n処理完了');
}
