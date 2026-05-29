import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goshopping/utils/app_logger.dart';
import 'package:uuid/uuid.dart';
import '../models/shared_group.dart';
import '../datastore/shared_group_repository.dart';

class FirestoreSharedGroupRepository implements SharedGroupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // FirebaseFirestoreインスタンスを直接受け取る
  FirestoreSharedGroupRepository(this._firestore);

  /// 購入グループコレクション（ルート直下 - QR招待のため）
  CollectionReference get _groupsCollection {
    return _firestore.collection('SharedGroups');
  }

  /// ショッピングリストID生成（groupId + UUID）
  String generateSharedListId(String groupId) {
    final uuid = _uuid.v4().replaceAll('-', '').substring(0, 12);
    return '${groupId}_$uuid';
  }

  /// リストIDからグループIDを抽出
  String getGroupIdFromListId(String listId) {
    return listId.split('_')[0];
  }

  @override
  Future<SharedGroup> createGroup(
      String groupId, String groupName, SharedGroupMember member) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Log.error('❌ [FIRESTORE] User not logged in');
        throw Exception("User not logged in");
      }

      Log.info('🔥 [FIRESTORE] Creating group: $groupName ($groupId)');
      Log.info('🔍 [FIRESTORE] Owner member.memberId: ${member.memberId}');
      Log.info('🔍 [FIRESTORE] Owner member.name: ${member.name}');

      // SharedGroup.createファクトリを使用
      final newGroup = SharedGroup.create(
        groupId: groupId,
        groupName: groupName,
        members: [member],
      );

      // 新しいアーキテクチャ: ルートの'SharedGroups'にドキュメントを作成
      final groupDocRef = _groupsCollection.doc(groupId);
      final groupData = {
        ..._groupToFirestore(newGroup),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      Log.info('🔥 [FIRESTORE] Group data prepared, writing to Firestore...');
      Log.info('🔍 [FIRESTORE] allowedUid in newGroup: ${newGroup.allowedUid}');
      Log.info(
          '🔍 [FIRESTORE] allowedUid in groupData: ${groupData['allowedUid']}');

      // Windows版Firestoreのスレッド問題を回避
      // 🔥 FIX: runTransaction()フォールバックを削除
      // runTransaction()はサーバー接続必須のため、機内モードで永久にハングする
      // オフライン永続化が有効な場合、.set()はローカルキャッシュにキューイングされ即座に返る
      await Future.microtask(() async {
        await groupDocRef.set(groupData);
      });
      Log.info('✅ [FIRESTORE] Group write successful: $groupName ($groupId)');

      Log.info(
          '🔥 [FIRESTORE] Created group in root collection: $groupName ($groupId)');
      return newGroup;
    } catch (e, st) {
      Log.error('❌ [FIRESTORE] createGroup error: $e', e, st);
      rethrow;
    }
  }

  @override
  Future<List<SharedGroup>> getAllGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        Log.warning('❌ User not authenticated');
        return [];
      }

      final currentUserId = currentUser.uid;
      Log.info('🔥 [FIRESTORE] Fetching groups for user: $currentUserId');
      Log.info(
          '🔥 [FIRESTORE_REPO] getAllGroups開始 - currentUserId: ${Log.maskUserId(currentUserId)}');

      // 新しいアーキテクチャ: ルートの'SharedGroups'をクエリ
      final groupsSnapshot = await _groupsCollection
          .where('allowedUid', arrayContains: currentUserId)
          .get();

      Log.info(
          '🔥 [FIRESTORE] Fetched groups count: ${groupsSnapshot.docs.length}');
      Log.info('✅ [FIRESTORE_REPO] ${groupsSnapshot.docs.length}グループ取得');

      for (var doc in groupsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final groupName = data?['groupName'] as String? ?? 'Unknown';
        final allowedUid = data?['allowedUid'] as List<dynamic>? ?? [];
        Log.info(
            '  📄 [FIRESTORE_DOC] ${Log.maskGroup(groupName, doc.id)} - allowedUid: ${allowedUid.map((uid) => Log.maskUserId(uid.toString())).toList()}');
      }

      if (groupsSnapshot.docs.isEmpty) {
        Log.info('⚠️ [FIRESTORE] No groups found for this user.');
        return [];
      }

      final userGroups =
          groupsSnapshot.docs.map((doc) => _groupFromFirestore(doc)).toList();

      return userGroups;
    } catch (e, st) {
      Log.error('❌ Firestore getAllGroups error: $e', e, st);
      rethrow;
    }
  }

  @override
  Future<SharedGroup> getGroupById(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) {
        throw Exception('Group not found: $groupId');
      }

      return _groupFromFirestore(doc);
    } catch (e, stackTrace) {
      Log.error('❌ Firestore getGroupById error: $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group) async {
    try {
      final updateData = _groupToFirestore(group);
      Log.info('🔍 [FIRESTORE UPDATE] groupId: $groupId');
      Log.info('🔍 [FIRESTORE UPDATE] group.allowedUid: ${group.allowedUid}');
      Log.info(
          '🔍 [FIRESTORE UPDATE] updateData[allowedUid]: ${updateData['allowedUid']}');

      // set(merge: true)を使用してドキュメントが存在しない場合も対応
      // Windows版Firestoreのスレッド問題を回避
      await Future.microtask(() async {
        await _groupsCollection.doc(groupId).set({
          ...updateData,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      Log.info('✅ [FIRESTORE UPDATE] Updated in Firestore: ${group.groupName}');
      return group;
    } catch (e, stackTrace) {
      Log.error('❌ Firestore updateGroup error: $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<SharedGroup> deleteGroup(String groupId) async {
    try {
      final user = _auth.currentUser;
      Log.info('🔍 [FIRESTORE DELETE] Attempting to delete group: $groupId');
      Log.info(
          '🔍 [FIRESTORE DELETE] User path: users/${user?.uid}/groups/$groupId');

      final doc = await _groupsCollection.doc(groupId).get();
      Log.info('🔍 [FIRESTORE DELETE] Document exists: ${doc.exists}');

      if (!doc.exists) {
        throw Exception('Group not found: $groupId (User: ${user?.uid})');
      }

      final group = _groupFromFirestore(doc);

      // 論理削除: isDeletedフラグを立てる（物理削除はしない）
      // Windows版Firestoreのスレッド問題を回避
      await Future.microtask(() async {
        await _groupsCollection.doc(groupId).update({
          'isDeleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      Log.info('🔥 [FIRESTORE] Marked group as deleted: $groupId');

      // 削除フラグを立てたグループを返す
      return group.copyWith(isDeleted: true, updatedAt: DateTime.now());
    } catch (e, stackTrace) {
      Log.error('❌ Firestore deleteGroup error: $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<SharedGroup> addMember(
      String groupId, SharedGroupMember member) async {
    try {
      final group = await getGroupById(groupId);
      final updatedGroup = group.addMember(member);

      // グループデータを更新（members配列が含まれている）
      // Windows版Firestoreのスレッド問題を回避
      await Future.microtask(() async {
        await _groupsCollection
            .doc(groupId)
            .update(_groupToFirestore(updatedGroup));
      });

      Log.info(
          '🔥 [FIRESTORE] Added member and created membership: ${member.name} to $groupId');
      return updatedGroup;
    } catch (e, stackTrace) {
      Log.error('❌ Firestore addMember error: $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<SharedGroup> removeMember(
      String groupId, SharedGroupMember member) async {
    try {
      final group = await getGroupById(groupId);
      final updatedGroup = group.removeMember(member);

      // グループデータを更新（members配列が含まれている）
      // Windows版Firestoreのスレッド問題を回避
      await Future.microtask(() async {
        await _groupsCollection
            .doc(groupId)
            .update(_groupToFirestore(updatedGroup));
      });

      Log.info(
          '🔥 [FIRESTORE] Removed member and deleted membership: ${member.name} from $groupId');
      return updatedGroup;
    } catch (e, stackTrace) {
      Log.error('❌ Firestore removeMember error: $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<SharedGroup> setMemberId(
      String oldId, String newId, String? contact) async {
    try {
      // TODO: Firestore実装 - 複数グループでのUID更新
      throw UnimplementedError('setMemberId not implemented for Firestore yet');
    } catch (e, stackTrace) {
      Log.error('❌ Firestore setMemberId error: $e', e, stackTrace);
      rethrow;
    }
  }

  // 🔒 メンバープール関連（個人情報保護のため Firestore では実装しない）
  @override
  Future<SharedGroup> getOrCreateMemberPool() async {
    throw UnimplementedError(
        '🔒 Member pool is local-only for privacy protection');
  }

  @override
  Future<void> syncMemberPool() async {
    // 🔒 個人情報保護: メンバープールはFirestoreに同期しない
  }

  @override
  Future<List<SharedGroupMember>> searchMembersInPool(String query) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return [];
  }

  @override
  Future<SharedGroupMember?> findMemberByEmail(String email) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return null;
  }

  // =================================================================
  // Firestore変換ヘルパー
  // =================================================================

  Map<String, dynamic> _groupToFirestore(SharedGroup group) {
    return {
      'groupName': group.groupName,
      'groupId': group.groupId,
      'ownerUid': group.ownerUid,
      'ownerName': group.ownerName,
      'ownerEmail': group.ownerEmail,
      'allowedUid': group.allowedUid, // 🔥 CRITICAL: 招待機能に必須
      'members':
          group.members?.map((m) => _memberToFirestore(m)).toList() ?? [],
      'createdAt':
          group.createdAt != null ? Timestamp.fromDate(group.createdAt!) : null,
      'updatedAt':
          group.updatedAt != null ? Timestamp.fromDate(group.updatedAt!) : null,
      'isDeleted': group.isDeleted, // 削除フラグも保存
      // v4: シンプル化されたデータ構造
    };
  }

  Map<String, dynamic> _memberToFirestore(SharedGroupMember m) {
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

  SharedGroup _groupFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final membersList = (data['members'] as List<dynamic>?)
            ?.map((memberData) =>
                _memberFromFirestore(memberData as Map<String, dynamic>))
            .toList() ??
        [];

    return SharedGroup(
      groupName: data['groupName'] ?? '',
      groupId: data['groupId'] ?? doc.id,
      ownerUid: data['ownerUid'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      allowedUid:
          List<String>.from(data['allowedUid'] ?? []), // 🔥 CRITICAL: これが抜けていた！
      members: membersList,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  SharedGroupMember _memberFromFirestore(Map<String, dynamic> data) {
    return SharedGroupMember(
      memberId: data['uid'] ?? data['memberId'] ?? '',
      name: data['displayName'] ?? data['name'] ?? '',
      contact: data['contact'] ?? '',
      role: SharedGroupRole.values.firstWhere((e) => e.name == data['role'],
          orElse: () => SharedGroupRole.member),
      invitedAt: _parseDateTime(data['invitedAt'] ?? data['joinedAt']),
      acceptedAt:
          _parseDateTimeNullable(data['acceptedAt'] ?? data['joinedAt']),
    );
  }

  /// Timestamp型またはString型をDateTime型に安全に変換する
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        Log.error('❌ [PARSE_DATETIME] Unknown type: ${value.runtimeType}');
        return DateTime.now();
      }
    } catch (e, stackTrace) {
      Log.error('❌ [PARSE_DATETIME] Error: $e', e, stackTrace);
      return DateTime.now();
    }
  }

  /// Timestamp型またはString型をnullableなDateTime型に安全に変換する
  DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> cleanupDeletedGroups() async {
    // Firestoreでは論理削除されたグループは自動的にクエリから除外されるため、
    // 物理削除は手動で行う必要がある。ただし、本番環境では慎重に扱う必要があるため、
    // 現状は何もしない（0を返す）
    Log.warning(
        '⚠️ [FIRESTORE] cleanupDeletedGroups is not implemented for production safety');
    return 0;
  }
}
