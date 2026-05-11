// lib/widgets/accept_invitation_widget.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_provider.dart';
import '../services/error_log_service.dart';
import '../services/qr_invitation_service.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import 'windows_qr_scanner_simple.dart';
import '../l10n/l10n.dart';

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
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  texts.inviteAcceptTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              texts.inviteAcceptDesc,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showQRScanner(context, ref),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(texts.scanQRCode),
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

    // 🔥 修正: 画面幅と高さの両方を考慮してスキャンエリアサイズを決定
    // AppBar(56px) + SafeAreaパディング + マージンを考慮
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // 利用可能な高さを計算（AppBar + SafeAreaパディング + ツールバーマージンを除外）
    final availableHeight =
        screenSize.height - 56 - padding.top - padding.bottom - 100;

    // スキャンエリアサイズ: 画面幅の60%、最小180px、最大280px
    final widthBasedSize = (screenSize.width * 0.6).clamp(180.0, 280.0);

    // 高さ基準のサイズ: 利用可能高さの70%
    final heightBasedSize = (availableHeight * 0.7).clamp(180.0, 280.0);

    // 最終サイズ: 幅と高さの小さい方を使用（AS10Lのような小画面対応）
    final scanAreaSize =
        widthBasedSize < heightBasedSize ? widthBasedSize : heightBasedSize;

    return Scaffold(
      appBar: AppBar(
        title: Text(texts.qrCodeReader),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: isWindows
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
                            const Icon(Icons.error,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('${texts.cameraErrorPrefix} $error'),
                            const SizedBox(height: 16),
                            Text(texts.checkCameraPermission),
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
                      Log.info(
                          '🔍 [MOBILE_SCANNER] バーコード数: ${barcodes.length}');

                      if (barcodes.isEmpty) {
                        Log.info('⚠️ [MOBILE_SCANNER] バーコードが検出されませんでした');
                        return;
                      }

                      // 🔥 NEW: バーコード詳細情報をログ出力（ディープリンク問題調査）
                      final barcode = barcodes.first;
                      Log.info(
                          '🔍 [MOBILE_SCANNER] Barcode type: ${barcode.type}');
                      Log.info(
                          '🔍 [MOBILE_SCANNER] Barcode format: ${barcode.format}');
                      Log.info(
                          '🔍 [MOBILE_SCANNER] Barcode value type: ${barcode.type.name}');
                      if (barcode.url != null) {
                        Log.warning(
                            '⚠️ [MOBILE_SCANNER] URL検出: ${barcode.url}');
                      }

                      final rawValue = barcode.rawValue;
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
                              SnackBar(
                                content: Text(texts.invalidQRFormat),
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
                  // スキャンエリアのオーバーレイ（動的サイズ対応）
                  Center(
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          texts.qrCodeHereOverlay,
                          style: const TextStyle(
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
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              texts.syncing,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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

        final groupName =
            invitationData['groupName'] as String? ?? texts.unknownGroup;
        final groupId = invitationData['sharedGroupId'] as String;

        // すでにグループメンバーかチェック
        // 🔥 FIX: Firestoreを直接参照（Hiveキャッシュをバイパス）
        // 退出後はallowedUidから削除されるため、Firestoreへのgetが permission-denied になる。
        // HybridRepoはそれをキャッチしてHiveにフォールバックするため、古いキャッシュを返してしまう。
        // 直接参照することでキャッシュ問題を回避し、permission-deniedを「メンバーでない」と正しく判定する。
        bool isAlreadyMember = false;
        try {
          final groupDoc = await FirebaseFirestore.instance
              .collection('SharedGroups')
              .doc(groupId)
              .get();
          if (groupDoc.exists) {
            final allowedUid =
                List<String>.from(groupDoc.data()?['allowedUid'] ?? []);
            isAlreadyMember = allowedUid.contains(user.uid);
            Log.info(
                '🔍 [QR_SCAN] Firestore最新allowedUid確認: isAlreadyMember=$isAlreadyMember');
          } else {
            Log.info('📝 [QR_SCAN] グループがFirestoreに存在しない - 新規参加フローへ');
          }
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            // permission-denied = allowedUidから除外済み = メンバーではない（退出済み）
            Log.info(
                '📝 [QR_SCAN] Firestore permission-denied = メンバーではない（退出済み）- 参加フローへ');
            isAlreadyMember = false;
          } else {
            Log.warning('⚠️ [QR_SCAN] Firestore取得エラー (${e.code}) - 参加フローを続行');
          }
        } catch (e) {
          Log.info('📝 [QR_SCAN] グループ取得エラー - 新規参加として続行: $e');
        }

        if (isAlreadyMember) {
          Log.info('💡 [QR_SCAN] すでにグループメンバー: ${user.uid}');
          if (mounted) {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.maybeOf(context);
            try {
              await _controller.stop();
            } catch (e) {
              Log.warning('⚠️ [QR_SCAN] カメラ停止エラー: $e');
            }
            navigator.pop(); // スキャナー画面を閉じる
            messenger?.showSnackBar(
              SnackBar(
                content: Text(texts.alreadyJoinedGroup(groupName)),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        // 確認ダイアログ
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(texts.joinGroup),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.joinGroupQuestion),
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
                child: Text(texts.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(texts.join),
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
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.maybeOf(context);

            try {
              Log.info('🔍 [ACCEPT] カメラ停止開始...');
              await _controller.stop();
              Log.info('✅ [ACCEPT] カメラ停止完了');
            } catch (e) {
              Log.warning('⚠️ [ACCEPT] カメラ停止エラー: $e');
            }

            // 通常のNavigatorで現在のスキャナー画面だけ閉じる
            Log.info('🔍 [ACCEPT] スキャナー画面を閉じます...');
            navigator.pop();
            Log.info('✅ [ACCEPT] スキャナー画面を閉じました');

            messenger?.showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(texts.invitationAccepted),
                    const SizedBox(height: 4),
                    Text(
                      texts.invitationPendingApproval(groupName),
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
        // エラー履歴に記録
        ErrorLogService.logOperationError('QR招待受諾', '$error', stackTrace);
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
