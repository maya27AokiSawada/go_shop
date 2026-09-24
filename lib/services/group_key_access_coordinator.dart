import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_group_provider.dart';
import '../providers/shared_list_provider.dart';
import '../utils/app_logger.dart';
import 'group_key_exchange_service.dart';

/// グループ画面（買い物リスト画面・メンバー管理画面など）を表示した際に、
/// 鍵ローテーション後の鍵解決・再配布・再暗号化を行う共通処理。
///
/// 元々は `SharedListPage` にのみ実装されており、リスト画面を開くまで
/// メンバー管理画面の名前・連絡先が復号されない不具合があったため、
/// 鍵を必要とする画面から共通で呼び出せるように切り出した。
///
/// [resetKeyWait] は呼び出し元が鍵待機用の状態（`SharedListPage` のスピナー等）
/// を持つ場合にのみ渡す。持たない画面は省略してよい。
Future<void> ensureGroupKeyAvailable({
  required WidgetRef ref,
  required String groupId,
  required bool Function() isMounted,
  void Function(String groupId)? resetKeyWait,
}) async {
  try {
    final service = ref.read(groupKeyExchangeServiceProvider);
    final persistedKey = await service.getPersistedGroupKey(groupId: groupId);
    final currentUid = ref.read(authStateProvider).valueOrNull?.uid;
    final shouldRefresh = currentUid != null
        ? await service.shouldRefreshGroupKey(
            groupId: groupId,
            memberUid: currentUid,
          )
        : false;
    final hasUsableKey = await service.hasUsableGroupKey(groupId: groupId);

    if (persistedKey != null &&
        persistedKey.isNotEmpty &&
        !shouldRefresh &&
        hasUsableKey) {
      Log.info('✅ [KEY_EXCHANGE] グループ $groupId には既存鍵あり');
      return;
    }

    void refreshGroupsIfMounted() {
      if (!isMounted()) return;
      Log.info('🔄 [KEY_EXCHANGE] 鍵解決後に allGroupsProvider を再構築');
      ref.invalidate(allGroupsProvider);
    }

    final allGroupsAsync = ref.read(allGroupsProvider);
    final group = await allGroupsAsync.when(
      data: (groups) =>
          Future.value(groups.where((g) => g.groupId == groupId).firstOrNull),
      loading: () => Future.value(null),
      error: (error, stack) => Future.value(null),
    );

    if (group == null) {
      Log.warning('⚠️ [KEY_EXCHANGE] グループ情報が取得できないため鍵作成をスキップ: $groupId');
      return;
    }

    final ownerUid = group.ownerUid ?? '';
    if (currentUid == null || ownerUid.isEmpty || currentUid != ownerUid) {
      Log.info(
          'ℹ️ [KEY_EXCHANGE] 非オーナーのため鍵作成をスキップ: groupId=$groupId, currentUid=${Log.maskUserId(currentUid)}, ownerUid=${Log.maskUserId(ownerUid)}');

      final memberShouldRefresh = currentUid != null
          ? await service.shouldRefreshGroupKey(
              groupId: groupId,
              memberUid: currentUid,
            )
          : false;

      if (memberShouldRefresh) {
        Log.info(
            '🔄 [KEY_EXCHANGE] メンバー端末でローカル鍵のバージョン差分を検出 → 再解決を実行: $groupId');
        resetKeyWait?.call(groupId);
        await service.resolveGroupKeyForMember(
          groupId: groupId,
          memberUid: currentUid,
        );
        refreshGroupsIfMounted();
        return;
      }

      final hasKey = await service.hasUsableGroupKey(groupId: groupId);
      if (!hasKey) {
        Log.info('ℹ️ [KEY_EXCHANGE] 鍵がありません。参加メンバーとして鍵の解決を試みます: $groupId');
        resetKeyWait?.call(groupId);
        await service.resolveGroupKeyForMember(
            groupId: groupId, memberUid: currentUid!);
        refreshGroupsIfMounted();
      }
      return;
    }

    final hasUsableOwnerKey =
        await service.hasUsableGroupKey(groupId: groupId);
    if (!hasUsableOwnerKey) {
      Log.info(
          '🔄 [KEY_EXCHANGE] オーナー自身の鍵状態が未確認のため、self-confirm を実行: $groupId');
      resetKeyWait?.call(groupId);
      await service.resolveGroupKeyForMember(
        groupId: groupId,
        memberUid: currentUid,
      );
    }

    final memberUids = group.members
            ?.where((member) => member.memberId.isNotEmpty)
            .map((member) => member.memberId)
            .toList() ??
        <String>[];

    final blockedByReencryption =
        await service.isRotationBlockedByPendingReencryption(
      groupId: groupId,
    );
    if (blockedByReencryption) {
      Log.info('ℹ️ [KEY_EXCHANGE] 再暗号化完了待ちのため鍵ローテーションをスキップ: $groupId');
      return;
    }

    final created = await service.ensureGroupKeyForOwner(
      groupId: groupId,
      ownerUid: group.ownerUid ?? '',
      memberUids: memberUids,
    );

    if (created) {
      Log.info('✅ [KEY_EXCHANGE] グループアクセス時に鍵作成・配布を実行: $groupId');
      final repository = ref.read(sharedListRepositoryProvider);
      final lists = await repository.getSharedListsByGroup(groupId);
      final listItems = <Map<String, dynamic>>[];

      for (final list in lists) {
        for (final item in list.items.values) {
          listItems.add({
            'memberId': item.memberId,
            'name': item.name,
          });
        }
      }

      await service.reencryptSharedItemsForGroup(
        groupId: groupId,
        items: listItems,
        repository: repository,
      );

      // ローテーション完了後は、全アイテムの再暗号化を終えてから
      // オーナー自身の鍵解決状況を confirmed に更新する。
      // これを先に行うと、アイテムがまだ暗号化済みの状態で usable と見なされて
      // しまい、UIが ciphertext のまま残る場合がある。
      await service.resolveGroupKeyForMember(
        groupId: groupId,
        memberUid: ownerUid,
      );
    } else {
      Log.info('ℹ️ [KEY_EXCHANGE] グループ $groupId は鍵作成対象外（既存鍵あり）');
    }
  } catch (e) {
    Log.error('❌ [KEY_EXCHANGE] グループアクセス時の鍵初期化失敗: $e');
  }
}
