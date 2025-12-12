import '../models/shared_group.dart';
import '../models/firestore_shared_list.dart';

/// アクセス権限を管理するヘルパークラス
class AccessControlHelper {
  /// ユーザーがSharedGroupのメンバーかどうかをチェック
  static bool isGroupMember(SharedGroup group, String uid) {
    if (group.ownerUid == uid) return true;
    
    final activeMembers = group.activeMembers;
    return activeMembers.any((member) => member.memberId == uid);
  }

  /// ユーザーがSharedListにアクセス権限を持つかどうかをチェック
  static bool canAccessSharedList(
    FirestoreSharedList sharedList, 
    String uid, 
    SharedGroup? group
  ) {
    // オーナーは常にアクセス可能
    if (sharedList.hasOwnerAccess(uid)) return true;
    
    // グループが存在し、そのメンバーならアクセス可能
    if (group != null && sharedList.groupId == group.groupId) {
      return isGroupMember(group, uid);
    }
    
    return false;
  }

  /// ユーザーがSharedListを編集する権限を持つかどうかをチェック
  static bool canEditSharedList(
    FirestoreSharedList sharedList, 
    String uid, 
    SharedGroup? group
  ) {
    // 基本的にはアクセス権限と同じ
    // 将来的にはより細かい権限制御を追加可能
    return canAccessSharedList(sharedList, uid, group);
  }

  /// ユーザーがSharedGroupを管理する権限を持つかどうかをチェック
  static bool canManageGroup(SharedGroup group, String uid) {
    return group.ownerUid == uid;
  }

  /// ユーザーがグループに招待を送る権限を持つかどうかをチェック
  static bool canInviteToGroup(SharedGroup group, String uid) {
    // オーナーと親役割のメンバーが招待可能
    if (group.ownerUid == uid) return true;
    
    final activeMembers = group.activeMembers;
    final userMember = activeMembers.where((member) => member.memberId == uid).firstOrNull;
    
    return userMember?.role == SharedGroupRole.owner;
  }

  /// グループの管理者権限（オーナーまたは管理者）を持つかチェック（将来の招待機能用）
  static bool hasManagerPermission(SharedGroup? group, String? uid) {
    if (group == null || uid == null || uid.isEmpty) return false;
    
    // グループオーナーなら管理者権限あり
    if (group.ownerUid == uid) return true;
    
    final activeMembers = group.activeMembers;
    final userMember = activeMembers.where((member) => member.memberId == uid).firstOrNull;
    
    return userMember?.role == SharedGroupRole.owner || 
           userMember?.role == SharedGroupRole.manager;
  }

  /// Firestore用：SharedGroupからアクセス権限のあるUIDs（memberIds）を抽出
  static List<String> extractAuthorizedUids(SharedGroup group) {
    final List<String> uids = [group.ownerUid ?? ''];
    
    // アクティブなメンバーのIDを追加
    final activeMembers = group.activeMembers;
    for (final member in activeMembers) {
      if (member.memberId.isNotEmpty && !uids.contains(member.memberId)) {
        uids.add(member.memberId);
      }
    }
    
    return uids.where((uid) => uid.isNotEmpty).toList();
  }

  /// 開発用：セキュリティチェックをバイパス（dev環境でのみ使用）
  static bool isDevelopmentMode = true; // 本番環境ではfalseに設定
  
  static bool allowAccessInDevelopment() {
    return isDevelopmentMode;
  }

  /// 統合アクセスチェック（開発環境考慮）
  static bool checkAccess({
    required String operation, // 'read', 'write', 'create', 'delete'
    required String resourceType, // 'sharedList', 'SharedGroup'
    required String uid,
    FirestoreSharedList? sharedList,
    SharedGroup? group,
  }) {
    // 開発環境では全てのアクセスを許可
    if (allowAccessInDevelopment()) {
      return true;
    }
    
    // 本番環境での詳細チェック
    switch (resourceType) {
      case 'sharedList':
        if (sharedList == null) return false;
        switch (operation) {
          case 'read':
          case 'write':
            return canAccessSharedList(sharedList, uid, group);
          case 'create':
          case 'delete':
            return sharedList.hasOwnerAccess(uid);
          default:
            return false;
        }
      case 'SharedGroup':
        if (group == null) return false;
        switch (operation) {
          case 'read':
            return isGroupMember(group, uid);
          case 'write':
          case 'create':
          case 'delete':
            return canManageGroup(group, uid);
          default:
            return false;
        }
      default:
        return false;
    }
  }
}
