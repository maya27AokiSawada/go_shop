import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_group.dart';
import '../models/whiteboard.dart';
import '../providers/whiteboard_provider.dart';
import '../providers/auth_provider.dart';
import '../pages/whiteboard_editor_page.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';

/// グループメンバータイル（ダブルタップで個人用ホワイトボード編集）
class MemberTileWithWhiteboard extends ConsumerWidget {
  final SharedGroupMember member;
  final String groupId;

  const MemberTileWithWhiteboard({
    super.key,
    required this.member,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final isCurrentUser = currentUser?.uid == member.memberId;

    // 個人用ホワイトボードの状態をリアルタイム監視
    final whiteboardAsync = ref.watch(
      personalWhiteboardProvider((groupId: groupId, userId: member.memberId)),
    );
    final currentWhiteboard = whiteboardAsync.valueOrNull;

    return ListTile(
      onTap: () => _openPersonalWhiteboard(
        context,
        ref,
        currentWhiteboard: currentWhiteboard,
      ),
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
      trailing: whiteboardAsync.when(
        data: (whiteboard) {
          // ホワイトボードが存在する場合、isPrivateに応じた表示
          if (whiteboard != null) {
            if (isCurrentUser) {
              // 自分のホワイトボード
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.draw,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'タップで開く',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              );
            } else {
              // 他人のホワイトボード
              final canEdit = !whiteboard.isPrivate;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    canEdit ? Icons.edit : Icons.visibility,
                    size: 16,
                    color: canEdit ? Colors.green[600] : Colors.orange[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    canEdit ? '編集可' : '編集不可',
                    style: TextStyle(
                      fontSize: 10,
                      color: canEdit ? Colors.green[600] : Colors.orange[600],
                    ),
                  ),
                ],
              );
            }
          }

          // ホワイトボードが未作成の場合
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCurrentUser ? Icons.draw : Icons.do_not_disturb_alt,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                isCurrentUser ? 'タップで開く' : '未作成',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          );
        },
        loading: () => const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
        error: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCurrentUser ? Icons.draw : Icons.visibility,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              isCurrentUser ? 'タップで開く' : '編集可',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 個人用ホワイトボードを開く
  Future<void> _openPersonalWhiteboard(
    BuildContext context,
    WidgetRef ref, {
    Whiteboard? currentWhiteboard,
  }) async {
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

      var whiteboard = currentWhiteboard;

      if (whiteboard != null) {
        AppLogger.info(
            '⚡ [PERSONAL_WB] 監視中の個人ボードを即使用: ${whiteboard.whiteboardId}, isPrivate=${whiteboard.isPrivate}');
      } else {
        AppLogger.info('🔄 [PERSONAL_WB] タップ時に直接ボード取得');
        whiteboard = await repository
            .getPersonalWhiteboard(
              groupId,
              member.memberId,
            )
            .timeout(const Duration(seconds: 3));
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
            .timeout(const Duration(seconds: 3));
        AppLogger.info('✅ 個人用ホワイトボード作成: ${member.name}');
      } else {
        AppLogger.info(
            '📋 [PERSONAL_WB] 既存個人ボードを使用: ${whiteboard.whiteboardId}, isPrivate=${whiteboard.isPrivate}');
      }

      if (context.mounted) {
        AppLogger.info(
            '🚪 [PERSONAL_WB] エディター遷移開始: whiteboardId=${whiteboard.whiteboardId}, isPrivate=${whiteboard.isPrivate}, isCurrentUser=$isCurrentUser');
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WhiteboardEditorPage(
              whiteboard: whiteboard!,
              groupId: groupId,
            ),
          ),
        );
      }
    } on TimeoutException {
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
