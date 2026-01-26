import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// ホワイトボード編集ロック管理
class WhiteboardEditLock {
  final FirebaseFirestore _firestore;

  WhiteboardEditLock({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ホワイトボードコレクション参照取得
  CollectionReference<Map<String, dynamic>> _whiteboardsCollection(
      String groupId) {
    return _firestore
        .collection('SharedGroups')
        .doc(groupId)
        .collection('whiteboards');
  }

  /// 🔒 編集ロックを取得（1時間有効）
  /// 戻り値: true=ロック取得成功, false=他ユーザーが編集中
  Future<bool> acquireEditLock({
    required String groupId,
    required String whiteboardId,
    required String userId,
    required String userName,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final whiteboardDocRef =
            _whiteboardsCollection(groupId).doc(whiteboardId);
        final snapshot = await transaction.get(whiteboardDocRef);

        if (!snapshot.exists) {
          throw Exception('ホワイトボードが存在しません');
        }

        final whiteboardData = snapshot.data()!;
        final editLock = whiteboardData['editLock'] as Map<String, dynamic>?;
        final now = DateTime.now();
        final lockExpiry = now.add(const Duration(hours: 1));

        if (editLock != null) {
          final currentUserId = editLock['userId'] as String?;
          final createdAt = (editLock['createdAt'] as Timestamp?)?.toDate();

          // 同じユーザーの場合は延長
          if (currentUserId == userId) {
            transaction.update(whiteboardDocRef, {
              'editLock.expiresAt': Timestamp.fromDate(lockExpiry),
              'editLock.updatedAt': FieldValue.serverTimestamp(),
            });
            AppLogger.info(
                '🔒 [LOCK] 編集ロック延長: ${AppLogger.maskUserId(userId)}');
            return true;
          }

          // ロックが有効期限内かチェック（1時間）
          if (createdAt != null && now.difference(createdAt).inHours < 1) {
            final currentUserName =
                editLock['userName'] as String? ?? 'Unknown';
            AppLogger.warning(
                '⚠️ [LOCK] 編集中ユーザー存在: ${AppLogger.maskName(currentUserName)}');
            return false; // 他ユーザーが編集中
          }

          // 期限切れのロックを削除して新しいロックを作成
          AppLogger.info(
              '🗑️ [LOCK] 期限切れロック削除: ${AppLogger.maskUserId(currentUserId)}');
        }

        // 新しい編集ロックを作成
        transaction.update(whiteboardDocRef, {
          'editLock': {
            'userId': userId,
            'userName': userName,
            'groupId': groupId,
            'whiteboardId': whiteboardId,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(lockExpiry),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        });

        AppLogger.info('✅ [LOCK] 編集ロック取得成功: ${AppLogger.maskName(userName)}');
        return true;
      });
    } catch (e) {
      AppLogger.error('❌ [LOCK] 編集ロック取得エラー: $e');
      return false;
    }
  }

  /// 🔓 編集ロックを解除
  Future<void> releaseEditLock({
    required String groupId,
    required String whiteboardId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final whiteboardDocRef =
            _whiteboardsCollection(groupId).doc(whiteboardId);
        final snapshot = await transaction.get(whiteboardDocRef);

        if (!snapshot.exists) return;

        final whiteboardData = snapshot.data()!;
        final editLock = whiteboardData['editLock'] as Map<String, dynamic>?;

        if (editLock != null) {
          final currentUserId = editLock['userId'] as String?;

          // 自分のロックの場合のみ削除
          if (currentUserId == userId) {
            transaction.update(whiteboardDocRef, {
              'editLock': FieldValue.delete(),
            });
            AppLogger.info(
                '🔓 [LOCK] 編集ロック解除: ${AppLogger.maskUserId(userId)}');
          } else {
            AppLogger.warning(
                '⚠️ [LOCK] 他ユーザーのロック解除試行: ${AppLogger.maskUserId(userId)}');
          }
        }
      });
    } catch (e) {
      AppLogger.error('❌ [LOCK] 編集ロック解除エラー: $e');
    }
  }

  /// 👥 現在の編集中ユーザー情報を取得
  Future<EditLockInfo?> getCurrentEditor({
    required String groupId,
    required String whiteboardId,
  }) async {
    try {
      final whiteboardDoc =
          await _whiteboardsCollection(groupId).doc(whiteboardId).get();

      if (!whiteboardDoc.exists) return null;

      final whiteboardData = whiteboardDoc.data()!;
      final editLock = whiteboardData['editLock'] as Map<String, dynamic>?;

      if (editLock == null) return null;

      final createdAt = (editLock['createdAt'] as Timestamp?)?.toDate();

      // 有効期限チェック（1時間）
      if (createdAt != null &&
          DateTime.now().difference(createdAt).inHours >= 1) {
        // 期限切れロックを削除
        await _whiteboardsCollection(groupId).doc(whiteboardId).update({
          'editLock': FieldValue.delete(),
        });
        AppLogger.info('🗑️ [LOCK] 期限切れロック自動削除');
        return null;
      }

      return EditLockInfo.fromMap(editLock);
    } catch (e) {
      AppLogger.error('❌ [LOCK] 編集中ユーザー情報取得エラー: $e');
      return null;
    }
  }

  /// 📡 編集ロック状態をリアルタイム監視
  Stream<EditLockInfo?> watchEditLock({
    required String groupId,
    required String whiteboardId,
  }) {
    return _whiteboardsCollection(groupId)
        .doc(whiteboardId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final whiteboardData = snapshot.data()!;
      final editLock = whiteboardData['editLock'] as Map<String, dynamic>?;

      if (editLock == null) return null;

      final createdAt = (editLock['createdAt'] as Timestamp?)?.toDate();

      // 有効期限チェック（1時間）
      if (createdAt != null &&
          DateTime.now().difference(createdAt).inHours >= 1) {
        // 期限切れの場合はnullを返す（自動削除は別途バックグラウンドで実行）
        return null;
      }

      return EditLockInfo.fromMap(editLock);
    });
  }

  /// 🧹 期限切れロックの一括クリーンアップ（メンテナンス用）
  Future<int> cleanupExpiredLocks({
    required String groupId,
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));
      final allWhiteboards = await _whiteboardsCollection(groupId).get();

      int deletedCount = 0;
      for (final doc in allWhiteboards.docs) {
        final whiteboardData = doc.data();
        final editLock = whiteboardData['editLock'] as Map<String, dynamic>?;

        if (editLock != null) {
          final createdAt = (editLock['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null && createdAt.isBefore(cutoffTime)) {
            await doc.reference.update({
              'editLock': FieldValue.delete(),
            });
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        AppLogger.info('🧹 [LOCK] 期限切れロック一括削除: $deletedCount件');
      }

      return deletedCount;
    } catch (e) {
      AppLogger.error('❌ [LOCK] 期限切れロッククリーンアップエラー: $e');
      return 0;
    }
  }

  /// 🗑️ 古いeditLocksコレクションを完全削除（マイグレーション用）
  Future<int> cleanupLegacyEditLocks({
    required String groupId,
  }) async {
    try {
      final legacyLocksCollection = _firestore
          .collection('SharedGroups')
          .doc(groupId)
          .collection('editLocks');

      final allLocks = await legacyLocksCollection.get();
      int deletedCount = 0;

      for (final doc in allLocks.docs) {
        await doc.reference.delete();
        deletedCount++;
        AppLogger.info('🗑️ [LOCK] 古いロック削除: ${doc.id}');
      }

      if (deletedCount > 0) {
        AppLogger.info('🧹 [LOCK] 古いeditLocksコレクション完全削除: $deletedCount件');
      }

      return deletedCount;
    } catch (e) {
      AppLogger.error('❌ [LOCK] 古いeditLocksクリーンアップエラー: $e');
      return 0;
    }
  }

  /// 💀 編集ロックを強制クリア（緊急時用）
  Future<bool> forceReleaseEditLock({
    required String groupId,
    required String whiteboardId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final whiteboardDocRef =
            _whiteboardsCollection(groupId).doc(whiteboardId);

        transaction.update(whiteboardDocRef, {
          'editLock': FieldValue.delete(),
        });

        AppLogger.info('💀 [LOCK] 編集ロック強制削除: $whiteboardId');
      });

      // 古いeditLocksコレクションも同時にクリーンアップ
      await cleanupLegacyEditLocks(groupId: groupId);

      return true;
    } catch (e) {
      AppLogger.error('❌ [LOCK] 編集ロック強制削除エラー: $e');
      return false;
    }
  }
}

/// 編集ロック情報
class EditLockInfo {
  final String userId;
  final String userName;
  final String groupId;
  final String whiteboardId;
  final DateTime createdAt;
  final DateTime expiresAt;

  const EditLockInfo({
    required this.userId,
    required this.userName,
    required this.groupId,
    required this.whiteboardId,
    required this.createdAt,
    required this.expiresAt,
  });

  factory EditLockInfo.fromMap(Map<String, dynamic> data) {
    return EditLockInfo(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      groupId: data['groupId'] as String,
      whiteboardId: data['whiteboardId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  /// ロックが有効か判定
  bool get isValid {
    return DateTime.now().isBefore(expiresAt);
  }

  /// 残り時間（分）
  int get remainingMinutes {
    final remaining = expiresAt.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// 残り時間の表示文字列
  String get remainingTimeText {
    final minutes = remainingMinutes;
    if (minutes <= 0) return '期限切れ';
    if (minutes < 60) return '残り$minutes分';
    final hours = (minutes / 60).floor();
    final remainingMins = minutes % 60;
    return '残り$hours時間$remainingMins分';
  }
}
