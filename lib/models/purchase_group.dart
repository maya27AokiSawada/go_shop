import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'purchase_group.g.dart';
part 'purchase_group.freezed.dart';

const uuid = Uuid();
// 家族の役割を定義するenum
@HiveType(typeId: 0)
enum PurchaseGroupRole {
  @HiveField(0)
  owner,
  @HiveField(1)
  parent,
  @HiveField(2)
  child,
}

@HiveType(typeId: 1)
@freezed
class PurchaseGroupMember with _$PurchaseGroupMember {
  const factory PurchaseGroupMember({
    @HiveField(0) @Default('') String memberId,
    @HiveField(1) required String name,
    @HiveField(2) required String contact, // email または phone
    @HiveField(3) required PurchaseGroupRole role,
    @HiveField(4) @Default(false) bool isSignedIn,
    @HiveField(5) @Default(false) bool isInvited, // 招待済みかどうか
    @HiveField(6) @Default(false) bool isInvitationAccepted, // 招待受諾済みかどうか
    @HiveField(7) DateTime? invitedAt, // 招待日時
    @HiveField(8) DateTime? acceptedAt, // 受諾日時
  }) = _PurchaseGroupMember;
  
  // カスタムコンストラクタでmemberIdを自動生成
  factory PurchaseGroupMember.create({
    String? memberId,
    required String name,
    required String contact,
    required PurchaseGroupRole role,
    bool isSignedIn = false,
    bool isInvited = false,
    bool isInvitationAccepted = false,
    DateTime? invitedAt,
    DateTime? acceptedAt,
  }) {
    return PurchaseGroupMember(
      memberId: memberId?.isNotEmpty == true ? memberId! : uuid.v4(),
      name: name,
      contact: contact,
      role: role,
      isSignedIn: isSignedIn,
      isInvited: isInvited,
      isInvitationAccepted: isInvitationAccepted,
      invitedAt: invitedAt,
      acceptedAt: acceptedAt,
    );
  }
}

// 拡張メソッドでcopyWithをHive用に追加
extension PurchaseGroupMemberExtension on PurchaseGroupMember {
  // Hive のアダプターに対応するためのメソッド
  PurchaseGroupMember copyWithExtra({
    String? name,
    String? memberId,
    String? contact,
    PurchaseGroupRole? role,
    bool? isSignedIn,
    bool? isInvited,
    bool? isInvitationAccepted,
    DateTime? invitedAt,
    DateTime? acceptedAt,
  }) {
    return PurchaseGroupMember(
      name: name ?? this.name,
      memberId: memberId ?? this.memberId,
      contact: contact ?? this.contact,
      role: role ?? this.role,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isInvited: isInvited ?? this.isInvited,
      isInvitationAccepted: isInvitationAccepted ?? this.isInvitationAccepted,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}
  

/// グループのデータを管理するクラス
@HiveType(typeId: 2)
@freezed
class PurchaseGroup with _$PurchaseGroup {
  const factory PurchaseGroup({
    @HiveField(0) required String groupName,
    @HiveField(1) required String groupId,
    @HiveField(2) String? ownerName,
    @HiveField(3) String? ownerEmail,
    @HiveField(4) String? ownerUid,
    @HiveField(5) List<PurchaseGroupMember>? members,
  }) = _PurchaseGroup;

  // カスタムコンストラクタでIDを自動生成
  factory PurchaseGroup.create({
    required String groupName,
    String? ownerName,
    String? ownerEmail,
    required List<PurchaseGroupMember>? members,
    String? ownerUid,
    String? groupId,
  }) {
    return PurchaseGroup(
      groupName: groupName,
      groupId: groupId ?? uuid.v4(),
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerUid: ownerUid ?? uuid.v4(),
      members: members,
    );
  }
}

// 拡張メソッドでaddMemberとremoveMemberを追加
extension PurchaseGroupExtension on PurchaseGroup {
  // 新しいメンバーを追加するメソッド
  PurchaseGroup addMember(PurchaseGroupMember member) {
    if (members == null) {
      return copyWith(
        members: [member],
      );
    } else {
      return copyWith(
        members: [...members!, member],
      );
    }
  }

  PurchaseGroup removeMember(PurchaseGroupMember member) {
    if (members == null) return this;
    return copyWith(
      members: members!.where((m) => m != member).toList(),
    );
  }

  // 招待機能メソッド
  PurchaseGroup inviteMember({
    required String name,
    required String contact, // email または phone
    required PurchaseGroupRole role,
  }) {
    final newMember = PurchaseGroupMember.create(
      name: name,
      contact: contact,
      role: role,
      isInvited: true,
      isInvitationAccepted: false,
      invitedAt: DateTime.now(),
    );
    return addMember(newMember);
  }

  // 招待を受諾
  PurchaseGroup acceptInvitation(String memberId) {
    if (members == null) return this;
    
    final updatedMembers = members!.map((member) {
      if (member.memberId == memberId && member.isInvited && !member.isInvitationAccepted) {
        return member.copyWith(
          isInvitationAccepted: true,
          acceptedAt: DateTime.now(),
        );
      }
      return member;
    }).toList();
    
    return copyWith(members: updatedMembers);
  }

  // 招待をキャンセル
  PurchaseGroup cancelInvitation(String memberId) {
    if (members == null) return this;
    return copyWith(
      members: members!.where((m) => m.memberId != memberId).toList(),
    );
  }

  // 招待待ちメンバーのリストを取得
  List<PurchaseGroupMember> get pendingInvitations {
    if (members == null) return [];
    return members!.where((m) => m.isInvited && !m.isInvitationAccepted).toList();
  }

  // アクティブなメンバー（招待受諾済み）のリストを取得
  List<PurchaseGroupMember> get activeMembers {
    if (members == null) return [];
    return members!.where((m) => !m.isInvited || m.isInvitationAccepted).toList();
  }

  // Hive のアダプターに対応するためのメソッド
  PurchaseGroup copyWithExtra({
    String? groupName,
    String? groupId,
    String? ownerName,
    String? ownerEmail,
    String? ownerUid,
    List<PurchaseGroupMember>? members,
  }) {
    return PurchaseGroup(
      groupName: groupName ?? this.groupName,
      groupId: groupId ?? this.groupId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerUid: ownerUid ?? this.ownerUid,
      members: members ?? this.members,
    );
  }
}
