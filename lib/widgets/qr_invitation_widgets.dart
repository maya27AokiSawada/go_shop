import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/qr_invitation_service.dart';

/// QRコード招待ボタンウィジェット
class QRInviteButton extends ConsumerWidget {
  final String shoppingListId;
  final String purchaseGroupId;
  final String groupName;
  final String groupOwnerUid;
  final String? customMessage;

  const QRInviteButton({
    super.key,
    required this.shoppingListId,
    required this.purchaseGroupId,
    required this.groupName,
    required this.groupOwnerUid,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _showQRInviteDialog(context, ref),
      icon: const Icon(Icons.qr_code),
      label: const Text('QRコード招待'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showQRInviteDialog(BuildContext context, WidgetRef ref) async {
    final qrService = ref.read(qrInvitationServiceProvider);
    
    try {
      final invitationData = await qrService.createQRInvitationData(
        shoppingListId: shoppingListId,
        purchaseGroupId: purchaseGroupId,
        groupName: groupName,
        groupOwnerUid: groupOwnerUid,
        customMessage: customMessage,
      );
      
      final qrData = qrService.encodeQRData(invitationData);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => QRInviteDialog(
            qrData: qrData,
            invitationData: invitationData,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QRコード生成エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// QRコード招待ダイアログ
class QRInviteDialog extends ConsumerWidget {
  final String qrData;
  final Map<String, dynamic> invitationData;

  const QRInviteDialog({
    Key? key,
    required this.qrData,
    required this.invitationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrService = ref.read(qrInvitationServiceProvider);
    
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Go Shop 招待QRコード',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 説明
            const Text(
              '相手にこのQRコードを読み取ってもらい、\nグループに参加してもらいましょう',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // QRコード
            qrService.generateQRWidget(qrData, size: 200.0),
            const SizedBox(height: 20),
            
            // 招待情報
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '招待者: ${invitationData['inviterEmail']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'メッセージ: ${invitationData['message']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyQRData(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('データをコピー'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareQR(context),
                    icon: const Icon(Icons.share),
                    label: const Text('共有'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyQRData(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: qrData));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('招待データをクリップボードにコピーしました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareQR(BuildContext context) async {
    // TODO: Share機能の実装（share_plusライブラリなど）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('共有機能は今後実装予定です'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// QRコードスキャナーボタン
class QRScanButton extends ConsumerWidget {
  const QRScanButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _showQRScanner(context, ref),
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('QRコードを読み取り'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showQRScanner(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    );
  }
}

/// QRコードスキャナーページ
class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({super.key});

  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage> {
  MobileScannerController? controller;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードを読み取り'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => controller?.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => controller?.switchCamera(),
            icon: const Icon(Icons.camera_rear),
          ),
        ],
      ),
      body: Column(
        children: [
          // 説明
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Go Shopの招待QRコードをカメラで読み取ってください',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          
          // QRスキャナー
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: _onQRDetected,
            ),
          ),
          
          // 処理状況表示
          if (isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('招待を処理中...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) async {
    if (!isProcessing && capture.barcodes.isNotEmpty) {
      final qrData = capture.barcodes.first.rawValue;
      if (qrData != null) {
        await _handleQRScan(qrData);
      }
    }
  }

  Future<void> _handleQRScan(String qrData) async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
    });

    try {
      final qrService = ref.read(qrInvitationServiceProvider);
      final invitationData = qrService.decodeQRData(qrData);
      
      if (invitationData == null) {
        throw Exception('無効なQRコードです');
      }

      // 招待受諾確認ダイアログを表示
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => QRInvitationAcceptDialog(
            invitationData: invitationData,
          ),
        );

        if (result == true) {
          Navigator.of(context).pop(); // スキャナーページを閉じる
        }
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
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

/// QR招待受諾確認ダイアログ
class QRInvitationAcceptDialog extends ConsumerWidget {
  final Map<String, dynamic> invitationData;

  const QRInvitationAcceptDialog({
    Key? key,
    required this.invitationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.group_add, color: Colors.blue),
          SizedBox(width: 8),
          Text('グループ招待'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${invitationData['inviterEmail']} さんからの招待です',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('メッセージ: ${invitationData['message']}'),
          const SizedBox(height: 16),
          const Text(
            'この招待を受諾しますか？',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => _acceptInvitation(context, ref),
          child: const Text('受諾'),
        ),
      ],
    );
  }

  Future<void> _acceptInvitation(BuildContext context, WidgetRef ref) async {
    try {
      final qrService = ref.read(qrInvitationServiceProvider);
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final success = await qrService.acceptQRInvitation(
        invitationData: invitationData,
        acceptorUid: currentUser.uid,
        ref: ref,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('招待を受諾しました！'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          throw Exception('招待の受諾に失敗しました');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// FirebaseAuth プロバイダー（他の場所で定義されている場合は削除）
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});