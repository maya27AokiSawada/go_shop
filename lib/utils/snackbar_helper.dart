import 'package:flutter/material.dart';

/// SnackBar表示の共通ヘルパークラス
///
/// 30箇所以上で重複していたSnackBar表示コードを統一。
/// context.mountedチェックを内蔵し、安全な表示を保証。
class SnackBarHelper {
  /// 成功メッセージを表示（緑背景）
  ///
  /// 使用例：
  /// ```dart
  /// SnackBarHelper.showSuccess(context, 'グループを作成しました');
  /// ```
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// エラーメッセージを表示（赤背景）
  ///
  /// 使用例：
  /// ```dart
  /// SnackBarHelper.showError(context, 'グループ作成に失敗しました');
  /// ```
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 情報メッセージを表示（デフォルト背景）
  ///
  /// 使用例：
  /// ```dart
  /// SnackBarHelper.showInfo(context, 'リスト名を入力してください');
  /// ```
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 警告メッセージを表示（オレンジ背景）
  ///
  /// 使用例：
  /// ```dart
  /// SnackBarHelper.showWarning(context, 'ネットワーク接続が不安定です');
  /// ```
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// カスタムSnackBarを表示
  ///
  /// アイコン付きやアクション付きなど、より高度なカスタマイズが必要な場合に使用。
  ///
  /// 使用例：
  /// ```dart
  /// SnackBarHelper.showCustom(
  ///   context,
  ///   message: '削除しました',
  ///   icon: Icons.delete,
  ///   action: SnackBarAction(
  ///     label: '元に戻す',
  ///     onPressed: () { /* undo logic */ },
  ///   ),
  /// );
  /// ```
  static void showCustom(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }
}
