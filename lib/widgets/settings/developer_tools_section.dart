import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/shared_group_provider.dart';
import '../../services/user_initialization_service.dart';
import '../test_scenario_widget.dart';
import '../../debug/fix_maya_group.dart';

/// 開発者ツールパネル（開発環境のみ）
class DeveloperToolsSection extends ConsumerWidget {
  final User? user;
  const DeveloperToolsSection({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: Colors.teal.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '開発者ツール',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Firebase認証とCRUD操作のテストシナリオを実行できます',
            style: TextStyle(
              fontSize: 12,
              color: Colors.teal.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TestScenarioWidget(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_filled, size: 16),
                  label: const Text(
                    'テストシナリオ',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade100,
                    foregroundColor: Colors.teal.shade800,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FixMayaGroupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.build, size: 16),
                  label: const Text(
                    'グループ修正',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.orange.shade800,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Firestoreデータ確認ボタン
          ElevatedButton.icon(
            onPressed: () async {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ログインが必要です')),
                );
                return;
              }

              try {
                final firestore = FirebaseFirestore.instance;
                final snapshot = await firestore
                    .collection('SharedGroups')
                    .where('allowedUid', arrayContains: user!.uid)
                    .get();

                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Firestoreデータ'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('現在のUID: ${user!.uid}'),
                            const SizedBox(height: 8),
                            Text('メール: ${user!.email}'),
                            const Divider(height: 16),
                            Text(
                              'Firestoreグループ数: ${snapshot.docs.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...snapshot.docs.map((doc) {
                              final data = doc.data();
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'グループ名: ${data['groupName'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('ID: ${doc.id}'),
                                      Text(
                                          'ownerUid: ${data['ownerUid'] ?? 'N/A'}'),
                                      Text(
                                          'allowedUid: ${data['allowedUid']?.toString() ?? 'N/A'}'),
                                    ],
                                  ),
                                ),
                              );
                            }),
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
                }
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('エラー'),
                      content: Text('Firestore確認エラー:\n$e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.cloud, size: 16),
            label: const Text(
              'Firestoreデータ確認',
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade100,
              foregroundColor: Colors.purple.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(double.infinity, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 8),
          // Firestoreから同期ボタン
          ElevatedButton.icon(
            onPressed: () async {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ログインが必要です')),
                );
                return;
              }

              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Firestoreから同期中...'),
                    duration: Duration(seconds: 2),
                  ),
                );

                final initService = ref.read(userInitializationServiceProvider);
                await initService.syncFromFirestoreToHive(user!);

                ref.invalidate(allGroupsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 同期完了しました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('同期エラー: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.sync, size: 16),
            label: const Text(
              'Firestoreから同期',
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade100,
              foregroundColor: Colors.green.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(double.infinity, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 8),
          // グループ状態確認ボタン（Hive）
          ElevatedButton.icon(
            onPressed: () {
              try {
                final groupsAsync = ref.read(allGroupsProvider);
                groupsAsync.when(
                  data: (groups) {
                    final message = groups.isEmpty
                        ? '❌ グループが見つかりません\n\n'
                            '現在のユーザー: ${user?.uid ?? "未ログイン"}\n'
                            '現在のメール: ${user?.email ?? "N/A"}'
                        : '✅ グループ数: ${groups.length}\n\n'
                            '${groups.map((g) => '・${g.groupName} (ID: ${g.groupId})').join('\n')}\n\n'
                            '現在のユーザー: ${user?.uid ?? "未ログイン"}';

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('グループ状態'),
                        content: SingleChildScrollView(
                          child: Text(message),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('読み込み中...')),
                    );
                  },
                  error: (error, stack) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('エラー'),
                        content: Text('グループ読み込みエラー:\n$error'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('確認エラー: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text(
              'グループ状態確認',
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(double.infinity, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
