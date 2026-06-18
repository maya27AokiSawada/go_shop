// lib/widgets/email_test_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/email_test_service.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';

class EmailTestButton extends ConsumerStatefulWidget {
  const EmailTestButton({super.key});

  @override
  ConsumerState<EmailTestButton> createState() => _EmailTestButtonState();
}

class _EmailTestButtonState extends ConsumerState<EmailTestButton> {
  bool _isLoading = false;
  String? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendTestEmail,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.email_outlined),
          label: const Text('メール送信テスト'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
        if (_lastResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _lastResult!.contains('成功')
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      _lastResult!.contains('成功') ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                _lastResult!,
                style: TextStyle(
                  fontSize: 12,
                  color: _lastResult!.contains('成功')
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _sendTestEmail() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final emailTestService = ref.read(emailTestServiceProvider);

      final testEmail = dotenv.env['TEST_EMAIL_RECIPIENT']?.trim();
      if (testEmail == null || testEmail.isEmpty) {
        throw StateError('TEST_EMAIL_RECIPIENT is not configured in .env');
      }

      Log.info('🧪 メール送信テスト開始');
      Log.info('   対象: ${Log.maskEmail(testEmail)}');

      final success = await emailTestService.sendTestEmail(
        testEmail: testEmail,
        customSubject:
            'GoShopping メール送信機能テスト - ${DateTime.now().toString().substring(0, 19)}',
        customBody: '''
GoShopping メール送信機能のテストです。

テスト実行日時: ${DateTime.now().toString()}
送信先: $testEmail
送信方式: Firebase Extensions Trigger Email

  このメールが届いていれば、メール送信機能は正常に動作しています。

【システム情報】
- アプリ: Go Shop
- 環境: Development/Test
- 送信方式: Firebase Extensions + フォールバック

Go Shop 開発チーム
        ''',
      );

      if (mounted) {
        setState(() {
          _lastResult = success
              ? '✅ テストメール送信成功\n宛先: $testEmail'
              : '❌ テストメール送信失敗\n詳細はログを確認してください';
        });

        // スナックバーでも結果を表示
        if (success) {
          SnackBarHelper.showSuccess(context, 'テストメール送信完了');
        } else {
          SnackBarHelper.showError(context, 'メール送信に失敗しました');
        }
      }
    } catch (e) {
      Log.error('❌ テストメール送信エラー: $e', e);

      if (mounted) {
        setState(() {
          _lastResult = '❌ エラー発生: ${e.toString()}';
        });

        SnackBarHelper.showCustom(
          context,
          message: 'エラー: ${e.toString()}',
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// 診断情報表示用のウィジェット
class EmailDiagnosticsWidget extends ConsumerStatefulWidget {
  const EmailDiagnosticsWidget({super.key});

  @override
  ConsumerState<EmailDiagnosticsWidget> createState() =>
      _EmailDiagnosticsWidgetState();
}

class _EmailDiagnosticsWidgetState
    extends ConsumerState<EmailDiagnosticsWidget> {
  Map<String, dynamic>? _diagnostics;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runDiagnostics,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.healing),
          label: const Text('メール設定診断'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        if (_diagnostics != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 診断結果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ..._diagnostics!.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            entry.value is bool && entry.value == true
                                ? Icons.check_circle
                                : Icons.error,
                            color: entry.value is bool && entry.value == true
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _diagnostics = null;
    });

    try {
      final emailTestService = ref.read(emailTestServiceProvider);
      final diagnostics = await emailTestService.diagnoseEmailSettings();

      if (mounted) {
        setState(() {
          _diagnostics = diagnostics;
        });
      }
    } catch (e) {
      Log.error('❌ 診断実行エラー: $e', e);

      if (mounted) {
        setState(() {
          _diagnostics = {
            'error': e.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
