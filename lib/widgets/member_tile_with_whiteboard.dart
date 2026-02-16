import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_group.dart';
import '../providers/whiteboard_provider.dart';
import '../providers/auth_provider.dart';
import '../pages/whiteboard_editor_page.dart';
import '../utils/app_logger.dart';

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

    // 個人用ホワイトボードの状態を監視
    final whiteboardAsync = ref.watch(
      personalWhiteboardProvider((groupId: groupId, userId: member.memberId)),
    );

    return InkWell(
      onDoubleTap: () => _openPersonalWhiteboard(context, ref),
      child: ListTile(
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
                      'ダブルタップ',
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
                  isCurrentUser ? Icons.draw : Icons.visibility,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isCurrentUser ? 'ダブルタップ' : '編集可',
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
                isCurrentUser ? 'ダブルタップ' : '編集可',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 個人用ホワイトボードを開く
  Future<void> _openPersonalWhiteboard(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final repository = ref.read(whiteboardRepositoryProvider);

      // 既存の個人用ホワイトボードを取得
      var whiteboard = await repository.getPersonalWhiteboard(
        groupId,
        member.memberId,
      );

      // なければ作成
      if (whiteboard == null) {
        whiteboard = await repository.createWhiteboard(
          groupId: groupId,
          ownerId: member.memberId, // 個人用
        );
        AppLogger.info('✅ 個人用ホワイトボード作成: ${member.name}');
      }

      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WhiteboardEditorPage(
              whiteboard: whiteboard!,
              groupId: groupId,
            ),
          ),
        );

        // 画面から戻ったらプロバイダーを更新
        ref.invalidate(personalWhiteboardProvider(
            (groupId: groupId, userId: member.memberId)));
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
