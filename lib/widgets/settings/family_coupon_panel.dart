import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/purchase_type.dart';
import '../../providers/family_coupon_provider.dart';
import '../../providers/purchase_type_provider.dart';
import '../../services/family_coupon_service.dart';
import '../../l10n/l10n.dart';
import 'purchase_plan_panel.dart';

/// 家族特典クーポンパネル
///
/// - Premium（subscribe）: 自分のクーポンと、特典を渡している家族（解除可）を表示
/// - 家族特典を利用中（family）: 誰の家族として特典を受けているかを表示
/// - 無料: クーポンの入力欄を表示（停止中の特典があればその旨も表示）
/// - 早期ダウンロード特典（purchase）: 表示しない
class FamilyCouponPanel extends ConsumerStatefulWidget {
  const FamilyCouponPanel({super.key});

  /// iOS では課金パネルと同じく既定で非表示（ビルドオプションで表示）
  static bool get isAvailable => PurchasePlanPanel.isAvailable;

  @override
  ConsumerState<FamilyCouponPanel> createState() => _FamilyCouponPanelState();
}

class _FamilyCouponPanelState extends ConsumerState<FamilyCouponPanel> {
  final _codeController = TextEditingController();
  bool _isBusy = false;
  bool _issueRequested = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orange : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Premium なのにクーポン未発行なら、一度だけ発行を依頼する
  void _issueCouponIfNeeded() {
    if (_issueRequested) return;
    _issueRequested = true;
    final service = ref.read(familyCouponServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await service.issueCoupon(); // 結果は users ドキュメントの監視で反映される
      } on FamilyCouponException catch (e) {
        _showMessage(texts.familyCouponError(e.reason), isError: true);
      }
    });
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isBusy = true);
    try {
      final sponsorName =
          await ref.read(familyCouponServiceProvider).redeemCoupon(code);
      _codeController.clear();
      _showMessage(texts.familyCouponRedeemed(_nameOrFallback(sponsorName)));
    } on FamilyCouponException catch (e) {
      _showMessage(texts.familyCouponError(e.reason), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _removeMember(FamilyMember member) async {
    final name = _nameOrFallback(member.displayName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(texts.familyCouponRemoveConfirmTitle),
        content: Text(texts.familyCouponRemoveConfirmBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(texts.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(texts.familyCouponRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(familyCouponServiceProvider).removeMember(member.uid);
      _showMessage(texts.familyCouponRemoved);
    } on FamilyCouponException catch (e) {
      _showMessage(texts.familyCouponError(e.reason), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _nameOrFallback(String? name) =>
      (name == null || name.isEmpty) ? texts.familyNameUnknown : name;

  @override
  Widget build(BuildContext context) {
    final purchaseType = ref.watch(purchaseTypeProvider).valueOrNull;
    final status = ref.watch(familyCouponStatusProvider).valueOrNull;
    if (purchaseType == null ||
        status == null ||
        purchaseType == PurchaseType.purchase) {
      return const SizedBox.shrink();
    }

    final Widget body;
    if (purchaseType == PurchaseType.subscribe) {
      if (status.couponCode == null) _issueCouponIfNeeded();
      body = _buildSponsorView(status);
    } else if (purchaseType == PurchaseType.family) {
      body = Text(
        texts.familyBenefitActive(_nameOrFallback(status.sponsorDisplayName)),
        style: TextStyle(fontSize: 13, color: Colors.teal.shade900),
      );
    } else {
      body = _buildRedeemView(status);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom,
                    color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    texts.familyCouponTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorView(FamilyCouponStatus status) {
    const limit = FamilyCouponService.memberLimit;
    final code = status.couponCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texts.familyCouponSponsorDesc(limit),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (code == null)
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  _showMessage(texts.familyCouponCopied);
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(texts.familyCouponCopy),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Text(
          texts.familyCouponMembers(status.members.length, limit),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (status.members.isEmpty)
          Text(
            texts.familyCouponNoMembers,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          )
        else
          for (final member in status.members)
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_nameOrFallback(member.displayName))),
                TextButton(
                  onPressed: _isBusy ? null : () => _removeMember(member),
                  child: Text(texts.familyCouponRemove),
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildRedeemView(FamilyCouponStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 発行者の Premium が無効で特典が停止中
        if (status.sponsorUid != null) ...[
          Text(
            texts.familyBenefitSuspended(
                _nameOrFallback(status.sponsorDisplayName)),
            style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          texts.familyCouponRedeemDesc,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                enabled: !_isBusy,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: texts.familyCouponInputHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _redeem(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isBusy ? null : _redeem,
              child: Text(texts.familyCouponRedeemButton),
            ),
          ],
        ),
      ],
    );
  }
}
