// lib/utils/group_helpers.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_group.dart';

/// デフォルトグループかどうかを判定
///
/// デフォルトグループの条件:
/// 1. groupId == 'default_group' (固定文字列、レガシー対応)
/// 2. groupId == user.uid (ユーザー専用グループ)
bool isDefaultGroup(PurchaseGroup group, User? currentUser) {
  // 固定文字列チェック（レガシー対応）
  if (group.groupId == 'default_group') {
    return true;
  }

  // ユーザーUID一致チェック
  if (currentUser != null && group.groupId == currentUser.uid) {
    return true;
  }

  return false;
}

/// グループIDのみでデフォルトグループかどうかを判定
/// （User オブジェクトが不要な場合）
bool isDefaultGroupById(String groupId, String? currentUserId) {
  // 固定文字列チェック
  if (groupId == 'default_group') {
    return true;
  }

  // ユーザーUID一致チェック
  if (currentUserId != null && groupId == currentUserId) {
    return true;
  }

  return false;
}
