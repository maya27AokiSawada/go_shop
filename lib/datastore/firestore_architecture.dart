// lib/datastore/firestore_architecture.dart
/// Firestore Collection Architecture for Go Shop
///
/// Owner UID Collection Structure:
///
/// /users/{ownerUid}/SharedGroups/{groupId} - Purchase Group Document
/// /users/{ownerUid}/sharedLists/{listId} - Shopping List Document
///
/// Each Purchase Group contains:
/// - Basic group info (name, creation date, etc.)
/// - Members list with roles
/// - AcceptedUids list (users who accepted invitations)
/// - SharedListIds array (references to shopping lists)
///
/// Invitation Flow:
/// 1. Owner/Manager creates invitation for specific group
/// 2. If multiple groups have same email, show selection UI
/// 3. Invited user adds their UID to AcceptedUids list
/// 4. User sync happens only on invitation acceptance
///
/// Role-based Permissions:
/// - Owner: Full access, can invite others
/// - Manager: Can invite others, manage group
/// - Member: View and edit lists only
///
/// Group Management:
/// - Different roles require separate groups
/// - Provide UI to copy existing members when creating new group
/// - Multiple invitation selection for same email addresses

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_group.dart';

class FirestoreCollections {
  static const String users = 'users';
  static const String SharedGroups = 'SharedGroups';
  static const String sharedLists = 'sharedLists';

  /// Get user's purchase groups collection reference
  static CollectionReference<Map<String, dynamic>> getUserSharedGroups(
      String ownerUid) {
    return FirebaseFirestore.instance
        .collection(users)
        .doc(ownerUid)
        .collection(SharedGroups);
  }

  /// Get user's shopping lists collection reference
  static CollectionReference<Map<String, dynamic>> getUserSharedLists(
      String ownerUid) {
    return FirebaseFirestore.instance
        .collection(users)
        .doc(ownerUid)
        .collection(sharedLists);
  }

  /// Get specific purchase group document reference
  static DocumentReference<Map<String, dynamic>> getSharedGroupDoc(
      String ownerUid, String groupId) {
    return getUserSharedGroups(ownerUid).doc(groupId);
  }

  /// Get specific shopping list document reference
  static DocumentReference<Map<String, dynamic>> getSharedListDoc(
      String ownerUid, String listId) {
    return getUserSharedLists(ownerUid).doc(listId);
  }
}
