// lib/widgets/invitation_management_dialog.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/invitation.dart';
import '../models/purchase_group.dart';
import '../providers/auth_provider.dart';
import '../providers/invitation_provider.dart';
import '../utils/app_logger.dart';

/// 招待管理ダイアログ
///
/// 機能:
/// - 招待コード生成（QRコード + テキスト）
/// - 有効な招待一覧表示
/// - 招待の取り消し
class InvitationManagementDialog extends ConsumerStatefulWidget {
  final PurchaseGroup group;

  const InvitationManagementDialog({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<InvitationManagementDialog> createState() =>
      _InvitationManagementDialogState();
}

class _InvitationManagementDialogState
    extends ConsumerState<InvitationManagementDialog> {
  bool _isCreating = false;
  Invitation? _latestInvitation;

  @override
  Widget build(BuildContext context) {
    final invitationsAsync =
        ref.watch(invitationListProvider(widget.group.groupId));
    final user = ref.watch(authStateProvider).valueOrNull;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '招待管理',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.group.groupName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // コンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 招待コード生成ボタン
                    ElevatedButton.icon(
                      onPressed: _isCreating
                          ? null
                          : () => _createInvitation(context, user),
                      icon: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isCreating ? '生成中...' : '新しい招待を作成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    // 最新の招待コード表示
                    if (_latestInvitation != null) ...[
                      const SizedBox(height: 16),
                      _buildInvitationCard(_latestInvitation!),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),

                    // 有効な招待一覧
                    Row(
                      children: [
                        const Icon(Icons.list, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          '有効な招待一覧',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => ref
                              .read(invitationListProvider(widget.group.groupId)
                                  .notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('更新'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    invitationsAsync.when(
                      data: (invitations) {
                        if (invitations.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                '有効な招待はありません',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: invitations
                              .map((inv) => _buildInvitationListTile(inv))
                              .toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'エラー: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 招待作成
  Future<void> _createInvitation(BuildContext context, user) async {
    if (user == null) {
      _showError(context, 'ユーザー情報が取得できません');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final invitation = await ref
          .read(invitationListProvider(widget.group.groupId).notifier)
          .createInvitation(
            groupName: widget.group.groupName,
            invitedBy: user.uid,
            inviterName: user.displayName ?? 'Unknown',
            expiry: const Duration(hours: 24),
            maxUses: 5,
          );

      if (invitation != null && mounted) {
        setState(() => _latestInvitation = invitation);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('招待コードを生成しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        _showError(context, '招待コードの生成に失敗しました');
      }
    } catch (e) {
      Log.error('❌ [INVITATION] 招待作成エラー: $e');
      if (mounted) {
        _showError(context, '招待コードの生成に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  /// 招待カード（QRコード + テキスト）
  Widget _buildInvitationCard(Invitation invitation) {
    // QRコード用のJSON データを生成
    final qrData = jsonEncode({
      'purchaseGroupId': widget.group.groupId,
      'groupName': widget.group.groupName,
      'inviterUid': invitation.invitedBy,
      'inviterName': invitation.inviterName,
      'expiresAt': invitation.expiresAt.toIso8601String(),
      'maxUses': invitation.maxUses,
      'token': invitation.token, // 手動入力用のトークンも含める
    });

    // デバッグ用ログ
    Log.info('🔍 [QR_GENERATION] QRコードデータ生成:');
    Log.info('  - purchaseGroupId: ${widget.group.groupId}');
    Log.info('  - groupName: ${widget.group.groupName}');
    Log.info('  - QR JSON: $qrData');

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '招待コード',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // QRコード（JSON形式）
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: qrData, // JSON形式のデータを使用
                version: QrVersions.auto,
                size: 200,
              ),
            ),

            const SizedBox(height: 16),

            // トークンテキスト（手動入力用）
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '手動入力用コード:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          invitation.token,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: invitation.token));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('コピーしました')),
                      );
                    },
                    tooltip: 'コピー',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 招待情報
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(
                  icon: Icons.schedule,
                  label: '残り${invitation.remainingTime.inHours}時間',
                ),
                _buildInfoChip(
                  icon: Icons.people,
                  label: '残り${invitation.remainingUses}人',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 招待一覧のタイル
  Widget _buildInvitationListTile(Invitation invitation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              invitation.isValid ? Colors.green.shade100 : Colors.grey.shade300,
          child: Icon(
            invitation.isValid ? Icons.check_circle : Icons.cancel,
            color: invitation.isValid ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          invitation.token,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '有効期限: ${invitation.remainingTime.inHours}時間 | 使用: ${invitation.currentUses}/${invitation.maxUses}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: () => _cancelInvitation(invitation.token),
          tooltip: '取り消し',
        ),
      ),
    );
  }

  /// 情報チップ
  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  /// 招待取り消し
  Future<void> _cancelInvitation(String token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('招待を取り消しますか？'),
        content: const Text('この招待コードは使用できなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('取り消す'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(invitationListProvider(widget.group.groupId).notifier)
          .cancelInvitation(token);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('招待を取り消しました'),
            backgroundColor: Colors.green,
          ),
        );

        if (_latestInvitation?.token == token) {
          setState(() => _latestInvitation = null);
        }
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
