import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
part 'purchase_group.g.dart';

final uuid = const Uuid();
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
class PurchaseGroupMember {
  @HiveField(0)
  String memberId;
  @HiveField(1)
  String name;
  @HiveField(2)
  String contact;
  @HiveField(3)
  PurchaseGroupRole role;
  @HiveField(4)
  bool isSignedIn;
  
  PurchaseGroupMember({
    this.memberId = '',
    required this.name,
    required this.contact,
    required this.role,
    this.isSignedIn = false,
  }) {
    memberId = memberId.isNotEmpty ? memberId : uuid.v4();
  }

  //
  PurchaseGroupMember copyWith({
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
  

/// 家族メンバーのデータを管理するクラス
/// @JsonSerializable()アノテーションを追加
@HiveType(typeId: 2)
class PurchaseGroup {
  @HiveField(0)
  String groupName;
  @HiveField(1)
  String groupId;
  @HiveField(2)
  String? ownerName;
  @HiveField(3)
  String? ownerEmail;
  @HiveField(4)
  String? ownerUid;
  @HiveField(5)
  List<PurchaseGroupMember>? members;

  // 新しい購入グループを作成するためのコンストラクタ
  PurchaseGroup({
    required this.groupName,
    this.ownerName,
    this.ownerEmail,
    required this.members,
    String? ownerUid,
    String? groupId,
  }) : ownerUid = ownerUid ?? uuid.v4(),
       groupId = groupId ?? uuid.v4();

  // 新しいメンバーを追加するメソッド
  PurchaseGroup addMember(PurchaseGroupMember member) {
    // 新しいmemberIDを生成（既存メンバーの最大ID + 1）
    // 新しいメンバーを作成（指定されたメンバー情報にnewMemberIdを設定）
    // 新しいPurchaseGroupインスタンスを返す
    if (members == null) {
      return PurchaseGroup(
        groupName: groupName,
        groupId: groupId,
        members: [PurchaseGroupMember(
          name: member.name,
          contact: member.contact,
          role: member.role,
          memberId: member.memberId
        )],
      );
    } else {
      return PurchaseGroup(
        groupName: groupName,
        groupId: groupId,
        members: [...members!, PurchaseGroupMember(
          name: member.name,
          contact: member.contact,
          role: member.role,
          memberId: member.memberId
        )],
      );
    }
  }

  PurchaseGroup removeMember(PurchaseGroupMember member) {
    return PurchaseGroup(
      groupName: groupName,
      groupId: groupId,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerUid: ownerUid,
      members: members!.where((m) => m != member).toList(),
    );
  }

  PurchaseGroup copyWith({
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