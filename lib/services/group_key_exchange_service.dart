import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth? _auth;
  final GroupKeyEncryptionService _crypto = GroupKeyEncryptionService();
  final Map<String, String> _groupKeyCache = <String, String>{};

  static const String _storagePrefix = 'group_key_v1:';
  static const String _localVersionPrefix = 'group_key_version_v1:';
  static const String _reencryptionFlagPrefix = 'group_key_reencrypting_v1:';

  GroupKeyExchangeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

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
      final currentUid = (_auth ?? FirebaseAuth.instance).currentUser?.uid;
      if (ownerUid.isEmpty || currentUid == null || currentUid != ownerUid) {
        Log.warning(
            '⚠️ [KEY_EXCHANGE] 非オーナー実行を拒否: groupId=$groupId, currentUid=${Log.maskUserId(currentUid)}, ownerUid=${Log.maskUserId(ownerUid)}');
        return false;
      }

      final blockedByReencryption =
          await _isRotationBlockedByPendingReencryption(groupId: groupId);
      if (blockedByReencryption) {
        Log.warning('⛔ [KEY_EXCHANGE] 再暗号化完了前の鍵ローテーションを拒否: groupId=$groupId');
        return false;
      }

      final persistedKey = await getPersistedGroupKey(groupId: groupId);
      final distributionUids = {
        ...memberUids.where((uid) => uid.isNotEmpty),
        ownerUid,
      }.toList();
      if (forceRefresh && persistedKey != null && persistedKey.isNotEmpty) {
        await rotateGroupKey(
          groupId: groupId,
          ownerUid: ownerUid,
          memberUids: distributionUids,
        );
        return true;
      }
      final shouldCreate = persistedKey == null || persistedKey.isEmpty;
      if (!shouldCreate) {
        return false;
      }

      final groupKey = _crypto.generateGroupKey();
      await _persistGroupKeyLocally(groupId: groupId, groupKey: groupKey);
      await rotateGroupKey(
        groupId: groupId,
        ownerUid: ownerUid,
        memberUids: distributionUids,
      );
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
      final currentUid = (_auth ?? FirebaseAuth.instance).currentUser?.uid;
      if (ownerUid.isEmpty || currentUid == null || currentUid != ownerUid) {
        Log.warning(
            '⚠️ [KEY_EXCHANGE] 招待受諾鍵処理を拒否（非オーナー）: groupId=$groupId, currentUid=${Log.maskUserId(currentUid)}, ownerUid=${Log.maskUserId(ownerUid)}');
        return;
      }

      String? groupKey = await getPersistedGroupKey(groupId: groupId);
      if (groupKey == null || groupKey.isEmpty) {
        Log.info(
            '🔑 [KEY_EXCHANGE] 新規グループキーを生成: groupId=$groupId, ownerUid=$ownerUid');
        groupKey = _crypto.generateGroupKey();
        await _persistGroupKeyLocally(groupId: groupId, groupKey: groupKey);
      }

      final recipientSecret = _deriveRecipientSecret(
        groupId: groupId,
        memberUid: memberUid,
      );
      final encryptedGroupKey = _crypto.encryptGroupKey(
        groupKey: groupKey,
        recipientSecret: recipientSecret,
      );

      final groupDoc = await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .get();
      final activeKeyVersion =
          (groupDoc.data()?['activeKeyVersion'] as num?)?.toInt() ?? 1;

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
        'keyVersion': activeKeyVersion,
        'status': 'ready',
        'confirmedKeyVersion': FieldValue.delete(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .set({
        'activeKeyVersion': activeKeyVersion,
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

        final groupDoc = await (_firestore ?? FirebaseFirestore.instance)
            .collection('SharedGroups')
            .doc(groupId)
            .get();
        final activeKeyVersion =
            (groupDoc.data()?['activeKeyVersion'] as num?)?.toInt() ?? 1;
        final keyVersion =
            (exchangeDoc.data()?['keyVersion'] as num?)?.toInt() ?? 1;

        if (keyVersion < activeKeyVersion) {
          Log.warning(
              '⚠️ [KEY_EXCHANGE] 古い鍵世代を無視: groupId=$groupId, memberUid=$memberUid, docVersion=$keyVersion, activeVersion=$activeKeyVersion');
          final recoveredGroupKey = await _recoverGroupKeyFromEnvelope(
            groupId: groupId,
            memberUid: memberUid,
            fromVersion: keyVersion,
            toVersion: activeKeyVersion,
          );
          if (recoveredGroupKey != null) {
            await _persistGroupKeyLocally(
              groupId: groupId,
              groupKey: recoveredGroupKey,
              version: activeKeyVersion,
            );
            final recipientSecret = _deriveRecipientSecret(
              groupId: groupId,
              memberUid: memberUid,
            );
            await exchangeDoc.reference.update({
              'encryptedGroupKey': _crypto.encryptGroupKey(
                groupKey: recoveredGroupKey,
                recipientSecret: recipientSecret,
              ),
              'keyVersion': activeKeyVersion,
              'status': 'confirmed',
              'confirmedKeyVersion': activeKeyVersion,
              'recoveredFromKeyVersion': keyVersion,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            Log.info(
                '✅ [KEY_EXCHANGE] 旧鍵ラップから現行鍵を復旧: groupId=$groupId, memberUid=$memberUid, fromVersion=$keyVersion, toVersion=$activeKeyVersion');
            return recoveredGroupKey;
          }
          await _clearPersistedGroupKey(groupId: groupId);
          await _markKeyExchangeStale(
            exchangeDoc: exchangeDoc,
            keyVersion: keyVersion,
            activeKeyVersion: activeKeyVersion,
          );
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
          groupId: groupId,
          groupKey: decryptedGroupKey,
          version: keyVersion,
        );

        final latestGroupDoc = await (_firestore ?? FirebaseFirestore.instance)
            .collection('SharedGroups')
            .doc(groupId)
            .get();
        final latestActiveKeyVersion =
            (latestGroupDoc.data()?['activeKeyVersion'] as num?)?.toInt() ?? 1;
        final latestExchangeDoc = await exchangeDoc.reference.get();
        final latestKeyVersion =
            (latestExchangeDoc.data()?['keyVersion'] as num?)?.toInt() ?? 1;
        final latestEncryptedGroupKey =
            latestExchangeDoc.data()?['encryptedGroupKey'] as String?;

        if (latestActiveKeyVersion != keyVersion ||
            latestKeyVersion != keyVersion ||
            latestEncryptedGroupKey != encryptedGroupKey) {
          Log.warning(
              '⚠️ [KEY_EXCHANGE] 確認前に鍵世代が更新されたため再解決: groupId=$groupId, memberUid=$memberUid, resolvedVersion=$keyVersion, activeVersion=$latestActiveKeyVersion, docVersion=$latestKeyVersion');
          await _clearPersistedGroupKey(groupId: groupId);
          if (latestKeyVersion < latestActiveKeyVersion) {
            await _markKeyExchangeStale(
              exchangeDoc: latestExchangeDoc,
              keyVersion: latestKeyVersion,
              activeKeyVersion: latestActiveKeyVersion,
            );
          }
          if (attempt < 4) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          return null;
        }

        await exchangeDoc.reference.update({
          'status': 'confirmed',
          'confirmedKeyVersion': keyVersion,
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
      final currentUid = (_auth ?? FirebaseAuth.instance).currentUser?.uid;
      if (ownerUid.isEmpty || currentUid == null || currentUid != ownerUid) {
        Log.warning(
            '⚠️ [KEY_EXCHANGE] 鍵ローテーションを拒否（非オーナー）: groupId=$groupId, currentUid=${Log.maskUserId(currentUid)}, ownerUid=${Log.maskUserId(ownerUid)}');
        return;
      }

      final blockedByReencryption =
          await _isRotationBlockedByPendingReencryption(groupId: groupId);
      if (blockedByReencryption) {
        Log.warning('⛔ [KEY_EXCHANGE] 再暗号化完了前の鍵ローテーションを拒否: groupId=$groupId');
        return;
      }

      final groupDoc = await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .get();
      final currentVersion =
          (groupDoc.data()?['activeKeyVersion'] as num?)?.toInt() ?? 1;
      final nextVersion = currentVersion + 1;
      final previousGroupKey = await getPersistedGroupKey(groupId: groupId);
      final previousLocalVersion =
          await getPersistedGroupKeyVersion(groupId: groupId);

      final newGroupKey = _crypto.generateGroupKey();
      await _persistGroupKeyLocally(
        groupId: groupId,
        groupKey: newGroupKey,
        version: nextVersion,
      );
      if (previousGroupKey != null &&
          previousGroupKey.isNotEmpty &&
          previousLocalVersion == currentVersion) {
        await _createKeyRecoveryEnvelope(
          groupId: groupId,
          previousGroupKey: previousGroupKey,
          newGroupKey: newGroupKey,
          fromVersion: currentVersion,
          toVersion: nextVersion,
        );
      }
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
          'keyVersion': nextVersion,
          'status': 'ready',
          'confirmedKeyVersion': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .set({
        'activeKeyVersion': nextVersion,
        'activeKeyUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      Log.error('❌ [KEY_EXCHANGE] 鍵ローテーション失敗: $e');
      rethrow;
    }
  }

  /// ローカルに保存済みの鍵を取得する。
  Future<int?> getPersistedGroupKeyVersion({required String groupId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_localVersionKey(groupId));
  }

  Future<void> _clearPersistedGroupKey({required String groupId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(groupId));
    await prefs.remove(_localVersionKey(groupId));
    _groupKeyCache.remove(groupId);
  }

  Future<String?> getPersistedGroupKey({required String groupId}) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_storageKey(groupId));
    if (value != null && value.isNotEmpty) {
      _groupKeyCache[groupId] = value;
    }
    return value;
  }

  Future<bool> hasUsableGroupKey({required String groupId}) async {
    final persistedKey = await getPersistedGroupKey(groupId: groupId);
    if (persistedKey == null || persistedKey.isEmpty) {
      return false;
    }

    final localVersion = await getPersistedGroupKeyVersion(groupId: groupId);
    final inactiveRemoteVersion =
        await _getGroupActiveKeyVersion(groupId: groupId);
    if (inactiveRemoteVersion != null &&
        inactiveRemoteVersion > 1 &&
        localVersion == null) {
      return false;
    }

    final currentUid = await _getCurrentUidSafely();
    if (localVersion != null && inactiveRemoteVersion != null) {
      final isCurrentVersion = localVersion >= inactiveRemoteVersion;
      if (!isCurrentVersion) {
        return false;
      }
    }

    if (currentUid != null && currentUid.isNotEmpty) {
      final doc = await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .collection('keyExchangeEvents')
          .doc(currentUid)
          .get();
      final docVersion = (doc.data()?['keyVersion'] as num?)?.toInt();
      final confirmedVersion =
          (doc.data()?['confirmedKeyVersion'] as num?)?.toInt();
      final remoteActiveVersion = inactiveRemoteVersion ?? docVersion ?? 1;
      final status = (doc.data()?['status'] as String?) ?? '';
      final isConfirmedForActiveVersion = docVersion != null &&
          docVersion == remoteActiveVersion &&
          confirmedVersion == remoteActiveVersion &&
          status == 'confirmed';
      if (!isConfirmedForActiveVersion) {
        Log.warning(
            '⚠️ [KEY_EXCHANGE] 現行世代で未確認の鍵を無効扱い: groupId=$groupId, memberUid=$currentUid, docVersion=$docVersion, confirmedVersion=$confirmedVersion, activeVersion=$remoteActiveVersion, status=$status');
        await _clearPersistedGroupKey(groupId: groupId);
        return false;
      }

      final encryptedGroupKey = doc.data()?['encryptedGroupKey'] as String?;
      if (encryptedGroupKey != null && encryptedGroupKey.isNotEmpty) {
        try {
          final recipientSecret = _deriveRecipientSecret(
            groupId: groupId,
            memberUid: currentUid,
          );
          final decrypted = _crypto.decryptGroupKey(
            encryptedGroupKey: encryptedGroupKey,
            recipientSecret: recipientSecret,
          );
          if (decrypted.isEmpty || decrypted != persistedKey) {
            Log.warning(
                '⚠️ [KEY_EXCHANGE] ローカル鍵と暗号文が不一致のため無効扱い: groupId=$groupId, memberUid=$currentUid, activeVersion=$remoteActiveVersion');
            await _clearPersistedGroupKey(groupId: groupId);
            return false;
          }
        } catch (_) {
          Log.warning(
              '⚠️ [KEY_EXCHANGE] 鍵復号に失敗したためローカル鍵を破棄: groupId=$groupId, memberUid=$currentUid');
          await _clearPersistedGroupKey(groupId: groupId);
          return false;
        }
      }
    }

    if (currentUid != null && currentUid.isNotEmpty) {
      final status = await _getKeyExchangeStatus(
        groupId: groupId,
        memberUid: currentUid,
      );
      if (status != null && status != 'confirmed') {
        return false;
      }
    }
    return true;
  }

  Future<bool> shouldRefreshGroupKey({
    required String groupId,
    required String memberUid,
  }) async {
    final activeVersion = await _getGroupActiveKeyVersion(groupId: groupId);
    if (activeVersion == null) {
      return false;
    }

    final localVersion = await getPersistedGroupKeyVersion(groupId: groupId);
    if (localVersion == null) {
      return true;
    }

    if (localVersion < activeVersion) {
      return true;
    }

    try {
      final exchangeDoc = await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .collection('keyExchangeEvents')
          .doc(memberUid)
          .get();
      final docVersion =
          (exchangeDoc.data()?['keyVersion'] as num?)?.toInt() ?? 1;
      final confirmedVersion =
          (exchangeDoc.data()?['confirmedKeyVersion'] as num?)?.toInt();
      final status = (exchangeDoc.data()?['status'] as String?) ?? '';
      if (status != 'confirmed' ||
          docVersion != activeVersion ||
          confirmedVersion != activeVersion) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> waitForUsableGroupKey({
    required String groupId,
    Duration checkInterval = const Duration(seconds: 1),
    int maxAttempts = 60,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final hasKey = await hasUsableGroupKey(groupId: groupId);
      if (hasKey) {
        return true;
      }

      if (attempt < maxAttempts - 1) {
        await Future.delayed(checkInterval);
      }
    }

    return false;
  }

  String _deriveRecipientSecret({
    required String groupId,
    required String memberUid,
    String? groupKey,
  }) {
    final keyMaterial = groupKey ?? '';
    final seed = '$groupId:$memberUid:$keyMaterial';
    final bytes = utf8.encode(seed);
    return base64.encode(sha256.convert(bytes).bytes);
  }

  Future<void> _persistGroupKeyLocally({
    required String groupId,
    required String groupKey,
    int? version,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(groupId), groupKey);
    if (version != null) {
      await prefs.setInt(_localVersionKey(groupId), version);
    }
    _groupKeyCache[groupId] = groupKey;
  }

  Future<String?> _getCurrentUidSafely() async {
    try {
      if (_auth != null) {
        return _auth.currentUser?.uid;
      }
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getKeyExchangeStatus({
    required String groupId,
    required String memberUid,
  }) async {
    try {
      final doc = await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .collection('keyExchangeEvents')
          .doc(memberUid)
          .get();
      final status = (doc.data()?['status'] as String?) ?? '';
      return status.isEmpty ? null : status;
    } catch (_) {
      return null;
    }
  }

  Future<void> _markKeyExchangeStale({
    required DocumentSnapshot<Map<String, dynamic>> exchangeDoc,
    required int keyVersion,
    required int activeKeyVersion,
  }) async {
    try {
      await exchangeDoc.reference.update({
        'status': 'stale',
        'confirmedKeyVersion': FieldValue.delete(),
        'staleKeyVersion': keyVersion,
        'expectedKeyVersion': activeKeyVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Log.warning('⚠️ [KEY_EXCHANGE] stale 状態の更新をスキップ: $e');
    }
  }

  Future<void> _createKeyRecoveryEnvelope({
    required String groupId,
    required String previousGroupKey,
    required String newGroupKey,
    required int fromVersion,
    required int toVersion,
  }) async {
    final envelopeSecret = _deriveRecoveryEnvelopeSecret(
      groupId: groupId,
      groupKey: previousGroupKey,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
    await (_firestore ?? FirebaseFirestore.instance)
        .collection('SharedGroups')
        .doc(groupId)
        .collection('keyRecoveryEnvelopes')
        .doc('$fromVersion-to-$toVersion')
        .set({
      'fromVersion': fromVersion,
      'toVersion': toVersion,
      'encryptedGroupKey': _crypto.encryptGroupKey(
        groupKey: newGroupKey,
        recipientSecret: envelopeSecret,
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 1)),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _recoverGroupKeyFromEnvelope({
    required String groupId,
    required String memberUid,
    required int fromVersion,
    required int toVersion,
  }) async {
    final localKey = await getPersistedGroupKey(groupId: groupId);
    final localVersion = await getPersistedGroupKeyVersion(groupId: groupId);
    if (localKey == null || localKey.isEmpty || localVersion != fromVersion) {
      return null;
    }

    try {
      final envelope = await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .collection('keyRecoveryEnvelopes')
          .doc('$fromVersion-to-$toVersion')
          .get();
      final data = envelope.data();
      final expiresAt = data?['expiresAt'] as Timestamp?;
      final encryptedGroupKey = data?['encryptedGroupKey'] as String?;
      if (!envelope.exists ||
          data?['fromVersion'] != fromVersion ||
          data?['toVersion'] != toVersion ||
          expiresAt == null ||
          !expiresAt.toDate().isAfter(DateTime.now()) ||
          encryptedGroupKey == null ||
          encryptedGroupKey.isEmpty) {
        return null;
      }

      return _crypto.decryptGroupKey(
        encryptedGroupKey: encryptedGroupKey,
        recipientSecret: _deriveRecoveryEnvelopeSecret(
          groupId: groupId,
          groupKey: localKey,
          fromVersion: fromVersion,
          toVersion: toVersion,
        ),
      );
    } catch (e) {
      Log.warning(
          '⚠️ [KEY_EXCHANGE] 回復用鍵エンベロープの復号失敗: groupId=$groupId, memberUid=$memberUid, error=$e');
      return null;
    }
  }

  String _deriveRecoveryEnvelopeSecret({
    required String groupId,
    required String groupKey,
    required int fromVersion,
    required int toVersion,
  }) {
    final seed = '$groupId:$fromVersion:$toVersion:$groupKey';
    return base64.encode(sha256.convert(utf8.encode(seed)).bytes);
  }

  Future<int?> _getGroupActiveKeyVersion({required String groupId}) async {
    try {
      final doc = await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .get();
      return (doc.data()?['activeKeyVersion'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  String encryptItemName({
    required String plaintextName,
    required String memberUid,
    required String groupId,
  }) {
    // 商品名は平文文字列のため、Base64へ正規化して既存の暗号化処理を再利用する。
    final normalizedPlaintext = base64.encode(utf8.encode(plaintextName));
    final activeGroupKey = _groupKeyCache[groupId] ?? '';
    final recipientSecret = _deriveRecipientSecret(
      groupId: groupId,
      memberUid: memberUid,
      groupKey: activeGroupKey,
    );
    return _crypto.encryptGroupKey(
      groupKey: normalizedPlaintext,
      recipientSecret: recipientSecret,
    );
  }

  String decryptItemName({
    required String encryptedName,
    required String groupKey,
    required String memberUid,
    required String groupId,
  }) {
    // 新方式: グループ鍵を導出に含める
    final keyedRecipientSecret = _deriveRecipientSecret(
      groupId: groupId,
      memberUid: memberUid,
      groupKey: groupKey,
    );
    try {
      final normalizedPlaintext = _crypto.decryptGroupKey(
        encryptedGroupKey: encryptedName,
        recipientSecret: keyedRecipientSecret,
      );
      return utf8.decode(base64.decode(normalizedPlaintext));
    } catch (_) {
      // 旧方式との後方互換: groupKeyを導出に含めない。
      final legacySecret = _deriveRecipientSecret(
        groupId: groupId,
        memberUid: memberUid,
      );
      final normalizedPlaintext = _crypto.decryptGroupKey(
        encryptedGroupKey: encryptedName,
        recipientSecret: legacySecret,
      );
      return utf8.decode(base64.decode(normalizedPlaintext));
    }
  }

  /// アイテム名が本サービス形式で暗号化済みかを判定する。
  bool isEncryptedItemName(String value) {
    try {
      final decoded = utf8.decode(base64.decode(value));
      final payload = jsonDecode(decoded);
      if (payload is! Map<String, dynamic>) {
        return false;
      }
      return payload.containsKey('version') &&
          payload.containsKey('ciphertext') &&
          payload.containsKey('tag');
    } catch (_) {
      return false;
    }
  }

  Future<void> setReencryptionInProgress({
    required String groupId,
    required bool inProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_reencryptionFlagPrefix$groupId', inProgress);

    try {
      await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .set({
        'keyRotationStatus': inProgress ? 'reencrypting' : 'idle',
        'keyReencryptionInProgress': inProgress,
        'keyReencryptionUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      Log.warning('⚠️ [KEY_EXCHANGE] 再暗号化フラグ更新失敗: $e');
    }
  }

  Future<bool> isReencryptionInProgress({required String groupId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_reencryptionFlagPrefix$groupId') ?? false;
  }

  /// 再暗号化が完了していないため鍵ローテーションをブロックすべきかを返す。
  Future<bool> isRotationBlockedByPendingReencryption({
    required String groupId,
  }) {
    return _isRotationBlockedByPendingReencryption(groupId: groupId);
  }

  Future<bool> _isRotationBlockedByPendingReencryption({
    required String groupId,
  }) async {
    final localInProgress = await isReencryptionInProgress(groupId: groupId);

    try {
      final snapshot = await (_firestore ?? FirebaseFirestore.instance)
          .collection('SharedGroups')
          .doc(groupId)
          .get();
      final data = snapshot.data();
      final remoteInProgress = data?['keyReencryptionInProgress'] == true;
      final rotationStatus = (data?['keyRotationStatus'] as String?) ?? '';
      final remoteReencrypting = rotationStatus == 'reencrypting';

      return localInProgress || remoteInProgress || remoteReencrypting;
    } catch (e) {
      Log.warning('⚠️ [KEY_EXCHANGE] 再暗号化状態のFirestore確認に失敗。ローカル判定を使用: $e');
      return localInProgress;
    }
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
  String _localVersionKey(String groupId) => '$_localVersionPrefix$groupId';
}
