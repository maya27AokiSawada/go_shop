import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 課金催促は非表示にして広告のみの運用とする。
class PaymentReminderWidget extends ConsumerWidget {
  const PaymentReminderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
