import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shared_group.dart';
import '../datastore/shared_group_repository.dart';
import '../providers/shared_group_provider.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';
import 'error_log_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

/// データ同期サービス
/// Firestore ⇄ Hive の同期を一元管理
class SyncService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SyncService(this._ref);

  SharedGroupRepository get _repository =>
      _ref.read(SharedGroupRepositoryProvider);

  /// 全グループを同期（Firestore → Hive）
  /// アプリ起動時などに使用
  Future<SyncResult> syncAllGroupsFromFirestore(User user) async {
    if (F.appFlavor != Flavor.prod) {
      AppLogger.info('💡 [SYNC] Dev環境のため、Firestore→Hive同期はスキップ');
      return SyncResult(syncedCount: 0, skippedCount: 0);
    }

    try {
      AppLogger.info('⬇️ [SYNC] Firestore→Hive全グループ同期開始');

      // 🔥 タイムアウト設定（30秒）
      final snapshot = await _firestore
          .collection('SharedGroups')
          .where('allowedUid', arrayContains: user.uid)
          .get()
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Firestore同期がタイムアウトしました（30秒）');
        },
      );

      AppLogger.info('📊 [SYNC] Firestoreクエリ完了: ${snapshot.docs.length}個のグループ');

      int syncedCount = 0;
      int skippedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isDeleted = data['isDeleted'] as bool? ?? false;

        if (isDeleted) {
          AppLogger.info('🗑️ [SYNC] 削除済みグループをスキップ: ${doc.id}');
          skippedCount++;
          continue;
        }

        try {
          final group = SharedGroup.fromJson(data);
          await _repository.updateGroup(doc.id, group);
          syncedCount++;
        } catch (e) {
          AppLogger.error('❌ [SYNC] グループ同期エラー: ${doc.id}, $e');
          skippedCount++;
        }
      }

      AppLogger.info('✅ [SYNC] 同期完了: $syncedCount個、スキップ: $skippedCount個');
      return SyncResult(syncedCount: syncedCount, skippedCount: skippedCount);
    } on TimeoutException catch (e) {
      // 🔥 タイムアウトエラー処理
      AppLogger.error('⏱️ [SYNC] 同期タイムアウト: $e');
      await ErrorLogService.logSyncError(
        '全グループ同期',
        'Firestore同期が30秒でタイムアウトしました。ネットワーク接続を確認してください。',
      );
      rethrow;
    } on FirebaseException catch (e) {
      // 🔥 Firestoreエラー処理
      AppLogger.error('❌ [SYNC] Firestore同期エラー: ${e.code} - ${e.message}');
      await ErrorLogService.logNetworkError(
        '全グループ同期',
        'Firestoreエラー: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      AppLogger.error('❌ [SYNC] Firestore→Hive同期エラー: $e');
      await ErrorLogService.logSyncError(
        '全グループ同期',
        'エラー: $e',
      );
      rethrow;
    }
  }

  /// 特定グループを同期（Firestore → Hive）
  /// 通知受信時などに使用
  Future<bool> syncSpecificGroup(String groupId) async {
    try {
      AppLogger.info('🔄 [SYNC] グループ同期開始: ${AppLogger.maskGroupId(groupId)}');

      // 🔥 タイムアウト設定（10秒）
      final groupDoc = await _firestore
          .collection('SharedGroups')
          .doc(groupId)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('グループ同期がタイムアウトしました（10秒）');
        },
      );

      if (!groupDoc.exists) {
        AppLogger.warning(
            '⚠️ [SYNC] グループが存在しません: ${AppLogger.maskGroupId(groupId)}');
        return false;
      }

      final groupData = groupDoc.data()!;
      final isDeleted = groupData['isDeleted'] as bool? ?? false;

      if (isDeleted) {
        AppLogger.info(
            '🗑️ [SYNC] 削除済みグループ: ${AppLogger.maskGroupId(groupId)}');
        await _repository.deleteGroup(groupId);
        return true;
      }

      final group = SharedGroup.fromJson(groupData);
      await _repository.updateGroup(groupId, group);

      AppLogger.info(
          '✅ [SYNC] グループ同期完了: ${AppLogger.maskGroup(group.groupName, group.groupId)}');
      return true;
    } on TimeoutException catch (e) {
      // 🔥 タイムアウトエラー処理
      AppLogger.error('⏱️ [SYNC] グループ同期タイムアウト: $e');
      await ErrorLogService.logSyncError(
        'グループ同期',
        'グループ ${AppLogger.maskGroupId(groupId)} の同期が10秒でタイムアウトしました',
      );
      return false;
    } on FirebaseException catch (e) {
      // 🔥 Firestoreエラー処理
      AppLogger.error('❌ [SYNC] Firestoreエラー: ${e.code}');
      await ErrorLogService.logNetworkError(
        'グループ同期',
        'Firestoreエラー (${e.code}): ${e.message}',
      );
      return false;
    } catch (e) {
      AppLogger.error(
          '❌ [SYNC] グループ同期エラー (${AppLogger.maskGroupId(groupId)}): $e');
      await ErrorLogService.logSyncError(
        'グループ同期',
        'エラー: $e',
      );
      return false;
    }
  }

  /// Hive → Firestore へのアップロード
  /// グループ作成時などに使用
  Future<bool> uploadGroupToFirestore(SharedGroup group) async {
    if (F.appFlavor != Flavor.prod) {
      AppLogger.info('💡 [SYNC] Dev環境のため、Firestoreアップロードはスキップ');
      return false;
    }

    try {
      AppLogger.info(
          '⬆️ [SYNC] グループをFirestoreにアップロード: ${AppLogger.maskGroup(group.groupName, group.groupId)}');

      await _firestore.collection('SharedGroups').doc(group.groupId).set({
        'groupId': group.groupId,
        'groupName': group.groupName,
        'ownerUid': group.ownerUid,
        'ownerName': group.ownerName,
        'ownerEmail': group.ownerEmail,
        'allowedUid': [group.ownerUid],
        'members': (group.members ?? [])
            .map((m) => {
                  'memberId': m.memberId,
                  'name': m.name,
                  'contact': m.contact,
                  'role': m.role.name,
                  'isSignedIn': m.isSignedIn,
                })
            .toList(),
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info(
          '✅ [SYNC] アップロード完了: ${AppLogger.maskGroup(group.groupName, group.groupId)}');
      return true;
    } on TimeoutException catch (e) {
      AppLogger.error('⏱️ [SYNC] アップロードタイムアウト: $e');
      await ErrorLogService.logSyncError(
        'グループアップロード',
        'グループ ${AppLogger.maskGroup(group.groupName, group.groupId)} のFirestoreアップロードがタイムアウトしました',
      );
      return false;
    } on FirebaseException catch (e) {
      AppLogger.error('❌ [SYNC] Firestoreエラー: ${e.code}');
      await ErrorLogService.logNetworkError(
        'グループアップロード',
        'Firestoreエラー (${e.code}): ${e.message}',
      );
      return false;
    } catch (e) {
      AppLogger.error(
          '❌ [SYNC] アップロード失敗: ${AppLogger.maskGroup(group.groupName, group.groupId)}, $e');
      await ErrorLogService.logOperationError(
        'グループアップロード',
        'エラー: $e',
      );
      return false;
    }
  }

  /// グループをFirestoreで削除フラグ設定
  Future<bool> markGroupAsDeletedInFirestore(String groupId) async {
    if (F.appFlavor != Flavor.prod) {
      AppLogger.info('💡 [SYNC] Dev環境のため、Firestore削除フラグはスキップ');
      return false;
    }

    try {
      await _firestore.collection('SharedGroups').doc(groupId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info(
          '✅ [SYNC] グループに削除フラグを設定: ${AppLogger.maskGroupId(groupId)}');
      return true;
    } on FirebaseException catch (e) {
      AppLogger.error('❌ [SYNC] Firestoreエラー: ${e.code}');
      await ErrorLogService.logNetworkError(
        'グループ削除フラグ設定',
        'Firestoreエラー (${e.code}): ${e.message}',
      );
      return false;
    } catch (e) {
      AppLogger.error('❌ [SYNC] 削除フラグ設定エラー: $e');
      await ErrorLogService.logOperationError(
        'グループ削除フラグ設定',
        'エラー: $e',
      );
      return false;
    }
  }

  /// プロバイダーを更新
  /// 同期後にUIを更新するために使用
  void invalidateGroupProvider() {
    _ref.invalidate(allGroupsProvider);
    AppLogger.info('🔄 [SYNC] グループプロバイダーを更新');
  }
}

/// 同期結果
class SyncResult {
  final int syncedCount;
  final int skippedCount;

  SyncResult({
    required this.syncedCount,
    required this.skippedCount,
  });

  int get totalProcessed => syncedCount + skippedCount;
}
