import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

import '../models/purchase_group.dart';
import '../models/invitation.dart';
import '../services/qr_invitation_service.dart';
import '../utils/app_logger.dart';

/// グループ招待管理ダイアログ
/// Firestoreから招待一覧を取得して表示
class GroupInvitationDialog extends ConsumerStatefulWidget {
  final PurchaseGroup group;

  const GroupInvitationDialog({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupInvitationDialog> createState() =>
      _GroupInvitationDialogState();
}

class _GroupInvitationDialogState extends ConsumerState<GroupInvitationDialog> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(),

            // コンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 招待コード生成ボタン
                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createInvitation,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code),
                      label: const Text('新しい招待コードを生成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 有効な招待一覧
                    const Text(
                      '有効な招待コード',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Firestoreから招待一覧を取得
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('invitations')
                          .where('groupId', isEqualTo: widget.group.groupId)
                          .where('status', isEqualTo: 'pending')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('エラー: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final invitations = snapshot.data?.docs ?? [];

                        if (invitations.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                '有効な招待コードはありません',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: invitations.map((doc) {
                            try {
                              final invitation = Invitation.fromFirestore(doc
                                  as DocumentSnapshot<Map<String, dynamic>>);
                              return _buildInvitationCard(invitation);
                            } catch (e) {
                              Log.error('招待データの読み込みエラー: $e');
                              return const SizedBox.shrink();
                            }
                          }).toList(),
                        );
                      },
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

  Widget _buildHeader() {
    return Container(
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
    );
  }

  Widget _buildInvitationCard(Invitation invitation) {
    // QRコード用のJSONデータを生成
    final qrData = jsonEncode({
      'invitationId': invitation.token,
      'purchaseGroupId': widget.group.groupId,
      'groupName': widget.group.groupName,
      'inviterUid': invitation.invitedBy,
      'inviterName': invitation.inviterName,
      'expiresAt': invitation.expiresAt.toIso8601String(),
      'maxUses': invitation.maxUses,
      'invitationToken': invitation.token,
      'token': invitation.token,
      'type': 'secure_qr_invitation',
      'version': '3.0',
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ステータス行
            Row(
              children: [
                Icon(
                  invitation.isValid ? Icons.check_circle : Icons.error,
                  color: invitation.isValid ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  invitation.isValid ? '有効' : '無効',
                  style: TextStyle(
                    color: invitation.isValid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 残り人数
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '残り${invitation.remainingUses}人',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // QRコード
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 情報
            _buildInfoRow('作成日時',
                '${invitation.createdAt.month}/${invitation.createdAt.day} ${invitation.createdAt.hour}:${invitation.createdAt.minute.toString().padLeft(2, '0')}'),
            _buildInfoRow('有効期限',
                '${invitation.remainingTime.inHours}時間${invitation.remainingTime.inMinutes.remainder(60)}分'),
            _buildInfoRow(
                '使用状況', '${invitation.currentUses}/${invitation.maxUses}人'),

            const SizedBox(height: 12),

            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyQRData(qrData),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('コピー'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteInvitation(invitation.token),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('削除'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvitation() async {
    setState(() => _isCreating = true);

    try {
      final qrService = ref.read(qrInvitationServiceProvider);
      await qrService.createQRInvitationData(
        shoppingListId: '',
        purchaseGroupId: widget.group.groupId,
        groupName: widget.group.groupName,
        groupOwnerUid: widget.group.ownerUid ?? widget.group.groupId,
        invitationType: 'individual',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('招待コードを生成しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _copyQRData(String qrData) async {
    await Clipboard.setData(ClipboardData(text: qrData));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('招待データをクリップボードにコピーしました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteInvitation(String token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('招待を削除'),
        content: const Text('この招待コードを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('invitations')
            .doc(token)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('招待を削除しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('削除エラー: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
