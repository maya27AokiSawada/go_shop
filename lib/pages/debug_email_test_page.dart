import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import '../utils/app_logger.dart';
import '../firebase_options.dart';
import '../helper/firebase_diagnostics.dart';



class DebugEmailTestPage extends StatefulWidget {
  const DebugEmailTestPage({super.key});

  @override
  State<DebugEmailTestPage> createState() => _DebugEmailTestPageState();
}

class _DebugEmailTestPageState extends State<DebugEmailTestPage> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController(text: 'Go Shop テストメール');
  final _messageController = TextEditingController(
    text: 'これはGo Shopからのテストメールです。',
  );
  bool _isSending = false;
  String? _lastDocId;
  String? _errorMessage;
  bool _isFirebaseInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    if (_isFirebaseInitialized || _isInitializing) return;
    
    setState(() {
      _isInitializing = true;
    });

    try {
      // Firebaseがすでに初期化されているかチェック
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      setState(() {
        _isFirebaseInitialized = true;
      });
      
      // デフォルトで現在のユーザーのメールアドレスを設定
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email != null) {
        _toController.text = currentUser!.email!;
      }
    } catch (e) {
      // すでに初期化されている場合
      if (e.toString().contains('duplicate-app')) {
        setState(() {
          _isFirebaseInitialized = true;
        });
        
        // デフォルトで現在のユーザーのメールアドレスを設定
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser?.email != null) {
          _toController.text = currentUser!.email!;
        }
      } else {
        setState(() {
          _errorMessage = 'Firebase初期化エラー: $e';
        });
      }
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _runFirebaseDiagnostics() async {
    try {
      final results = await FirebaseDiagnostics.runDiagnostics();
      
      if (!mounted) return;

      // 結果をダイアログで表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔍 Firebase診断結果'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDiagnosticResult(
                  'Auth接続',
                  results['auth_status'] == true,
                ),
                if (results['user_email'] != null && results['user_email'] != 'No user')
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: Text(
                      'ユーザー: ${results['user_email']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (results['user_uid'] != null && results['user_uid'] != 'No UID')
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: Text(
                      'UID: ${results['user_uid']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const Divider(),
                _buildDiagnosticResult(
                  'Firestore接続',
                  results['firestore_connection'] == true,
                ),
                if (results['firestore_latency_ms'] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: Text(
                      'レイテンシ: ${results['firestore_latency_ms']}ms',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (results['firestore_error'] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: Text(
                      'エラー: ${results['firestore_error']}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                const Divider(),
                if (results['auth_status'] == true) ...[
                  _buildDiagnosticResult(
                    'Firestore書き込み',
                    results['firestore_write'] == true,
                  ),
                  if (results['firestore_write_error'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                      child: Text(
                        'エラー: ${results['firestore_write_error']}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  const Divider(),
                ],
                const Text(
                  '診断情報:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'タイムスタンプ: ${results['timestamp'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (results['general_error'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '一般エラー: ${results['general_error']}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('診断実行エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDiagnosticResult(String label, bool success) {
    return Row(
      children: [
        Icon(
          success ? Icons.check_circle : Icons.error,
          color: success ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: success ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendTestEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _lastDocId = null;
    });

    try {
      Log.debug('📧 メール送信開始: ${_toController.text.trim()}');
      
      // mailコレクションにドキュメントを追加
      Log.debug('📝 Firestoreドキュメント作成中...');
      final docRef = await FirebaseFirestore.instance.collection('mail').add({
        'to': _toController.text.trim(),
        'message': {
          'subject': _subjectController.text,
          'text': _messageController.text,
          'html': '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .header { background-color: #FF9800; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .footer { background-color: #f5f5f5; padding: 10px; text-align: center; font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🛒 Go Shop</h1>
  </div>
  <div class="content">
    <p>${_messageController.text}</p>
    <p>このメールは、Go Shopのメール送信機能のテストです。</p>
    <p>送信日時: ${DateTime.now().toIso8601String()}</p>
  </div>
  <div class="footer">
    <p>© 2025 Go Shop - 家族で買い物リストを共有</p>
  </div>
</body>
</html>
          ''',
        },
      });

      Log.debug('✅ Firestoreドキュメント作成完了: ${docRef.id}');
      Log.debug('📮 Extension処理待ち... (数秒かかる場合があります)');

      setState(() {
        _lastDocId = docRef.id;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ メール送信リクエストを作成しました\nDocument ID: ${docRef.id}\n\n配送ステータスボタンで確認できます'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      
      // 5秒後に自動でステータスチェック
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        Log.debug('🔍 自動ステータスチェック開始');
        await _checkDeliveryStatus();
      }
    } catch (e, stackTrace) {
      Log.error('❌ メール送信エラー: $e');
      Log.error('スタックトレース: $stackTrace');
      
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ エラー: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _checkDeliveryStatus() async {
    if (_lastDocId == null) {
      Log.warning('⚠️ チェック対象のドキュメントIDがありません');
      return;
    }

    try {
      Log.debug('🔍 配送ステータス確認開始: $_lastDocId');
      
      final doc = await FirebaseFirestore.instance
          .collection('mail')
          .doc(_lastDocId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        Log.warning('⚠️ ドキュメントが存在しません: $_lastDocId');
        Log.warning('   Extensionによって既に削除された可能性があります');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ ドキュメントが見つかりません\n\nExtensionによって処理され削除された可能性があります\n（成功した場合、TTL設定により削除されます）'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 8),
          ),
        );
        return;
      }

      final data = doc.data()!;
      Log.debug('📄 ドキュメントデータ: ${data.keys.toList()}');
      
      final delivery = data['delivery'] as Map<String, dynamic>?;

      String statusMessage;
      Color statusColor;

      if (delivery == null) {
        Log.debug('⏳ 配送情報なし - Extension処理待ち');
        statusMessage = '⏳ 配送ステータス: 処理待ち\n\nExtensionがまだドキュメントを処理していません。\n数秒待ってから再確認してください。';
        statusColor = Colors.orange;
      } else {
        final state = delivery['state'] as String?;
        final startTime = delivery['startTime'];
        final endTime = delivery['endTime'];
        final attempts = delivery['attempts'] ?? 0;
        final error = delivery['error'];
        final info = delivery['info'] as Map<String, dynamic>?;

        Log.debug('📊 配送状態: $state');
        Log.debug('📊 試行回数: $attempts');
        if (error != null) {
          Log.error('❌ エラー: $error');
        }

        statusMessage = '📮 配送ステータス: ${state ?? "不明"}\n\n';
        statusMessage += '🕐 開始時刻: ${startTime ?? "N/A"}\n';
        statusMessage += '🕐 終了時刻: ${endTime ?? "N/A"}\n';
        statusMessage += '🔄 試行回数: $attempts\n';

        if (state == 'SUCCESS') {
          statusColor = Colors.green;
          statusMessage += '\n✅ メール送信成功！';
        } else if (state == 'ERROR' || state == 'REJECTED') {
          statusColor = Colors.red;
          statusMessage += '\n❌ メール送信失敗';
        } else {
          statusColor = Colors.orange;
        }

        if (error != null) {
          if (error is String) {
            statusMessage += '\n\n❌ エラー詳細:\n$error';
          } else if (error is Map) {
            statusMessage += '\n\n❌ エラー詳細:';
            error.forEach((key, value) {
              statusMessage += '\n  • $key: $value';
            });
          }
        }

        if (info != null) {
          statusMessage += '\n\nℹ️ 追加情報:';
          info.forEach((key, value) {
            statusMessage += '\n  • $key: $value';
          });
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                delivery == null ? Icons.hourglass_empty : 
                (delivery['state'] == 'SUCCESS' ? Icons.check_circle : 
                (delivery['state'] == 'ERROR' || delivery['state'] == 'REJECTED' ? Icons.error : Icons.info)),
                color: statusColor,
              ),
              const SizedBox(width: 8),
              const Text('配送ステータス'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(statusMessage),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
            if (delivery == null || (delivery['state'] != 'SUCCESS'))
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkDeliveryStatus();
                },
                child: const Text('再確認'),
              ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      Log.error('❌ ステータス確認エラー: $e');
      Log.error('スタックトレース: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ エラー: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メール送信テスト'),
        backgroundColor: Colors.orange,
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Firebase初期化中...'),
                ],
              ),
            )
          : !_isFirebaseInitialized
              ? Center(
                  child: Card(
                    margin: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Firebase初期化エラー',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ?? '不明なエラー',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializeFirebase,
                            child: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Firebase診断セクション
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🔍 Firebase診断',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _runFirebaseDiagnostics,
                                  icon: const Icon(Icons.bug_report),
                                  label: const Text('Firebase診断を実行'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // メール送信セクション
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📧 テストメール送信',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Firebase Extension (Trigger Email) のテスト送信です。',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: '送信先メールアドレス',
                  hintText: 'example@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'メールアドレスを入力してください';
                  }
                  if (!value.contains('@')) {
                    return '有効なメールアドレスを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: '件名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '件名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'メッセージ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'メッセージを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSending ? null : _sendTestEmail,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? '送信中...' : 'テストメールを送信'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              if (_lastDocId != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _checkDeliveryStatus,
                  icon: const Icon(Icons.info),
                  label: const Text('配送ステータスを確認'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
              if (_lastDocId != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ 送信リクエスト作成済み',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Document ID: $_lastDocId'),
                        const SizedBox(height: 8),
                        const Text(
                          'Firebase Console → Firestore → mail コレクションで配送状態を確認できます。',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '❌ エラーが発生しました',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_errorMessage!),
                      ],
                    ),
                  ),
                ),
              ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
