import 'dart:io' show Platform;

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

  /// whiteboardIdを指定してホワイトボードを取得
  Future<Whiteboard?> getWhiteboardById(
    String groupId,
    String whiteboardId,
  ) async {
    try {
      final doc = await _collection(groupId).doc(whiteboardId).get();
      if (!doc.exists) {
        AppLogger.warning('📋 [GET_WB_BY_ID] ホワイトボードが存在しません: $whiteboardId');
        return null;
      }

      return Whiteboard.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      AppLogger.error('❌ [GET_WB_BY_ID] ホワイトボード取得エラー: $e');
      return null;
    }
  }

  /// 個人用ホワイトボード取得
  Future<Whiteboard?> getPersonalWhiteboard(
    String groupId,
    String userId,
  ) async {
    try {
      final querySnapshot =
          await _collection(groupId).where('ownerId', isEqualTo: userId).get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.info('📋 個人用ホワイトボード未作成: userId=$userId');
        return null;
      }

      return _pickLatestPersonalWhiteboard(querySnapshot.docs, userId);
    } catch (e) {
      AppLogger.error('❌ 個人用ホワイトボード取得エラー: $e');
      return null;
    }
  }

  /// 個人用ホワイトボードをリアルタイム監視
  Stream<Whiteboard?> watchPersonalWhiteboard(
    String groupId,
    String userId,
  ) {
    return _collection(groupId)
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        AppLogger.info(
            '📡 [WATCH_PERSONAL_WB] 個人用ホワイトボード未作成: ${AppLogger.maskUserId(userId)}');
        return null;
      }

      final whiteboard = _pickLatestPersonalWhiteboard(snapshot.docs, userId);
      AppLogger.info(
          '📡 [WATCH_PERSONAL_WB] 個人用ホワイトボード更新検知: ${AppLogger.maskUserId(userId)}, isPrivate=${whiteboard.isPrivate}');
      return whiteboard;
    });
  }

  Whiteboard _pickLatestPersonalWhiteboard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String userId,
  ) {
    final whiteboards =
        docs.map((doc) => Whiteboard.fromFirestore(doc.data(), doc.id)).toList()
          ..sort((a, b) {
            final updatedComparison = b.updatedAt.compareTo(a.updatedAt);
            if (updatedComparison != 0) {
              return updatedComparison;
            }
            return b.createdAt.compareTo(a.createdAt);
          });

    if (whiteboards.length > 1) {
      AppLogger.warning(
          '⚠️ [PERSONAL_WB] 重複個人ボード検出: user=${AppLogger.maskUserId(userId)}, count=${whiteboards.length}, latest=${whiteboards.first.whiteboardId}');
    }

    return whiteboards.first;
  }

  /// 個人用ホワイトボードのプライベート設定を切り替え
  /// stale な whiteboardId を保持していても、ownerId に紐づく最新ボードを更新する
  Future<Whiteboard> togglePersonalWhiteboardPrivate({
    required String groupId,
    required String ownerId,
  }) async {
    final current = await getPersonalWhiteboard(groupId, ownerId);
    if (current == null) {
      throw Exception('個人用ホワイトボードが存在しません');
    }

    await _collection(groupId).doc(current.whiteboardId).update({
      'isPrivate': !current.isPrivate,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.info(
        '✅ [PERSONAL_WB] プライベート設定切り替え: ${AppLogger.maskUserId(ownerId)} ${!current.isPrivate ? "ON" : "OFF"} target=${current.whiteboardId}');

    final reloaded = await getWhiteboardById(groupId, current.whiteboardId);
    return reloaded ??
        current.copyWith(
          isPrivate: !current.isPrivate,
          updatedAt: DateTime.now(),
        );
  }

  /// 個人用ホワイトボードのプライベート設定を明示的に設定
  Future<Whiteboard> setPersonalWhiteboardPrivate({
    required String groupId,
    required String ownerId,
    required bool isPrivate,
  }) async {
    final current = await getPersonalWhiteboard(groupId, ownerId);
    if (current == null) {
      throw Exception('個人用ホワイトボードが存在しません');
    }

    return setWhiteboardPrivate(
      groupId: groupId,
      whiteboardId: current.whiteboardId,
      isPrivate: isPrivate,
      ownerId: ownerId,
      fallbackWhiteboard: current,
    );
  }

  /// 指定ホワイトボードのプライベート設定を明示的に更新
  Future<Whiteboard> setWhiteboardPrivate({
    required String groupId,
    required String whiteboardId,
    required bool isPrivate,
    String? ownerId,
    Whiteboard? fallbackWhiteboard,
  }) async {
    await _collection(groupId).doc(whiteboardId).update({
      'isPrivate': isPrivate,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.info(
        '✅ [PERSONAL_WB] プライベート設定を明示更新: ${AppLogger.maskUserId(ownerId)} value=$isPrivate target=$whiteboardId');

    final reloaded = await getWhiteboardById(groupId, whiteboardId);
    return (reloaded ??
            fallbackWhiteboard ??
            Whiteboard(
              whiteboardId: whiteboardId,
              groupId: groupId,
              ownerId: ownerId,
              strokes: const [],
              isPrivate: isPrivate,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              canvasWidth: 1280.0,
              canvasHeight: 720.0,
            ))
        .copyWith(
      isPrivate: isPrivate,
      updatedAt: DateTime.now(),
    );
  }

  /// ホワイトボード作成
  Future<Whiteboard> createWhiteboard({
    required String groupId,
    String? ownerId, // null = グループ共通
    double canvasWidth = 1280.0,
    double canvasHeight = 720.0,
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

  /// 🔥 改善案1: 差分ストローク追加（安全な同時編集対応）
  /// 新しいストロークのみをFirestoreに追加する
  Future<void> addStrokesToWhiteboard({
    required String groupId,
    required String whiteboardId,
    required List<DrawingStroke> newStrokes,
  }) async {
    if (newStrokes.isEmpty) return;

    try {
      // write-only 操作で runTransaction() を使うと、端末や回線状態によって
      // サーバー応答待ちのまま保存スピナーが復帰しないことがある。
      // グループ共有ボードは編集ロック前提、個人ボードは単独編集前提のため、
      // ここでは通常の get + update で差分追加する。
      AppLogger.info('💾 [REPO] 通常のupdate処理でストローク追加開始');
      await _addStrokesWithoutTransaction(
        groupId: groupId,
        whiteboardId: whiteboardId,
        newStrokes: newStrokes,
      );
      AppLogger.info('✅ [REPO] 通常のupdate処理でストローク追加完了');
    } catch (e, stackTrace) {
      AppLogger.error('❌ [REPO] ストローク追加エラー: $e');
      AppLogger.error('📍 [REPO] スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// トランザクションを使わない保存処理
  /// arrayUnion を使って既存ストロークを読み込まずに直接追記する。
  /// これにより docRef.get() の遅延（ネットワーク待機）を排除する。
  Future<void> _addStrokesWithoutTransaction({
    required String groupId,
    required String whiteboardId,
    required List<DrawingStroke> newStrokes,
  }) async {
    try {
      final docRef = _collection(groupId).doc(whiteboardId);

      // 🔥 get() を廃止: arrayUnion で直接追記（重複はFirestoreが排除）
      final newStrokeMaps = newStrokes
          .map((s) => {
                'strokeId': s.strokeId,
                'points': s.points.map((p) => p.toMap()).toList(),
                'colorValue': s.colorValue,
                'strokeWidth': s.strokeWidth,
                'createdAt': Timestamp.fromDate(s.createdAt),
                'authorId': s.authorId,
                'authorName': s.authorName,
              })
          .toList();

      AppLogger.info(
          '💾 [REPO] arrayUnionでFirestore更新中... (${newStrokes.length}個)');
      await docRef.update({
        'strokes': FieldValue.arrayUnion(newStrokeMaps),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ [REPO] Firestore更新完了: ${newStrokes.length}個のストロークを追加');
    } catch (e, stackTrace) {
      AppLogger.error('❌ [WINDOWS] ストローク追加エラー: $e');
      AppLogger.error('📍 [WINDOWS] スタックトレース: $stackTrace');
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

  /// ホワイトボード全消去（ストロークをクリア）
  Future<void> clearWhiteboard({
    required String groupId,
    required String whiteboardId,
  }) async {
    try {
      await _collection(groupId).doc(whiteboardId).update({
        'strokes': [], // ストローク全削除
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ ホワイトボード全消去: $whiteboardId');
    } catch (e) {
      AppLogger.error('❌ ホワイトボード全消去エラー: $e');
      rethrow;
    }
  }

  /// 🔥 NEW: グループ共通ホワイトボードをリアルタイム監視
  /// コレクション全体を監視してownerIdがnullのものをフィルタリング
  /// ホワイトボードの新規作成も自動的に検知できる
  Stream<Whiteboard?> watchGroupWhiteboard(String groupId) {
    return _collection(groupId).snapshots().map((snapshot) {
      AppLogger.info(
          '📡 [WATCH_GROUP_WB] スナップショット受信: ${snapshot.docs.length}件');

      // ownerIdがnullのドキュメントを探す
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ownerId = data['ownerId'];

        if (ownerId == null) {
          AppLogger.info('✅ [WATCH_GROUP_WB] グループ共通ホワイトボード検知: ${doc.id}');
          return Whiteboard.fromFirestore(data, doc.id);
        }
      }

      // グループ共通ホワイトボードが見つからない
      AppLogger.info('📡 [WATCH_GROUP_WB] グループ共通ホワイトボードなし');
      return null;
    });
  }

  /// ホワイトボードをリアルタイム監視
  Stream<Whiteboard?> watchWhiteboard(String groupId, String whiteboardId) {
    return _collection(groupId)
        .doc(whiteboardId)
        .snapshots()
        .where((snapshot) => !snapshot.metadata.hasPendingWrites)
        .map((snapshot) {
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
