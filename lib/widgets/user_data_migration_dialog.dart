import 'package:flutter/material.dart';

/// ユーザー切り替え時のデータ引き継ぎ選択ダイアログ
class UserDataMigrationDialog extends StatelessWidget {
  final String previousUser;
  final String newUser;
  final VoidCallback onKeepData;
  final VoidCallback onClearData;

  const UserDataMigrationDialog({
    super.key,
    required this.previousUser,
    required this.newUser,
    required this.onKeepData,
    required this.onClearData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ユーザー変更を検知'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('異なるユーザーでログインしました。',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('前回: $previousUser'),
          Text('今回: $newUser'),
          const SizedBox(height: 16),
          const Text('以前のデータをどうしますか？'),
          const SizedBox(height: 8),
          const Text(
            '• 引き継ぐ: 既存のグループとショッピングリストが新しいユーザーに移行されます\n'
            '• 消去: 新しいユーザー用に空の状態から開始します',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onClearData,
          child: const Text('消去'),
        ),
        TextButton(
          onPressed: onKeepData,
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('引き継ぐ'),
        ),
      ],
    );
  }

  /// ダイアログを表示してユーザーの選択を取得
  static Future<bool?> show(
    BuildContext context, {
    required String previousUser,
    required String newUser,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserDataMigrationDialog(
        previousUser: previousUser,
        newUser: newUser,
        onKeepData: () => Navigator.of(context).pop(true),
        onClearData: () => Navigator.of(context).pop(false),
      ),
    );
  }
}
