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
  final String name;
  @HiveField(1)
  String? memberID; //uid未判明の時はnull
  @HiveField(2)
  final String contact;
  @HiveField(3)
  final PurchaseGroupRole role;
  @HiveField(4)
  final bool isSignedIn;
  //
  PurchaseGroupMember({
    required this.name,
    this.memberID, //uid未判明の時はnull
    required this.contact,
    required this.role,
    this.isSignedIn = false,
  });
  //
  PurchaseGroupMember copyWith({
    String? name,
    String? memberID,
    String? contact,
    PurchaseGroupRole? role,
    bool? isSignedIn,
  }) {
    return PurchaseGroupMember(
      name: name ?? this.name,
      memberID: memberID ?? this.memberID,
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
  String groupID;
  @HiveField(2)
  List<PurchaseGroupMember> members;

  // 新しい購入グループを作成するためのコンストラクタ
  PurchaseGroup({
    required this.groupName,
    required this.members,
    String? groupID,
  }) : groupID = groupID ?? uuid.v4();

  // 新しいメンバーを追加するメソッド
  PurchaseGroup addMember(PurchaseGroupMember member) {
    // 新しいmemberIDを生成（既存メンバーの最大ID + 1）
      // 新しいメンバーを作成（指定されたメンバー情報にnewMemberIdを設定）
    // 新しいPurchaseGroupインスタンスを返す
    return PurchaseGroup(
      groupName: groupName,
      groupID: groupID,
      members: [...members, member],
    );
  }
  PurchaseGroup removeMember(PurchaseGroupMember member) {
    return PurchaseGroup(
      groupName: groupName,
      groupID: groupID,
      members: members.where((m) => m != member).toList(),
    );
  }

  PurchaseGroup copyWith({
    String? groupName,
    String? groupID,
    List<PurchaseGroupMember>? members,
  }) {
    return PurchaseGroup(
      groupName: groupName ?? this.groupName,
      groupID: groupID ?? this.groupID,
      members: members ?? this.members,
    );
  }
}