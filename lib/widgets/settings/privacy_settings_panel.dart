import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// プライバシー設定パネルウィジェット
class PrivacySettingsPanel extends StatelessWidget {
  const PrivacySettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(
                Icons.security,
                color: Colors.purple.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'プライバシー設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _LegalLinkTile(
            icon: Icons.privacy_tip_outlined,
            label: 'プライバシーポリシー',
            url:
                'https://maya27aokisawada.github.io/go_shop/specifications/privacy_policy',
          ),
          const SizedBox(height: 8),
          const _LegalLinkTile(
            icon: Icons.description_outlined,
            label: '利用規約',
            url:
                'https://maya27aokisawada.github.io/go_shop/specifications/terms_of_service',
          ),
        ],
      ),
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  const _LegalLinkTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.purple.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.purple.shade700,
                decoration: TextDecoration.underline,
              ),
            ),
            const Spacer(),
            Icon(Icons.open_in_new, size: 14, color: Colors.purple.shade400),
          ],
        ),
      ),
    );
  }
}
