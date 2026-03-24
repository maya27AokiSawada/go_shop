// lib/services/firestore_group_sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/shared_group.dart';
import '../flavors.dart';
import 'user_preferences_service.dart';
import 'error_log_service.dart';

/// Firestore・Hive間のグループデータ同期サービス
class FirestoreGroupSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// サインイン時にFirestoreからグループデータを読み込み、ローカルに同期
  static Future<List<SharedGroup>> syncGroupsOnSignIn() async {
    try {
      Log.info('🔄 サインイン時グループ同期開始');

      // 本番環境でない場合は空のリストを返す
      if (F.appFlavor != Flavor.prod) {
        Log.warning('⚠️ 開発環境のためFirestore同期をスキップ');
        return [];
      }

      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('⚠️ 未認証のためグループ同期をスキップ');
        return [];
      }

      // UIDをSharedPreferencesに保存
      await UserPreferencesService.saveUserId(user.uid);

      // メールアドレスをSharedPreferencesに保存
      if (user.email != null) {
        await UserPreferencesService.saveUserEmail(user.email!);
      }

      // Firestoreからユーザーが参加しているグループを取得
      final groups = await _fetchUserGroups(user.uid);
      Log.info('✅ Firestoreから${groups.length}件のグループを取得');

      return groups;
    } catch (e, stackTrace) {
      Log.error('❌ サインイン時グループ同期エラー: $e');
      Log.info('スタックトレース: $stackTrace');
      await ErrorLogService.logSyncError('サインイン時グループ同期', '$e');
      return [];
    }
  }

  /// 特定のグループをFirestoreから取得してHiveに同期
  static Future<SharedGroup?> syncSpecificGroup(String groupId) async {
    try {
      Log.info('🔄 グループ[$groupId]の個別同期開始');

      if (F.appFlavor != Flavor.prod) {
        Log.warning('⚠️ 開発環境のためFirestore同期をスキップ');
        return null;
      }

      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('⚠️ 未認証のためグループ同期をスキップ');
        return null;
      }

      // Firestoreから特定のグループを取得
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) {
        Log.warning('⚠️ グループ[$groupId]がFirestoreに存在しません');
        return null;
      }

      final groupData = groupDoc.data()!;
      // Firestoreデータから直接SharedGroupを構築
      final group = SharedGroup(
        groupId: groupDoc.id,
        groupName: groupData['groupName'] ?? '',
        ownerName: groupData['ownerName'],
        ownerEmail: groupData['ownerEmail'],
        ownerUid: groupData['ownerUid'],
        members: (groupData['members'] as List<dynamic>?)
            ?.map((memberData) => SharedGroupMember(
                  memberId: memberData['memberId'] ?? '',
                  name: memberData['name'] ?? '',
                  contact: memberData['contact'] ?? '',
                  role: SharedGroupRole.values[memberData['role'] ?? 0],
                  isSignedIn: memberData['isSignedIn'] ?? false,
                ))
            .toList(),
        ownerMessage: groupData['ownerMessage'],
        // sharedListIds はサブコレクションに移行したため削除
      );

      // ユーザーがそのグループのメンバーかチェック
      final isMember = group.members?.any((member) =>
              member.memberId == user.uid || member.contact == user.email) ??
          false;

      if (!isMember) {
        Log.warning('⚠️ ユーザーはグループ[$groupId]のメンバーではありません');
        return null;
      }

      Log.info('✅ グループ[$groupId]の同期完了');
      return group;
    } catch (e, stackTrace) {
      Log.error('❌ グループ[$groupId]の同期エラー: $e');
      Log.info('スタックトレース: $stackTrace');
      await ErrorLogService.logSyncError('グループ個別同期', '$e');
      return null;
    }
  }

  /// グループデータをFirestoreに保存
  static Future<bool> saveGroupToFirestore(SharedGroup group) async {
    try {
      Log.info('💾 グループ[${group.groupName}]をFirestoreに保存開始');

      if (F.appFlavor != Flavor.prod) {
        Log.warning('⚠️ 開発環境のためFirestore保存をスキップ');
        return false;
      }

      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('⚠️ 未認証のためFirestore保存をスキップ');
        return false;
      }

      // SharedGroupからFirestore用のMapを手動で構築
      final groupData = <String, dynamic>{
        'groupName': group.groupName,
        'ownerName': group.ownerName,
        'ownerEmail': group.ownerEmail,
        'ownerUid': group.ownerUid,
        'ownerMessage': group.ownerMessage,
        // 'sharedListIds': group.sharedListIds, // サブコレクションに移行したため削除
        'members': group.members
            ?.map((member) => {
                  'memberId': member.memberId,
                  'name': member.name,
                  'contact': member.contact,
                  'role': member.role.index,
                  'isSignedIn': member.isSignedIn,
                })
            .toList(),
      };

      await _firestore.collection('groups').doc(group.groupId).set(groupData);

      Log.info('✅ グループ[${group.groupName}]のFirestore保存完了');
      return true;
    } catch (e, stackTrace) {
      Log.error('❌ グループ[${group.groupName}]のFirestore保存エラー: $e');
      Log.info('スタックトレース: $stackTrace');
      await ErrorLogService.logSyncError('Firestoreグループ保存', '$e');
      return false;
    }
  }

  /// ユーザーが参加しているグループ一覧をFirestoreから取得
  static Future<List<SharedGroup>> _fetchUserGroups(String userId) async {
    final groups = <SharedGroup>[];

    try {
      // グループコレクションから、allowedUidにユーザーIDが含まれているものを検索
      final querySnapshot = await _firestore
          .collection('groups')
          .where('allowedUid', arrayContains: userId)
          .get();

      Log.info('🔍 [FETCH] allowedUidクエリで${querySnapshot.docs.length}件取得');

      for (final doc in querySnapshot.docs) {
        final groupData = doc.data();
        final group = SharedGroup(
          groupId: doc.id,
          groupName: groupData['groupName'] ?? '',
          ownerName: groupData['ownerName'],
          ownerEmail: groupData['ownerEmail'],
          ownerUid: groupData['ownerUid'],
          members: (groupData['members'] as List<dynamic>?)
              ?.map((memberData) => SharedGroupMember(
                    memberId: memberData['memberId'] ?? '',
                    name: memberData['name'] ?? '',
                    contact: memberData['contact'] ?? '',
                    role: SharedGroupRole.values[memberData['role'] ?? 0],
                    isSignedIn: memberData['isSignedIn'] ?? false,
                  ))
              .toList(),
          ownerMessage: groupData['ownerMessage'],
          allowedUid: (groupData['allowedUid'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          // sharedListIds はサブコレクションに移行したため削除
        );
        groups.add(group);
        Log.info(
            '📦 [FETCH] グループ追加: ${group.groupName} (ID: ${group.groupId})');
      }

      Log.info('✅ [FETCH] 合計${groups.length}件のグループを取得完了');
    } catch (e) {
      Log.error('❌ ユーザーグループ取得エラー: $e');
      await ErrorLogService.logSyncError('ユーザーグループ取得', '$e');
    }

    return groups;
  }

  /// グループの変更をリアルタイムで監視（ストリーム）
  static Stream<List<SharedGroup>> watchUserGroups() {
    if (F.appFlavor != Flavor.prod) {
      return Stream.value([]);
    }

    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('groups')
        .where('allowedUid', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final groupData = doc.data();
        return SharedGroup(
          groupId: doc.id,
          groupName: groupData['groupName'] ?? '',
          ownerName: groupData['ownerName'],
          ownerEmail: groupData['ownerEmail'],
          ownerUid: groupData['ownerUid'],
          members: (groupData['members'] as List<dynamic>?)
              ?.map((memberData) => SharedGroupMember(
                    memberId: memberData['memberId'] ?? '',
                    name: memberData['name'] ?? '',
                    contact: memberData['contact'] ?? '',
                    role: SharedGroupRole.values[memberData['role'] ?? 0],
                    isSignedIn: memberData['isSignedIn'] ?? false,
                  ))
              .toList(),
          ownerMessage: groupData['ownerMessage'],
          allowedUid: (groupData['allowedUid'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          // sharedListIds はサブコレクションに移行したため削除
        );
      }).toList();
    });
  }

  /// サインアウト時の清理処理
  static Future<void> clearSyncDataOnSignOut() async {
    try {
      Log.info('🧹 サインアウト時の同期データクリア開始');

      // SharedPreferencesから認証情報のみクリア（ユーザー名・データバージョンは保持）
      await UserPreferencesService.clearAuthInfo();

      Log.info('✅ サインアウト時クリア完了');
    } catch (e) {
      Log.error('❌ サインアウト時クリアエラー: $e');
      await ErrorLogService.logOperationError('サインアウト時クリア', '$e');
    }
  }
}
