import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/whiteboard.dart';
import '../utils/app_logger.dart';

const _uuid = Uuid();

/// ホワイトボードのFirestoreリポジトリ
class WhiteboardRepository {
  final FirebaseFirestore _firestore;

  WhiteboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// コレクション参照取得
  CollectionReference<Map<String, dynamic>> _collection(String groupId) {
    return _firestore
        .collection('SharedGroups')
        .doc(groupId)
        .collection('whiteboards');
  }

  /// グループ共通ホワイトボード取得
  Future<Whiteboard?> getGroupWhiteboard(String groupId) async {
    try {
      // 🔥 NOTE: Firestoreでは where('ownerId', isEqualTo: null) が正しく動作しないため、
      // 全ホワイトボードを取得してフィルタリングする
      final querySnapshot = await _collection(groupId).get();

      AppLogger.info(
          '📋 [GET_GROUP_WB] 全ホワイトボード取得: ${querySnapshot.docs.length}件');

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final ownerId = data['ownerId'];
        AppLogger.info(
            '📋 [GET_GROUP_WB] whiteboardId: ${doc.id}, ownerId: ${AppLogger.maskUserId(ownerId)}');

        // ownerIdがnullのものを探す
        if (ownerId == null) {
          AppLogger.info('✅ [GET_GROUP_WB] グループ共通ホワイトボード発見: ${doc.id}');
          return Whiteboard.fromFirestore(data, doc.id);
        }
      }

      AppLogger.info('📋 [GET_GROUP_WB] グループ共通ホワイトボード未作成: $groupId');
      return null;
    } catch (e) {
      AppLogger.error('❌ グループ共通ホワイトボード取得エラー: $e');
      return null;
    }
  }

  /// 個人用ホワイトボード取得
  Future<Whiteboard?> getPersonalWhiteboard(
    String groupId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _collection(groupId)
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.info('📋 個人用ホワイトボード未作成: userId=$userId');
        return null;
      }

      final doc = querySnapshot.docs.first;
      return Whiteboard.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      AppLogger.error('❌ 個人用ホワイトボード取得エラー: $e');
      return null;
    }
  }

  /// ホワイトボード作成
  Future<Whiteboard> createWhiteboard({
    required String groupId,
    String? ownerId, // null = グループ共通
    double canvasWidth = 800.0,
    double canvasHeight = 600.0,
  }) async {
    final whiteboardId = _uuid.v4();
    final now = DateTime.now();

    final whiteboard = Whiteboard(
      whiteboardId: whiteboardId,
      groupId: groupId,
      ownerId: ownerId,
      strokes: [],
      isPrivate: false,
      createdAt: now,
      updatedAt: now,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );

    await _collection(groupId).doc(whiteboardId).set(whiteboard.toFirestore());

    AppLogger.info(
        '✅ ホワイトボード作成: ${ownerId == null ? "グループ共通" : "個人用(${AppLogger.maskUserId(ownerId)})"}');
    return whiteboard;
  }

  /// ホワイトボード更新（ストローク追加・削除）
  Future<void> updateWhiteboard(Whiteboard whiteboard) async {
    try {
      final updatedWhiteboard = whiteboard.copyWith(
        updatedAt: DateTime.now(),
      );

      await _collection(whiteboard.groupId)
          .doc(whiteboard.whiteboardId)
          .set(updatedWhiteboard.toFirestore());

      AppLogger.info('✅ ホワイトボード更新: ${whiteboard.whiteboardId}');
    } catch (e) {
      AppLogger.error('❌ ホワイトボード更新エラー: $e');
      rethrow;
    }
  }

  /// プライベート設定切り替え
  Future<void> togglePrivate(Whiteboard whiteboard) async {
    try {
      await _collection(whiteboard.groupId)
          .doc(whiteboard.whiteboardId)
          .update({
        'isPrivate': !whiteboard.isPrivate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ プライベート設定切り替え: ${!whiteboard.isPrivate ? "ON" : "OFF"}');
    } catch (e) {
      AppLogger.error('❌ プライベート設定エラー: $e');
      rethrow;
    }
  }

  /// ホワイトボードをリアルタイム監視
  Stream<Whiteboard?> watchWhiteboard(String groupId, String whiteboardId) {
    return _collection(groupId).doc(whiteboardId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Whiteboard.fromFirestore(snapshot.data()!, snapshot.id);
    });
  }

  /// グループの全ホワイトボード取得（グループ共通+全メンバーの個人用）
  Future<List<Whiteboard>> getAllWhiteboards(String groupId) async {
    try {
      final querySnapshot = await _collection(groupId).get();
      return querySnapshot.docs
          .map((doc) => Whiteboard.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('❌ 全ホワイトボード取得エラー: $e');
      return [];
    }
  }

  /// ホワイトボード削除
  Future<void> deleteWhiteboard(String groupId, String whiteboardId) async {
    try {
      await _collection(groupId).doc(whiteboardId).delete();
      AppLogger.info('✅ ホワイトボード削除: $whiteboardId');
    } catch (e) {
      AppLogger.error('❌ ホワイトボード削除エラー: $e');
      rethrow;
    }
  }
}
