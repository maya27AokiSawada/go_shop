// すももユーザーのFirestoreデータ確認スクリプト
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  // Firebase初期化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  const sumomoUid = 'K35DAuQUktfhSr4XWFoAtBNL32E3';

  print('🔍 すももユーザーのFirestoreデータ確認');
  print('UID: $sumomoUid\n');

  // 1. ユーザープロファイル確認
  print('=== 1. ユーザープロファイル ===');
  try {
    final userDoc = await firestore.collection('users').doc(sumomoUid).get();
    if (userDoc.exists) {
      print('✅ ユーザードキュメント存在');
      print('データ: ${userDoc.data()}');
    } else {
      print('❌ ユーザードキュメント不在');
    }
  } catch (e) {
    print('⚠️ エラー: $e');
  }

  // 2. allowedUidでグループ検索
  print('\n=== 2. allowedUidでグループ検索 ===');
  try {
    final groupsSnapshot = await firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: sumomoUid)
        .get();

    print('検索結果: ${groupsSnapshot.docs.length}件');
    for (final doc in groupsSnapshot.docs) {
      final data = doc.data();
      print('\nグループID: ${doc.id}');
      print('  groupName: ${data['groupName']}');
      print('  ownerUid: ${data['ownerUid']}');
      print('  allowedUid: ${data['allowedUid']}');
      print('  isDeleted: ${data['isDeleted']}');
    }
  } catch (e) {
    print('⚠️ エラー: $e');
  }

  // 3. デフォルトグループ(groupId=UID)の直接確認
  print('\n=== 3. デフォルトグループ(groupId=UID)確認 ===');
  try {
    final defaultGroupDoc =
        await firestore.collection('SharedGroups').doc(sumomoUid).get();

    if (defaultGroupDoc.exists) {
      print('✅ デフォルトグループ存在');
      print('データ: ${defaultGroupDoc.data()}');

      // SharedListsも確認
      print('\n=== 4. SharedLists確認 ===');
      final listsSnapshot = await firestore
          .collection('SharedGroups')
          .doc(sumomoUid)
          .collection('sharedLists')
          .get();

      print('リスト数: ${listsSnapshot.docs.length}件');
      for (final listDoc in listsSnapshot.docs) {
        final listData = listDoc.data();
        print('\nリストID: ${listDoc.id}');
        print('  listName: ${listData['listName']}');
        print('  groupId: ${listData['groupId']}');
      }
    } else {
      print('❌ デフォルトグループ不在 - 作成が必要');
    }
  } catch (e) {
    print('⚠️ エラー: $e');
  }

  print('\n✅ 確認完了');
}
