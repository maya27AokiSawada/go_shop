import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_group.dart';
import '../providers/purchase_group_provider.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';

/// グループ選択専用ウィジェット
class GroupSelectorWidget extends ConsumerWidget {
  const GroupSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGroupsAsync = ref.watch(allGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    AppLogger.info('グループセレクタ呼び出し開始');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // デバッグ用: Firestore同期ボタン（コンパクト版）
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    AppLogger.info('🔄 [DEBUG] Firestore強制同期開始');
                    try {
                      await ref.read(forceSyncProvider.future);
                      AppLogger.info('✅ [DEBUG] Firestore同期完了');
                      SnackBarHelper.showSuccess(context, '同期完了');
                    } catch (e) {
                      AppLogger.error('❌ [DEBUG] Firestore同期エラー: $e');
                      SnackBarHelper.showError(context, '同期エラー: $e');
                    }
                  },
                  icon: const Icon(Icons.sync, size: 14),
                  label: const Text('同期', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(60, 28),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppLogger.info('🔄 [DEBUG] プロバイダー更新');
                    ref.invalidate(allGroupsProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('更新', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(60, 28),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 既存のGroupSelector
        allGroupsAsync.when(
          data: (groups) =>
              _buildGroupDropdown(context, ref, groups, selectedGroupId),
          loading: () => _buildLoadingWidget(),
          error: (error, stack) => _buildErrorWidget(context, ref, error),
        ),
      ],
    );
  }

  Widget _buildGroupDropdown(BuildContext context, WidgetRef ref,
      List<SharedGroup> groups, String? selectedGroupId) {
    AppLogger.info('📋 [GROUP_SELECTOR] グループ数: ${groups.length}');

    // デバッグ: 各グループの詳細をログ出力
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      AppLogger.info(
          '📋 [GROUP_SELECTOR] [$i] ${group.groupName} (${group.groupId}) - Owner: ${group.ownerUid}');
      AppLogger.info(
          '📋 [GROUP_SELECTOR] [$i] Members: ${group.members?.length ?? 0}');
    }

    // デフォルトグループの存在チェック
    final hasDefaultGroup = groups.any((g) => g.groupId == 'default_group');
    AppLogger.info('📋 [GROUP_SELECTOR] デフォルトグループ存在: $hasDefaultGroup');

    if (groups.isEmpty) {
      return _buildCreateGroupWidget(ref);
    }

    // 有効なグループIDを決定
    final groupExists = selectedGroupId != null &&
        groups.any((group) => group.groupId == selectedGroupId);
    final validSelectedGroupId =
        groupExists ? selectedGroupId : groups.first.groupId;

    AppLogger.info(
        '📋 [GROUP_SELECTOR] 選択グループ: $selectedGroupId -> $validSelectedGroupId');

    // 選択状態が無効な場合、自動的に修正
    if (!groupExists && groups.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppLogger.info('📋 [GROUP_SELECTOR] 自動選択実行: ${groups.first.groupId}');
        ref
            .read(selectedGroupIdProvider.notifier)
            .selectGroup(groups.first.groupId);
      });
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ヘッダー部分
              Row(
                children: [
                  const Icon(Icons.group, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'グループ選択',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${groups.length}個',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ドロップダウン部分
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: validSelectedGroupId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    iconSize: 24,
                    elevation: 16,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    items: groups
                        .map<DropdownMenuItem<String>>((SharedGroup group) {
                      return DropdownMenuItem<String>(
                        value: group.groupId,
                        child: Row(
                          children: [
                            Icon(
                              group.groupId == 'default_group'
                                  ? Icons.home
                                  : Icons.group,
                              size: 16,
                              color: group.groupId == 'default_group'
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                group.groupName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (group.members?.isNotEmpty == true) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${group.members!.length}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != selectedGroupId) {
                        AppLogger.info(
                            '📋 [GROUP_SELECTOR] ドロップダウン選択: $selectedGroupId -> $newValue');
                        try {
                          ref
                              .read(selectedGroupIdProvider.notifier)
                              .selectGroup(newValue);
                          AppLogger.info('📋 [GROUP_SELECTOR] 選択完了: $newValue');
                        } catch (e) {
                          AppLogger.error('📋 [GROUP_SELECTOR] 選択エラー: $e');
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('グループを読み込み中...', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 24),
              const SizedBox(height: 8),
              const Text(
                'グループの読み込みに失敗',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                error.toString().length > 50
                    ? '${error.toString().substring(0, 50)}...'
                    : error.toString(),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  AppLogger.info('📋 [GROUP_SELECTOR] 再試行ボタン押下');
                  ref.invalidate(allGroupsProvider);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('再試行', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateGroupWidget(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_add, size: 32, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'グループがありません',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                '最初のグループを作成してください',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  AppLogger.info(
                      '📋 [GROUP_SELECTOR] グループ作成要求 - FloatingActionButtonを使用してください');
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('グループを作成', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
