// lib/helpers/ui_helper.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// UI関連のヘルパー関数を集約
class UiHelper {
  static final Logger _logger = Logger();

  /// 成功メッセージを表示
  static void showSuccessMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// エラーメッセージを表示
  static void showErrorMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
      ),
    );
  }

  /// 警告メッセージを表示
  static void showWarningMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: duration,
      ),
    );
  }

  /// 情報メッセージを表示
  static void showInfoMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: duration,
      ),
    );
  }

  /// カスタマイズ可能なSnackBarを表示
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.blue,
        duration: duration,
      ),
    );
  }

  /// 確認ダイアログを表示
  /// 
  /// Returns: ユーザーが「はい」を選択した場合true
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'はい',
    String cancelText = 'キャンセル',
  }) async {
    if (!context.mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// 情報ダイアログを表示
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    String okText = 'OK',
  }) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(okText),
          ),
        ],
      ),
    );
  }

  /// ローディングダイアログを表示
  static void showLoadingDialog(
    BuildContext context, {
    String message = '処理中...',
  }) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// ローディングダイアログを閉じる
  static void hideLoadingDialog(BuildContext context) {
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  /// QRコードスキャンダイアログを表示
  static void showQrCodeScanDialog(
    BuildContext context,
    VoidCallback onScan,
  ) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコード招待'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'グループ招待QRコードをスキャンして\nグループに参加できます',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onScan();
              },
              child: const Text('QRコードをスキャン'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// 開発中機能のダイアログを表示
  static void showComingSoonDialog(
    BuildContext context, {
    String feature = '機能',
  }) {
    showInfoDialog(
      context,
      title: '開発中',
      message: '$featureは開発中です。\n近日中に実装予定です。',
    );
  }

  /// アバウトダイアログを表示
  static void showAboutDialog(
    BuildContext context, {
    required String appName,
    required String version,
    String? description,
    Widget? applicationIcon,
  }) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (applicationIcon != null) ...[
              applicationIcon,
              const SizedBox(width: 12),
            ],
            Text(appName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('バージョン: $version'),
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// スナックバーでログを表示（デバッグ用）
  static void showDebugLog(
    BuildContext context,
    String log, {
    bool alsoLogToConsole = true,
  }) {
    if (alsoLogToConsole) {
      _logger.d(log);
    }
    
    showInfoMessage(context, log);
  }
}
