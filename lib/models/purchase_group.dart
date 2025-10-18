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
  @HiveField(3)
  friend, // フレンド招待で追加されたメンバー
}

// 招待状態を定義するenum
@HiveType(typeId: 8)
enum InvitationStatus {
  @HiveField(0)
  self,        // 自分（招待ではない）
  @HiveField(1)
  pending,     // 招待中
  @HiveField(2)
  accepted,    // 受諾済み
  @HiveField(3)
  deleted,     // アカウント削除済み
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
    // 新しい招待管理フィールド
    @HiveField(9) @Default(InvitationStatus.self) InvitationStatus invitationStatus,
    @HiveField(10) String? securityKey, // 招待時のセキュリティキー
    @HiveField(7) DateTime? invitedAt, // 招待日時
    @HiveField(8) DateTime? acceptedAt, // 受諾日時
    // 既存のフィールドは後方互換性のため残す（非推奨）
    @HiveField(5) @Default(false) @Deprecated('Use invitationStatus instead') bool isInvited,
    @HiveField(6) @Default(false) @Deprecated('Use invitationStatus instead') bool isInvitationAccepted,
  }) = _PurchaseGroupMember;
  
  // カスタムコンストラクタでmemberIdを自動生成
  factory PurchaseGroupMember.create({
    String? memberId,
    required String name,
    required String contact,
    required PurchaseGroupRole role,
    bool isSignedIn = false,
    InvitationStatus invitationStatus = InvitationStatus.self,
    String? securityKey,
    DateTime? invitedAt,
    DateTime? acceptedAt,
    // 後方互換性のため
    bool isInvited = false,
    bool isInvitationAccepted = false,
  }) {
    return PurchaseGroupMember(
      memberId: memberId?.isNotEmpty == true ? memberId! : uuid.v4(),
      name: name,
      contact: contact,
      role: role,
      isSignedIn: isSignedIn,
      invitationStatus: invitationStatus,
      securityKey: securityKey,
      invitedAt: invitedAt,
      acceptedAt: acceptedAt,
      isInvited: isInvited,
      isInvitationAccepted: isInvitationAccepted,
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
    InvitationStatus? invitationStatus,
    String? securityKey,
    DateTime? invitedAt,
    DateTime? acceptedAt,
    // 後方互換性
    bool? isInvited,
    bool? isInvitationAccepted,
  }) {
    return PurchaseGroupMember(
      name: name ?? this.name,
      memberId: memberId ?? this.memberId,
      contact: contact ?? this.contact,
      role: role ?? this.role,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      securityKey: securityKey ?? this.securityKey,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      isInvited: isInvited ?? this.isInvited,
      isInvitationAccepted: isInvitationAccepted ?? this.isInvitationAccepted,
    );
  }
  
  // 招待状態を判定するヘルパーメソッド
  bool get isPending => invitationStatus == InvitationStatus.pending;
  bool get isAccepted => invitationStatus == InvitationStatus.accepted;
  bool get isDeleted => invitationStatus == InvitationStatus.deleted;
  bool get isSelf => invitationStatus == InvitationStatus.self;
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
    @HiveField(6) String? ownerMessage, // オーナーからメンバーへのメッセージ
    @HiveField(7) List<String>? shoppingListIds, // 複数のショッピングリストID管理（古いデータ互換のためnullable）
  }) = _PurchaseGroup;

  // カスタムコンストラクタでIDを自動生成
  factory PurchaseGroup.create({
    required String groupName,
    String? ownerName,
    String? ownerEmail,
    required List<PurchaseGroupMember>? members,
    String? ownerUid,
    String? groupId,
    String? ownerMessage,
    List<String>? shoppingListIds,
  }) {
    return PurchaseGroup(
      groupName: groupName,
      groupId: groupId ?? uuid.v4(),
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerUid: ownerUid ?? uuid.v4(),
      members: members,
      ownerMessage: ownerMessage,
      shoppingListIds: shoppingListIds ?? [], // nullの場合は空リストを設定
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
    String? ownerMessage,
    List<String>? shoppingListIds,
  }) {
    return PurchaseGroup(
      groupName: groupName ?? this.groupName,
      groupId: groupId ?? this.groupId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerUid: ownerUid ?? this.ownerUid,
      members: members ?? this.members,
      ownerMessage: ownerMessage ?? this.ownerMessage,
      shoppingListIds: shoppingListIds ?? this.shoppingListIds,
    );
  }

  /// ショッピングリスト管理メソッド
  // 新しいショッピングリストIDを追加
  PurchaseGroup addShoppingList(String listId) {
    final currentList = shoppingListIds ?? [];
    if (currentList.contains(listId)) return this;
    return copyWith(
      shoppingListIds: [...currentList, listId],
    );
  }

  // ショッピングリストIDを削除
  PurchaseGroup removeShoppingList(String listId) {
    final currentList = shoppingListIds ?? [];
    return copyWith(
      shoppingListIds: currentList.where((id) => id != listId).toList(),
    );
  }

  // 指定したショッピングリストが存在するか確認
  bool hasShoppingList(String listId) {
    return shoppingListIds?.contains(listId) ?? false;
  }

  // メインのショッピングリストID（最初のリスト）を取得
  String? get primaryShoppingListId {
    final currentList = shoppingListIds ?? [];
    return currentList.isEmpty ? null : currentList.first;
  }

  // ショッピングリスト数を取得
  int get shoppingListCount {
    return shoppingListIds?.length ?? 0;
  }
}
