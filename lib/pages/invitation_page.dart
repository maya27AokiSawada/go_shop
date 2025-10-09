// lib/pages/invitation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/invitation_service.dart';
import '../providers/auth_provider.dart';

class InvitationPage extends ConsumerStatefulWidget {
  final String invitationId;
  final String groupId;
  
  const InvitationPage({
    super.key,
    required this.invitationId,
    required this.groupId,
  });

  @override
  ConsumerState<InvitationPage> createState() => _InvitationPageState();
}

class _InvitationPageState extends ConsumerState<InvitationPage> {
  final InvitationService _invitationService = InvitationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('グループ招待')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: authState.when(
          data: (user) {
            if (user == null) {
              return _buildLoginPrompt();
            } else {
              return _buildInvitationAccept();
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.group_add, size: 80, color: Colors.blue),
        const SizedBox(height: 20),
        const Text(
          'グループに参加するには\nログインが必要です',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            // ログイン画面に遷移
            Navigator.pushReplacementNamed(context, '/login', arguments: {
              'redirectPath': '/invite',
              'invitationId': widget.invitationId,
              'groupId': widget.groupId,
            });
          },
          child: const Text('ログイン / サインアップ'),
        ),
      ],
    );
  }

  Widget _buildInvitationAccept() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.group, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          'グループへの招待',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'グループID: ${widget.groupId}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        const Text(
          'このグループに参加しますか？',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _acceptInvitation,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('参加する'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _acceptInvitation() async {
    setState(() => _isLoading = true);

    try {
      // 新しいAPIでは招待コードを使用
      await _invitationService.acceptInvitation(widget.invitationId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('グループに参加しました！')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('参加に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
