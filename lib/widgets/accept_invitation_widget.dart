// lib/widgets/accept_invitation_widget.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/auth_provider.dart';
import '../services/qr_invitation_service.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

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
            ElevatedButton.icon(
              onPressed: () => _showQRScanner(context, ref),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QRコードをスキャン'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
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

              final rawValue = barcodes.first.rawValue;
              if (rawValue != null) {
                // QRコードがJSON形式かトークン形式か判定
                if (rawValue.startsWith('{') || rawValue.startsWith('[')) {
                  // JSON形式 = QR招待
                  _processQRInvitation(rawValue);
                } else {
                  // サポートされない形式
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('無効なQRコード形式です'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _processQRInvitation(String qrData) async {
    Log.info(
        '🔍 [QR_SCAN] _processQRInvitation開始, _isProcessing: $_isProcessing');
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    Log.info('🔍 [QR_SCAN] _isProcessing=true に設定');

    await ErrorHandler.handleAsync(
      operation: () async {
        final user = ref.read(authStateProvider).valueOrNull;
        if (user == null) {
          throw Exception('ユーザー情報が取得できません');
        }

        // QRデータをJSONとしてパース
        Map<String, dynamic> invitationData;
        try {
          invitationData = jsonDecode(qrData) as Map<String, dynamic>;
          Log.info('🔍 [QR_SCAN] 受信したQRデータ: $qrData');
          Log.info(
              '🔍 [QR_SCAN] purchaseGroupId: ${invitationData['purchaseGroupId']}');
          Log.info('🔍 [QR_SCAN] groupName: ${invitationData['groupName']}');
        } catch (e) {
          throw Exception('無効なQRコード形式です');
        }

        // 確認ダイアログ
        final groupName = invitationData['groupName'] as String? ?? '不明なグループ';
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
                  groupName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          // QR招待を受諾
          final qrService = ref.read(qrInvitationServiceProvider);
          final success = await qrService.acceptQRInvitation(
            invitationData: invitationData,
            acceptorUid: user.uid,
            ref: ref,
          );

          if (success && mounted) {
            Navigator.of(context).pop(); // スキャナー画面を閉じる
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('「$groupName」に参加しました'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (mounted) {
            throw Exception('グループへの参加に失敗しました');
          }
        }
      },
      context: 'ACCEPT_INVITE:processQRInvitation',
      defaultValue: null,
      onError: (error, stackTrace) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラー: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}
