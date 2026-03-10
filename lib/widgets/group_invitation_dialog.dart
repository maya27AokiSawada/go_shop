import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

import '../models/shared_group.dart';
import '../models/invitation.dart';
import '../services/qr_invitation_service.dart';
import '../providers/shared_group_provider.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';

/// グループ招待管理ダイアログ
/// Firestoreから招待一覧を取得して表示
class GroupInvitationDialog extends ConsumerStatefulWidget {
  final SharedGroup group;

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
  final Set<String> _processedAcceptances = {}; // 処理済みの受諾を追跡

  @override
  void initState() {
    super.initState();
    _ensureGroupExistsInFirestore();
  }

  /// グループドキュメントがFirestoreに存在することを確認
  Future<void> _ensureGroupExistsInFirestore() async {
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('SharedGroups')
          .doc(widget.group.groupId)
          .get();

      if (!groupDoc.exists) {
        Log.error('グループがFirestoreに存在しません: ${widget.group.groupId}');
        Log.error('グループを作成します...');

        // グループドキュメントを作成
        await FirebaseFirestore.instance
            .collection('SharedGroups')
            .doc(widget.group.groupId)
            .set({
          'groupId': widget.group.groupId,
          'groupName': widget.group.groupName,
          'ownerUid': widget.group.ownerUid,
          'allowedUid': widget.group.allowedUid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Log.info('グループをFirestoreに作成しました: ${widget.group.groupId}');
      } else {
        Log.info('グループはFirestoreに存在します: ${widget.group.groupId}');
      }
    } catch (e) {
      Log.error('グループ存在確認エラー: $e');
    }
  }

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

                    // Firestoreから招待一覧を取得（グループメンバー全員が閲覧可能）
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('SharedGroups')
                          .doc(widget.group.groupId)
                          .collection('invitations')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          Log.error('招待一覧取得エラー: ${snapshot.error}');
                          Log.error('  現在のユーザー: ${currentUser?.uid}');
                          Log.error('  グループID: ${widget.group.groupId}');
                          Log.error('  グループownerUid: ${widget.group.ownerUid}');
                          Log.error(
                              '  グループallowedUid: ${widget.group.allowedUid}');
                          return Column(
                            children: [
                              Text('エラー: ${snapshot.error}'),
                              const SizedBox(height: 8),
                              Text('ユーザー: ${currentUser?.uid}',
                                  style: const TextStyle(fontSize: 10)),
                              Text('グループ: ${widget.group.groupId}',
                                  style: const TextStyle(fontSize: 10)),
                              Text('Owner: ${widget.group.ownerUid}',
                                  style: const TextStyle(fontSize: 10)),
                              Text(
                                  'Members: ${widget.group.allowedUid.join(", ")}',
                                  style: const TextStyle(fontSize: 10)),
                            ],
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final invitations = snapshot.data?.docs ?? [];

                        // クライアント側でフィルタリングとソート
                        final filteredInvitations = invitations.where((doc) {
                          try {
                            final data = doc.data() as Map<String, dynamic>?;
                            final status = data?['status'] as String?;
                            return status == 'pending' || status == null;
                          } catch (e) {
                            return false;
                          }
                        }).toList()
                          ..sort((a, b) {
                            try {
                              final aData = a.data() as Map<String, dynamic>?;
                              final bData = b.data() as Map<String, dynamic>?;
                              final aCreated =
                                  aData?['createdAt'] as Timestamp?;
                              final bCreated =
                                  bData?['createdAt'] as Timestamp?;
                              if (aCreated == null || bCreated == null) {
                                return 0;
                              }
                              return bCreated.compareTo(aCreated); // 降順
                            } catch (e) {
                              return 0;
                            }
                          });

                        if (filteredInvitations.isEmpty) {
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

                        // 招待の usedBy 配列を監視してグループメンバーを自動追加
                        _processInvitationAcceptances(filteredInvitations);

                        return Column(
                          children: filteredInvitations.map((doc) {
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
      'sharedGroupId': widget.group.groupId,
      'groupName': widget.group.groupName,
      'inviterUid': invitation.invitedBy,
      'inviterName': invitation.inviterName,
      'expiresAt': invitation.expiresAt.toIso8601String(),
      'maxUses': invitation.maxUses,
      'invitationToken': invitation.token,
      'token': invitation.token,
      'securityKey': invitation.securityKey, // セキュリティキー追加
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
        sharedGroupId: widget.group.groupId,
        groupName: widget.group.groupName,
        groupOwnerUid: widget.group.ownerUid ?? widget.group.groupId,
        groupAllowedUids: widget.group.allowedUid,
        invitationType: 'individual',
      );

      if (mounted) {
        SnackBarHelper.showSuccess(context, '招待コードを生成しました');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'エラー: $e');
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
      SnackBarHelper.showSuccess(context, '招待データをクリップボードにコピーしました');
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
        // サブコレクションパスで削除: /SharedGroups/{groupId}/invitations/{token}
        await FirebaseFirestore.instance
            .collection('SharedGroups')
            .doc(widget.group.groupId)
            .collection('invitations')
            .doc(token)
            .delete();

        if (mounted) {
          SnackBarHelper.showSuccess(context, '招待を削除しました');
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, '削除エラー: $e');
        }
      }
    }
  }

  /// 招待受諾を監視してグループメンバーを自動追加
  void _processInvitationAcceptances(List<QueryDocumentSnapshot> invitations) {
    for (final invitationDoc in invitations) {
      try {
        final data = invitationDoc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final usedBy = (data['usedBy'] as List<dynamic>?)?.cast<String>() ?? [];

        // 新しく追加されたUIDを検出
        for (final acceptorUid in usedBy) {
          final key = '${invitationDoc.id}_$acceptorUid';
          if (!_processedAcceptances.contains(key)) {
            _processedAcceptances.add(key);

            // グループに受諾者を追加（非同期処理）
            _addAcceptorToGroup(acceptorUid, data);
          }
        }
      } catch (e) {
        Log.error('招待受諾処理エラー: $e');
      }
    }
  }

  /// グループに受諾者を追加
  Future<void> _addAcceptorToGroup(
      String acceptorUid, Map<String, dynamic> invitationData) async {
    try {
      final groupId = widget.group.groupId;
      final currentAllowedUids = List<String>.from(widget.group.allowedUid);

      // 既に追加済みの場合はスキップ
      if (currentAllowedUids.contains(acceptorUid)) {
        Log.info('✅ [INVITATION_MONITOR] 既にメンバー追加済み: $acceptorUid');
        return;
      }

      // allowedUidに追加
      currentAllowedUids.add(acceptorUid);

      // 受諾者の名前を取得（招待データから、または通知から）
      final acceptorName = invitationData['acceptorName'] as String? ?? 'ユーザー';

      // メンバーリストに追加
      final updatedMembers =
          List<SharedGroupMember>.from(widget.group.members ?? []);
      updatedMembers.add(
        SharedGroupMember(
          memberId: acceptorUid,
          name: acceptorName,
          contact: '', // 空文字列（後で受諾者が設定可能）
          role: SharedGroupRole.member,
          isSignedIn: true,
          invitationStatus: InvitationStatus.accepted,
          acceptedAt: DateTime.now(),
        ),
      );

      Log.info(
          '📤 [INVITATION_MONITOR] Firestoreへグループ更新: allowedUid追加 $acceptorUid');

      // Firestoreに更新（ownerとして実行）
      await FirebaseFirestore.instance
          .collection('SharedGroups')
          .doc(groupId)
          .update({
        'allowedUid': currentAllowedUids,
        'members': updatedMembers
            .map((m) => {
                  'memberId': m.memberId,
                  'name': m.name,
                  'contact': m.contact,
                  'role': m.role.name,
                  'isSignedIn': m.isSignedIn,
                  'invitationStatus': m.invitationStatus.name,
                  'acceptedAt': m.acceptedAt?.toIso8601String(),
                })
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Log.info('✅ [INVITATION_MONITOR] グループ更新完了: $acceptorUid を追加');

      // ローカルのHiveも更新
      final repository = ref.read(SharedGroupRepositoryProvider);
      final updatedGroup = widget.group.copyWith(
        allowedUid: currentAllowedUids,
        members: updatedMembers,
      );
      await repository.updateGroup(groupId, updatedGroup);

      // UI通知
      if (mounted) {
        SnackBarHelper.showSuccess(context, '$acceptorName さんがグループに参加しました');
      }
    } catch (e) {
      Log.error('❌ [INVITATION_MONITOR] グループ更新エラー: $e');
    }
  }
}
