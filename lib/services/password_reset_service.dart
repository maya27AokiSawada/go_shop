// lib/services/password_reset_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';

/// パスワードリセット処理を管理するサービス
class PasswordResetService {
  /// パスワードリセットメールを送信
  ///
  /// Returns: (success, errorMessage)
  Future<PasswordResetResult> sendPasswordResetEmail(String email) async {
    // バリデーション
    if (email.isEmpty) {
      return PasswordResetResult(
        success: false,
        message: 'パスワードリセットにはメールアドレスが必要です',
        severity: MessageSeverity.warning,
      );
    }

    if (!email.contains('@')) {
      return PasswordResetResult(
        success: false,
        message: '有効なメールアドレスを入力してください',
        severity: MessageSeverity.error,
      );
    }

    try {
      // Firebase Auth パスワードリセット {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      } else {
        // Dev環境では模擬処理
        await Future.delayed(const Duration(seconds: 1));
        Log.info('🔄 Dev環境: パスワードリセットメール送信模擬完了');
      }

      return PasswordResetResult(
        success: true,
        message: 'パスワードリセットメールを $email に送信しました',
        severity: MessageSeverity.success,
      );
    } catch (e) {
      Log.error('❌ パスワードリセット送信エラー: $e');

      String errorMessage = 'パスワードリセットに失敗しました';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'このメールアドレスは登録されていません';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'メールアドレスの形式が正しくありません';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'リクエストが多すぎます。しばらく待ってから再試行してください';
      }

      return PasswordResetResult(
        success: false,
        message: errorMessage,
        severity: MessageSeverity.error,
      );
    }
  }

  /// パスワードリセットが可能かチェック
  bool canResetPassword(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  /// メールアドレスのバリデーション
  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!email.contains('@')) {
      return '有効なメールアドレスを入力してください';
    }
    return null;
  }
}

/// パスワードリセット結果
class PasswordResetResult {
  final bool success;
  final String message;
  final MessageSeverity severity;

  PasswordResetResult({
    required this.success,
    required this.message,
    required this.severity,
  });
}

/// メッセージの重要度
enum MessageSeverity {
  success,
  warning,
  error,
}
