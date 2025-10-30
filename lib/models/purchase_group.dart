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
  self, // 自分（招待ではない）
  @HiveField(1)
  pending, // 招待中
  @HiveField(2)
  accepted, // 受諾済み
  @HiveField(3)
  deleted, // アカウント削除済み
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
    @HiveField(9)
    @Default(InvitationStatus.self)
    InvitationStatus invitationStatus,
    @HiveField(10) String? securityKey, // 招待時のセキュリティキー
    @HiveField(7) DateTime? invitedAt, // 招待日時
    @HiveField(8) DateTime? acceptedAt, // 受諾日時
    // 既存のフィールドは後方互換性のため残す（非推奨）
    @HiveField(5)
    @Default(false)
    @Deprecated('Use invitationStatus instead')
    bool isInvited,
    @HiveField(6)
    @Default(false)
    @Deprecated('Use invitationStatus instead')
    bool isInvitationAccepted,
  }) = _PurchaseGroupMember;

  factory PurchaseGroupMember.fromJson(Map<String, dynamic> json) =>
      _$PurchaseGroupMemberFromJson(json);

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
  const PurchaseGroup._(); // Freezedでカスタムメソッドを使うためプライベートコンストラクタを追加

  const factory PurchaseGroup({
    @HiveField(0) required String groupName,
    @HiveField(1) required String groupId,
    @HiveField(2) String? ownerName,
    @HiveField(3) String? ownerEmail,
    @HiveField(4) String? ownerUid,
    @HiveField(5) List<PurchaseGroupMember>? members,
    @HiveField(6) String? ownerMessage,
    // @HiveField(7) @Default([]) List<String> shoppingListIds, // サブコレクション化のため不要に
    @HiveField(11) @Default([]) List<String> allowedUid,
    @HiveField(12) @Default(false) bool isSecret,
    // acceptedUid: [{uid: securityKey}] のような構造を想定
    @HiveField(13) @Default([]) List<Map<String, String>> acceptedUid,
  }) = _PurchaseGroup;

  factory PurchaseGroup.fromJson(Map<String, dynamic> json) =>
      _$PurchaseGroupFromJson(json);

  // カスタムコンストラクタでIDを自動生成
  factory PurchaseGroup.create({
    required String groupName,
    required List<PurchaseGroupMember> members,
    String? groupId,
    String? ownerMessage,
    // List<String>? shoppingListIds, // サブコレクション化のため不要に
    bool isSecret = false,
  }) {
    final owner = members.firstWhere(
      (m) => m.role == PurchaseGroupRole.owner,
      orElse: () => throw Exception('Owner not found in members list'),
    );

    return PurchaseGroup(
      groupName: groupName,
      groupId: groupId ?? uuid.v4(),
      ownerName: owner.name,
      ownerEmail: owner.contact,
      ownerUid: owner.memberId,
      members: members,
      ownerMessage: ownerMessage,
      // shoppingListIds: shoppingListIds ?? [], // サブコレクション化のため不要に
      allowedUid: [owner.memberId], // 作成者を自動的に許可リストに追加
      isSecret: isSecret,
      acceptedUid: [],
    );
  }

  // 新しいメンバーを追加するメソッド
  PurchaseGroup addMember(PurchaseGroupMember member) {
    final newMembers = (members ?? [])
        .where((m) => m.memberId != member.memberId)
        .toList()
      ..add(member);

    // メンバーのUIDがallowedUidになければ追加
    final newAllowedUids = List<String>.from(allowedUid);
    if (!newAllowedUids.contains(member.memberId)) {
      newAllowedUids.add(member.memberId);
    }

    return copyWith(
      members: newMembers,
      allowedUid: newAllowedUids,
    );
  }

  PurchaseGroup removeMember(PurchaseGroupMember member) {
    final newMembers =
        (members ?? []).where((m) => m.memberId != member.memberId).toList();
    final newAllowedUids =
        allowedUid.where((uid) => uid != member.memberId).toList();

    return copyWith(
      members: newMembers,
      allowedUid: newAllowedUids,
    );
  }

  // 招待機能メソッド
  PurchaseGroup inviteMember({
    required String name,
    required String contact,
    required PurchaseGroupRole role,
    required String securityKey,
  }) {
    final tempMemberId = 'temp_${uuid.v4()}';
    final newMember = PurchaseGroupMember.create(
      memberId: tempMemberId,
      name: name,
      contact: contact,
      role: role,
      invitationStatus: InvitationStatus.pending,
      invitedAt: DateTime.now(),
      securityKey: securityKey,
    );

    final newAcceptedUids = List<Map<String, String>>.from(acceptedUid);
    newAcceptedUids.add({tempMemberId: securityKey});

    return copyWith(
      members: [...?members, newMember],
      acceptedUid: newAcceptedUids,
    );
  }

  // 招待を受諾
  PurchaseGroup acceptInvitation(String tempMemberId, String newUid) {
    final updatedMembers = (members ?? []).map((member) {
      if (member.memberId == tempMemberId &&
          member.invitationStatus == InvitationStatus.pending) {
        return member.copyWith(
          memberId: newUid, // UIDを新しいものに更新
          invitationStatus: InvitationStatus.accepted,
          acceptedAt: DateTime.now(),
          securityKey: null, // 受諾後は不要
        );
      }
      return member;
    }).toList();

    // allowedUidに新しいUIDを追加
    final newAllowedUids = [...allowedUid, newUid];
    // acceptedUidから仮IDのエントリを削除
    final newAcceptedUids = List<Map<String, String>>.from(acceptedUid)
      ..removeWhere((map) => map.containsKey(tempMemberId));

    return copyWith(
      members: updatedMembers,
      allowedUid: newAllowedUids,
      acceptedUid: newAcceptedUids,
    );
  }

  // 招待をキャンセル
  PurchaseGroup cancelInvitation(String memberId) {
    final newMembers =
        (members ?? []).where((m) => m.memberId != memberId).toList();
    final newAcceptedUids = List<Map<String, String>>.from(acceptedUid)
      ..removeWhere((map) => map.containsKey(memberId));

    return copyWith(
      members: newMembers,
      acceptedUid: newAcceptedUids,
    );
  }

  // 招待待ちメンバーのリストを取得
  List<PurchaseGroupMember> get pendingInvitations {
    return (members ?? [])
        .where((m) => m.invitationStatus == InvitationStatus.pending)
        .toList();
  }

  // アクティブなメンバー（招待受諾済みまたは自己）のリストを取得
  List<PurchaseGroupMember> get activeMembers {
    return (members ?? [])
        .where((m) =>
            m.invitationStatus == InvitationStatus.accepted ||
            m.invitationStatus == InvitationStatus.self)
        .toList();
  }

  // shoppingListIds関連のメソッドはサブコレクション化により不要になったため削除
}
