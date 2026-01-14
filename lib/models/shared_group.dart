import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'shared_group.g.dart';
part 'shared_group.freezed.dart';

const uuid = Uuid();

// グループの役割を定義するenum
@HiveType(typeId: 0)
enum SharedGroupRole {
  @HiveField(0)
  owner,
  @HiveField(1)
  member,
  @HiveField(2)
  manager,
  @HiveField(3)
  partner, // パートナー招待で追加されたメンバー（全グループへの管理者権限）
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

// 招待タイプを定義するenum
@HiveType(typeId: 9)
enum InvitationType {
  @HiveField(0)
  individual, // 個別グループ招待
  @HiveField(1)
  partner, // パートナー招待（全グループへの管理者アクセス）
}

// 同期ステータスを定義するenum
@HiveType(typeId: 10)
enum SyncStatus {
  @HiveField(0)
  synced, // Firestoreと同期済み
  @HiveField(1)
  pending, // 招待受諾中（プレースホルダー）
  @HiveField(2)
  local, // ローカルのみ（Firestoreに未送信）
}

// グループタイプを定義するenum
@HiveType(typeId: 11)
enum GroupType {
  @HiveField(0)
  shopping, // 買い物リストグループ（デフォルト）
  @HiveField(1)
  todo, // TODOタスク管理グループ
}

@HiveType(typeId: 1)
@freezed
class SharedGroupMember with _$SharedGroupMember {
  const factory SharedGroupMember({
    @HiveField(0) @Default('') String memberId,
    @HiveField(1) required String name,
    @HiveField(2) required String contact, // email または phone
    @HiveField(3) required SharedGroupRole role,
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
  }) = _SharedGroupMember;

  factory SharedGroupMember.fromJson(Map<String, dynamic> json) =>
      _$SharedGroupMemberFromJson(json);

  // カスタムコンストラクタでmemberIdを自動生成
  factory SharedGroupMember.create({
    String? memberId,
    required String name,
    required String contact,
    required SharedGroupRole role,
    bool isSignedIn = false,
    InvitationStatus invitationStatus = InvitationStatus.self,
    String? securityKey,
    DateTime? invitedAt,
    DateTime? acceptedAt,
    // 後方互換性のため
    bool isInvited = false,
    bool isInvitationAccepted = false,
  }) {
    return SharedGroupMember(
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
extension SharedGroupMemberExtension on SharedGroupMember {
  // Hive のアダプターに対応するためのメソッド
  SharedGroupMember copyWithExtra({
    String? name,
    String? memberId,
    String? contact,
    SharedGroupRole? role,
    bool? isSignedIn,
    InvitationStatus? invitationStatus,
    String? securityKey,
    DateTime? invitedAt,
    DateTime? acceptedAt,
    // 後方互換性
    bool? isInvited,
    bool? isInvitationAccepted,
  }) {
    return SharedGroupMember(
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
class SharedGroup with _$SharedGroup {
  const SharedGroup._(); // Freezedでカスタムメソッドを使うためプライベートコンストラクタを追加

  const factory SharedGroup({
    @HiveField(0) required String groupName,
    @HiveField(1) required String groupId,
    @HiveField(2) String? ownerName,
    @HiveField(3) String? ownerEmail,
    @HiveField(4) String? ownerUid,
    @HiveField(5) List<SharedGroupMember>? members,
    @HiveField(6) String? ownerMessage,
    // @HiveField(7) @Default([]) List<String> sharedListIds, // サブコレクション化のため不要に
    @HiveField(11) @Default([]) List<String> allowedUid,
    @HiveField(12) @Default(false) bool isSecret,
    // acceptedUid: [{uid: securityKey}] のような構造を想定
    @HiveField(13) @Default([]) List<Map<String, String>> acceptedUid,
    // 削除フラグと最終アクセス日時
    @HiveField(14) @Default(false) bool isDeleted,
    @HiveField(15) DateTime? lastAccessedAt,
    @HiveField(16) DateTime? createdAt,
    @HiveField(17) DateTime? updatedAt,
    @HiveField(18) @Default(SyncStatus.synced) SyncStatus syncStatus,
    @HiveField(19)
    @Default(GroupType.shopping)
    GroupType groupType, // グループタイプ追加

    // 🆕 階層構造管理（HiveField 20-21）
    @HiveField(20) String? parentGroupId, // 親グループID
    @HiveField(21) @Default([]) List<String> childGroupIds, // 子グループIDリスト

    // 🆕 権限管理（HiveField 22-24）
    @HiveField(22)
    @Default({})
    Map<String, int> memberPermissions, // userId → permission bits
    @HiveField(23) @Default(0x03) int defaultPermission, // デフォルト権限（READ | DONE）
    @HiveField(24) @Default(true) bool inheritParentLists, // 親グループのリストを継承表示するか
  }) = _SharedGroup;

  factory SharedGroup.fromJson(Map<String, dynamic> json) =>
      _$SharedGroupFromJson(json);

  // カスタムコンストラクタでIDを自動生成
  factory SharedGroup.create({
    required String groupName,
    required List<SharedGroupMember> members,
    String? groupId,
    String? ownerMessage,
    // List<String>? sharedListIds, // サブコレクション化のため不要に
    bool isSecret = false,
  }) {
    final owner = members.firstWhere(
      (m) => m.role == SharedGroupRole.owner,
      orElse: () => throw Exception('Owner not found in members list'),
    );

    final now = DateTime.now();
    return SharedGroup(
      groupName: groupName,
      groupId: groupId ?? uuid.v4(),
      ownerName: owner.name,
      ownerEmail: owner.contact,
      ownerUid: owner.memberId,
      members: members,
      ownerMessage: ownerMessage,
      // sharedListIds: sharedListIds ?? [], // サブコレクション化のため不要に
      allowedUid: [owner.memberId], // 作成者を自動的に許可リストに追加
      isSecret: isSecret,
      acceptedUid: [],
      isDeleted: false,
      lastAccessedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  // 新しいメンバーを追加するメソッド
  SharedGroup addMember(SharedGroupMember member) {
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

  SharedGroup removeMember(SharedGroupMember member) {
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
  SharedGroup inviteMember({
    required String name,
    required String contact,
    required SharedGroupRole role,
    required String securityKey,
  }) {
    final tempMemberId = 'temp_${uuid.v4()}';
    final newMember = SharedGroupMember.create(
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
  SharedGroup acceptInvitation(String tempMemberId, String newUid) {
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
  SharedGroup cancelInvitation(String memberId) {
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
  List<SharedGroupMember> get pendingInvitations {
    return (members ?? [])
        .where((m) => m.invitationStatus == InvitationStatus.pending)
        .toList();
  }

  // アクティブなメンバー（招待受諾済みまたは自己）のリストを取得
  List<SharedGroupMember> get activeMembers {
    return (members ?? [])
        .where((m) =>
            m.invitationStatus == InvitationStatus.accepted ||
            m.invitationStatus == InvitationStatus.self)
        .toList();
  }

  // 最終アクセス日時を更新
  SharedGroup markAsAccessed() {
    return copyWith(
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // グループを削除済みとしてマーク
  SharedGroup markAsDeleted() {
    return copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
  }

  // 🆕 階層構造関連のヘルパーメソッド

  /// このグループが親グループを持つか
  bool get hasParent => parentGroupId != null && parentGroupId!.isNotEmpty;

  /// このグループが子グループを持つか
  bool get hasChildren => childGroupIds.isNotEmpty;

  /// ルートグループか（親を持たない）
  bool get isRoot => !hasParent;

  /// 階層の深さを取得（ルートは0）
  int getHierarchyDepth(Map<String, SharedGroup> allGroups) {
    if (isRoot) return 0;
    final parent = allGroups[parentGroupId];
    if (parent == null) return 0;
    return 1 + parent.getHierarchyDepth(allGroups);
  }

  // 🆕 権限管理関連のヘルパーメソッド

  /// 指定ユーザーの権限を取得
  ///
  /// オーナーは常に全権限、それ以外は設定された権限またはデフォルト権限
  int getUserPermission(String userId) {
    // オーナーは全権限
    if (ownerUid == userId) return 0xFF; // Permission.FULL

    // 直接設定された権限があればそれを返す
    if (memberPermissions.containsKey(userId)) {
      return memberPermissions[userId]!;
    }

    // デフォルト権限を返す
    return defaultPermission;
  }

  /// 指定ユーザーが特定の権限を持っているかチェック
  bool hasPermission(String userId, int requiredPermission) {
    final userPerm = getUserPermission(userId);
    return (userPerm & requiredPermission) == requiredPermission;
  }

  /// グループ階層パスを取得（例: "本部 > 営業部 > 東京支店"）
  String getHierarchyPath(Map<String, SharedGroup> allGroups,
      {String separator = ' > '}) {
    if (isRoot) return groupName;

    final parent = allGroups[parentGroupId];
    if (parent == null) return groupName;

    return '${parent.getHierarchyPath(allGroups, separator: separator)}$separator$groupName';
  }

  // グループが削除されているかチェック
  bool get isDeletedGroup => isDeleted;

  // sharedListIds関連のメソッドはサブコレクション化により不要になったため削除
}
