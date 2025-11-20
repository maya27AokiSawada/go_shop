import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🔍 Firestore通知確認スクリプト開始');

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // 現在のユーザー確認
  final currentUser = auth.currentUser;
  if (currentUser == null) {
    print('❌ ユーザーが認証されていません');
    return;
  }

  print('✅ 現在のユーザー:');
  print('  - UID: ${currentUser.uid}');
  print('  - Email: ${currentUser.email}');
  print('  - DisplayName: ${currentUser.displayName}');
  print('');

  // mayaのUID
  const mayaUid = 'VqNEozvTyXXw55Q46mNiGNMNngw2';
  const sumomoUid = 'K35DAuQUktfhSr4XWFoAtBNL32E3';

  print('📬 mayaへの通知を確認...');
  final mayaNotifications = await firestore
      .collection('notifications')
      .where('userId', isEqualTo: mayaUid)
      .orderBy('timestamp', descending: true)
      .limit(5)
      .get();

  print('  - 通知件数: ${mayaNotifications.docs.length}');
  for (var doc in mayaNotifications.docs) {
    final data = doc.data();
    print('  - ID: ${doc.id}');
    print('    type: ${data['type']}');
    print('    message: ${data['message']}');
    print('    read: ${data['read']}');
    print('    timestamp: ${data['timestamp']}');
    print('    metadata: ${data['metadata']}');
    print('');
  }

  print('📬 すももへの通知を確認...');
  final sumomoNotifications = await firestore
      .collection('notifications')
      .where('userId', isEqualTo: sumomoUid)
      .orderBy('timestamp', descending: true)
      .limit(5)
      .get();

  print('  - 通知件数: ${sumomoNotifications.docs.length}');
  for (var doc in sumomoNotifications.docs) {
    final data = doc.data();
    print('  - ID: ${doc.id}');
    print('    type: ${data['type']}');
    print('    message: ${data['message']}');
    print('    read: ${data['read']}');
    print('    timestamp: ${data['timestamp']}');
    print('');
  }

  print('✅ 確認完了');
}
