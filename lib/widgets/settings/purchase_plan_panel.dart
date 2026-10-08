import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/purchase_type_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/purchase_service.dart';
import '../../l10n/l10n.dart';
import '../../config/subscription_sales_config.dart';

/// Premium月額プランの購入・復元を行う設定パネル。
class PurchasePlanPanel extends ConsumerStatefulWidget {
  const PurchasePlanPanel({super.key});

  @override
  ConsumerState<PurchasePlanPanel> createState() => _PurchasePlanPanelState();
}

class _PurchasePlanPanelState extends ConsumerState<PurchasePlanPanel> {
  bool _isLoading = true;
  bool _isStoreAvailable = false;
  bool _isPremiumProductAvailable = false;
  bool _isPremiumYearlyProductAvailable = false;
  late final PurchaseService _purchaseService;
  late PurchaseFlowState _purchaseState;
  StreamSubscription<PurchaseFlowState>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _purchaseService = ref.read(purchaseServiceProvider);
    _purchaseState = _purchaseService.currentState;
    _statusSubscription = _purchaseService.statusStream.listen((state) {
      if (!mounted) return;
      setState(() => _purchaseState = state);
    });
    _initializePurchaseService();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePurchaseService() async {
    await _purchaseService.initialize();
    await _purchaseService.refreshSalesStartDate();
    if (!mounted) return;
    setState(() {
      _isStoreAvailable = _purchaseService.isAvailable;
      _isPremiumProductAvailable = _purchaseService.isPremiumMonthlyAvailable;
      _isPremiumYearlyProductAvailable =
          _purchaseService.isPremiumYearlyAvailable;
      _isLoading = false;
    });
  }

  Future<void> _startPurchase() async {
    await _purchaseService.buyPremiumMonthly();
  }

  Future<void> _startYearlyPurchase() async {
    await _purchaseService.buyPremiumYearly();
  }

  Future<void> _restorePurchases() async {
    await _purchaseService.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumActiveProvider);
    final isPurchasePending =
        _purchaseState.status == PurchaseFlowStatus.pending;
    final isSalesOpen = _purchaseService.isSalesOpen;

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
          const SizedBox(height: 8),
          _buildLegalLink(
            AppLocalizations.currentLanguageCode == 'en'
                ? 'Plan details and pricing'
                : 'プラン内容・価格',
            SubscriptionSalesConfig.premiumPlanDetailsUrl,
          ),
          if (!isPremium && !isSalesOpen) ...[
            const SizedBox(height: 12),
            _buildPreReleaseNotice(),
          ] else if (!isPremium) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ||
                      !_isStoreAvailable ||
                      !_isPremiumProductAvailable ||
                      isPurchasePending
                  ? null
                  : _startPurchase,
              icon: _isLoading || isPurchasePending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.workspace_premium),
              label: Text(
                isPurchasePending
                    ? '処理中'
                    : 'Premiumを有効化 (${_purchaseService.premiumMonthlyPrice})',
              ),
            ),
            if (!_isLoading && !_isStoreAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'ストアに接続できません。ストアアプリのあるAndroidまたはiOS端末でお試しください。',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ] else if (!_isLoading && !_isPremiumProductAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'Premium商品をストアから取得できませんでした。購入に使用するストアアカウントとアプリの配布元を確認してください。',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
            if (!_isLoading &&
                _isStoreAvailable &&
                _isPremiumYearlyProductAvailable) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isPurchasePending ? null : _startYearlyPurchase,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(
                  isPurchasePending
                      ? '処理中'
                      : '年払いでPremiumを有効化 (${_purchaseService.premiumYearlyPrice})',
                ),
              ),
            ],
          ],
          if (_purchaseState.message != null) ...[
            const SizedBox(height: 8),
            Text(
              _purchaseState.message!,
              style: TextStyle(
                fontSize: 12,
                color: _purchaseState.status == PurchaseFlowStatus.error
                    ? Colors.red.shade700
                    : _purchaseState.status == PurchaseFlowStatus.purchased ||
                            _purchaseState.status == PurchaseFlowStatus.restored
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isLoading || !_isStoreAvailable || isPurchasePending
                ? null
                : _restorePurchases,
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('購入を復元'),
          ),
          if (Platform.isIOS && !isPremium && isSalesOpen) ...[
            const Divider(height: 24),
            Text(
              texts.subscriptionNotesTitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              texts.subscriptionNotesBody,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildLegalLink(
                  texts.privacyPolicy,
                  'https://maya27aokisawada.github.io/go_shop/specifications/privacy_policy',
                ),
                const Text(' | ', style: TextStyle(color: Colors.grey)),
                _buildLegalLink(
                  texts.termsOfService,
                  'https://maya27aokisawada.github.io/go_shop/specifications/terms_of_service',
                ),
                const Text(' | ', style: TextStyle(color: Colors.grey)),
                _buildLegalLink(
                  texts.commercialDisclosure,
                  'https://maya27aokisawada.github.io/go_shop/specifications/tokushoho',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// プレ公開期間中に購入ボタンの代わりに表示する案内。
  Widget _buildPreReleaseNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: Colors.amber.shade900,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  texts.subscriptionPreReleaseTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            texts.subscriptionPreReleaseBody,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 4),
          Text(
            texts.subscriptionSalesStartNotice(
              _purchaseService.salesStartDate.year,
              _purchaseService.salesStartDate.month,
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
