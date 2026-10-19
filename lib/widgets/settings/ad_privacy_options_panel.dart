import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ad_service.dart';
import '../../l10n/l10n.dart';

/// 広告のプライバシー設定パネル（UMP の同意変更・取り消し入口）
///
/// EEA・英国・スイスなど、UMP が同意変更の入口を必要とするユーザーにのみ表示する。
class AdPrivacyOptionsPanel extends ConsumerStatefulWidget {
  const AdPrivacyOptionsPanel({super.key});

  @override
  ConsumerState<AdPrivacyOptionsPanel> createState() =>
      _AdPrivacyOptionsPanelState();
}

class _AdPrivacyOptionsPanelState extends ConsumerState<AdPrivacyOptionsPanel> {
  bool _isRequired = false;
  bool _isShowingForm = false;

  @override
  void initState() {
    super.initState();
    _checkRequirement();
  }

  Future<void> _checkRequirement() async {
    try {
      final required =
          await ref.read(adServiceProvider).isPrivacyOptionsRequired();
      if (mounted) setState(() => _isRequired = required);
    } catch (_) {
      // 広告非対応プラットフォームなどでは表示しない
    }
  }

  Future<void> _showForm() async {
    setState(() => _isShowingForm = true);
    try {
      await ref.read(adServiceProvider).showPrivacyOptionsForm();
    } finally {
      if (mounted) setState(() => _isShowingForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRequired) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip_outlined,
                    color: Colors.purple.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    texts.adPrivacyOptionsTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              texts.adPrivacyOptionsDesc,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isShowingForm ? null : _showForm,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(texts.adPrivacyOptionsButton),
            ),
          ],
        ),
      ),
    );
  }
}
