import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

/// Firestoreの買い物リスト確認・削除スクリプト
void main() async {
  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  const groupId = 'MZVD2Wb1cnTJHnb1j8LqEzjbPjA2';
  const deleteTargetListId = 'fc03469d-6c96-4835-95a8-88179e452c64';

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📋 Firestore買い物リスト確認');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // グループ内の全リストを取得
  print('🔍 グループ内の全リストを取得...');
  final listsSnapshot = await firestore
      .collection('SharedGroups')
      .doc(groupId)
      .collection('sharedLists')
      .get();

  print('✅ 取得完了: ${listsSnapshot.docs.length}件\n');

  for (final doc in listsSnapshot.docs) {
    final data = doc.data();
    final listId = doc.id;
    final listName = data['listName'] ?? '(名前なし)';
    final isTarget = listId == deleteTargetListId;

    print('${isTarget ? "🎯" : "📄"} リスト: $listName');
    print('   ID: $listId');
    if (isTarget) {
      print('   ⚠️ これが削除対象のリストです！');
    }
    print('');
  }

  // 削除対象リストの存在確認
  final targetDoc = await firestore
      .collection('SharedGroups')
      .doc(groupId)
      .collection('sharedLists')
      .doc(deleteTargetListId)
      .get();

  if (targetDoc.exists) {
    print('❌ 削除対象リストがまだFirestoreに存在しています！');
    print('   リスト名: ${targetDoc.data()?['listName']}');
    print('   作成日: ${targetDoc.data()?['createdAt']}');
    print('\n🗑️ 手動削除を実行しますか? (この処理は実行されません)');
    print('   削除コマンド例:');
    print('   await firestore.collection("SharedGroups")');
    print('       .doc("$groupId")');
    print('       .collection("sharedLists")');
    print('       .doc("$deleteTargetListId")');
    print('       .delete();');
  } else {
    print('✅ 削除対象リストは正常に削除されています');
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ 確認完了');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}
