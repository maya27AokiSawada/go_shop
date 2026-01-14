// lib/widgets/windows_qr_scanner.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/app_logger.dart';

/// Windows用QRコードスキャナー
/// camera + google_mlkit_barcode_scanning を使用
class WindowsQRScanner extends StatefulWidget {
  final void Function(String code) onDetect;
  final String? overlayText;

  const WindowsQRScanner({
    super.key,
    required this.onDetect,
    this.overlayText,
  });

  @override
  State<WindowsQRScanner> createState() => _WindowsQRScannerState();
}

class _WindowsQRScannerState extends State<WindowsQRScanner> {
  CameraController? _cameraController;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      Log.info('📷 カメラ初期化開始...');

      // タイムアウト付きでカメラ取得（5秒）
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Log.error('❌ カメラ取得タイムアウト');
          throw Exception('カメラ取得がタイムアウトしました');
        },
      );

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'カメラが見つかりません。\n\n'
              '画像ファイルから読み取ることもできます。\n'
              '下のボタンを押してQRコード画像を選択してください。';
        });
        Log.error('❌ カメラが見つかりません');
        return;
      }

      Log.info('✅ ${cameras.length}台のカメラを検出');

      // 最初のカメラを使用
      final camera = cameras.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      // タイムアウト付きで初期化（10秒）
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Log.error('❌ カメラ初期化タイムアウト');
          throw Exception('カメラ初期化がタイムアウトしました');
        },
      );

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      Log.info('✅ カメラ初期化完了');

      // 画像ストリーム開始
      _cameraController!.startImageStream(_processCameraImage);
    } on TimeoutException catch (e) {
      Log.error('❌ カメラ初期化タイムアウト: $e');
      setState(() {
        _errorMessage = 'カメラの起動に時間がかかりすぎています。\n\n'
            'Windowsのカメラドライバーやセキュリティ設定を\n'
            '確認してください。\n\n'
            '代わりに画像ファイルから読み取ることもできます。\n'
            '下のボタンを押してQRコード画像を選択してください。';
      });
    } catch (e, stackTrace) {
      Log.error('❌ カメラ初期化エラー: $e', e, stackTrace);

      // カメラアクセス拒否の場合の詳細メッセージ
      String errorDetail = 'カメラ初期化エラー: $e';
      if (e.toString().contains('permission') ||
          e.toString().contains('access') ||
          e.toString().contains('denied')) {
        errorDetail = 'カメラへのアクセスが拒否されました。\n\n'
            'Windowsの設定でカメラアクセスを許可してください：\n\n'
            '1. 「設定」を開く\n'
            '2. 「プライバシーとセキュリティ」→「カメラ」\n'
            '3. 「アプリがカメラにアクセスできるようにする」をオン\n'
            '4. デスクトップアプリの一覧で「GoShopping」を探してオン\n\n'
            '設定変更後、このアプリを再起動してください。';
      }

      setState(() {
        _errorMessage = errorDetail;
      });
    }
  }

  /// 画像ファイルからQRコードを読み取る
  Future<void> _pickImageAndScan() async {
    try {
      Log.info('📁 画像ファイル選択開始...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        Log.info('⚠️ ファイル選択がキャンセルされました');
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        Log.error('❌ ファイルパスが取得できません');
        return;
      }

      Log.info('📷 画像ファイルを解析: $filePath');

      // InputImageを作成
      final inputImage = InputImage.fromFilePath(filePath);

      // バーコードスキャン
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QRコードが見つかりませんでした'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        Log.info('⚠️ QRコードが見つかりませんでした');
        return;
      }

      final barcode = barcodes.first;
      final rawValue = barcode.rawValue;

      if (rawValue != null && rawValue.isNotEmpty) {
        Log.info('✅ QRコード検出（画像ファイル）: $rawValue');
        widget.onDetect(rawValue);
      }
    } catch (e, stackTrace) {
      Log.error('❌ 画像ファイルQRスキャンエラー: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // CameraImageをInputImageに変換
      final inputImage = _convertCameraImage(image);

      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // バーコードスキャン
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        final rawValue = barcode.rawValue;

        if (rawValue != null && rawValue.isNotEmpty) {
          Log.info('✅ QRコード検出: $rawValue');

          // コールバック実行（UI更新のためasync/awaitなし）
          widget.onDetect(rawValue);

          // スキャン成功後はストリームを停止
          await _cameraController?.stopImageStream();
        }
      }
    } catch (e) {
      Log.error('❌ 画像処理エラー: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // CameraImageのメタデータを取得
      final camera = _cameraController?.description;
      if (camera == null) return null;

      // 画像の向きを取得
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      if (sensorOrientation == 0) {
        rotation = InputImageRotation.rotation0deg;
      } else if (sensorOrientation == 90) {
        rotation = InputImageRotation.rotation90deg;
      } else if (sensorOrientation == 180) {
        rotation = InputImageRotation.rotation180deg;
      } else if (sensorOrientation == 270) {
        rotation = InputImageRotation.rotation270deg;
      }

      if (rotation == null) return null;

      // InputImageFormatを取得
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      // プレーンを取得
      if (image.planes.isEmpty) return null;

      final plane = image.planes.first;

      // InputImageを作成
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      Log.error('❌ CameraImage変換エラー: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 80, color: Colors.orange.shade300),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickImageAndScan,
                icon: const Icon(Icons.image),
                label: const Text('画像ファイルから読み取る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isInitialized = false;
                  });
                  _initializeCamera();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('カメラ再試行'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('戻る'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('カメラを起動中...'),
            const SizedBox(height: 8),
            Text(
              '起動に時間がかかる場合は\n画像ファイルから読み取ることもできます',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // カメラプレビュー
        Center(
          child: AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),

        // オーバーレイ（スキャンエリア表示）
        Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ガイドテキスト
        if (widget.overlayText != null)
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Colors.black54,
              child: Text(
                widget.overlayText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),

        // 画像ファイル選択ボタン
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _pickImageAndScan,
              icon: const Icon(Icons.image),
              label: const Text('画像ファイルから読み取る'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
