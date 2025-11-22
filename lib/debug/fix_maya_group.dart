import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/purchase_group.dart';
import '../utils/app_logger.dart';

/// mayaのデフォルトグループを修正するデバッグ画面
class FixMayaGroupScreen extends ConsumerStatefulWidget {
  const FixMayaGroupScreen({super.key});

  @override
  ConsumerState<FixMayaGroupScreen> createState() => _FixMayaGroupScreenState();
}

class _FixMayaGroupScreenState extends ConsumerState<FixMayaGroupScreen> {
  String _log = '';
  bool _isProcessing = false;

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    Log.info(message);
  }

  Future<void> _fixMayaGroup() async {
    setState(() {
      _isProcessing = true;
      _log = '';
    });

    try {
      _addLog('===== mayaグループ修正開始 =====');

      // Hive Boxを開く
      final box = await Hive.openBox<PurchaseGroup>('purchase_groups');
      _addLog('Hive Box opened: ${box.length} groups');

      // 全グループをチェック
      for (var i = 0; i < box.length; i++) {
        final group = box.getAt(i);
        if (group == null) continue;

        _addLog('\n--- グループ ${i + 1} ---');
        _addLog('名前: ${group.groupName}');
        _addLog('groupId: ${group.groupId}');
        _addLog('syncStatus: ${group.syncStatus}');

        if (group.members != null && group.members!.isNotEmpty) {
          final owner = group.members!.first;
          _addLog('オーナー: ${owner.name}');
          _addLog('memberId: ${owner.memberId}');

          // 修正が必要なグループを検出
          final needsFix =
              owner.memberId == '831f3be8-0daf-43da-98e4-1bda6d55621c' ||
                  group.groupId == 'default_group' ||
                  (group.groupName.contains('maya') &&
                      group.groupId != 'VqNEozvTyXXw55Q46mNiGNMNngw2');

          if (needsFix) {
            _addLog('\n⚠️ 修正が必要です！');

            // 正しいデータで修正
            final correctedMember = owner.copyWith(
              memberId: 'VqNEozvTyXXw55Q46mNiGNMNngw2',
            );

            final correctedMembers = [
              correctedMember,
              ...group.members!.skip(1),
            ];

            final correctedGroup = group.copyWith(
              groupId: 'VqNEozvTyXXw55Q46mNiGNMNngw2',
              members: correctedMembers,
              syncStatus: SyncStatus.synced,
            );

            await box.putAt(i, correctedGroup);

            _addLog('✅ 修正完了:');
            _addLog('  新groupId: VqNEozvTyXXw55Q46mNiGNMNngw2');
            _addLog('  新memberId: VqNEozvTyXXw55Q46mNiGNMNngw2');
            _addLog('  新syncStatus: synced');
          }
        }
      }

      await box.close();

      _addLog('\n===== 修正完了 =====');
      _addLog('アプリを再起動してFirestoreに同期してください');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('修正完了！アプリを再起動してください'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      _addLog('\n❌ エラー発生: $e');
      _addLog('スタックトレース: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mayaグループ修正'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '問題:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'memberIdが誤っている: 831f3be8-0daf-43da-98e4-1bda6d55621c\n'
                  '正しいFirebase UID: VqNEozvTyXXw55Q46mNiGNMNngw2',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _fixMayaGroup,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('修正を実行'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _log,
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
