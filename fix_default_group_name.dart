import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'lib/firebase_options.dart';
import 'lib/models/shared_group.dart';

void main() async {
  print('🔧 デフォルトグループ名修正スクリプト開始');

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive初期化
  await Hive.initFlutter();
  Hive.registerAdapter(SharedGroupAdapter());
  Hive.registerAdapter(SharedGroupMemberAdapter());
  Hive.registerAdapter(SharedGroupRoleAdapter());
  Hive.registerAdapter(SyncStatusAdapter());
  Hive.registerAdapter(InvitationStatusAdapter());

  final SharedGroupBox = await Hive.openBox<SharedGroup>('SharedGroups');

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print('❌ ユーザーが認証されていません');
    return;
  }

  print('✅ 現在のユーザー:');
  print('  - UID: ${currentUser.uid}');
  print('  - Email: ${currentUser.email}');
  print('  - DisplayName: ${currentUser.displayName}');
  print('');

  // デフォルトグループを検索
  SharedGroup? defaultGroup;
  for (var group in SharedGroupBox.values) {
    if (group.groupId == currentUser.uid) {
      defaultGroup = group;
      break;
    }
  }

  if (defaultGroup == null) {
    print('❌ デフォルトグループが見つかりません');
    return;
  }

  print('📋 現在のデフォルトグループ:');
  print('  - groupId: ${defaultGroup.groupId}');
  print('  - groupName: ${defaultGroup.groupName}');
  print('  - ownerName: ${defaultGroup.ownerName}');
  print('');

  // ユーザー名を取得（SharedPreferencesまたはFirestore）
  final userName =
      currentUser.displayName ?? currentUser.email?.split('@').first ?? 'ユーザー';
  final newGroupName = '$userNameグループ';

  print('🔄 グループ名を更新:');
  print('  - 旧: ${defaultGroup.groupName}');
  print('  - 新: $newGroupName');

  // グループ名を更新
  final updatedGroup = defaultGroup.copyWith(
    groupName: newGroupName,
    ownerName: userName,
  );

  await SharedGroupBox.put(currentUser.uid, updatedGroup);

  print('✅ デフォルトグループ名を更新しました！');
  print('');
  print('📋 更新後のデフォルトグループ:');
  print('  - groupId: ${updatedGroup.groupId}');
  print('  - groupName: ${updatedGroup.groupName}');
  print('  - ownerName: ${updatedGroup.ownerName}');

  await Hive.close();
  print('✅ 完了');
}
