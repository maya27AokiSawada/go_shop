import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

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
      title: Text(texts.userChangedDetected),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.differentUserLoggedIn,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(texts.userPrevious(previousUser)),
          Text(texts.userCurrent(newUser)),
          const SizedBox(height: 16),
          Text(texts.whatToDoWithOldData),
          const SizedBox(height: 8),
          Text(
            texts.dataMigrationDescription,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onClearData,
          child: Text(texts.clearData),
        ),
        TextButton(
          onPressed: onKeepData,
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(texts.keepData),
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
