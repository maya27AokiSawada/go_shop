import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n.dart';
import '../providers/group_limit_provider.dart';
import '../providers/page_index_provider.dart';

/// グループ数がプラン上限を超えているときに、グループの削除を促す警告
///
/// 上限内なら何も表示しない。[showOpenGroupButton] が true のときは
/// グループ画面（下部ナビゲーションの index 1）へ移動するボタンを表示する。
class GroupLimitWarningBanner extends ConsumerWidget {
  final bool showOpenGroupButton;

  const GroupLimitWarningBanner({super.key, this.showOpenGroupButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(groupLimitStatusProvider);
    if (!status.isExceeded) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texts.groupLimitExceededTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            texts.groupLimitExceededMessage(
                status.groupCount, status.maxGroups),
            style: TextStyle(fontSize: 14, color: Colors.red.shade900),
          ),
          if (showOpenGroupButton) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () =>
                    ref.read(pageIndexProvider.notifier).setPageIndex(1),
                icon: const Icon(Icons.group),
                label: Text(texts.openGroupPage),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
