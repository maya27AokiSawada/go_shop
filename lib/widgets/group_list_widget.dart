import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shared_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/current_list_provider.dart';
import '../providers/group_shopping_lists_provider.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import '../utils/snackbar_helper.dart';
// 🔥 REMOVED: import '../utils/group_helpers.dart'; デフォルトグループ機能削除
import '../pages/group_member_management_page.dart';
import '../services/user_initialization_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
// 🔥 REMOVED: import 'initial_setup_widget.dart'; グループページ内にメッセージ表示に変更

/// グループをリスト表示するウィジェット
/// タップでメンバー管理画面に遷移
class GroupListWidget extends ConsumerWidget {
  const GroupListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Log.info('🔄 [GROUP_LIST_WIDGET] build() 開始');

    // ✅ 最初に全ての依存性を確定する
    final allGroupsAsync = ref.watch(allGroupsProvider);
    // selectedGroupIdProviderとcurrentGroupProviderを同期して使用
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
          padding: const EdgeInsets.all(12.0), // 🔥 FIX: 16→12に縮小
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups,
                      color: Colors.blue, size: 20), // 🔥 FIX: サイズ指定
                  const SizedBox(width: 8),
                  const Expanded(
                    // 🔥 FIX: オーバーフロー防止
                    child: Text(
                      'グループ一覧',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis, // 🔥 FIX: オーバーフロー時省略
                    ),
                  ),
                  const Spacer(),
                  // デバッグボタン
                  IconButton(
                    onPressed: () async {
                      await ErrorHandler.handleAsync(
                        operation: () async {
                          AppLogger.info('🔄 [DEBUG] 双方向同期開始');
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) {
                            throw Exception('ユーザーがサインインしていません');
                          }

                          // 1. Hive→Firestore同期（ローカルの最新データをアップロード）
                          {
                            final initService =
                                ref.read(userInitializationServiceProvider);
                            AppLogger.info('⬆️ [DEBUG] Hive→Firestore同期開始...');
                            await initService.syncHiveToFirestore(currentUser);
                            AppLogger.info('✅ [DEBUG] Hive→Firestore同期完了');

                            // Firestore書き込み反映を待つ
                            await Future.delayed(const Duration(seconds: 2));
                          }

                          // 2. Firestore→Hive同期（Firestoreから最新データを取得）
                          AppLogger.info('⬇️ [DEBUG] Firestore→Hive同期開始...');
                          await ref.read(forceSyncProvider.future);
                          AppLogger.info('✅ [DEBUG] Firestore→Hive同期完了');

                          if (context.mounted) {
                            SnackBarHelper.showSuccess(context, '双方向同期完了');
                          }
                        },
                        context: 'GROUP_LIST:debugSync',
                        defaultValue: null,
                        onError: (error, stackTrace) {
                          if (context.mounted) {
                            SnackBarHelper.showError(context, '同期エラー: $error');
                          }
                        },
                      );
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
      List<SharedGroup> groups, String selectedGroupId) {
    AppLogger.info('📋 [GROUP_LIST] グループ数: ${groups.length}');

    // 🔥 FIX: グループが0個の場合はシンプルなメッセージを表示
    // （右下のFloatingActionButtonでグループ作成可能）
    // 🔥 AS10L対応: SingleChildScrollViewでオーバーフロー防止
    if (groups.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0), // 🔥 FIX: 32→24に縮小
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // 🔥 FIX: 最小サイズに制限
              children: [
                Icon(Icons.group_add,
                    size: 60, color: Colors.blue.shade200), // 🔥 FIX: 80→60に縮小
                const SizedBox(height: 16), // 🔥 FIX: 24→16に縮小
                const Text(
                  '最初のグループを作成するか\nQRコードをスキャンして参加してください',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold), // 🔥 FIX: 20→16に縮小
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12), // 🔥 FIX: 16→12に縮小
                Text(
                  '右下の ＋ ボタンからグループを作成できます',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600), // 🔥 FIX: 16→14に縮小
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: groups.length,
      padding:
          const EdgeInsets.only(bottom: 80), // FloatingActionButtonの分の余白を追加
      itemBuilder: (context, index) {
        return _buildGroupTile(context, ref, groups[index], selectedGroupId);
      },
    );
  }

  Widget _buildGroupTile(BuildContext context, WidgetRef ref, SharedGroup group,
      String selectedGroupId) {
    final memberCount = group.members?.length ?? 0;
    final isCurrentGroup = selectedGroupId == group.groupId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isCurrentGroup ? 4 : 1,
      color: isCurrentGroup ? Colors.blue.shade50 : null,
      child: GestureDetector(
        onTap: () async {
          AppLogger.info('📋 [GROUP_LIST] グループ選択: ${group.groupId}');
          await _selectCurrentGroup(context, ref, group);
        },
        onDoubleTap: () {
          AppLogger.info('📋 [GROUP_LIST] メンバー管理: ${group.groupId}');
          _navigateToMemberManagement(context, ref, group);
        },
        onLongPress: () {
          _showGroupOptions(context, ref, group);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCurrentGroup
                ? Colors.blue.shade200
                : Colors.blue.shade100, // 🔥 REMOVED: デフォルトグループ判定削除
            child: isCurrentGroup
                ? const Icon(Icons.check_circle, color: Colors.white, size: 20)
                : const Icon(
                    Icons.group, // 🔥 REMOVED: デフォルトグループ判定削除
                    color: Colors.blue,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              Text('メンバー: $memberCount人'),
              // 🔥 REMOVED: デフォルトグループ判定削除 - 全グループでオーナー表示
              if (group.ownerUid?.isNotEmpty ?? false)
                Text(
                  'オーナー: ${group.ownerName ?? '（不明）'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// グループの最終使用リストを復元
  Future<void> _restoreLastUsedList(WidgetRef ref, String groupId) async {
    await ErrorHandler.handleAsync(
      operation: () async {
        // 最終使用リストIDを取得
        final listId = await ref
            .read(currentListProvider.notifier)
            .getSavedListIdForGroup(groupId);

        // グループのリスト一覧を取得
        final listsAsync = await ref.read(groupSharedListsProvider.future);

        // 🆕 リストが空の場合（新規グループなど）は何もしない
        if (listsAsync.isEmpty) {
          AppLogger.info('💡 [LIST_RESTORE] グループ[$groupId]にリストがありません');
          ref.read(currentListProvider.notifier).clearSelection();
          return;
        }

        if (listId != null) {
          // リストIDに一致するリストを検索
          final list = listsAsync.where((l) => l.listId == listId).firstOrNull;

          if (list != null) {
            // リストを復元
            ref.read(currentListProvider.notifier).selectList(
                  list,
                  groupId: groupId,
                );
            AppLogger.info(
                '✅ [LIST_RESTORE] グループ[$groupId]の最終使用リストを復元: ${list.listName}');
          } else {
            AppLogger.info('⚠️ [LIST_RESTORE] リストID[$listId]が見つかりません');
            ref.read(currentListProvider.notifier).clearSelection();
          }
        } else {
          // 🆕 保存情報がない場合：リストが1つだけなら自動選択
          if (listsAsync.length == 1) {
            final onlyList = listsAsync.first;
            ref.read(currentListProvider.notifier).selectList(
                  onlyList,
                  groupId: groupId,
                );
            AppLogger.info(
                '✅ [LIST_RESTORE] リストが1つのみ - 自動選択: ${onlyList.listName}');
          } else {
            AppLogger.info('💡 [LIST_RESTORE] グループ[$groupId]の最終使用リスト情報なし');
            ref.read(currentListProvider.notifier).clearSelection();
          }
        }
      },
      context: 'GROUP_LIST:restoreLastUsedList',
      defaultValue: null,
      onError: (error, stackTrace) {
        AppLogger.info('❌ [LIST_RESTORE] エラー発生: $error');
        ref.read(currentListProvider.notifier).clearSelection();
      },
    );
  }

  Future<void> _selectCurrentGroup(
      BuildContext context, WidgetRef ref, SharedGroup group) async {
    final selectedGroupId = ref.read(selectedGroupIdProvider);

    if (selectedGroupId == group.groupId) {
      AppLogger.info('📋 [GROUP_SELECT] 既に選択済み: ${group.groupId}');
      // 既に選択済みの場合もリストを再取得してUIを更新
      ref.invalidate(groupSharedListsProvider);
      return;
    }

    // グループを選択（awaitで非同期完了を待つ）
    await ref.read(selectedGroupIdProvider.notifier).selectGroup(group.groupId);

    AppLogger.info(
        '📋 [GROUP_SELECT] selectedGroupIdProviderを更新: ${group.groupId}');

    // 🔄 グループ切り替え時：最終使用リストを復元
    await _restoreLastUsedList(ref, group.groupId);

    AppLogger.info(
        '📋 [GROUP_SELECT] カレントグループを変更: ${group.groupName} (${group.groupId})');

    // 成功メッセージを表示
    SnackBarHelper.showCustom(
      context,
      message: '「${group.groupName}」を選択しました',
      icon: Icons.check_circle,
      backgroundColor: Colors.green[700],
      duration: const Duration(seconds: 2),
    );

    // グループ切り替え時にリスト一覧プロバイダーも再取得
    ref.invalidate(groupSharedListsProvider);
  }

  void _navigateToMemberManagement(
      BuildContext context, WidgetRef ref, SharedGroup group) {
    // メンバー管理画面に遷移（カレントグループ設定は行わない）
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupMemberManagementPage(group: group),
      ),
    );
  }

  Widget _buildCurrentGroupInfo(WidgetRef ref, String selectedGroupId,
      AsyncValue<List<SharedGroup>> allGroupsAsync) {
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

        // カレントグループ表示を削除（AppBarに統合済み）
        return const SizedBox.shrink();
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
            '右下の + ボタンから新しいグループを作成してください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'グループを読み込み中...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'デフォルトグループを準備しています',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
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
      BuildContext context, WidgetRef ref, SharedGroup group) async {
    // 現在のユーザー情報を安全に取得
    final currentUser = ErrorHandler.handleSync<User?>(
      operation: () {
        {
          return FirebaseAuth.instance.currentUser;
        }
        return null;
      },
      context: 'GROUP_LIST:getCurrentUser',
      defaultValue: null,
    );

    // 🔥 REMOVED: デフォルトグループ削除保護廃止
    // 全てのグループが削除可能

    if (currentUser == null) {
      AppLogger.warning('⚠️  [GROUP_OPTIONS] ユーザーが認証されていません');
      return;
    }

    // 🔥 P1 #3 FIX: オーナーは削除、メンバーは退出ダイアログを表示
    // 以前は非オーナーを早期returnしていたため、退出機能に到達できなかった
    // オーナー判定は_showDeleteConfirmationDialog内でgroup.ownerUidで行う
    _showDeleteConfirmationDialog(context, ref, group);
  }

  static void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, SharedGroup group) {
    // オーナー判定
    final authState = ref.read(authStateProvider);
    final currentUser = authState.value;
    final isOwner = currentUser != null && group.ownerUid == currentUser.uid;

    if (isOwner) {
      // オーナーの場合: グループ削除ダイアログ
      _showOwnerDeleteDialog(context, ref, group);
    } else {
      // メンバーの場合: グループ離脱ダイアログ
      _showMemberLeaveDialog(context, ref, group);
    }
  }

  /// オーナー用: グループ削除確認ダイアログ
  static void _showOwnerDeleteDialog(
      BuildContext context, WidgetRef ref, SharedGroup group) {
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

  /// メンバー用: グループ離脱確認ダイアログ
  static void _showMemberLeaveDialog(
      BuildContext context, WidgetRef ref, SharedGroup group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('グループを退出'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('「${group.groupName}」から退出しますか？'),
              const SizedBox(height: 8),
              const Text(
                'あなたの情報がこのグループから削除されます。\n再度参加するには、招待が必要です。',
                style: TextStyle(color: Colors.orange, fontSize: 12),
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
                _leaveGroup(context, ref, group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
  }

  /// オーナー専用: グループ完全削除
  static void _deleteGroup(
      BuildContext context, WidgetRef ref, SharedGroup group) async {
    AppLogger.info('🗑️ [GROUP_DELETE] グループ削除開始: ${group.groupId}');

    try {
      // ローディング表示
      SnackBarHelper.showCustom(
        context,
        message: 'グループを削除中...',
        icon: Icons.hourglass_empty,
        duration: const Duration(seconds: 5),
      );

      // リポジトリから削除実行
      final repository = ref.read(SharedGroupRepositoryProvider);
      await repository.deleteGroup(group.groupId);

      // 🔥 削除通知を送信
      final notificationService = ref.read(notificationServiceProvider);
      final authState = ref.read(authStateProvider);
      final currentUser = authState.value;
      if (currentUser != null) {
        final userName = currentUser.displayName ?? 'ユーザー';
        await notificationService.sendGroupDeletedNotification(
          groupId: group.groupId,
          groupName: group.groupName,
          deleterName: userName,
        );
        AppLogger.info('✅ [GROUP_DELETE] 削除通知送信完了');
      }

      // 削除されたグループが選択中のグループの場合はクリア
      final selectedGroupId = ref.read(selectedGroupIdProvider);
      if (selectedGroupId == group.groupId) {
        AppLogger.info('🔄 [GROUP_DELETE] 選択中のグループをクリア: ${group.groupId}');
        ref.read(selectedGroupIdProvider.notifier).clearSelection();
        ref.read(currentListProvider.notifier).clearSelection();
      }

      // プロバイダーを更新
      ref.invalidate(allGroupsProvider);

      AppLogger.info('✅ [GROUP_DELETE] グループ削除完了: ${group.groupId}');

      // 成功メッセージ
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        SnackBarHelper.showSuccess(context, '「${group.groupName}」を削除しました');
      }
    } catch (error, stackTrace) {
      AppLogger.error('❌ [GROUP_DELETE] グループ削除エラー', error, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        SnackBarHelper.showError(context, 'グループの削除に失敗しました: $error');
      }
    }
  }

  /// メンバー専用: グループ離脱
  static void _leaveGroup(
      BuildContext context, WidgetRef ref, SharedGroup group) async {
    AppLogger.info('🚪 [GROUP_LEAVE] グループ離脱開始: ${group.groupId}');

    try {
      // ローディング表示
      SnackBarHelper.showCustom(
        context,
        message: 'グループを退出中...',
        icon: Icons.hourglass_empty,
        duration: const Duration(seconds: 5),
      );

      // 現在のユーザー情報取得
      final authState = ref.read(authStateProvider);
      final currentUser = authState.value;
      if (currentUser == null) {
        throw Exception('ユーザー情報が取得できません');
      }

      // 自分のメンバー情報を検索
      final myMember = group.members?.firstWhere(
        (m) => m.memberId == currentUser.uid,
        orElse: () => throw Exception('メンバー情報が見つかりません'),
      );

      if (myMember == null) {
        throw Exception('メンバー情報が見つかりません');
      }

      // リポジトリからメンバー削除実行
      // 🔥 CRITICAL: removeMember()は members + allowedUid 両方を更新
      final repository = ref.read(SharedGroupRepositoryProvider);
      await repository.removeMember(group.groupId, myMember);

      AppLogger.info('✅ [GROUP_LEAVE] Firestore更新完了（members + allowedUid）');

      // ローカル（Hive）から削除
      // 注: HybridRepositoryが自動的にHiveも更新する

      // 離脱したグループが選択中の場合はクリア
      final selectedGroupId = ref.read(selectedGroupIdProvider);
      if (selectedGroupId == group.groupId) {
        AppLogger.info('🔄 [GROUP_LEAVE] 選択中のグループをクリア: ${group.groupId}');
        ref.read(selectedGroupIdProvider.notifier).clearSelection();
        ref.read(currentListProvider.notifier).clearSelection();
      }

      // プロバイダーを更新（UIから消える）
      ref.invalidate(allGroupsProvider);

      AppLogger.info('✅ [GROUP_LEAVE] グループ離脱完了: ${group.groupId}');

      // 成功メッセージ
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        SnackBarHelper.showSuccess(context, '「${group.groupName}」から退出しました');
      }
    } catch (error, stackTrace) {
      AppLogger.error('❌ [GROUP_LEAVE] グループ離脱エラー', error, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        SnackBarHelper.showError(context, 'グループの退出に失敗しました');
      }
    }
  }
}
