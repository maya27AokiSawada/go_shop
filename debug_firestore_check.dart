import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

/// Firestoreのデータを確認するデバッグスクリプト
///
/// 使い方:
/// dart run debug_firestore_check.dart
void main() async {
  print('🔍 Firestoreデータ確認スクリプト起動...');

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('\n📊 全SharedGroupsを確認:');
  print('=' * 80);

  try {
    final groupsSnapshot = await firestore.collection('SharedGroups').get();

    if (groupsSnapshot.docs.isEmpty) {
      print('⚠️ グループが存在しません');
      return;
    }

    for (var doc in groupsSnapshot.docs) {
      final data = doc.data();
      print('\n🔹 グループID: ${doc.id}');
      print('  グループ名: ${data['groupName']}');
      print('  オーナーUID: ${data['ownerUid']}');
      print('  オーナー名: ${data['ownerName']}');

      // allowedUidsの表示
      final allowedUids = data['allowedUids'] as List?;
      print('  許可UID数: ${allowedUids?.length ?? 0}');
      if (allowedUids != null) {
        for (var uid in allowedUids) {
          print('    - $uid');
        }
      }

      // membersの表示
      final members = data['members'] as List?;
      print('  メンバー数: ${members?.length ?? 0}');
      if (members != null) {
        for (var member in members) {
          if (member is Map) {
            print('    - 名前: ${member['name']}');
            print('      UID: ${member['memberId']}');
            print('      役割: ${member['role']}');
            print('      サインイン: ${member['isSignedIn']}');
          }
        }
      }

      // 更新日時
      final updatedAt = data['updatedAt'] as Timestamp?;
      if (updatedAt != null) {
        print('  更新日時: ${updatedAt.toDate()}');
      }

      print('-' * 80);
    }

    // 通知も確認
    print('\n\n📬 最近の通知を確認:');
    print('=' * 80);

    final notificationsSnapshot = await firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    if (notificationsSnapshot.docs.isEmpty) {
      print('⚠️ 通知が存在しません');
    } else {
      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        print('\n🔔 通知ID: ${doc.id}');
        print('  タイプ: ${data['type']}');
        print('  対象UID: ${data['userId']}');
        print('  グループID: ${data['groupId']}');
        print('  メッセージ: ${data['message']}');
        print('  既読: ${data['read']}');
        print('  日時: $timestamp');
        print('-' * 40);
      }
    }
  } catch (e, stackTrace) {
    print('❌ エラー発生: $e');
    print(stackTrace);
  }

  print('\n✅ 確認完了');
}
