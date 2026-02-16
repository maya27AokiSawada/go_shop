import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/invite_code_service.dart';
import '../utils/snackbar_helper.dart';

/// QRコード読み取り画面 + 手動入力ダイアログ
///
/// 機能:
/// - カメラでQRコード読み取り
/// - 手動入力ダイアログ
/// - 招待コード検証
/// - エラーハンドリング
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  late MobileScannerController controller;
  bool isProcessing = false;
  String? lastScannedCode;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード読み取り'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showManualInputDialog(context),
            icon: const Icon(Icons.keyboard),
            tooltip: 'コード手動入力',
          ),
        ],
      ),
      body: Stack(
        children: [
          // カメラプレビュー
          MobileScanner(
            controller: controller,
            onDetect: _handleQrCode,
          ),

          // オーバーレイ
          _buildScanOverlay(),

          // 処理中インジケーター
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '招待コードを確認中...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  /// スキャンオーバーレイ
  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // コーナーマーカー
            ...List.generate(4, (index) {
              return Positioned(
                top: index < 2 ? 0 : null,
                bottom: index >= 2 ? 0 : null,
                left: index % 2 == 0 ? 0 : null,
                right: index % 2 == 1 ? 0 : null,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft:
                          index == 0 ? const Radius.circular(9) : Radius.zero,
                      topRight:
                          index == 1 ? const Radius.circular(9) : Radius.zero,
                      bottomLeft:
                          index == 2 ? const Radius.circular(9) : Radius.zero,
                      bottomRight:
                          index == 3 ? const Radius.circular(9) : Radius.zero,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 下部説明シート
  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'QRコードを枠内に合わせてください',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'QRコードが見つからない場合は、右上のキーボードアイコンから招待コードを手動入力できます。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showManualInputDialog(context),
              icon: const Icon(Icons.keyboard),
              label: const Text('手動入力'),
            ),
          ),
        ],
      ),
    );
  }

  /// QRコード検出処理
  void _handleQrCode(BarcodeCapture capture) async {
    if (isProcessing) return;

    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty || code == lastScannedCode) return;

    // 重複スキャン防止
    lastScannedCode = code;

    setState(() => isProcessing = true);

    await _processInviteCode(code);

    if (mounted) {
      setState(() => isProcessing = false);
    }
  }

  /// 招待コード処理
  Future<void> _processInviteCode(String code) async {
    try {
      // 基本フォーマット検証
      if (!InviteCodeService.validateInviteCode(code, 'dummy-group-id')) {
        throw Exception('無効な招待コード形式です');
      }

      // TODO: 実際のグループ検索・参加処理
      // 現在は仮の成功処理
      await Future.delayed(const Duration(seconds: 1)); // 検証処理をシミュレート

      if (mounted) {
        // 成功時の処理
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('招待コード「$code」を認識しました')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // 結果を返して画面を閉じる
        Navigator.of(context).pop(code);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'エラー: $e');

        // エラー時はスキャンを続行
        lastScannedCode = null;
      }
    }
  }

  /// 手動入力ダイアログ
  Future<void> _showManualInputDialog(BuildContext context) async {
    final codeController = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: Colors.blue),
            SizedBox(width: 8),
            Text('招待コードを入力'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('8桁の英数字を入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                hintText: 'AB12CD34',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                letterSpacing: 2,
              ),
              onChanged: (value) {
                // 大文字に変換
                final upperValue = value.toUpperCase();
                if (upperValue != value) {
                  codeController.value = codeController.value.copyWith(
                    text: upperValue,
                    selection:
                        TextSelection.collapsed(offset: upperValue.length),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(codeController.text.trim()),
            child: const Text('確認'),
          ),
        ],
      ),
    );

    if (code != null && code.isNotEmpty) {
      await _processInviteCode(code);
    }
  }
}
