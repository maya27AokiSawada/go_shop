import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../providers/firestore_provider.dart';
import '../providers/shopping_list_provider.dart';
import 'dart:developer' as developer;

class FirestorePurchaseGroupRepository implements PurchaseGroupRepository {
  final Ref _ref;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Refを受け取り、firestoreProviderからインスタンスを取得
  FirestorePurchaseGroupRepository(this._ref)
      : _firestore = _ref.read(firestoreProvider);

  /// 購入グループコレクション（全体で一意）
  CollectionReference get _groupsCollection =>
      _firestore.collection('purchaseGroups');

  /// ショッピングリストID生成（groupId + UUID）
  String generateShoppingListId(String groupId) {
    final uuid = _uuid.v4().replaceAll('-', '').substring(0, 12);
    return '${groupId}_$uuid';
  }

  /// リストIDからグループIDを抽出
  String getGroupIdFromListId(String listId) {
    return listId.split('_')[0];
  }

  @override
  Future<PurchaseGroup> createGroup(
      String groupId, String groupName, PurchaseGroupMember member) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        developer.log('❌ [FIRESTORE] User not logged in');
        throw Exception("User not logged in");
      }

      developer.log('🔥 [FIRESTORE] Creating group: $groupName ($groupId)');

      // PurchaseGroup.createファクトリを使用
      final newGroup = PurchaseGroup.create(
        groupId: groupId,
        groupName: groupName,
        members: [member],
      );

      // 新しいアーキテクチャ: ルートの'purchaseGroups'にドキュメントを作成
      final groupDocRef = _groupsCollection.doc(groupId);
      final groupData = {
        ..._groupToFirestore(newGroup),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      developer
          .log('🔥 [FIRESTORE] Group data prepared, writing to Firestore...');

      try {
        // シンプルなset操作でトランザクションを避ける（crash-proof）
        await groupDocRef.set(groupData);
        developer
            .log('✅ [FIRESTORE] Group write successful: $groupName ($groupId)');
      } catch (writeError) {
        developer
            .log('❌ [FIRESTORE] Write failed, trying transaction: $writeError');

        // setが失敗した場合のみトランザクションを試行
        await _firestore.runTransaction((transaction) async {
          transaction.set(groupDocRef, groupData);
        });
        developer.log(
            '✅ [FIRESTORE] Transaction write successful: $groupName ($groupId)');
      }

      developer.log(
          '🔥 [FIRESTORE] Created group in root collection: $groupName ($groupId)');
      return newGroup;
    } catch (e, st) {
      developer.log('❌ [FIRESTORE] createGroup error: $e');
      developer.log('📄 [FIRESTORE] StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        developer.log('❌ User not authenticated');
        return [];
      }

      final currentUserId = currentUser.uid;
      developer.log('🔥 [FIRESTORE] Fetching groups for user: $currentUserId');

      // 新しいアーキテクチャ: ルートの'purchaseGroups'をクエリ
      final groupsSnapshot = await _groupsCollection
          .where('allowedUid', arrayContains: currentUserId)
          .get();

      developer.log(
          '🔥 [FIRESTORE] Fetched groups count: ${groupsSnapshot.docs.length}');

      if (groupsSnapshot.docs.isEmpty) {
        developer.log('⚠️ [FIRESTORE] No groups found for this user.');
        return [];
      }

      final userGroups =
          groupsSnapshot.docs.map((doc) => _groupFromFirestore(doc)).toList();

      return userGroups;
    } catch (e, st) {
      developer.log('❌ Firestore getAllGroups error: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> getGroupById(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) {
        throw Exception('Group not found: $groupId');
      }

      return _groupFromFirestore(doc);
    } catch (e) {
      developer.log('❌ Firestore getGroupById error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    try {
      await _groupsCollection.doc(groupId).update({
        ..._groupToFirestore(group),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('🔥 Updated in Firestore: ${group.groupName}');
      return group;
    } catch (e) {
      developer.log('❌ Firestore updateGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) {
        throw Exception('Group not found: $groupId');
      }

      final group = _groupFromFirestore(doc);

      // 新しいアーキテクチャ: サブコレクション内のショッピングリストを削除
      final shoppingListRepo = _ref.read(shoppingListRepositoryProvider);
      await shoppingListRepo.deleteShoppingListsByGroupId(groupId);

      // グループ本体を削除
      await _groupsCollection.doc(groupId).delete();

      developer.log(
          '🔥 [FIRESTORE] Deleted group and associated shopping lists: $groupId');
      return group;
    } catch (e) {
      developer.log('❌ Firestore deleteGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> addMember(
      String groupId, PurchaseGroupMember member) async {
    try {
      final group = await getGroupById(groupId);
      final updatedGroup = group.addMember(member);

      // グループデータを更新（members配列が含まれている）
      await _groupsCollection
          .doc(groupId)
          .update(_groupToFirestore(updatedGroup));

      developer.log(
          '🔥 [FIRESTORE] Added member and created membership: ${member.name} to $groupId');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ Firestore addMember error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> removeMember(
      String groupId, PurchaseGroupMember member) async {
    try {
      final group = await getGroupById(groupId);
      final updatedGroup = group.removeMember(member);

      // グループデータを更新（members配列が含まれている）
      await _groupsCollection
          .doc(groupId)
          .update(_groupToFirestore(updatedGroup));

      developer.log(
          '🔥 [FIRESTORE] Removed member and deleted membership: ${member.name} from $groupId');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ Firestore removeMember error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> setMemberId(
      String oldId, String newId, String? contact) async {
    try {
      // TODO: Firestore実装 - 複数グループでのUID更新
      throw UnimplementedError('setMemberId not implemented for Firestore yet');
    } catch (e) {
      developer.log('❌ Firestore setMemberId error: $e');
      rethrow;
    }
  }

  // 🔒 メンバープール関連（個人情報保護のため Firestore では実装しない）
  @override
  Future<PurchaseGroup> getOrCreateMemberPool() async {
    throw UnimplementedError(
        '🔒 Member pool is local-only for privacy protection');
  }

  @override
  Future<void> syncMemberPool() async {
    // 🔒 個人情報保護: メンバープールはFirestoreに同期しない
  }

  @override
  Future<List<PurchaseGroupMember>> searchMembersInPool(String query) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return [];
  }

  @override
  Future<PurchaseGroupMember?> findMemberByEmail(String email) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return null;
  }

  // =================================================================
  // Firestore変換ヘルパー
  // =================================================================

  Map<String, dynamic> _groupToFirestore(PurchaseGroup group) {
    return {
      'groupName': group.groupName,
      'groupId': group.groupId,
      'ownerUid': group.ownerUid,
      'members':
          group.members?.map((m) => _memberToFirestore(m)).toList() ?? [],
      'createdAt': group.createdAt,
      'updatedAt': group.updatedAt,
      // v4: シンプル化されたデータ構造
    };
  }

  Map<String, dynamic> _memberToFirestore(PurchaseGroupMember m) {
    return {
      'memberId': m.memberId,
      'name': m.name,
      'contact': m.contact,
      'role': m.role.name, // enumを文字列として保存
      'invitedAt':
          m.invitedAt != null ? Timestamp.fromDate(m.invitedAt!) : null,
      'acceptedAt':
          m.acceptedAt != null ? Timestamp.fromDate(m.acceptedAt!) : null,
    };
  }

  PurchaseGroup _groupFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final membersList = (data['members'] as List<dynamic>?)
            ?.map((memberData) =>
                _memberFromFirestore(memberData as Map<String, dynamic>))
            .toList() ??
        [];

    return PurchaseGroup(
      groupName: data['groupName'] ?? '',
      groupId: data['groupId'] ?? doc.id,
      ownerUid: data['ownerUid'] ?? '',
      members: membersList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  PurchaseGroupMember _memberFromFirestore(Map<String, dynamic> data) {
    return PurchaseGroupMember(
      memberId: data['uid'] ?? data['memberId'] ?? '',
      name: data['displayName'] ?? data['name'] ?? '',
      contact: data['contact'] ?? '',
      role: PurchaseGroupRole.values.firstWhere((e) => e.name == data['role'],
          orElse: () => PurchaseGroupRole.member),
      invitedAt: (data['invitedAt'] as Timestamp?)?.toDate() ??
          (data['joinedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate() ??
          (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }
}
