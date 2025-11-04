// lib/helper/security_validator.dart
import 'package:firebase_auth/firebase_auth.dart';

import '../models/purchase_group.dart';
import '../flavors.dart';
import '../utils/app_logger.dart';

/// 本番環境セキュリティ検証ヘルパー
class SecurityValidator {
  /// Firebase Auth UIDと uidの整合性チェック
  static bool validateMemberIdConsistency(
      PurchaseGroup group, String currentUid) {
    // 開発環境ではスキップ
    if (F.appFlavor == Flavor.dev) return true;

    final member = group.members.firstWhere(
      (m) => m.uid == currentUid,
      orElse: () => throw SecurityException('User not found in group members'),
    );

    // uidとFirebase Auth UIDの一致確認
    return member.uid == currentUid;
  }

  /// オーナー権限の厳密チェック
  static bool validateOwnerAccess(PurchaseGroup group, String currentUid) {
    // 開発環境ではスキップ
    if (F.appFlavor == Flavor.dev) return true;

    // FirestoreルールでチェックされるownerUidと一致するかチェック
    return group.ownerUid == currentUid;
  }

  /// メンバー権限の厳密チェック
  static bool validateMemberAccess(PurchaseGroup group, String currentUid) {
    // 開発環境ではスキップ
    if (F.appFlavor == Flavor.dev) return true;

    // オーナーアクセス
    if (validateOwnerAccess(group, currentUid)) return true;

    // メンバーリストでのUID確認（v4: isInvitationAccepted削除、joinedAtで判定）
    return group.members
        .any((member) => member.uid == currentUid && member.joinedAt != null);
  }

  /// 招待権限の厳密チェック
  static bool validateInvitePermission(PurchaseGroup group, String currentUid) {
    // 開発環境ではスキップ
    if (F.appFlavor == Flavor.dev) return true;

    // オーナーは常に招待可能
    if (validateOwnerAccess(group, currentUid)) return true;

    // 管理者も招待可能
    final member = group.members.firstWhere(
      (m) => m.uid == currentUid,
      orElse: () => throw SecurityException('User not found in group members'),
    );

    return member.role == PurchaseGroupRole.manager && member.joinedAt != null;
  }

  /// Firestoreセキュリティルール準拠チェック
  static void validateFirestoreRuleCompliance({
    required String operation, // 'read', 'write', 'create', 'delete'
    required String resourceType, // 'purchaseGroup', 'shoppingList'
    required PurchaseGroup group,
    required String currentUid,
  }) {
    // 本番環境のみチェック
    if (F.appFlavor == Flavor.dev) return;

    switch (operation) {
      case 'read':
        if (!validateMemberAccess(group, currentUid)) {
          throw SecurityException(
              'Read access denied: User is not a group member');
        }
        break;
      case 'write':
      case 'delete':
        if (!validateOwnerAccess(group, currentUid)) {
          throw SecurityException(
              'Write access denied: User is not the group owner');
        }
        break;
      case 'create':
        // 作成時は current user が owner になる前提
        break;
      default:
        throw SecurityException('Unknown operation: $operation');
    }
  }

  /// メンバーID修復（Firebase UIDとの整合性確保）
  static Future<PurchaseGroup> repairMemberIds(PurchaseGroup group) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return group;

    // メンバーリストでcurrentUserのエントリを探してUIDを修復
    final updatedMembers = group.members.map((member) {
      // emailが一致するメンバーのuidをFirebase UIDに修正
      if (member.contact == currentUser.email &&
          member.uid != currentUser.uid) {
        Log.info('🔧 Member ID repair: ${member.uid} -> ${currentUser.uid}');
        return member.copyWith(uid: currentUser.uid);
      }
      return member;
    }).toList();

    return group.copyWith(members: updatedMembers);
  }
}

/// セキュリティ例外クラス
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
