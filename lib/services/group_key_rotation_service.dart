import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datastore/firestore_shared_list_repository.dart';
import '../providers/firestore_provider.dart';
import '../utils/app_logger.dart';
import 'group_key_exchange_service.dart';

final groupKeyRotationServiceProvider =
    Provider<GroupKeyRotationService>((ref) => GroupKeyRotationService(ref));

/// 旧鍵の暗号文が残っているため、鍵ローテーションを見送ったことを表す。
class GroupKeyRotationBlockedException implements Exception {
  const GroupKeyRotationBlockedException(this.message);

  final String message;

  @override
  String toString() => 'GroupKeyRotationBlockedException: $message';
}

/// グループ鍵のローテーションを安全に行う（オーナー端末専用）。
///
/// 端末は1世代前の鍵までしか保持しないため、旧鍵の暗号文が残ったまま
/// ローテーションすると、そのデータは誰も復号できなくなる。そこで時間間隔ではなく
/// 「全データが現行鍵で読める」ことを条件にローテーションする。
///
/// また、抜けたメンバー（`keyExchangeEvents` はあるが `allowedUid` にいない）を
/// 検出したら自動でローテーションし、以後のデータを旧鍵で読めないようにする。
/// メンバーの削除・自主退出・アカウント削除のどの経路でも、オーナー端末が
/// 次にグループへアクセスした時点で反映される。
class GroupKeyRotationService {
  GroupKeyRotationService(this._ref, {FirebaseAuth? auth}) : _injectedAuth = auth;

  final Ref _ref;
  final FirebaseAuth? _injectedAuth;

  String? get _currentUid =>
      (_injectedAuth ?? FirebaseAuth.instance).currentUser?.uid;
  final Map<String, DateTime> _departedCheckedAt = <String, DateTime>{};
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  /// 抜けたメンバーの確認を同じグループで繰り返さない間隔（`force` 指定時を除く）。
  static const Duration _departedCheckInterval = Duration(minutes: 5);

  GroupKeyExchangeService get _keyService =>
      _ref.read(groupKeyExchangeServiceProvider);
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  DocumentReference<Map<String, dynamic>> _groupDoc(String groupId) =>
      _firestore.collection('SharedGroups').doc(groupId);

  /// 抜けたメンバーの鍵配布データが残っていれば、鍵をローテーションする。
  ///
  /// [removedUids] は直前に削除したメンバー。グループの `allowedUid` が
  /// Firestore へ反映される前でも、抜けたメンバーとして扱う。
  /// 旧鍵の暗号文が残っていてローテーションできない場合は、次回の確認で再試行する。
  Future<void> rotateIfMembersDeparted({
    required String groupId,
    Set<String> removedUids = const {},
    bool force = false,
  }) {
    if (!force) {
      final checkedAt = _departedCheckedAt[groupId];
      if (checkedAt != null &&
          DateTime.now().difference(checkedAt) < _departedCheckInterval) {
        return Future.value();
      }
    }

    final inFlight = _inFlight[groupId];
    if (inFlight != null) return inFlight;

    // オーナー以外の端末でも確認を繰り返さないよう、先に記録する（失敗時は消す）。
    _departedCheckedAt[groupId] = DateTime.now();
    final future = _rotateIfMembersDeparted(
      groupId: groupId,
      removedUids: removedUids,
    ).whenComplete(() {
      _inFlight.remove(groupId);
    });
    _inFlight[groupId] = future;
    return future;
  }

  Future<void> _rotateIfMembersDeparted({
    required String groupId,
    required Set<String> removedUids,
  }) async {
    try {
      final currentUid = _currentUid;
      var data = (await _groupDoc(groupId).get()).data();
      final ownerUid = data?['ownerUid'] as String?;
      if (data == null || currentUid == null || currentUid != ownerUid) {
        return;
      }

      // 削除したメンバーが allowedUid に残っている間は、回復エンベロープ
      // （旧鍵で新鍵を包んだもの）を読めてしまうため、削除の反映を待つ。
      for (var attempt = 0;
          attempt < 10 && _allowsAny(data!, removedUids);
          attempt++) {
        await Future.delayed(const Duration(seconds: 1));
        data = (await _groupDoc(groupId).get()).data();
        if (data == null) return;
      }
      if (_allowsAny(data!, removedUids)) {
        Log.warning(
            '⏳ [KEY_ROTATION] メンバー削除が反映されていないためローテーションを見送り（次回再試行）: groupId=$groupId');
        _departedCheckedAt.remove(groupId);
        return;
      }
      // 鍵未設定のグループはローテーション対象外
      if (data['activeKeyVersion'] == null) return;

      final memberUids = _currentMemberUids(data, ownerUid!, removedUids);
      final exchangeDocs =
          await _groupDoc(groupId).collection('keyExchangeEvents').get();
      final departedUids = exchangeDocs.docs
          .map((doc) => doc.id)
          .where((uid) => uid != ownerUid && !memberUids.contains(uid))
          .toSet();

      if (departedUids.isEmpty) return;

      Log.info(
          '🔑 [KEY_ROTATION] 抜けたメンバーを検出したため鍵をローテーション: groupId=$groupId, ${departedUids.length}人');
      await rotateSafely(groupId: groupId, removedUids: removedUids);
    } on GroupKeyRotationBlockedException catch (e) {
      // 次回の確認で再試行する
      _departedCheckedAt.remove(groupId);
      Log.warning('⏳ [KEY_ROTATION] ローテーションを見送り: groupId=$groupId, ${e.message}');
    } catch (e) {
      _departedCheckedAt.remove(groupId);
      Log.error('❌ [KEY_ROTATION] 抜けたメンバーの確認・ローテーションに失敗: $e');
    }
  }

  /// 全データが現行鍵で読めることを確認してから、鍵をローテーションする。
  ///
  /// 1. 平文・旧鍵のデータを現行鍵へ揃える（失敗したら [GroupKeyRotationBlockedException]）
  /// 2. 新しい鍵を現在のメンバーへ配布する
  /// 3. データを新しい鍵へ揃える（失敗しても1世代前の鍵で読めるため、次回の読み込みで再試行）
  /// 4. 抜けたメンバーの鍵配布データを削除する
  Future<void> rotateSafely({
    required String groupId,
    Set<String> removedUids = const {},
  }) async {
    final keyService = _keyService;
    final currentUid = _currentUid;
    final data = (await _groupDoc(groupId).get()).data();
    final ownerUid = data?['ownerUid'] as String?;
    if (data == null || currentUid == null || currentUid != ownerUid) {
      throw StateError('鍵のローテーションはグループのオーナーのみ実行できます');
    }

    // 1. 現行鍵へ揃える
    await keyService.ensureFreshGroupKey(
      groupId: groupId,
      activeKeyVersion: (data['activeKeyVersion'] as num?)?.toInt(),
    );
    await keyService.reencryptGroupFieldsIfKeyChanged(groupId: groupId);
    final listRepository = FirestoreSharedListRepository(_ref);
    final itemsReady = await listRepository.reencryptItemsToCurrentKey(groupId);
    final fieldsReady =
        await keyService.areGroupFieldsOnCurrentKey(groupId: groupId);
    if (!itemsReady || !fieldsReady) {
      throw const GroupKeyRotationBlockedException(
          '旧い鍵で暗号化されたままのデータがあるため、再暗号化が終わるまで鍵を変更できません');
    }

    // 2. 新しい鍵を現在のメンバーへ配布する
    final versionBefore =
        await keyService.getPersistedGroupKeyVersion(groupId: groupId);
    final memberUids = _currentMemberUids(data, ownerUid!, removedUids);
    await keyService.ensureGroupKeyForOwner(
      groupId: groupId,
      ownerUid: ownerUid,
      memberUids: memberUids.toList(),
      forceRefresh: true,
    );
    final versionAfter =
        await keyService.getPersistedGroupKeyVersion(groupId: groupId);
    if (versionAfter == null || versionAfter == versionBefore) {
      throw const GroupKeyRotationBlockedException(
          '鍵を変更できませんでした（再暗号化の完了待ちの可能性があります）');
    }

    // 3. データを新しい鍵へ揃える
    await keyService.reencryptGroupFieldsIfKeyChanged(groupId: groupId);
    await listRepository.reencryptItemsToCurrentKey(groupId);

    // 4. 抜けたメンバーの鍵配布データを削除する
    final exchangeDocs =
        await _groupDoc(groupId).collection('keyExchangeEvents').get();
    for (final doc in exchangeDocs.docs) {
      if (doc.id != ownerUid && !memberUids.contains(doc.id)) {
        await doc.reference.delete();
      }
    }

    Log.info(
        '✅ [KEY_ROTATION] 鍵をローテーション: groupId=$groupId, version=$versionBefore→$versionAfter');
  }

  bool _allowsAny(Map<String, dynamic> groupData, Set<String> uids) {
    if (uids.isEmpty) return false;
    final allowed = (groupData['allowedUid'] as List<dynamic>? ?? const [])
        .map((uid) => uid.toString());
    return allowed.any(uids.contains);
  }

  /// 鍵を配布する現在のメンバー（オーナーを除く）。
  Set<String> _currentMemberUids(
    Map<String, dynamic> groupData,
    String ownerUid,
    Set<String> removedUids,
  ) {
    final allowed = (groupData['allowedUid'] as List<dynamic>? ?? const [])
        .map((uid) => uid.toString());
    return allowed
        .where((uid) =>
            uid.isNotEmpty && uid != ownerUid && !removedUids.contains(uid))
        .toSet();
  }
}
