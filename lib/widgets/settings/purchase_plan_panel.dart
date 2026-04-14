import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/purchase_type.dart';
import '../../providers/purchase_type_provider.dart';
import '../../services/purchase_service.dart';

/// 課金プランパネルウィジェット（設定ページ用）
class PurchasePlanPanel extends ConsumerStatefulWidget {
  const PurchasePlanPanel({super.key});

  @override
  ConsumerState<PurchasePlanPanel> createState() => _PurchasePlanPanelState();
}

class _PurchasePlanPanelState extends ConsumerState<PurchasePlanPanel> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // PurchaseService を初期化（商品情報をロード）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final service = ref.read(purchaseServiceProvider);
        await service.initialize();
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _buy(
    BuildContext context,
    PurchaseService service,
    Future<void> Function() buyAction,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await buyAction();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('購入処理に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restore(BuildContext context, PurchaseService service) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await service.restorePurchases();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入情報を復元しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('復元に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseTypeAsync = ref.watch(purchaseTypeProvider);
    final service = ref.read(purchaseServiceProvider);

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
          // ヘッダー
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '課金プラン',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 現在のプラン表示
          purchaseTypeAsync.when(
            data: (type) => _buildCurrentPlanBadge(type),
            loading: () => const SizedBox(
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // プラン比較表
          _buildPlanComparisonTable(),

          const SizedBox(height: 16),

          // 購入ボタン（現在のプランに応じて表示）
          purchaseTypeAsync.when(
            data: (type) => _buildPurchaseButtons(context, service, type),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // 購入復元ボタン
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed:
                  _isProcessing ? null : () => _restore(context, service),
              child: const Text(
                '購入を復元する',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),

          const SizedBox(height: 4),
          Text(
            '※ サブスクは2ヶ月ごとに自動更新されます。設定アプリからいつでも解約できます。',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBadge(PurchaseType type) {
    Color badgeColor;
    IconData icon;
    switch (type) {
      case PurchaseType.subscribe:
        badgeColor = Colors.green;
        icon = Icons.card_membership;
        break;
      case PurchaseType.purchase:
        badgeColor = Colors.blue;
        icon = Icons.shopping_bag;
        break;
      case PurchaseType.free:
        badgeColor = Colors.grey;
        icon = Icons.person;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: badgeColor, size: 16),
        const SizedBox(width: 6),
        Text(
          '現在のプラン：${type.displayName}',
          style: TextStyle(
            fontSize: 13,
            color: badgeColor.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanComparisonTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.amber.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        _tableHeader(),
        _tableRow('バナー広告', '表示', '非表示', '表示'),
        _tableRow('全画面広告', '表示', '非表示', '非表示'),
        _tableRow('料金', '無料', '¥100\n/2ヶ月', '¥1,000\n買い切り'),
      ],
    );
  }

  TableRow _tableHeader() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.amber.shade100),
      children: [
        _tableCell('機能', isHeader: true),
        _tableCell('無料', isHeader: true),
        _tableCell('サブスク', isHeader: true),
        _tableCell('買い切り', isHeader: true),
      ],
    );
  }

  TableRow _tableRow(String feature, String free, String sub, String buy) {
    return TableRow(children: [
      _tableCell(feature),
      _tableCell(free, isGreen: free == '非表示'),
      _tableCell(sub, isGreen: sub == '非表示'),
      _tableCell(buy, isGreen: buy == '非表示'),
    ]);
  }

  Widget _tableCell(String text,
      {bool isHeader = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: isGreen
              ? Colors.green.shade700
              : (isHeader ? Colors.amber.shade900 : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildPurchaseButtons(
    BuildContext context,
    PurchaseService service,
    PurchaseType currentType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // サブスクボタン：未購入の場合のみ表示
        if (currentType != PurchaseType.subscribe)
          FilledButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _buy(
                      context,
                      service,
                      service.buySubscription,
                    ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.card_membership, size: 16),
            label: Text('サブスク購入 — ${service.subscriptionPrice}'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),

        if (currentType != PurchaseType.subscribe) const SizedBox(height: 8),

        // 買い切りボタン：未購入の場合のみ表示
        if (currentType == PurchaseType.free)
          OutlinedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _buy(
                      context,
                      service,
                      service.buyOneTimePurchase,
                    ),
            icon: const Icon(Icons.shopping_bag, size: 16),
            label: Text('買い切り購入 — ${service.oneTimePurchasePrice}'),
          ),
      ],
    );
  }
}
