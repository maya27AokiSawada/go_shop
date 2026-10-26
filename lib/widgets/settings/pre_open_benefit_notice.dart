import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pre_open_benefit_provider.dart';
import '../../services/pre_open_benefit_service.dart';
import '../../l10n/l10n.dart';

/// プレオープン特典で Premium 相当の機能を利用中であることの案内。
class PreOpenBenefitNotice extends StatelessWidget {
  const PreOpenBenefitNotice({super.key, required this.status});

  /// 利用中の特典の状態（[PreOpenBenefitStatus.endDate] が必要）
  final PreOpenBenefitStatus status;

  @override
  Widget build(BuildContext context) {
    // 終了日時の直前の日を「〜まで」として表示する
    final lastDay = status.endDate!.subtract(const Duration(seconds: 1));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                size: 18,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  texts.preOpenBenefitTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            texts.preOpenBenefitBody(lastDay.year, lastDay.month, lastDay.day),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}

/// 課金パネルを表示しない環境（iOS の課金開始前）で、
/// プレオープン特典の案内だけを表示する設定パネル。
/// 購入ボタンなど課金関連の UI は含めない。特典の対象外なら何も表示しない。
class PreOpenBenefitPanel extends ConsumerWidget {
  const PreOpenBenefitPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(preOpenBenefitProvider).valueOrNull;
    if (status == null || !status.isActive) return const SizedBox.shrink();

    // 下余白はパネル側で持つ（非表示時に余白が残らないように）
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: PreOpenBenefitNotice(status: status),
    );
  }
}
