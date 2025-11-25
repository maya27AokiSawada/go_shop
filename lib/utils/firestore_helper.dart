// lib/utils/firestore_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_group.dart';
import 'firestore_converter.dart';
import 'app_logger.dart';

/// Firestore 操作のヘルパークラス
/// グループデータの取得処理を一元化
class FirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 特定グループを Firestore から取得
  ///
  /// [groupId] グループID
  ///
  /// 戻り値: SharedGroup または null (グループが存在しない場合)
  static Future<SharedGroup?> fetchGroup(String groupId) async {
    try {
      final doc =
          await _firestore.collection('SharedGroups').doc(groupId).get();

      if (!doc.exists) {
        AppLogger.warning('⚠️ [FIRESTORE] グループが存在しません: $groupId');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        AppLogger.warning('⚠️ [FIRESTORE] グループデータが空です: $groupId');
        return null;
      }

      // Timestamp変換してSharedGroupに変換
      final convertedData = FirestoreConverter.convertTimestamps(data);
      final group = SharedGroup.fromJson(convertedData);

      AppLogger.info(
          '✅ [FIRESTORE] グループ取得: ${group.groupName}, allowedUid: ${group.allowedUid}');

      return group;
    } catch (e) {
      AppLogger.error('❌ [FIRESTORE] グループ取得エラー ($groupId): $e');
      return null;
    }
  }

  /// ユーザーの全グループを Firestore から取得
  ///
  /// [userId] ユーザーID
  /// [includeDeleted] 削除済みグループを含めるか (デフォルト: false)
  ///
  /// 戻り値: SharedGroup のリスト
  static Future<List<SharedGroup>> fetchUserGroups(
    String userId, {
    bool includeDeleted = false,
  }) async {
    try {
      var query = _firestore
          .collection('SharedGroups')
          .where('allowedUid', arrayContains: userId);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      final snapshot = await query.get();

      final groups = <SharedGroup>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final convertedData = FirestoreConverter.convertTimestamps(data);
          final group = SharedGroup.fromJson(convertedData).copyWith(
            groupId: doc.id, // ドキュメントIDを確実に設定
          );
          groups.add(group);
        } catch (e) {
          AppLogger.warning('⚠️ [FIRESTORE] グループ変換エラー (${doc.id}): $e');
        }
      }

      AppLogger.info(
          '✅ [FIRESTORE] ユーザーグループ取得: ${groups.length}個 (UID: $userId)');

      return groups;
    } catch (e) {
      AppLogger.error('❌ [FIRESTORE] ユーザーグループ取得エラー: $e');
      return [];
    }
  }

  /// グループの存在確認
  static Future<bool> groupExists(String groupId) async {
    try {
      final doc =
          await _firestore.collection('SharedGroups').doc(groupId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.error('❌ [FIRESTORE] グループ存在確認エラー: $e');
      return false;
    }
  }
}
