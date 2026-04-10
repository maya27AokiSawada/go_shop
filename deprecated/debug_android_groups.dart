import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'lib/models/shared_group.dart';

/// Androidでグループが表示されない問題を調査するスクリプト
Future<void> main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(SharedGroupAdapter());
  Hive.registerAdapter(SharedGroupMemberAdapter());
  Hive.registerAdapter(SharedGroupRoleAdapter());

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final currentUser = auth.currentUser;

  print('========== グループ調査開始 ==========');
  print('現在のユーザー: ${currentUser?.email} (UID: ${currentUser?.uid})');
  print('');

  // 1. Hiveの内容確認
  print('--- Hive (ローカル) ---');
  final hiveBox = await Hive.openBox<SharedGroup>('SharedGroupBox');
  print('Hiveのグループ数: ${hiveBox.length}');
  for (var i = 0; i < hiveBox.length; i++) {
    final group = hiveBox.getAt(i);
    if (group != null) {
      print('  - ${group.groupName} (ID: ${group.groupId})');
      print('    allowedUid: ${group.allowedUid}');
      print('    syncStatus: ${group.syncStatus}');
    }
  }
  print('');

  // 2. Firestoreの内容確認
  print('--- Firestore (リモート) ---');
  try {
    final snapshot = await firestore.collection('SharedGroups').get();
    print('Firestoreのグループ数: ${snapshot.docs.length}');

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final allowedUid = List<String>.from(data['allowedUid'] ?? []);
      final isAccessible = allowedUid.contains(currentUser?.uid);

      print('  - ${data['groupName']} (ID: ${doc.id})');
      print('    ownerUid: ${data['ownerUid']}');
      print('    allowedUid: $allowedUid');
      print('    アクセス可能: $isAccessible');
    }
  } catch (e) {
    print('Firestore読み取りエラー: $e');
  }
  print('');

  // 3. mayaのUIDで検索
  if (currentUser != null) {
    print('--- mayaのUIDでグループ検索 ---');
    try {
      final myGroups = await firestore
          .collection('SharedGroups')
          .where('allowedUid', arrayContains: currentUser.uid)
          .get();

      print('検索結果: ${myGroups.docs.length}件');
      for (var doc in myGroups.docs) {
        print('  - ${doc.data()['groupName']} (ID: ${doc.id})');
      }
    } catch (e) {
      print('検索エラー: $e');
    }
  }

  print('========== 調査完了 ==========');
}
