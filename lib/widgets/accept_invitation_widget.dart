// lib/widgets/accept_invitation_widget.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/auth_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../services/qr_invitation_service.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import 'windows_qr_scanner_simple.dart';

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
    // QRコード専用設定でコントローラーを初期化
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode], // QRコードのみ検出
      detectionSpeed: DetectionSpeed.normal, // 通常速度
      facing: CameraFacing.back, // バックカメラ
      torchEnabled: false,
    );
    Log.info('📷 [MOBILE_SCANNER] コントローラー初期化完了 - QRコード専用モード');

    // カメラ起動を待ってから状態をログ出力
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Log.info('📷 [MOBILE_SCANNER] カメラ起動待機完了');
        Log.info('📷 [MOBILE_SCANNER] Torch対応: ${_controller.torchEnabled}');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // プラットフォーム判定
    final isWindows = !kIsWeb && Platform.isWindows;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードをスキャン'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isWindows
          ? WindowsQRScannerSimple(
              onDetect: (rawValue) {
                if (_isProcessing) return;

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
              },
            )
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error) {
                    Log.error('❌ [MOBILE_SCANNER] カメラエラー: $error');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('カメラエラー: $error'),
                          const SizedBox(height: 16),
                          const Text('カメラの権限を確認してください'),
                        ],
                      ),
                    );
                  },
                  onDetect: (capture) {
                    Log.info('📷 [MOBILE_SCANNER] カメラ画像取得 - onDetect呼び出し');
                    Log.info('🔍 [MOBILE_SCANNER] onDetect呼び出し');
                    Log.info(
                        '🔍 [MOBILE_SCANNER] _isProcessing=$_isProcessing');

                    if (_isProcessing) {
                      Log.info('⚠️ [MOBILE_SCANNER] 既に処理中のためスキップ');
                      return;
                    }

                    final barcodes = capture.barcodes;
                    Log.info('🔍 [MOBILE_SCANNER] バーコード数: ${barcodes.length}');

                    if (barcodes.isEmpty) {
                      Log.info('⚠️ [MOBILE_SCANNER] バーコードが検出されませんでした');
                      return;
                    }

                    final rawValue = barcodes.first.rawValue;
                    Log.info(
                        '🔍 [MOBILE_SCANNER] rawValue長さ: ${rawValue?.length ?? 0}文字');
                    Log.info(
                        '🔍 [MOBILE_SCANNER] rawValue内容: ${rawValue != null ? rawValue.substring(0, rawValue.length > 100 ? 100 : rawValue.length) : 'null'}');

                    if (rawValue != null) {
                      Log.info(
                          '🔍 [MOBILE_SCANNER] 最初の文字: "${rawValue.isNotEmpty ? rawValue[0] : ''}"');
                      Log.info(
                          '🔍 [MOBILE_SCANNER] JSON形式チェック: startsWith({)=${rawValue.startsWith('{')} startsWith([)=${rawValue.startsWith('[')}');

                      // QRコードがJSON形式かトークン形式か判定
                      if (rawValue.startsWith('{') ||
                          rawValue.startsWith('[')) {
                        Log.info('✅ [MOBILE_SCANNER] JSON形式のQRコード検出 - 処理開始');
                        // JSON形式 = QR招待
                        _processQRInvitation(rawValue);
                      } else {
                        Log.warning(
                            '⚠️ [MOBILE_SCANNER] サポートされないQRコード形式: ${rawValue.substring(0, rawValue.length > 20 ? 20 : rawValue.length)}');
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
                    } else {
                      Log.warning('⚠️ [MOBILE_SCANNER] rawValueがnullです');
                    }
                  },
                ),
                // スキャンエリアのオーバーレイ
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'QRコードをここに',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                // 処理中インジケーター
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            '処理中...',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
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

        // QRデータをパース＆Firestoreから詳細取得（v3.1軽量版対応）
        final qrService = ref.read(qrInvitationServiceProvider);
        final invitationData = await qrService.decodeQRData(qrData);

        if (invitationData == null) {
          throw Exception('無効なQRコード形式です');
        }

        Log.info(
            '🔍 [QR_SCAN] 受信したQRデータ: ${qrData.substring(0, qrData.length > 100 ? 100 : qrData.length)}...');
        Log.info(
            '🔍 [QR_SCAN] SharedGroupId: ${invitationData['sharedGroupId']}');
        Log.info('🔍 [QR_SCAN] groupName: ${invitationData['groupName']}');

        final groupName = invitationData['groupName'] as String? ?? '不明なグループ';
        final groupId = invitationData['sharedGroupId'] as String;

        // すでにグループメンバーかチェック
        final groupRepository = ref.read(SharedGroupRepositoryProvider);
        try {
          final existingGroup = await groupRepository.getGroupById(groupId);

          if (existingGroup.allowedUid.contains(user.uid)) {
            Log.info('💡 [QR_SCAN] すでにグループメンバー: ${user.uid}');
            if (mounted) {
              Navigator.of(context).pop(); // スキャナー画面を閉じる
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('すでに「$groupName」に参加しています'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        } catch (e) {
          // グループが見つからない場合は新規参加として続行
          Log.info('📝 [QR_SCAN] グループ未参加 - 確認ダイアログ表示');
        }

        // 確認ダイアログ
        if (!mounted) return;
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
          Log.info('🔍 [ACCEPT] 招待受諾処理開始...');
          final qrService = ref.read(qrInvitationServiceProvider);
          final success = await qrService.acceptQRInvitation(
            invitationData: invitationData,
            acceptorUid: user.uid,
            ref: ref,
          );

          Log.info('🔍 [ACCEPT] 招待受諾結果: success=$success, mounted=$mounted');

          if (success && mounted) {
            // 🔥 FIX: rootNavigatorを使用してスキャナー画面を確実に閉じる
            Log.info('🔍 [ACCEPT] スキャナー画面を閉じます...');
            Navigator.of(context, rootNavigator: true).pop();
            Log.info('✅ [ACCEPT] スキャナー画面を閉じました');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ 招待を受諾しました'),
                    const SizedBox(height: 4),
                    Text(
                      '招待元（$groupName）の確認をお待ちください',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
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
