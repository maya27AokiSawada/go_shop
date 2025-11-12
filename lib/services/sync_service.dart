import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../providers/purchase_group_provider.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

/// データ同期サービス
/// Firestore ⇄ Hive の同期を一元管理
class SyncService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SyncService(this._ref);

  PurchaseGroupRepository get _repository =>
      _ref.read(purchaseGroupRepositoryProvider);

  /// 全グループを同期（Firestore → Hive）
  /// アプリ起動時などに使用
  Future<SyncResult> syncAllGroupsFromFirestore(User user) async {
    if (F.appFlavor != Flavor.prod) {
      AppLogger.info('💡 [SYNC] Dev環境のため、Firestore→Hive同期はスキップ');
      return SyncResult(syncedCount: 0, skippedCount: 0);
    }

    try {
      AppLogger.info('⬇️ [SYNC] Firestore→Hive全グループ同期開始');

      final snapshot = await _firestore
          .collection('purchaseGroups')
          .where('allowedUid', arrayContains: user.uid)
          .get();

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
          final group = PurchaseGroup.fromJson(data);
          await _repository.updateGroup(doc.id, group);
          syncedCount++;
        } catch (e) {
          AppLogger.error('❌ [SYNC] グループ同期エラー: ${doc.id}, $e');
          skippedCount++;
        }
      }

      AppLogger.info('✅ [SYNC] 同期完了: $syncedCount個、スキップ: $skippedCount個');
      return SyncResult(syncedCount: syncedCount, skippedCount: skippedCount);
    } catch (e) {
      AppLogger.error('❌ [SYNC] Firestore→Hive同期エラー: $e');
      rethrow;
    }
  }

  /// 特定グループを同期（Firestore → Hive）
  /// 通知受信時などに使用
  Future<bool> syncSpecificGroup(String groupId) async {
    try {
      AppLogger.info('🔄 [SYNC] グループ同期開始: $groupId');

      final groupDoc =
          await _firestore.collection('purchaseGroups').doc(groupId).get();

      if (!groupDoc.exists) {
        AppLogger.warning('⚠️ [SYNC] グループが存在しません: $groupId');
        return false;
      }

      final groupData = groupDoc.data()!;
      final isDeleted = groupData['isDeleted'] as bool? ?? false;

      if (isDeleted) {
        AppLogger.info('🗑️ [SYNC] 削除済みグループ: $groupId');
        await _repository.deleteGroup(groupId);
        return true;
      }

      final group = PurchaseGroup.fromJson(groupData);
      await _repository.updateGroup(groupId, group);

      AppLogger.info('✅ [SYNC] グループ同期完了: ${group.groupName}');
      return true;
    } catch (e) {
      AppLogger.error('❌ [SYNC] グループ同期エラー ($groupId): $e');
      return false;
    }
  }

  /// Hive → Firestore へのアップロード
  /// グループ作成時などに使用
  Future<bool> uploadGroupToFirestore(PurchaseGroup group) async {
    if (F.appFlavor != Flavor.prod) {
      AppLogger.info('💡 [SYNC] Dev環境のため、Firestoreアップロードはスキップ');
      return false;
    }

    try {
      AppLogger.info('⬆️ [SYNC] グループをFirestoreにアップロード: ${group.groupName}');

      await _firestore.collection('purchaseGroups').doc(group.groupId).set({
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

      AppLogger.info('✅ [SYNC] アップロード完了: ${group.groupName}');
      return true;
    } catch (e) {
      AppLogger.error('❌ [SYNC] アップロード失敗: ${group.groupName}, $e');
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
      await _firestore.collection('purchaseGroups').doc(groupId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ [SYNC] グループに削除フラグを設定: $groupId');
      return true;
    } catch (e) {
      AppLogger.error('❌ [SYNC] 削除フラグ設定エラー: $e');
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
