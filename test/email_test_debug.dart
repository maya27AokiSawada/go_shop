// test/email_test_debug.dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goshopping/services/email_test_service.dart';
import 'package:goshopping/widgets/email_test_button.dart';
import 'package:goshopping/utils/app_logger.dart';

void main() {
  runApp(const ProviderScope(child: EmailTestDebugApp()));
}

class EmailTestDebugApp extends StatelessWidget {
  const EmailTestDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Shop Email Test Debug',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const EmailTestDebugPage(),
    );
  }
}

class EmailTestDebugPage extends ConsumerStatefulWidget {
  const EmailTestDebugPage({super.key});

  @override
  ConsumerState<EmailTestDebugPage> createState() => _EmailTestDebugPageState();
}

class _EmailTestDebugPageState extends ConsumerState<EmailTestDebugPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Shop Email Test Debug'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📧 メール送信テスト デバッグ画面',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Firebase Extensions Trigger Email の動作確認',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              '宛先: support@example.com',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 30),

            // メール送信テストボタン
            EmailTestButton(),

            SizedBox(height: 30),

            // 診断ウィジェット
            EmailDiagnosticsWidget(),

            SizedBox(height: 30),

            // 手動テストボタン
            ManualEmailTestWidget(),
          ],
        ),
      ),
    );
  }
}

class ManualEmailTestWidget extends ConsumerStatefulWidget {
  const ManualEmailTestWidget({super.key});

  @override
  ConsumerState<ManualEmailTestWidget> createState() =>
      _ManualEmailTestWidgetState();
}

class _ManualEmailTestWidgetState extends ConsumerState<ManualEmailTestWidget> {
  bool _isLoading = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔧 手動テスト',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runManualTest,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bug_report),
          label: const Text('手動デバッグテスト実行'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _result!,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _runManualTest() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      AppLogger.info('🧪 手動デバッグテスト開始');

      final emailTestService = ref.read(emailTestServiceProvider);

      // 1. サービス初期化確認
      AppLogger.success('✅ EmailTestService 初期化成功');

      // 2. 診断実行
      AppLogger.info('🔍 メール設定診断開始...');
      final diagnostics = await emailTestService.diagnoseEmailSettings();
      AppLogger.info('📊 診断結果: $diagnostics');

      // 3. テストメール送信
      AppLogger.info('📧 テストメール送信開始...');
      final success = await emailTestService.sendTestEmail(
        testEmail: 'support@example.com',
        customSubject:
            'Go Shop デバッグテスト - ${DateTime.now().toString().substring(0, 19)}',
        customBody: '''
Go Shop デバッグテストメールです。

実行日時: ${DateTime.now()}
テストモード: 手動デバッグ
ブランチ: test
宛先: support@example.com

このメールは開発・テスト用に送信されています。

Go Shop開発チーム
        ''',
      );

      final resultText = '''
🧪 手動デバッグテスト結果

📊 診断結果:
${diagnostics.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}

📧 メール送信: ${success ? '✅ 成功' : '❌ 失敗'}

実行時刻: ${DateTime.now().toString()}
      ''';

      setState(() {
        _result = resultText;
      });

      AppLogger.success('🎊 手動デバッグテスト完了');
    } catch (e) {
      AppLogger.error('❌ 手動デバッグテストエラー: $e');
      setState(() {
        _result = '❌ エラー発生: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
