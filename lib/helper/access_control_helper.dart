import '../models/purchase_group.dart';
import '../models/firestore_shopping_list.dart';

/// アクセス権限を管理するヘルパークラス
class AccessControlHelper {
  /// ユーザーがPurchaseGroupのメンバーかどうかをチェック
  static bool isGroupMember(PurchaseGroup group, String uid) {
    if (group.ownerUid == uid) return true;
    
    final activeMembers = group.activeMembers;
    return activeMembers.any((member) => member.memberId == uid);
  }

  /// ユーザーがShoppingListにアクセス権限を持つかどうかをチェック
  static bool canAccessShoppingList(
    FirestoreShoppingList shoppingList, 
    String uid, 
    PurchaseGroup? group
  ) {
    // オーナーは常にアクセス可能
    if (shoppingList.hasOwnerAccess(uid)) return true;
    
    // グループが存在し、そのメンバーならアクセス可能
    if (group != null && shoppingList.groupId == group.groupId) {
      return isGroupMember(group, uid);
    }
    
    return false;
  }

  /// ユーザーがShoppingListを編集する権限を持つかどうかをチェック
  static bool canEditShoppingList(
    FirestoreShoppingList shoppingList, 
    String uid, 
    PurchaseGroup? group
  ) {
    // 基本的にはアクセス権限と同じ
    // 将来的にはより細かい権限制御を追加可能
    return canAccessShoppingList(shoppingList, uid, group);
  }

  /// ユーザーがPurchaseGroupを管理する権限を持つかどうかをチェック
  static bool canManageGroup(PurchaseGroup group, String uid) {
    return group.ownerUid == uid;
  }

  /// ユーザーがグループに招待を送る権限を持つかどうかをチェック
  static bool canInviteToGroup(PurchaseGroup group, String uid) {
    // オーナーと親役割のメンバーが招待可能
    if (group.ownerUid == uid) return true;
    
    final activeMembers = group.activeMembers;
    final userMember = activeMembers.where((member) => member.memberId == uid).firstOrNull;
    
    return userMember?.role == PurchaseGroupRole.owner;
  }

  /// Firestore用：PurchaseGroupからアクセス権限のあるUIDs（memberIds）を抽出
  static List<String> extractAuthorizedUids(PurchaseGroup group) {
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
    required String resourceType, // 'shoppingList', 'purchaseGroup'
    required String uid,
    FirestoreShoppingList? shoppingList,
    PurchaseGroup? group,
  }) {
    // 開発環境では全てのアクセスを許可
    if (allowAccessInDevelopment()) {
      return true;
    }
    
    // 本番環境での詳細チェック
    switch (resourceType) {
      case 'shoppingList':
        if (shoppingList == null) return false;
        switch (operation) {
          case 'read':
          case 'write':
            return canAccessShoppingList(shoppingList, uid, group);
          case 'create':
          case 'delete':
            return shoppingList.hasOwnerAccess(uid);
          default:
            return false;
        }
      case 'purchaseGroup':
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
