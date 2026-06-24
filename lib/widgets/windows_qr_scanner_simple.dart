// lib/widgets/windows_qr_scanner_simple.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../utils/app_logger.dart';

// Note: Windows版では画像からのQRコード自動読み取りは未実装
// ユーザーはAndroid/iOSデバイスでQRコードをスキャンしてください

/// Windows専用QRスキャナーウィジェット（画像ファイル選択のみ）
/// カメラは非対応のため、画像ファイルからQRコードを読み取る
class WindowsQRScannerSimple extends StatefulWidget {
  final Function(String) onDetect;

  const WindowsQRScannerSimple({
    super.key,
    required this.onDetect,
  });

  @override
  State<WindowsQRScannerSimple> createState() => _WindowsQRScannerSimpleState();
}

class _WindowsQRScannerSimpleState extends State<WindowsQRScannerSimple> {
  String? _errorMessage;
  bool _isProcessing = false;

  /// 画像ファイルを選択してQRコードをスキャン
  Future<void> _pickImageAndScan() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      Log.info('📁 画像ファイル選択開始...');

      // ファイル選択
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        Log.info('ℹ️ ファイル選択がキャンセルされました');
        setState(() => _isProcessing = false);
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        Log.error('❌ ファイルパスが取得できません');
        setState(() {
          _errorMessage = 'ファイルパスが取得できませんでした';
          _isProcessing = false;
        });
        return;
      }

      Log.info('📷 画像ファイルを解析: $filePath');

      // 画像ファイルを読み込み
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // 画像をデコード
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('画像のデコードに失敗しました');
      }

      // QRコードを検出
      final qrCode = _detectQRCode(image);

      if (qrCode != null && qrCode.isNotEmpty) {
        Log.info('✅ QRコード検出（画像ファイル）: $qrCode');
        widget.onDetect(qrCode);
      } else {
        // Windows版: 自動検出失敗時は手動入力を促す
        setState(() => _isProcessing = false);

        if (mounted) {
          final manualInput = await _showManualInputDialog();
          if (manualInput != null && manualInput.isNotEmpty) {
            Log.info('✅ 手動入力されたQRコード: $manualInput');
            widget.onDetect(manualInput);
          }
        }
      }
    } catch (e, stackTrace) {
      Log.error('❌ 画像ファイルQRスキャンエラー: $e', e, stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'エラー: $e';
          _isProcessing = false;
        });
      }
    }
  }

  /// QRコードを検出（Pure Dart実装）
  String? _detectQRCode(img.Image image) {
    // Windows版: 画像からのQRコード自動読み取りは未実装
    // ユーザーに手動入力を促す
    Log.info('📷 画像選択完了: ${image.width}x${image.height}');
    Log.info('⚠️ Windows版では自動QRコード読み取りは未対応です');

    return null; // 手動入力を促すためnullを返す
  }

  /// 手動入力ダイアログを表示
  Future<String?> _showManualInputDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコードを手動入力'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Windows版では画像からのQRコード自動読み取りは未対応です。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'スマートフォンで表示されているQRコードの内容（JSON形式）を\n'
                '手動で入力してください:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{"groupId": "...", "groupName": "...", ...}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.of(context).pop(text.isNotEmpty ? text : null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードスキャン (Windows)'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アイコン
              Icon(
                _errorMessage != null
                    ? Icons.error_outline
                    : Icons.qr_code_scanner,
                size: 100,
                color: _errorMessage != null ? Colors.orange : Colors.blue,
              ),
              const SizedBox(height: 24),

              // メッセージ
              Text(
                _errorMessage ?? 'Windows版では自動QRスキャン未対応',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _errorMessage != null
                      ? Colors.orange.shade900
                      : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),

              // 説明
              if (_errorMessage == null)
                Text(
                  'Windows版ではQRコード自動読み取りは未対応です。\n'
                  'Android/iOSデバイスでQRコードをスキャンしてください。\n'
                  '（または、画像選択後に手動で招待コードを入力）',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

              const SizedBox(height: 32),

              // 画像ファイル選択ボタン
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImageAndScan,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.image),
                label: Text(_isProcessing ? '処理中...' : '画像ファイルを選択'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 戻るボタン
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
