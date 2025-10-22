import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../utils/app_logger.dart';

/// グループ選択専用ウィジェット
///
/// 機能:
/// - ドロップダウンリストによるグループ選択
/// - 選択結果のプロバイダーへの反映
/// - グループが存在しない場合の作成機能
/// - ローディング状態とエラー状態の表示
class GroupSelectorWidget extends ConsumerWidget {
  const GroupSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGroupsAsync = ref.watch(allGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    Log.info('📋 [GROUP_SELECTOR] 呼び出し開始 - 状態: ${allGroupsAsync.runtimeType}');

    return allGroupsAsync.when(
      data: (groups) =>
          _buildGroupDropdown(context, ref, groups, selectedGroupId),
      loading: () => _buildLoadingWidget(),
      error: (error, stack) => _buildErrorWidget(context, ref, error),
    );
  }

  /// グループ選択ドロチE�Eダウンを構篁E
  Widget _buildGroupDropdown(BuildContext context, WidgetRef ref,
      List<PurchaseGroup> groups, String? selectedGroupId) {
    AppLogger.info('📋 [GROUP_SELECTOR] チE�Eタ取得�E劁E- グループ数: ${groups.length}');

    for (var g in groups) {
      AppLogger.info(
          '📋 [GROUP_SELECTOR] - ${g.groupName} (${g.groupId}) メンバ�E数: ${g.members?.length ?? 0}');
    }

    // グループが空の場合�E作�Eボタンを表示
    if (groups.isEmpty) {
      return _buildCreateGroupWidget(ref);
    }

    // 選択されたグループが存在するかチェチE��
    final groupExists = selectedGroupId != null &&
        groups.any((group) => group.groupId == selectedGroupId);
    final validSelectedGroupId =
        groupExists ? selectedGroupId : groups.first.groupId;

    AppLogger.info(
        '📋 [GROUP_SELECTOR] selectedGroupId: $selectedGroupId, validSelectedGroupId: $validSelectedGroupId');

    // 選択されたグループIDが変更された場合、�Eロバイダーを更新
    if (validSelectedGroupId != selectedGroupId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(selectedGroupIdProvider.notifier)
            .selectGroup(validSelectedGroupId);
      });
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'グループ選択',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'アクティブなグループ',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              initialValue: validSelectedGroupId,
              items: groups.map((group) {
                final displayName = group.groupId == 'default_group'
                    ? 'マイリスト（プライベート）'
                    : group.groupName;
                final memberCount = group.members?.length ?? 0;
                return DropdownMenuItem<String>(
                  value: group.groupId,
                  child: Row(
                    children: [
                      Expanded(child: Text(displayName)),
                      if (memberCount > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$memberCount人',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newGroupId) {
                if (newGroupId != null) {
                  AppLogger.info('📋 [GROUP_SELECTOR] グループ選択: $newGroupId');
                  ref
                      .read(selectedGroupIdProvider.notifier)
                      .selectGroup(newGroupId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ローディング中のウィジェット
  Widget _buildLoadingWidget() {
    AppLogger.info('⏳ [GROUP_SELECTOR] ロード中...');
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('グループを読み込み中...'),
          ],
        ),
      ),
    );
  }

  /// グループ作成ウィジェット
  Widget _buildCreateGroupWidget(WidgetRef ref) {
    AppLogger.warning('⚠️ [GROUP_SELECTOR] グループが空です - デフォルトグループ作成を提供');

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.group_add,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            const Text(
              'グループが見つかりません',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '新しいグループを作成して買い物リストを始めましょう',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _createDefaultGroup(ref),
              icon: const Icon(Icons.add),
              label: const Text('マイリストを作成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// エラー表示ウィジェチE��
  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
    AppLogger.error('❁E[GROUP_SELECTOR] エラー: $error');

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'グループ�E読み込みに失敗しました',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'エラー詳細: $error',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.invalidate(allGroupsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// デフォルトグループ作成処理
  Future<void> _createDefaultGroup(WidgetRef ref) async {
    AppLogger.info('🔄 [GROUP_SELECTOR] デフォルトグループ作成開始');

    try {
      final repository = ref.read(purchaseGroupRepositoryProvider);
      await repository.getGroupById('default_group'); // これで自動作成される
      ref.invalidate(allGroupsProvider);
      AppLogger.info('✅ [GROUP_SELECTOR] デフォルトグループ作成完了');
    } catch (e) {
      AppLogger.error('❌ [GROUP_SELECTOR] デフォルトグループ作成失敗: $e');
      // エラーはUIに表示されるため、ここでは何もしない
    }
  }
}
