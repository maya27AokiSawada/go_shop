import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/access_control_service.dart';

/// プライバシー設定パネルウィジェット
class PrivacySettingsPanel extends ConsumerStatefulWidget {
  const PrivacySettingsPanel({super.key});

  @override
  ConsumerState<PrivacySettingsPanel> createState() =>
      _PrivacySettingsPanelState();
}

class _PrivacySettingsPanelState extends ConsumerState<PrivacySettingsPanel> {
  bool _isSecretMode = false;

  @override
  void initState() {
    super.initState();
    _loadSecretMode();
  }

  Future<void> _loadSecretMode() async {
    final accessControl = ref.read(accessControlServiceProvider);
    final isSecretMode = await accessControl.isSecretModeEnabled();
    if (mounted) {
      setState(() {
        _isSecretMode = isSecretMode;
      });
    }
  }

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
          const SizedBox(height: 8),
          Text(
            'シークレットモードをオンにすると、サインインが必要になります',
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final accessControl = ref.read(accessControlServiceProvider);
              await accessControl.toggleSecretMode();
              final newSecretMode = await accessControl.isSecretModeEnabled();
              setState(() {
                _isSecretMode = newSecretMode;
              });
            },
            icon: Icon(
              _isSecretMode ? Icons.visibility : Icons.visibility_off,
              size: 16,
            ),
            label: Text(
              _isSecretMode ? 'シークレットモード: ON' : 'シークレットモード: OFF',
              style: const TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSecretMode
                  ? Colors.orange.shade100
                  : Colors.green.shade100,
              foregroundColor: _isSecretMode
                  ? Colors.orange.shade800
                  : Colors.green.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
