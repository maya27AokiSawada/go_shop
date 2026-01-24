import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:goshopping/models/shared_group.dart';

/// しんやさんのグループ問題デバッグスクリプト
///
/// 目的:
/// 1. Firestoreから「すもも共有グループ」が取得できるか確認
/// 2. Hiveに「すもも共有グループ」が存在するか確認
/// 3. allowedUidにしんやのUIDが含まれているか確認
///
/// 実行方法:
/// ```bash
/// dart debug_shinya_groups.dart
/// ```

Future<void> main() async {
  print('🔍 [DEBUG] しんやのグループ問題デバッグ開始');

  try {
    // Firebase Auth初期化
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      print('❌ [DEBUG] ユーザーが認証されていません');
      return;
    }

    final shinyaUid = currentUser.uid;
    print('✅ [DEBUG] しんやのUID: ${shinyaUid.substring(0, 3)}***');

    // Firestore確認
    print('\n📱 [DEBUG] === Firestoreからグループ取得 ===');
    final firestore = FirebaseFirestore.instance;
    final groupsSnapshot = await firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: shinyaUid)
        .get();

    print('📱 [DEBUG] Firestoreから取得したグループ数: ${groupsSnapshot.docs.length}');

    for (var doc in groupsSnapshot.docs) {
      final data = doc.data();
      final groupName = data['groupName'] as String? ?? 'Unknown';
      final allowedUid = data['allowedUid'] as List<dynamic>? ?? [];
      final ownerUid = data['ownerUid'] as String? ?? 'Unknown';

      print('  📄 [GROUP] $groupName (${doc.id})');
      print('    - ownerUid: ${ownerUid.substring(0, 3)}***');
      print('    - allowedUid count: ${allowedUid.length}');
      print('    - しんや含む: ${allowedUid.contains(shinyaUid)}');

      // 「すもも共有グループ」を特定
      if (groupName.contains('すもも')) {
        print('    🎯 [TARGET] すもも共有グループを発見！');
        print(
            '    - allowedUid: ${allowedUid.map((uid) => '${uid.toString().substring(0, 3)}***').toList()}');
      }
    }

    // Hive確認
    print('\n💾 [DEBUG] === Hiveからグループ取得 ===');

    // Hive初期化（ユーザー固有パス）
    // 注意: このスクリプトは実際のアプリ内で実行する必要があります
    // （Hive Boxが正しく初期化されている必要があるため）

    final hiveBox = Hive.box<SharedGroup>('sharedGroups_$shinyaUid');
    final hiveGroups = hiveBox.values.toList();

    print('💾 [DEBUG] Hiveから取得したグループ数: ${hiveGroups.length}');

    for (var group in hiveGroups) {
      print('  📦 [GROUP] ${group.groupName} (${group.groupId})');
      print('    - allowedUid count: ${group.allowedUid.length}');
      print('    - しんや含む: ${group.allowedUid.contains(shinyaUid)}');
      print('    - isDeleted: ${group.isDeleted}');

      // 「すもも共有グループ」を特定
      if (group.groupName.contains('すもも')) {
        print('    🎯 [TARGET] すもも共有グループを発見！');
        print(
            '    - allowedUid: ${group.allowedUid.map((uid) => '${uid.substring(0, 3)}***').toList()}');
      }
    }

    // 比較
    print('\n🔍 [DEBUG] === Firestore vs Hive 比較 ===');
    print('Firestore: ${groupsSnapshot.docs.length}グループ');
    print('Hive: ${hiveGroups.length}グループ');

    final diff = groupsSnapshot.docs.length - hiveGroups.length;
    if (diff > 0) {
      print('⚠️ [WARNING] Firestoreに$diff個多くグループがあります');
      print('⚠️ [WARNING] 同期が必要です！');
    } else if (diff < 0) {
      print('⚠️ [WARNING] Hiveに${-diff}個多くグループがあります');
      print('⚠️ [WARNING] 古いキャッシュが残っている可能性があります');
    } else {
      print('✅ [OK] グループ数は一致しています');
    }

    print('\n✅ [DEBUG] デバッグ完了');
  } catch (e, st) {
    print('❌ [DEBUG] エラー発生: $e');
    print('Stack trace: $st');
  }
}
