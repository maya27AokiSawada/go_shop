import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/datastore/hive_purchase_group_repository.dart';
import 'lib/flavors.dart';
import 'lib/main.dart';
import 'lib/utils/app_logger.dart';

/// Firestore→Hive同期問題のデバッグスクリプト
///
/// 実行方法:
/// flutter run -t debug_sync_issue.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 本番環境に設定
  F.appFlavor = Flavor.prod;

  // Hive初期化（main.dartと同じ）
  await initializeHive();

  runApp(const DebugSyncApp());
}

class DebugSyncApp extends StatelessWidget {
  const DebugSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Sync Debug',
      home: DebugSyncPage(),
    );
  }
}

class DebugSyncPage extends StatefulWidget {
  const DebugSyncPage({super.key});

  @override
  State<DebugSyncPage> createState() => _DebugSyncPageState();
}

class _DebugSyncPageState extends State<DebugSyncPage> {
  String _log = '';
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    AppLogger.info(message);
  }

  Future<void> _runDebug() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _log = '';
    });

    try {
      _addLog('=== デバッグ開始 ===');

      // 1. ユーザー認証状態確認
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addLog('❌ ユーザーがサインインしていません');
        return;
      }

      _addLog('✅ ユーザー認証OK');
      _addLog('   - UID: ${user.uid}');
      _addLog('   - Email: ${user.email}');

      // 2. Firestoreクエリ実行
      _addLog('\n--- Firestoreクエリ実行 ---');
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('SharedGroups')
          .where('allowedUid', arrayContains: user.uid)
          .get();

      _addLog('📊 クエリ結果: ${snapshot.docs.length}個のドキュメント');

      if (snapshot.docs.isEmpty) {
        _addLog('⚠️ Firestoreにグループがありません');

        // コレクション全体を確認
        _addLog('\n--- 全SharedGroupsを確認 ---');
        final allSnapshot = await firestore.collection('SharedGroups').get();
        _addLog('全体: ${allSnapshot.docs.length}個のドキュメント');

        for (final doc in allSnapshot.docs) {
          final data = doc.data();
          _addLog('  - ID: ${doc.id}');
          _addLog('    groupName: ${data['groupName']}');
          _addLog('    allowedUid: ${data['allowedUid']}');
        }
        return;
      }

      // 3. Firestoreデータ詳細表示
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _addLog('\n📄 グループ詳細: ${doc.id}');
        _addLog('   - groupName: ${data['groupName']}');
        _addLog('   - ownerUid: ${data['ownerUid']}');
        _addLog('   - allowedUid: ${data['allowedUid']}');
        _addLog('   - isDeleted: ${data['isDeleted'] ?? false}');
      }

      // 4. Hive確認（保存前）
      _addLog('\n--- Hive確認（保存前） ---');
      // TODO: HiveSharedGroupRepositoryのインスタンス取得が必要
      // 現在のところ、Riverpodなしでは取得困難
      _addLog('⚠️ HiveリポジトリはRiverpod依存のため、直接確認できません');
      _addLog('   設定ページの「グループ状態確認」ボタンで確認してください');

      // 5. Hiveへの書き込みテスト
      _addLog('\n--- Hiveへの書き込みテスト ---');
      _addLog('⚠️ 実際の書き込みは user_initialization_service.dart で実行されます');
      _addLog('   syncFromFirestoreToHive() を確認してください');

      _addLog('\n=== デバッグ完了 ===');
    } catch (e, stack) {
      _addLog('\n❌ エラー発生: $e');
      _addLog('Stack trace:\n$stack');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Debug'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isRunning ? null : _runDebug,
              child: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('デバッグ実行'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _log.isEmpty ? '上のボタンを押してデバッグを開始' : _log,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
