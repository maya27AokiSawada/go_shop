import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../datastore/shared_list_repository.dart';
import 'group_key_encryption_service.dart';

final groupKeyExchangeServiceProvider =
    Provider<GroupKeyExchangeService>((ref) {
  return GroupKeyExchangeService();
});

enum GroupKeyMode {
  plaintext,
  encrypted,
}

class GroupKeyExchangeService {
  final FirebaseFirestore? _firestore;
  final GroupKeyEncryptionService _crypto = GroupKeyEncryptionService();

  static const String _storagePrefix = 'group_key_v1:';

  GroupKeyExchangeService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  /// グループ鍵が未設定の場合は平文として扱う。
  Future<GroupKeyMode> getGroupKeyMode({required String groupId}) async {
    final persistedKey = await getPersistedGroupKey(groupId: groupId);
    if (persistedKey == null || persistedKey.isEmpty) {
      return GroupKeyMode.plaintext;
    }
    return GroupKeyMode.encrypted;
  }

  /// オーナーが鍵を作成・再配布する。
  Future<bool> ensureGroupKeyForOwner({
    required String groupId,
    required String ownerUid,
    required List<String> memberUids,
    bool forceRefresh = false,
  }) async {
    try {
      final persistedKey = await getPersistedGroupKey(groupId: groupId);
      final shouldCreate =
          forceRefresh || persistedKey == null || persistedKey.isEmpty;
      if (!shouldCreate) {
        return false;
      }

      final groupKey = _crypto.generateGroupKey();
      await _persistGroupKeyLocally(groupId: groupId, groupKey: groupKey);
      if (_firestore != null) {
        await rotateGroupKey(
          groupId: groupId,
          ownerUid: ownerUid,
          memberUids: memberUids,
        );
      }
      return true;
    } catch (e) {
      Log.error('❌ [KEY_EXCHANGE] 鍵生成失敗: $e');
      rethrow;
    }
  }

  /// 招待受諾時に、オーナー側で新しいグループ鍵を生成し、メンバー用に暗号化して保存する。
  Future<void> handleAcceptedInvitation({
    required String groupId,
    required String memberUid,
    required String ownerUid,
  }) async {
    try {
      final groupKey = _crypto.generateGroupKey();
      final recipientSecret = _deriveRecipientSecret(
        groupId: groupId,
        memberUid: memberUid,
      );
      final encryptedGroupKey = _crypto.encryptGroupKey(
        groupKey: groupKey,
        recipientSecret: recipientSecret,
      );

      final exchangeDocRef = (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .collection('keyExchangeEvents')
          .doc(memberUid);

      await exchangeDocRef.set({
        'groupId': groupId,
        'memberUid': memberUid,
        'ownerUid': ownerUid,
        'encryptedGroupKey': encryptedGroupKey,
        'keyVersion': 1,
        'status': 'ready',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .set({
        'activeKeyVersion': 1,
        'activeKeyUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Log.info('✅ [KEY_EXCHANGE] 暗号化鍵を保存: $groupId / $memberUid');
    } catch (e) {
      Log.error('❌ [KEY_EXCHANGE] 暗号化鍵保存エラー: $e');
      rethrow;
    }
  }

  /// 参加者側で、ホストが保存した暗号化鍵を読み出し、復号してローカル保存する。
  Future<String?> resolveGroupKeyForMember({
    required String groupId,
    required String memberUid,
  }) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final exchangeDoc = await (_firestore ?? FirebaseFirestore.instance)
            .collection('SharedGroups')
            .doc(groupId)
            .collection('keyExchangeEvents')
            .doc(memberUid)
            .get();

        if (!exchangeDoc.exists) {
          if (attempt < 4) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          return null;
        }

        final encryptedGroupKey =
            exchangeDoc.data()?['encryptedGroupKey'] as String?;
        if (encryptedGroupKey == null || encryptedGroupKey.isEmpty) {
          if (attempt < 4) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          return null;
        }

        final recipientSecret = _deriveRecipientSecret(
          groupId: groupId,
          memberUid: memberUid,
        );
        final decryptedGroupKey = _crypto.decryptGroupKey(
          encryptedGroupKey: encryptedGroupKey,
          recipientSecret: recipientSecret,
        );

        await _persistGroupKeyLocally(
            groupId: groupId, groupKey: decryptedGroupKey);
        await exchangeDoc.reference.update({
          'status': 'confirmed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Log.info('✅ [KEY_EXCHANGE] 鍵復号成功: $groupId / $memberUid');
        return decryptedGroupKey;
      } catch (e) {
        Log.error('❌ [KEY_EXCHANGE] 鍵復号エラー: $e');
        if (attempt < 4) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        rethrow;
      }
    }

    return null;
  }

  /// 既存の共有アイテムを新しい鍵で再暗号化する。
  /// ここでは最小実装として、各アイテム名を新しい鍵で暗号化した文字列を
  /// アイテムの `name` フィールドの代わりに保持し、復号時に元に戻す。
  Future<void> reencryptSharedItemsForGroup({
    required String groupId,
    required List<Map<String, dynamic>> items,
    SharedListRepository? repository,
  }) async {
    try {
      final currentGroupKey = await getPersistedGroupKey(groupId: groupId);
      if (currentGroupKey == null || currentGroupKey.isEmpty) {
        return;
      }

      final encryptedItems = items.map((item) {
        final itemName = item['name']?.toString() ?? '';
        final encryptedName = _crypto.encryptGroupKey(
          groupKey: currentGroupKey,
          recipientSecret: _deriveRecipientSecret(
            groupId: groupId,
            memberUid: item['memberId']?.toString() ?? groupId,
          ),
        );

        return {
          ...item,
          'name': encryptedName,
          'encryptedName': true,
          'originalName': itemName,
        };
      }).toList();

      await _persistReencryptedItems(groupId: groupId, items: encryptedItems);

      if (repository != null) {
        final lists = await repository.getSharedListsByGroup(groupId);
        for (final list in lists) {
          final updatedItems = <String, dynamic>{};
          for (final item in list.items.values) {
            final matchingItem = encryptedItems.firstWhere(
              (entry) =>
                  entry['memberId'] == item.memberId &&
                  entry['name'] == item.name,
              orElse: () => <String, dynamic>{},
            );
            if (matchingItem.isNotEmpty) {
              updatedItems[item.itemId] = item.copyWith(
                name: matchingItem['name'].toString(),
              );
            } else {
              updatedItems[item.itemId] = item;
            }
          }
          final updatedList = list.copyWith(items: {
            for (final entry in updatedItems.entries) entry.key: entry.value,
          });
          await repository.updateSharedList(updatedList);
        }
      }
    } catch (e) {
      Log.error('❌ [KEY_EXCHANGE] アイテム再暗号化失敗: $e');
      rethrow;
    }
  }

  /// 新しい鍵を生成して、指定メンバーへ再配布する。
  Future<void> rotateGroupKey({
    required String groupId,
    required String ownerUid,
    required List<String> memberUids,
  }) async {
    try {
      final newGroupKey = _crypto.generateGroupKey();
      await _persistGroupKeyLocally(groupId: groupId, groupKey: newGroupKey);
      for (final memberUid in memberUids) {
        final recipientSecret = _deriveRecipientSecret(
          groupId: groupId,
          memberUid: memberUid,
        );
        final encryptedGroupKey = _crypto.encryptGroupKey(
          groupKey: newGroupKey,
          recipientSecret: recipientSecret,
        );

        await (_firestore ?? FirebaseFirestore.instance)
            .collection('SharedGroups')
            .doc(groupId)
            .collection('keyExchangeEvents')
            .doc(memberUid)
            .set({
          'groupId': groupId,
          'memberUid': memberUid,
          'ownerUid': ownerUid,
          'encryptedGroupKey': encryptedGroupKey,
          'keyVersion': 2,
          'status': 'ready',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .set({
        'activeKeyVersion': 2,
        'activeKeyUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      Log.error('❌ [KEY_EXCHANGE] 鍵ローテーション失敗: $e');
      rethrow;
    }
  }

  /// ローカルに保存済みの鍵を取得する。
  Future<String?> getPersistedGroupKey({required String groupId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey(groupId));
  }

  String _deriveRecipientSecret({
    required String groupId,
    required String memberUid,
  }) {
    final seed = '$groupId:$memberUid';
    final bytes = utf8.encode(seed);
    return base64.encode(sha256.convert(bytes).bytes);
  }

  Future<void> _persistGroupKeyLocally({
    required String groupId,
    required String groupKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(groupId), groupKey);
  }

  String encryptItemName({
    required String plaintextName,
    required String memberUid,
    required String groupId,
  }) {
    final recipientSecret = _deriveRecipientSecret(
      groupId: groupId,
      memberUid: memberUid,
    );
    return _crypto.encryptGroupKey(
      groupKey: plaintextName,
      recipientSecret: recipientSecret,
    );
  }

  String decryptItemName({
    required String encryptedName,
    required String groupKey,
    required String memberUid,
    required String groupId,
  }) {
    final recipientSecret = _deriveRecipientSecret(
      groupId: groupId,
      memberUid: memberUid,
    );
    return _crypto.decryptGroupKey(
      encryptedGroupKey: encryptedName,
      recipientSecret: recipientSecret,
    );
  }

  Future<void> _persistReencryptedItems({
    required String groupId,
    required List<Map<String, dynamic>> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_storagePrefix${groupId}_items',
      items.map((item) => jsonEncode(item)).toList(),
    );
  }

  String _storageKey(String groupId) => '$_storagePrefix$groupId';
}
