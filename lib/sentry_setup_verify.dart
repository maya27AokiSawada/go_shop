import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sentry初期化
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://9aa7459e94ab157f830e81c9f1a585b3@o4510820521738240.ingest.us.sentry.io/4510820522786816';
      options.debug = true; // デバッグモードで詳細ログ出力
      options.environment = 'test';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const SentrySetupVerifyApp()),
  );
}

class SentrySetupVerifyApp extends StatelessWidget {
  const SentrySetupVerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentry Setup Verification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SentryTestPage(),
    );
  }
}

class SentryTestPage extends StatelessWidget {
  const SentryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentry動作確認'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sentryクラッシュレポートテスト',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // テストエラーを送信
                throw StateError(
                    'This is a test exception for Sentry verification');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text(
                'Sentryエラーを送信',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // キャッチ可能なエラーを送信
                try {
                  throw Exception('Caught test exception');
                } catch (e, stackTrace) {
                  await Sentry.captureException(
                    e,
                    stackTrace: stackTrace,
                    hint: Hint.withMap({
                      'test_type': 'manual_capture',
                      'timestamp': DateTime.now().toIso8601String(),
                    }),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('エラーをSentryに送信しました！'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text(
                'キャッチ済みエラーを送信',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                '※ エラー送信後、Sentryダッシュボードで\nレポートを確認してください',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
