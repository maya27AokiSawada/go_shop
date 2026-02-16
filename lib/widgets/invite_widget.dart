import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/shared_group.dart';
import '../services/invite_code_service.dart';

/// QRコード中心の招待ウィジェット（AutoInviteButtonの置き換え）
///
/// 機能:
/// - セキュアな8桁招待コード生成
/// - QRコード表示
/// - 招待文の手動共有（ユーザー選択）
/// - クリップボードコピー機能
class InviteWidget extends ConsumerWidget {
  final SharedGroup group;

  const InviteWidget({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteCode = InviteCodeService.generateInviteCode(group.groupId);
    final inviteText =
        InviteCodeService.generateInviteText(group.groupName, inviteCode);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Row(
              children: [
                const Icon(Icons.group_add, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'グループに招待',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // QRコード表示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: inviteCode,
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QRコードをスキャン',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 招待コード表示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '招待コード',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          inviteCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyToClipboard(context, inviteCode),
                    icon: const Icon(Icons.copy),
                    tooltip: 'コピー',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 共有ボタン群
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareInvite(context, inviteText),
                    icon: const Icon(Icons.share),
                    label: const Text('招待文を共有'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context, inviteText),
                    icon: const Icon(Icons.content_copy),
                    label: const Text('招待文をコピー'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 説明文
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QRコードを読み取るか、招待コードを手動入力で参加できます。\nLINE、メール、SNSなどお好みの方法で共有してください。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// クリップボードにコピー
  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('クリップボードにコピーしました')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 招待文を共有（将来的にshare_plusパッケージ使用）
  Future<void> _shareInvite(BuildContext context, String text) async {
    // 暫定：クリップボードにコピー + 案内
    await _copyToClipboard(context, text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.share, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('招待文をコピーしました'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'LINEやメールなどで共有してください',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
