import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/purchase_type_provider.dart';
import '../../providers/subscription_provider.dart';

/// Premium月額プランの購入・復元を行う設定パネル。
class PurchasePlanPanel extends ConsumerStatefulWidget {
  const PurchasePlanPanel({super.key});

  @override
  ConsumerState<PurchasePlanPanel> createState() => _PurchasePlanPanelState();
}

class _PurchasePlanPanelState extends ConsumerState<PurchasePlanPanel> {
  bool _isLoading = true;
  bool _isStoreAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializePurchaseService();
  }

  Future<void> _initializePurchaseService() async {
    final service = ref.read(purchaseServiceProvider);
    await service.initialize();
    if (!mounted) return;
    setState(() {
      _isStoreAvailable = service.isAvailable;
      _isLoading = false;
    });
  }

  Future<void> _startPurchase() async {
    final service = ref.read(purchaseServiceProvider);
    await service.buyPremiumMonthly();
  }

  Future<void> _restorePurchases() async {
    final service = ref.read(purchaseServiceProvider);
    await service.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumActiveProvider);
    final service = ref.read(purchaseServiceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPremium ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPremium ? Colors.green.shade300 : Colors.amber.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.workspace_premium : Icons.star_outline,
                color:
                    isPremium ? Colors.green.shade700 : Colors.amber.shade800,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPremium ? 'Premiumプランを利用中' : 'Premiumプラン',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPremium
                        ? Colors.green.shade800
                        : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPremium
                ? '広告なしで、最大20グループ、1グループ50人まで利用できます。'
                : '広告なし、最大20グループ、1グループ50人まで利用できます。',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.business_outlined,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'グループ数・メンバー数の上限を緩和したBusinessプランを今後導入予定です。',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  _isLoading || !_isStoreAvailable ? null : _startPurchase,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.workspace_premium),
              label: Text('Premiumを有効化 (${service.premiumMonthlyPrice})'),
            ),
            if (!_isLoading && !_isStoreAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'ストアに接続できません。ストアアプリのあるAndroidまたはiOS端末でお試しください。',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed:
                _isLoading || !_isStoreAvailable ? null : _restorePurchases,
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('購入を復元'),
          ),
        ],
      ),
    );
  }
}
