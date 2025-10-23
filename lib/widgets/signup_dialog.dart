// lib/widgets/signup_dialog.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'signup_processing_widget.dart';

/// サインアップ処理を表示するダイアログ
class SignupDialog extends StatelessWidget {
  final User user;
  final String? displayName;
  final VoidCallback? onCompleted;

  const SignupDialog({
    super.key,
    required this.user,
    this.displayName,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SignupProcessingWidget(
        user: user,
        displayName: displayName,
        onCompleted: () {
          Navigator.of(context).pop(true);
          onCompleted?.call();
        },
        onError: (error) {
          Navigator.of(context).pop(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('サインアップ処理エラー: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      ),
    );
  }
}

/// サインアップダイアログを表示する関数
Future<bool?> showSignupDialog({
  required BuildContext context,
  required User user,
  String? displayName,
  VoidCallback? onCompleted,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // 処理中はダイアログを閉じれない
    builder: (context) => SignupDialog(
      user: user,
      displayName: displayName,
      onCompleted: onCompleted,
    ),
  );
}
