import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/news_provider.dart';
import '../../l10n/l10n.dart';
import '../../services/user_preferences_service.dart';
import '../../utils/app_logger.dart';

/// 表示言語設定パネル（日本語 / English）
class LanguageSettingsPanel extends ConsumerStatefulWidget {
  const LanguageSettingsPanel({super.key});

  @override
  ConsumerState<LanguageSettingsPanel> createState() =>
      _LanguageSettingsPanelState();
}

class _LanguageSettingsPanelState extends ConsumerState<LanguageSettingsPanel> {
  String _selectedLang = 'ja';

  @override
  void initState() {
    super.initState();
    _selectedLang = AppLocalizations.currentLanguageCode;
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final saved = await UserPreferencesService.getLanguageCode();
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        _selectedLang = saved;
      });
    }
  }

  Future<void> _onLanguageChanged(String newLang) async {
    if (newLang == _selectedLang) return;

    AppLocalizations.setLanguage(newLang);
    await UserPreferencesService.saveLanguageCode(newLang);
    AppLogger.info('🌐 言語変更: $_selectedLang → $newLang');

    // ニュースプロバイダーを新しい言語で再フェッチ
    ref.read(newsLanguageCodeProvider.notifier).state = newLang;

    if (mounted) {
      setState(() {
        _selectedLang = newLang;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newLang == 'en' ? texts.languageChangedEn : texts.languageChangedJa,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(Icons.language, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texts.displayLanguageTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            texts.displayLanguageDesc,
            style: TextStyle(fontSize: 12, color: Colors.teal.shade600),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'ja',
                label: Text(texts.languageJa),
                icon: const Icon(Icons.flag, size: 16),
              ),
              const ButtonSegment<String>(
                value: 'en',
                label: Text('English'),
                icon: Icon(Icons.language, size: 16),
              ),
            ],
            selected: {_selectedLang},
            onSelectionChanged: (Set<String> newSelection) {
              _onLanguageChanged(newSelection.first);
            },
          ),
        ],
      ),
    );
  }
}
