import 'dart:async' show TimeoutException;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_id_service.dart';
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
      final deviceId = await DeviceIdService.getDevicePrefix();

      // 🔥 Windows版対策: runTransactionでクラッシュするため通常の処理を使用
      if (Platform.isWindows) {
        return await _acquireEditLockWithoutTransaction(
          groupId: groupId,
          whiteboardId: whiteboardId,
          userId: userId,
          userName: userName,
          deviceId: deviceId,
        );
      }

      // 🔥 FIX: runTransactionがハングする問題対策 - 5秒タイムアウトでフォールバック
      try {
        return await Future.any([
          _firestore.runTransaction<bool>((transaction) async {
            final whiteboardDocRef =
                _whiteboardsCollection(groupId).doc(whiteboardId);
            final snapshot = await transaction.get(whiteboardDocRef);

            if (!snapshot.exists) {
              throw Exception('ホワイトボードが存在しません');
            }

            final whiteboardData = snapshot.data()!;
            final editLock =
                whiteboardData['editLock'] as Map<String, dynamic>?;
            final now = DateTime.now();
            final lockExpiry = now.add(const Duration(hours: 1));

            if (editLock != null) {
              final currentUserId = editLock['userId'] as String?;
              final currentDeviceId = editLock['deviceId'] as String?;
              final createdAt = (editLock['createdAt'] as Timestamp?)?.toDate();

              // 同じユーザーかつ同じ端末、または legacy lock（deviceIdなし）は延長
              if (currentUserId == userId) {
                if (currentDeviceId == null || currentDeviceId == deviceId) {
                  transaction.update(whiteboardDocRef, {
                    'editLock.userId': userId,
                    'editLock.userName': userName,
                    'editLock.deviceId': deviceId,
                    'editLock.expiresAt': Timestamp.fromDate(lockExpiry),
                    'editLock.updatedAt': FieldValue.serverTimestamp(),
                  });
                  AppLogger.info(
                      '🔒 [LOCK] 編集ロック延長: ${AppLogger.maskUserId(userId)}@$deviceId');
                  return true;
                }

                // 同一ユーザーの別端末が持つstaleロックは強制引き継ぎ
                AppLogger.warning(
                    '⚠️ [LOCK] 同一ユーザーの別端末からロック引き継ぎ: ${AppLogger.maskUserId(userId)} $currentDeviceId → $deviceId');
                transaction.update(whiteboardDocRef, {
                  'editLock.userId': userId,
                  'editLock.userName': userName,
                  'editLock.deviceId': deviceId,
                  'editLock.expiresAt': Timestamp.fromDate(lockExpiry),
                  'editLock.updatedAt': FieldValue.serverTimestamp(),
                });
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
                'deviceId': deviceId,
                'groupId': groupId,
                'whiteboardId': whiteboardId,
                'createdAt': FieldValue.serverTimestamp(),
                'expiresAt': Timestamp.fromDate(lockExpiry),
                'updatedAt': FieldValue.serverTimestamp(),
              },
            });

            AppLogger.info(
                '✅ [LOCK] 編集ロック取得成功: ${AppLogger.maskName(userName)}');
            return true;
          }),
          Future<bool>.delayed(
            const Duration(seconds: 5),
            () => throw TimeoutException('runTransaction 5秒タイムアウト'),
          ),
        ]);
      } on TimeoutException {
        // runTransactionがハング → トランザクションなし方式にフォールバック
        AppLogger.warning(
            '⏳ [LOCK] runTransactionタイムアウト（5秒）- 非トランザクション方式にフォールバック');
        return await _acquireEditLockWithoutTransaction(
          groupId: groupId,
          whiteboardId: whiteboardId,
          userId: userId,
          userName: userName,
          deviceId: deviceId,
        );
      }
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
      final deviceId = await DeviceIdService.getDevicePrefix();

      // 🔥 Windows版対策: runTransactionでクラッシュするため通常の処理を使用
      if (Platform.isWindows) {
        await _releaseEditLockWithoutTransaction(
          groupId: groupId,
          whiteboardId: whiteboardId,
          userId: userId,
          deviceId: deviceId,
        );
        return;
      }

      await _firestore.runTransaction((transaction) async {
        final whiteboardDocRef =
            _whiteboardsCollection(groupId).doc(whiteboardId);
        final snapshot = await transaction.get(whiteboardDocRef);

        if (!snapshot.exists) return;

        final whiteboardData = snapshot.data()!;
        final editLock = whiteboardData['editLock'] as Map<String, dynamic>?;

        if (editLock != null) {
          final currentUserId = editLock['userId'] as String?;
          final currentDeviceId = editLock['deviceId'] as String?;

          // 🔥 FIX: 同一ユーザーなら別端末からでも解除を許可
          if (currentUserId == userId) {
            transaction.update(whiteboardDocRef, {
              'editLock': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
              'editLockReleasedAt': FieldValue.serverTimestamp(),
            });
            AppLogger.info(
                '🔓 [LOCK] 編集ロック解除: ${AppLogger.maskUserId(userId)}@$deviceId (lock was @$currentDeviceId)');
          } else {
            AppLogger.warning(
                '⚠️ [LOCK] 他ユーザーのロック解除試行: lock=${AppLogger.maskUserId(currentUserId)}@$currentDeviceId, requester=${AppLogger.maskUserId(userId)}@$deviceId');
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
        // 🔥 FIX: pending write スナップショットをフィルター（streamから除外）
        // map内でnullを返す旧方式はページ側の _hasEditLock を誤リセットしていた
        .where((snapshot) => !snapshot.metadata.hasPendingWrites)
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
  /// 🔥 DEPRECATED: Firestoreルール権限不足のため無効化
  Future<int> cleanupLegacyEditLocks({
    required String groupId,
  }) async {
    // 🔥 古いeditLocksコレクションのクリーンアップは不要
    // permission-deniedエラーを避けるため処理をスキップ
    AppLogger.info('⏭️ [LOCK] 古いeditLocksクリーンアップはスキップ（権限不足）');
    return 0;
  }

  /// 💀 編集ロックを強制クリア（緊急時用）
  Future<bool> forceReleaseEditLock({
    required String groupId,
    required String whiteboardId,
  }) async {
    try {
      // 🔥 Windows版対策: runTransactionでクラッシュするため通常の処理を使用
      if (Platform.isWindows) {
        await _forceReleaseEditLockWithoutTransaction(
          groupId: groupId,
          whiteboardId: whiteboardId,
        );
        return true;
      }

      await _firestore.runTransaction((transaction) async {
        final whiteboardDocRef =
            _whiteboardsCollection(groupId).doc(whiteboardId);

        transaction.update(whiteboardDocRef, {
          'editLock': FieldValue.delete(),
        });

        AppLogger.info('💀 [LOCK] 編集ロック強制削除: $whiteboardId');
      });

      return true;
    } catch (e) {
      AppLogger.error('❌ [LOCK] 編集ロック強制削除エラー: $e');
      return false;
    }
  }

  /// 💻 Windows版専用: トランザクションを使わない編集ロック取得
  Future<bool> _acquireEditLockWithoutTransaction({
    required String groupId,
    required String whiteboardId,
    required String userId,
    required String userName,
    required String deviceId,
  }) async {
    try {
      final whiteboardDocRef =
          _whiteboardsCollection(groupId).doc(whiteboardId);
      final now = DateTime.now();
      final lockExpiry = now.add(const Duration(hours: 1));

      // 🔥 FIX: get() に3秒タイムアウト + キャッシュフォールバック
      DocumentSnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await Future.any<DocumentSnapshot<Map<String, dynamic>>>([
          whiteboardDocRef.get(),
          Future.delayed(
            const Duration(seconds: 3),
            () => throw TimeoutException('get() 3秒タイムアウト'),
          ),
        ]);
      } on TimeoutException {
        AppLogger.warning('⏳ [FALLBACK] get() 3秒タイムアウト - キャッシュから読み込み試行');
        try {
          snapshot = await whiteboardDocRef.get(
            const GetOptions(source: Source.cache),
          );
        } catch (_) {
          // キャッシュも取得不可 - 楽観的ロック書き込み
          AppLogger.warning('⚠️ [FALLBACK] キャッシュも取得不可 - 楽観的ロック書き込み実行');
          await whiteboardDocRef.update({
            'editLock': {
              'userId': userId,
              'userName': userName,
              'deviceId': deviceId,
              'groupId': groupId,
              'whiteboardId': whiteboardId,
              'createdAt': FieldValue.serverTimestamp(),
              'expiresAt': Timestamp.fromDate(lockExpiry),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          });
          AppLogger.info(
              '✅ [FALLBACK] 楽観的ロック書き込み完了: ${AppLogger.maskName(userName)}');
          return true;
        }
      }

      if (!snapshot.exists) {
        throw Exception('ホワイトボードが存在しません');
      }

      final whiteboardData = snapshot.data()!;
      final editLock = whiteboardData['editLock'] as Map<String, dynamic>?;

      if (editLock != null) {
        final currentUserId = editLock['userId'] as String?;
        final currentDeviceId = editLock['deviceId'] as String?;
        final createdAt = (editLock['createdAt'] as Timestamp?)?.toDate();

        // 同じユーザーかつ同じ端末、または legacy lock（deviceIdなし）は延長
        if (currentUserId == userId) {
          if (currentDeviceId == null || currentDeviceId == deviceId) {
            await whiteboardDocRef.update({
              'editLock.userId': userId,
              'editLock.userName': userName,
              'editLock.deviceId': deviceId,
              'editLock.expiresAt': Timestamp.fromDate(lockExpiry),
              'editLock.updatedAt': FieldValue.serverTimestamp(),
            });
            AppLogger.info(
                '🔒 [WINDOWS] 編集ロック延長: ${AppLogger.maskUserId(userId)}@$deviceId');
            return true;
          }

          // 同一ユーザーの別端末が持つstaleロックは強制引き継ぎ
          AppLogger.warning(
              '⚠️ [WINDOWS] 同一ユーザーの別端末からロック引き継ぎ: ${AppLogger.maskUserId(userId)} $currentDeviceId → $deviceId');
          await whiteboardDocRef.update({
            'editLock.userId': userId,
            'editLock.userName': userName,
            'editLock.deviceId': deviceId,
            'editLock.expiresAt': Timestamp.fromDate(lockExpiry),
            'editLock.updatedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }

        // ロックが有効期限内かチェック（1時間）
        if (createdAt != null && now.difference(createdAt).inHours < 1) {
          final currentUserName = editLock['userName'] as String? ?? 'Unknown';
          AppLogger.warning(
              '⚠️ [WINDOWS] 編集中ユーザー存在: ${AppLogger.maskName(currentUserName)}');
          return false;
        }

        AppLogger.info(
            '🗑️ [WINDOWS] 期限切れロック削除: ${AppLogger.maskUserId(currentUserId)}');
      }

      // 新しい編集ロックを作成
      await whiteboardDocRef.update({
        'editLock': {
          'userId': userId,
          'userName': userName,
          'deviceId': deviceId,
          'groupId': groupId,
          'whiteboardId': whiteboardId,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(lockExpiry),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });

      AppLogger.info('✅ [WINDOWS] 編集ロック取得成功: ${AppLogger.maskName(userName)}');
      return true;
    } catch (e) {
      AppLogger.error('❌ [WINDOWS] 編集ロック取得エラー: $e');
      return false;
    }
  }

  /// 💻 Windows版専用: トランザクションを使わない編集ロック解除
  Future<void> _releaseEditLockWithoutTransaction({
    required String groupId,
    required String whiteboardId,
    required String userId,
    required String deviceId,
  }) async {
    try {
      final whiteboardDocRef =
          _whiteboardsCollection(groupId).doc(whiteboardId);
      final snapshot = await whiteboardDocRef.get();

      if (!snapshot.exists) return;

      final whiteboardData = snapshot.data()!;
      final editLock = whiteboardData['editLock'] as Map<String, dynamic>?;

      if (editLock != null) {
        final currentUserId = editLock['userId'] as String?;
        final currentDeviceId = editLock['deviceId'] as String?;

        // 🔥 FIX: 同一ユーザーなら別端末からでも解除を許可
        if (currentUserId == userId) {
          await whiteboardDocRef.update({
            'editLock': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
            'editLockReleasedAt': FieldValue.serverTimestamp(),
          });
          AppLogger.info(
              '🔓 [WINDOWS] 編集ロック解除: ${AppLogger.maskUserId(userId)}@$deviceId (lock was @$currentDeviceId)');
        } else {
          AppLogger.warning(
              '⚠️ [WINDOWS] 他ユーザーのロック解除試行: lock=${AppLogger.maskUserId(currentUserId)}@$currentDeviceId, requester=${AppLogger.maskUserId(userId)}@$deviceId');
        }
      }
    } catch (e) {
      AppLogger.error('❌ [WINDOWS] 編集ロック解除エラー: $e');
    }
  }

  /// 💻 Windows版専用: トランザクションを使わない編集ロック強制解除
  Future<void> _forceReleaseEditLockWithoutTransaction({
    required String groupId,
    required String whiteboardId,
  }) async {
    try {
      final whiteboardDocRef =
          _whiteboardsCollection(groupId).doc(whiteboardId);

      await whiteboardDocRef.update({
        'editLock': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'editLockReleasedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('💀 [WINDOWS] 編集ロック強制削除: $whiteboardId');
    } catch (e) {
      AppLogger.error('❌ [WINDOWS] 編集ロック強制削除エラー: $e');
      rethrow;
    }
  }
}

/// 編集ロック情報
class EditLockInfo {
  final String userId;
  final String userName;
  final String? deviceId;
  final String groupId;
  final String whiteboardId;
  final DateTime createdAt;
  final DateTime expiresAt;

  const EditLockInfo({
    required this.userId,
    required this.userName,
    this.deviceId,
    required this.groupId,
    required this.whiteboardId,
    required this.createdAt,
    required this.expiresAt,
  });

  factory EditLockInfo.fromMap(Map<String, dynamic> data) {
    return EditLockInfo(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      deviceId: data['deviceId'] as String?,
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
