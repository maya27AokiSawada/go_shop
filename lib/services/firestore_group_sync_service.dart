// lib/services/firestore_group_sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../flavors.dart';
import 'user_preferences_service.dart';

/// Firestore・Hive間のグループデータ同期サービス
class FirestoreGroupSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// サインイン時にFirestoreからグループデータを読み込み、ローカルに同期
  static Future<List<PurchaseGroup>> syncGroupsOnSignIn() async {
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
      return [];
    }
  }

  /// 特定のグループをFirestoreから取得してHiveに同期
  static Future<PurchaseGroup?> syncSpecificGroup(String groupId) async {
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
      // Firestoreデータから直接PurchaseGroupを構築
      final group = PurchaseGroup(
        groupId: groupDoc.id,
        groupName: groupData['groupName'] ?? '',
        ownerName: groupData['ownerName'],
        ownerEmail: groupData['ownerEmail'],
        ownerUid: groupData['ownerUid'],
        members: (groupData['members'] as List<dynamic>?)
            ?.map((memberData) => PurchaseGroupMember(
                  memberId: memberData['memberId'] ?? '',
                  name: memberData['name'] ?? '',
                  contact: memberData['contact'] ?? '',
                  role: PurchaseGroupRole.values[memberData['role'] ?? 0],
                  isSignedIn: memberData['isSignedIn'] ?? false,
                ))
            .toList(),
        ownerMessage: groupData['ownerMessage'],
        // shoppingListIds はサブコレクションに移行したため削除
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
      return null;
    }
  }

  /// グループデータをFirestoreに保存
  static Future<bool> saveGroupToFirestore(PurchaseGroup group) async {
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

      // PurchaseGroupからFirestore用のMapを手動で構築
      final groupData = <String, dynamic>{
        'groupName': group.groupName,
        'ownerName': group.ownerName,
        'ownerEmail': group.ownerEmail,
        'ownerUid': group.ownerUid,
        'ownerMessage': group.ownerMessage,
        // 'shoppingListIds': group.shoppingListIds, // サブコレクションに移行したため削除
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
      return false;
    }
  }

  /// ユーザーが参加しているグループ一覧をFirestoreから取得
  static Future<List<PurchaseGroup>> _fetchUserGroups(String userId) async {
    final groups = <PurchaseGroup>[];

    try {
      // グループコレクションから、ユーザーがメンバーになっているものを検索
      final querySnapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .get();

      for (final doc in querySnapshot.docs) {
        final groupData = doc.data();
        final group = PurchaseGroup(
          groupId: doc.id,
          groupName: groupData['groupName'] ?? '',
          ownerName: groupData['ownerName'],
          ownerEmail: groupData['ownerEmail'],
          ownerUid: groupData['ownerUid'],
          members: (groupData['members'] as List<dynamic>?)
              ?.map((memberData) => PurchaseGroupMember(
                    memberId: memberData['memberId'] ?? '',
                    name: memberData['name'] ?? '',
                    contact: memberData['contact'] ?? '',
                    role: PurchaseGroupRole.values[memberData['role'] ?? 0],
                    isSignedIn: memberData['isSignedIn'] ?? false,
                  ))
              .toList(),
          ownerMessage: groupData['ownerMessage'],
          // shoppingListIds はサブコレクションに移行したため削除
        );
        groups.add(group);
      }

      // メールアドレスベースでも検索（UIDが設定される前のメンバー対応）
      final user = _auth.currentUser;
      if (user?.email != null) {
        final emailQuery = await _firestore
            .collection('groups')
            .where('memberEmails', arrayContains: user!.email)
            .get();

        for (final doc in emailQuery.docs) {
          // 既に追加済みでないかチェック
          if (!groups.any((g) => g.groupId == doc.id)) {
            final groupData = doc.data();
            final group = PurchaseGroup(
              groupId: doc.id,
              groupName: groupData['groupName'] ?? '',
              ownerName: groupData['ownerName'],
              ownerEmail: groupData['ownerEmail'],
              ownerUid: groupData['ownerUid'],
              members: (groupData['members'] as List<dynamic>?)
                  ?.map((memberData) => PurchaseGroupMember(
                        memberId: memberData['memberId'] ?? '',
                        name: memberData['name'] ?? '',
                        contact: memberData['contact'] ?? '',
                        role: PurchaseGroupRole.values[memberData['role'] ?? 0],
                        isSignedIn: memberData['isSignedIn'] ?? false,
                      ))
                  .toList(),
              ownerMessage: groupData['ownerMessage'],
              // shoppingListIds はサブコレクションに移行したため削除
            );
            groups.add(group);
          }
        }
      }
    } catch (e) {
      Log.error('❌ ユーザーグループ取得エラー: $e');
    }

    return groups;
  }

  /// グループの変更をリアルタイムで監視（ストリーム）
  static Stream<List<PurchaseGroup>> watchUserGroups() {
    if (F.appFlavor != Flavor.prod) {
      return Stream.value([]);
    }

    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final groupData = doc.data();
        return PurchaseGroup(
          groupId: doc.id,
          groupName: groupData['groupName'] ?? '',
          ownerName: groupData['ownerName'],
          ownerEmail: groupData['ownerEmail'],
          ownerUid: groupData['ownerUid'],
          members: (groupData['members'] as List<dynamic>?)
              ?.map((memberData) => PurchaseGroupMember(
                    memberId: memberData['memberId'] ?? '',
                    name: memberData['name'] ?? '',
                    contact: memberData['contact'] ?? '',
                    role: PurchaseGroupRole.values[memberData['role'] ?? 0],
                    isSignedIn: memberData['isSignedIn'] ?? false,
                  ))
              .toList(),
          ownerMessage: groupData['ownerMessage'],
          // shoppingListIds はサブコレクションに移行したため削除
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
    }
  }
}
