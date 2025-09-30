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
  leader,
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
    @HiveField(2) required String contact,
    @HiveField(3) required PurchaseGroupRole role,
    @HiveField(4) @Default(false) bool isSignedIn,
  }) = _PurchaseGroupMember;
  
  // カスタムコンストラクタでmemberIdを自動生成
  factory PurchaseGroupMember.create({
    String? memberId,
    required String name,
    required String contact,
    required PurchaseGroupRole role,
    bool isSignedIn = false,
  }) {
    return PurchaseGroupMember(
      memberId: memberId?.isNotEmpty == true ? memberId! : uuid.v4(),
      name: name,
      contact: contact,
      role: role,
      isSignedIn: isSignedIn,
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
  }) {
    return PurchaseGroupMember(
      name: name ?? this.name,
      memberId: memberId ?? this.memberId,
      contact: contact ?? this.contact,
      role: role ?? this.role,
      isSignedIn: isSignedIn ?? this.isSignedIn,
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
