import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/purchase_type.dart';
import '../../providers/purchase_type_provider.dart';
import '../../utils/app_logger.dart';

/// 課金状態の切替パネル（開発環境のみ）
///
/// ストアで購入せずに自分の purchaseType を subscribe / free に切り替え、
/// 家族特典クーポンなど Premium 前提の機能を確認する。
/// 書き込みは dev プロジェクト専用の Callable（setDevPurchaseType）で行う。
class DevPurchaseTypeSwitcher extends ConsumerStatefulWidget {
  const DevPurchaseTypeSwitcher({super.key});

  @override
  ConsumerState<DevPurchaseTypeSwitcher> createState() =>
      _DevPurchaseTypeSwitcherState();
}

class _DevPurchaseTypeSwitcherState
    extends ConsumerState<DevPurchaseTypeSwitcher> {
  bool _isBusy = false;

  Future<void> _setPurchaseType(PurchaseType type) async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFunctions.instanceFor(region: 'asia-northeast1')
          .httpsCallable('setDevPurchaseType')
          .call<Map<String, dynamic>>({'purchaseType': type.firestoreValue});
      messenger.showSnackBar(
        SnackBar(content: Text('課金状態を ${type.displayName} にしました')),
      );
    } catch (e) {
      Log.warning('⚠️ [DEV] 課金状態の切替エラー: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('課金状態の切替エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(purchaseTypeProvider).valueOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium,
                  color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '課金状態の切替（開発用）',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '現在: ${current?.displayName ?? '読み込み中'}\n'
            'ストアで購入せずに Firestore の purchaseType を切り替えます（dev プロジェクトのみ）',
            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _isBusy || current == PurchaseType.subscribe
                      ? null
                      : () => _setPurchaseType(PurchaseType.subscribe),
                  child: const Text('Premium にする'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isBusy || current == PurchaseType.free
                      ? null
                      : () => _setPurchaseType(PurchaseType.free),
                  child: const Text('無料に戻す'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
