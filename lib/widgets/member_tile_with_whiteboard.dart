import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_group.dart';
import '../models/whiteboard.dart';
import '../providers/whiteboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_group_provider.dart';
import '../pages/whiteboard_editor_page.dart';
import '../services/personal_whiteboard_cache_service.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';

/// グループメンバータイル（タップでロール変更、ダブルタップで個人用ホワイトボード編集）
class MemberTileWithWhiteboard extends ConsumerStatefulWidget {
  final SharedGroupMember member;
  final String groupId;

  const MemberTileWithWhiteboard({
    super.key,
    required this.member,
    required this.groupId,
  });

  @override
  ConsumerState<MemberTileWithWhiteboard> createState() =>
      _MemberTileWithWhiteboardState();
}

class _MemberTileWithWhiteboardState
    extends ConsumerState<MemberTileWithWhiteboard> {
  static const Duration _personalWhiteboardFetchTimeout = Duration(seconds: 20);

  bool _isOpening = false;

  SharedGroupMember get member => widget.member;
  String get groupId => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final isCurrentUser = currentUser?.uid == member.memberId;

    // グループ情報取得（オーナー判定用）
    final allGroupsAsync = ref.watch(allGroupsProvider);
    SharedGroup? group;
    allGroupsAsync.whenData((groups) {
      try {
        group = groups.firstWhere((g) => g.groupId == groupId);
      } catch (_) {}
    });
    final isOwner = group != null && currentUser?.uid == group!.ownerUid;
    final isManager = group != null &&
        group!.members?.any((m) =>
                m.memberId == currentUser?.uid &&
                m.role == SharedGroupRole.manager) ==
            true;

    return ListTile(
      onTap: _isOpening
          ? null
          : () => _handleTap(context, ref,
              isOwner: isOwner, isManager: isManager, group: group),
      onDoubleTap:
          _isOpening ? null : () => _openPersonalWhiteboard(context, ref),
      leading: CircleAvatar(
        backgroundColor: _getRoleColor(member.role),
        child: Text(
          member.name.isNotEmpty ? member.name[0] : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Text(member.name),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'あなた',
                style: TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(_getRoleLabel(member.role)),
      trailing: _isOpening
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCurrentUser ? Icons.draw : Icons.visibility,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isCurrentUser ? 'ダブルタップで開く' : 'ダブルタップで確認',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
    );
  }

  /// シングルタップ処理（オーナー: ロール変更 / その他: メンバー情報表示）
  void _handleTap(
    BuildContext context,
    WidgetRef ref, {
    required bool isOwner,
    required bool isManager,
    required SharedGroup? group,
  }) {
    // オーナー: 全メンバー（自分以外）のロール変更可
    // 管理者: memberロールのメンバーのみ昇格/降格可（オーナー・他の管理者は不可）
    final canEditRole = group != null &&
        (isOwner
            ? member.role != SharedGroupRole.owner
            : isManager && member.role == SharedGroupRole.member);
    if (canEditRole) {
      _showRoleChangeDialog(context, ref, group);
    } else {
      _showMemberInfoDialog(context);
    }
  }

  /// ロール変更ダイアログ（オーナー専用）
  Future<void> _showRoleChangeDialog(
    BuildContext context,
    WidgetRef ref,
    SharedGroup group,
  ) async {
    final currentRole = member.role;
    final canPromote = currentRole == SharedGroupRole.member;
    final canDemote = currentRole == SharedGroupRole.manager;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '現在のロール: ${_getRoleLabel(currentRole)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (canPromote)
              const Text(
                'マネージャーに昇格すると、メンバー招待や\nリスト編集ができるようになります。',
                style: TextStyle(fontSize: 13),
              ),
            if (canDemote)
              const Text(
                'メンバーに降格すると、管理操作の\n権限が取り消されます。',
                style: TextStyle(fontSize: 13),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          if (canPromote)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _updateMemberRole(ref, group, SharedGroupRole.manager);
                if (context.mounted) {
                  SnackBarHelper.showSuccess(
                      context, '${member.name} さんをマネージャーに昇格しました');
                }
              },
              icon: const Icon(Icons.arrow_upward, size: 16),
              label: const Text('マネージャーに昇格'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          if (canDemote)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _updateMemberRole(ref, group, SharedGroupRole.member);
                if (context.mounted) {
                  SnackBarHelper.showSuccess(
                      context, '${member.name} さんをメンバーに降格しました');
                }
              },
              icon: const Icon(Icons.arrow_downward, size: 16),
              label: const Text('メンバーに降格'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// メンバー情報表示ダイアログ（オーナー以外向け）
  void _showMemberInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(member.role),
                  radius: 16,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getRoleLabel(member.role),
                  style: TextStyle(
                    color: _getRoleColor(member.role),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (member.contact.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                member.contact,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, size: 14, color: Colors.blue),
                  SizedBox(width: 6),
                  Text(
                    'ダブルタップでホワイトボードを表示',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// ロール更新
  Future<void> _updateMemberRole(
    WidgetRef ref,
    SharedGroup group,
    SharedGroupRole newRole,
  ) async {
    try {
      final repository = ref.read(SharedGroupRepositoryProvider);
      final updatedMembers = group.members?.map((m) {
        if (m.memberId == member.memberId) {
          return m.copyWith(role: newRole);
        }
        return m;
      }).toList();
      final updatedGroup = group.copyWith(members: updatedMembers);
      await repository.updateGroup(group.groupId, updatedGroup);
      ref.invalidate(selectedGroupNotifierProvider);
    } catch (e) {
      AppLogger.error('❌ [MEMBER_TILE] ロール変更エラー: $e');
    }
  }

  /// 個人用ホワイトボードを開く
  Future<void> _openPersonalWhiteboard(
    BuildContext context,
    WidgetRef ref, {
    Whiteboard? currentWhiteboard,
  }) async {
    if (_isOpening) {
      AppLogger.info('🔒 [PERSONAL_WB] 既にオープン処理中のため無視');
      return;
    }
    setState(() => _isOpening = true);
    try {
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser == null) {
        SnackBarHelper.showError(context, 'サインイン状態を確認できないため開けません');
        return;
      }

      final isCurrentUser = currentUser.uid == member.memberId;

      AppLogger.info(
          '📝 [PERSONAL_WB] オープン要求: member=${AppLogger.maskUserId(member.memberId)}, group=${AppLogger.maskGroupId(groupId)}');

      final repository = ref.read(whiteboardRepositoryProvider);
      final cacheKey = PersonalWhiteboardCacheService.buildCacheKey(
        currentUserId: currentUser.uid,
        groupId: groupId,
        memberId: member.memberId,
      );

      final cachedWhiteboard = currentWhiteboard ??
          PersonalWhiteboardCacheService.getMemoryCachedWhiteboard(cacheKey) ??
          await PersonalWhiteboardCacheService.loadWhiteboard(cacheKey);

      Whiteboard? whiteboard;

      if (isCurrentUser) {
        AppLogger.info('🔄 [PERSONAL_WB] オーナー本人のため最新ボードを優先取得');
        whiteboard = await repository
            .getPersonalWhiteboard(
              groupId,
              member.memberId,
            )
            .timeout(_personalWhiteboardFetchTimeout);
        if (whiteboard != null) {
          await PersonalWhiteboardCacheService.saveWhiteboard(
              cacheKey, whiteboard);
        } else {
          whiteboard = cachedWhiteboard;
        }
      } else {
        whiteboard = cachedWhiteboard;
        if (whiteboard != null) {
          AppLogger.info(
              '⚡ [PERSONAL_WB] キャッシュ済み個人ボードを即使用: ${whiteboard.whiteboardId}, isPrivate=${whiteboard.isPrivate}');
        } else {
          AppLogger.info('🔄 [PERSONAL_WB] タップ時に直接ボード取得');
          whiteboard = await repository
              .getPersonalWhiteboard(
                groupId,
                member.memberId,
              )
              .timeout(_personalWhiteboardFetchTimeout);
          if (whiteboard != null) {
            await PersonalWhiteboardCacheService.saveWhiteboard(
                cacheKey, whiteboard);
          }
        }
      }

      // なければ作成（自分のボードのみ）
      if (whiteboard == null) {
        if (!isCurrentUser) {
          AppLogger.info(
              'ℹ️ [PERSONAL_WB] 他ユーザーの個人用ホワイトボードは未作成のため遷移しない: ${AppLogger.maskUserId(member.memberId)}');
          if (context.mounted) {
            SnackBarHelper.showInfo(
                context, '${member.name} さんの個人用ホワイトボードはまだ作成されていません');
          }
          return;
        }

        whiteboard = await repository
            .createWhiteboard(
              groupId: groupId,
              ownerId: member.memberId, // 個人用
            )
            .timeout(_personalWhiteboardFetchTimeout);
        await PersonalWhiteboardCacheService.saveWhiteboard(
            cacheKey, whiteboard);
        AppLogger.info('✅ 個人用ホワイトボード作成: ${member.name}');
      } else {
        AppLogger.info(
            '📋 [PERSONAL_WB] 既存個人ボードを使用: ${whiteboard.whiteboardId}, isPrivate=${whiteboard.isPrivate}');
      }

      if (context.mounted) {
        AppLogger.info(
            '🚪 [PERSONAL_WB] エディター遷移開始: whiteboardId=${whiteboard.whiteboardId}, isPrivate=${whiteboard.isPrivate}, isCurrentUser=$isCurrentUser');
        final updatedWhiteboard = await Navigator.of(context).push<Whiteboard?>(
          MaterialPageRoute(
            builder: (_) => WhiteboardEditorPage(
              whiteboard: whiteboard!,
              groupId: groupId,
              ownerName: member.name,
            ),
          ),
        );
        if (updatedWhiteboard != null) {
          await PersonalWhiteboardCacheService.saveWhiteboard(
            cacheKey,
            updatedWhiteboard,
          );
        }
      }
    } on TimeoutException {
      final currentUser = ref.read(authStateProvider).value;
      final fallbackWhiteboard = currentUser == null
          ? null
          : await PersonalWhiteboardCacheService.loadWhiteboard(
              PersonalWhiteboardCacheService.buildCacheKey(
                currentUserId: currentUser.uid,
                groupId: groupId,
                memberId: member.memberId,
              ),
            );

      if (fallbackWhiteboard != null && context.mounted) {
        AppLogger.warning(
            '⚠️ [PERSONAL_WB] Firestore取得タイムアウトのためキャッシュから起動: ${fallbackWhiteboard.whiteboardId}');
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WhiteboardEditorPage(
              whiteboard: fallbackWhiteboard,
              groupId: groupId,
              ownerName: member.name,
            ),
          ),
        );
        return;
      }

      AppLogger.error('❌ 個人用ホワイトボード取得タイムアウト');
      if (context.mounted) {
        SnackBarHelper.showWarning(context, 'ホワイトボードの取得がタイムアウトしました');
      }
    } catch (e) {
      AppLogger.error('❌ 個人用ホワイトボードオープンエラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ホワイトボードを開けませんでした: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  /// 役割ごとの色
  Color _getRoleColor(SharedGroupRole role) {
    switch (role) {
      case SharedGroupRole.owner:
        return Colors.red[700]!;
      case SharedGroupRole.manager:
        return Colors.orange[700]!;
      case SharedGroupRole.partner:
        return Colors.purple[700]!;
      case SharedGroupRole.member:
        return Colors.blue[700]!;
    }
  }

  /// 役割ラベル
  String _getRoleLabel(SharedGroupRole role) {
    switch (role) {
      case SharedGroupRole.owner:
        return 'オーナー';
      case SharedGroupRole.manager:
        return 'マネージャー';
      case SharedGroupRole.partner:
        return 'パートナー';
      case SharedGroupRole.member:
        return 'メンバー';
    }
  }
}
