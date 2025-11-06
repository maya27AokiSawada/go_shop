import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/current_group_provider.dart';
import '../providers/current_list_provider.dart';
import '../providers/group_shopping_lists_provider.dart';
import '../utils/app_logger.dart';
import '../pages/group_member_management_page.dart';
import '../services/user_initialization_service.dart';
import '../flavors.dart';

/// グループをリスト表示するウィジェット
/// タップでメンバー管理画面に遷移
class GroupListWidget extends ConsumerWidget {
  const GroupListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Log.info('🔄 [GROUP_LIST_WIDGET] build() 開始');

    // ✅ 最初に全ての依存性を確定する
    final allGroupsAsync = ref.watch(allGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    final syncStatus = ref.watch(firestoreSyncStatusProvider);

    // 同期中の場合はローディング表示
    if (syncStatus == 'syncing') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Firestore同期中...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー部分
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'グループ一覧',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // デバッグボタン
                  IconButton(
                    onPressed: () async {
                      AppLogger.info('🔄 [DEBUG] 双方向同期開始');
                      try {
                        // Firestore→Hive同期
                        await ref.read(forceSyncProvider.future);

                        // Hive→Firestore同期（本番環境のみ）
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (F.appFlavor == Flavor.prod && currentUser != null) {
                          final initService =
                              ref.read(userInitializationServiceProvider);
                          await initService.syncHiveToFirestore(currentUser);
                          AppLogger.info('✅ [DEBUG] Hive→Firestore同期完了');
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('双方向同期完了')),
                        );
                      } catch (e) {
                        AppLogger.error('❌ [DEBUG] 同期エラー: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('同期エラー: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync, size: 20),
                    tooltip: '双方向同期',
                  ),
                ],
              ),
              // カレントグループ情報
              _buildCurrentGroupInfo(
                  ref, selectedGroupId ?? 'default_group', allGroupsAsync),
            ],
          ),
        ),

        // グループリスト（スクロール可能に変更）
        Expanded(
          child: allGroupsAsync.when(
            data: (groups) => _buildGroupList(
                context, ref, groups, selectedGroupId ?? 'default_group'),
            loading: () => _buildLoadingWidget(),
            error: (error, stack) => _buildErrorWidget(context, ref, error),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupList(BuildContext context, WidgetRef ref,
      List<PurchaseGroup> groups, String selectedGroupId) {
    AppLogger.info('📋 [GROUP_LIST] グループ数: ${groups.length}');

    if (groups.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildGroupTile(context, ref, groups[index], selectedGroupId);
      },
    );
  }

  Widget _buildGroupTile(BuildContext context, WidgetRef ref,
      PurchaseGroup group, String selectedGroupId) {
    final isDefaultGroup = group.groupId == 'default_group';
    final memberCount = group.members?.length ?? 0;
    final isCurrentGroup = selectedGroupId == group.groupId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isCurrentGroup ? 4 : 1,
      color: isCurrentGroup ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentGroup
              ? Colors.blue.shade200
              : (isDefaultGroup ? Colors.green.shade100 : Colors.blue.shade100),
          child: isCurrentGroup
              ? const Icon(Icons.check_circle, color: Colors.white, size: 20)
              : Icon(
                  isDefaultGroup ? Icons.person : Icons.group,
                  color: isDefaultGroup ? Colors.green.shade700 : Colors.blue,
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.groupName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isCurrentGroup ? Colors.blue.shade800 : null,
                ),
              ),
            ),
            if (isCurrentGroup)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Text(
                  'カレント',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDefaultGroup)
              Text(
                'プライベート専用（あなたのみ）',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text('メンバー: $memberCount人'),
            if (!isDefaultGroup && (group.ownerUid?.isNotEmpty ?? false))
              Text(
                'オーナー: ${group.ownerName ?? group.ownerUid}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.settings, size: 18, color: Colors.grey),
          onPressed: () {
            AppLogger.info('📋 [GROUP_LIST] メンバー管理ボタン: ${group.groupId}');
            _navigateToMemberManagement(context, ref, group);
          },
          tooltip: 'メンバー管理',
        ),
        onTap: () async {
          AppLogger.info('📋 [GROUP_LIST] グループ選択: ${group.groupId}');
          await _selectCurrentGroup(context, ref, group);
        },
        onLongPress: () {
          _showGroupOptions(context, ref, group);
        },
      ),
    );
  }

  Future<void> _selectCurrentGroup(
      BuildContext context, WidgetRef ref, PurchaseGroup group) async {
    final currentGroup = ref.read(currentGroupProvider);

    if (currentGroup?.groupId == group.groupId) {
      AppLogger.info('📋 [GROUP_SELECT] 既に選択済み: ${group.groupId}');
      // 既に選択済みの場合もリストを再取得してUIを更新
      ref.invalidate(groupShoppingListsProvider);
      return;
    }

    // グループを選択してカレントグループに設定（awaitで非同期完了を待つ）
    await ref.read(currentGroupProvider.notifier).selectGroup(group);

    // 🔄 グループ切り替え時は現在のリスト選択をクリア
    // （別のグループのリストIDが残っているとDropdownエラーになるため）
    ref.read(currentListProvider.notifier).clearSelection();
    AppLogger.info('🗑️ [GROUP_SELECT] カレントリストをクリアしました');

    AppLogger.info(
        '📋 [GROUP_SELECT] カレントグループを変更: ${group.groupName} (${group.groupId})');

    // 成功メッセージを表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('「${group.groupName}」をカレントグループに設定しました'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // グループ切り替え時にリスト一覧プロバイダーも再取得
    ref.invalidate(groupShoppingListsProvider);
  }

  void _navigateToMemberManagement(
      BuildContext context, WidgetRef ref, PurchaseGroup group) {
    // メンバー管理画面に遷移（カレントグループ設定は行わない）
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupMemberManagementPage(group: group),
      ),
    );
  }

  Widget _buildCurrentGroupInfo(WidgetRef ref, String selectedGroupId,
      AsyncValue<List<PurchaseGroup>> allGroupsAsync) {
    return allGroupsAsync.when(
      data: (groups) {
        final currentGroup =
            groups.where((g) => g.groupId == selectedGroupId).firstOrNull;

        if (currentGroup == null) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'カレントグループが選択されていません',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.my_location, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'カレント: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  currentGroup.groupName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${currentGroup.members?.length ?? 0}人',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'グループがありません',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            '右下の + ボタンから\n新しいグループを作成してください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('グループを読み込み中...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'グループの読み込みに失敗しました',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString().length > 100
                ? '${error.toString().substring(0, 100)}...'
                : error.toString(),
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              AppLogger.info('📋 [GROUP_LIST] 再試行ボタン押下');
              ref.invalidate(allGroupsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showGroupOptions(
      BuildContext context, WidgetRef ref, PurchaseGroup group) async {
    // デフォルトグループは削除不可
    if (group.groupId == 'default_group') {
      AppLogger.info('🔒 [GROUP_OPTIONS] デフォルトグループは削除できません');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('デフォルトグループ（MyLists）は削除できません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 現在のユーザー情報を安全に取得
    User? currentUser;
    try {
      if (F.appFlavor == Flavor.prod) {
        currentUser = FirebaseAuth.instance.currentUser;
      }
    } catch (e) {
      AppLogger.info('🔄 [GROUP_OPTIONS] Firebase利用不可（開発環境）: $e');
      currentUser = null;
    }
    if (currentUser == null && F.appFlavor == Flavor.prod) {
      AppLogger.warning('⚠️  [GROUP_OPTIONS] ユーザーが認証されていません');
      return;
    }

    // グループのオーナーかどうかを確認
    final members = group.members;
    final currentUserId = currentUser?.uid ?? '';
    final currentMember = members?.firstWhere(
          (member) => member.memberId == currentUserId,
          orElse: () => const PurchaseGroupMember(
            memberId: '',
            name: '',
            contact: '',
            role: PurchaseGroupRole.member,
          ),
        ) ??
        const PurchaseGroupMember(
          memberId: '',
          name: '',
          contact: '',
          role: PurchaseGroupRole.member,
        );

    final isOwner = currentMember.role == PurchaseGroupRole.owner;

    if (!isOwner) {
      AppLogger.info('📋 [GROUP_OPTIONS] オーナーではないため削除権限なし: $currentUserId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('グループを削除できるのはオーナーのみです'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 削除確認ダイアログを表示
    _showDeleteConfirmationDialog(context, ref, group);
  }

  static void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, PurchaseGroup group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('グループを削除'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('「${group.groupName}」を削除しますか？'),
              const SizedBox(height: 8),
              const Text(
                'この操作は取り消せません。\nグループ内のすべてのデータが削除されます。',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteGroup(context, ref, group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  static void _deleteGroup(
      BuildContext context, WidgetRef ref, PurchaseGroup group) async {
    AppLogger.info('🗑️ [GROUP_DELETE] グループ削除開始: ${group.groupId}');

    try {
      // ローディング表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('グループを削除中...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // リポジトリから削除実行
      final repository = ref.read(purchaseGroupRepositoryProvider);
      await repository.deleteGroup(group.groupId);

      // プロバイダーを更新
      ref.invalidate(allGroupsProvider);

      AppLogger.info('✅ [GROUP_DELETE] グループ削除完了: ${group.groupId}');

      // 成功メッセージ
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${group.groupName}」を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('❌ [GROUP_DELETE] グループ削除エラー', error, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('グループの削除に失敗しました: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
