import 'package:shared_preferences/shared_preferences.dart';

import '../datastore/hive_shared_group_repository.dart';
import '../datastore/hive_shared_list_repository.dart';
import '../datastore/shared_group_firestore_codec.dart';
import '../models/shared_list.dart';
import '../utils/app_logger.dart';
import 'group_key_exchange_service.dart';

/// Hive のローカルキャッシュを平文へ移行する（1回限り）。
///
/// 以前は Hive にアイテム名の暗号文、復号できなかったグループ共有フィールドの
/// 暗号文が混在していた。現在は暗号化・復号を Firestore リポジトリの境界で行い、
/// Hive には平文だけを保存するため、既存キャッシュをその場で復号する。
///
/// `updatedAt` は変えない（Hive→Firestore の同期判定に影響させないため）。
/// 復号できなかった値はそのまま残し、次回の Firestore 読み込みで上書きされる。
class HivePlaintextMigrationService {
  static const String _doneKey = 'hive_plaintext_migration_v1_done';

  /// 旧実装が平文のアイテム名を保存していた SharedPreferences のキー
  /// （`group_key_v1:{groupId}_items`）と、鍵変更検出用のマーカー。
  static const String _legacyItemsKeyPrefix = 'group_key_v1:';
  static const String _legacyItemsKeySuffix = '_items';
  static const String _legacyFingerprintPrefix = 'group_key_fingerprint_v1:';

  static Future<void> runIfNeeded({
    required HiveSharedListRepository hiveListRepository,
    required HiveSharedGroupRepository hiveGroupRepository,
    required GroupKeyExchangeService keyService,
    SharedGroupFirestoreCodec? codec,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_doneKey) == true) return;

    Log.info('🔓 [HIVE_MIGRATION] Hive キャッシュの平文化を開始');
    try {
      await _decryptCachedLists(hiveListRepository, keyService);
      await _decryptCachedGroups(
        hiveGroupRepository,
        codec ?? sharedGroupFirestoreCodec(),
      );
      await _removeLegacyPreferences(prefs);
      await prefs.setBool(_doneKey, true);
      Log.info('✅ [HIVE_MIGRATION] Hive キャッシュの平文化が完了');
    } catch (e) {
      // 次回起動時に再試行する。キャッシュは Firestore 読み込みでも上書きされる。
      Log.warning('⚠️ [HIVE_MIGRATION] Hive キャッシュの平文化に失敗（次回再試行）: $e');
    }
  }

  static Future<void> _decryptCachedLists(
    HiveSharedListRepository hiveListRepository,
    GroupKeyExchangeService keyService,
  ) async {
    var migrated = 0;
    for (final list in hiveListRepository.getAllLists()) {
      // ローカル鍵のみ使う（起動直後のためネットワークの鍵解決はしない）。
      await keyService.getPersistedGroupKey(groupId: list.groupId);

      var changed = false;
      final items = <String, SharedItem>{};
      for (final entry in list.items.entries) {
        final item = entry.value;
        if (item.name.isEmpty || !keyService.isEncryptedItemName(item.name)) {
          items[entry.key] = item;
          continue;
        }
        final result = keyService.tryDecryptItemName(
          encryptedName: item.name,
          memberUid: item.memberId,
          groupId: list.groupId,
        );
        if (result == null) {
          items[entry.key] = item;
          continue;
        }
        items[entry.key] = item.copyWith(name: result.name);
        changed = true;
      }

      if (changed) {
        await hiveListRepository.updateSharedList(list.copyWith(items: items));
        migrated++;
      }
    }
    Log.info('🔓 [HIVE_MIGRATION] リストを平文化: $migrated件');
  }

  static Future<void> _decryptCachedGroups(
    HiveSharedGroupRepository hiveGroupRepository,
    SharedGroupFirestoreCodec codec,
  ) async {
    if (!codec.encryptionEnabled) return;

    var migrated = 0;
    for (final group in await hiveGroupRepository.getAllGroups()) {
      if (!codec.groupHasEncryptedFields(group)) continue;
      final decrypted = await codec.decryptGroupPrimed(group);
      if (!codec.groupHasEncryptedFields(decrypted)) {
        await hiveGroupRepository.saveGroup(decrypted);
        migrated++;
      }
    }
    Log.info('🔓 [HIVE_MIGRATION] グループを平文化: $migrated件');
  }

  static Future<void> _removeLegacyPreferences(SharedPreferences prefs) async {
    for (final key in prefs.getKeys().toList()) {
      final isLegacyItems = key.startsWith(_legacyItemsKeyPrefix) &&
          key.endsWith(_legacyItemsKeySuffix);
      if (isLegacyItems || key.startsWith(_legacyFingerprintPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
