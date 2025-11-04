import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'purchase_group.g.dart';
part 'purchase_group.freezed.dart';

const uuid = Uuid();

// グループの役割を定義するenum
@HiveType(typeId: 0)
enum PurchaseGroupRole {
  @HiveField(0)
  owner,
  @HiveField(1)
  member,
  @HiveField(2)
  manager,
}

/// 【v4.0 シンプル設計】
/// メンバー情報: UID + 表示名 + ロールのみ
/// 詳細情報は /users/{uid} から取得
@HiveType(typeId: 1)
@freezed
class PurchaseGroupMember with _$PurchaseGroupMember {
  const factory PurchaseGroupMember({
    @HiveField(0) required String uid, // Firebase UID
    @HiveField(1) required String displayName, // 表示名
    @HiveField(2) required PurchaseGroupRole role, // 権限
    @HiveField(3) DateTime? joinedAt, // 参加日時
  }) = _PurchaseGroupMember;

  factory PurchaseGroupMember.fromJson(Map<String, dynamic> json) =>
      _$PurchaseGroupMemberFromJson(json);

  // 後方互換性のためのファクトリコンストラクタ
  factory PurchaseGroupMember.fromLegacy({
    required String memberId,
    required String name,
    required PurchaseGroupRole role,
    DateTime? joinedAt,
  }) {
    return PurchaseGroupMember(
      uid: memberId,
      displayName: name,
      role: role,
      joinedAt: joinedAt ?? DateTime.now(),
    );
  }

  // 新規作成用
  factory PurchaseGroupMember.create({
    required String uid,
    required String displayName,
    PurchaseGroupRole role = PurchaseGroupRole.member,
  }) {
    return PurchaseGroupMember(
      uid: uid,
      displayName: displayName,
      role: role,
      joinedAt: DateTime.now(),
    );
  }
}

// 後方互換性のための旧データモデル
@Deprecated('v3.0互換用。v4.0以降はPurchaseGroupMemberを使用')
@HiveType(typeId: 14) // 新しいtypeIdを割り当て
@freezed
class LegacyPurchaseGroupMember with _$LegacyPurchaseGroupMember {
  const factory LegacyPurchaseGroupMember({
    @HiveField(0) @Default('') String memberId,
    @HiveField(1) required String name,
    @HiveField(2) required String contact,
    @HiveField(3) required PurchaseGroupRole role,
    @HiveField(4) @Default(false) bool isSignedIn,
  }) = _LegacyPurchaseGroupMember;

  factory LegacyPurchaseGroupMember.fromJson(Map<String, dynamic> json) =>
      _$LegacyPurchaseGroupMemberFromJson(json);
}

/// 【v4.0 シンプル設計】グループのデータを管理するクラス
/// 必要最小限の情報のみ保持: GroupID, 名前, オーナーUID, メンバーリスト
@HiveType(typeId: 2)
@freezed
class PurchaseGroup with _$PurchaseGroup {
  const PurchaseGroup._();

  const factory PurchaseGroup({
    @HiveField(0) required String groupId,
    @HiveField(1) required String groupName,
    @HiveField(2) required String ownerUid,
    @HiveField(3) @Default([]) List<PurchaseGroupMember> members,
    @HiveField(4) DateTime? createdAt,
    @HiveField(5) DateTime? updatedAt,
  }) = _PurchaseGroup;

  factory PurchaseGroup.fromJson(Map<String, dynamic> json) =>
      _$PurchaseGroupFromJson(json);

  // 新規作成用ファクトリ
  factory PurchaseGroup.create({
    required String groupName,
    required String ownerUid,
    required String ownerDisplayName,
    String? groupId,
  }) {
    final now = DateTime.now();
    final owner = PurchaseGroupMember(
      uid: ownerUid,
      displayName: ownerDisplayName,
      role: PurchaseGroupRole.owner,
      joinedAt: now,
    );

    return PurchaseGroup(
      groupId: groupId ?? uuid.v4(),
      groupName: groupName,
      ownerUid: ownerUid,
      members: [owner],
      createdAt: now,
      updatedAt: now,
    );
  }

  // 後方互換性のためのファクトリ（v3→v4変換）
  factory PurchaseGroup.fromLegacy({
    required String groupName,
    required String groupId,
    String? ownerUid,
    List<dynamic>? members,
  }) {
    final now = DateTime.now();

    // 旧メンバーデータを新形式に変換
    final convertedMembers = members?.map((m) {
          if (m is PurchaseGroupMember) {
            return m; // 既に新形式
          }
          // 旧形式（LegacyPurchaseGroupMember）から変換
          final legacyMap = m as Map<String, dynamic>;
          return PurchaseGroupMember(
            uid: legacyMap['memberId'] ?? legacyMap['uid'] ?? '',
            displayName:
                legacyMap['name'] ?? legacyMap['displayName'] ?? 'Unknown',
            role: legacyMap['role'] ?? PurchaseGroupRole.member,
            joinedAt: legacyMap['joinedAt'] ?? now,
          );
        }).toList() ??
        [];

    // オーナーUIDの決定
    final finalOwnerUid = ownerUid ??
        convertedMembers
            .firstWhere(
              (m) => m.role == PurchaseGroupRole.owner,
              orElse: () => convertedMembers.isNotEmpty
                  ? convertedMembers.first
                  : PurchaseGroupMember(
                      uid: 'unknown',
                      displayName: 'Unknown',
                      role: PurchaseGroupRole.owner,
                      joinedAt: now,
                    ),
            )
            .uid;

    return PurchaseGroup(
      groupId: groupId,
      groupName: groupName,
      ownerUid: finalOwnerUid,
      members: convertedMembers,
      createdAt: now,
      updatedAt: now,
    );
  }

  // 【v4.0】メンバー追加メソッド
  PurchaseGroup addMember(PurchaseGroupMember member) {
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
  PurchaseGroup removeMember(String uid) {
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
  PurchaseGroup updateMemberRole(String uid, PurchaseGroupRole newRole) {
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
  PurchaseGroupMember? getMemberByUid(String uid) {
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
    return member?.role == PurchaseGroupRole.manager;
  }

  // メンバー数
  int get memberCount => members.length;

  // オーナー情報
  PurchaseGroupMember? get owner => getMemberByUid(ownerUid);
  String get ownerDisplayName => owner?.displayName ?? 'Unknown';

  // 後方互換性のためのゲッター
  String? get ownerName => ownerDisplayName;
  String? get ownerEmail => owner?.uid; // 簡略化: UIDを返す
}
