import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_group_v4.g.dart';
part 'purchase_group_v4.freezed.dart';

const uuid = Uuid();

/// 【v4.0】グループの役割を定義するenum
@HiveType(typeId: 15) // 新しいtypeID
enum PurchaseGroupRoleV4 {
  @HiveField(0)
  owner,
  @HiveField(1)
  member,
  @HiveField(2)
  manager,
}

/// 【v4.0 シンプル設計】
/// メンバー情報: UID + 表示名 + ロールのみ
/// 詳細情報（email, phone等）は /users/{uid} から取得
@HiveType(typeId: 16) // 新しいtypeID
@freezed
class PurchaseGroupMemberV4 with _$PurchaseGroupMemberV4 {
  const factory PurchaseGroupMemberV4({
    @HiveField(0) required String uid, // Firebase UID
    @HiveField(1) required String displayName, // 表示名
    @HiveField(2) required PurchaseGroupRoleV4 role, // 権限
    @HiveField(3) DateTime? joinedAt, // 参加日時
  }) = _PurchaseGroupMemberV4;

  factory PurchaseGroupMemberV4.fromJson(Map<String, dynamic> json) =>
      _$PurchaseGroupMemberV4FromJson(json);

  // 新規作成用
  factory PurchaseGroupMemberV4.create({
    required String uid,
    required String displayName,
    PurchaseGroupRoleV4 role = PurchaseGroupRoleV4.member,
  }) {
    return PurchaseGroupMemberV4(
      uid: uid,
      displayName: displayName,
      role: role,
      joinedAt: DateTime.now(),
    );
  }
}

/// 【v4.0 シンプル設計】グループのデータを管理するクラス
/// 必要最小限の情報のみ保持: GroupID, 名前, オーナーUID, メンバーリスト
@HiveType(typeId: 17) // 新しいtypeID
@freezed
class PurchaseGroupV4 with _$PurchaseGroupV4 {
  const PurchaseGroupV4._();

  const factory PurchaseGroupV4({
    @HiveField(0) required String groupId,
    @HiveField(1) required String groupName,
    @HiveField(2) required String ownerUid,
    @HiveField(3) @Default([]) List<PurchaseGroupMemberV4> members,
    @HiveField(4) DateTime? createdAt,
    @HiveField(5) DateTime? updatedAt,
  }) = _PurchaseGroupV4;

  factory PurchaseGroupV4.fromJson(Map<String, dynamic> json) =>
      _$PurchaseGroupV4FromJson(json);

  // 新規作成用ファクトリ
  factory PurchaseGroupV4.create({
    required String groupName,
    required String ownerUid,
    required String ownerDisplayName,
    String? groupId,
  }) {
    final now = DateTime.now();
    final owner = PurchaseGroupMemberV4(
      uid: ownerUid,
      displayName: ownerDisplayName,
      role: PurchaseGroupRoleV4.owner,
      joinedAt: now,
    );

    return PurchaseGroupV4(
      groupId: groupId ?? uuid.v4(),
      groupName: groupName,
      ownerUid: ownerUid,
      members: [owner],
      createdAt: now,
      updatedAt: now,
    );
  }

  // 【v4.0】メンバー追加メソッド
  PurchaseGroupV4 addMember(PurchaseGroupMemberV4 member) {
    // 重複チェック
    if (members.any((m) => m.uid == member.uid)) {
      return this; // 既存メンバーは追加しない
    }

    return copyWith(
      members: [...members, member],
      updatedAt: DateTime.now(),
    );
  }

  // 【v4.0】メンバー削除メソッド
  PurchaseGroupV4 removeMember(String uid) {
    // オーナーは削除できない
    if (uid == ownerUid) {
      throw Exception('オーナーは削除できません');
    }

    return copyWith(
      members: members.where((m) => m.uid != uid).toList(),
      updatedAt: DateTime.now(),
    );
  }

  // 【v4.0】メンバーの権限変更
  PurchaseGroupV4 updateMemberRole(String uid, PurchaseGroupRoleV4 newRole) {
    final updatedMembers = members.map((m) {
      if (m.uid == uid) {
        return m.copyWith(role: newRole);
      }
      return m;
    }).toList();

    return copyWith(
      members: updatedMembers,
      updatedAt: DateTime.now(),
    );
  }

  // ヘルパーメソッド
  PurchaseGroupMemberV4? getMemberByUid(String uid) {
    try {
      return members.firstWhere((m) => m.uid == uid);
    } catch (e) {
      return null;
    }
  }

  bool isMember(String uid) {
    return members.any((m) => m.uid == uid);
  }

  bool isOwner(String uid) {
    return ownerUid == uid;
  }

  bool isManager(String uid) {
    final member = getMemberByUid(uid);
    return member?.role == PurchaseGroupRoleV4.manager;
  }

  // メンバー数
  int get memberCount => members.length;

  // オーナー情報
  PurchaseGroupMemberV4? get owner => getMemberByUid(ownerUid);
  String get ownerDisplayName => owner?.displayName ?? 'Unknown';
}
