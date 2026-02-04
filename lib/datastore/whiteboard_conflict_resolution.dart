import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/whiteboard.dart';
import '../utils/app_logger.dart';

/// ホワイトボードの競合解決機能
class WhiteboardConflictResolver {
  final FirebaseFirestore _firestore;

  WhiteboardConflictResolver({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 🔥 改善案1: 差分ストローク追加（推奨）
  /// 新しいストロークのみをFirestoreに追加する
  Future<void> addStrokesToWhiteboard({
    required String groupId,
    required String whiteboardId,
    required List<DrawingStroke> newStrokes,
  }) async {
    if (newStrokes.isEmpty) return;

    try {
      // 🔥 Windows版対策: runTransactionでクラッシュするため通常の処理を使用
      if (Platform.isWindows) {
        await _addStrokesWithoutTransaction(
          groupId: groupId,
          whiteboardId: whiteboardId,
          newStrokes: newStrokes,
        );
        return;
      }

      // Firestoreトランザクションで安全に追加
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore
            .collection('SharedGroups')
            .doc(groupId)
            .collection('whiteboards')
            .doc(whiteboardId);

        // 現在のホワイトボードを取得
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('ホワイトボードが存在しません');
        }

        final currentData = snapshot.data()!;
        final currentStrokes = (currentData['strokes'] as List<dynamic>?)
                ?.map((s) =>
                    DrawingStroke.fromFirestore(s as Map<String, dynamic>))
                .toList() ??
            [];

        // 🔥 重複チェック: strokeIdが既に存在するストロークは除外
        final existingStrokeIds = currentStrokes.map((s) => s.strokeId).toSet();
        final uniqueNewStrokes = newStrokes
            .where((stroke) => !existingStrokeIds.contains(stroke.strokeId))
            .toList();

        if (uniqueNewStrokes.isEmpty) {
          AppLogger.info('📋 [CONFLICT] 重複ストローク検出、追加をスキップ');
          return;
        }

        // 新しいストロークを追加
        final mergedStrokes = [...currentStrokes, ...uniqueNewStrokes];

        // ドキュメントを更新
        transaction.update(docRef, {
          'strokes': mergedStrokes
              .map((s) => {
                    'strokeId': s.strokeId,
                    'points': s.points.map((p) => p.toMap()).toList(),
                    'colorValue': s.colorValue,
                    'strokeWidth': s.strokeWidth,
                    'createdAt': Timestamp.fromDate(s.createdAt),
                    'authorId': s.authorId,
                    'authorName': s.authorName,
                  })
              .toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        AppLogger.info('✅ [CONFLICT] ${uniqueNewStrokes.length}個のストロークを安全に追加');
      });
    } catch (e) {
      AppLogger.error('❌ [CONFLICT] ストローク追加エラー: $e');
      rethrow;
    }
  }

  /// 🔥 改善案2: ストローク削除（論理削除）
  /// 特定のストロークを削除済みマーク
  Future<void> markStrokesAsDeleted({
    required String groupId,
    required String whiteboardId,
    required List<String> strokeIds,
    required String deletedBy,
  }) async {
    if (strokeIds.isEmpty) return;

    try {
      // 🔥 Windows版対策: runTransactionでクラッシュするため通常の処理を使用
      if (Platform.isWindows) {
        await _markStrokesAsDeletedWithoutTransaction(
          groupId: groupId,
          whiteboardId: whiteboardId,
          strokeIds: strokeIds,
          deletedBy: deletedBy,
        );
        return;
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore
            .collection('SharedGroups')
            .doc(groupId)
            .collection('whiteboards')
            .doc(whiteboardId);

        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final currentData = snapshot.data()!;
        final strokes = (currentData['strokes'] as List<dynamic>?)
                ?.map((s) => s as Map<String, dynamic>)
                .toList() ??
            [];

        // 削除対象のストロークに削除フラグを追加
        for (var stroke in strokes) {
          final strokeId = stroke['strokeId'] as String;
          if (strokeIds.contains(strokeId)) {
            stroke['isDeleted'] = true;
            stroke['deletedAt'] = FieldValue.serverTimestamp();
            stroke['deletedBy'] = deletedBy;
          }
        }

        transaction.update(docRef, {
          'strokes': strokes,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        AppLogger.info('✅ [CONFLICT] ${strokeIds.length}個のストロークを削除マーク');
      });
    } catch (e) {
      AppLogger.error('❌ [CONFLICT] ストローク削除エラー: $e');
      rethrow;
    }
  }

  /// 🔥 改善案3: バージョン管理による楽観的ロック
  /// バージョン番号チェックで同時編集を検知
  Future<bool> updateWithVersionCheck({
    required String groupId,
    required String whiteboardId,
    required Whiteboard updatedWhiteboard,
    required int expectedVersion,
  }) async {
    try {
      // 🔥 Windows版対策: runTransactionでクラッシュするため通常の処理を使用
      if (Platform.isWindows) {
        return await _updateWithVersionCheckWithoutTransaction(
          groupId: groupId,
          whiteboardId: whiteboardId,
          updatedWhiteboard: updatedWhiteboard,
          expectedVersion: expectedVersion,
        );
      }

      return await _firestore.runTransaction<bool>((transaction) async {
        final docRef = _firestore
            .collection('SharedGroups')
            .doc(groupId)
            .collection('whiteboards')
            .doc(whiteboardId);

        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('ホワイトボードが存在しません');
        }

        final currentData = snapshot.data()!;
        final currentVersion = currentData['version'] as int? ?? 0;

        // バージョンチェック: 期待値と異なる場合は競合
        if (currentVersion != expectedVersion) {
          AppLogger.warning(
              '⚠️ [CONFLICT] バージョン競合検出: expected=$expectedVersion, current=$currentVersion');
          return false; // 競合発生、更新失敗
        }

        // バージョンをインクリメントして更新
        final newData = updatedWhiteboard.toFirestore();
        newData['version'] = currentVersion + 1;
        newData['updatedAt'] = FieldValue.serverTimestamp();

        transaction.set(docRef, newData);

        AppLogger.info('✅ [CONFLICT] バージョン更新成功: v${currentVersion + 1}');
        return true; // 更新成功
      });
    } catch (e) {
      AppLogger.error('❌ [CONFLICT] バージョン更新エラー: $e');
      return false;
    }
  }

  /// � Windows版専用: トランザクションを使わないストローク追加
  Future<void> _addStrokesWithoutTransaction({
    required String groupId,
    required String whiteboardId,
    required List<DrawingStroke> newStrokes,
  }) async {
    try {
      final docRef = _firestore
          .collection('SharedGroups')
          .doc(groupId)
          .collection('whiteboards')
          .doc(whiteboardId);

      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw Exception('ホワイトボードが存在しません');
      }

      final currentData = snapshot.data()!;
      final currentStrokes = (currentData['strokes'] as List<dynamic>?)
              ?.map(
                  (s) => DrawingStroke.fromFirestore(s as Map<String, dynamic>))
              .toList() ??
          [];

      final existingStrokeIds = currentStrokes.map((s) => s.strokeId).toSet();
      final uniqueNewStrokes = newStrokes
          .where((stroke) => !existingStrokeIds.contains(stroke.strokeId))
          .toList();

      if (uniqueNewStrokes.isEmpty) {
        AppLogger.info('📋 [WINDOWS] 重複ストローク検出、追加をスキップ');
        return;
      }

      final mergedStrokes = [...currentStrokes, ...uniqueNewStrokes];

      await docRef.update({
        'strokes': mergedStrokes
            .map((s) => {
                  'strokeId': s.strokeId,
                  'points': s.points.map((p) => p.toMap()).toList(),
                  'colorValue': s.colorValue,
                  'strokeWidth': s.strokeWidth,
                  'createdAt': Timestamp.fromDate(s.createdAt),
                  'authorId': s.authorId,
                  'authorName': s.authorName,
                })
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ [WINDOWS] ${uniqueNewStrokes.length}個のストロークを安全に追加');
    } catch (e) {
      AppLogger.error('❌ [WINDOWS] ストローク追加エラー: $e');
      rethrow;
    }
  }

  /// 💻 Windows版専用: トランザクションを使わないストローク削除
  Future<void> _markStrokesAsDeletedWithoutTransaction({
    required String groupId,
    required String whiteboardId,
    required List<String> strokeIds,
    required String deletedBy,
  }) async {
    try {
      final docRef = _firestore
          .collection('SharedGroups')
          .doc(groupId)
          .collection('whiteboards')
          .doc(whiteboardId);

      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final currentData = snapshot.data()!;
      final strokes = (currentData['strokes'] as List<dynamic>?)
              ?.map((s) => s as Map<String, dynamic>)
              .toList() ??
          [];

      for (var stroke in strokes) {
        final strokeId = stroke['strokeId'] as String;
        if (strokeIds.contains(strokeId)) {
          stroke['isDeleted'] = true;
          stroke['deletedAt'] = FieldValue.serverTimestamp();
          stroke['deletedBy'] = deletedBy;
        }
      }

      await docRef.update({
        'strokes': strokes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ [WINDOWS] ${strokeIds.length}個のストロークを削除マーク');
    } catch (e) {
      AppLogger.error('❌ [WINDOWS] ストローク削除エラー: $e');
      rethrow;
    }
  }

  /// 💻 Windows版専用: トランザクションを使わないバージョン更新
  Future<bool> _updateWithVersionCheckWithoutTransaction({
    required String groupId,
    required String whiteboardId,
    required Whiteboard updatedWhiteboard,
    required int expectedVersion,
  }) async {
    try {
      final docRef = _firestore
          .collection('SharedGroups')
          .doc(groupId)
          .collection('whiteboards')
          .doc(whiteboardId);

      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw Exception('ホワイトボードが存在しません');
      }

      final currentData = snapshot.data()!;
      final currentVersion = currentData['version'] as int? ?? 0;

      if (currentVersion != expectedVersion) {
        AppLogger.warning(
            '⚠️ [WINDOWS] バージョン競合検出: expected=$expectedVersion, current=$currentVersion');
        return false;
      }

      final newData = updatedWhiteboard.toFirestore();
      newData['version'] = currentVersion + 1;
      newData['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(newData);

      AppLogger.info('✅ [WINDOWS] バージョン更新成功: v${currentVersion + 1}');
      return true;
    } catch (e) {
      AppLogger.error('❌ [WINDOWS] バージョン更新エラー: $e');
      return false;
    }
  }

  /// �🔥 改善案4: リアルタイム競合検知
  /// 他ユーザーの編集中状態を監視
  Stream<List<String>> watchActiveEditors(String groupId, String whiteboardId) {
    return _firestore
        .collection('SharedGroups')
        .doc(groupId)
        .collection('whiteboards')
        .doc(whiteboardId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return <String>[];

      final data = snapshot.data()!;
      final activeEditors = (data['activeEditors'] as Map<String, dynamic>?)
              ?.entries
              .where((entry) {
                final lastActivity = entry.value as Timestamp?;
                if (lastActivity == null) return false;

                // 30秒以内にアクティビティがあるユーザーを「編集中」とみなす
                final now = DateTime.now();
                final activityTime = lastActivity.toDate();
                return now.difference(activityTime).inSeconds <= 30;
              })
              .map((entry) => entry.key)
              .toList() ??
          [];

      return activeEditors;
    });
  }

  /// アクティブエディター状態を更新
  Future<void> updateEditorActivity({
    required String groupId,
    required String whiteboardId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('SharedGroups')
          .doc(groupId)
          .collection('whiteboards')
          .doc(whiteboardId)
          .update({
        'activeEditors.$userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('❌ [CONFLICT] エディター状態更新エラー: $e');
    }
  }
}
