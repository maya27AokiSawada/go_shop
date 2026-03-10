import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../providers/shared_group_provider.dart';
import '../providers/shared_list_provider.dart';
import '../widgets/sync_status_widget.dart';
import '../models/shared_group.dart';
import '../models/shared_list.dart';
import '../flavors.dart';

/// ハイブリッド同期システムのテストページ
class HybridSyncTestPage extends ConsumerStatefulWidget {
  const HybridSyncTestPage({super.key});

  @override
  ConsumerState<HybridSyncTestPage> createState() => _HybridSyncTestPageState();
}

class _HybridSyncTestPageState extends ConsumerState<HybridSyncTestPage> {
  final _testGroupNameController = TextEditingController();

  @override
  void dispose() {
    _testGroupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allGroupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 ハイブリッド同期テスト'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: SyncStatusWidget(showLabel: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 環境情報
            _buildEnvironmentInfo(),
            const SizedBox(height: 16),

            // 同期管理
            const SyncManagementWidget(),
            const SizedBox(height: 16),

            // テスト機能
            _buildTestFeatures(),
            const SizedBox(height: 16),

            // グループ一覧
            _buildGroupsList(allGroupsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentInfo() {
    final hybridRepo = ref.read(hybridRepositoryProvider);

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  '環境情報',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                'フレーバー', F.appFlavor?.name.toUpperCase() ?? 'UNKNOWN'),
            _buildInfoRow('リポジトリ', hybridRepo != null ? 'ハイブリッド' : 'Hiveのみ'),
            if (hybridRepo != null) ...[
              _buildInfoRow(
                  'オンライン状態', hybridRepo.isOnline ? '🟢 接続中' : '🔴 オフライン'),
              _buildInfoRow('同期状態', hybridRepo.isSyncing ? '🔄 同期中' : '✅ 待機中'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTestFeatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science),
                SizedBox(width: 8),
                Text(
                  'テスト機能',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // テストグループ作成
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _testGroupNameController,
                    decoration: const InputDecoration(
                      labelText: 'テストグループ名',
                      border: OutlineInputBorder(),
                      hintText: 'テスト用グループを作成',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _createTestGroup,
                  icon: const Icon(Icons.add),
                  label: const Text('作成'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // テストボタン群
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testCacheSpeed,
                  icon: const Icon(Icons.speed),
                  label: const Text('キャッシュ速度'),
                ),
                ElevatedButton.icon(
                  onPressed: _testOfflineMode,
                  icon: const Icon(Icons.cloud_off),
                  label: const Text('オフラインモード'),
                ),
                ElevatedButton.icon(
                  onPressed: _testConflictResolution,
                  icon: const Icon(Icons.merge),
                  label: const Text('競合解決'),
                ),
                ElevatedButton.icon(
                  onPressed: _testFirestoreConnection,
                  icon: const Icon(Icons.cloud),
                  label: const Text('Firestore接続'),
                ),
                ElevatedButton.icon(
                  onPressed: _checkFirestoreData,
                  icon: const Icon(Icons.storage),
                  label: const Text('Firestoreデータ'),
                ),
                ElevatedButton.icon(
                  onPressed: _detailedDataCheck,
                  icon: const Icon(Icons.search),
                  label: const Text('詳細データ確認'),
                ),
                ElevatedButton.icon(
                  onPressed: _addTestMembers,
                  icon: const Icon(Icons.people),
                  label: const Text('メンバー追加'),
                ),
                ElevatedButton.icon(
                  onPressed: _testSharedListSync,
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('買い物リスト同期'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(AsyncValue<List<SharedGroup>> allGroupsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group),
                const SizedBox(width: 8),
                const Text(
                  'グループ一覧',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ref.invalidate(allGroupsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: '更新',
                ),
              ],
            ),
            const SizedBox(height: 12),
            allGroupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('グループがありません'),
                    ),
                  );
                }

                return Column(
                  children: groups
                      .map((group) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  group.groupName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: Colors.blue[700]),
                                ),
                              ),
                              title: Text(group.groupName),
                              subtitle: Text(
                                '${(group.members?.isNotEmpty ?? false) ? group.members!.length : 0}メンバー • ${group.groupId}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (group.groupName.startsWith('テスト'))
                                    IconButton(
                                      onPressed: () => _deleteTestGroup(group),
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: '削除',
                                    ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () => _showGroupDetails(group),
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text('エラー: $error'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(allGroupsProvider),
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // テスト機能の実装
  // =================================================================

  void _createTestGroup() async {
    final name = _testGroupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('グループ名を入力してください')),
      );
      return;
    }

    try {
      final notifier = ref.read(allGroupsProvider.notifier);
      await notifier.createNewGroup('テスト$name');

      _testGroupNameController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('テストグループ「$name」を作成しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  void _testCacheSpeed() async {
    final stopwatch = Stopwatch()..start();

    try {
      await ref.read(allGroupsProvider.future);
      stopwatch.stop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('キャッシュ読み取り: ${stopwatch.elapsedMilliseconds}ms'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('速度テストエラー: $e')),
        );
      }
    }
  }

  void _testOfflineMode() {
    final hybridRepo = ref.read(hybridRepositoryProvider);
    if (hybridRepo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ハイブリッドモードではありません')),
      );
      return;
    }

    hybridRepo.setOnlineStatus(!hybridRepo.isOnline);
    ref.invalidate(syncStatusProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hybridRepo.isOnline ? 'オンラインモードに切り替えました' : 'オフラインモードに切り替えました',
        ),
      ),
    );
  }

  void _testConflictResolution() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('競合解決テスト（未実装）')),
    );
  }

  void _testFirestoreConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Firestore接続をテスト中...')),
    );

    try {
      // Firebase初期化状態を確認
      final firebase = Firebase.apps;
      if (firebase.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Firebaseが初期化されていません'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Firestore接続テスト
      final firestore = FirebaseFirestore.instance;

      // テスト用ドキュメントの読み書き
      final testDoc = firestore.collection('connection_test').doc('test');

      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
        'platform': 'windows',
        'user': 'test_user'
      });

      final doc = await testDoc.get();

      if (doc.exists) {
        // テストドキュメントを削除
        await testDoc.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Firestore接続成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Firestoreデータ読み取りに失敗'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Firestore接続エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkFirestoreData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Firestoreデータをチェック中...')),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // SharedGroupsコレクションの確認
      final groupsSnapshot = await firestore.collection('SharedGroups').get();

      if (groupsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📭 Firestoreにグループデータがありません'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final groupCount = groupsSnapshot.docs.length;
        final groupNames = groupsSnapshot.docs
            .map((doc) => doc.data()['groupName'] ?? 'Unknown')
            .take(3)
            .join(', ');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📊 Firestore: $groupCountグループ (例: $groupNames)'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );

        // 詳細ログ出力
        for (final doc in groupsSnapshot.docs) {
          final data = doc.data();
          Log.info(
              '🔥 Firestore Group: ${doc.id} - ${data['groupName']} (${data['members']?.length ?? 0} members)');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Firestoreデータ確認エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _detailedDataCheck() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('詳細データ確認を実行中...')),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // Hiveデータの確認
      final localGroups = await ref.read(allGroupsProvider.future);

      // Firestoreデータの確認
      final groupsSnapshot = await firestore.collection('SharedGroups').get();

      // 比較結果
      final localCount = localGroups.length;
      final firestoreCount = groupsSnapshot.docs.length;

      String resultMessage = '📋 データ比較結果:\n';
      resultMessage += '• Hive (ローカル): $localCountグループ\n';
      resultMessage += '• Firestore (クラウド): $firestoreCountグループ\n';

      if (localCount == firestoreCount) {
        resultMessage += '✅ データ数は一致しています';
      } else {
        resultMessage += '⚠️ データ数が不一致です';
      }

      // 各グループの詳細確認
      Log.info('🔍 === 詳細データ比較 ===');
      Log.info('📱 Hive Groups:');
      for (final group in localGroups) {
        Log.info(
            '  - ${group.groupName} (${group.members?.length ?? 0} members) [${group.groupId}]');
      }

      Log.info('🔥 Firestore Groups:');
      for (final doc in groupsSnapshot.docs) {
        final data = doc.data();
        final memberCount = (data['members'] as List?)?.length ?? 0;
        Log.info('  - ${data['groupName']} ($memberCount members) [${doc.id}]');
      }

      // 最新データの詳細表示
      if (groupsSnapshot.docs.isNotEmpty) {
        final latestDoc = groupsSnapshot.docs.first;
        final latestData = latestDoc.data();
        resultMessage += '\n\n🔥 最新Firestoreデータ:\n';
        resultMessage += '• ID: ${latestDoc.id}\n';
        resultMessage += '• 名前: ${latestData['groupName']}\n';
        resultMessage += '• 作成者: ${latestData['createdBy']}\n';
        resultMessage +=
            '• メンバー数: ${(latestData['members'] as List?)?.length ?? 0}\n';
        resultMessage += '• 更新日時: ${latestData['updatedAt']?.toDate()}\n';
      }

      // 結果をダイアログで表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 詳細データ確認'),
          content: SingleChildScrollView(
            child: Text(resultMessage),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 詳細確認エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addTestMembers() async {
    final groups = await ref.read(allGroupsProvider.future);
    final testGroups =
        groups.where((g) => g.groupName.startsWith('テスト')).toList();

    if (testGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テストグループがありません')),
      );
      return;
    }

    final group = testGroups.first;
    final testMember = SharedGroupMember.create(
      memberId: 'test_uid_${DateTime.now().millisecondsSinceEpoch % 1000}',
      name: 'テストメンバー${DateTime.now().millisecondsSinceEpoch % 1000}',
      contact: '',
      role: SharedGroupRole.member,
    );

    try {
      final notifier = ref.read(selectedGroupNotifierProvider.notifier);
      await notifier.addMember(testMember);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${group.groupName}にメンバーを追加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  void _deleteTestGroup(SharedGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テストグループ削除'),
        content: Text('「${group.groupName}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(allGroupsProvider.notifier);
        final repository = ref.read(SharedGroupRepositoryProvider);
        await repository.deleteGroup(group.groupId);
        await notifier.refresh(); // リストを更新

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${group.groupName}を削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除エラー: $e')),
          );
        }
      }
    }
  }

  void _showGroupDetails(SharedGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.groupName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('グループID: ${group.groupId}'),
            Text('オーナー: ${group.ownerName ?? 'N/A'}'),
            Text('メンバー数: ${group.members?.length ?? 0}'),
            if ((group.members?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              const Text('メンバー:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...group.members!.map((member) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• ${member.name} (${member.role.name})'),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _testSharedListSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('買い物リスト同期テストを実行中...')),
    );

    try {
      // 現在のグループを取得
      final allGroupsAsync = ref.read(allGroupsProvider.future);
      final groups = await allGroupsAsync;

      if (groups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ テスト用グループがありません。先にグループを作成してください。'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final testGroup = groups.first;
      final groupId = testGroup.groupId;

      // SharedListRepository取得
      final repository = ref.read(sharedListRepositoryProvider);

      // テスト用買い物リストを作成
      final testItem = SharedItem(
        itemId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        memberId: 'test',
        name: 'テスト商品${DateTime.now().millisecondsSinceEpoch % 1000}',
        quantity: 1,
        registeredDate: DateTime.now(),
        isPurchased: false,
      );
      final testList = SharedList.create(
        ownerUid: testGroup.ownerUid ?? 'test',
        groupId: groupId,
        groupName: testGroup.groupName,
        listName: 'テストリスト',
        items: {testItem.itemId: testItem},
      );

      // Hive + Firestore ハイブリッド保存
      await repository.addItem(testList);

      // 保存後の確認
      final savedList = await repository.getSharedList(groupId);

      String resultMessage = '✅ 買い物リスト同期テスト完了\n';
      resultMessage += '• グループ: ${testGroup.groupName}\n';
      resultMessage += '• アイテム数: ${savedList?.items.length ?? 0}\n';
      resultMessage += '• Hive: ローカル保存完了\n';

      if (F.appFlavor == Flavor.prod) {
        resultMessage += '• Firestore: バックグラウンド同期実行中\n';
        resultMessage += '• 同期方式: ハイブリッド（キャッシュファースト）';
      } else {
        resultMessage += '• モード: DEV（Hiveのみ）';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🛒 買い物リスト同期テスト'),
          content: Text(resultMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );

      Log.info(
          '🛒 SharedList sync test completed for group: ${testGroup.groupName}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 買い物リスト同期テストエラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Log.error('❌ SharedList sync test error: $e');
    }
  }
}
