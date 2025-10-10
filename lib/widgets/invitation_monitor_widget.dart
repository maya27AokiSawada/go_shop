// lib/widgets/invitation_monitor_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accepted_invitation.dart';
import '../services/accepted_invitation_service.dart';
import '../services/invitation_monitor_service.dart';

/// 招待監視ウィジェット（オーナー専用）
/// 受諾された招待をリアルタイム表示し、権限同期を管理
class InvitationMonitorWidget extends ConsumerStatefulWidget {
  const InvitationMonitorWidget({super.key});

  @override
  ConsumerState<InvitationMonitorWidget> createState() => _InvitationMonitorWidgetState();
}

class _InvitationMonitorWidgetState extends ConsumerState<InvitationMonitorWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // 監視開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invitationMonitorServiceProvider).startMonitoring();
    });
  }

  @override
  void dispose() {
    // 監視停止
    ref.read(invitationMonitorServiceProvider).stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acceptedInvitationService = ref.read(acceptedInvitationServiceProvider);

    return Card(
      child: StreamBuilder<List<FirestoreAcceptedInvitation>>(
        stream: acceptedInvitationService.watchUnprocessedInvitations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('招待状況を確認中...'),
                ],
              ),
            );
          }

          final invitations = snapshot.data ?? [];
          
          return ExpansionTile(
            leading: Icon(
              invitations.isEmpty ? Icons.check_circle : Icons.notifications_active,
              color: invitations.isEmpty ? Colors.green : Colors.orange,
            ),
            title: Text(
              invitations.isEmpty 
                ? '📥 招待受諾 (待機中: 0件)'
                : '📥 招待受諾 (未処理: ${invitations.length}件)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: invitations.isEmpty ? Colors.green[700] : Colors.orange[700],
              ),
            ),
            subtitle: Text(
              invitations.isEmpty
                ? 'すべての招待が処理済みです'
                : '${invitations.length}件の新しい参加者が待機中',
            ),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            children: [
              if (invitations.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '🎉 現在、未処理の招待受諾はありません。\n'
                    '新しいメンバーが参加するとここに表示されます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Column(
                  children: [
                    ...invitations.map((invitation) => _buildInvitationTile(invitation)),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _processAllInvitations(),
                              icon: const Icon(Icons.playlist_add_check),
                              label: const Text('すべて処理'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showInvitationStats(),
                            icon: const Icon(Icons.analytics),
                            tooltip: '招待統計',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInvitationTile(FirestoreAcceptedInvitation invitation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange[100],
        child: Text(
          invitation.acceptorName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(invitation.acceptorName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📧 ${invitation.acceptorEmail}'),
          Text('👥 ${invitation.inviteRole} として参加'),
          Text('🕒 ${_formatDateTime(invitation.acceptedAt)}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _processInvitation(invitation),
            icon: const Icon(Icons.check, color: Colors.green),
            tooltip: '承認して権限付与',
          ),
          IconButton(
            onPressed: () => _rejectInvitation(invitation),
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: '拒否',
          ),
        ],
      ),
    );
  }

  Future<void> _processInvitation(FirestoreAcceptedInvitation invitation) async {
    try {
      final monitorService = ref.read(invitationMonitorServiceProvider);
      
      // 個別処理は processAllPendingInvitations を使って実行
      await monitorService.processAllPendingInvitations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${invitation.acceptorName}の参加を承認しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 処理に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvitation(FirestoreAcceptedInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('招待を拒否'),
        content: Text('${invitation.acceptorName}の参加を拒否しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('拒否'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final acceptedInvitationService = ref.read(acceptedInvitationServiceProvider);
        await acceptedInvitationService.deleteAcceptedInvitation(
          acceptorUid: invitation.acceptorUid,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${invitation.acceptorName}の招待を拒否しました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 拒否処理に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _processAllInvitations() async {
    try {
      final monitorService = ref.read(invitationMonitorServiceProvider);
      await monitorService.processAllPendingInvitations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ すべての招待を処理しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 一括処理に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showInvitationStats() async {
    final monitorService = ref.read(invitationMonitorServiceProvider);
    final stats = await monitorService.getInvitationStats();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 招待統計'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('総招待数: ${stats['total'] ?? 0}件'),
              Text('処理済み: ${stats['processed'] ?? 0}件'),
              Text('未処理: ${stats['pending'] ?? 0}件'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
           '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}