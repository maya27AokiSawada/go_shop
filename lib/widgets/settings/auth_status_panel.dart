import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 認証状態を表示するパネルウィジェット
class AuthStatusPanel extends StatelessWidget {
  final User? user;

  const AuthStatusPanel({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = user != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAuthenticated ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAuthenticated ? Colors.green.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAuthenticated ? Icons.check_circle : Icons.account_circle,
            color: isAuthenticated ? Colors.green : Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAuthenticated ? 'ログイン済み: ${user!.email}' : '未ログイン状態',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isAuthenticated
                    ? Colors.green.shade800
                    : Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
