// lib/pages/invitation_accept_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/invitation_service.dart';
import '../providers/purchase_group_provider.dart';

/// 招待受諾画面
class InvitationAcceptPage extends ConsumerStatefulWidget {
  final String inviteCode;

  const InvitationAcceptPage({
    super.key,
    required this.inviteCode,
  });

  @override
  ConsumerState<InvitationAcceptPage> createState() => _InvitationAcceptPageState();
}

class _InvitationAcceptPageState extends ConsumerState<InvitationAcceptPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _invitationInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvitationInfo();
  }

  Future<void> _loadInvitationInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invitationService = ref.read(invitationServiceProvider);
      final info = await invitationService.getInvitationByCode(widget.inviteCode);
      
      setState(() {
        _invitationInfo = info;
        _isLoading = false;
      });

      if (info == null) {
        setState(() {
          _errorMessage = '無効または期限切れの招待コードです';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '招待情報の取得に失敗しました: $e';
      });
    }
  }

  Future<void> _acceptInvitation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invitationService = ref.read(invitationServiceProvider);
      await invitationService.acceptInvitation(widget.inviteCode);

      if (mounted) {
        // グループリストを更新
        ref.invalidate(allGroupsProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('グループに参加しました！'),
            backgroundColor: Colors.green,
          ),
        );

        // ホーム画面に戻る
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('招待の受諾に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ招待'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _invitationInfo != null
                    ? _buildInvitationView()
                    : const Center(child: Text('招待情報を読み込み中...')),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'エラー',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationView() {
    final info = _invitationInfo!;
    final expiresAt = info['expiresAt'] as DateTime;
    final timeRemaining = expiresAt.difference(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 招待情報カード
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.group_add,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'グループ招待',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('グループ名', info['groupName']),
                const SizedBox(height: 8),
                _buildInfoRow('招待者', info['inviterEmail']),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '有効期限',
                  timeRemaining.inHours > 0
                      ? '残り${timeRemaining.inHours}時間'
                      : '残り${timeRemaining.inMinutes}分',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // 説明テキスト
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    '招待について',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'この招待を受諾すると、グループの買い物リストを共有できるようになります。',
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // アクションボタン
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('辞退'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _acceptInvitation,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '招待を受諾',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}