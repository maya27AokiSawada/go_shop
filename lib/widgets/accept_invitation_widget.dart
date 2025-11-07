// lib/widgets/accept_invitation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/auth_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../utils/app_logger.dart';

/// 招待受諾ウィジェット
///
/// グループ画面に配置し、QRスキャンまたは手動入力で招待を受諾
class AcceptInvitationWidget extends ConsumerWidget {
  const AcceptInvitationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '招待を受ける',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'グループに招待されましたか？\nQRコードをスキャンするか、招待コードを入力してください。',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showQRScanner(context, ref),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('QRスキャン'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showManualInput(context, ref),
                    icon: const Icon(Icons.keyboard),
                    label: const Text('コード入力'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// QRスキャナーを表示
  void _showQRScanner(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }

  /// 手動入力ダイアログを表示
  void _showManualInput(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ManualInvitationInputDialog(),
    );
  }
}

/// QRスキャナー画面
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  late MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードをスキャン'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;

              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final token = barcodes.first.rawValue;
              if (token != null && token.startsWith('INV_')) {
                _processInvitation(token);
              }
            },
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showManualInput(context, ref);
                },
                icon: const Icon(Icons.keyboard),
                label: const Text('コード入力に切り替え'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processInvitation(String token) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) {
        throw Exception('ユーザー情報が取得できません');
      }

      // 招待情報を取得して確認
      final service = ref.read(invitationServiceProvider);
      final invitation = await service.validateAndGetInvitation(token);

      if (invitation == null || !mounted) {
        throw Exception('無効な招待コードです');
      }

      // 確認ダイアログ
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('グループに参加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('以下のグループに参加しますか？'),
              const SizedBox(height: 16),
              Text(
                invitation.groupName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('招待者: ${invitation.inviterName}'),
              Text('有効期限: ${invitation.remainingTime.inHours}時間'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('参加する'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        // 招待を受諾
        final success = await service.acceptInvitation(
          token: token,
          userId: user.uid,
          userName: user.displayName ?? 'Unknown',
          userEmail: user.email ?? '',
        );

        if (success && mounted) {
          // グループ一覧を更新
          ref.invalidate(allGroupsProvider);

          Navigator.of(context).pop(); // スキャナー画面を閉じる
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「${invitation.groupName}」に参加しました'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          throw Exception('グループへの参加に失敗しました');
        }
      }
    } catch (e) {
      Log.error('❌ [INVITATION] 招待処理エラー: $e');
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
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showManualInput(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ManualInvitationInputDialog(),
    );
  }
}

/// 手動入力ダイアログ
class ManualInvitationInputDialog extends ConsumerStatefulWidget {
  const ManualInvitationInputDialog({super.key});

  @override
  ConsumerState<ManualInvitationInputDialog> createState() =>
      _ManualInvitationInputDialogState();
}

class _ManualInvitationInputDialogState
    extends ConsumerState<ManualInvitationInputDialog> {
  final _controller = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('招待コード入力'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('招待コードを入力してください'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'INV_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processInvitation,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('確認'),
        ),
      ],
    );
  }

  Future<void> _processInvitation() async {
    final token = _controller.text.trim();

    if (token.isEmpty || !token.startsWith('INV_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('有効な招待コードを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) {
        throw Exception('ユーザー情報が取得できません');
      }

      final service = ref.read(invitationServiceProvider);
      final invitation = await service.validateAndGetInvitation(token);

      if (invitation == null || !mounted) {
        throw Exception('無効な招待コードです');
      }

      // ダイアログを閉じて確認ダイアログを表示
      Navigator.of(context).pop();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('グループに参加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('以下のグループに参加しますか？'),
              const SizedBox(height: 16),
              Text(
                invitation.groupName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('招待者: ${invitation.inviterName}'),
              Text('有効期限: ${invitation.remainingTime.inHours}時間'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('参加する'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final success = await service.acceptInvitation(
          token: token,
          userId: user.uid,
          userName: user.displayName ?? 'Unknown',
          userEmail: user.email ?? '',
        );

        if (success && mounted) {
          ref.invalidate(allGroupsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「${invitation.groupName}」に参加しました'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          throw Exception('グループへの参加に失敗しました');
        }
      }
    } catch (e) {
      Log.error('❌ [INVITATION] 招待処理エラー: $e');
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
        setState(() => _isProcessing = false);
      }
    }
  }
}
