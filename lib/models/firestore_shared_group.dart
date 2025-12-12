import 'package:cloud_firestore/cloud_firestore.dart';

// 招待ユーザー情報を管理するクラス（SharedGroup用）
class GroupInvitedUser {
  final String email;          // 招待されたメールアドレス
  final String? uid;           // 確定したUID（ログイン後）
  final DateTime invitedAt;    // 招待日時
  final bool isConfirmed;      // UID確定済みフラグ
  final String role;           // 招待時の役割

  const GroupInvitedUser({
    required this.email,
    this.uid,
    required this.invitedAt,
    this.isConfirmed = false,
    this.role = 'member',
  });

  GroupInvitedUser copyWith({
    String? email,
    String? uid,
    DateTime? invitedAt,
    bool? isConfirmed,
    String? role,
  }) {
    return GroupInvitedUser(
      email: email ?? this.email,
      uid: uid ?? this.uid,
      invitedAt: invitedAt ?? this.invitedAt,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'uid': uid,
      'invitedAt': invitedAt.toIso8601String(),
      'isConfirmed': isConfirmed,
      'role': role,
    };
  }

  factory GroupInvitedUser.fromJson(Map<String, dynamic> json) {
    return GroupInvitedUser(
      email: json['email'] as String,
      uid: json['uid'] as String?,
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      role: json['role'] as String? ?? 'member',
    );
  }
}

// Firestore用SharedGroupクラス
class FirestoreSharedGroup {
  final String id;                                  // ドキュメントID
  final String groupName;                           // グループ名
  final String ownerUid;                            // オーナーUID
  final String ownerEmail;                          // オーナーメールアドレス
  final List<String> memberUids;                    // 確定メンバーのUID一覧
  final List<GroupInvitedUser> invitedUsers;        // 招待中ユーザー一覧
  final List<String> sharedListIds;              // このグループが持つSharedListのID一覧
  final Map<String, dynamic> metadata;             // その他のメタデータ

  const FirestoreSharedGroup({
    required this.id,
    required this.groupName,
    required this.ownerUid,
    required this.ownerEmail,
    this.memberUids = const [],
    this.invitedUsers = const [],
    this.sharedListIds = const [],
    this.metadata = const {},
  });

  FirestoreSharedGroup copyWith({
    String? id,
    String? groupName,
    String? ownerUid,
    String? ownerEmail,
    List<String>? memberUids,
    List<GroupInvitedUser>? invitedUsers,
    List<String>? sharedListIds,
    Map<String, dynamic>? metadata,
  }) {
    return FirestoreSharedGroup(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      memberUids: memberUids ?? this.memberUids,
      invitedUsers: invitedUsers ?? this.invitedUsers,
      sharedListIds: sharedListIds ?? this.sharedListIds,
      metadata: metadata ?? this.metadata,
    );
  }

  // Firestore用のMap変換メソッド
  factory FirestoreSharedGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreSharedGroup(
      id: doc.id,
      groupName: data['groupName'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      memberUids: List<String>.from(data['memberUids'] ?? []),
      invitedUsers: (data['invitedUsers'] as List?)
          ?.map((e) => GroupInvitedUser.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      sharedListIds: List<String>.from(data['sharedListIds'] ?? []),
      metadata: data['metadata'] ?? {},
    );
  }

  // Firestoreへの保存用Map変換
  Map<String, dynamic> toFirestore() {
    return {
      'groupName': groupName,
      'ownerUid': ownerUid,
      'ownerEmail': ownerEmail,
      'memberUids': memberUids,
      'invitedUsers': invitedUsers.map((e) => e.toJson()).toList(),
      'sharedListIds': sharedListIds,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // 新しい招待ユーザーを追加
  FirestoreSharedGroup addInvitation({
    required String email,
    String role = 'member',
  }) {
    // 既に招待済みかチェック
    final alreadyInvited = invitedUsers.any((user) => user.email == email);
    final alreadyMember = memberUids.any((uid) => uid == email); // 将来的にメールからUID検索
    
    if (alreadyInvited || alreadyMember) {
      return this; // 既に招待済みまたはメンバー
    }
    
    final newInvitation = GroupInvitedUser(
      email: email,
      invitedAt: DateTime.now(),
      role: role,
    );
    
    return copyWith(
      invitedUsers: [...invitedUsers, newInvitation],
    );
  }

  // 招待ユーザーをUIDに変換し、メールアドレスを削除するメソッド
  FirestoreSharedGroup confirmInvitation({
    required String email,
    required String uid,
  }) {
    final updatedInvitedUsers = invitedUsers.map((invitedUser) {
      if (invitedUser.email == email && !invitedUser.isConfirmed) {
        return invitedUser.copyWith(
          uid: uid,
          isConfirmed: true,
        );
      }
      return invitedUser;
    }).toList();
    
    // 確定したUIDをメンバーリストに追加
    final updatedMemberUids = [...memberUids];
    if (!updatedMemberUids.contains(uid)) {
      updatedMemberUids.add(uid);
    }
    
    return copyWith(
      memberUids: updatedMemberUids,
      invitedUsers: updatedInvitedUsers,
    );
  }
  
  // 確定済み招待を削除（メールアドレス情報を削除）
  FirestoreSharedGroup cleanupConfirmedInvitations() {
    final cleanedInvitedUsers = invitedUsers
        .where((invitedUser) => !invitedUser.isConfirmed)
        .toList();
    
    return copyWith(invitedUsers: cleanedInvitedUsers);
  }

  // SharedListをグループに追加
  FirestoreSharedGroup addSharedList(String sharedListId) {
    if (sharedListIds.contains(sharedListId)) {
      return this;
    }
    
    return copyWith(
      sharedListIds: [...sharedListIds, sharedListId],
    );
  }

  // SharedListをグループから削除
  FirestoreSharedGroup removeSharedList(String sharedListId) {
    return copyWith(
      sharedListIds: sharedListIds.where((id) => id != sharedListId).toList(),
    );
  }

  // ユーザーがグループメンバーかチェック
  bool isMember(String uid, String? email) {
    // オーナーまたはメンバー
    if (ownerUid == uid || memberUids.contains(uid)) {
      return true;
    }
    
    // 招待されたメールアドレス
    if (email != null) {
      return invitedUsers.any((invitedUser) => 
        invitedUser.email == email && !invitedUser.isConfirmed);
    }
    
    return false;
  }

  // 全てのアクセス権限を持つUID（オーナー + メンバー）
  List<String> get allAuthorizedUids {
    final uids = <String>[ownerUid, ...memberUids];
    return uids.toSet().toList(); // 重複除去
  }
}
